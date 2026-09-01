--------------------------------------------------------------------------------
-- level_array
--
-- The C_NUM_SIDES price level tables, each replicated C_LVL_RD_PORTS times.
-- Geometry comes entirely from level_pkg, so this entity has no generics and
-- drops straight into price_storage.
--
-- Geometry comes entirely from the CONFIGURATION blocks in level_cfg_pkg and
-- level_pkg - see the notes there on what limits each axis. Concurrent
-- assertions below catch configurations that would fail to synthesise, and
-- validate the band table itself.
--
-- WRITES ARE NOT PARALLEL, READS ARE - IN TWO DIMENSIONS
--
-- One mutation touches one level on one side, so a single write port plus wsel
-- is enough, exactly as in ram_array. Reads are the opposite: every side must
-- be readable at once to publish both halves of the top of book in the same
-- cycle, and within a side, two different addresses are needed at once.
--
--   raddr(BUY )(RMW    ) = level being aggregated   ->  rdata(BUY )(RMW    )
--   raddr(BUY )(PUBLISH) = best bid from encoder    ->  rdata(BUY )(PUBLISH)
--   raddr(SELL)(RMW    ) = level being aggregated   ->  rdata(SELL)(RMW    )
--   raddr(SELL)(PUBLISH) = best ask from encoder    ->  rdata(SELL)(PUBLISH)
--
-- The second index is the reason this module is not just ram_array with
-- different constants. A simple dual-port RAM has one read port; more than one
-- read address per cycle means replicating the memory. Each replica of a side
-- sees the same we, waddr and wdata, so the copies are bit-identical at all
-- times and any of them may be read. This costs C_LVL_RD_PORTS times the memory
-- and no logic - no arbiter, no stall path, no extra latency.
--
-- READ LATENCY IS C_LVL_READ_LATENCY on every replica together. Addresses on
-- cycle N give data on cycle N+1 by default.
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
    ----------------------------------------------------------------------------
    we    : in  std_logic;
    wsel  : in  t_lvl_sel;
    waddr : in  t_lvl_addr;
    wdata : in  t_level;

    ----------------------------------------------------------------------------
    -- Read ports: every side, every replica, every cycle, each with its own
    -- address. Indexed (side)(port); use C_LVL_PORT_RMW and C_LVL_PORT_PUBLISH
    -- rather than open-coding the second index.
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
           integer'image(C_LVL_ADDR_W) & " address bits, replicated " &
           integer'image(C_LVL_NUM_RAMS) & " times. Above " &
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

  assert C_LVL_RD_PORTS <= 4
    report "level_array: C_LVL_RD_PORTS = " & integer'image(C_LVL_RD_PORTS) &
           ". Each read port is a full replica of every side's memory - area " &
           "is linear in this. Two covers the aggregation and publish paths."
    severity warning;

  assert C_NUM_SIDES <= 4
    report "level_array: C_NUM_SIDES = " & integer'image(C_NUM_SIDES) &
           ". A displayed book has two sides; more implies additional queues " &
           "that may not want to share this array's geometry."
    severity warning;

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
  -- An out-of-range wsel matches no side, so the write is dropped rather than
  -- landing somewhere unintended. Reachable only when C_NUM_SIDES is not a
  -- power of two.
  ------------------------------------------------------------------------------
  g_wdecode : for s in 0 to C_NUM_SIDES - 1 generate
    we_side(s) <= we when unsigned(wsel) = s else '0';
  end generate g_wdecode;

  ------------------------------------------------------------------------------
  -- The tables. Identical, independent, no shared state between sides - which
  -- is what allows both sides to be read at once - and within a side, identical
  -- replicas differing only in their read address.
  ------------------------------------------------------------------------------
  g_sides : for s in 0 to C_NUM_SIDES - 1 generate

    g_ports : for p in 0 to C_LVL_RD_PORTS - 1 generate

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
          raddr => raddr(s)(p),
          rdata => rdata(s)(p)
        );

    end generate g_ports;

  end generate g_sides;

end architecture rtl;
