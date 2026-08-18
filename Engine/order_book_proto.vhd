--------------------------------------------------------------------------------
-- order_book
--
-- The order book engine proper. Consumes the normalised command stream from
-- book_input_stage and maintains the book.
--
-- Interface is command-level, not message-level: every ITCH concern - byte
-- offsets, message types, the quantity and price semantic overloads - has
-- already been resolved upstream. This module sees only ADD / EXEC / REPLACE
-- / DELETE against an (order_id, side) key.
--
-- Semantics this module is responsible for (spec 2.6.2):
--
--   ADD      insert a resting order at s_price with s_qty
--   REPLACE  the order loses priority: remove the old resting quantity and
--            insert at the new price and quantity
--   EXEC     s_qty is an executed DELTA. Subtract it from the resting
--            quantity. s_px_valid is low, so the price to decrement must be
--            recovered from the stored order, never from the command.
--   DELETE   remove the order outright
--
--   An order that reaches zero remaining quantity is removed WITHOUT a
--   Delete message ever arriving - except when s_undisc is set, where the
--   order rests with zero visible quantity and does get an explicit D.
--   This is why s_undisc must be stored with the order.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ram_pkg.all;
use work.hash_pkg.all;
use work.order_book_pkg.all;
entity order_book is
  generic (
    -- Live-order capacity. Sized so the structure never runs hot; a single
    -- ASX instrument is expected to rest far fewer than this.
    G_MAX_ORDERS : natural := 16384
  );
  port (
    clk    : in std_logic;
    resetn : in std_logic;

    ----------------------------------------------------------------------------
    -- Slave: normalised command bus from book_input_stage
    ----------------------------------------------------------------------------
    s_tvalid : in std_logic;
    s_tready : out std_logic;

    s_op       : in t_book_op; -- ADD / EXEC / REPLACE / DELETE
    s_order_id : in std_logic_vector(63 downto 0);
    s_book_id  : in std_logic_vector(31 downto 0); -- unused while single-instrument
    s_side     : in std_logic; -- 0 = buy, 1 = sell
    s_qty      : in unsigned(31 downto 0); -- absolute on ADD/REPLACE, delta on EXEC
    s_price    : in signed(31 downto 0); -- qualified by s_px_valid
    s_px_valid : in std_logic; -- low on EXEC and DELETE
    s_undisc   : in std_logic; -- order rests with zero visible qty
    s_implied  : in std_logic; -- TMC-generated

    key : in t_key; --test vector

    busy : out std_logic;

    -- Write port
    we    : out std_logic;
    wsel  : out t_sel := (others => '0'); -- which table
    waddr : out t_addr; -- slot within that table
    wdata : out t_slot; -- valid + key + value, full width

    -- Read ports
    raddr : out t_addr_set; -- one address per table
    rdata : in t_slot_set -- all tables, valid 1 cycle after raddr

  );
end entity order_book;
architecture rtl of order_book is

  ------------------------------------------------------------------------------
  -- Handshake
  ------------------------------------------------------------------------------
  signal s_tready_i : std_logic := '0';
  signal s_xfer     : std_logic := '0'; -- slave  handshake completes this cycle
  signal m_xfer     : std_logic := '0'; -- master handshake completes this cycle

  signal busy_r : std_logic := '0';

  signal table_cnt : unsigned(integer(ceil(log2(real(C_NUM_TABLES)))) - 1 downto 0) := (others => '0'); -- Unsigned coutner for number of tables

  signal key_r  : t_slot := (others => '0'); -- Key reg
  signal addr_r : t_addr := (others => '0'); -- Addr reg

  signal eviction : std_logic := '0'; -- No eviction
  signal beat_reg : unsigned(1 downto 0);

begin

  s_tready <= s_tready_i;
  s_xfer   <= s_tvalid and s_tready_i;

  counter : process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        table_cnt <= (others => '0');
      else
        if s_xfer = '1' or busy_r = '1' then
          if table_cnt = C_NUM_TABLES - 1 then
            table_cnt <= (others => '0');
          else
            table_cnt <= table_cnt + 1; -- Go to next table
          end if;
        else
          table_cnt <= (others => '0');
        end if;
      end if;
    end if;
  end process counter;

  insert : process (clk) is
    variable addr        : t_addr;
    variable addr_victim : t_addr;
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        busy_r   <= '0';
        key_r    <= (others => '0');
        addr_r   <= (others => '0');
        waddr    <= (others => '0');
        wdata    <= (others => '0');
        eviction <= '0';
        beat_reg <= (others => '0');
        wsel     <= (others => '0');
      else
   
        if busy_r = '0' then
            key_r <= 1 & key;
            addr_r <= hash(key, 0);
        else
            key_r <= rdata(to_integer(table_cnt));
            addr_r <= hash(rdata(to_integer(table_cnt))(15 downto 0),to_integer(table_cnt));
        end if;
        -- Both the key and addr registers are taken from the read port every cycle, except on the first cycle where the key
        -- and addr registers are loaded straight from the input key.
        
        if s_xfer = '1' then
          -- First Beat -> AXI handsahke complete: key saved to reg + status bit set high
          busy_r <= '1';

        end if;

        if busy_r = '1' then
          -- Second beat+ set write ports to write from first table -> eviction logic
  
          we       <= '1';
          waddr    <= addr_r;
          wdata    <= key_r; --write key to table
          wsel     <= std_logic_vector(table_cnt - 1);

          if rdata(to_integer(table_cnt))(C_VALID_BIT) = '0' then
            -- EMPTY
            busy_r <= '0';
          end if;
        end if;

      end if;
    end if;
  end process insert;

  busy       <= busy_r;
  s_tready_i <= not busy_r;

  raddr(0) <= hash(key, 0) when busy_r = '0' else
  hash(key_r, 0);



  g_raddr : for i in 1 to C_NUM_TABLES - 1 generate
    raddr(i) <= hash(key_r(15 downto 0), i);
  end generate g_raddr;


end architecture rtl;
