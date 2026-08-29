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
-- IMPORTANT NOTES / possible improvements
--
-- -> Before implementation, HDL needs to be as dynamic as possible (No hardcoding values) this will help in testing.
--    values should be added in serperate package file
-- 
-- -> First stage is getting each operation to work by themselves -> secodn stage is to get operations 
--    working simaltneously (multi read ram module will be needed)
--
-- -> arbiter for write ports for different processes !!OR!! seperate processes into different modules entirely (an order book top level will MUX write ports)
--
-- -> For lookup logic a counter could possibly used instead of the looking_r signal.
--
-- -> For insertion logic, write address port is just a delayed version of the read port (logic could be altered to remove clutter)
--
-- -> minor logic flaw - lookup never checks for valid bit - should be ok
--
-- -> If lookups are no longer directly asked, OP_NULL can be removed from t_book_op
--
-- -> carry chain explanation in report ???? - + zero extra depth with < operator
--
-- -> EXEC into 0 qty / undiscoled stuff not implemented.
--
-- -> Longest path is the exec logic - needs to be altered if clock to be increased.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ram_pkg.all;
use work.hash65_pkg.all;
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
    s_qty      : in std_logic_vector(31 downto 0); -- absolute on ADD/REPLACE, delta on EXEC
    s_price    : in std_logic_vector(31 downto 0); -- qualified by s_px_valid
    s_px_valid : in std_logic; -- low on EXEC and DELETE
    s_undisc   : in std_logic; -- order rests with zero visible qty
    s_implied  : in std_logic; -- TMC-generated

    busy : out std_logic;

    lookup_return : out t_key     := (others => '0'); --Exact data type may shift with a KVS system
    lookup_found  : out std_logic := '0';
    s_lookup      : in std_logic  := '0';
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
  signal busy_i          : std_logic                                                      := '0';
  signal table_cnt       : unsigned(integer(ceil(log2(real(C_NUM_TABLES)))) - 1 downto 0) := (others => '0'); -- Unsigned coutner for number of tables
  signal key_r           : t_vkey                                                         := (others => '0'); -- Key reg
  signal addr_r          : t_addr                                                         := (others => '0'); -- Addr reg
  signal insertion_we    : std_logic                                                      := '0';
  signal insertion_waddr : t_addr                                                         := (others => '0');
  signal insertion_wdata : t_slot                                                         := (others => '0');
  signal insertion_wsel  : t_sel                                                          := (others => '0');
  signal key             : t_key                                                          := (others => '0');
  signal value           : t_val                                                          := (others => '0');
  signal value_r         : t_val                                                          := (others => '0');
  ------------------------------------------------------------------------------
  -- Lookup/Modify/Delete
  ------------------------------------------------------------------------------
  signal lookup_r       : t_key     := (others => '0'); --hold lookup/delete value
  signal modify_r       : t_val     := (others => '0'); --hold modification value
  signal delmod         : std_logic := '0';
  signal looking_r      : std_logic := '0';
  signal lookup_found_i : std_logic := '0';
  signal modify_we      : std_logic := '0';
  signal modify_waddr   : t_addr    := (others => '0');
  signal modify_wdata   : t_slot    := (others => '0');
  signal modify_wsel    : t_sel     := (others => '0');
  signal op_r           : t_book_op;

  signal raddr_i : t_addr_set := (others => (others => '0'));

begin

  key <= s_order_id & s_side;

  value <= s_qty & s_price & s_undisc & s_implied;

  s_tready <= s_tready_i;
  s_xfer   <= s_tvalid and s_tready_i;

  counter : process (clk)
    -- Cycles through tables individually for insertion.
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        table_cnt <= (others => '0');
      else
        if s_xfer = '1' or busy_i = '1' then
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
        busy_i          <= '0';
        key_r           <= (others => '0');
        addr_r          <= (others => '0');
        value_r         <= (others => '0');
        insertion_waddr <= (others => '0');
        insertion_wdata <= (others => '0');
        insertion_wsel  <= (others => '0');
        insertion_we    <= '0';
      else
        if s_xfer = '1' and s_op = OP_ADD then
          -- First Beat -> AXI handsahke complete: key saved to reg + status bit set high
          busy_i  <= '1';
          key_r   <= '1' & key; -- add valid bit
          value_r <= value;
          addr_r  <= hash(key, 0);
        elsif busy_i = '0' then
          key_r   <= (others => '0');
          addr_r  <= (others => '0');
          value_r <= (others => '0');
        else
          key_r   <= rdata(to_integer(table_cnt - 1))(VKEY_RANGE);
          value_r <= rdata(to_integer(table_cnt - 1))(VAL_RANGE);
          addr_r  <= hash(rdata(to_integer(table_cnt - 1))(KEY_RANGE), to_integer(table_cnt));
        end if;
        -- Both the key and addr registers are taken from the read port every cycle, except on the first cycle where the key
        -- and addr registers are loaded straight from the input key.

        if busy_i = '1' then
          -- Second beat+ set write ports to write from first table -> eviction logic
          insertion_we    <= '1';
          insertion_waddr <= addr_r;
          insertion_wdata <= key_r & value_r; --write key to table
          insertion_wsel  <= std_logic_vector(table_cnt - 1);
          if rdata(to_integer(table_cnt - 1))(C_VALID_BIT) = '0' then
            -- EMPTY slot
            busy_i <= '0';
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
    variable prev_val : unsigned(C_VAL_W - 1 downto 0) := (others => '0');
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        lookup_found_i <= '0';
        lookup_r       <= (others => '0');
        modify_r       <= (others => '0');
        looking_r      <= '0';
        modify_waddr   <= (others => '0');
        modify_wdata   <= (others => '0');
        modify_wsel    <= (others => '0');
        modify_we      <= '0';
        lookup_return  <= (others => '0');
        delmod         <= '0';
        op_r           <= OP_NULL;
      else
        if s_xfer = '1' and (s_lookup = '1' or s_op = OP_DELETE or s_op = OP_REPLACE or s_op = OP_EXEC) then

          looking_r <= '1';
          lookup_r  <= key;
          modify_r  <= value;
          op_r      <= s_op;

          if s_op = OP_DELETE or s_op = OP_REPLACE or s_op = OP_EXEC then
            delmod <= '1';
          end if;

        end if;

        -- or deletion/modification pipeline could possibly done in the cycle after lookup
        if looking_r = '1' then
          for i in 0 to C_NUM_TABLES - 1 loop
            if rdata(i)(KEY_RANGE) = lookup_r and rdata(i)(C_VALID_BIT) = '1' then
              lookup_found_i <= '1';
              lookup_return  <= rdata(i)(KEY_RANGE);

              modify_waddr <= raddr_i(i);
              modify_we    <= delmod;
              modify_wsel  <= std_logic_vector(to_unsigned(i, modify_wsel'length));

              prev_val := unsigned(rdata(i)(VAL_RANGE));
            end if;
          end loop;
          looking_r    <= '0';
          modify_wdata <= modify_func(
            op_r,
            lookup_r,
            prev_val,
            modify_r
            );
          -- MODIFY ORDER -> placed in order of priority for logic levels
          -- EXEC: subtracts the executed qty from the current order only
          -- REPLACE: replaces the whole order
          -- DELETE: simply clears everything
          delmod <= '0';
          op_r   <= OP_NULL;
        else
          lookup_found_i <= '0';
          modify_we      <= '0';
          modify_waddr   <= (others => '0');
          modify_wdata   <= (others => '0');
          modify_wsel    <= (others => '0');
        end if;
      end if;
    end if;
  end process lookup;

  busy       <= busy_i;
  s_tready_i <= not (busy_i or looking_r);

  lookup_found <= lookup_found_i;

  -- !!NOTES
  -- All table reads are set to the address of the input key anticipating a lookup (exc table 0)

  raddr_i(0) <= hash(key, 0) when busy_i = '0' else
  hash(rdata(to_integer(table_cnt - 1))(KEY_RANGE), 0);
  -- input key addr on beat 0 and data read on beats 1+ (for cases when a key is moved back to the start of the table index)

  g_raddr_i : for i in 1 to C_NUM_TABLES - 1 generate
    raddr_i(i) <= hash(key, i) when busy_i = '0' else
    hash(rdata(to_integer(table_cnt - 1))(KEY_RANGE), i);
  end generate g_raddr_i;

  g_raddr : for i in 0 to C_NUM_TABLES - 1 generate
    raddr(i) <= raddr_i(i);
  end generate g_raddr;
  -- For insertion logic -> Read address for the current table is set to the address of the key in the previous table

  we    <= (insertion_we or modify_we);
  waddr <= (insertion_waddr or modify_waddr);
  wdata <= (insertion_wdata or modify_wdata);
  wsel  <= (insertion_wsel or modify_wsel);
  -- MUX for write ports
end architecture rtl;
