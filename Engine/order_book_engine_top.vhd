--------------------------------------------------------------------------------
-- order_book_engine_top
--
-- Structural top for the ASX ITCH order book engine.
--
--   msg_fields -> book_input_stage -> order_fifo -> order_book -> price_storage
--                                                       |              |
--                                                   ram_array      level_array
--
-- Nothing but wiring lives here. Geometry comes from ram_pkg and level_pkg, so
-- the memories take no generics.
--
-- The slave port is one decoded message per cycle in the C_FLD_* layout from
-- itch_parser_pkg - no beats, no assembly, no handshake. book_input_stage
-- normalises it and emits a one-cycle command pulse; order_fifo absorbs that,
-- since its s_tready is hardwired high.
--
-- Note the dependency direction: the engine now uses itch_parser_pkg, for
-- C_MSG_FIELDS_W and the field offsets. That is the price of deleting the
-- second decoder - the message layout is defined in exactly one place and the
-- engine reads it from there.
--
-- price_storage does not drive its status or top-of-book outputs yet; those
-- ports are brought out regardless so the interface does not change when it
-- does.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.ram_pkg.all;
  use work.order_book_pkg.all;
  use work.level_pkg.all;
  use work.itch_parser_pkg.all;

entity order_book_engine_top is
  generic (
    G_ORDER_BOOK_ID : natural  := 85603;   -- instrument this instance tracks
    G_FIFO_DEPTH    : positive := 16;      -- commands buffered before order_book
    G_MAX_ORDERS    : natural  := 16384
  );
  port (
    clk           : in    std_logic;
    resetn        : in    std_logic;

    ----------------------------------------------------------------------------
    -- Slave: one decoded message per cycle from itch_parser. No handshake.
    ----------------------------------------------------------------------------
    s_valid       : in    std_logic;
    s_type        : in    std_logic_vector(7 downto 0);
    s_fields      : in    std_logic_vector(C_MSG_FIELDS_W - 1 downto 0);

    ----------------------------------------------------------------------------
    -- Price window
    ----------------------------------------------------------------------------
    base_price    : in    std_logic_vector(31 downto 0);

    ----------------------------------------------------------------------------
    -- Master: top of book
    ----------------------------------------------------------------------------
    m_tvalid      : out   std_logic;
    m_tready      : in    std_logic;

    m_bid_price   : out   std_logic_vector(31 downto 0);
    m_bid_qty     : out   std_logic_vector(31 downto 0);
    m_ask_price   : out   std_logic_vector(31 downto 0);
    m_ask_qty     : out   std_logic_vector(31 downto 0);
    m_valid       : out   std_logic_vector(1 downto 0);

    ----------------------------------------------------------------------------
    -- Status
    ----------------------------------------------------------------------------
    book_busy     : out   std_logic;
    level_busy    : out   std_logic;
    oor           : out   std_logic;
    fifo_full     : out   std_logic;
    fifo_overflow : out   std_logic;
    stat_bad_side : out   std_logic;   -- right book, unrecognised side byte
    stat_qty_ovf  : out   std_logic    -- wire quantity exceeded 32 bits
  );
end entity order_book_engine_top;

architecture rtl of order_book_engine_top is

  ------------------------------------------------------------------------------
  -- book_input_stage -> order_fifo
  --
  -- in_tvalid is a one-cycle pulse. There is no ready in this direction.
  ------------------------------------------------------------------------------
  signal in_tvalid   : std_logic;
  signal in_op       : t_book_op;
  signal in_order_id : std_logic_vector(63 downto 0);
  signal in_book_id  : std_logic_vector(31 downto 0);
  signal in_side     : std_logic;
  signal in_qty      : unsigned(31 downto 0);
  signal in_price    : signed(31 downto 0);
  signal in_px_valid : std_logic;
  signal in_undisc   : std_logic;
  signal in_implied  : std_logic;

  signal fifo_ready  : std_logic;   -- hardwired high inside order_fifo

  ------------------------------------------------------------------------------
  -- order_fifo -> order_book
  ------------------------------------------------------------------------------
  signal cmd_tvalid   : std_logic;
  signal cmd_tready   : std_logic;
  signal cmd_op       : t_book_op;
  signal cmd_order_id : std_logic_vector(63 downto 0);
  signal cmd_book_id  : std_logic_vector(31 downto 0);
  signal cmd_side     : std_logic;
  signal cmd_qty      : std_logic_vector(31 downto 0);
  signal cmd_price    : std_logic_vector(31 downto 0);
  signal cmd_px_valid : std_logic;
  signal cmd_undisc   : std_logic;
  signal cmd_implied  : std_logic;

  ------------------------------------------------------------------------------
  -- order_book <-> ram_array
  ------------------------------------------------------------------------------
  signal ram_we    : std_logic;
  signal ram_wsel  : t_sel;
  signal ram_waddr : t_addr;
  signal ram_wdata : t_slot;
  signal ram_raddr : t_addr_set;
  signal ram_rdata : t_slot_set;

  ------------------------------------------------------------------------------
  -- order_book -> price_storage
  ------------------------------------------------------------------------------
  signal mut_tvalid : std_logic;
  signal mut_tready : std_logic;
  signal mut_op     : t_book_op;
  signal mut_side   : std_logic;
  signal mut_price  : std_logic_vector(31 downto 0);
  signal mut_qty    : std_logic_vector(31 downto 0);

  ------------------------------------------------------------------------------
  -- price_storage <-> level_array
  ------------------------------------------------------------------------------
  signal lvl_we        : std_logic;
  signal lvl_wsel      : std_logic;
  signal lvl_waddr     : t_lvl_addr;
  signal lvl_wdata     : t_level;
  signal lvl_raddr     : t_lvl_addr;
  signal lvl_raddr_set : t_lvl_addr_set;
  signal lvl_rdata     : t_level_set;

begin

  ------------------------------------------------------------------------------
  -- Normalise and filter. One combinational level plus the output register.
  ------------------------------------------------------------------------------
  u_book_input_stage : entity work.book_input_stage
    generic map (
      G_ORDER_BOOK_ID => G_ORDER_BOOK_ID
    )
    port map (
      clk           => clk,
      resetn        => resetn,

      s_valid       => s_valid,
      s_type        => s_type,
      s_fields      => s_fields,

      m_tvalid      => in_tvalid,
      m_op          => in_op,
      m_order_id    => in_order_id,
      m_book_id     => in_book_id,
      m_side        => in_side,
      m_qty         => in_qty,
      m_price       => in_price,
      m_px_valid    => in_px_valid,
      m_undisc      => in_undisc,
      m_implied     => in_implied,

      stat_bad_side => stat_bad_side,
      stat_qty_ovf  => stat_qty_ovf
    );

  ------------------------------------------------------------------------------
  -- Elastic buffer. Also the unsigned/signed to std_logic_vector cast point.
  --
  -- The command pulse has nowhere to wait, so the FIFO taking it every cycle is
  -- what makes the stage above safe. Checked rather than assumed.
  ------------------------------------------------------------------------------
  u_order_fifo : entity work.order_fifo
    generic map (
      G_DEPTH => G_FIFO_DEPTH
    )
    port map (
      clk        => clk,
      resetn     => resetn,

      s_tvalid   => in_tvalid,
      s_tready   => fifo_ready,
      s_op       => in_op,
      s_order_id => in_order_id,
      s_book_id  => in_book_id,
      s_side     => in_side,
      s_qty      => in_qty,
      s_price    => in_price,
      s_px_valid => in_px_valid,
      s_undisc   => in_undisc,
      s_implied  => in_implied,

      m_tvalid   => cmd_tvalid,
      m_tready   => cmd_tready,
      m_op       => cmd_op,
      m_order_id => cmd_order_id,
      m_book_id  => cmd_book_id,
      m_side     => cmd_side,
      m_qty      => cmd_qty,
      m_price    => cmd_price,
      m_px_valid => cmd_px_valid,
      m_undisc   => cmd_undisc,
      m_implied  => cmd_implied,

      full       => fifo_full,
      overflow   => fifo_overflow
    );

  assert not (rising_edge(clk) and in_tvalid = '1' and fifo_ready = '0')
    report "order_book_engine_top: command pulse dropped, order_fifo was not ready"
    severity failure;

  ------------------------------------------------------------------------------
  -- Order table
  ------------------------------------------------------------------------------
  u_order_book : entity work.order_book
    generic map (
      G_MAX_ORDERS => G_MAX_ORDERS
    )
    port map (
      clk        => clk,
      resetn     => resetn,

      s_tvalid   => cmd_tvalid,
      s_tready   => cmd_tready,
      s_op       => cmd_op,
      s_order_id => cmd_order_id,
      s_book_id  => cmd_book_id,
      s_side     => cmd_side,
      s_qty      => cmd_qty,
      s_price    => cmd_price,
      s_px_valid => cmd_px_valid,
      s_undisc   => cmd_undisc,
      s_implied  => cmd_implied,

      busy       => book_busy,

      we         => ram_we,
      wsel       => ram_wsel,
      waddr      => ram_waddr,
      wdata      => ram_wdata,
      raddr      => ram_raddr,
      rdata      => ram_rdata,

      m_tvalid   => mut_tvalid,
      m_tready   => mut_tready,
      m_side     => mut_side,
      m_qty      => mut_qty,
      m_price    => mut_price,
      m_op       => mut_op
    );

  u_ram_array : entity work.ram_array
    port map (
      clk   => clk,
      we    => ram_we,
      wsel  => ram_wsel,
      waddr => ram_waddr,
      wdata => ram_wdata,
      raddr => ram_raddr,
      rdata => ram_rdata
    );

  ------------------------------------------------------------------------------
  -- Price level aggregation.
  --
  -- G_NUM_LEVELS is set from C_LVL_DEPTH so the port widths derived from it
  -- match t_lvl_addr; the default of 1024 does not.
  ------------------------------------------------------------------------------
  u_price_storage : entity work.price_storage
    generic map (
      G_NUM_LEVELS => C_LVL_DEPTH,
      G_TICK       => 1
    )
    port map (
      clk         => clk,
      resetn      => resetn,

      s_tvalid    => mut_tvalid,
      s_tready    => mut_tready,
      s_op        => mut_op,
      s_side      => mut_side,
      s_price     => mut_price,
      s_qty       => mut_qty,

      base_price  => base_price,
      oor         => oor,
      busy        => level_busy,

      lvl_we      => lvl_we,
      lvl_wsel    => lvl_wsel,
      lvl_waddr   => lvl_waddr,
      lvl_wdata   => lvl_wdata,
      lvl_raddr   => lvl_raddr,
      lvl_rdata   => lvl_rdata,

      m_tvalid    => m_tvalid,
      m_tready    => m_tready,
      m_bid_price => m_bid_price,
      m_bid_qty   => m_bid_qty,
      m_ask_price => m_ask_price,
      m_ask_qty   => m_ask_qty,
      m_valid     => m_valid
    );

  -- price_storage issues one read address; both sides are read at it.
  lvl_raddr_set <= (others => lvl_raddr);

  u_level_array : entity work.level_array
    port map (
      clk   => clk,
      we    => lvl_we,
      wsel  => lvl_wsel,
      waddr => lvl_waddr,
      wdata => lvl_wdata,
      raddr => lvl_raddr_set,
      rdata => lvl_rdata
    );

end architecture rtl;
