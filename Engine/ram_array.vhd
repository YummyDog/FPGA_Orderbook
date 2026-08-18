--------------------------------------------------------------------------------
-- ram_array
--
-- The C_NUM_TABLES hash tables, read in parallel and written one at a time.
-- Geometry comes entirely from ram_pkg, so this entity has no generics and
-- drops straight into the engine.
--
-- Default geometry: 4 tables x 8 slots x 25 bits = 32 slots total.
--
-- READS ARE PARALLEL, WRITES ARE NOT
--
-- A key may rest in any table, so a lookup reads every table at once and
-- compares all results against the key. The addresses are generally all
-- different, which is why each table needs its own - hence raddr being a set
-- rather than one value.
--
--   raddr(0) = h0(key)  ->  rdata(0)  \
--   raddr(1) = h1(key)  ->  rdata(1)   |  same cycle, compared in parallel
--   raddr(2) = h2(key)  ->  rdata(2)   |
--   raddr(3) = h3(key)  ->  rdata(3)  /
--
-- An insert or an eviction touches exactly one slot, so a single write port
-- plus wsel is enough and far cheaper than N write ports.
--
-- Fixed-order insertion uses the same ports sequentially: drive all four
-- addresses from hash_all(current_key), select the one table the counter is
-- pointing at, ignore the rest. Costs nothing - the RAMs read every cycle
-- regardless - and avoids a separate address mux.
--
-- READ LATENCY IS ONE CYCLE on every table together. Addresses on cycle N
-- give data on cycle N+1.
--
-- READ-DURING-WRITE RETURNS OLD DATA. A read issued in the same cycle as a
-- write to the same address sees the pre-write contents. Back-to-back inserts
-- landing on one slot will corrupt unless the second is held off until the
-- first write commits - which is what the engine's busy signal is for.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;

entity ram_array is
  port (
    clk   : in  std_logic;

    ----------------------------------------------------------------------------
    -- Write port: one table at a time, chosen by wsel
    ----------------------------------------------------------------------------
    we    : in  std_logic;
    wsel  : in  t_sel;
    waddr : in  t_addr;
    wdata : in  t_slot;

    ----------------------------------------------------------------------------
    -- Read ports: every table, every cycle, each with its own address
    ----------------------------------------------------------------------------
    raddr : in  t_addr_set;
    rdata : out t_slot_set
  );
end entity ram_array;


architecture rtl of ram_array is

  -- One write enable per table, at most one high at a time.
  signal we_table : t_table_flags;

begin

  ------------------------------------------------------------------------------
  -- Decode wsel into per-table write enables.
  --
  -- An out-of-range wsel matches no table, so the write is dropped rather than
  -- landing somewhere unintended. Reachable only when C_NUM_TABLES is not a
  -- power of two.
  ------------------------------------------------------------------------------
  g_wdecode : for i in 0 to C_NUM_TABLES-1 generate
    we_table(i) <= we when unsigned(wsel) = i else '0';
  end generate g_wdecode;

  ------------------------------------------------------------------------------
  -- The tables. Identical, independent, no shared state - which is what allows
  -- all C_NUM_TABLES reads to happen at once.
  ------------------------------------------------------------------------------
  g_tables : for i in 0 to C_NUM_TABLES-1 generate

    u_ram : entity work.ram_sdp
      generic map (
        G_ADDR_W => C_ADDR_W,
        G_DATA_W => C_SLOT_W
      )
      port map (
        clk   => clk,
        we    => we_table(i),
        waddr => waddr,
        wdata => wdata,
        raddr => raddr(i),
        rdata => rdata(i)
      );

  end generate g_tables;

end architecture rtl;
