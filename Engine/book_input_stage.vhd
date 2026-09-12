--------------------------------------------------------------------------------
-- book_input_stage
--
-- Normalises one decoded ITCH message into a book command.
--
-- ============================================================================
-- WHAT CHANGED
-- ============================================================================
-- This stage no longer sees message bytes. itch_parser now frames, extracts
-- and field-decodes, and hands over a msg_fields bus in the C_FLD_* layout
-- from itch_parser_pkg. So the beat counter, the 320-bit assembly buffer, the
-- per-lane merge mux and the emit-beat table are all gone, and with them the
-- rule that a message occupied three to five beats.
--
-- What is left is pure semantics: narrow the quantity, decode the side byte,
-- pull the two exchange-order-type bits, and decide whether the price may
-- reach the book. One combinational level plus the output register.
--
-- ============================================================================
-- ONE MESSAGE PER CYCLE
-- ============================================================================
-- itch_parser can retire at most one message per cycle - the shortest in-scope
-- type is D at 18 + 2 = 20 wire bytes, so no two can complete in one 8-byte
-- beat - and this stage is a single register stage with no state. So it
-- accepts a message every cycle and needs no buffering.
--
-- m_tvalid is high for exactly one cycle per accepted command and there is no
-- m_tready: order_fifo's s_tready is hardwired high. A consumer that can stall
-- needs a holding register in front of it.
--
-- ============================================================================
-- SEMANTIC NORMALISATION - unchanged from decode_book_msg
-- ============================================================================
--   * QUANTITY is absolute on A/U but an executed DELTA on E. The op field
--     tells downstream which. Narrowed 64 -> 32 with saturation.
--
--   * PRICE is the order's book price on A/U. px_valid is held low on every
--     EXEC: E carries no price field at all, so the resting price can only
--     come from the order table.
--
--   * EXCHANGE ORDER TYPE exists only on A/U, so undisc and implied must be
--     captured at add/replace time and stored in the order record. They are
--     unrecoverable at execution time.
--
--   * SIDE is an ASCII byte. Anything other than 'B' or 'S' drops the message
--     and pulses stat_bad_side.
--
-- F and C are out of scope upstream and are not accepted here either. If they
-- are re-enabled in itch_parser, add them to f_is_scoped and to the op case -
-- F behaves exactly like A, and C like E.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.ram_pkg.all;
  use work.order_book_pkg.all;
  use work.itch_parser_pkg.all;

entity book_input_stage is
  generic (
    -- Instrument this engine instance tracks; all other order books dropped.
    --
    -- A natural rather than a vector so it can be overridden from the
    -- simulator command line (nvc -e -gG_ORDER_BOOK_ID=85603).
    G_ORDER_BOOK_ID : natural := 85603
  );
  port (
    clk        : in    std_logic;
    resetn     : in    std_logic;

    ----------------------------------------------------------------------------
    -- Slave: one decoded message per cycle from itch_parser. No handshake.
    ----------------------------------------------------------------------------
    s_valid    : in    std_logic;
    s_type     : in    std_logic_vector(7 downto 0);
    s_fields   : in    std_logic_vector(C_MSG_FIELDS_W - 1 downto 0);

    ----------------------------------------------------------------------------
    -- Master: normalised command. Valid for ONE cycle. No handshake.
    ----------------------------------------------------------------------------
    m_tvalid   : out   std_logic;

    m_op       : out   t_book_op;                     -- ADD / EXEC / REPLACE / DELETE
    m_order_id : out   std_logic_vector(63 downto 0);
    m_book_id  : out   std_logic_vector(31 downto 0);
    m_side     : out   std_logic;                     -- 0 = buy, 1 = sell
    m_qty      : out   unsigned(31 downto 0);         -- absolute on ADD/REPLACE, delta on EXEC
    m_price    : out   signed(31 downto 0);           -- valid on ADD/REPLACE only
    m_px_valid : out   std_logic;
    m_undisc   : out   std_logic;                     -- exchange order type bit 5
    m_implied  : out   std_logic;                     -- exchange order type bit 13

    ----------------------------------------------------------------------------
    -- Status pulses, may be left open
    ----------------------------------------------------------------------------
    stat_bad_side : out std_logic;   -- right book, unrecognised side byte
    stat_qty_ovf  : out std_logic    -- wire quantity exceeded 32 bits
  );
end entity book_input_stage;

architecture rtl of book_input_stage is

  ------------------------------------------------------------------------------
  -- C_TYPE_* is declared in BOTH order_book_pkg and itch_parser_pkg, so with
  -- both use clauses neither is directly visible. Bind once by selected name.
  ------------------------------------------------------------------------------
  constant K_A : std_logic_vector(7 downto 0) := work.itch_parser_pkg.C_TYPE_A;
  constant K_U : std_logic_vector(7 downto 0) := work.itch_parser_pkg.C_TYPE_U;
  constant K_E : std_logic_vector(7 downto 0) := work.itch_parser_pkg.C_TYPE_E;
  constant K_D : std_logic_vector(7 downto 0) := work.itch_parser_pkg.C_TYPE_D;

  constant C_BOOK_ID : std_logic_vector(31 downto 0) :=
    std_logic_vector(to_unsigned(G_ORDER_BOOK_ID, 32));

  ------------------------------------------------------------------------------
  -- Types this stage acts on. ADD F AND C HERE if they are re-enabled upstream.
  ------------------------------------------------------------------------------
  function f_is_scoped (t : std_logic_vector(7 downto 0)) return boolean is
  begin
    return t = K_A or t = K_U or t = K_E or t = K_D;
  end function;

  ------------------------------------------------------------------------------
  -- Field views
  ------------------------------------------------------------------------------
  signal side_b   : std_logic_vector(7 downto 0);
  signal extype   : std_logic_vector(C_FLD_EXTYPE_W - 1 downto 0);
  signal qty64    : std_logic_vector(63 downto 0);

  signal side_c   : std_logic;
  signal side_ok  : std_logic;
  signal qty32    : unsigned(31 downto 0);
  signal qty_ovf  : std_logic;

  signal is_add   : std_logic;   -- A
  signal is_rep   : std_logic;   -- U
  signal is_exec  : std_logic;   -- E
  signal is_del   : std_logic;   -- D
  signal scoped   : std_logic;

  signal book_hit : std_logic;
  signal accept_c : std_logic;

  ------------------------------------------------------------------------------
  -- Output registers
  ------------------------------------------------------------------------------
  signal r_tvalid   : std_logic  := '0';
  signal r_cmd      : t_book_cmd := C_BOOK_CMD_NULL;
  signal r_bad_side : std_logic  := '0';
  signal r_qty_ovf  : std_logic  := '0';

begin

  ------------------------------------------------------------------------------
  -- Field extraction. All of these are plain slices of the incoming bus.
  ------------------------------------------------------------------------------
  side_b <= itch_side(s_fields);
  qty64  <= itch_quantity(s_fields);
  extype <= s_fields(C_FLD_EXTYPE_LO + C_FLD_EXTYPE_W - 1 downto C_FLD_EXTYPE_LO);

  is_add  <= '1' when s_type = K_A else '0';
  is_rep  <= '1' when s_type = K_U else '0';
  is_exec <= '1' when s_type = K_E else '0';
  is_del  <= '1' when s_type = K_D else '0';
  scoped  <= '1' when f_is_scoped(s_type) else '0';

  ------------------------------------------------------------------------------
  -- Side byte
  ------------------------------------------------------------------------------
  side_c  <= '1' when side_b = C_SIDE_SELL else '0';
  side_ok <= '1' when (side_b = C_SIDE_BUY or side_b = C_SIDE_SELL) else '0';

  ------------------------------------------------------------------------------
  -- Narrow the 64-bit wire quantity, saturating rather than truncating so an
  -- out-of-range value cannot silently become a small one.
  ------------------------------------------------------------------------------
  qty_ovf <= '1' when qty64(63 downto 32) /= (63 downto 32 => '0') else '0';
  qty32   <= (others => '1') when qty_ovf = '1' else unsigned(qty64(31 downto 0));

  ------------------------------------------------------------------------------
  -- Filters
  ------------------------------------------------------------------------------
  book_hit <= '1' when itch_order_book_id(s_fields) = C_BOOK_ID else '0';
  accept_c <= s_valid and scoped and book_hit and side_ok;

  ------------------------------------------------------------------------------
  -- Output register. The default assignment keeps m_tvalid a one-cycle pulse.
  ------------------------------------------------------------------------------
  p_reg : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        r_tvalid   <= '0';
        r_cmd      <= C_BOOK_CMD_NULL;
        r_bad_side <= '0';
        r_qty_ovf  <= '0';
      else

        r_tvalid   <= '0';
        r_bad_side <= '0';
        r_qty_ovf  <= '0';

        if accept_c = '1' then

          r_tvalid <= '1';

          r_cmd.valid    <= '1';
          r_cmd.order_id <= itch_order_id(s_fields);
          r_cmd.book_id  <= itch_order_book_id(s_fields);
          r_cmd.side     <= side_c;
          r_cmd.side_ok  <= '1';
          r_cmd.position <= unsigned(itch_position(s_fields));
          r_cmd.qty      <= qty32;
          r_cmd.qty_ovf  <= qty_ovf;
          r_qty_ovf      <= qty_ovf;

          -- Op, price visibility and the exchange-order-type bits all follow
          -- from the type. D carries none of them.
          if is_add = '1' then
            r_cmd.op       <= OP_ADD;
            r_cmd.price    <= signed(itch_price(s_fields));
            r_cmd.px_valid <= '1';
            r_cmd.undisc   <= extype(C_EXTYPE_BIT_UNDISCLOSED);
            r_cmd.implied  <= extype(C_EXTYPE_BIT_IMPLIED);
          elsif is_rep = '1' then
            r_cmd.op       <= OP_REPLACE;
            r_cmd.price    <= signed(itch_price(s_fields));
            r_cmd.px_valid <= '1';
            r_cmd.undisc   <= extype(C_EXTYPE_BIT_UNDISCLOSED);
            r_cmd.implied  <= extype(C_EXTYPE_BIT_IMPLIED);
          elsif is_exec = '1' then
            r_cmd.op       <= OP_EXEC;
            r_cmd.price    <= (others => '0');
            r_cmd.px_valid <= '0';
            r_cmd.undisc   <= '0';
            r_cmd.implied  <= '0';
          else
            r_cmd.op       <= OP_DELETE;
            r_cmd.qty      <= (others => '0');
            r_cmd.qty_ovf  <= '0';
            r_qty_ovf      <= '0';
            r_cmd.price    <= (others => '0');
            r_cmd.px_valid <= '0';
            r_cmd.undisc   <= '0';
            r_cmd.implied  <= '0';
          end if;

        elsif s_valid = '1' and scoped = '1' and book_hit = '1'
              and side_ok = '0' then
          -- Our instrument, but the side byte was not 'B' or 'S'. Dropping it
          -- desynchronises the book, so surface it rather than swallowing it.
          r_bad_side <= '1';
        end if;

      end if;
    end if;
  end process p_reg;

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------
  m_tvalid   <= r_tvalid;
  m_op       <= r_cmd.op;
  m_order_id <= r_cmd.order_id;
  m_book_id  <= r_cmd.book_id;
  m_side     <= r_cmd.side;
  m_qty      <= r_cmd.qty;
  m_price    <= r_cmd.price;
  m_px_valid <= r_cmd.px_valid;
  m_undisc   <= r_cmd.undisc;
  m_implied  <= r_cmd.implied;

  stat_bad_side <= r_bad_side;
  stat_qty_ovf  <= r_qty_ovf;

end architecture rtl;
