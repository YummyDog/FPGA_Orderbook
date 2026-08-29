--------------------------------------------------------------------------------
-- order_book_top
--
-- Wires order_book to a real ram_array. Exists because order_book exposes its
-- memory ports rather than owning the memory, so it cannot be simulated on its
-- own without something on the other end of those ports.
--
-- The testbench drives this, and reads the table contents straight out of the
-- RAM signals through the design hierarchy:
--
--     u_ram_arr.g_tables[t].u_ram.ram[addr]
--
-- which is the actual memory the DUT is writing to, not a model of it.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;
use work.order_book_pkg.all;

entity order_book_top is
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;

    ----------------------------------------------------------------------------
    -- Slave: normalised command bus
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
    s_lookup   : in  std_logic;                    -- 1 = probe only, no write


    busy          : out std_logic;
    lookup_found  : out std_logic;   -- high when lookup_return is valid
    lookup_return : out t_key
  );
end entity order_book_top;


architecture rtl of order_book_top is

  -- Memory interconnect. Exposed as signals so the testbench can watch them
  -- as well as the RAM contents.
  signal we    : std_logic;
  signal wsel  : t_sel;
  signal waddr : t_addr;
  signal wdata : t_slot;
  signal raddr : t_addr_set;
  signal rdata : t_slot_set;

begin

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
      s_lookup   => s_lookup,

      busy       => busy,
      lookup_found  => lookup_found,
      lookup_return => lookup_return,

      we         => we,
      wsel       => wsel,
      waddr      => waddr,
      wdata      => wdata,
      raddr      => raddr,
      rdata      => rdata
    );

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

end architecture rtl;
