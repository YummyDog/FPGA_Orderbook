--------------------------------------------------------------------------------
-- level_array
--
-- The C_NUM_SIDES price level tables. One memory per side, addressed by level.
-- Geometry comes entirely from level_pkg, so this entity has no generics and
-- drops straight into price_storage.
--
-- Geometry comes entirely from the CONFIGURATION blocks in level_cfg_pkg and
-- level_pkg - see the notes there on what limits each axis. Concurrent
-- assertions below catch configurations that would fail to synthesise, and
-- validate the band table itself.
--
-- WRITES ARE NOT PARALLEL, READS ARE
--
-- One mutation touches one level on one side, so a single write port plus wsel
-- is enough, exactly as in ram_array. Reads are per-side, because both halves
-- of the top of book have to be readable in the same cycle:
--
--   raddr(BUY )  ->  rdata(BUY )
--   raddr(SELL)  ->  rdata(SELL)
--
-- Each side is its own memory with no shared state, which is what makes the
-- simultaneous read free. Within a side there is one read port, so the
-- aggregation and publish paths share it - see the note at the end.
--
-- wsel IS A SINGLE BIT, NOT A VECTOR
--
-- '0' selects side 0, '1' selects side 1 - the same encoding side carries
-- everywhere else in the design, so price_storage's lvl_wsel and order_book's
-- m_side wire straight in with no adapter. This differs from ram_array, whose
-- wsel is a t_sel vector because it selects one of four hash tables, which is
-- a genuine multi-way choice.
--
-- The cost is that C_NUM_SIDES is now capped at 2, and the assertion below
-- enforces it. That is not a real restriction on a displayed book, but it does
-- mean the geometry no longer scales by changing one constant: a third queue
-- needs wsel widened back to t_lvl_sel and the unsigned compare restored in
-- g_wdecode. level_pkg still declares t_lvl_sel and C_LVL_SEL_W, unused, for
-- exactly that.
--
-- READ LATENCY IS C_LVL_READ_LATENCY. Addresses on cycle N give data on cycle
-- N+1 by default.
--
-- READ-DURING-WRITE RETURNS OLD DATA, inherited from ram_sdp. Unlike the order
-- table, where the engine's busy signal holds off a colliding access, this is
-- NOT sufficient here. Consecutive mutations to the same price level are the
-- common case in market data rather than a rare collision - adds and executions
-- cluster at top of book - so stalling would cost throughput on exactly the
-- traffic that matters. price_storage must instead forward from its write stage
-- when the incoming index matches, and this module makes no attempt to do that
-- for it: one comparator and a mux belong at the point where the new value is
-- computed, not buried in the memory wrapper.
--
-- THERE IS NO VALID BIT AND NO INITIALISATION. Block RAM contents after
-- configuration are part-dependent, so a slot whose occupancy bit is clear
-- holds garbage, not zero. Occupancy is tracked in flip-flops in price_storage
-- and nothing here may be read without consulting it. See level_pkg.
--
-- SLOTS ABOVE C_LVL_USED ARE ALLOCATED BUT DEAD
--
-- ram_sdp derives its depth as 2**G_ADDR_W, so a used depth of C_LVL_USED
-- rounds up to the next power of two. At the working geometry that is 10,304
-- used out of 16,384 allocated - 37% of the memory is addressable but can never
-- be produced by the band map, and is never written.
--
-- To reclaim it, give ram_sdp an explicit depth generic:
--
--     generic ( G_DEPTH : natural := 0 );          -- 0 => 2**G_ADDR_W
--     constant C_DEPTH : positive :=
--       maximum(1, G_DEPTH) when G_DEPTH > 0 else 2**G_ADDR_W;
--
-- and pass G_DEPTH => C_LVL_USED below. Vivado infers non-power-of-two depths
-- without complaint. Left alone here so ram_sdp stays exactly as the order
-- table needs it.
--
-- ONE READ PORT PER SIDE
--
-- The aggregation read and any top-of-book publish read contend for it.
-- price_storage owns that choice: either it publishes from registers it already
-- holds, or it steals cycles when no mutation is in flight. If both are ever
-- needed in the same cycle at different addresses, the memory has to be
-- duplicated - each copy fed identical we/waddr/wdata, read independently.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.level_cfg_pkg.all;
use work.level_band_pkg.all;
use work.level_pkg.all;

entity level_array is
  port (
    clk   : in  std_logic;

    ----------------------------------------------------------------------------
    -- Write port: one side at a time, chosen by wsel. Broadcast to every
    -- replica of that side.
    --
    -- wsel is a SINGLE BIT, not t_lvl_sel, and carries the side directly:
    -- '0' selects side 0, '1' selects side 1. It is the same encoding the rest
    -- of the design uses for side on every other interface - order_book's
    -- m_side, price_storage's s_side - so a producer wires straight in with no
    -- vector adapter. See the note below on what this costs.
    ----------------------------------------------------------------------------
    we    : in  std_logic;
    wsel  : in  std_logic;
    waddr : in  t_lvl_addr;
    wdata : in  t_level;

    ----------------------------------------------------------------------------
    -- Read ports: one address and one result per side, every cycle. The level
    -- within a side is selected by the address.
    ----------------------------------------------------------------------------
    raddr : in  t_lvl_addr_set;
    rdata : out t_level_set
  );
end entity level_array;


architecture rtl of level_array is

  -- One write enable per side, at most one high at a time. Shared by every
  -- replica of that side, which is what keeps the copies identical.
  signal we_side : t_lvl_flags;

begin

  ------------------------------------------------------------------------------
  -- Band table validation.
  --
  -- The band map is the whole correctness argument for this structure: the
  -- index must be monotone in price and bijective over the legal prices, or the
  -- priority encoder reads position and gets the wrong level. These assertions
  -- check the properties that make that true, at elaboration, so a bad edit to
  -- the table fails immediately rather than producing a book that is subtly
  -- wrong at band boundaries.
  ------------------------------------------------------------------------------

  -- Ascending, non-overlapping bands. Without this the range compares in
  -- px_index overlap and the last matching band silently wins.
  g_band_order : for b in 1 to C_NUM_BANDS - 1 generate
    assert C_BANDS(b).lo_cent > C_BANDS(b - 1).lo_cent
      report "level_array: band " & integer'image(b) & " starts at " &
             integer'image(C_BANDS(b).lo_cent) & "c, which is not above band " &
             integer'image(b - 1) & " at " &
             integer'image(C_BANDS(b - 1).lo_cent) & "c. Bands must ascend."
      severity failure;
  end generate g_band_order;

  -- Each band's width must be a whole number of its own ticks, or the join to
  -- the next band lands mid-tick and the map stops being monotone.
  g_band_divides : for b in 0 to C_NUM_BANDS - 1 generate
    assert (C_BAND_MAP(b).hi_px - C_BAND_MAP(b).lo_px)
             mod C_BAND_MAP(b).tick_px = 0
      report "level_array: band " & integer'image(b) & " spans " &
             integer'image(C_BAND_MAP(b).hi_px - C_BAND_MAP(b).lo_px) &
             " price units, which is not a whole number of " &
             integer'image(C_BAND_MAP(b).tick_px) & "-unit ticks."
      severity failure;
  end generate g_band_divides;

  -- Ticks are expressed in tenths of a cent, so the wire resolution has to be
  -- at least that fine or the scaling truncates to zero.
  assert C_PX_PER_CENT mod 10 = 0
    report "level_array: C_PX_PER_CENT = " & integer'image(C_PX_PER_CENT) &
           " is not a multiple of 10. Tick sizes are given in tenths of a " &
           "cent and cannot be represented at this wire resolution."
    severity failure;

  -- The cap has to sit inside the last band, or levels go missing.
  assert C_LVL_MAX_CENT > C_BANDS(C_NUM_BANDS - 1).lo_cent
    report "level_array: C_LVL_MAX_CENT = " & integer'image(C_LVL_MAX_CENT) &
           "c is not above the start of the last band at " &
           integer'image(C_BANDS(C_NUM_BANDS - 1).lo_cent) & "c."
    severity failure;

  ------------------------------------------------------------------------------
  -- Geometry guard rails.
  ------------------------------------------------------------------------------
  assert C_LVL_ADDR_W <= C_LVL_ADDR_W_MAX
    report "level_array: C_LVL_MAX_CENT = " & integer'image(C_LVL_MAX_CENT) &
           "c needs " & integer'image(C_LVL_LEVELS) & " levels and " &
           integer'image(C_LVL_ADDR_W) & " address bits, across " &
           integer'image(C_NUM_SIDES) & " sides. Above " &
           integer'image(C_LVL_ADDR_W_MAX) &
           " the array will not elaborate in reasonable time or synthesise. " &
           "Lower the price cap."
    severity failure;

  -- The price field must be able to hold the cap, or a stored price wraps.
  -- Compared in the log domain: 2 ** C_LVL_PRICE_W overflows a VHDL integer at
  -- the working width of 32, so the direct form is not evaluable.
  assert C_LVL_PRICE_W >= natural(ceil(log2(real(C_LVL_MAX_PX + 1))))
    report "level_array: C_LVL_PRICE_W = " & integer'image(C_LVL_PRICE_W) &
           " bits cannot represent the maximum price of " &
           integer'image(C_LVL_MAX_PX) & " units, which needs " &
           integer'image(natural(ceil(log2(real(C_LVL_MAX_PX + 1))))) & "."
    severity failure;

  assert C_LVL_GRP_W < C_LVL_ADDR_W
    report "level_array: C_LVL_GRP_W = " & integer'image(C_LVL_GRP_W) &
           " is not smaller than C_LVL_ADDR_W = " &
           integer'image(C_LVL_ADDR_W) &
           ". The priority encoder would have a single group, i.e. be flat, " &
           "and will not close timing at this depth."
    severity warning;

  -- A single-bit wsel can name exactly two tables. Anything above that would
  -- elaborate, allocate and read normally, but its write enable is tied low by
  -- the decode below and it could never be written - a silent, permanent data
  -- loss that no simulation of the write path would show, because the write
  -- simply never arrives. Fatal rather than a warning for that reason.
  --
  -- To go wider, put wsel back to t_lvl_sel and restore the unsigned compare
  -- in g_wdecode; level_pkg still carries the type and C_LVL_SEL_W.
  assert C_NUM_SIDES <= 2
    report "level_array: C_NUM_SIDES = " & integer'image(C_NUM_SIDES) &
           ", but wsel is a single bit and can only select 2 tables. Sides " &
           "2 and above would be allocated and readable but never writable. " &
           "Widen wsel to t_lvl_sel to support more."
    severity failure;

  -- Not fatal, but worth seeing: how much of the allocated memory the band map
  -- can actually reach. See the note on reclaiming it in the header.
  assert C_LVL_USED = C_LVL_DEPTH
    report "level_array: " & integer'image(C_LVL_USED) & " of " &
           integer'image(C_LVL_DEPTH) & " allocated slots are reachable (" &
           integer'image(100 * C_LVL_USED / C_LVL_DEPTH) &
           "%). ram_sdp rounds depth to a power of two; see the header note " &
           "on adding G_DEPTH to reclaim the remainder."
    severity note;

  -- Printed once at elaboration so a simulation log records what was built.
  assert false
    report "level_array geometry: " & level_geometry_string
    severity note;

  ------------------------------------------------------------------------------
  -- Decode wsel into per-side write enables.
  --
  -- wsel is one bit, so the decode is a straight equality against the side
  -- index rather than an unsigned compare. Sides above 1 can never match and
  -- their write enable is tied low - the assertion above rejects that
  -- configuration outright rather than letting it build tables that are
  -- readable but permanently unwritable.
  --
  -- A metavalue on wsel matches neither branch, so the write is dropped rather
  -- than landing on a side picked by accident. Same behaviour the unsigned
  -- compare had.
  ------------------------------------------------------------------------------
  g_wdecode : for s in 0 to C_NUM_SIDES - 1 generate
    we_side(s) <= we when (s = 0 and wsel = '0')
                      or (s = 1 and wsel = '1')
                  else '0';
  end generate g_wdecode;

  ------------------------------------------------------------------------------
  -- The tables. Identical, independent, no shared state between sides - which
  -- is what allows both sides to be read in the same cycle.
  ------------------------------------------------------------------------------
  g_sides : for s in 0 to C_NUM_SIDES - 1 generate

    u_ram : entity work.ram_sdp
      generic map (
        G_ADDR_W    => C_LVL_ADDR_W,
        G_DATA_W    => C_LEVEL_W,
        G_OUT_REG   => C_LVL_RAM_OUT_REG,
        G_RAM_STYLE => C_LVL_RAM_STYLE
      )
      port map (
        clk   => clk,
        we    => we_side(s),
        waddr => waddr,
        wdata => wdata,
        raddr => raddr(s),
        rdata => rdata(s)
      );

  end generate g_sides;

end architecture rtl;
