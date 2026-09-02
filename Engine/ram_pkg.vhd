--------------------------------------------------------------------------------
-- ram_pkg
--
-- Single source of truth for the hash table's geometry and slot layout.
--
-- SWEEPING
--
-- The four constants in the CONFIGURATION block below are the only things to
-- change between experiments; everything else derives from them. Keeping them
-- as constants rather than generics means one edit reconfigures the whole
-- design, and both NVC and Vivado see identical values - which matters when
-- comparing a simulation result against a utilisation report.
--
-- For an automated sweep, regenerate this block from a script rather than
-- editing by hand:
--
--     sed -i "s/C_NUM_TABLES : positive := .*/C_NUM_TABLES : positive := $N;/" ram_pkg.vhd
--
-- The assertions at the end of the package catch configurations that would
-- take hours to elaborate or fail to synthesise, rather than letting them run.
--
-- SLOT LAYOUT
--
--    MSB                                      LSB
--   +-------+----------------------------------+
--   | valid |               key                |
--   +-------+----------------------------------+
--       1                 C_KEY_W
--
-- Key and value share one slot rather than living in separate RAMs. That keeps
-- eviction simple - a displaced entry moves as one write - at the cost of
-- moving C_VAL_W bits on every hop that only the key needed to move. Splitting
-- them later means the value RAM can be single-ported, since only the column
-- that hit is ever read.
--
-- The valid bit distinguishes an empty slot from one holding key 0, which is
-- otherwise a legitimate key. It also makes a delete cheap: clear one bit.
--
-- Block RAM contents after configuration are part-dependent, so nothing may
-- assume the memory starts cleared. Walk every address clearing valid bits
-- before serving traffic - C_DEPTH cycles, which at large depths is no longer
-- negligible and needs hiding behind an init state.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ram_pkg is

  ------------------------------------------------------------------------------
  -- CONFIGURATION - the sweep knobs
  ------------------------------------------------------------------------------

  -- Cuckoo columns. Each needs its own physical memory, since a BRAM has two
  -- ports and all columns must be read in the same cycle - so area is linear
  -- in this and cannot be shared.
  --
  -- Capacity returns saturate quickly. Maximum load factor by column count:
  --   2 -> 50%,  3 -> 91.8%,  4 -> 97.7%,  5 -> 99.2%,  6 -> 99.6%
  -- Past 4 the gain is fractions of a percent for a linear area cost.
  --
  -- Those figures assume a key may go in ANY of its slots. Under fixed-order
  -- insertion, where every insert enters at table 0 and victims move forward,
  -- contention at table 0 does not improve with more columns - only the number
  -- of downstream homes does. Expect measured behaviour to diverge from the
  -- published thresholds; that divergence is worth recording.
  constant C_NUM_TABLES : positive := 4;

  -- Slots per column. Address bits, so depth is 2**this.
  --
  -- BRAM granularity dominates below a tile boundary: a 33-bit slot occupies
  -- two BRAM18s whatever the depth, so shallow tables waste silicon and
  -- sweeping below ~512 measures nothing. Above one tile deep the tool
  -- cascades and adds an output mux - one level per doubling - which is where
  -- depth starts costing Fmax rather than just area.
  constant C_ADDR_W : positive := 4;

  -- Key width. 16 during bring-up where key and payload are the same field;
  -- 65 for the real table, being order_id(64) & side(1) - order IDs are unique
  -- only within an order book AND side.
  constant C_KEY_W : positive := 65;

  -- Value width, for the key-value form. Zero means no separate value RAM and
  -- the key doubles as the payload, which is the bring-up arrangement.
  --
  -- The real value is 66 bits: price(32) + qty(32) + undisc(1) + implied(1).
  constant C_VAL_W : natural := 66;

  ------------------------------------------------------------------------------
  -- Guard rails
  --
  -- C_ADDR_W of 32 would declare an array of 4 billion elements per table.
  -- NVC will attempt the allocation and die; Vivado will refuse to infer it.
  -- 20 bits (1M slots) is already beyond most parts once multiplied by
  -- C_NUM_TABLES and the slot width.
  ------------------------------------------------------------------------------
  constant C_ADDR_W_MAX : positive := 20;

  ------------------------------------------------------------------------------
  -- Derived
  ------------------------------------------------------------------------------
  constant C_DEPTH    : positive := 2 ** C_ADDR_W;
  constant C_CAPACITY : positive := C_DEPTH * C_NUM_TABLES;

  -- Bits needed to name one table. maximum() guards the single-table case,
  -- where log2 would give 0 and produce an illegal null vector.
  constant C_SEL_W : positive :=
  maximum(1, natural(ceil(log2(real(C_NUM_TABLES)))));

  constant C_SLOT_W : positive := 1 + C_KEY_W + C_VAL_W;

  --    MSB                                                    LSB
  --   +-------+---------------------------+--------------------+
  --   | valid |            key            |       value        |
  --   +-------+---------------------------+--------------------+
  --       1            C_KEY_W                  C_VAL_W
  constant C_VALID_BIT : natural := C_SLOT_W - 1;
  constant C_KEY_HI    : natural := C_VALID_BIT - 1;
  constant C_KEY_LO    : natural := C_VAL_W;
  constant C_VAL_HI    : natural := C_VAL_W - 1;
  constant C_VAL_LO    : natural := 0;

  constant C_HAS_VALUE : boolean := C_VAL_W > 0;

  -- Total memory bits, for comparing configurations at a glance.
  constant C_TOTAL_BITS : natural := C_CAPACITY * C_SLOT_W;
  ------------------------------------------------------------------------------
  -- Read latency of the memory, in cycles.
  --
  -- 1 with a registered output only. Setting G_OUT_REG on ram_sdp makes it 2,
  -- which is the usual way to close timing on deep cascaded BRAM - but every
  -- index offset in the engine's FSM assumes this value, so changing it is a
  -- design change, not a knob.
  ------------------------------------------------------------------------------
  constant C_RAM_OUT_REG  : boolean  := false;
  constant C_READ_LATENCY : positive := 1 + boolean'pos(C_RAM_OUT_REG);

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  subtype t_addr is std_logic_vector(C_ADDR_W - 1 downto 0);
  subtype t_key is std_logic_vector(C_KEY_W - 1 downto 0);
  subtype t_key_u is unsigned(C_KEY_W - 1 downto 0);
  subtype t_vkey is std_logic_vector(C_KEY_W downto 0); --valid key
  subtype t_slot is std_logic_vector(C_SLOT_W - 1 downto 0);
  subtype t_sel is std_logic_vector(C_SEL_W - 1 downto 0);
  -- Value type is declared at width 1 when unused, so the subtype is always
  -- legal; nothing should reference it unless C_HAS_VALUE.
  subtype t_val is std_logic_vector(C_VAL_W - 1 downto 0);
  subtype t_val_u is unsigned(C_VAL_W - 1 downto 0);

  ------------------------------------------------------------------------------
  -- Range subtypes (C_VAL_W-1 downto 0);
  ------------------------------------------------------------------------------
  subtype KEY_RANGE is integer range C_SLOT_W - 2 downto C_VAL_W; --key slice
  subtype VKEY_RANGE is integer range C_SLOT_W - 1 downto C_VAL_W; -- valid bit + key slice
  subtype VAL_RANGE is integer range C_VAL_W - 1 downto 0; --value slice
  subtype KEYVAL_RANGE is integer range C_SLOT_W - 2 downto 0; -- key + value slice
  subtype ALL_RANGE is integer range C_SLOT_W - 1 downto 0; --valid bit + key + value 
  subtype QTY_RANGE is integer range C_VAL_W - 1 downto C_VAL_W - 32; --qty
  subtype NOTQTY_RANGE is integer range C_VAL_W - 33 downto 0; --not qty
  subtype PRICE_RANGE is integer range C_VAL_W - 33 downto 2; --qty
  constant SIDE_BIT : natural := C_VAL_W - 1;
  -- One element per table. Reads are parallel, so addresses and results both
  -- come as full sets; a counter can index either.
  type t_addr_set is array (0 to C_NUM_TABLES - 1) of t_addr;
  type t_slot_set is array (0 to C_NUM_TABLES - 1) of t_slot;
  type t_val_set is array (0 to C_NUM_TABLES - 1) of t_val;

  ------------------------------------------------------------------------------
  -- Book operations
  ------------------------------------------------------------------------------
  type t_book_op is (OP_ADD, OP_EXEC, OP_REPLACE, OP_DELETE);

  -- One bit per table, for hit / occupancy flags.
  subtype t_table_flags is std_logic_vector(0 to C_NUM_TABLES - 1);

  constant C_SLOT_EMPTY : t_slot := (others => '0');

  ------------------------------------------------------------------------------
  -- Slot accessors
  --
  -- Used instead of open-coded bit ranges so the layout can change in one
  -- place. Purely combinational rewiring - no logic cost.
  ------------------------------------------------------------------------------
  -- Build a slot from a key and a value.
  --
  -- There is deliberately no overload taking a t_vkey: t_key and t_vkey are
  -- both subtypes of std_logic_vector, and VHDL resolves overloads on BASE
  -- types, so the two declarations would be homographs and illegal. On an
  -- eviction hop the insert path already holds a t_vkey, which carries its own
  -- valid bit, so concatenate directly:  wdata <= key_r & value_r;
  function make_slot (key : t_key; val : t_val) return t_slot;

  function make_vkey (key : t_key) return t_vkey; -- valid = '1'
  function vkey_key (v    : t_vkey) return t_key;
  function vkey_valid (v  : t_vkey) return std_logic;

  function slot_valid (s : t_slot) return std_logic;
  function slot_key (s   : t_slot) return t_key;
  function slot_val (s   : t_slot) return t_val;
  function slot_vkey (s  : t_slot) return t_vkey;
  function modify_func(
    op     : t_book_op;
    lookup : t_key;
    prev   : t_val_u;
    modify : t_val
  ) return t_slot;
  -- MODIFY ORDER -> placed in order of priority for logic levels
  -- EXEC: subtracts the executed qty from the current order only
  -- REPLACE: replaces the whole order
  -- DELETE: simply clears everything

  -- True when the slot is occupied AND holds this key. The valid term matters:
  -- without it, uninitialised memory that happens to match reads as a hit.
  function slot_hit (s : t_slot; key : t_key) return std_logic;

  -- Human-readable geometry, for a report line at the top of a simulation.
  function geometry_string return string;

end package ram_pkg;
package body ram_pkg is

  function make_slot (key : t_key; val : t_val) return t_slot is
  begin
    return '1' & key & val;
  end function;

  function make_vkey (key : t_key) return t_vkey is
  begin
    return '1' & key;
  end function;

  function vkey_key (v : t_vkey) return t_key is
  begin
    return v(C_KEY_W - 1 downto 0);
  end function;

  function vkey_valid (v : t_vkey) return std_logic is
  begin
    return v(C_KEY_W);
  end function;

  function slot_valid (s : t_slot) return std_logic is
  begin
    return s(C_VALID_BIT);
  end function;

  function slot_key (s : t_slot) return t_key is
  begin
    return s(C_KEY_HI downto C_KEY_LO);
  end function;

  function slot_val (s : t_slot) return t_val is
  begin
    return s(C_VAL_HI downto C_VAL_LO);
  end function;

  -- Valid bit and key together, dropping the value. This is what an eviction
  -- hop carries forward.
  function slot_vkey (s : t_slot) return t_vkey is
  begin
    return s(C_VALID_BIT) & s(C_KEY_HI downto C_KEY_LO);
  end function;

  function slot_hit (s : t_slot; key : t_key) return std_logic is
  begin
    if s(C_VALID_BIT) = '1' and s(C_KEY_HI downto C_KEY_LO) = key then
      return '1';
    end if;
    return '0';
  end function;

  function geometry_string return string is
  begin
    return integer'image(C_NUM_TABLES) & " tables x " &
    integer'image(C_DEPTH) & " slots = " &
    integer'image(C_CAPACITY) & " capacity, key " &
    integer'image(C_KEY_W) & "b, slot " &
    integer'image(C_SLOT_W) & "b, value " &
    integer'image(C_VAL_W) & "b, total " &
    integer'image(C_TOTAL_BITS) & " bits";
  end function;

  function modify_func(
    op     : t_book_op;
    lookup : t_key;
    prev   : t_val_u;
    modify : t_val
  ) return t_slot is
  begin
    if op = OP_EXEC and unsigned(modify(QTY_RANGE)) < prev(QTY_RANGE) then
      return '1' &
      lookup &
      std_logic_vector(
      unsigned(prev(QTY_RANGE)) - unsigned(modify(QTY_RANGE))
      ) &
      modify(NOTQTY_RANGE);

    elsif op = OP_REPLACE then
      return '1' & lookup & modify;

    else
      return (others => '0');
    end if;
  end function;
  -- MODIFY ORDER -> placed in order of priority for logic levels
  -- EXEC: subtracts the executed qty from the current order only, clears if qty matches
  -- REPLACE: replaces the whole order
  -- DELETE: simply clears everything

end package body ram_pkg;
