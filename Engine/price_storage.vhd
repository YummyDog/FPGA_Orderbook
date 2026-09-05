--------------------------------------------------------------------------------
-- price_storage
--
-- Aggregates the per-order mutation stream from order_book into per-price
-- resting quantity, one table per side, and publishes top of book.
--
-- Slave interface matches the order_book master bus directly.
--
-- VHDL-2008
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- IMPORTANT NOTES / possible improvements
--
-- -> SDP RAM limitations with read and write at the same address at the same time. (ADDRESS COLLISION) This will need to be confirmed at some point
--    Logic needs to be written to capture entire data if the second replcace message has the same price as the new data is not written into RAM just yet.
-- 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ram_pkg.all;
use work.order_book_pkg.all;
use work.level_pkg.all;

entity price_storage is
  generic (
    -- Levels held per side (window, not full price space)
    G_NUM_LEVELS : natural := 1024;
    -- Price units per level index
    G_TICK : natural := 1
  );
  port (
    clk    : in std_logic;
    resetn : in std_logic;

    ----------------------------------------------------------------------------
    -- Slave: order mutation stream from order_book
    ----------------------------------------------------------------------------
    s_tvalid : in std_logic;
    s_tready : out std_logic;

    s_op    : in t_book_op; -- ADD / DELETE
    s_side  : in std_logic; -- 0 = buy, 1 = sell
    s_price : in std_logic_vector(31 downto 0); -- always valid on this bus
    s_qty   : in std_logic_vector(31 downto 0); -- absolute on ADD/REPLACE, delta on EXEC

    ----------------------------------------------------------------------------
    -- Price window
    ----------------------------------------------------------------------------
    base_price : in std_logic_vector(31 downto 0);
    oor        : out std_logic; -- price fell outside the window

    busy : out std_logic;

    ----------------------------------------------------------------------------
    -- Level table
    ----------------------------------------------------------------------------
    lvl_we    : out std_logic;
    lvl_wsel  : out std_logic; -- which side's table
    lvl_waddr : out std_logic_vector(integer(ceil(log2(real(G_NUM_LEVELS)))) - 1 downto 0);
    lvl_wdata : out t_level; -- side(1) + qty(32) + price(32)

    lvl_raddr : out std_logic_vector(integer(ceil(log2(real(G_NUM_LEVELS)))) - 1 downto 0);
    lvl_rdata : in t_level_set; -- valid 1 cycle after raddr

    ----------------------------------------------------------------------------
    -- Master: top of book
    ----------------------------------------------------------------------------
    m_tvalid : out std_logic := '0';
    m_tready : in std_logic;

    m_bid_price : out std_logic_vector(31 downto 0) := (others => '0');
    m_bid_qty   : out std_logic_vector(31 downto 0) := (others => '0');
    m_ask_price : out std_logic_vector(31 downto 0) := (others => '0');
    m_ask_qty   : out std_logic_vector(31 downto 0) := (others => '0');
    m_valid     : out std_logic_vector(1 downto 0)  := (others => '0') -- per side
  );
end entity price_storage;

architecture rtl of price_storage is
  signal side_r    : std_logic                     := '0';
  signal price_r   : std_logic_vector(31 downto 0) := (others => '0');
  signal qty_r     : std_logic_vector(31 downto 0) := (others => '0');
  signal op_r      : t_book_op;
  signal inserting : std_logic := '0';
  signal delete    : t_level;
  signal insert    : t_level;
  signal side_int  : integer                       := 0;
  signal price_c   : std_logic_vector(31 downto 0) := (others => '0');
  signal qty_c     : std_logic_vector(31 downto 0) := (others => '0');
  signal index     : std_logic_vector(13 downto 0) := (others => '0');
  signal wqty      : std_logic_vector(31 downto 0) := (others => '0');
  signal wprice    : std_logic_vector(31 downto 0) := (others => '0');
  signal wside     : std_logic                     := '0';

  signal rqty0   : std_logic_vector(31 downto 0) := (others => '0');
  signal rprice0 : std_logic_vector(31 downto 0) := (others => '0');
  signal rqty1   : std_logic_vector(31 downto 0) := (others => '0');
  signal rprice1 : std_logic_vector(31 downto 0) := (others => '0');

  signal lvl_wdata_i : t_level;

  signal lvl_r : t_level;

  signal double : std_logic := '0';

begin

  side_int <= 0 when side_r = '0' else
    1;
  price_c <= lvl_rdata(side_int)(LVL_PRICE_RANGE) when double = '0' else
    lvl_r(LVL_PRICE_RANGE);
  qty_c <= lvl_rdata(side_int)(LVL_QTY_RANGE) when double = '0' else
    lvl_r(LVL_QTY_RANGE);

  delete <= side_r & std_logic_vector(unsigned(qty_c) - unsigned(qty_r)) & price_r;
  insert <= side_r & std_logic_vector(unsigned(qty_c) + unsigned(qty_r)) & price_r;

  delete <= side_r & std_logic_vector(unsigned(qty_c) - unsigned(qty_r)) & price_r;
  insert <= side_r & std_logic_vector(unsigned(qty_c) + unsigned(qty_r)) & price_r;

  storage : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        side_r      <= '0';
        price_r     <= (others => '0');
        qty_r       <= (others => '0');
        op_r        <= OP_ADD;
        index       <= (others => '0');
        inserting   <= '0';
        lvl_we      <= '0';
        lvl_waddr   <= (others => '0');
        double      <= '0';
        lvl_r       <= (others => '0');
        lvl_wsel    <= '0';
        lvl_wdata_i <= (others => '0');
      else
        if s_tvalid = '1' then
          side_r    <= s_side;
          price_r   <= s_price;
          qty_r     <= s_qty;
          op_r      <= s_op;
          index     <= px_index(s_price);
          inserting <= '1';

        else
          inserting <= '0';
        end if;

        if inserting = '1' and s_tvalid = '1' and s_price = price_r and s_side = side_r then

          if op_r = OP_DELETE then
            lvl_r <= delete;
          else
            lvl_r <= insert;
          end if;
          double <= '1';
          -- Logic for replace messages for when price is equal on both orders -> level is saved internally and altered before writing to ram this is to avoid a sdp address collision

        elsif inserting = '1' then
          lvl_we    <= '1';
          lvl_waddr <= index;
          lvl_wsel  <= side_r;
          if op_r = OP_DELETE then
            lvl_wdata_i <= delete;
          else
            lvl_wdata_i <= insert;
          end if;
        else
          lvl_we <= '0';
          double <= '0';
        end if;

      end if;
    end if;
  end process storage;

  lvl_raddr <= px_index(s_price);

  lvl_wdata <= lvl_wdata_i;

  rqty0 <= lvl_rdata(0)(LVL_QTY_RANGE);
  rqty1 <= lvl_rdata(1)(LVL_QTY_RANGE);

  rprice0 <= lvl_rdata(0)(LVL_PRICE_RANGE);
  rprice1 <= lvl_rdata(1)(LVL_PRICE_RANGE);

  wqty   <= lvl_wdata_i(LVL_QTY_RANGE);
  wprice <= lvl_wdata_i(LVL_PRICE_RANGE);
  wside  <= lvl_wdata_i(64);
  --read address set straight from inputs combinationally

end architecture rtl;
