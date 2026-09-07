--------------------------------------------------------------------------------
-- order_fifo
--
-- Elastic buffer between book_input_stage and order_book.
--
-- Feedthrough: while empty, the slave payload is muxed straight to the master
-- port and can complete its master handshake the same cycle. It is only stored
-- if that handshake does not complete.
--
-- m_tvalid is high whenever the FIFO holds anything, and in feedthrough when
-- s_tvalid is high. It never depends on m_tready. A command leaves only on a
-- full m_tvalid / m_tready handshake.
--
-- s_tready is tied high, so the FIFO cannot refuse a command. If G_DEPTH is
-- undersized the write is dropped, stored contents are untouched, and the
-- sticky overflow flag is raised.
--
-- Storage is a register array shifted down on every read, so the head is always
-- slot 0 and no pointers or RAM are needed. Fields are packed into one
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
    full       : out   std_logic;
    overflow   : out   std_logic   -- sticky: a command was dropped
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
  -- State
  ------------------------------------------------------------------------------
  signal regs       : t_regs    := (others => (others => '0'));
  signal count      : t_cnt     := (others => '0');
  signal overflow_r : std_logic := '0';

  signal s_word     : t_word;
  signal m_word     : t_word;
  signal empty_i    : std_logic;
  signal full_i     : std_logic;
  signal m_tvalid_i : std_logic;
  signal push       : std_logic;   -- accepted, and not passed straight through
  signal pop        : std_logic;   -- stored command delivered this cycle
  signal wr_en      : std_logic;   -- push with a slot available for it

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

  empty_i <= '1' when count = 0       else '0';
  full_i  <= '1' when count = G_DEPTH else '0';

  ------------------------------------------------------------------------------
  -- Handshakes. The empty_i term on m_word and m_tvalid_i is the feedthrough.
  ------------------------------------------------------------------------------
  s_tready   <= '1';

  m_word     <= s_word   when empty_i = '1' else regs(0);
  m_tvalid_i <= s_tvalid when empty_i = '1' else '1';
  m_tvalid   <= m_tvalid_i;

  -- Stored unless handed straight to the master this cycle.
  push  <= s_tvalid and not (empty_i and m_tready);
  pop   <= (not empty_i) and m_tready;

  -- Full and popping frees the slot being vacated, so the write is still legal.
  wr_en <= push and ((not full_i) or pop);

  ------------------------------------------------------------------------------
  -- Store. Shift down on a pop, so the oldest command is always regs(0) and the
  -- new command goes on the end. The write follows the shift, so a same-cycle
  -- push and pop resolves to the shifted position.
  ------------------------------------------------------------------------------
  p_fifo : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        count      <= (others => '0');
        overflow_r <= '0';
      else

        if pop = '1' then
          for i in 0 to G_DEPTH - 2 loop
            regs(i) <= regs(i + 1);
          end loop;
        end if;

        if wr_en = '1' then
          if pop = '1' then
            regs(to_integer(count) - 1) <= s_word;
          else
            regs(to_integer(count)) <= s_word;
          end if;
        end if;

        if wr_en = '1' and pop = '0' then
          count <= count + 1;
        elsif wr_en = '0' and pop = '1' then
          count <= count - 1;
        end if;

        -- Accepted but no slot for it: the command is gone. Cleared by reset only.
        if push = '1' and wr_en = '0' then
          overflow_r <= '1';
        end if;

      end if;
    end if;
  end process p_fifo;

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

  full       <= full_i;
  overflow   <= overflow_r;

  -- A dropped command desynchronises the book for the rest of the session.
  assert not (rising_edge(clk) and push = '1' and wr_en = '0')
    report "order_fifo: overflow, command dropped - increase G_DEPTH"
    severity failure;

end architecture rtl;
