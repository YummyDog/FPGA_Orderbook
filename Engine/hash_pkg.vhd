--------------------------------------------------------------------------------
-- hash_pkg
--
-- C_NUM_TABLES independent hash functions, C_KEY_W-bit key -> C_ADDR_W-bit
-- address. Geometry and types come from ram_pkg, so the hashes cannot drift
-- out of step with the memory they address.
--
-- Default: 16-bit key -> 3-bit address, 4 tables.
--
-- HOW IT WORKS
--
-- Each output bit is the XOR of a selected subset of the key bits:
--
--     h(b) = XOR of ( key AND mask(table)(b) )
--
-- A linear map over GF(2) - an XOR tree, nothing more. Each mask row picks
-- which key bits feed one output bit. Different masks give different,
-- uncorrelated hashes, which is the property multiple cuckoo tables need.
--
-- A plain shift would NOT give this: shifting is a bijection, so keys
-- colliding in one table would systematically collide in the next, and the
-- extra tables would buy nothing.
--
-- WHY THESE MASKS
--
--   1. Within a table, the rows end in 001, 010, 100. Restricted to key bits
--      2..0 the matrix is the identity, so the rows are linearly independent
--      by construction. A full-rank linear map is exactly balanced: over
--      uniform keys every address is equally likely, no slot favoured.
--      KEEP THIS PATTERN if you change the masks - a rank-2 map would quietly
--      produce only half the addresses.
--
--   2. The upper bits of every row are roughly half ones, spread across the
--      key, and differ between tables. Every key bit influences the result,
--      and the tables disagree about which keys collide.
--
-- COST
--
-- C_NUM_TABLES * C_ADDR_W XOR trees, each reducing at most C_KEY_W bits:
-- depth 4 for a 16-bit key. Combinational, single cycle, trivial at
-- 156.25 MHz. All table addresses are produced at once, which is what the
-- parallel lookup path needs.
--
-- BEFORE COMMITTING TO THIS
--
-- If ASX order IDs hold a dense counter in their low bits, the best hash is
-- no hash at all: taking the low address bits directly maps sequential keys
-- to sequential slots with zero collisions, beating any mixing function.
-- Worth measuring against a real capture before assuming randomness is wanted.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;

package hash_pkg is

  ------------------------------------------------------------------------------
  -- Mask matrix: [table][output bit] -> which key bits to XOR together
  --
  -- The literal below is written for C_NUM_TABLES = 4, C_ADDR_W = 3,
  -- C_KEY_W = 16. Changing any of those in ram_pkg requires reworking it.
  ------------------------------------------------------------------------------
  type t_mask_rows   is array (0 to C_ADDR_W-1) of t_key;
  type t_mask_tables is array (0 to C_NUM_TABLES-1) of t_mask_rows;

  constant C_HASH_MASK : t_mask_tables := (
    --        bit 0      bit 1      bit 2
    0 => (x"ACD1", x"6962", x"D38C"),
    1 => (x"CB59", x"B5A2", x"5ADC"),
    2 => (x"E539", x"9CCA", x"376C"),
    3 => (x"DCA9", x"A69A", x"6E74")
  );

  ------------------------------------------------------------------------------
  -- XOR-reduce a vector to a single bit.
  --
  -- VHDL-2008 has a unary "xor" operator that does this, but it is spelled out
  -- here so the tree is visible and the code survives a tool with patchy 2008
  -- support.
  ------------------------------------------------------------------------------
  function xor_reduce (v : std_logic_vector) return std_logic;

  -- Address of key in one table
  function hash (key : t_key; tbl : natural) return t_addr;

  -- Every table's address at once. Feeds ram_array's raddr directly, for both
  -- the parallel lookup path and fixed-order insertion (which uses one element
  -- at a time, indexed by the table counter).
  function hash_all (key : t_key) return t_addr_set;

end package hash_pkg;


package body hash_pkg is

  ------------------------------------------------------------------------------
  function xor_reduce (v : std_logic_vector) return std_logic is
    variable acc : std_logic := '0';
  begin
    for i in v'range loop
      acc := acc xor v(i);
    end loop;
    return acc;
  end function;

  ------------------------------------------------------------------------------
  -- h(b) = parity of the key bits selected by mask row b.
  --
  -- Synthesises to C_ADDR_W independent XOR trees. The AND is free: a masked
  -- bit is simply not wired into the tree.
  ------------------------------------------------------------------------------
  function hash (key : t_key; tbl : natural) return t_addr is
    variable h : t_addr;
  begin
    assert tbl < C_NUM_TABLES
      report "hash: table index " & integer'image(tbl) & " out of range"
      severity failure;

    for b in 0 to C_ADDR_W-1 loop
      h(b) := xor_reduce(key and C_HASH_MASK(tbl)(b));
    end loop;

    return h;
  end function;

  ------------------------------------------------------------------------------
  -- All tables in parallel.
  --
  -- On lookup every element is used: the key may rest anywhere, so all
  -- candidate slots are read and compared at once.
  --
  -- On fixed-order insertion only one element is used per hop - but note the
  -- key changes at every hop. Hop 1 needs hash_all(victim)(1), not
  -- hash_all(original_key)(1), so this must be recomputed from the key
  -- currently in flight rather than latched once at the start.
  ------------------------------------------------------------------------------
  function hash_all (key : t_key) return t_addr_set is
    variable a : t_addr_set;
  begin
    for t in 0 to C_NUM_TABLES-1 loop
      a(t) := hash(key, t);
    end loop;
    return a;
  end function;

end package body hash_pkg;
