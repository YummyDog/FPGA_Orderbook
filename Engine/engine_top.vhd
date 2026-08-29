--------------------------------------------------------------------------------
-- engine_top
--
-- Synthesis top level: book_input_stage -> order_book -> ram_array.
--
-- Built for out-of-context synthesis, to get a utilisation figure and a
-- critical path without a board, a pinout or an I/O standard:
--
--     synth_design -mode out_of_context -top engine_top -part <part>
--     report_timing_summary
--     report_utilization -hierarchical
--
-- Every output is driven from something the design computes, and every input
-- reaches logic that matters, so nothing here should be optimised away. If
-- the utilisation report comes back near-empty, that is the first thing to
-- check.
--
-- WHAT THIS IS NOT
--
-- Not a functional integration. key_op is derived from the decoded message
-- type by a fixed map (see below) purely so the engine has an operation to
-- perform; the real design needs a sequencer, since a REPLACE is a lookup
-- then a delete then an insert, and an EXEC needs the stored quantity read
-- back before it can be modified. That sequencer does not exist yet.
--
-- It is still the right shape for a timing measurement: the paths that will
-- dominate - the hash trees, the parallel compare, the write-port mux, the
-- memory address setup - are all present and connected as they will be.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;
use work.order_book_pkg.all;

entity engine_top is
  generic (
    -- Instrument this engine instance tracks.
    G_ORDER_BOOK_ID : natural  := 85603;

    -- Raw ITCH message buffer width, in bytes.
    G_MSG_BYTES     : positive := 64
  );
  port (
    clk           : in  std_logic;
    resetn        : in  std_logic;

    ----------------------------------------------------------------------------
    -- Slave: raw ITCH messages from the parser FIFO
    ----------------------------------------------------------------------------
    s_tvalid      : in  std_logic;
    s_tready      : out std_logic;
    s_ttype       : in  std_logic_vector(7 downto 0);
    s_tdata       : in  std_logic_vector(G_MSG_BYTES*8-1 downto 0);

    ----------------------------------------------------------------------------
    -- Status. Registered inside the engine, brought out so synthesis keeps
    -- the logic that produces them.
    ----------------------------------------------------------------------------
    busy          : out std_logic;
    lookup_found  : out std_logic;
    lookup_return : out t_key
  );
end entity engine_top;


architecture rtl of engine_top is

  ------------------------------------------------------------------------------
  -- Normalised command bus, book_input_stage -> order_book
  ------------------------------------------------------------------------------
  signal cmd_tvalid   : std_logic;
  signal cmd_tready   : std_logic;

  signal cmd_op       : t_book_op;
  signal cmd_order_id : std_logic_vector(63 downto 0);
  signal cmd_book_id  : std_logic_vector(31 downto 0);
  signal cmd_side     : std_logic;
  signal cmd_qty      : unsigned(31 downto 0);
  signal cmd_price    : signed(31 downto 0);
  signal cmd_px_valid : std_logic;
  signal cmd_undisc   : std_logic;
  signal cmd_implied  : std_logic;

  -- order_book takes these as plain vectors, so the numeric types from the
  -- input stage are converted here. Rewiring only - no logic.
  signal cmd_qty_slv   : std_logic_vector(31 downto 0);
  signal cmd_price_slv : std_logic_vector(31 downto 0);
  ------------------------------------------------------------------------------
  -- Memory interconnect, order_book <-> ram_array
  ------------------------------------------------------------------------------
  signal we    : std_logic;
  signal wsel  : t_sel;
  signal waddr : t_addr;
  signal wdata : t_slot;
  signal raddr : t_addr_set;
  signal rdata : t_slot_set;

begin

  ------------------------------------------------------------------------------
  -- Module 1: filter and normalise
  ------------------------------------------------------------------------------
  u_input : entity work.book_input_stage
    generic map (
      G_ORDER_BOOK_ID => G_ORDER_BOOK_ID,
      G_MSG_BYTES     => G_MSG_BYTES
    )
    port map (
      clk        => clk,
      resetn     => resetn,

      s_tvalid   => s_tvalid,
      s_tready   => s_tready,
      s_ttype    => s_ttype,
      s_tdata    => s_tdata,

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
      m_implied  => cmd_implied
    );

  cmd_qty_slv   <= std_logic_vector(cmd_qty);
  cmd_price_slv <= std_logic_vector(cmd_price);

  ------------------------------------------------------------------------------
  -- Operation map, message type -> table operation.
  --
  -- A placeholder. The real mapping is not one-to-one:
  --
  --   ADD      insert, but must probe first - an A can arrive for an order
  --            ID already resting (reactivation, or after a sequence gap)
  --   EXEC     probe, read the stored quantity, subtract, then either write
  --            back or remove if it reaches zero
  --   REPLACE  probe, then rewrite price and quantity in place - the key is
  --            unchanged, so the slot cannot move
  --   DELETE   probe, clear the valid bit
  --
  -- Collapsing those to a single cycle of key_op is wrong functionally but
  -- exercises every path for synthesis, which is what this top level is for.
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- The engine
  ------------------------------------------------------------------------------
  u_book : entity work.order_book
    port map (
      clk           => clk,
      resetn        => resetn,

      s_tvalid      => cmd_tvalid,
      s_tready      => cmd_tready,

      s_op          => cmd_op,
      s_order_id    => cmd_order_id,
      s_book_id     => cmd_book_id,
      s_side        => cmd_side,
      s_qty         => cmd_qty_slv,
      s_price       => cmd_price_slv,
      s_px_valid    => cmd_px_valid,
      s_undisc      => cmd_undisc,
      s_implied     => cmd_implied,

      busy          => busy,
      lookup_return => lookup_return,
      lookup_found  => lookup_found,

      we            => we,
      wsel          => wsel,
      waddr         => waddr,
      wdata         => wdata,
      raddr         => raddr,
      rdata         => rdata
    );

  ------------------------------------------------------------------------------
  -- The tables
  ------------------------------------------------------------------------------
  u_ram : entity work.ram_array
    port map (
      clk   => clk,
      we    => we,
      wsel  => wsel,
      waddr => waddr,
      wdata => wdata,
      raddr => raddr,
      rdata => rdata
    );

end architecture rtl;
