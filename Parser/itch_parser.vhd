--------------------------------------------------------------------------------
-- itch_parser
--
-- Stage 5 of the market-data header parser pipeline.
--
--   AXI-Stream slave in -> AXI-Stream master out (data unmodified)
--   Field bus in  (Ethernet + IPv4 + UDP + Mold, C_MOLD_BUS_W bits)
--   Per-message event stream out
--
-- ============================================================================
-- DELIBERATE DEVIATIONS FROM THE COMMON SKELETON - please review
-- ============================================================================
--
-- 1. N OUTPUTS PER PACKET, not one field bus alongside tlast. A packet
--    carries several messages, so this stage emits an event per message.
--    The 523-bit upstream bus is re-presented on pkt_fields with every
--    event, so single-point end-to-end checking still works.
--
-- 2. A MESSAGE ASSEMBLY BUFFER (64 bytes) exists. It is bounded and cannot
--    back up - it is a shift-in register, not elastic storage - but it IS
--    storage, and the instructions ask for storage to be flagged.
--
-- 3. tkeep IS INSPECTED here, unlike the four header parsers. The ITCH
--    payload runs to the end of the frame, so the final partial beat must
--    not be parsed as data.
--
-- 4. TWO-CYCLE EVENT LATENCY. Framing completes a message in one cycle;
--    field decode and emission happen the next. This keeps the type mux and
--    field extraction out of the framing feedback loop, which is the only
--    timing-critical path in the design.
--
-- ============================================================================
-- 'T' SECONDS MESSAGES - the chosen special case
-- ============================================================================
-- A Seconds block is 7 bytes, smaller than one beat, so two messages could
-- otherwise complete within a single beat. T is therefore treated as CLOCK
-- STATE: its 4-byte seconds value is captured into exchange_seconds and no
-- event is emitted. Since T is the only type with a sub-8-byte block, no two
-- EMITTED events can ever land in the same beat.
--
-- T still consumes a sequence number, so msg_index advances across it.
--
-- ============================================================================
-- FRAMING
-- ============================================================================
-- Driven by the length chain plus the end of the packet, NOT by the Mold
-- message_count. The count is a cross-check only (pkt_count_mismatch), so a
-- packet whose count disagrees with its contents is flagged rather than
-- mis-framed - the same principle as ihl_invalid.
--
-- The payload starts at byte 62 untagged (beat 7, lane 6) or byte 66 tagged
-- (beat 8, lane 2). Bytes are then walked one at a time through a three-phase
-- state machine, unrolled eight times per beat. This handles a length field
-- straddling a beat boundary (roughly 1 message in 8) without special cases.
--
-- ============================================================================
-- KNOWN LIMITATIONS IN THIS FIRST CUT
-- ============================================================================
--   * If a message completes AND a following message is cut short by tlast
--     in the SAME beat, only the first event is emitted and
--     C_ST_MULTI_COMPLETE is set. The second is lost.
--   * Messages longer than 64 bytes (R at 113, M at 261) are framed and
--     counted but only their first 64 bytes are assembled. They are not
--     decoded types, so no field is affected.
--   * The unrolled eight-byte chain is the deepest logic in the project.
--     Timing at 156.25 MHz needs a trial synthesis on the chosen part.
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
    pkt_msg_count      : out std_logic_vector(15 downto 0);  -- as framed
    pkt_count_mismatch : out std_logic
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
  -- Message assembly buffer as a byte array. Indexing with a variable is
  -- legal and readable; it synthesises to a decoder plus byte write enables,
  -- the same hardware a variable-range slice would produce.
  ------------------------------------------------------------------------------
  type byte_array_t is array (0 to C_MSG_BUF_BYTES-1)
    of std_logic_vector(7 downto 0);

  function to_slv (a : byte_array_t) return std_logic_vector is
    variable r : std_logic_vector(C_MSG_BUF_W-1 downto 0);
  begin
    for i in a'range loop
      r(8*i + 7 downto 8*i) := a(i);
    end loop;
    return r;
  end function;

  -- Framing phases
  constant PH_LEN_HI : std_logic_vector(1 downto 0) := "00";
  constant PH_LEN_LO : std_logic_vector(1 downto 0) := "01";
  constant PH_DATA   : std_logic_vector(1 downto 0) := "10";

  ------------------------------------------------------------------------------
  -- Beat tracking and payload start
  ------------------------------------------------------------------------------
  signal beat_cnt : unsigned(3 downto 0);
  signal vlan_c   : std_logic;

  -- Payload begins at byte 62 (beat 7, lane 6) or byte 66 (beat 8, lane 2)
  signal first_beat  : unsigned(3 downto 0);
  signal first_lane  : unsigned(2 downto 0);

  ------------------------------------------------------------------------------
  -- Framing state
  ------------------------------------------------------------------------------
  signal phase_r    : std_logic_vector(1 downto 0);
  signal len_hi_r   : std_logic_vector(7 downto 0);
  signal msg_len_r  : unsigned(15 downto 0);
  signal rem_r      : unsigned(15 downto 0);
  signal byte_idx_r : unsigned(15 downto 0);
  signal buf_r      : byte_array_t;
  signal index_r    : unsigned(15 downto 0);
  signal seconds_r  : std_logic_vector(31 downto 0);

  ------------------------------------------------------------------------------
  -- Stage 1 -> stage 2 handoff (a completed message awaiting decode)
  --
  -- cmp_fields_r captures the upstream bus AT COMPLETION. It cannot be read
  -- from s_fields_r in stage 2: by then the next packet's beats may already
  -- be in this stage, and the upstream slices update at DIFFERENT times
  -- (eth_parser at its beat 1, mold_parser not until beat 7), so a late read
  -- yields an incoherent mix of two packets.
  ------------------------------------------------------------------------------
  signal cmp_valid_r  : std_logic;
  signal cmp_buf_r    : byte_array_t;
  signal cmp_type_r   : std_logic_vector(7 downto 0);
  signal cmp_len_r    : unsigned(15 downto 0);
  signal cmp_index_r  : unsigned(15 downto 0);
  signal cmp_stat_r   : std_logic_vector(C_MSG_STATUS_W-1 downto 0);
  signal cmp_fields_r : std_logic_vector(C_MOLD_BUS_W-1 downto 0);

  ------------------------------------------------------------------------------
  -- Stage 2 outputs
  ------------------------------------------------------------------------------
  signal msg_valid_r  : std_logic;
  signal msg_index_r  : std_logic_vector(15 downto 0);
  signal msg_seqnum_r : std_logic_vector(63 downto 0);
  signal msg_type_r   : std_logic_vector(7 downto 0);
  signal msg_len_out_r: std_logic_vector(15 downto 0);
  signal msg_fields_r : std_logic_vector(C_MSG_FIELDS_W-1 downto 0);
  signal msg_stat_r   : std_logic_vector(C_MSG_STATUS_W-1 downto 0);
  signal pkt_fields_r : std_logic_vector(C_ITCH_PKT_W-1 downto 0);

  signal pkt_done_r      : std_logic;
  signal pkt_count_r     : std_logic_vector(15 downto 0);
  signal pkt_mismatch_r  : std_logic;

  ------------------------------------------------------------------------------
  -- Upstream bus and data path, one register stage each
  ------------------------------------------------------------------------------
  signal s_fields_r : std_logic_vector(C_MOLD_BUS_W-1 downto 0);
  signal tdata_r    : std_logic_vector(63 downto 0);
  signal tkeep_r    : std_logic_vector(7 downto 0);
  signal tvalid_r   : std_logic;
  signal tlast_r    : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Backpressure: parsers never stall.
  ------------------------------------------------------------------------------
  s_axis_tready <= '1';

  ------------------------------------------------------------------------------
  -- Tag select and payload start position
  ------------------------------------------------------------------------------
  vlan_c <= eth_vlan_present(s_fields);

  first_beat <= to_unsigned(8, 4) when vlan_c = '1' else to_unsigned(7, 4);
  first_lane <= to_unsigned(2, 3) when vlan_c = '1' else to_unsigned(6, 3);

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
  -- Stage 1: framing
  --
  -- Walks the eight bytes of the beat through the length/data state machine.
  -- The loop is unrolled by synthesis; the variables carry state from one
  -- byte to the next within the cycle.
  ------------------------------------------------------------------------------
  p_frame : process (clk)
    variable v_phase  : std_logic_vector(1 downto 0);
    variable v_len_hi : std_logic_vector(7 downto 0);
    variable v_len    : unsigned(15 downto 0);
    variable v_rem    : unsigned(15 downto 0);
    variable v_idx    : unsigned(15 downto 0);
    variable v_buf    : byte_array_t;
    variable v_index  : unsigned(15 downto 0);
    variable v_secs   : std_logic_vector(31 downto 0);

    variable v_b      : std_logic_vector(7 downto 0);
    variable v_len16  : std_logic_vector(15 downto 0);
    variable v_type   : std_logic_vector(7 downto 0);
    variable v_active : boolean;

    variable v_emitted : boolean;
    variable v_multi   : std_logic;
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        beat_cnt      <= (others => '0');
        phase_r       <= PH_LEN_HI;
        len_hi_r      <= (others => '0');
        msg_len_r     <= (others => '0');
        rem_r         <= (others => '0');
        byte_idx_r    <= (others => '0');
        index_r       <= (others => '0');
        seconds_r     <= (others => '0');
        buf_r         <= (others => (others => '0'));
        cmp_valid_r   <= '0';
        cmp_stat_r    <= (others => '0');
        cmp_fields_r  <= (others => '0');
        pkt_done_r    <= '0';
        pkt_count_r   <= (others => '0');
        pkt_mismatch_r<= '0';
      else

        -- single-cycle strobes
        cmp_valid_r <= '0';
        pkt_done_r  <= '0';

        if s_axis_tvalid = '1' then

          --------------------------------------------------------------------
          -- Load framing state into variables
          --------------------------------------------------------------------
          v_phase  := phase_r;
          v_len_hi := len_hi_r;
          v_len    := msg_len_r;
          v_rem    := rem_r;
          v_idx    := byte_idx_r;
          v_buf    := buf_r;
          v_index  := index_r;
          v_secs   := seconds_r;

          v_emitted := false;
          v_multi   := '0';

          -- New packet: clear framing state
          if beat_cnt = 0 then
            v_phase := PH_LEN_HI;
            v_index := (others => '0');
            v_rem   := (others => '0');
            v_idx   := (others => '0');
          end if;

          --------------------------------------------------------------------
          -- Beat position tracking
          --------------------------------------------------------------------
          if s_axis_tlast = '1' then
            beat_cnt <= (others => '0');
          elsif beat_cnt /= 15 then
            beat_cnt <= beat_cnt + 1;
          end if;

          --------------------------------------------------------------------
          -- Walk the eight bytes
          --------------------------------------------------------------------
          for i in 0 to 7 loop

            -- Is this byte part of the ITCH payload, and actually present?
            v_active := false;
            if s_axis_tkeep(i) = '1' then
              if beat_cnt > first_beat then
                v_active := true;
              elsif beat_cnt = first_beat then
                v_active := (i >= to_integer(first_lane));
              end if;
            end if;

            if v_active then
              v_b := bsel(s_axis_tdata, i);

              case v_phase is

                when PH_LEN_HI =>
                  v_len_hi := v_b;
                  v_phase  := PH_LEN_LO;

                when PH_LEN_LO =>
                  -- Explicit slices, not concatenation: declaring
                  -- byte_array_t as an array of std_logic_vector creates an
                  -- implicit "&" returning byte_array_t, which makes
                  -- v_len_hi & v_b ambiguous.
                  v_len16(15 downto 8) := v_len_hi;
                  v_len16(7 downto 0)  := v_b;
                  v_len := unsigned(v_len16);
                  v_rem := unsigned(v_len16);
                  v_idx := (others => '0');
                  if v_len16 = x"0000" then
                    -- zero-length message: complete immediately
                    v_index := v_index + 1;
                    v_phase := PH_LEN_HI;
                  else
                    v_phase := PH_DATA;
                  end if;

                when others =>                     -- PH_DATA
                  -- Assemble only what a decoded message can need. R (113)
                  -- and M (261) are framed and counted but not assembled.
                  if v_idx < C_MSG_BUF_BYTES then
                    v_buf(to_integer(v_idx(5 downto 0))) := v_b;
                  end if;
                  v_idx := v_idx + 1;
                  v_rem := v_rem - 1;

                  if v_rem = 0 then
                    ----------------------------------------------------------
                    -- Message complete
                    ----------------------------------------------------------
                    v_type := v_buf(0);

                    if v_type = C_TYPE_T then
                      -- Clock state, not a message. No event emitted.
                      v_secs(31 downto 24) := v_buf(1);
                      v_secs(23 downto 16) := v_buf(2);
                      v_secs(15 downto  8) := v_buf(3);
                      v_secs( 7 downto  0) := v_buf(4);
                    else
                      if v_emitted then
                        -- Cannot happen with T special-cased, since T is the
                        -- only sub-8-byte block. Flagged rather than assumed.
                        v_multi := '1';
                      else
                        v_emitted   := true;
                        cmp_buf_r    <= v_buf;
                        cmp_type_r   <= v_type;
                        cmp_len_r    <= v_len;
                        cmp_index_r  <= v_index;
                        cmp_fields_r <= s_fields;   -- context AT completion
                        cmp_valid_r  <= '1';

                        cmp_stat_r <= (others => '0');
                        cmp_stat_r(C_ST_DECODED) <=
                          '1' when is_decoded_type(v_type) else '0';
                        cmp_stat_r(C_ST_UNKNOWN_TYPE) <=
                          '1' when spec_msg_len(v_type) = 0 else '0';
                        cmp_stat_r(C_ST_LEN_MISMATCH) <=
                          '0' when to_integer(v_len) = spec_msg_len(v_type)
                          else '1';
                      end if;
                    end if;

                    v_index := v_index + 1;
                    v_phase := PH_LEN_HI;
                  end if;

              end case;
            end if;
          end loop;

          --------------------------------------------------------------------
          -- End of packet
          --------------------------------------------------------------------
          if s_axis_tlast = '1' then

            -- A message cut short by the end of the frame
            if v_phase /= PH_LEN_HI then
              if v_emitted then
                v_multi := '1';       -- first cut: the short message is lost
              else
                v_emitted   := true;
                cmp_buf_r    <= v_buf;
                cmp_type_r   <= v_buf(0);
                cmp_len_r    <= v_len;
                cmp_index_r  <= v_index;
                cmp_fields_r <= s_fields;   -- context AT completion
                cmp_valid_r  <= '1';

                cmp_stat_r <= (others => '0');
                cmp_stat_r(C_ST_MSG_TRUNCATED) <= '1';
                cmp_stat_r(C_ST_UNKNOWN_TYPE)  <=
                  '1' when spec_msg_len(v_buf(0)) = 0 else '0';

                v_index := v_index + 1;
              end if;
            end if;

            pkt_done_r  <= '1';
            pkt_count_r <= std_logic_vector(v_index);
            if v_index /= unsigned(mold_message_count(s_fields)) then
              pkt_mismatch_r <= '1';
            else
              pkt_mismatch_r <= '0';
            end if;
          end if;

          if v_multi = '1' then
            cmp_stat_r(C_ST_MULTI_COMPLETE) <= '1';
          end if;

          --------------------------------------------------------------------
          -- Store framing state back
          --------------------------------------------------------------------
          phase_r    <= v_phase;
          len_hi_r   <= v_len_hi;
          msg_len_r  <= v_len;
          rem_r      <= v_rem;
          byte_idx_r <= v_idx;
          buf_r      <= v_buf;
          index_r    <= v_index;
          seconds_r  <= v_secs;

        end if;
      end if;
    end if;
  end process p_frame;

  ------------------------------------------------------------------------------
  -- Stage 2: decode and emit
  --
  -- Kept separate so the type mux and field extraction sit OUTSIDE the
  -- framing feedback loop. Costs one cycle of event latency.
  ------------------------------------------------------------------------------
  p_emit : process (clk)
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
      else
        msg_valid_r <= cmp_valid_r;

        if cmp_valid_r = '1' then
          msg_index_r   <= std_logic_vector(cmp_index_r);
          msg_type_r    <= cmp_type_r;
          msg_len_out_r <= std_logic_vector(cmp_len_r);
          msg_stat_r    <= cmp_stat_r;

          -- Context latched when the message completed, NOT the current bus.
          pkt_fields_r  <= cmp_fields_r;

          -- Sequence of this message = mold sequence + index within packet
          msg_seqnum_r <= std_logic_vector(
            unsigned(mold_sequence_num(cmp_fields_r)) +
            resize(cmp_index_r, 64));

          if cmp_stat_r(C_ST_DECODED) = '1' then
            msg_fields_r <= decode_msg(to_slv(cmp_buf_r), cmp_type_r);
          else
            msg_fields_r <= (others => '0');
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

  -- Upstream context, captured when the message completed and re-presented
  -- with every event
  pkt_fields <= pkt_fields_r;

  exchange_seconds <= seconds_r;

  pkt_done           <= pkt_done_r;
  pkt_msg_count      <= pkt_count_r;
  pkt_count_mismatch <= pkt_mismatch_r;

end architecture rtl;
