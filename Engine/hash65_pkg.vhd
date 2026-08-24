--------------------------------------------------------------------------------
-- hash65_pkg
--
-- C_NUM_TABLES independent hash functions, 65-bit key -> C_ADDR_W-bit address.
--
-- KEY LAYOUT
--
--     bit 64      63                                          0
--    +--------+----------------------------------------------+
--    |  side  |                  order_id                    |
--    +--------+----------------------------------------------+
--
-- Order IDs are unique only within an order book AND side (spec 2.6), so a buy
-- and a sell order can legitimately carry the same numeric ID. Folding side
-- into the key is what keeps them distinct - drop it and the two become the
-- same key, which the table cannot tell apart at all. That is a duplicate key
-- rather than a hash collision, and no amount of hashing recovers from it.
--
-- Use make_key() rather than concatenating by hand, so the bit position is
-- defined in one place.
--
-- Requires C_KEY_W = 65 in ram_pkg. Multi-symbol would extend this to 97 bits
-- with order_book_id, or better, to 65 + log2(symbols) via a symbol index -
-- the construction below is width-agnostic either way.
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
-- SIDE IS TREATED AS AN ORDINARY KEY BIT
--
-- Deliberately. XORing side into one output bit would put a buy order and its
-- same-ID sell counterpart in adjacent slots in every table - correlated
-- placement, and a wasted opportunity. Letting bit 64 participate in the mask
-- like any other bit sends them to unrelated addresses in all tables.
--
-- MASK CONSTRUCTION
--
-- Two properties, both deliberate:
--
--   1. The upper bits of each row come from a deterministic xorshift sequence,
--      giving roughly half ones spread across the key, different for every
--      (table, output bit) pair. Every key bit - including side - influences
--      the result, and the tables disagree about which keys collide.
--
--   2. The low C_ADDR_W bits of row b are one-hot at bit b. Restricted to
--      those columns the matrix is the identity, so the rows are linearly
--      independent by construction. A full-rank linear map is exactly
--      balanced: over uniform keys every address is equally likely.
--
-- Property 2 also means the low C_ADDR_W key bits pass through unmixed, XORed
-- with a function of the upper bits. For ASX order IDs, whose low word looks
-- like a dense counter, that is desirable - sequential IDs spread across all
-- addresses rather than clumping.
--
-- COST
--
-- C_NUM_TABLES * C_ADDR_W XOR trees, each reducing about (65 - C_ADDR_W)/2 + 1
-- terms - roughly 31 at C_ADDR_W = 4. A 31-input XOR is two LUT6 levels, so
-- four tables is 16 trees and about 110 LUTs. At C_ADDR_W = 12 it is 48 trees
-- and roughly 350 LUTs, still depth 2. Combinational, single cycle,
-- comfortable at 156.25 MHz.
--
-- Note the tree barely deepens with key width: term count halves the key, and
-- LUT6 reduction is log base 6. Going 16 -> 65 bits costs nothing in depth;
-- you would need past 216 bits to reach a fourth level.
--
-- IF ORDER IDS TURN OUT TO BE DENSE
--
-- Set C_HASH_T0_IDENTITY true. Table 0 then uses the low key bits directly -
-- no XOR tree, no logic, no delay. Under fixed-order insertion table 0 takes
-- every insert, so making it collision-free for sequential IDs is the single
-- highest-value change available. Tables 1..N-1 keep the full mixing, which is
-- what they need since they receive displaced keys rather than fresh ones.
--
-- Caveat: with side at bit 64 and the identity taking bits C_ADDR_W-1..0, the
-- side bit does not reach table 0's address at all. A buy and a sell order
-- with the same ID would then always collide in table 0 - not incorrect, since
-- the stored key still distinguishes them, but it doubles table 0's collision
-- rate. Worth measuring both ways.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ram_pkg.all;

package hash65_pkg is

  ------------------------------------------------------------------------------
  -- Key layout
  ------------------------------------------------------------------------------
  constant C_ORDER_ID_W  : positive := 64;
  constant C_SIDE_BIT    : natural  := C_ORDER_ID_W;   -- 64
  constant C_HASH65_KEY_W : positive := C_ORDER_ID_W + 1;  -- 65

  -- Build a key from its parts. side: 0 = buy, 1 = sell.
  function make_key (order_id : std_logic_vector(C_ORDER_ID_W-1 downto 0);
                     side     : std_logic) return t_key;

  function key_order_id (k : t_key) return std_logic_vector;
  function key_side     (k : t_key) return std_logic;

  ------------------------------------------------------------------------------
  -- Use the low key bits directly for table 0 instead of an XOR tree.
  --
  -- Only correct if the low C_ADDR_W bits of the order ID are well
  -- distributed - true for a dense counter, false for anything sparse.
  ------------------------------------------------------------------------------
  constant C_HASH_T0_IDENTITY : boolean := false;

  type t_mask_rows   is array (0 to C_ADDR_W-1) of t_key;
  type t_mask_tables is array (0 to C_NUM_TABLES-1) of t_mask_rows;

  ------------------------------------------------------------------------------
  -- Deferred constant: declared here, given its value in the package body.
  --
  -- It cannot be initialised here. A constant in a package DECLARATION is
  -- elaborated before the package body exists, so calling build_masks at this
  -- point would use a subprogram whose body has not been elaborated - illegal
  -- per LRM 14.4.2. Deferring moves the initialisation into the body, after
  -- build_masks is available.
  ------------------------------------------------------------------------------
  constant C_HASH_MASK : t_mask_tables;

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

end package hash65_pkg;


package body hash65_pkg is

  ------------------------------------------------------------------------------
  function make_key (order_id : std_logic_vector(C_ORDER_ID_W-1 downto 0);
                     side     : std_logic) return t_key is
  begin
    return side & order_id;
  end function;

  function key_order_id (k : t_key) return std_logic_vector is
  begin
    return k(C_ORDER_ID_W-1 downto 0);
  end function;

  function key_side (k : t_key) return std_logic is
  begin
    return k(C_SIDE_BIT);
  end function;

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
  -- Mask generation. Local to the body - nothing outside needs to call it.
  ------------------------------------------------------------------------------
  function build_masks return t_mask_tables is
    variable m : t_mask_tables;
    variable s : unsigned(63 downto 0) := x"9E3779B97F4A7C15";  -- golden ratio
    variable v : t_key;
  begin
    for t in 0 to C_NUM_TABLES-1 loop
      for b in 0 to C_ADDR_W-1 loop

        -- Upper bits: one xorshift draw per bit, so the row is independent of
        -- key width and of every other row. Bit 64 (side) is drawn like any
        -- other, which is what keeps buy and sell placements uncorrelated.
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
  -- Completion of the deferred constant. build_masks is elaborated by this
  -- point, so the call is legal here where it was not in the declaration.
  ------------------------------------------------------------------------------
  constant C_HASH_MASK : t_mask_tables := build_masks;

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

end package body hash65_pkg;
