--------------------------------------------------------------------------------
-- ram_sdp
--
-- Simple dual-port RAM: one write port, one read port, both on the same clock.
-- Inferred from a plain signal array, so it maps to whatever the target part
-- offers (block RAM, distributed RAM) without naming a vendor primitive.
--
-- "Simple dual-port" means one port only ever writes and the other only ever
-- reads. That is what a cuckoo table needs - lookups read while an eviction
-- chain writes - and it is cheaper than a true dual-port RAM where both ports
-- can do both.
--
-- READ LATENCY IS ONE CYCLE. rdata is registered, so the value for the
-- address presented on cycle N appears on cycle N+1. Everything downstream
-- has to be built around that; it is not optional. An unregistered
-- (asynchronous) read would stop the design inferring block RAM at all, and
-- would put the whole memory array in the combinational path.
--
-- READ-DURING-WRITE returns the OLD contents. If waddr = raddr on the same
-- cycle with we high, rdata gives what was there before the write, because
-- the read is scheduled from the signal's pre-update value. This matters for
-- back-to-back operations on one key: a read issued the cycle after a write
-- to the same address is fine, but a read in the SAME cycle is stale. That is
-- exactly why a cuckoo table needs a forwarding path around the memory rather
-- than relying on the RAM alone.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sdp is
  generic (
    G_ADDR_W : positive := 3;   -- 3 bits -> 8 locations per table
    G_DATA_W : positive := 8
  );
  port (
    clk   : in  std_logic;

    -- Write port
    we    : in  std_logic;
    waddr : in  std_logic_vector(G_ADDR_W-1 downto 0);
    wdata : in  std_logic_vector(G_DATA_W-1 downto 0);

    -- Read port, registered: rdata valid one cycle after raddr
    raddr : in  std_logic_vector(G_ADDR_W-1 downto 0);
    rdata : out std_logic_vector(G_DATA_W-1 downto 0)
  );
end entity ram_sdp;


architecture rtl of ram_sdp is

  constant C_DEPTH : positive := 2**G_ADDR_W;

  type t_ram is array (0 to C_DEPTH-1) of std_logic_vector(G_DATA_W-1 downto 0);

  -- Initialised for simulation only. Real block RAM contents after
  -- configuration are part-dependent, so nothing downstream should assume
  -- the memory starts cleared - clear it explicitly if it matters.
  signal ram : t_ram := (others => (others => '0'));

begin

  ------------------------------------------------------------------------------
  -- No reset on the memory array. Resetting thousands of RAM bits would
  -- force the synthesiser to build registers instead of a memory, and no
  -- FPGA block RAM has a reset on its contents anyway.
  ------------------------------------------------------------------------------
  p_ram : process (clk) is
  begin
    if rising_edge(clk) then

      if we = '1' then
        ram(to_integer(unsigned(waddr))) <= wdata;
      end if;

      -- Read scheduled before the write above takes effect, giving
      -- read-during-write = old data.
      rdata <= ram(to_integer(unsigned(raddr)));

    end if;
  end process p_ram;

end architecture rtl;
