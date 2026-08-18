--------------------------------------------------------------------------------
-- ram_pkg
--
-- Single source of truth for the hash table's geometry and slot layout.
--
-- Everything is a constant rather than a generic, so the engine, the RAM array
-- and the hash functions all agree by construction - change a value here and
-- every module that uses the package follows. The cost is that you cannot have
-- two differently-sized tables in one design; that is the intended trade for a
-- single-instrument engine.
--
-- SLOT LAYOUT
--
--    MSB                                                          LSB
--   +-------+---------------------------+--------------------------+
--   | valid |            key            |          value           |
--   +-------+---------------------------+--------------------------+
--       1            C_KEY_W                     C_VAL_W
--
-- The valid bit is what distinguishes an empty slot from one holding key 0,
-- which is otherwise a legitimate key. It is also what makes a delete cheap:
-- clear one bit rather than rewrite the slot.
--
-- Block RAM contents after configuration are part-dependent, so nothing may
-- assume the memory starts cleared. Walk every address clearing valid bits
-- before serving traffic.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ram_pkg is

  ------------------------------------------------------------------------------
  -- Geometry
  ------------------------------------------------------------------------------
  constant C_NUM_TABLES : positive := 4;    -- cuckoo columns
  constant C_ADDR_W     : positive := 3;    -- 3 bits -> 8 locations per table
  constant C_KEY_W      : positive := 16;
  constant C_VAL_W      : positive := 8;

  constant C_DEPTH      : positive := 2**C_ADDR_W;              -- 8
  constant C_CAPACITY   : positive := C_DEPTH * C_NUM_TABLES;   -- 32 slots total

  -- Bits needed to name one table. maximum() guards the single-table case,
  -- where log2 would give 0 and produce an illegal null vector.
  constant C_SEL_W : positive :=
    maximum(1, natural(ceil(log2(real(C_NUM_TABLES)))));        -- 2

  ------------------------------------------------------------------------------
  -- Slot layout
  ------------------------------------------------------------------------------
  constant C_SLOT_W : positive := 1 + C_KEY_W;        -- 25

  constant C_VALID_BIT : natural := C_SLOT_W - 1;               
  constant C_KEY_HI    : natural := C_VALID_BIT - 1;            
  constant C_KEY_LO    : natural := 0;   

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  subtype t_addr is std_logic_vector(C_ADDR_W-1 downto 0);
  subtype t_key  is std_logic_vector(C_KEY_W-1 downto 0);
  subtype t_val  is std_logic_vector(C_VAL_W-1 downto 0);
  subtype t_slot is std_logic_vector(C_SLOT_W-1 downto 0);
  subtype t_sel  is std_logic_vector(C_SEL_W-1 downto 0);

  -- One element per table. Reads are parallel, so addresses and results both
  -- come as full sets; a counter can index either.
  type t_addr_set is array (0 to C_NUM_TABLES-1) of t_addr;
  type t_slot_set is array (0 to C_NUM_TABLES-1) of t_slot;

  -- One bit per table, for hit / occupancy flags.
  subtype t_table_flags is std_logic_vector(0 to C_NUM_TABLES-1);

  constant C_SLOT_EMPTY : t_slot := (others => '0');

  ------------------------------------------------------------------------------
  -- Slot accessors
  --
  -- Used instead of open-coded bit ranges so the layout can change in one
  -- place. Purely combinational rewiring - no logic cost.
  ------------------------------------------------------------------------------
  function make_slot  (key : t_key) return t_slot;
  function slot_valid (s : t_slot) return std_logic;
  function slot_key   (s : t_slot) return t_key;

  -- True when the slot is occupied AND holds this key. The valid term matters:
  -- without it, uninitialised memory that happens to match reads as a hit.
  function slot_hit (s : t_slot; key : t_key) return std_logic;

end package ram_pkg;


package body ram_pkg is

  function make_slot (key : t_key) return t_slot is
  begin
    return '1' & key;
  end function;

  function slot_valid (s : t_slot) return std_logic is
  begin
    return s(C_VALID_BIT);
  end function;

  function slot_key (s : t_slot) return t_key is
  begin
    return s(C_KEY_HI downto C_KEY_LO);
  end function;


  function slot_hit (s : t_slot; key : t_key) return std_logic is
  begin
    if s(C_VALID_BIT) = '1' and s(C_KEY_HI downto C_KEY_LO) = key then
      return '1';
    end if;
    return '0';
  end function;

end package body ram_pkg;
