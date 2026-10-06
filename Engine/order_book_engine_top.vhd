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
-- TIMESTAMPING
--
-- Four event sources are stamped from one free-running counter and merged
-- into time_event_fifo. Its output leaves on ev_valid / ev_ready / ev_payload
-- for the TX framer.
--
--   source  valid              op                   data (64 bits)  side
--   price   lvl_we             price_storage ts_op  qty & price     ps ts_side
--   order   order_book ts_en   order_book ts_op     order_id        ob ts_side
--   input   in_tvalid          in_op                order_id        in_side
--   fifo    order_fifo ts_en   cmd_op               order_id        cmd_side
--
-- Op is t_book_op'pos: ADD "00", EXEC "01", REPLACE "10", DELETE "11".
--
--   ev_payload (MSB first): event_type(2) op(2) data(64) side(1) ts(18)
--
-- The payload is also decoded back into ev_type / ev_op / ev_data / ev_side /
-- ev_ts. Those are internal signals for viewing in simulation and drive
-- nothing. ev_data is 65 bits, data & side, with side in bit 0.
--
-- ev_ready comes from the TX framer, which is busy for a whole frame per
-- event, so an event now sits on the output until it is taken. Nothing pushes
-- back into the book: time_event_fifo has no ready on its inputs, and does not
-- handle overflow.
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
    -- FCS result from input_top. Registered in order_fifo, unused otherwise.
    ----------------------------------------------------------------------------
    fcs_complete  : in    std_logic;
    fcs_true      : in    std_logic;
    fcs_false     : in    std_logic;
    fcs_flags     : out   std_logic_vector(2 downto 0);

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
    -- Master: timestamp event stream, to the TX framer
    --
    -- payload (MSB first): event_type(2) op(2) data(64) side(1) ts(18)
    ----------------------------------------------------------------------------
    ev_valid      : out   std_logic;
    ev_ready      : in    std_logic;
    ev_payload    : out   std_logic_vector(86 downto 0);

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

  ------------------------------------------------------------------------------
  -- Timestamping
  --
  -- C_TS_W must match the 18-bit timestamp port on time_event_fifo, and the
  -- field positions below must match its m_payload layout.
  ------------------------------------------------------------------------------
  constant C_TS_W     : positive := 18;
  constant C_EV_DEPTH : positive := 32;   -- power of two, >= 8

  -- m_payload fields, MSB first: event_type(2) op(2) data(64) side(1) ts(18)
  subtype EV_TYPE_RANGE is natural range 86 downto 85;
  subtype EV_OP_RANGE   is natural range 84 downto 83;
  subtype EV_DATA_RANGE is natural range 82 downto 18;   -- data & side
  constant C_EV_SIDE_BIT : natural := 18;
  subtype EV_TS_RANGE   is natural range 17 downto 0;

  function f_op (op : t_book_op) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(t_book_op'pos(op), 2));
  end function f_op;

  signal ts_count : std_logic_vector(C_TS_W - 1 downto 0);

  -- Raw timestamp taps out of the modules
  signal fifo_ts_en : std_logic;
  signal ob_ts_en   : std_logic;
  signal ob_ts_op   : t_book_op;
  signal ob_ts_side : std_logic;
  signal ob_ts_id   : std_logic_vector(63 downto 0);
  signal ps_ts_op   : t_book_op;
  signal ps_ts_side : std_logic;

  -- Event FIFO inputs
  signal price_ev_valid : std_logic;
  signal price_ev_op    : std_logic_vector(1 downto 0);
  signal price_ev_data  : std_logic_vector(63 downto 0);
  signal price_ev_side  : std_logic;

  signal order_ev_valid : std_logic;
  signal order_ev_op    : std_logic_vector(1 downto 0);
  signal order_ev_data  : std_logic_vector(63 downto 0);
  signal order_ev_side  : std_logic;

  signal input_ev_valid : std_logic;
  signal input_ev_op    : std_logic_vector(1 downto 0);
  signal input_ev_data  : std_logic_vector(63 downto 0);
  signal input_ev_side  : std_logic;

  signal fifo_ev_valid  : std_logic;
  signal fifo_ev_op     : std_logic_vector(1 downto 0);
  signal fifo_ev_data   : std_logic_vector(63 downto 0);
  signal fifo_ev_side   : std_logic;

  -- Event FIFO output, as it leaves on the ports
  signal ev_valid_i   : std_logic;
  signal ev_payload_i : std_logic_vector(86 downto 0);

  -- The payload decoded back into its fields. Viewed in simulation only.
  signal ev_type : std_logic_vector(1 downto 0);
  signal ev_op   : std_logic_vector(1 downto 0);
  signal ev_data : std_logic_vector(64 downto 0);   -- data & side, side in bit 0
  signal ev_side : std_logic;
  signal ev_ts   : std_logic_vector(C_TS_W - 1 downto 0);

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
      overflow   => fifo_overflow,

      ts_en      => fifo_ts_en,

      fcs_complete => fcs_complete,
      fcs_true     => fcs_true,
      fcs_false    => fcs_false,
      fcs_flags    => fcs_flags
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
      m_op       => mut_op,

      ts_op      => ob_ts_op,
      ts_en      => ob_ts_en,
      ts_side    => ob_ts_side,
      ts_id      => ob_ts_id
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
      m_valid     => m_valid,

      ts_op       => ps_ts_op,
      ts_side     => ps_ts_side
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

  ------------------------------------------------------------------------------
  -- Timestamping
  ------------------------------------------------------------------------------
  u_ts_counter : entity work.timestamp_counter
    generic map (
      WIDTH => C_TS_W
    )
    port map (
      clk     => clk,
      rst_n   => resetn,
      count_o => ts_count
    );

  -- price: one event per level write. ts_op and ts_side are registered with
  -- lvl_we, so all three line up with the write on the bus.
  price_ev_valid <= lvl_we;
  price_ev_op    <= f_op(ps_ts_op);
  price_ev_data  <= lvl_wdata(LVL_QTY_RANGE) & lvl_wdata(LVL_PRICE_RANGE);
  price_ev_side  <= ps_ts_side;

  -- order: first table write of each command only (eviction hops excluded).
  -- id, side and op are latched on the order_book slave handshake.
  order_ev_valid <= ob_ts_en;
  order_ev_op    <= f_op(ob_ts_op);
  order_ev_data  <= ob_ts_id;
  order_ev_side  <= ob_ts_side;

  -- input: the one-cycle command pulse out of book_input_stage.
  input_ev_valid <= in_tvalid;
  input_ev_op    <= f_op(in_op);
  input_ev_data  <= in_order_id;
  input_ev_side  <= in_side;

  -- fifo: the master handshake, i.e. the cycle order_book takes the command.
  fifo_ev_valid  <= fifo_ts_en;
  fifo_ev_op     <= f_op(cmd_op);
  fifo_ev_data   <= cmd_order_id;
  fifo_ev_side   <= cmd_side;

  u_time_event_fifo : entity work.time_event_fifo
    generic map (
      DEPTH => C_EV_DEPTH
    )
    port map (
      clk         => clk,
      rst_n       => resetn,

      timestamp   => ts_count,

      price_valid => price_ev_valid,
      price_op    => price_ev_op,
      price_data  => price_ev_data,
      price_side  => price_ev_side,

      order_valid => order_ev_valid,
      order_op    => order_ev_op,
      order_data  => order_ev_data,
      order_side  => order_ev_side,

      input_valid => input_ev_valid,
      input_op    => input_ev_op,
      input_data  => input_ev_data,
      input_side  => input_ev_side,

      fifo_valid  => fifo_ev_valid,
      fifo_op     => fifo_ev_op,
      fifo_data   => fifo_ev_data,
      fifo_side   => fifo_ev_side,

      m_valid     => ev_valid_i,
      m_ready     => ev_ready,
      m_payload   => ev_payload_i
    );

  ev_valid   <= ev_valid_i;
  ev_payload <= ev_payload_i;

  -- Decode, for the waveform. An event is on these while ev_valid is high, and
  -- is taken on the cycle ev_valid and ev_ready are both high.
  ev_type <= ev_payload_i(EV_TYPE_RANGE);
  ev_op   <= ev_payload_i(EV_OP_RANGE);
  ev_data <= ev_payload_i(EV_DATA_RANGE);
  ev_side <= ev_payload_i(C_EV_SIDE_BIT);
  ev_ts   <= ev_payload_i(EV_TS_RANGE);

end architecture rtl;
