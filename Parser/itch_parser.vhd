--------------------------------------------------------------------------------
-- itch_parser
--
-- Stage 5 of the market-data header parser pipeline.
--
-- ============================================================================
-- WHY THIS IS NOT THE PREVIOUS DESIGN
-- ============================================================================
-- The old parser framed arithmetically inside a single feedback loop:
--
--     start -> mux 2 length bytes out of the view -> 18-bit add -> compare
--           -> next start -> register
--
-- and did it TWICE per beat. That is a recurrence, so no amount of pipelining
-- shortens it, and it did not close at 161 MHz on Virtex-7.
--
-- Here the adder is moved OUT of the loop. Every cycle, for all eight lanes of
-- the beat in win_r(0), the next-block offset is computed SPECULATIVELY:
--
--     nxt(o) = o + len(o) + 2      for o = 0 .. 7, in parallel
--
-- The two length bytes at lane o are a STATIC SLICE of the 16-byte view, so
-- there is no mux in front of the adder - just eight independent 10-bit adds.
-- The results are registered as a lookup table, and the framing recurrence
-- degenerates to a pointer chase through registered values:
--
--     if rem = 0 then  (rem, lane) <= tbl(lane);   -- one 8:1 mux
--     else             rem         <= rem - 1;     -- one 7-bit decrement
--
-- No adder, no length read, no compare chain. Three logic levels.
--
-- ============================================================================
-- TWO FACTS THAT MAKE IT WORK - both provable from spec_msg_len
-- ============================================================================
-- 1. A SECOND BLOCK CAN ONLY START IN THE SAME BEAT IF THE FIRST IS 'T'.
--    A second start needs nxt(o) <= 7, i.e. len <= 5 - o. T is the only type
--    with len <= 5 (it is 5), which forces o = 0. So the second hop is
--    precomputed in the speculative stage as nxt(nxt(o)) and a THIRD hop is
--    impossible: two blocks are at least 7 wire bytes each, so the third
--    start is at least 14 - always outside the beat.
--
-- 2. NO IN-SCOPE MESSAGE EVER COMPLETES IN THE BEAT IT STARTS.
--    The shortest in-scope type is D at 18 + 2 = 20 wire bytes. So at most
--    ONE message can be retired per beat, one command can be produced per
--    cycle, and NO elastic buffering is needed anywhere in the chain.
--
-- ============================================================================
-- SCOPE
-- ============================================================================
-- A, U, E and D are decoded and emitted. T is framed and its seconds value is
-- captured, but no event is emitted. Every other type is framed (so the length
-- chain stays correct) and discarded.
--
-- F and C are DELIBERATELY OUT OF SCOPE per the current requirement. They are
-- book-affecting types: F is an Add Order carrying a participant ID and C is
-- an Order Executed at a price differing from the display price. Re-enabling
-- them is a one-line edit in each of f_in_scope and f_decode_scoped - both are
-- marked. Nothing else changes, and no logic depth is added, because A/F and
-- E/C share their byte layouts up to the fields the book needs.
--
-- ============================================================================
-- LATENCY AND THROUGHPUT
-- ============================================================================
--   one 8-byte beat per cycle, s_axis_tready tied high
--   THREE cycles from the arrival of the beat that completes a message to
--   msg_valid; book_input_stage adds one, for four to the order FIFO
--   one message per cycle sustained
--
-- There is no AXI-Stream master. The packet bytes stop here.
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

    -- Upstream field bus -----------------------------------------------------
    s_fields       : in  std_logic_vector(C_MOLD_BUS_W-1 downto 0);

    -- Per-message event ------------------------------------------------------
    msg_valid      : out std_logic;
    msg_type       : out std_logic_vector(7 downto 0);
    msg_fields     : out std_logic_vector(C_MSG_FIELDS_W-1 downto 0);
    msg_index      : out std_logic_vector(15 downto 0);
    msg_seqnum     : out std_logic_vector(63 downto 0);
    msg_length     : out std_logic_vector(15 downto 0);
    msg_status     : out std_logic_vector(C_MSG_STATUS_W-1 downto 0);
    pkt_fields     : out std_logic_vector(C_ITCH_PKT_W-1 downto 0);

    -- Exchange clock, from the most recent Seconds message -------------------
    exchange_seconds : out std_logic_vector(31 downto 0);

    -- Packet-level status ----------------------------------------------------
    pkt_done         : out std_logic;
    pkt_msg_count    : out std_logic_vector(15 downto 0)   -- as framed
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

  type byte_t is array (natural range <>) of std_logic_vector(7 downto 0);

  ------------------------------------------------------------------------------
  -- Big-endian field of n bytes starting at message byte i.
  --
  -- Written as a loop rather than a concatenation chain: byte_t, t_typ8 and
  -- win_t all have std_logic_vector as their element type, which makes a bare
  -- "&" between two 8-bit vectors ambiguous anywhere in this architecture.
  ------------------------------------------------------------------------------
  function be (buf : std_logic_vector; i : natural; n : natural)
    return std_logic_vector is
    variable r : std_logic_vector(8*n - 1 downto 0);
  begin
    for k in 0 to n-1 loop
      r(8*(n-1-k) + 7 downto 8*(n-1-k)) := mb(buf, i + k);
    end loop;
    return r;
  end function;

  ------------------------------------------------------------------------------
  -- Rolling window of raw beats. win_r(0) is the NEWEST.
  --
  -- Depth 12 covers the deepest read: an E message starting at lane 7 puts its
  -- start beat at window index 8, and the readout runs six beats newer than
  -- that. Indices are taken mod C_WIN_BEATS, so a short message harmlessly
  -- wraps onto stale beats it never reads.
  ------------------------------------------------------------------------------
  constant C_WIN_BEATS : natural := 12;

  type win_t is array (0 to C_WIN_BEATS-1) of std_logic_vector(63 downto 0);
  signal win_r : win_t := (others => (others => '0'));

  ------------------------------------------------------------------------------
  -- Extraction width.
  --
  -- The deepest byte any in-scope decode reads is 35 (exchange order type on
  -- A/U). 40 bytes from message byte 0 covers it with margin and keeps the
  -- rotate small.
  ------------------------------------------------------------------------------
  constant C_EXT_BYTES : natural := 40;
  constant C_EXT_W     : natural := C_EXT_BYTES * 8;

  ------------------------------------------------------------------------------
  -- Speculative table geometry
  ------------------------------------------------------------------------------
  constant C_REM_W  : natural := 7;    -- beats to the next block start, 0..127
  constant C_NXT_W  : natural := 10;   -- offset within the beat frame, 0..1023
  constant C_LEN_W  : natural := 9;    -- length saturates here; M (261) fits

  type t_typ8  is array (0 to 7) of std_logic_vector(7 downto 0);
  type t_len16 is array (0 to 7) of unsigned(15 downto 0);
  type t_nxt   is array (0 to 7) of unsigned(C_NXT_W-1 downto 0);
  type t_rem   is array (0 to 7) of unsigned(C_REM_W-1 downto 0);
  type t_l3    is array (0 to 7) of unsigned(2 downto 0);
  type t_b4    is array (0 to 7) of unsigned(3 downto 0);

  -- Registered table. Every entry describes the block that is STILL IN FLIGHT
  -- after this beat, i.e. the second one when a 'T' was absorbed by the hop.
  signal tb_typ    : t_typ8  := (others => (others => '0'));
  signal tb_len    : t_len16 := (others => (others => '0'));
  signal tb_rem    : t_rem   := (others => (others => '0'));
  signal tb_lane   : t_l3    := (others => (others => '0'));
  signal tb_slane  : t_l3    := (others => (others => '0'));
  type t_secs is array (0 to 7) of std_logic_vector(31 downto 0);
  signal tb_secs   : t_secs := (others => (others => '0'));
  signal tb_scope  : std_logic_vector(0 to 7) := (others => '0');
  signal tb_ist    : std_logic_vector(0 to 7) := (others => '0');
  signal tb_lenok  : std_logic_vector(0 to 7) := (others => '0');
  signal tb_two    : std_logic_vector(0 to 7) := (others => '0');

  -- A 'T' absorbed by the hop is retired without ever getting an in-flight
  -- record, so its seconds value is captured here instead. The hop can only
  -- happen at lane 0 (see the proof in the header), so this is one static
  -- slice rather than a per-lane table.
  signal t0_hit_r  : std_logic := '0';
  signal t0_secs_r : std_logic_vector(31 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- Framing-domain replicas of the sideband.
  --
  -- The table registered at the end of cycle W describes the beat that was in
  -- win_r(0) DURING W, which is win_r(1) during W+1. So tlast, tkeep and the
  -- field bus need a two-deep delay on the same enable as the window, while
  -- the framing valid is a plain one-cycle delay of tvalid: the window
  -- advances one beat per valid cycle, so each beat appears as win_r(0)
  -- exactly once and is framed exactly once.
  ------------------------------------------------------------------------------
  -- Framing beat X needs beat X+1 for lookahead, so the LAST beat of a packet
  -- can only be framed once something follows it. flush_r manufactures that
  -- one extra advance after tlast; the bytes it shifts in are garbage, but
  -- they can only reach a block starting at lane 6 or 7 of the final beat,
  -- which is truncated and dropped anyway.
  signal flush_r : std_logic := '0';
  signal adv_c   : std_logic;

  signal in_beat   : unsigned(3 downto 0) := (others => '0');
  signal k1_beat   : unsigned(3 downto 0) := (others => '0');
  signal k1_last   : std_logic := '0';
  signal k1_keep   : std_logic_vector(7 downto 0) := (others => '0');
  signal k1_fields : std_logic_vector(C_MOLD_BUS_W-1 downto 0) := (others => '0');

  signal fv_valid  : std_logic := '0';
  signal fv_beat   : unsigned(3 downto 0) := (others => '0');
  signal fv_last   : std_logic := '0';
  signal fv_keep   : std_logic_vector(7 downto 0) := (others => '0');
  signal fv_fields : std_logic_vector(C_MOLD_BUS_W-1 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- THE FRAMING RECURRENCE - the only loop in the design
  --
  --   rem / lane   the next block starts 8*rem + lane bytes into this beat
  --   active       inside the Mold payload
  --   armed        an in-flight block exists; fl_* describe it
  ------------------------------------------------------------------------------
  signal active_r : std_logic := '0';
  signal rem_r    : unsigned(C_REM_W-1 downto 0) := (others => '0');
  signal lane_r   : unsigned(2 downto 0) := (others => '0');
  signal armed_r  : std_logic := '0';

  -- In-flight record, captured when the block starts.
  signal fl_typ_r    : std_logic_vector(7 downto 0) := (others => '0');
  signal fl_len_r    : unsigned(15 downto 0) := (others => '0');
  signal fl_slane_r  : unsigned(2 downto 0) := (others => '0');
  -- Window index of the block's START beat, counted rather than predicted.
  -- Set to 1 when the block is framed and incremented every framing beat, so
  -- at retire time win_r(fl_base_r) IS the start beat - with no correction for
  -- the tail case and, more importantly, no arithmetic in front of the 12:1
  -- beat mux. This is the select for the deepest datapath in the design, so it
  -- has to arrive as a bare register output.
  signal fl_base_r   : unsigned(3 downto 0) := (others => '0');
  signal fl_scope_r  : std_logic := '0';
  signal fl_lenok_r  : std_logic := '0';
  signal fl_idx_r    : unsigned(15 downto 0) := (others => '0');
  signal fl_seq_r    : unsigned(63 downto 0) := (others => '0');

  signal index_r   : unsigned(15 downto 0) := (others => '0');
  signal seq_r     : unsigned(63 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- Retire decisions. Read by the framing process AND by the extract process,
  -- which runs in the SAME cycle off the fl_* registers - that is where the
  -- fourth cycle of end-to-end latency comes back.
  ------------------------------------------------------------------------------
  signal sl_c       : unsigned(2 downto 0);
  signal end_ok_c   : std_logic;
  signal start_ok_c : std_logic;
  signal surv_ok_c  : std_logic;
  signal first_ok_c : std_logic;
  signal ret_norm_c : std_logic;
  signal ret_tail_c : std_logic;
  signal load_c     : std_logic;
  signal retire_c   : std_logic;

  signal vlan_c       : std_logic;
  signal first_beat_c : unsigned(3 downto 0);
  signal first_lane_c : unsigned(2 downto 0);
  signal pay_arm_c    : std_logic;

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------
  signal msg_valid_r  : std_logic := '0';
  signal msg_type_r   : std_logic_vector(7 downto 0) := (others => '0');
  signal msg_fields_r : std_logic_vector(C_MSG_FIELDS_W-1 downto 0) := (others => '0');
  signal msg_index_r  : std_logic_vector(15 downto 0) := (others => '0');
  signal msg_seq_r    : std_logic_vector(63 downto 0) := (others => '0');
  signal msg_len_r    : std_logic_vector(15 downto 0) := (others => '0');
  signal msg_stat_r   : std_logic_vector(C_MSG_STATUS_W-1 downto 0) := (others => '0');
  signal pkt_fields_r : std_logic_vector(C_ITCH_PKT_W-1 downto 0) := (others => '0');
  signal seconds_r    : std_logic_vector(31 downto 0) := (others => '0');
  signal pkt_done_r   : std_logic := '0';
  signal pkt_count_r  : std_logic_vector(15 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- Types that occupy the in-flight record and are extracted at retire time.
  --
  -- T is deliberately NOT here. At 5 + 2 = 7 wire bytes it is the one type
  -- short enough to start AND finish inside a single beat, which would break
  -- the invariant that at most one message retires per beat - a trailing T
  -- would be loaded in the final beat and then dropped by the packet end
  -- before it could be retired. Seconds is captured from the speculative
  -- table at LOAD time instead, which needs no in-flight slot at all.
  --
  -- Every type in here is at least 20 wire bytes, so no two can end in the
  -- same 8-byte beat.
  --
  -- ADD F AND C HERE to bring them back into scope.
  ------------------------------------------------------------------------------
  function f_in_scope (t : std_logic_vector(7 downto 0)) return boolean is
  begin
    return t = C_TYPE_A or t = C_TYPE_U or t = C_TYPE_E or t = C_TYPE_D;
  end function;

  ------------------------------------------------------------------------------
  -- Fixed-offset decode, restricted to the in-scope types.
  --
  -- Produces the standard C_FLD_* layout from itch_parser_pkg so the field bus
  -- is unchanged, but only populates what A/U/E/D actually carry. MATCHID,
  -- POWNER, PCP, PRINT and CROSS stay zero because the types that carry them
  -- (F, C, P) are out of scope.
  --
  -- This is decode_msg with the out-of-scope arms removed; it exists here
  -- rather than in the package because the extraction buffer is 40 bytes and
  -- decode_msg indexes to byte 57 for C.
  ------------------------------------------------------------------------------
  function f_decode_scoped (buf : std_logic_vector;
                            t   : std_logic_vector(7 downto 0))
    return std_logic_vector is
    variable f : std_logic_vector(C_MSG_FIELDS_W-1 downto 0) := (others => '0');
  begin
    -- Identity block, byte-identical across A, U, E and D
    f(C_FLD_TS_NS_LO  + 31 downto C_FLD_TS_NS_LO)  := be(buf,  1, 4);
    f(C_FLD_ORDID_LO  + 63 downto C_FLD_ORDID_LO)  := be(buf,  5, 8);
    f(C_FLD_BOOKID_LO + 31 downto C_FLD_BOOKID_LO) := be(buf, 13, 4);
    f(C_FLD_SIDE_LO   +  7 downto C_FLD_SIDE_LO)   := mb(buf, 17);

    case t is

      -- A: Add Order (37).  U: Order Replace (36).
      -- ADD C_TYPE_F HERE: same layout, plus owner at 37..43.
      when C_TYPE_A | C_TYPE_U =>
        f(C_FLD_POS_LO    + 31 downto C_FLD_POS_LO)    := be(buf, 18, 4);
        f(C_FLD_QTY_LO    + 63 downto C_FLD_QTY_LO)    := be(buf, 22, 8);
        f(C_FLD_PRICE_LO  + 31 downto C_FLD_PRICE_LO)  := be(buf, 30, 4);
        f(C_FLD_EXTYPE_LO + 15 downto C_FLD_EXTYPE_LO) := be(buf, 34, 2);
        if t = C_TYPE_A then
          f(C_FLD_LOT_LO + 7 downto C_FLD_LOT_LO) := mb(buf, 36);
        end if;

      -- E: Order Executed (52). Quantity is an executed DELTA.
      -- ADD C_TYPE_C HERE: same layout to byte 25, plus price at 52..55 -
      -- which needs C_EXT_BYTES raised to 56.
      when C_TYPE_E =>
        f(C_FLD_QTY_LO + 63 downto C_FLD_QTY_LO) := be(buf, 18, 8);

      -- D: Order Delete (18). Identity only, already assembled above.
      when others =>
        null;

    end case;

    return f;
  end function;

begin

  ------------------------------------------------------------------------------
  -- Backpressure: parsers never stall.
  ------------------------------------------------------------------------------
  s_axis_tready <= '1';

  ------------------------------------------------------------------------------
  -- The window and the framing-domain sideband replicas. Both advance on the
  -- same enable so the table and its tlast/tkeep stay in step.
  ------------------------------------------------------------------------------
  adv_c <= s_axis_tvalid or flush_r;

  p_window : process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        win_r     <= (others => (others => '0'));
        flush_r   <= '0';
        in_beat   <= (others => '0');
        k1_beat   <= (others => '0');
        k1_last   <= '0';
        k1_keep   <= (others => '0');
        k1_fields <= (others => '0');
        fv_beat   <= (others => '0');
        fv_last   <= '0';
        fv_keep   <= (others => '0');
        fv_fields <= (others => '0');
        fv_valid  <= '0';
      else
        flush_r  <= s_axis_tvalid and s_axis_tlast;
        fv_valid <= adv_c;

        if s_axis_tvalid = '1' then
          if s_axis_tlast = '1' then
            in_beat <= (others => '0');
          elsif in_beat /= 15 then
            in_beat <= in_beat + 1;
          end if;
        end if;

        if adv_c = '1' then
          win_r     <= s_axis_tdata & win_r(0 to C_WIN_BEATS-2);
          k1_beat   <= in_beat;
          k1_last   <= s_axis_tlast;
          k1_keep   <= s_axis_tkeep;
          k1_fields <= s_fields;
          fv_beat   <= k1_beat;
          fv_last   <= k1_last;
          fv_keep   <= k1_keep;
          fv_fields <= k1_fields;
        end if;
      end if;
    end if;
  end process p_window;

  ------------------------------------------------------------------------------
  -- SPECULATIVE STAGE
  --
  -- Eight independent length reads and adds, then the two-hop composition.
  -- Everything here is feed-forward from win_r(0) and the incoming beat, so it
  -- can take a further pipeline stage if it ever needs one.
  ------------------------------------------------------------------------------
  p_spec : process (clk)
    variable v_view : byte_t(0 to 15);
    variable v_len  : t_len16;
    variable v_typ  : t_typ8;
    variable v_sat  : unsigned(C_LEN_W-1 downto 0);
    variable v_nxt  : t_nxt;
    variable v_hop  : std_logic_vector(0 to 7);
    variable v_j    : integer range 0 to 7;
    variable c_typ  : std_logic_vector(7 downto 0);
    variable c_len  : unsigned(15 downto 0);
    variable c_nxt  : unsigned(C_NXT_W-1 downto 0);
    variable c_sl   : integer range 0 to 7;
    variable v_p    : unsigned(C_NXT_W-1 downto 0);
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        tb_typ    <= (others => (others => '0'));
        tb_len    <= (others => (others => '0'));
        tb_rem    <= (others => (others => '0'));
        tb_lane   <= (others => (others => '0'));
        tb_slane  <= (others => (others => '0'));
        tb_secs   <= (others => (others => '0'));
        tb_scope  <= (others => '0');
        tb_ist    <= (others => '0');
        tb_lenok  <= (others => '0');
        tb_two    <= (others => '0');
        t0_hit_r  <= '0';
        t0_secs_r <= (others => '0');
      elsif adv_c = '1' then

        -- 16-byte view: the beat being framed, plus one beat of lookahead so a
        -- length field at lane 6 or 7 is an ordinary static slice.
        for i in 0 to 7 loop
          v_view(i)     := bsel(win_r(0), i);
          v_view(i + 8) := bsel(s_axis_tdata, i);
        end loop;

        ----------------------------------------------------------------------
        -- Pass A: eight parallel speculative reads. No mux in front of the
        -- adders - v_view(o) and v_view(o+1) are constant slices for each o.
        ----------------------------------------------------------------------
        for o in 0 to 7 loop
          v_len(o)(15 downto 8) := unsigned(v_view(o));
          v_len(o)( 7 downto 0) := unsigned(v_view(o + 1));
          v_typ(o) := v_view(o + 2);

          -- Saturate so a garbage length cannot wrap the beat counter. Real
          -- lengths reach 261 (M), which fits in C_LEN_W.
          if v_len(o)(15 downto C_LEN_W) /= 0 then
            v_sat := (others => '1');
          else
            v_sat := unsigned(v_len(o)(C_LEN_W-1 downto 0));
          end if;

          v_nxt(o) := to_unsigned(o, C_NXT_W) + resize(v_sat, C_NXT_W)
                    + to_unsigned(2, C_NXT_W);

          if v_nxt(o) <= 7 then
            v_hop(o) := '1';
          else
            v_hop(o) := '0';
          end if;
        end loop;

        ----------------------------------------------------------------------
        -- Pass B: compose the hop. Every entry ends up describing the block
        -- still in flight after this beat.
        ----------------------------------------------------------------------
        for o in 0 to 7 loop
          if v_hop(o) = '1' then
            v_j    := to_integer(v_nxt(o)(2 downto 0));
            c_typ  := v_typ(v_j);
            c_len  := v_len(v_j);
            c_nxt  := v_nxt(v_j);
            c_sl   := v_j;
          else
            c_typ  := v_typ(o);
            c_len  := v_len(o);
            c_nxt  := v_nxt(o);
            c_sl   := o;
          end if;

          -- c_nxt is where the pointer lands, in this beat's frame. It is
          -- always >= 8: a non-hop entry did not fit in the beat, and a hopped
          -- entry is at least 14. So the shift into the next beat's frame
          -- never goes negative.
          v_p  := c_nxt - to_unsigned(8, C_NXT_W);
          tb_rem(o)  <= resize(v_p(C_NXT_W-1 downto 3), C_REM_W);
          tb_lane(o) <= v_p(2 downto 0);

          tb_typ(o)   <= c_typ;
          tb_len(o)   <= c_len;
          tb_slane(o) <= to_unsigned(c_sl, 3);
          tb_two(o)   <= v_hop(o);

          -- Seconds is message bytes 1..4, i.e. view(c_sl+3 .. c_sl+6). c_sl
          -- is at most 7, so this never leaves the 16-byte view. A T that ran
          -- past the end of the beat would be truncated and is not a message.
          tb_secs(o)(31 downto 24) <= v_view(c_sl + 3);
          tb_secs(o)(23 downto 16) <= v_view(c_sl + 4);
          tb_secs(o)(15 downto  8) <= v_view(c_sl + 5);
          tb_secs(o)( 7 downto  0) <= v_view(c_sl + 6);

          if f_in_scope(c_typ) then
            tb_scope(o) <= '1';
          else
            tb_scope(o) <= '0';
          end if;

          if c_typ = C_TYPE_T then
            tb_ist(o) <= '1';
          else
            tb_ist(o) <= '0';
          end if;

          if to_integer(c_len) = spec_msg_len(c_typ) then
            tb_lenok(o) <= '1';
          else
            tb_lenok(o) <= '0';
          end if;
        end loop;

        ----------------------------------------------------------------------
        -- A 'T' swallowed by the hop. Only reachable at lane 0, so the seconds
        -- bytes (message bytes 1..4 = view 3..6) are a single static slice.
        ----------------------------------------------------------------------
        if v_hop(0) = '1' and v_typ(0) = C_TYPE_T then
          t0_hit_r  <= '1';
          t0_secs_r(31 downto 24) <= v_view(3);
          t0_secs_r(23 downto 16) <= v_view(4);
          t0_secs_r(15 downto  8) <= v_view(5);
          t0_secs_r( 7 downto  0) <= v_view(6);
        else
          t0_hit_r <= '0';
        end if;

      end if;
    end if;
  end process p_spec;

  ------------------------------------------------------------------------------
  -- Payload start and end-of-packet guards
  ------------------------------------------------------------------------------
  vlan_c       <= eth_vlan_present(fv_fields);
  first_beat_c <= to_unsigned(8, 4) when vlan_c = '1' else to_unsigned(7, 4);
  first_lane_c <= to_unsigned(2, 3) when vlan_c = '1' else to_unsigned(6, 3);

  -- Armed one beat early so the state is already (rem = 0, lane = first_lane)
  -- when the first payload beat is framed. Keeping the override off the
  -- recurrence input this way costs one 2:1 mux, not a comparator.
  pay_arm_c <= '1' when fv_valid = '1' and active_r = '0'
                    and fv_beat = (first_beat_c - 1)
               else '0';

  ------------------------------------------------------------------------------
  -- End-of-packet guards.
  --
  -- These read fv_keep BIT BY BIT rather than decoding a highest-valid-lane and
  -- comparing against it. tkeep is contiguous, so fv_keep(n) already answers
  -- "is the byte at lane n real", and an 8:1 mux of registered bits replaces a
  -- priority encoder, an increment and a 4-bit comparator.
  --
  -- That matters because these signals gate the framing recurrence as well as
  -- the emit stage: anything deep here lands directly on the rem_r / lane_r
  -- path, which is the one path in the design that has to stay shallow.
  ------------------------------------------------------------------------------

  -- Start lane of the block that SURVIVES this beat. It differs from lane_r
  -- only when a hop absorbed a T ahead of it.
  sl_c <= tb_slane(to_integer(lane_r));

  -- The in-flight block's last byte sits at lane_r - 1. When lane_r is 0 that
  -- is the previous beat, which is always fully populated.
  end_ok_c <= '1' when fv_last = '0' or lane_r = 0
              else fv_keep(to_integer(lane_r) - 1);

  -- A block starts here at all: its first byte must be inside the packet.
  -- Without this, Ethernet padding frames as a stream of zero-length blocks
  -- and inflates pkt_msg_count.
  start_ok_c <= '1' when fv_last = '0' else fv_keep(to_integer(lane_r));

  -- ...and separately, whether the SURVIVING block exists. On the last beat a
  -- hop can absorb a real T and leave the second block pointing past the end
  -- of the packet, in which case only the T is there.
  surv_ok_c <= '1' when fv_last = '0' else fv_keep(to_integer(sl_c));

  ret_norm_c <= '1' when fv_valid = '1' and active_r = '1' and rem_r = 0
                     and end_ok_c = '1'
                else '0';

  -- Tail case: the packet ends and the in-flight block finishes exactly on the
  -- last byte, so the pointer never lands and ret_norm_c never fires.
  ret_tail_c <= '1' when fv_valid = '1' and active_r = '1' and fv_last = '1'
                     and rem_r = 1 and lane_r = 0 and fv_keep(7) = '1'
                else '0';

  first_ok_c <= '1' when fv_valid = '1' and active_r = '1' and rem_r = 0
                     and start_ok_c = '1'
                else '0';

  load_c <= first_ok_c and surv_ok_c;

  retire_c <= (ret_norm_c or ret_tail_c) and armed_r and fl_scope_r;

  ------------------------------------------------------------------------------
  -- THE FRAMING RECURRENCE
  --
  -- One 8:1 mux of registered table entries, one 7-bit decrement, one 2:1
  -- select. Everything else in this process is off the loop.
  ------------------------------------------------------------------------------
  p_frame : process (clk)
    variable v_l   : integer range 0 to 7;
    variable v_idx : unsigned(15 downto 0);
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        active_r    <= '0';
        rem_r       <= (others => '0');
        lane_r      <= (others => '0');
        armed_r     <= '0';
        fl_typ_r    <= (others => '0');
        fl_len_r    <= (others => '0');
        fl_slane_r  <= (others => '0');
        fl_base_r   <= (others => '0');
        fl_scope_r  <= '0';
        fl_lenok_r  <= '0';
        fl_idx_r    <= (others => '0');
        fl_seq_r    <= (others => '0');
        index_r     <= (others => '0');
        seq_r       <= (others => '0');
        pkt_done_r  <= '0';
        pkt_count_r <= (others => '0');
      else

        pkt_done_r <= '0';

        if fv_valid = '1' then

          v_l   := to_integer(lane_r);
          v_idx := index_r;

          -- Age of the in-flight block, in framing beats. Saturates well above
          -- the in-scope maximum of 8 (E starting at lane 7).
          if fl_base_r /= 15 then
            fl_base_r <= fl_base_r + 1;
          end if;

          --------------------------------------------------------------------
          -- The pointer chase
          --------------------------------------------------------------------
          if rem_r /= 0 then
            rem_r <= rem_r - 1;

          elsif first_ok_c = '1' then

            if surv_ok_c = '1' then
              rem_r  <= tb_rem(v_l);
              lane_r <= tb_lane(v_l);

              armed_r     <= '1';
              -- 2, not 1: this value first takes effect on the beat AFTER the
              -- one the block was framed in, and win_r(1) is the beat being
              -- framed. So at a retire d beats later it reads 1 + d, which is
              -- exactly the window index of the start beat.
              fl_base_r   <= to_unsigned(2, 4);
              fl_typ_r    <= tb_typ(v_l);
              fl_len_r    <= tb_len(v_l);
              fl_slane_r  <= tb_slane(v_l);
              fl_scope_r  <= tb_scope(v_l);
              fl_lenok_r  <= tb_lenok(v_l);

              -- A hop absorbed a T in this same beat. That T consumed the
              -- CURRENT sequence number, so the surviving block takes the next
              -- one and the counters advance by two.
              if tb_two(v_l) = '1' then
                fl_idx_r <= index_r + 1;
                fl_seq_r <= seq_r + 1;
                v_idx    := index_r + 2;
                seq_r    <= seq_r + 2;
              else
                fl_idx_r <= index_r;
                fl_seq_r <= seq_r;
                v_idx    := index_r + 1;
                seq_r    <= seq_r + 1;
              end if;
            else
              -- Last beat, and only the hop's first block is inside the
              -- packet. Count that one and arm nothing.
              armed_r <= '0';
              v_idx   := index_r + 1;
              seq_r   <= seq_r + 1;
            end if;

            index_r <= v_idx;

          elsif ret_norm_c = '1' then
            -- Retired, but the next block starts outside the packet.
            armed_r <= '0';
          end if;

          if ret_tail_c = '1' then
            armed_r <= '0';
          end if;

          --------------------------------------------------------------------
          -- Payload start
          --------------------------------------------------------------------
          if pay_arm_c = '1' then
            active_r <= '1';
            armed_r  <= '0';
            rem_r    <= (others => '0');
            lane_r   <= first_lane_c;
            index_r  <= (others => '0');
            seq_r    <= unsigned(mold_sequence_num(fv_fields));
          end if;

          --------------------------------------------------------------------
          -- End of packet. Anything still in flight ran past the packet end
          -- and is dropped.
          --------------------------------------------------------------------
          if fv_last = '1' then
            active_r    <= '0';
            armed_r     <= '0';
            rem_r       <= (others => '0');
            lane_r      <= (others => '0');
            pkt_done_r  <= '1';
            -- v_idx, not index_r: a message can be loaded in this same beat.
            pkt_count_r <= std_logic_vector(v_idx);
          end if;

        end if;
      end if;
    end if;
  end process p_frame;

  ------------------------------------------------------------------------------
  -- EXTRACT AND DECODE
  --
  -- Runs in the SAME cycle as the recurrence, reading fl_slane_r and
  -- fl_base_r directly rather than waiting on a handoff register.
  --
  -- Every mux select on this chain - fl_base_r, fl_slane_r, fl_typ_r - is a
  -- bare register output. Nothing combinational sits in front of the beat
  -- selection, which is what keeps this path down to three mux stages.
  --
  -- Select-then-rotate, not rotate-then-select: seven whole beats are picked
  -- out of the window with a 12:1 mux, and only those 56 bytes are rotated by
  -- the start lane. That is shallower and far smaller than rotating the whole
  -- window.
  ------------------------------------------------------------------------------
  p_emit : process (clk)
    variable v_base : integer;
    variable v_idx  : integer;
    variable v_grp  : byte_t(0 to 55);
    variable v_lin  : byte_t(0 to 41);
    variable v_msg  : std_logic_vector(C_EXT_W-1 downto 0);
    variable v_sl   : integer range 0 to 7;
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        msg_valid_r  <= '0';
        msg_type_r   <= (others => '0');
        msg_fields_r <= (others => '0');
        msg_index_r  <= (others => '0');
        msg_seq_r    <= (others => '0');
        msg_len_r    <= (others => '0');
        msg_stat_r   <= (others => '0');
        pkt_fields_r <= (others => '0');
        seconds_r    <= (others => '0');
      else

        -- Exchange clock. Captured when the block is FRAMED, not when it
        -- retires: a T is short enough to be the last message in a packet and
        -- finish inside the final beat, where there is no later beat to retire
        -- it in. Both cases are gated on load_c so a speculative read that
        -- framing never selects cannot corrupt the clock.
        if first_ok_c = '1' then
          if load_c = '1' and tb_ist(to_integer(lane_r)) = '1' then
            -- The surviving block is a T. It sits after any T the hop
            -- absorbed, so it is the later clock value and wins.
            seconds_r <= tb_secs(to_integer(lane_r));
          elsif lane_r = 0 and t0_hit_r = '1' then
            -- Only the hop's T is inside the packet. A hop can only ever
            -- happen at lane 0.
            seconds_r <= t0_secs_r;
          end if;
        end if;

        -- The wide payload registers run on fv_valid, NOT on retire_c.
        --
        -- retire_c is several levels of end-of-packet logic deep, and gating
        -- msg_fields_r (512), pkt_fields_r (523) and the seqnum/index/length
        -- word with it put over 1100 clock enables on one late net - which
        -- cost more in fanout routing than the logic did. Only msg_valid_r
        -- needs it, so only msg_valid_r gets it. Downstream already qualifies
        -- the payload with msg_valid, so letting it carry junk on the cycles
        -- in between is free.
        --
        -- fv_valid is a plain registered copy of the advance strobe, so this
        -- enable is a register output straight to the CE pins with no logic in
        -- between, and the datapath still stops toggling between packets.
        if fv_valid = '1' then

          -- win_r(1) is the beat being framed and fl_base_r is how many beats
          -- ago the block started, so win_r(fl_base_r) is its start beat. True
          -- for the tail retire as well, which is why there is no correction
          -- term and no logic ahead of the mux.
          v_base := to_integer(fl_base_r);

          for k in 0 to 6 loop
            v_idx := (v_base - k) mod C_WIN_BEATS;
            for m in 0 to 7 loop
              v_grp(8*k + m) := bsel(win_r(v_idx), m);
            end loop;
          end loop;

          v_sl := to_integer(fl_slane_r);
          for i in 0 to 41 loop
            v_lin(i) := v_grp(i + v_sl);
          end loop;

          -- v_lin(0..1) are the Mold length prefix; message byte 0 is at 2.
          for m in 0 to C_EXT_BYTES-1 loop
            v_msg(8*m + 7 downto 8*m) := v_lin(m + 2);
          end loop;

          msg_type_r   <= fl_typ_r;
          msg_fields_r <= f_decode_scoped(v_msg, fl_typ_r);
          msg_index_r  <= std_logic_vector(fl_idx_r);
          msg_seq_r    <= std_logic_vector(fl_seq_r);
          msg_len_r    <= std_logic_vector(fl_len_r);
          pkt_fields_r <= fv_fields;

          msg_stat_r                    <= (others => '0');
          msg_stat_r(C_ST_DECODED)      <= '1';
          msg_stat_r(C_ST_LEN_MISMATCH) <= not fl_lenok_r;

        end if;

        -- The only register retire_c drives.
        msg_valid_r <= retire_c;
      end if;
    end if;
  end process p_emit;

  ------------------------------------------------------------------------------
  -- Outputs. All registered.
  ------------------------------------------------------------------------------
  msg_valid  <= msg_valid_r;
  msg_type   <= msg_type_r;
  msg_fields <= msg_fields_r;
  msg_index  <= msg_index_r;
  msg_seqnum <= msg_seq_r;
  msg_length <= msg_len_r;
  msg_status <= msg_stat_r;
  pkt_fields <= pkt_fields_r;

  exchange_seconds <= seconds_r;

  pkt_done      <= pkt_done_r;
  pkt_msg_count <= pkt_count_r;

end architecture rtl;
