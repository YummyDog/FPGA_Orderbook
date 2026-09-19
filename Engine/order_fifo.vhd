--------------------------------------------------------------------------------
-- order_fifo
--
-- Elastic buffer between book_input_stage and order_book, with FCS gating.
--
-- Two columns of G_DEPTH entries, paired by index: column 0 holds the packed
-- command, column 1 holds the 2 bit FCS word for that command. Entry i of one
-- column belongs with entry i of the other. The columns are written from
-- independent sources and so fill independently, but they are consumed
-- together, which is what keeps the pairing in step.
--
--   FCS word : bit 0 = crc_complete, bit 1 = fcs_true
--              "11" = verdict arrived and good -> command is delivered
--              "01" = verdict arrived and bad  -> command is dumped
--              "00" = no verdict yet           -> command waits
--
-- A command reaches the master port only when its own FCS word is "11". If the
-- word is "01" the command is discarded in place: it is removed from the head
-- with its FCS word, m_tvalid is never asserted for it, and no master handshake
-- is involved. One command is dumped per clock.
--
-- Feedthrough is kept on both inputs. While the command column is empty the
-- slave payload is muxed straight to the master port, and while the FCS column
-- is empty the live fcs_* inputs are muxed straight into the gate. So a command
-- that arrives after its verdict, or a verdict that arrives after its command,
-- is handled the same cycle. When both arrive on the same cycle into empty
-- columns they also feed through, though that case is not required to.
--
-- m_tvalid is high whenever a command and a passing FCS word are both at the
-- head, from storage or from feedthrough. It never depends on m_tready. A
-- command leaves only on a full m_tvalid / m_tready handshake, or on a dump.
--
-- s_tready is tied high, so the FIFO cannot refuse a command, and there is no
-- backpressure on the FCS inputs either. If G_DEPTH is undersized the write is
-- dropped, stored contents are untouched, and the sticky overflow flag is
-- raised.
--
-- Storage is a register array shifted down on every read, so the head is always
-- slot 0 and no pointers or RAM are needed. Command fields are packed into one
-- std_logic_vector; the unsigned qty and signed price are cast on the way in.
--
-- Depth is any value >= 1, not just powers of two.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.order_book_pkg.all;
  use work.ram_pkg.all;

entity order_fifo is
  generic (
    G_DEPTH : positive := 16
  );
  port (
    clk        : in    std_logic;
    resetn     : in    std_logic;

    ----------------------------------------------------------------------------
    -- Slave: command bus from book_input_stage
    ----------------------------------------------------------------------------
    s_tvalid   : in    std_logic;
    s_tready   : out   std_logic;

    s_op       : in    t_book_op;
    s_order_id : in    std_logic_vector(63 downto 0);
    s_book_id  : in    std_logic_vector(31 downto 0);
    s_side     : in    std_logic;
    s_qty      : in    unsigned(31 downto 0);
    s_price    : in    signed(31 downto 0);
    s_px_valid : in    std_logic;
    s_undisc   : in    std_logic;
    s_implied  : in    std_logic;

    ----------------------------------------------------------------------------
    -- Master: same bus, std_logic_vector payload, to order_book
    ----------------------------------------------------------------------------
    m_tvalid   : out   std_logic;
    m_tready   : in    std_logic;

    m_op       : out   t_book_op;
    m_order_id : out   std_logic_vector(63 downto 0);
    m_book_id  : out   std_logic_vector(31 downto 0);
    m_side     : out   std_logic;
    m_qty      : out   std_logic_vector(31 downto 0);
    m_price    : out   std_logic_vector(31 downto 0);
    m_px_valid : out   std_logic;
    m_undisc   : out   std_logic;
    m_implied  : out   std_logic;

    ----------------------------------------------------------------------------
    -- Status, may be left open
    ----------------------------------------------------------------------------
    full       : out   std_logic;  -- either column full
    overflow   : out   std_logic;  -- sticky: a command or a verdict was dropped

    ----------------------------------------------------------------------------
    -- FCS result for the command these flags belong to.
    --
    -- fcs_complete is the strobe: one assertion enqueues one verdict into the
    -- FCS column, and fcs_true / fcs_false are sampled with it. The sequencing
    -- of these inputs is the source's business and is not policed here.
    -- fcs_flags is the registered copy of the raw inputs, unchanged from before.
    ----------------------------------------------------------------------------
    fcs_complete : in    std_logic;
    fcs_true     : in    std_logic;
    fcs_false    : in    std_logic;
    fcs_flags    : out   std_logic_vector(2 downto 0)
  );
end entity order_fifo;

architecture rtl of order_fifo is

  function f_clog2 (n : positive) return natural is
    variable v : positive := 1;
    variable r : natural  := 0;
  begin
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function f_clog2;

  ------------------------------------------------------------------------------
  -- Packed command word. The op encoding derives from t_book_op itself, so
  -- adding an operation to order_book_pkg needs no edit here.
  ------------------------------------------------------------------------------
  constant C_OP_W       : natural := maximum(1, f_clog2(t_book_op'pos(t_book_op'high) + 1));

  constant C_IMPLIED_B  : natural := 0;
  constant C_UNDISC_B   : natural := C_IMPLIED_B + 1;
  constant C_PX_VALID_B : natural := C_UNDISC_B + 1;
  constant C_SIDE_B     : natural := C_PX_VALID_B + 1;
  constant C_PRICE_L    : natural := C_SIDE_B + 1;
  constant C_QTY_L      : natural := C_PRICE_L + s_price'length;
  constant C_BOOK_ID_L  : natural := C_QTY_L + s_qty'length;
  constant C_ORDER_ID_L : natural := C_BOOK_ID_L + s_book_id'length;
  constant C_OP_L       : natural := C_ORDER_ID_L + s_order_id'length;

  -- _FLD suffix so these do not clash with the t_val ranges in order_book_pkg.
  subtype PRICE_FLD    is natural range C_QTY_L      - 1 downto C_PRICE_L;
  subtype QTY_FLD      is natural range C_BOOK_ID_L  - 1 downto C_QTY_L;
  subtype BOOK_ID_FLD  is natural range C_ORDER_ID_L - 1 downto C_BOOK_ID_L;
  subtype ORDER_ID_FLD is natural range C_OP_L       - 1 downto C_ORDER_ID_L;
  subtype OP_FLD       is natural range C_OP_L + C_OP_W - 1 downto C_OP_L;

  subtype t_word is std_logic_vector(C_OP_L + C_OP_W - 1 downto 0);
  type    t_regs is array (0 to G_DEPTH - 1) of t_word;
  subtype t_cnt  is unsigned(f_clog2(G_DEPTH + 1) - 1 downto 0);

  ------------------------------------------------------------------------------
  -- FCS column word
  ------------------------------------------------------------------------------
  constant C_CPLT_B  : natural := 0;
  constant C_TRUE_B  : natural := 1;

  subtype t_fcs      is std_logic_vector(1 downto 0);
  type    t_fcs_regs is array (0 to G_DEPTH - 1) of t_fcs;

  constant C_FCS_PASS : t_fcs := (C_TRUE_B => '1', C_CPLT_B => '1');  -- "11"

  ------------------------------------------------------------------------------
  -- State
  ------------------------------------------------------------------------------
  signal regs       : t_regs     := (others => (others => '0'));
  signal fcs_regs   : t_fcs_regs := (others => (others => '0'));
  signal ord_count  : t_cnt      := (others => '0');
  signal fcs_count  : t_cnt      := (others => '0');
  signal overflow_r : std_logic  := '0';

  signal fcs_r      : std_logic_vector(2 downto 0) := (others => '0');

  signal s_word     : t_word;
  signal m_word     : t_word;
  signal s_fcs      : t_fcs;      -- verdict presented on the inputs this cycle
  signal fcs_head   : t_fcs;      -- verdict at the head, stored or feedthrough

  signal ord_empty  : std_logic;
  signal fcs_empty  : std_logic;
  signal ord_full   : std_logic;
  signal fcs_full   : std_logic;

  signal fcs_event  : std_logic;  -- a verdict is being presented this cycle
  signal ord_val    : std_logic;  -- a command is at the head
  signal fcs_val    : std_logic;  -- a verdict is at the head
  signal fcs_pass   : std_logic;  -- head verdict is "11"
  signal fcs_fail   : std_logic;  -- head verdict is complete but not true

  signal m_tvalid_i : std_logic;
  signal xfer       : std_logic;  -- command delivered on a master handshake
  signal dump       : std_logic;  -- command discarded on a failed verdict
  signal consume    : std_logic;  -- head pair leaves, either way

  signal ord_push   : std_logic;  -- command stored, not passed straight through
  signal fcs_push   : std_logic;  -- verdict stored, not passed straight through
  signal ord_pop    : std_logic;  -- stored command left the head
  signal fcs_pop    : std_logic;  -- stored verdict left the head
  signal ord_wr_en  : std_logic;  -- ord_push with a slot available for it
  signal fcs_wr_en  : std_logic;  -- fcs_push with a slot available for it

begin

  ------------------------------------------------------------------------------
  -- Pack. The only type conversion in the design.
  ------------------------------------------------------------------------------
  s_word(OP_FLD)       <= std_logic_vector(to_unsigned(t_book_op'pos(s_op), C_OP_W));
  s_word(ORDER_ID_FLD) <= s_order_id;
  s_word(BOOK_ID_FLD)  <= s_book_id;
  s_word(C_SIDE_B)     <= s_side;
  s_word(QTY_FLD)      <= std_logic_vector(s_qty);
  s_word(PRICE_FLD)    <= std_logic_vector(s_price);
  s_word(C_PX_VALID_B) <= s_px_valid;
  s_word(C_UNDISC_B)   <= s_undisc;
  s_word(C_IMPLIED_B)  <= s_implied;

  -- A verdict is enqueued on the fcs_complete strobe. fcs_false needs no bit of
  -- its own: anything that completes without fcs_true is a failure.
  fcs_event         <= fcs_complete;
  s_fcs(C_CPLT_B)   <= fcs_complete;
  s_fcs(C_TRUE_B)   <= fcs_true and fcs_complete;

  ord_empty <= '1' when ord_count = 0       else '0';
  fcs_empty <= '1' when fcs_count = 0       else '0';
  ord_full  <= '1' when ord_count = G_DEPTH else '0';
  fcs_full  <= '1' when fcs_count = G_DEPTH else '0';

  ------------------------------------------------------------------------------
  -- Heads. The empty terms are the feedthrough: an empty column presents its
  -- live input instead of slot 0.
  ------------------------------------------------------------------------------
  s_tready <= '1';

  m_word   <= regs(0)     when ord_empty = '0' else s_word;
  ord_val  <= '1'         when ord_empty = '0' else s_tvalid;

  fcs_head <= fcs_regs(0) when fcs_empty = '0' else s_fcs;
  fcs_val  <= '1'         when fcs_empty = '0' else fcs_event;

  fcs_pass <= '1' when fcs_val = '1' and fcs_head = C_FCS_PASS else '0';
  fcs_fail <= '1' when fcs_val = '1' and fcs_head(C_CPLT_B) = '1'
                                    and fcs_head(C_TRUE_B) = '0' else '0';

  ------------------------------------------------------------------------------
  -- Gate. A command needs its own verdict before it can go anywhere, so an
  -- unmatched head blocks the column behind it, by design.
  ------------------------------------------------------------------------------
  m_tvalid_i <= ord_val and fcs_pass;
  m_tvalid   <= m_tvalid_i;

  xfer       <= m_tvalid_i and m_tready;
  dump       <= ord_val and fcs_fail;     -- no handshake, discarded in place
  consume    <= xfer or dump;

  -- Stored unless it was the head this cycle and the head left.
  ord_push <= s_tvalid  and not (ord_empty and consume);
  fcs_push <= fcs_event and not (fcs_empty and consume);

  ord_pop  <= consume and not ord_empty;
  fcs_pop  <= consume and not fcs_empty;

  -- Full and popping frees the slot being vacated, so the write is still legal.
  ord_wr_en <= ord_push and ((not ord_full) or ord_pop);
  fcs_wr_en <= fcs_push and ((not fcs_full) or fcs_pop);

  ------------------------------------------------------------------------------
  -- Store. Shift down on a pop, so the oldest entry is always slot 0 and the new
  -- entry goes on the end. The write follows the shift, so a same-cycle push and
  -- pop resolves to the shifted position. Both columns use the same scheme with
  -- their own counts, and pop together, which is what holds the pairing.
  ------------------------------------------------------------------------------
  p_fifo : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        ord_count  <= (others => '0');
        fcs_count  <= (others => '0');
        overflow_r <= '0';
      else

        ------------------------------------------------------------------------
        -- Command column
        ------------------------------------------------------------------------
        if ord_pop = '1' then
          for i in 0 to G_DEPTH - 2 loop
            regs(i) <= regs(i + 1);
          end loop;
        end if;

        if ord_wr_en = '1' then
          if ord_pop = '1' then
            regs(to_integer(ord_count) - 1) <= s_word;
          else
            regs(to_integer(ord_count)) <= s_word;
          end if;
        end if;

        if ord_wr_en = '1' and ord_pop = '0' then
          ord_count <= ord_count + 1;
        elsif ord_wr_en = '0' and ord_pop = '1' then
          ord_count <= ord_count - 1;
        end if;

        ------------------------------------------------------------------------
        -- FCS column
        ------------------------------------------------------------------------
        if fcs_pop = '1' then
          for i in 0 to G_DEPTH - 2 loop
            fcs_regs(i) <= fcs_regs(i + 1);
          end loop;
        end if;

        if fcs_wr_en = '1' then
          if fcs_pop = '1' then
            fcs_regs(to_integer(fcs_count) - 1) <= s_fcs;
          else
            fcs_regs(to_integer(fcs_count)) <= s_fcs;
          end if;
        end if;

        if fcs_wr_en = '1' and fcs_pop = '0' then
          fcs_count <= fcs_count + 1;
        elsif fcs_wr_en = '0' and fcs_pop = '1' then
          fcs_count <= fcs_count - 1;
        end if;

        -- Accepted but no slot for it: the entry is gone and the two columns are
        -- out of step from here on. Cleared by reset only.
        if (ord_push = '1' and ord_wr_en = '0')
          or (fcs_push = '1' and fcs_wr_en = '0') then
          overflow_r <= '1';
        end if;

      end if;
    end if;
  end process p_fifo;

  ------------------------------------------------------------------------------
  -- Raw FCS inputs, registered. Kept for whatever monitors them downstream.
  ------------------------------------------------------------------------------
  p_fcs : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        fcs_r <= (others => '0');
      else
        fcs_r <= fcs_complete & fcs_true & fcs_false;
      end if;
    end if;
  end process p_fcs;

  fcs_flags <= fcs_r;

  ------------------------------------------------------------------------------
  -- Unpack
  ------------------------------------------------------------------------------
  m_op       <= t_book_op'val(to_integer(unsigned(m_word(OP_FLD))));
  m_order_id <= m_word(ORDER_ID_FLD);
  m_book_id  <= m_word(BOOK_ID_FLD);
  m_side     <= m_word(C_SIDE_B);
  m_qty      <= m_word(QTY_FLD);
  m_price    <= m_word(PRICE_FLD);
  m_px_valid <= m_word(C_PX_VALID_B);
  m_undisc   <= m_word(C_UNDISC_B);
  m_implied  <= m_word(C_IMPLIED_B);

  full       <= ord_full or fcs_full;
  overflow   <= overflow_r;

  -- A dropped entry desynchronises the book for the rest of the session.
  assert not (rising_edge(clk) and ord_push = '1' and ord_wr_en = '0')
    report "order_fifo: overflow, command dropped - increase G_DEPTH"
    severity failure;

  assert not (rising_edge(clk) and fcs_push = '1' and fcs_wr_en = '0')
    report "order_fifo: overflow, FCS verdict dropped - increase G_DEPTH"
    severity failure;

end architecture rtl;
