--------------------------------------------------------------------------------
-- ram_sdp
--
-- Simple dual-port RAM: one write port, one read port, both on the same clock.
-- Inferred from a plain signal array, so it maps to whatever the target part
-- offers without naming a vendor primitive.
--
-- Matches the AMD UG901 simple dual-port template. "Simple dual-port" means
-- one port only ever writes and the other only ever reads - what a cuckoo
-- table needs, and cheaper than a true dual-port where both do both.
--
-- READ LATENCY IS ONE CYCLE by default. rdata is registered, so the value for
-- the address presented on cycle N appears on cycle N+1. An unregistered read
-- would stop block RAM inferring at all and put the whole memory array in the
-- combinational path.
--
-- Setting G_OUT_REG adds a second register stage, making it TWO cycles. That
-- is the standard way to close timing on deep cascaded BRAM, where the tool
-- inserts an output mux per doubling beyond one tile. Note this is a design
-- change, not a free knob: every index offset in the engine's FSM assumes the
-- latency, so C_READ_LATENCY in ram_pkg has to be honoured downstream.
--
-- READ-DURING-WRITE RETURNS OLD DATA. If waddr = raddr on the same cycle with
-- we high, rdata gives the pre-write contents, because the read is scheduled
-- from the signal's pre-update value. This is READ_FIRST behaviour, supported
-- for SDP with a common clock, and it is what lets back-to-back operations on
-- one key work without a forwarding path - provided the engine holds off the
-- second until the first write commits.
--
-- G_RAM_STYLE is passed to Vivado as a hint. It is a vendor attribute but
-- attribute declarations are ignored by tools that do not recognise them, so
-- this stays portable in a way that instantiating XPM_MEMORY would not.
-- Useful for a sweep: forcing "block" versus "distributed" at a size where
-- the tool would choose differently isolates one variable.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sdp is
  generic (
    G_ADDR_W    : positive := 3;
    G_DATA_W    : positive := 17;

    -- Extra output register. Read latency becomes 2.
    G_OUT_REG   : boolean := false;

    -- "auto" | "block" | "distributed" | "ultra" | "registers"
    G_RAM_STYLE : string := "auto"
  );
  port (
    clk   : in  std_logic;

    -- Write port
    we    : in  std_logic;
    waddr : in  std_logic_vector(G_ADDR_W-1 downto 0);
    wdata : in  std_logic_vector(G_DATA_W-1 downto 0);

    -- Read port, registered. Valid G_OUT_REG ? 2 : 1 cycles after raddr.
    raddr : in  std_logic_vector(G_ADDR_W-1 downto 0);
    rdata : out std_logic_vector(G_DATA_W-1 downto 0)
  );
end entity ram_sdp;


architecture rtl of ram_sdp is

  constant C_DEPTH : positive := 2**G_ADDR_W;

  type t_ram is array (0 to C_DEPTH-1) of std_logic_vector(G_DATA_W-1 downto 0);

  -- Initialised for simulation only. Real block RAM contents after
  -- configuration are part-dependent, so nothing downstream should assume the
  -- memory starts cleared.
  --
  -- At large depths this initialiser is also the thing that makes elaboration
  -- slow - it is a per-element assignment across C_DEPTH * G_DATA_W bits.
  signal ram : t_ram := (others => (others => '0'));

  attribute ram_style : string;
  attribute ram_style of ram : signal is G_RAM_STYLE;

  signal rdata_1 : std_logic_vector(G_DATA_W-1 downto 0) := (others => '0');

begin

  ------------------------------------------------------------------------------
  -- No reset on the memory array. Resetting thousands of RAM bits would force
  -- the synthesiser to build registers instead of a memory, and no FPGA block
  -- RAM has a reset on its contents anyway.
  ------------------------------------------------------------------------------
  p_ram : process (clk) is
  begin
    if rising_edge(clk) then

      if we = '1' then
        ram(to_integer(unsigned(waddr))) <= wdata;
      end if;

      -- Read scheduled before the write above takes effect, giving
      -- read-during-write = old data.
      rdata_1 <= ram(to_integer(unsigned(raddr)));

    end if;
  end process p_ram;

  ------------------------------------------------------------------------------
  -- Optional second stage. Kept as a separate register rather than folded in,
  -- so the synthesiser can absorb it into the BRAM's own output register
  -- rather than building fabric flops.
  ------------------------------------------------------------------------------
  gen_out_reg : if G_OUT_REG generate
    p_out : process (clk) is
    begin
      if rising_edge(clk) then
        rdata <= rdata_1;
      end if;
    end process p_out;
  end generate gen_out_reg;

  gen_no_out_reg : if not G_OUT_REG generate
    rdata <= rdata_1;
  end generate gen_no_out_reg;

end architecture rtl;
