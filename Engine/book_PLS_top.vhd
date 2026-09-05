--------------------------------------------------------------------------------
-- book_PLS_top
--
-- order_book + ram_array + price_storage. The level memory is NOT here.
--
--     s_*  ->  order_book  ->  m_*  ->  price_storage  ->  tob_*
--                  |                         |
--              ram_array                 lvl_* ports
--                (VHDL)                (out to the testbench)
--
-- The order table is still a real memory, wired up and read through the
-- hierarchy. The level table is not: level_array has been taken out and
-- price_storage's level bus is brought straight to the pins, where a Python
-- model in the testbench answers it. See level_ram_model.py.
--
-- WHY THE LEVEL MEMORY IS MODELLED AND THE ORDER MEMORY IS NOT
--
-- The order table is not the module under test - it is a dependency that
-- already works, and reading the real thing costs nothing. The level table is
-- the far side of the interface being brought up, and a model there is worth
-- more than a memory: it can be inspected between cycles, reset independently,
-- primed with whatever contents a case needs, and it will not silently absorb
-- a malformed write the way a real RAM does.
--
-- The model is authoritative on timing and must match what level_array's
-- ram_sdp did:
--
--     read latency 1        address on cycle N, data on cycle N+1
--     read during write     returns OLD data
--     no reset, no valid    contents start at zero in simulation only
--     one write port        one side at a time, chosen by lvl_wsel
--     one read port         per side, both at the same address
--
-- level_ram_model.py implements exactly that and says so in its header. If
-- C_LVL_RAM_OUT_REG is ever turned on, both have to change together.
--
-- THE READ ADDRESS IS BROADCAST
--
-- price_storage issues one lvl_raddr but indexes the returned data by side, so
-- both sides are read at the same index and it picks the half it wants. That
-- was free in level_array because the sides were independent memories, and it
-- is free in the model for the same reason. Hence one address port out and two
-- data ports back.
--
-- lvl_rdata IS SPLIT INTO ONE PORT PER SIDE
--
-- price_storage takes t_level_set, an array of vectors. That is awkward to
-- drive from cocotb, so the two sides arrive as separate std_logic_vector
-- ports and are assembled into the set below. Rewiring only. The split is
-- hardcoded to two because lvl_wsel is a single bit and cannot name more.
--
-- ADDRESS WIDTH IS FORCED TO MATCH level_pkg
--
-- price_storage sizes its level address ports from G_NUM_LEVELS. Nothing
-- constrains that to agree with t_lvl_addr any more now that level_array is
-- gone, so it is pinned here and asserted below - the model reads its depth
-- from the same place, and a silent divergence would put the model and the
-- design on different address spaces.
--
--     C_LVL_USED = 10304  ->  ceil(log2()) = 14  =  C_LVL_ADDR_W
--
-- THE EVENT BUS IS BROADCAST, NOT HANDSHAKEN
--
-- order_book's master bus feeds price_storage's slave bus. The reverse
-- direction is NOT closed: price_storage does not drive its s_tready, so
-- connecting it to order_book's m_tready would put 'U' on the engine's
-- handshake and poison a state machine that currently works. m_tready is
-- therefore left as a top level input for the testbench to drive, and
-- price_storage observes the bus. price_storage's own s_tready is brought out
-- as pls_tready so the testbench can show it is undriven rather than silently
-- pretending the handshake exists.
--
-- Close the loop by changing one line once price_storage drives s_tready:
--
--     u_book port map ( ... m_tready => pls_tready ... )
--
-- WHAT WILL NOT HAPPEN YET
--
-- price_storage gates its input capture on its OWN m_tvalid, which nothing in
-- that architecture assigns. It sits at its initial '0' forever, so the
-- capture registers never load and lvl_we never rises. Expect zero level
-- writes, and a model that stays empty, until that changes.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.ram_pkg.all;
use work.order_book_pkg.all;

-- level_pkg only. level_cfg_pkg and level_band_pkg are what level_pkg builds
-- its own declarations from; nothing named here comes from them directly.
use work.level_pkg.all;

entity book_PLS_top is
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;

    ----------------------------------------------------------------------------
    -- Slave: normalised command bus into order_book
    ----------------------------------------------------------------------------
    s_tvalid   : in  std_logic;
    s_tready   : out std_logic;

    s_op       : in  t_book_op;
    s_order_id : in  std_logic_vector(63 downto 0);
    s_book_id  : in  std_logic_vector(31 downto 0);
    s_side     : in  std_logic;
    s_qty      : in  std_logic_vector(31 downto 0);
    s_price    : in  std_logic_vector(31 downto 0);
    s_px_valid : in  std_logic;
    s_undisc   : in  std_logic;
    s_implied  : in  std_logic;

    busy       : out std_logic;

    ----------------------------------------------------------------------------
    -- Book events, one per insertion or modification.
    --
    -- Still brought out, and still consumed by the testbench, even though
    -- price_storage now listens to them - see the header note on why the
    -- handshake is not closed internally.
    ----------------------------------------------------------------------------
    m_tvalid   : out std_logic;
    m_tready   : in  std_logic;
    m_side     : out std_logic;
    m_qty      : out std_logic_vector(31 downto 0);
    m_price    : out std_logic_vector(31 downto 0);
    m_op       : out t_book_op;

    ----------------------------------------------------------------------------
    -- Level memory bus. The Python model lives on the other side of these.
    --
    -- Direction is from the DESIGN's point of view: lvl_we/wsel/waddr/wdata
    -- and lvl_raddr are driven by price_storage and read by the model;
    -- lvl_rdata0/1 are driven by the model and read by price_storage.
    ----------------------------------------------------------------------------
    lvl_we     : out std_logic;
    lvl_wsel   : out std_logic;                 -- '0' = side 0, '1' = side 1
    lvl_waddr  : out t_lvl_addr;
    lvl_wdata  : out t_level;

    lvl_raddr  : out t_lvl_addr;                -- one address, both sides
    lvl_rdata0 : in  t_level;                   -- side 0, one cycle later
    lvl_rdata1 : in  t_level;                   -- side 1, one cycle later

    ----------------------------------------------------------------------------
    -- Price level storage
    ----------------------------------------------------------------------------
    base_price : in  std_logic_vector(31 downto 0);

    pls_tready : out std_logic;   -- price_storage s_tready (undriven today)
    pls_busy   : out std_logic;
    pls_oor    : out std_logic;

    ----------------------------------------------------------------------------
    -- Master: top of book
    ----------------------------------------------------------------------------
    tob_tvalid    : out std_logic;
    tob_tready    : in  std_logic;

    tob_bid_price : out std_logic_vector(31 downto 0);
    tob_bid_qty   : out std_logic_vector(31 downto 0);
    tob_ask_price : out std_logic_vector(31 downto 0);
    tob_ask_qty   : out std_logic_vector(31 downto 0);
    tob_valid     : out std_logic_vector(1 downto 0)
  );
end entity book_PLS_top;


architecture rtl of book_PLS_top is

  ------------------------------------------------------------------------------
  -- Level count handed to price_storage.
  --
  -- C_LVL_USED, not C_LVL_LEVELS: the used depth is rounded up to a whole
  -- number of encoder groups in level_pkg, and it is that rounded figure the
  -- address width is derived from.
  ------------------------------------------------------------------------------
  constant C_PLS_LEVELS : positive := C_LVL_USED;

  -- What price_storage will build its address ports as, given the above.
  constant C_PLS_ADDR_W : positive :=
    integer(ceil(log2(real(C_PLS_LEVELS))));

  ------------------------------------------------------------------------------
  -- Order table interconnect, order_book <-> ram_array. Names kept identical
  -- to order_book_top so the existing tracing helpers move across unchanged.
  ------------------------------------------------------------------------------
  signal we    : std_logic;
  signal wsel  : t_sel;
  signal waddr : t_addr;
  signal wdata : t_slot;
  signal raddr : t_addr_set;
  signal rdata : t_slot_set;

  ------------------------------------------------------------------------------
  -- Book event bus, order_book -> price_storage. Internal copies so both the
  -- output ports and the downstream slave can be fed from one source.
  ------------------------------------------------------------------------------
  signal ev_tvalid : std_logic;
  signal ev_side   : std_logic;
  signal ev_qty    : std_logic_vector(31 downto 0);
  signal ev_price  : std_logic_vector(31 downto 0);
  signal ev_op     : t_book_op;

  ------------------------------------------------------------------------------
  -- The two read-data ports, gathered back into the set price_storage expects.
  ------------------------------------------------------------------------------
  signal lvl_rdata_i : t_level_set;

begin

  ------------------------------------------------------------------------------
  -- Geometry guard.
  --
  -- price_storage derives its address width from a generic; t_lvl_addr derives
  -- its from the band table. With level_array gone, nothing else forces those
  -- two to agree, and the model sizes itself from the second. Fail here at
  -- elaboration rather than letting the design and its memory model address
  -- different things.
  ------------------------------------------------------------------------------
  assert C_PLS_ADDR_W = C_LVL_ADDR_W
    report "book_PLS_top: price_storage with G_NUM_LEVELS = " &
           integer'image(C_PLS_LEVELS) & " builds " &
           integer'image(C_PLS_ADDR_W) & "-bit level addresses, but " &
           "t_lvl_addr is " & integer'image(C_LVL_ADDR_W) &
           ". The two geometries have diverged."
    severity failure;

  assert C_NUM_SIDES = 2
    report "book_PLS_top: C_NUM_SIDES = " & integer'image(C_NUM_SIDES) &
           ", but lvl_wsel is a single bit and lvl_rdata is split into " &
           "exactly two ports. Widen both to go further."
    severity failure;

  -- Printed once so a simulation log records the geometry the model has to
  -- match. level_array used to do this; it is gone, so it happens here.
  assert false
    report "book_PLS_top level geometry: " & level_geometry_string
    severity note;

  ------------------------------------------------------------------------------
  -- The order book engine
  ------------------------------------------------------------------------------
  u_book : entity work.order_book
    port map (
      clk        => clk,
      resetn     => resetn,

      s_tvalid   => s_tvalid,
      s_tready   => s_tready,
      s_op       => s_op,
      s_order_id => s_order_id,
      s_book_id  => s_book_id,
      s_side     => s_side,
      s_qty      => s_qty,
      s_price    => s_price,
      s_px_valid => s_px_valid,
      s_undisc   => s_undisc,
      s_implied  => s_implied,

      busy       => busy,

      m_tvalid   => ev_tvalid,
      m_tready   => m_tready,
      m_side     => ev_side,
      m_qty      => ev_qty,
      m_price    => ev_price,
      m_op       => ev_op,

      we         => we,
      wsel       => wsel,
      waddr      => waddr,
      wdata      => wdata,
      raddr      => raddr,
      rdata      => rdata
    );

  ------------------------------------------------------------------------------
  -- The order tables. Still real memory.
  ------------------------------------------------------------------------------
  u_ram_arr : entity work.ram_array
    port map (
      clk   => clk,
      we    => we,
      wsel  => wsel,
      waddr => waddr,
      wdata => wdata,
      raddr => raddr,
      rdata => rdata
    );

  -- Event bus out to the testbench.
  m_tvalid <= ev_tvalid;
  m_side   <= ev_side;
  m_qty    <= ev_qty;
  m_price  <= ev_price;
  m_op     <= ev_op;

  ------------------------------------------------------------------------------
  -- Read data in from the model, assembled into the set. Rewiring only.
  ------------------------------------------------------------------------------
  lvl_rdata_i(0) <= lvl_rdata0;
  lvl_rdata_i(1) <= lvl_rdata1;

  ------------------------------------------------------------------------------
  -- Price level aggregation
  ------------------------------------------------------------------------------
  u_pls : entity work.price_storage
    generic map (
      G_NUM_LEVELS => C_PLS_LEVELS,
      G_TICK       => 1
    )
    port map (
      clk         => clk,
      resetn      => resetn,

      s_tvalid    => ev_tvalid,
      s_tready    => pls_tready,
      s_op        => ev_op,
      s_side      => ev_side,
      s_price     => ev_price,
      s_qty       => ev_qty,

      base_price  => base_price,
      oor         => pls_oor,

      busy        => pls_busy,

      lvl_we      => lvl_we,
      lvl_wsel    => lvl_wsel,
      lvl_waddr   => lvl_waddr,
      lvl_wdata   => lvl_wdata,

      lvl_raddr   => lvl_raddr,
      lvl_rdata   => lvl_rdata_i,

      m_tvalid    => tob_tvalid,
      m_tready    => tob_tready,

      m_bid_price => tob_bid_price,
      m_bid_qty   => tob_bid_qty,
      m_ask_price => tob_ask_price,
      m_ask_qty   => tob_ask_qty,
      m_valid     => tob_valid
    );

end architecture rtl;
