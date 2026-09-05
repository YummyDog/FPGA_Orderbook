--------------------------------------------------------------------------------
-- level_band_pkg / level_pkg
--
-- Single source of truth for the price level tables' geometry and slot layout.
-- Stands alongside ram_pkg, which does the same job for the cuckoo order table.
-- The two structures share ram_sdp and nothing else.
--
-- THREE PACKAGES, ONE FILE
--
-- level_pkg's header needs the total level count to size its subtypes, and that
-- count is computed by a function from the band table. A function body lives in
-- a package body, which elaborates AFTER the header that would call it - so a
-- package cannot use its own function to build its own constants. The band
-- table and its builder therefore live in level_band_pkg, which is fully
-- elaborated first. Both stay in this file, so the configuration is still one
-- edit in one place.
--
-- Downstream files want all three:
--     use work.level_cfg_pkg.all;  use work.level_band_pkg.all;  use work.level_pkg.all;
--
-- DIRECT MAPPED, NOT WINDOWED
--
-- Every legal ASX price up to the cap owns a dedicated slot for the life of the
-- session. There is no base_price register, no sliding window, no rebase, and
-- no out-of-window failure mode. The map from price to slot is fixed at
-- synthesis and never moves.
--
-- The reason this fits is that the legal price space is far smaller than the
-- raw price space. ASX quotes on a tick that widens with price, so above $2
-- only one price in ten is ever legal. Folding the tick into the index
-- compresses the space ~97x, turning 1,000,000 raw units into ~10,000 levels.
--
-- Indexing on the raw price instead is the silent killer here: a table
-- addressed by price units holds one usable level per tick, so a 16k-deep table
-- would carry ~1,600 real levels and three quarters of its slots would be
-- unreachable. The low bits of a quantised price are structure, not
-- information, and the band map is what removes them.
--
-- BAND MAP
--
-- From the ASX price step schedule for equities and redeemable preference
-- securities:
--
--     market price            minimum bid
--     up to 10c               0.1c
--     10c up to $2.00         0.5c
--     $2.00 and above         1c
--
-- Laid end to end in index space, each band starting where the previous
-- finished:
--
--     band 0   $0.000 - $0.10     0.1c        100 levels   base      0
--     band 1   $0.100 - $2.00     0.5c        380 levels   base    100
--     band 2   $2.000 - $100.00   1.0c      9,800 levels   base    480
--                                          ----------
--                                          10,280 levels
--
-- The index is strictly monotone in price across the joins, which is what the
-- top-of-book priority encoder needs - it reads position, so position must be
-- price order. The map is also bijective over the legal prices, so the reverse
-- direction recovers an exact price from an index with one constant multiply.
--
-- Bands 0 and 1 cost 480 levels between them, under 5% of the table. A given
-- instrument will almost certainly live entirely in band 2 and never touch
-- them, but carrying all three costs almost nothing and keeps the design
-- instrument-agnostic rather than tied to one price range.
--
-- THE CAP IS THE ONE REAL CONSTRAINT
--
-- ASX permits prices to $99,999,990, which is ten million levels. Not mappable
-- at any slot width, so a bound is unavoidable. The difference from a windowed
-- design is that this bound is a synthesis-time constant rather than a runtime
-- register: nothing rebases, and a price above the cap is a hard error that
-- should never fire rather than a routine event to be handled.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package level_cfg_pkg is

  ------------------------------------------------------------------------------
  -- CONFIGURATION - price units, cap, and the bands
  ------------------------------------------------------------------------------

  -- Price units per cent on the wire.
  --
  -- 10 means the feed carries 1/1000 of a dollar, so the finest ASX step (0.1c)
  -- is one unit. If the ITCH price field is in 1/10000 of a dollar, set this to
  -- 100 - the band table below is expressed in cents and scales automatically,
  -- and the level count is unchanged.
  --
  -- CONFIRM THIS AGAINST THE ITCH PRICE FIELD DEFINITION. It is the one
  -- constant here that cannot be derived and that silently breaks the map if
  -- wrong: an off-by-ten makes every price fail the on-tick test.
  constant C_PX_PER_CENT : positive := 10;

  -- Highest supported price, in cents, exclusive. $100.00.
  --
  -- This sets the table depth almost single-handedly, since band 2 is 95% of
  -- the levels. Sizing guide, both sides and both read-port replicas included:
  --
  --     $20  ->   2,280 levels,  0.30 Mbit
  --     $50  ->   5,280 levels,  0.69 Mbit
  --     $100 ->  10,280 levels,  1.34 Mbit
  --     $250 ->  25,280 levels,  3.28 Mbit
  --     $500 ->  50,280 levels,  6.54 Mbit
  --
  -- A price at or above this is not representable. price_storage must reject it
  -- rather than let it wrap, because an unchecked price still produces a
  -- plausible index - just the wrong one.
  constant C_LVL_MAX_CENT : positive := 10000;

  ------------------------------------------------------------------------------
  -- The band table
  --
  -- lo_cent is inclusive; each band runs to the start of the next, and the last
  -- runs to C_LVL_MAX_CENT. Ticks are in tenths of a cent so the table reads
  -- like the published schedule and stays independent of C_PX_PER_CENT.
  --
  -- Bands must be listed in ascending price order with strictly increasing
  -- lo_cent, and each band's width must divide evenly by its tick. Both are
  -- asserted in level_array.
  ------------------------------------------------------------------------------
  type t_band is record
    lo_cent : natural;   -- inclusive lower bound, cents
    tick_tc : positive;  -- tick, tenths of a cent
  end record;

  constant C_NUM_BANDS : positive := 3;

  type t_band_table is array (0 to C_NUM_BANDS - 1) of t_band;

  constant C_BANDS : t_band_table := (
    (lo_cent =>   0, tick_tc =>  1),   -- up to 10c        0.1c
    (lo_cent =>  10, tick_tc =>  5),   -- 10c to $2.00     0.5c
    (lo_cent => 200, tick_tc => 10)    -- $2.00 and above  1c
  );

  ------------------------------------------------------------------------------
  -- Derived band map. Computed at elaboration from the table above - nothing
  -- below is hand-entered.
  ------------------------------------------------------------------------------
  type t_band_map is record
    lo_px   : natural;   -- inclusive, price units
    hi_px   : natural;   -- exclusive, price units
    tick_px : positive;  -- price units per level
    n_lvl   : natural;   -- levels in this band
    base    : natural;   -- index of this band's first level
  end record;

  type t_band_map_table is array (0 to C_NUM_BANDS - 1) of t_band_map;

  function build_band_map return t_band_map_table;

end package level_cfg_pkg;


package body level_cfg_pkg is

  function build_band_map return t_band_map_table is
    variable r    : t_band_map_table;
    variable base : natural := 0;
    variable lo   : natural;
    variable hi   : natural;
    variable tick : positive;
  begin
    for b in 0 to C_NUM_BANDS - 1 loop

      lo := C_BANDS(b).lo_cent * C_PX_PER_CENT;

      if b = C_NUM_BANDS - 1 then
        hi := C_LVL_MAX_CENT * C_PX_PER_CENT;
      else
        hi := C_BANDS(b + 1).lo_cent * C_PX_PER_CENT;
      end if;

      -- tick_tc is tenths of a cent, so scale by C_PX_PER_CENT / 10.
      tick := (C_BANDS(b).tick_tc * C_PX_PER_CENT) / 10;

      r(b) := (lo_px   => lo,
               hi_px   => hi,
               tick_px => tick,
               n_lvl   => (hi - lo) / tick,
               base    => base);

      base := base + (hi - lo) / tick;

    end loop;

    return r;
  end function;

end package body level_cfg_pkg;


--------------------------------------------------------------------------------
-- level_band_pkg
--
-- The derived band map. Separate from level_cfg_pkg only so that package's body
-- is fully elaborated before build_band_map is called - a package may not use
-- its own body's function to build its own header constants.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.level_cfg_pkg.all;

package level_band_pkg is

  constant C_BAND_MAP : t_band_map_table := build_band_map;

  -- Total legal prices, i.e. levels actually used.
  constant C_LVL_LEVELS : positive :=
    C_BAND_MAP(C_NUM_BANDS - 1).base + C_BAND_MAP(C_NUM_BANDS - 1).n_lvl;

  -- Highest representable price, exclusive.
  constant C_LVL_MAX_PX : positive := C_LVL_MAX_CENT * C_PX_PER_CENT;

end package level_band_pkg;


--------------------------------------------------------------------------------
-- level_pkg
--
-- Table geometry, slot layout, and the price <-> index map.
--
-- SLOT LAYOUT
--
--    MSB                                                    LSB
--   +------+---------------------------+--------------------+
--   | side |            qty            |       price        |
--   +------+---------------------------+--------------------+
--    C_LVL_SIDE_W        C_LVL_QTY_W        C_LVL_PRICE_W
--
-- Price is stored rather than reconstructed. Since the map is bijective the
-- price is strictly redundant with the index, so this is a latency trade: it
-- keeps index_price() off the publish path at the cost of C_LVL_PRICE_W bits
-- per level. Dropping it halves the memory and puts one constant multiply back
-- on that path - worth it at a high cap, probably not at $100.
--
-- Side is stored for the same reason it is not needed: it is redundant with the
-- table a slot lives in, so a mismatch is a free consistency check on the
-- aggregation logic. Set C_LVL_SIDE_W to 0 to drop it once the design is
-- trusted.
--
-- THERE IS NO VALID BIT
--
-- Deliberately. Occupancy lives in a per-side bitmap of flip-flops in
-- price_storage, one bit per level, not in the memory. That bitmap has to exist
-- anyway to drive the top-of-book priority encoder, and putting it in fabric
-- rather than RAM buys three things:
--
--   * The encoder answers "where is the best bid" without a memory access.
--   * A slot narrows by one bit.
--   * IT REMOVES THE INITIALISATION WALK. Block RAM contents after
--     configuration are part-dependent, so ordinarily nothing may assume the
--     memory starts cleared and the design must walk every address before
--     serving traffic. Flip-flops clear in one cycle. If the occupancy bit is
--     low the aggregation logic treats the level as qty zero and never reads
--     what the RAM holds, so the RAM never needs clearing at all.
--
-- The consequence is that this package's contents are meaningless without the
-- accompanying occupancy vector. A t_level read from a level whose bit is clear
-- is garbage, not an empty level.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.level_cfg_pkg.all;
use work.level_band_pkg.all;

package level_pkg is

  ------------------------------------------------------------------------------
  -- CONFIGURATION - the remaining sweep knobs
  ------------------------------------------------------------------------------

  -- Levels per group in the hierarchical top-of-book priority encoder, as
  -- address bits.
  --
  -- A flat encoder across the depth will not close timing at any useful size.
  -- Two levels of 2**this will. The second stage needs a mux of 2**this-bit
  -- slices, which is where the area goes, so the two stages want to be roughly
  -- equal - i.e. this near C_LVL_ADDR_W / 2.
  --
  -- Also sets the granularity the used depth rounds up to.
  constant C_LVL_GRP_W : positive := 5;

  -- Independent level tables, one per side. Each is its own physical memory,
  -- so both sides can be read in the same cycle. Area is linear in this.
  constant C_NUM_SIDES : positive := 2;

  -- Slot fields. Setting C_LVL_SIDE_W to 0 drops the redundant side bit.
  constant C_LVL_SIDE_W  : natural  := 1;
  constant C_LVL_QTY_W   : positive := 32;
  constant C_LVL_PRICE_W : positive := 32;

  -- "auto" | "block" | "distributed" | "ultra" | "registers"
  constant C_LVL_RAM_STYLE : string := "auto";

  -- Extra output register on the level RAMs. Read latency becomes 2.
  --
  -- A design change, not a free knob: the forwarding comparator in the
  -- aggregation path assumes the number of stages between a read being issued
  -- and the matching write committing.
  constant C_LVL_RAM_OUT_REG : boolean := false;

  ------------------------------------------------------------------------------
  -- Derived geometry
  ------------------------------------------------------------------------------
  constant C_LVL_GRP : positive := 2 ** C_LVL_GRP_W;

  -- Used depth, rounded up to a whole number of encoder groups. Not a power of
  -- two: nothing truncates a price any more, so the depth is free to be
  -- whatever the band map needs. Rounding 10,280 up to 16,384 would waste 37%.
  constant C_LVL_USED : positive :=
    ((C_LVL_LEVELS + C_LVL_GRP - 1) / C_LVL_GRP) * C_LVL_GRP;

  constant C_LVL_NUM_GRP : positive := C_LVL_USED / C_LVL_GRP;

  -- Address width, and the depth that width actually allocates. ram_sdp builds
  -- 2**G_ADDR_W words, so slots between C_LVL_USED and C_LVL_DEPTH are
  -- addressable but never written. See the note in level_array on reclaiming
  -- them.
  constant C_LVL_ADDR_W : positive := natural(ceil(log2(real(C_LVL_USED))));

  constant C_LVL_DEPTH : positive := 2 ** C_LVL_ADDR_W;

  constant C_LEVEL_W : positive := C_LVL_SIDE_W + C_LVL_QTY_W + C_LVL_PRICE_W;

  -- Bits needed to name one side. maximum() guards the single-table case, where
  -- log2 would give 0 and produce an illegal null vector.
  constant C_LVL_SEL_W : positive :=
    maximum(1, natural(ceil(log2(real(C_NUM_SIDES)))));

  -- One memory per side.
  constant C_LVL_TOTAL_BITS : natural := C_LVL_DEPTH * C_LEVEL_W * C_NUM_SIDES;

  constant C_LVL_READ_LATENCY : positive := 1 + boolean'pos(C_LVL_RAM_OUT_REG);

  ------------------------------------------------------------------------------
  -- Guard rails
  ------------------------------------------------------------------------------
  constant C_LVL_ADDR_W_MAX : positive := 18;

  ------------------------------------------------------------------------------
  -- Slot layout
  --
  --    MSB                                      LSB
  --   +------+---------------+------------------+
  --   | side |      qty      |      price       |
  --   +------+---------------+------------------+
  ------------------------------------------------------------------------------
  constant C_LVL_SIDE_BIT : natural := C_LEVEL_W - 1;

  constant C_LVL_QTY_HI : natural := C_LEVEL_W - 1 - C_LVL_SIDE_W;
  constant C_LVL_QTY_LO : natural := C_LVL_PRICE_W;

  constant C_LVL_PRICE_HI : natural := C_LVL_PRICE_W - 1;
  constant C_LVL_PRICE_LO : natural := 0;

  constant C_LVL_HAS_SIDE : boolean := C_LVL_SIDE_W > 0;

  ------------------------------------------------------------------------------
  -- Range subtypes
  ------------------------------------------------------------------------------
  subtype LVL_QTY_RANGE   is integer range C_LVL_QTY_HI downto C_LVL_QTY_LO;
  subtype LVL_PRICE_RANGE is integer range C_LVL_PRICE_HI downto C_LVL_PRICE_LO;
  subtype LVL_ALL_RANGE   is integer range C_LEVEL_W - 1 downto 0;

  -- qty and price together, dropping the side bit. What a write-back carries
  -- when the side is already implied by wsel.
  subtype LVL_PAYLOAD_RANGE is integer range C_LVL_QTY_HI downto 0;

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  subtype t_lvl_addr  is std_logic_vector(C_LVL_ADDR_W - 1 downto 0);
  subtype t_lvl_sel   is std_logic_vector(C_LVL_SEL_W - 1 downto 0);
  subtype t_level     is std_logic_vector(C_LEVEL_W - 1 downto 0);
  subtype t_lvl_qty   is std_logic_vector(C_LVL_QTY_W - 1 downto 0);
  subtype t_lvl_qty_u is unsigned(C_LVL_QTY_W - 1 downto 0);
  subtype t_lvl_price is std_logic_vector(C_LVL_PRICE_W - 1 downto 0);

  -- Occupancy. One bit per USED level, held in flip-flops by price_storage, not
  -- in the memory. Sized to C_LVL_USED rather than C_LVL_DEPTH so the priority
  -- encoder never scans slots the band map cannot produce.
  subtype t_lvl_occ is std_logic_vector(C_LVL_USED - 1 downto 0);

  type t_lvl_occ_set is array (0 to C_NUM_SIDES - 1) of t_lvl_occ;

  -- One read address and one read result per side. The level within a side is
  -- selected by the address, so the storage is (side)(level) with the second
  -- index carried on t_lvl_addr rather than as an array dimension.
  type t_lvl_addr_set is array (0 to C_NUM_SIDES - 1) of t_lvl_addr;
  type t_level_set    is array (0 to C_NUM_SIDES - 1) of t_level;

  -- One bit per side, for per-table flags.
  subtype t_lvl_flags is std_logic_vector(0 to C_NUM_SIDES - 1);

  constant C_LEVEL_EMPTY : t_level := (others => '0');

  ------------------------------------------------------------------------------
  -- Price <-> index map
  --
  -- px_index is combinational: C_NUM_BANDS range compares feeding a mux, with
  -- one division by a CONSTANT divisor per band. Constant division synthesises
  -- to a multiply by reciprocal, not a divider - but it is still the deepest
  -- logic on the input path, so register it in price_storage rather than
  -- letting it merge into the RAM address path.
  --
  -- px_legal must gate every write. An out-of-range or off-tick price still
  -- produces a plausible-looking index, just the wrong one, and there is no
  -- valid bit in the slot to catch it downstream.
  --
  -- Both take an unconstrained vector so they accept a price of any width
  -- without the caller resizing.
  ------------------------------------------------------------------------------
  function px_index (price : std_logic_vector) return t_lvl_addr;
  function px_legal (price : std_logic_vector) return boolean;
  function index_price (idx : t_lvl_addr) return t_lvl_price;

  ------------------------------------------------------------------------------
  -- Slot accessors
  --
  -- Used instead of open-coded bit ranges so the layout can change in one
  -- place. Purely combinational rewiring - no logic cost.
  ------------------------------------------------------------------------------
  function make_level (side : std_logic;
                       qty  : t_lvl_qty;
                       px   : t_lvl_price) return t_level;

  function level_side  (l : t_level) return std_logic;
  function level_qty   (l : t_level) return t_lvl_qty;
  function level_qty_u (l : t_level) return t_lvl_qty_u;
  function level_price (l : t_level) return t_lvl_price;

  -- True when the slot's stored side matches the table it was read from. The
  -- side field is redundant by construction, so this can only fail if the
  -- aggregation logic wrote to the wrong table - which is what it is for.
  function level_side_ok (l : t_level; side : std_logic) return boolean;

  -- Human-readable geometry, for a report line at the top of a simulation.
  function band_map_string return string;
  function level_geometry_string return string;

end package level_pkg;


package body level_pkg is

  ------------------------------------------------------------------------------
  -- Worked in unsigned throughout rather than converting to integer: a 32-bit
  -- price exceeds integer'high, so to_integer would overflow in simulation on
  -- exactly the malformed input these are meant to reject.
  ------------------------------------------------------------------------------
  function px_index (price : std_logic_vector) return t_lvl_addr is
    variable p : unsigned(price'length - 1 downto 0);
    variable i : unsigned(C_LVL_ADDR_W - 1 downto 0) := (others => '0');
  begin
    p := unsigned(price);

    for b in 0 to C_NUM_BANDS - 1 loop
      if p >= C_BAND_MAP(b).lo_px and p < C_BAND_MAP(b).hi_px then
        i := resize(
               (p - C_BAND_MAP(b).lo_px) / C_BAND_MAP(b).tick_px
                 + C_BAND_MAP(b).base,
               C_LVL_ADDR_W);
      end if;
    end loop;

    return std_logic_vector(i);
  end function;

  ------------------------------------------------------------------------------
  function px_legal (price : std_logic_vector) return boolean is
    variable p : unsigned(price'length - 1 downto 0);
  begin
    p := unsigned(price);

    for b in 0 to C_NUM_BANDS - 1 loop
      if p >= C_BAND_MAP(b).lo_px and p < C_BAND_MAP(b).hi_px then
        -- In range for this band; must also sit on the band's tick.
        return ((p - C_BAND_MAP(b).lo_px) mod C_BAND_MAP(b).tick_px) = 0;
      end if;
    end loop;

    return false;
  end function;

  ------------------------------------------------------------------------------
  function index_price (idx : t_lvl_addr) return t_lvl_price is
    variable i : unsigned(C_LVL_ADDR_W - 1 downto 0);
    variable p : unsigned(C_LVL_PRICE_W - 1 downto 0) := (others => '0');
  begin
    i := unsigned(idx);

    for b in 0 to C_NUM_BANDS - 1 loop
      if i >= C_BAND_MAP(b).base
         and i < C_BAND_MAP(b).base + C_BAND_MAP(b).n_lvl then
        p := resize(
               (i - C_BAND_MAP(b).base) * C_BAND_MAP(b).tick_px
                 + C_BAND_MAP(b).lo_px,
               C_LVL_PRICE_W);
      end if;
    end loop;

    return std_logic_vector(p);
  end function;

  ------------------------------------------------------------------------------
  function make_level (side : std_logic;
                       qty  : t_lvl_qty;
                       px   : t_lvl_price) return t_level is
    variable v_side : std_logic_vector(C_LVL_SIDE_W - 1 downto 0);
  begin
    if C_LVL_HAS_SIDE then
      v_side := (others => side);
      return v_side & qty & px;
    else
      return qty & px;
    end if;
  end function;

  function level_side (l : t_level) return std_logic is
  begin
    if C_LVL_HAS_SIDE then
      return l(C_LVL_SIDE_BIT);
    else
      return '0';
    end if;
  end function;

  function level_qty (l : t_level) return t_lvl_qty is
  begin
    return l(C_LVL_QTY_HI downto C_LVL_QTY_LO);
  end function;

  function level_qty_u (l : t_level) return t_lvl_qty_u is
  begin
    return unsigned(l(C_LVL_QTY_HI downto C_LVL_QTY_LO));
  end function;

  function level_price (l : t_level) return t_lvl_price is
  begin
    return l(C_LVL_PRICE_HI downto C_LVL_PRICE_LO);
  end function;

  function level_side_ok (l : t_level; side : std_logic) return boolean is
  begin
    if not C_LVL_HAS_SIDE then
      return true;
    end if;
    return l(C_LVL_SIDE_BIT) = side;
  end function;

  ------------------------------------------------------------------------------
  function band_map_string return string is
  begin
    return integer'image(C_BAND_MAP(0).n_lvl) & " + " &
           integer'image(C_BAND_MAP(1).n_lvl) & " + " &
           integer'image(C_BAND_MAP(2).n_lvl) & " levels @ ticks " &
           integer'image(C_BAND_MAP(0).tick_px) & "/" &
           integer'image(C_BAND_MAP(1).tick_px) & "/" &
           integer'image(C_BAND_MAP(2).tick_px) & " px";
  end function;

  function level_geometry_string return string is
  begin
    return integer'image(C_NUM_SIDES) & " sides x " &
           integer'image(C_LVL_LEVELS) & " legal prices (" &
           band_map_string & "), max $" &
           integer'image(C_LVL_MAX_CENT / 100) & ", used depth " &
           integer'image(C_LVL_USED) & ", allocated " &
           integer'image(C_LVL_DEPTH) & " (" &
           integer'image(C_LVL_ADDR_W) & " addr bits), slot " &
           integer'image(C_LEVEL_W) & "b (side " &
           integer'image(C_LVL_SIDE_W) & "b, qty " &
           integer'image(C_LVL_QTY_W) & "b, price " &
           integer'image(C_LVL_PRICE_W) & "b), " &
           integer'image(C_NUM_SIDES) & " memories, " &
           integer'image(C_LVL_TOTAL_BITS) & " bits, read latency " &
           integer'image(C_LVL_READ_LATENCY);
  end function;

end package body level_pkg;
