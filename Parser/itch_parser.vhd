--------------------------------------------------------------------------------
-- itch_parser
--
-- Stage 5 of the market-data header parser pipeline.
--
-- ============================================================================
-- STRUCTURE
-- ============================================================================
-- Raw beats are stored UNCONDITIONALLY in a rolling window, and the message is
-- selected out of that window afterwards:
--
--     win_r <= s_axis_tdata & win_r(0 to 7);   -- no enable, no decoder
--
-- Do everything, then select - rather than select, then do. Nothing on the
-- window path depends on framing state, so the framing loop carries only the
-- block offsets plus the current length and type. There is no byte index, no
-- per-byte buffer write, and no Seconds capture inside the loop.
--
-- Extraction runs in stage 2, where it is FEED-FORWARD from registers and can
-- take a further pipeline stage if it ever needs one - unlike the framing
-- loop, which cannot.
--
-- ============================================================================
-- LATENCY AND THROUGHPUT
-- ============================================================================
--   one 8-byte beat per cycle, s_axis_tready tied high
--   two cycles from message completion to msg_valid
--
-- ============================================================================
-- 'T' SECONDS MESSAGES
-- ============================================================================
-- A Seconds block is 7 bytes, smaller than one beat, so two messages can
-- complete in a single beat. T is treated as CLOCK STATE: its seconds value is
-- captured and no event is emitted. It still consumes a sequence number, so
-- msg_index advances across it.
--
-- The type byte is captured during framing rather than read back out of the
-- window, so the T decision costs one register and no select.
--
-- ============================================================================
-- FRAMING
-- ============================================================================
-- Driven by the length chain plus the end of the packet, NOT by the Mold
-- message_count. The framed count is reported raw on pkt_msg_count; a
-- downstream checker compares it against message_count from the field bus.
--
-- Payload starts at byte 62 untagged (beat 7, lane 6) or byte 66 tagged
-- (beat 8, lane 2).
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;
use work.udp_parser_pkg.all;
use work.mold_parser_pkg.all;
use work.itch_parser_pkg.all;

entity itch_parser is
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;                        -- synchronous, active low

    -- AXI-Stream slave -------------------------------------------------------
    s_axis_tdata   : in  std_logic_vector(63 downto 0);
    s_axis_tkeep   : in  std_logic_vector(7 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;                -- tied high, never stalls
    s_axis_tlast   : in  std_logic;

    -- AXI-Stream master ------------------------------------------------------
    m_axis_tdata   : out std_logic_vector(63 downto 0);
    m_axis_tkeep   : out std_logic_vector(7 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;                -- UNUSED, parsers never stall
    m_axis_tlast   : out std_logic;

    -- Upstream field bus -----------------------------------------------------
    s_fields       : in  std_logic_vector(C_MOLD_BUS_W-1 downto 0);

    -- Per-message event ------------------------------------------------------
    msg_valid      : out std_logic;
    msg_index      : out std_logic_vector(15 downto 0);
    msg_seqnum     : out std_logic_vector(63 downto 0);
    msg_type       : out std_logic_vector(7 downto 0);
    msg_length     : out std_logic_vector(15 downto 0);
    msg_fields     : out std_logic_vector(C_MSG_FIELDS_W-1 downto 0);
    msg_status     : out std_logic_vector(C_MSG_STATUS_W-1 downto 0);
    pkt_fields     : out std_logic_vector(C_ITCH_PKT_W-1 downto 0);

    -- Exchange clock, from the most recent Seconds message --------------------
    exchange_seconds : out std_logic_vector(31 downto 0);

    -- Packet-level status, pulsed with the outgoing tlast --------------------
    pkt_done           : out std_logic;
    pkt_msg_count      : out std_logic_vector(15 downto 0)  -- as framed
  );
end entity itch_parser;


architecture rtl of itch_parser is

  ------------------------------------------------------------------------------
  -- Byte lane n of a beat. n = 0 is the earliest byte on the wire.
  ------------------------------------------------------------------------------
  function bsel (d : std_logic_vector(63 downto 0); n : natural)
    return std_logic_vector is
  begin
    return d(8*n + 7 downto 8*n);
  end function;

  ------------------------------------------------------------------------------
  -- Rolling window of raw beats.
  --
  -- Depth 9 = 72 bytes, which always contains any decoded message: the
  -- largest is C at 58 bytes, and a message ending at lane 0 of the newest
  -- beat starts at most 64 bytes earlier.
  --
  -- win_r(0) is the NEWEST beat.
  ------------------------------------------------------------------------------
  constant C_WIN_BEATS : natural := 9;
  constant C_WIN_BYTES : natural := C_WIN_BEATS * 8;   -- 72

  type win_t   is array (0 to C_WIN_BEATS-1) of std_logic_vector(63 downto 0);
  type byte_t  is array (natural range <>) of std_logic_vector(7 downto 0);

  signal win_r : win_t := (others => (others => '0'));

  ------------------------------------------------------------------------------
  -- Flatten the window so byte 0 is the OLDEST and byte 71 the newest.
  --
  --   flat(f) = lane (f mod 8) of win_r(8 - f/8)
  --
  -- So the newest beat occupies flat bytes 64..71.
  ------------------------------------------------------------------------------
  function flatten (w : win_t) return byte_t is
    variable r : byte_t(0 to C_WIN_BYTES-1);
  begin
    for f in 0 to C_WIN_BYTES-1 loop
      r(f) := bsel(w((C_WIN_BEATS-1) - (f / 8)), f mod 8);
    end loop;
    return r;
  end function;

  ------------------------------------------------------------------------------
  -- Two-stage extraction.
  --
  -- A single 72:1 mux per output byte would be enormous. The offset splits
  -- into a lane (0..7) and a beat (0..8), so it is done as an 8-way byte
  -- rotate followed by a 9-way beat select - roughly 6 logic levels rather
  -- than 7, and far less area.
  --
  -- Both selects come from REGISTERS, and the whole thing is feed-forward.
  ------------------------------------------------------------------------------
  function rot_lane (f : byte_t; lane : natural) return byte_t is
    variable r : byte_t(0 to C_WIN_BYTES-1);
  begin
    for k in 0 to C_WIN_BYTES-1 loop
      r(k) := f((k + lane) mod C_WIN_BYTES);
    end loop;
    return r;
  end function;

  function sel_beat (f : byte_t; beat : natural) return std_logic_vector is
    variable r : std_logic_vector(C_MSG_BUF_W-1 downto 0) := (others => '0');
  begin
    for k in 0 to C_MSG_BUF_BYTES-1 loop
      r(8*k + 7 downto 8*k) := f((8*beat + k) mod C_WIN_BYTES);
    end loop;
    return r;
  end function;

  ------------------------------------------------------------------------------
  -- 16-byte view spanning the previous and current beat.
  --
  -- view(o + 8) is the byte at offset o, for o in -8 .. +7. During cycle T
  -- win_r(0) holds beat T-1 and s_axis_tdata is beat T, so a length field
  -- straddling a beat boundary is an ordinary read at a negative offset -
  -- no pending state, no special case.
  ------------------------------------------------------------------------------
  function make_view (prev, cur : std_logic_vector(63 downto 0)) return byte_t is
    variable v : byte_t(0 to 15);
  begin
    for i in 0 to 7 loop
      v(i)     := bsel(prev, i);
      v(i + 8) := bsel(cur, i);
    end loop;
    return v;
  end function;

  ------------------------------------------------------------------------------
  -- Beat tracking and payload start
  ------------------------------------------------------------------------------
  signal beat_cnt : unsigned(3 downto 0) := (others => '0');
  signal vlan_c   : std_logic;

  -- Registered at packet start so the raw s_fields route and the VLAN mux sit
  -- OFF the head of the framing chain.
  signal in_payload_r : std_logic := '0';
  signal start_lane_r : unsigned(2 downto 0) := (others => '0');
  signal first_beat_c : unsigned(3 downto 0);
  signal first_lane_c : unsigned(2 downto 0);

  ------------------------------------------------------------------------------
  -- ARITHMETIC FRAMING STATE - this is the only loop that cannot be pipelined
  --
  -- Offsets are signed and relative to lane 0 of the CURRENT beat, so a block
  -- that began in the previous beat simply has a negative offset. The 16-byte
  -- view above covers -8..+7, which removes every "pending byte" special case.
  --
  --   in_block_r  a block is in progress; end_r is its last byte
  --   end_r       offset of the in-progress block's LAST byte
  --   start_r     offset of the next block's first (length) byte
  ------------------------------------------------------------------------------
  signal in_block_r : std_logic := '0';
  signal end_r      : signed(17 downto 0) := (others => '0');
  signal start_r    : signed(17 downto 0) := (others => '0');
  signal cur_len_r  : unsigned(15 downto 0) := (others => '0');
  signal cur_type_r : std_logic_vector(7 downto 0) := (others => '0');
  signal index_r    : unsigned(15 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- Stage 1 -> stage 2 handoff
  --
  -- cmp_end_lane_r is the lane of the message's LAST byte in the beat that
  -- was current when it completed. Since stage 2 runs one cycle later and
  -- win_r(0) then holds that beat, the message's last byte is at flat index
  -- 64 + end_lane.
  ------------------------------------------------------------------------------
  signal cmp_valid_r    : std_logic := '0';
  signal cmp_is_t_r     : std_logic := '0';
  signal cmp_type_r     : std_logic_vector(7 downto 0) := (others => '0');
  signal cmp_len_r      : unsigned(15 downto 0) := (others => '0');
  signal cmp_index_r    : unsigned(15 downto 0) := (others => '0');
  signal cmp_end_lane_r : unsigned(2 downto 0) := (others => '0');
  signal cmp_stat_r     : std_logic_vector(C_MSG_STATUS_W-1 downto 0)
                        := (others => '0');
  signal cmp_fields_r   : std_logic_vector(C_MOLD_BUS_W-1 downto 0)
                        := (others => '0');

  -- 'T' gets its OWN capture registers. Sharing cmp_* would let a Seconds
  -- message completing later in the same beat overwrite the values of a real
  -- message that already set cmp_valid_r - exactly what happens when a
  -- 27-byte block is followed by a 7-byte Seconds block.
  signal t_end_lane_r : unsigned(2 downto 0) := (others => '0');
  signal t_len_r      : unsigned(15 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- Stage 2 outputs
  ------------------------------------------------------------------------------
  signal msg_valid_r   : std_logic := '0';
  signal msg_index_r   : std_logic_vector(15 downto 0) := (others => '0');
  signal msg_seqnum_r  : std_logic_vector(63 downto 0) := (others => '0');
  signal msg_type_r    : std_logic_vector(7 downto 0) := (others => '0');
  signal msg_len_out_r : std_logic_vector(15 downto 0) := (others => '0');
  signal msg_fields_r  : std_logic_vector(C_MSG_FIELDS_W-1 downto 0)
                       := (others => '0');
  signal msg_stat_r    : std_logic_vector(C_MSG_STATUS_W-1 downto 0)
                       := (others => '0');
  signal pkt_fields_r  : std_logic_vector(C_ITCH_PKT_W-1 downto 0)
                       := (others => '0');
  signal seconds_r     : std_logic_vector(31 downto 0) := (others => '0');

  signal pkt_done_r  : std_logic := '0';
  signal pkt_count_r : std_logic_vector(15 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- Data path and upstream bus, one register stage each
  ------------------------------------------------------------------------------
  signal s_fields_r : std_logic_vector(C_MOLD_BUS_W-1 downto 0)
                    := (others => '0');
  signal tdata_r    : std_logic_vector(63 downto 0) := (others => '0');
  signal tkeep_r    : std_logic_vector(7 downto 0)  := (others => '0');
  signal tvalid_r   : std_logic := '0';
  signal tlast_r    : std_logic := '0';

begin

  ------------------------------------------------------------------------------
  -- Backpressure: parsers never stall.
  ------------------------------------------------------------------------------
  s_axis_tready <= '1';

  vlan_c       <= eth_vlan_present(s_fields);
  first_beat_c <= to_unsigned(8, 4) when vlan_c = '1' else to_unsigned(7, 4);
  first_lane_c <= to_unsigned(2, 3) when vlan_c = '1' else to_unsigned(6, 3);

  ------------------------------------------------------------------------------
  -- Data path and upstream field bus
  ------------------------------------------------------------------------------
  p_datapath : process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        tdata_r    <= (others => '0');
        tkeep_r    <= (others => '0');
        tvalid_r   <= '0';
        tlast_r    <= '0';
        s_fields_r <= (others => '0');
      else
        tdata_r    <= s_axis_tdata;
        tkeep_r    <= s_axis_tkeep;
        tvalid_r   <= s_axis_tvalid;
        tlast_r    <= s_axis_tlast and s_axis_tvalid;
        s_fields_r <= s_fields;
      end if;
    end if;
  end process p_datapath;

  ------------------------------------------------------------------------------
  -- The window. Unconditional shift - no enable, no decoder, no index, and
  -- so no dependence on anything the framing loop computes.
  ------------------------------------------------------------------------------
  p_window : process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        win_r <= (others => (others => '0'));
      elsif s_axis_tvalid = '1' then
        win_r <= s_axis_tdata & win_r(0 to C_WIN_BEATS-2);
      end if;
    end if;
  end process p_window;

  ------------------------------------------------------------------------------
  -- Stage 1: framing
  --
  -- Two arithmetic passes per beat over the 16-byte view of the previous and
  -- current beat. The variables carry the block offsets from pass to pass
  -- within the cycle; only in_block / end / start / len / type are registered
  -- across beats.
  ------------------------------------------------------------------------------
  p_frame : process (clk)
    variable v_view    : byte_t(0 to 15);
    variable v_in      : std_logic;
    variable v_end     : signed(17 downto 0);
    variable v_start   : signed(17 downto 0);
    variable v_len     : unsigned(15 downto 0);
    variable v_type    : std_logic_vector(7 downto 0);
    variable v_index   : unsigned(15 downto 0);
    variable v_len16   : std_logic_vector(15 downto 0);
    variable v_o       : integer;
    variable v_lastlane: integer;
    variable v_emitted : boolean;
    variable v_multi   : std_logic;
    variable v_overrun : std_logic;

    -- one completion: lane, length, type
    procedure do_complete (lane : in integer;
                           len  : in unsigned(15 downto 0);
                           typ  : in std_logic_vector(7 downto 0)) is
    begin
      if typ = C_TYPE_T then
        -- clock state, own registers so a real message already captured in
        -- this beat is not disturbed
        cmp_is_t_r   <= '1';
        t_end_lane_r <= to_unsigned(lane, 3);
        t_len_r      <= len;
      elsif v_emitted then
        v_multi := '1';
      else
        v_emitted      := true;
        cmp_valid_r    <= '1';
        cmp_type_r     <= typ;
        cmp_len_r      <= len;
        cmp_index_r    <= v_index;
        cmp_end_lane_r <= to_unsigned(lane, 3);
        cmp_fields_r   <= s_fields;
        cmp_stat_r     <= (others => '0');
        cmp_stat_r(C_ST_DECODED) <=
          '1' when is_decoded_type(typ) else '0';
        cmp_stat_r(C_ST_UNKNOWN_TYPE) <=
          '1' when spec_msg_len(typ) = 0 else '0';
        cmp_stat_r(C_ST_LEN_MISMATCH) <=
          '0' when to_integer(len) = spec_msg_len(typ) else '1';
      end if;
      v_index := v_index + 1;
    end procedure;

  begin
    if rising_edge(clk) then
      if resetn = '0' then
        beat_cnt     <= (others => '0');
        in_payload_r <= '0';
        start_lane_r <= (others => '0');
        in_block_r   <= '0';
        end_r        <= (others => '0');
        start_r      <= (others => '0');
        cur_len_r    <= (others => '0');
        cur_type_r   <= (others => '0');
        index_r      <= (others => '0');
        cmp_valid_r  <= '0';
        cmp_is_t_r   <= '0';
        cmp_stat_r   <= (others => '0');
        cmp_fields_r <= (others => '0');
        t_end_lane_r <= (others => '0');
        t_len_r      <= (others => '0');
        pkt_done_r   <= '0';
        pkt_count_r  <= (others => '0');
      else

        cmp_valid_r <= '0';
        cmp_is_t_r  <= '0';
        pkt_done_r  <= '0';

        if s_axis_tvalid = '1' then

          v_view  := make_view(win_r(0), s_axis_tdata);
          v_in    := in_block_r;
          v_end   := end_r;
          v_start := start_r;
          v_len   := cur_len_r;
          v_type  := cur_type_r;
          v_index := index_r;

          v_emitted := false;
          v_multi   := '0';
          v_overrun := '0';

          -- highest lane carrying real data in this beat
          v_lastlane := -1;
          for i in 0 to 7 loop
            if s_axis_tkeep(i) = '1' then
              v_lastlane := i;
            end if;
          end loop;

          --------------------------------------------------------------------
          -- Packet / payload boundaries
          --------------------------------------------------------------------
          if beat_cnt = 0 then
            v_index := (others => '0');
            v_in    := '0';
            v_start := to_signed(64, 18);      -- nothing until the payload
          end if;

          if s_axis_tlast = '1' then
            in_payload_r <= '0';
          elsif beat_cnt = first_beat_c then
            in_payload_r <= '1';
          end if;
          start_lane_r <= first_lane_c;

          -- first payload beat: the first block starts at start_lane
          if beat_cnt = first_beat_c then
            v_in    := '0';
            v_start := signed(resize(unsigned(first_lane_c), 18));
          end if;

          if s_axis_tlast = '1' then
            beat_cnt <= (others => '0');
          elsif beat_cnt /= 15 then
            beat_cnt <= beat_cnt + 1;
          end if;

          --------------------------------------------------------------------
          -- ARITHMETIC FRAMING
          --
          -- Two passes, not eight. Pass 1 retires a block already in
          -- progress; pass 2 reads and possibly retires the next one.
          --
          -- Two is provably enough for ASX ITCH: a third would need two
          -- consecutive sub-8-byte blocks, and Seconds (7 bytes) is the only
          -- type that small. A third is detected and flagged rather than
          -- silently mis-framed.
          --------------------------------------------------------------------
          if (in_payload_r = '1') or (beat_cnt = first_beat_c) then

            -- pass 1: does the in-progress block end in this beat?
            if v_in = '1' and v_end <= 7 then
              if to_integer(v_end) <= v_lastlane then
                do_complete(to_integer(v_end), v_len, v_type);
                v_in    := '0';
                v_start := v_end + 1;
              end if;
            end if;

            -- pass 2: read the next block if its length and type bytes are
            -- all inside the view, and its start byte actually arrived
            if v_in = '0' and v_start <= 5 and v_start >= -8 then
              v_o := to_integer(v_start);
              if (v_o + 2) <= v_lastlane then
                v_len16(15 downto 8) := v_view(v_o + 8);
                v_len16(7 downto 0)  := v_view(v_o + 9);
                v_len  := unsigned(v_len16);
                v_type := v_view(v_o + 10);
                v_end  := v_start + signed(resize(unsigned(v_len16), 18)) + 1;
                v_in   := '1';

                if v_end <= 7 then
                  if to_integer(v_end) <= v_lastlane then
                    do_complete(to_integer(v_end), v_len, v_type);
                    v_in    := '0';
                    v_start := v_end + 1;
                    -- a third pass would be needed here; flag it
                    if v_start <= 5 then
                      v_overrun := '1';
                    end if;
                  end if;
                end if;
              end if;
            end if;
          end if;

          --------------------------------------------------------------------
          -- End of packet
          --------------------------------------------------------------------
          if s_axis_tlast = '1' then
            if v_in = '1' then
              -- a block was still in progress
              if not v_emitted then
                v_emitted      := true;
                cmp_valid_r    <= '1';
                cmp_type_r     <= v_type;
                cmp_len_r      <= v_len;
                cmp_index_r    <= v_index;
                cmp_end_lane_r <= to_unsigned(7, 3);
                cmp_fields_r   <= s_fields;
                cmp_stat_r     <= (others => '0');
                cmp_stat_r(C_ST_MSG_TRUNCATED) <= '1';
                cmp_stat_r(C_ST_UNKNOWN_TYPE)  <=
                  '1' when spec_msg_len(v_type) = 0 else '0';
                v_index := v_index + 1;
              else
                v_multi := '1';
              end if;
            end if;
            pkt_done_r  <= '1';
            pkt_count_r <= std_logic_vector(v_index);
          end if;

          if (v_multi or v_overrun) = '1' then
            cmp_stat_r(C_ST_MULTI_COMPLETE) <= '1';
          end if;

          --------------------------------------------------------------------
          -- Shift the offsets into the next beat's frame of reference
          --------------------------------------------------------------------
          if s_axis_tlast = '1' then
            in_block_r <= '0';
            start_r    <= to_signed(64, 18);
            end_r      <= (others => '0');
          else
            in_block_r <= v_in;
            end_r      <= v_end   - 8;
            start_r    <= v_start - 8;
          end if;
          cur_len_r  <= v_len;
          cur_type_r <= v_type;
          index_r    <= v_index;

        end if;
      end if;
    end if;
  end process p_frame;

  ------------------------------------------------------------------------------
  -- Stage 2: extract from the window, decode, emit
  --
  -- Entirely feed-forward from registers. If this ever becomes the critical
  -- path it can take a further pipeline stage - unlike the framing loop.
  --
  -- The message's last byte sits at flat index 64 + cmp_end_lane_r, because
  -- win_r(0) now holds the beat that was current when it completed. Its first
  -- byte is therefore at 65 + end_lane - len.
  ------------------------------------------------------------------------------
  p_emit : process (clk)
    variable v_flat  : byte_t(0 to C_WIN_BYTES-1);
    variable v_rot   : byte_t(0 to C_WIN_BYTES-1);
    variable v_msg   : std_logic_vector(C_MSG_BUF_W-1 downto 0);
    variable v_start : integer;
    variable v_lane  : natural;
    variable v_beat  : natural;
    variable v_sec   : integer;
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        msg_valid_r   <= '0';
        msg_index_r   <= (others => '0');
        msg_seqnum_r  <= (others => '0');
        msg_type_r    <= (others => '0');
        msg_len_out_r <= (others => '0');
        msg_fields_r  <= (others => '0');
        msg_stat_r    <= (others => '0');
        pkt_fields_r  <= (others => '0');
        seconds_r     <= (others => '0');
      else
        msg_valid_r <= cmp_valid_r;

        if (cmp_valid_r = '1') or (cmp_is_t_r = '1') then

          v_flat := flatten(win_r);

          ------------------------------------------------------------------
          -- 'T' - clock state only. Just four bytes, so a small dedicated
          -- select rather than the full message extraction.
          --
          -- Message byte 1 sits at flat index (64 + end_lane) - len + 2, and
          -- byte 1 is the MOST significant of the big-endian seconds value.
          ------------------------------------------------------------------
          if cmp_is_t_r = '1' then
            v_sec := 64 + to_integer(t_end_lane_r) - to_integer(t_len_r) + 2;
            if v_sec < 0 then
              v_sec := 0;
            end if;
            seconds_r <= v_flat((v_sec + 0) mod C_WIN_BYTES) &
                         v_flat((v_sec + 1) mod C_WIN_BYTES) &
                         v_flat((v_sec + 2) mod C_WIN_BYTES) &
                         v_flat((v_sec + 3) mod C_WIN_BYTES);
          end if;

          ------------------------------------------------------------------
          -- A real message: locate it in the window and decode
          ------------------------------------------------------------------
          if cmp_valid_r = '1' then
            v_start := 64 + to_integer(cmp_end_lane_r)
                          - to_integer(cmp_len_r) + 1;
            if v_start < 0 then
              v_start := 0;               -- longer than the window; only
            end if;                       -- undecoded types can be

            v_lane := v_start mod 8;
            v_beat := v_start / 8;
            if v_beat > C_WIN_BEATS-1 then
              v_beat := C_WIN_BEATS-1;
            end if;

            v_rot := rot_lane(v_flat, v_lane);
            v_msg := sel_beat(v_rot, v_beat);

            msg_index_r   <= std_logic_vector(cmp_index_r);
            msg_type_r    <= cmp_type_r;
            msg_len_out_r <= std_logic_vector(cmp_len_r);
            msg_stat_r    <= cmp_stat_r;
            pkt_fields_r  <= cmp_fields_r;

            msg_seqnum_r <= std_logic_vector(
              unsigned(mold_sequence_num(cmp_fields_r)) +
              resize(cmp_index_r, 64));

            if cmp_stat_r(C_ST_DECODED) = '1' then
              msg_fields_r <= decode_msg(v_msg, cmp_type_r);
            else
              msg_fields_r <= (others => '0');
            end if;
          end if;

        end if;
      end if;
    end if;
  end process p_emit;

  ------------------------------------------------------------------------------
  -- Outputs. All registered.
  ------------------------------------------------------------------------------
  m_axis_tdata  <= tdata_r;
  m_axis_tkeep  <= tkeep_r;
  m_axis_tvalid <= tvalid_r;
  m_axis_tlast  <= tlast_r;

  msg_valid  <= msg_valid_r;
  msg_index  <= msg_index_r;
  msg_seqnum <= msg_seqnum_r;
  msg_type   <= msg_type_r;
  msg_length <= msg_len_out_r;
  msg_fields <= msg_fields_r;
  msg_status <= msg_stat_r;
  pkt_fields <= pkt_fields_r;

  exchange_seconds <= seconds_r;

  pkt_done      <= pkt_done_r;
  pkt_msg_count <= pkt_count_r;

end architecture rtl;
