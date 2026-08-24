--------------------------------------------------------------------------------
-- hashKVS_pkg
--
-- Width-agnostic replacement for hash_pkg, for the key-value-store form of
-- the table where the key is (order_id, side) at 65 bits. hash_pkg keeps the
-- hand-written 16-bit masks used during bring-up; the two are interchangeable
-- at the call site, so switching is a use-clause change.
--
-- C_NUM_TABLES independent hash functions, C_KEY_W-bit key -> C_ADDR_W-bit
-- address. Geometry comes from ram_pkg, so the hashes cannot drift out of step
-- with the memory they address.
--
-- Works at any width. The masks are generated at elaboration rather than
-- written out as literals, which matters once the key reaches 65 bits: a
-- hand-written matrix would be C_NUM_TABLES * C_ADDR_W * C_KEY_W bits of
-- constants - nearly 3,000 for a 4 x 12 x 65 configuration.
--
-- HOW IT WORKS
--
-- Each output bit is the XOR of a selected subset of the key bits:
--
--     h(b) = XOR of ( key AND mask(table)(b) )
--
-- A linear map over GF(2) - an XOR tree, nothing more. Different masks give
-- different, uncorrelated hashes, which is the property multiple cuckoo tables
-- need. A plain shift would NOT give this: shifting is a bijection, so keys
-- colliding in one table would systematically collide in the next.
--
-- MASK CONSTRUCTION
--
-- Two properties, both deliberate:
--
--   1. The upper bits of each row come from a deterministic xorshift sequence,
--      giving roughly half ones spread across the key, different for every
--      (table, output bit) pair. Every key bit influences the result, and the
--      tables disagree about which keys collide.
--
--   2. The low C_ADDR_W bits of row b are one-hot at bit b. Restricted to
--      those columns the matrix is the identity, so the rows are linearly
--      independent by construction. A full-rank linear map is exactly
--      balanced: over uniform keys every address is equally likely.
--
-- Property 2 also means the low C_ADDR_W key bits pass through unmixed, XORed
-- with a function of the upper bits. For ASX order IDs, whose low word looks
-- like a dense counter, that is desirable rather than a flaw - sequential IDs
-- spread across all addresses instead of clumping.
--
-- COST
--
-- C_NUM_TABLES * C_ADDR_W XOR trees, each reducing about C_KEY_W/2 terms. A
-- 33-input XOR is two LUT6 levels, so a 4 x 12 x 65 configuration is 48 trees
-- of depth 2-3, roughly 350 LUTs. Combinational, single cycle, comfortable at
-- 156.25 MHz. All table addresses are produced at once, which is what the
-- parallel lookup path needs.
--
-- IF ORDER IDS TURN OUT TO BE DENSE
--
-- Set C_HASH_T0_IDENTITY true. Table 0 then uses the low key bits directly -
-- no XOR tree, no logic, no delay. Under fixed-order insertion table 0 takes
-- every insert, so making it collision-free for sequential IDs is the single
-- highest-value change available. Tables 1..N-1 keep the full mixing, which is
-- what they need since they receive displaced keys rather than fresh ones.
--
-- Worth measuring against a real capture before deciding.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;

package hashKVS_pkg is

  ------------------------------------------------------------------------------
  -- Use the low key bits directly for table 0 instead of an XOR tree.
  --
  -- Only correct if the low C_ADDR_W bits of the key are well distributed -
  -- true for a dense counter, false for anything sparse or clustered.
  ------------------------------------------------------------------------------
  constant C_HASH_T0_IDENTITY : boolean := false;

  type t_mask_rows   is array (0 to C_ADDR_W-1) of t_key;
  type t_mask_tables is array (0 to C_NUM_TABLES-1) of t_mask_rows;

  function build_masks return t_mask_tables;

  constant C_HASH_MASK : t_mask_tables := build_masks;

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

end package hashKVS_pkg;


package body hashKVS_pkg is

  ------------------------------------------------------------------------------
  -- Deterministic bit source for the masks.
  --
  -- Marsaglia's 64-bit xorshift. Used only at elaboration to fill constants -
  -- no hardware is generated for it.
  ------------------------------------------------------------------------------
  function xorshift64 (x : unsigned(63 downto 0)) return unsigned is
    variable v : unsigned(63 downto 0) := x;
  begin
    v := v xor shift_left(v, 13);
    v := v xor shift_right(v, 7);
    v := v xor shift_left(v, 17);
    return v;
  end function;

  ------------------------------------------------------------------------------
  function build_masks return t_mask_tables is
    variable m : t_mask_tables;
    variable s : unsigned(63 downto 0) := x"9E3779B97F4A7C15";  -- golden ratio
    variable v : t_key;
  begin
    for t in 0 to C_NUM_TABLES-1 loop
      for b in 0 to C_ADDR_W-1 loop

        -- Upper bits: one xorshift draw per bit, so the row is independent of
        -- key width and of every other row.
        for i in C_KEY_W-1 downto 0 loop
          s    := xorshift64(s);
          v(i) := s(0);
        end loop;

        -- Low C_ADDR_W bits: one-hot at b. Guarantees the rows are linearly
        -- independent, hence the map is full rank and balanced.
        v(C_ADDR_W-1 downto 0) := (others => '0');
        v(b)                   := '1';

        m(t)(b) := v;
      end loop;
    end loop;
    return m;
  end function;

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

    if C_HASH_T0_IDENTITY and tbl = 0 then
      return key(C_ADDR_W-1 downto 0);
    end if;

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

end package body hashKVS_pkg;
