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
-- IMPORTANT NOTES
--
-- -> Before implementation, HDL needs to be as dynamic as possible (No hardcoding values) this will help in testing.
--    values should be added in serperate package file
-- 
-- -> First stage is getting each operation to work by themselves -> secodn stage is to get operations 
--    working simaltneously (multi read ram module will be needed)
--
-- -> Design will msot likely shift to a key-value-store which will use a set of tables for data and a set of tables for keys.
--    For devlopment, keys and value are identical with keys stored with a valid bit in the table
--
-- -> May need a seperate module or FSM to launch a pipeline of operations eg replace: 1. lookup 2. delete 3. Insertion
--
-- -> arbiter for write ports for different processes
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

    key    : in t_key; --test vector
    key_op : in std_logic_vector(1 downto 0); -- Key operation : 0 = INSERTION, 1 = LOOKUP, 2 = DELETION, 3 MODIFY

    busy : out std_logic;

    lookup_return : out t_key     := (others => '0'); --Exact data type may shift with a KVS system
    lookup_found  : out std_logic := '0';
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

  ------------------------------------------------------------------------------
  -- Insertion
  ------------------------------------------------------------------------------
  signal busy_r          : std_logic                                                      := '0';
  signal table_cnt       : unsigned(integer(ceil(log2(real(C_NUM_TABLES)))) - 1 downto 0) := (others => '0'); -- Unsigned coutner for number of tables
  signal key_r           : t_slot                                                         := (others => '0'); -- Key reg
  signal addr_r          : t_addr                                                         := (others => '0'); -- Addr reg
  signal insertion_we    : std_logic                                                      := '0';
  signal insertion_waddr : t_addr                                                         := (others => '0');
  signal insertion_wdata : t_slot                                                         := (others => '0');
  signal insertion_wsel  : t_sel                                                          := (others => '0');

  ------------------------------------------------------------------------------
  -- Lookup/Modify/Delete
  ------------------------------------------------------------------------------
  signal lookup_r       : t_key                                                          := (others => '0');
  signal looking_r      : std_logic                                                      := '0';
  signal lookup_found_r : std_logic                                                      := '0';
  signal modify_we      : std_logic                                                      := '0';
  signal modify_waddr   : t_addr                                                         := (others => '0');
  signal modify_wdata   : t_slot                                                         := (others => '0');
  signal modify_wsel    : t_sel                                                          := (others => '0');
  signal table_reg      : unsigned(integer(ceil(log2(real(C_NUM_TABLES)))) - 1 downto 0) := (others => '0'); -- register to hold a tables address for deletion
  signal op_r           : std_logic_vector(1 downto 0);

begin

  s_tready <= s_tready_i;
  s_xfer   <= s_tvalid and s_tready_i;

  counter : process (clk)
    -- Cycles through tables individually for insertion.
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

  ------------------------------------------------------------------------------
  -- INSERTION
  ------------------------------------------------------------------------------
  insert : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        busy_r          <= '0';
        key_r           <= (others => '0');
        addr_r          <= (others => '0');
        insertion_waddr <= (others => '0');
        insertion_wdata <= (others => '0');
        insertion_wsel  <= (others => '0');
        insertion_we    <= '0';
      else
        if s_xfer = '1' and key_op = "00" then
          -- First Beat -> AXI handsahke complete: key saved to reg + status bit set high
          busy_r <= '1';
          key_r  <= '1' & key;
          addr_r <= hash(key, 0);

        elsif busy_r = '0' then
          key_r  <= (others => '0');
          addr_r <= (others => '0');
        else
          key_r  <= rdata(to_integer(table_cnt - 1));
          addr_r <= hash(rdata(to_integer(table_cnt - 1))(15 downto 0), to_integer(table_cnt));
        end if;
        -- Both the key and addr registers are taken from the read port every cycle, except on the first cycle where the key
        -- and addr registers are loaded straight from the input key.

        if busy_r = '1' then
          -- Second beat+ set write ports to write from first table -> eviction logic
          insertion_we    <= '1';
          insertion_waddr <= addr_r;
          insertion_wdata <= key_r; --write key to table
          insertion_wsel  <= std_logic_vector(table_cnt - 1);
          if rdata(to_integer(table_cnt - 1))(C_VALID_BIT) = '0' then
            -- EMPTY slot
            busy_r <= '0';
          end if;
        else
          insertion_we    <= '0';
          insertion_waddr <= (others => '0');
          insertion_wdata <= (others => '0');
          insertion_wsel  <= (others => '0');

        end if;
      end if;
    end if;
  end process insert;

  ------------------------------------------------------------------------------
  -- LOOKUP, DELETE, MODIFY
  ------------------------------------------------------------------------------
  lookup : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        lookup_found_r <= '0';
        lookup_r       <= (others => '0');
        looking_r      <= '0';
        op_r           <= (others => '0');
        table_reg      <= (others => '0');
        modify_waddr   <= (others => '0');
        modify_wdata   <= (others => '0');
        modify_wsel    <= (others => '0');
        modify_we      <= '0';
      else
        if s_xfer = '1' and (key_op = "01" or key_op = "10" or key_op = "11") then

          looking_r <= '1';
          lookup_r  <= key;
          op_r      <= key_op;

        end if;

        -- !!NOTES lookup may need to be pipelined depending on no. of tables or clock speed
        -- or deletion/modification pipeline could possibly done in the cycle after lookup
        if looking_r = '1' then
          for i in 0 to C_NUM_TABLES - 1 loop
            if rdata(i)(15 downto 0) = lookup_r then
              lookup_found_r <= '1';
              lookup_return  <= rdata(i)(15 downto 0);
              table_reg      <= to_unsigned(i, table_reg'length);
            end if;
          end loop;
          looking_r <= '0';
        elsif op_r = "10" then
          -- If deletion
          modify_we    <= '0';
          modify_waddr <= hash(lookup_r, to_integer(table_reg));
          modify_wdata <= '0' & lookup_r;
          modify_wsel  <= std_logic_vector(table_reg);
        else
          lookup_found_r <= '0';
          modify_waddr   <= (others => '0');
          modify_wdata   <= (others => '0');
          modify_wsel    <= (others => '0');
          modify_we      <= '0';
        end if;
      end if;
    end if;
  end process lookup;

  ------------------------------------------------------------------------------
  -- Deletion
  ------------------------------------------------------------------------------
  busy       <= busy_r;
  s_tready_i <= not (busy_r or looking_r);

  lookup_found <= lookup_found_r;

  -- !!NOTES
  -- All table reads are set to the address of the input key anticipating a lookup (exc table 0)

  raddr(0) <= hash(key, 0) when busy_r = '0' else
  hash(rdata(to_integer(table_cnt - 1))(15 downto 0), 0);
  -- input key addr on beat 0 and data read on beats 1+ (for cases when a key is moved back to the start of the table index)

  g_raddr : for i in 1 to C_NUM_TABLES - 1 generate
    raddr(i) <= hash(key, i) when busy_r = '0' else
    hash(rdata(to_integer(table_cnt - 1))(15 downto 0), i);
  end generate g_raddr;
  -- For insertion logic -> Read address for the current table is set to the address of the key in the previous table

  we    <= (insertion_we or modify_we);
  waddr <= (insertion_waddr or modify_waddr);
  wdata <= (insertion_wdata or modify_wdata);
  wsel  <= (insertion_wsel or modify_wsel);

end architecture rtl;
