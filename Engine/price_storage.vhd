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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  use work.ram_pkg.all;
  use work.order_book_pkg.all;

entity price_storage is
  generic (
    -- Levels held per side (window, not full price space)
    G_NUM_LEVELS : natural := 1024;
    -- Price units per level index
    G_TICK       : natural := 1
  );
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;

    ----------------------------------------------------------------------------
    -- Slave: order mutation stream from order_book
    ----------------------------------------------------------------------------
    s_tvalid : in  std_logic;
    s_tready : out std_logic;

    s_op    : in  t_book_op;                     -- ADD / EXEC / REPLACE / DELETE
    s_side  : in  std_logic;                     -- 0 = buy, 1 = sell
    s_price : in  std_logic_vector(31 downto 0); -- always valid on this bus
    s_qty   : in  std_logic_vector(31 downto 0); -- absolute on ADD/REPLACE, delta on EXEC

    ----------------------------------------------------------------------------
    -- Price window
    ----------------------------------------------------------------------------
    base_price : in  std_logic_vector(31 downto 0);
    oor        : out std_logic; -- price fell outside the window

    busy : out std_logic;

    ----------------------------------------------------------------------------
    -- Level table
    ----------------------------------------------------------------------------
    lvl_we    : out std_logic;
    lvl_wsel  : out std_logic; -- which side's table
    lvl_waddr : out std_logic_vector(integer(ceil(log2(real(G_NUM_LEVELS)))) - 1 downto 0);
    lvl_wdata : out std_logic_vector(48 downto 0); -- valid + qty + order count

    lvl_raddr : out std_logic_vector(integer(ceil(log2(real(G_NUM_LEVELS)))) - 1 downto 0);
    lvl_rdata : in  std_logic_vector(48 downto 0); -- valid 1 cycle after raddr

    ----------------------------------------------------------------------------
    -- Master: top of book
    ----------------------------------------------------------------------------
    m_tvalid : out std_logic := '0';
    m_tready : in  std_logic;

    m_bid_price : out std_logic_vector(31 downto 0) := (others => '0');
    m_bid_qty   : out std_logic_vector(31 downto 0) := (others => '0');
    m_ask_price : out std_logic_vector(31 downto 0) := (others => '0');
    m_ask_qty   : out std_logic_vector(31 downto 0) := (others => '0');
    m_valid     : out std_logic_vector(1 downto 0)  := (others => '0') -- per side
  );
end entity price_storage;

architecture rtl of price_storage is
signal cnt;
signal delta

begin




end architecture rtl;
