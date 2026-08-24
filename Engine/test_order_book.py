"""
cocotb testbench for order_book - realistic traffic walkthrough.

Drives ASX-shaped order IDs through the AXI-Stream slave interface, fills the
tables to roughly 50%, then runs three lookups, three deletions and three
modifications. Table contents are printed after every operation.

Slots hold valid + key + value. Modify rewrites the VALUE at the same address
and leaves the key alone - the hash is over the key, so the slot cannot move.
lookup_return currently exposes the key only; the value is not brought out.

No assertions. This is a visibility harness - it reports what happened and
flags anything that looks wrong, rather than failing the run.

TOPLEVEL IS order_book_top

order_book exposes its memory ports rather than owning the memory, so it
cannot run standalone. order_book_top wires it to a real ram_array. The table
contents below are read straight out of that RAM through the design hierarchy,
so read latency and read-during-write are whatever the RTL actually does.

KEY LAYOUT

The RTL builds its key as  s_order_id & s_side,  so side is bit 0 and the
order ID occupies bits 64..1. Note this is NOT the layout in hash65_pkg's
make_key, which puts side at bit 64. The testbench follows the RTL.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly

CLK_PERIOD_NS = 6.4          # 156.25 MHz

# ---------------------------------------------------------------------------
# Geometry - must match ram_pkg
# ---------------------------------------------------------------------------
NUM_TABLES = 4
ADDR_W = 4
DEPTH = 2 ** ADDR_W          # 16 slots per table
ORDER_ID_W = 64
KEY_W = ORDER_ID_W + 1       # 65, order_id & side
VAL_W = 66                   # qty(32) & price(32) & undisc(1) & implied(1)
SLOT_W = 1 + KEY_W + VAL_W   # 132
VALID_BIT = SLOT_W - 1       # 131
KEY_MASK = (1 << KEY_W) - 1
VAL_MASK = (1 << VAL_W) - 1


def slot_key(slot):
    """Key field of a slot: bits SLOT_W-2 .. VAL_W."""
    return None if slot is None else (slot >> VAL_W) & KEY_MASK


def slot_val(slot):
    """Value field of a slot: bits VAL_W-1 .. 0."""
    return None if slot is None else slot & VAL_MASK


def u32(v: int) -> int:
    """
    Two's complement 32-bit.

    s_qty and s_price are std_logic_vector, not unsigned/signed, so cocotb
    will not accept a negative int - it has no sign to work from. Prices are
    genuinely signed on the wire (combination books quote negative values), so
    anything negative has to be converted here before it is driven.
    """
    return v & 0xFFFFFFFF


def make_value(qty: int, price: int, undisc: int = 0, implied: int = 0) -> int:
    """
    Matches the RTL:  value <= s_qty & s_price & s_undisc & s_implied.

    Field positions within the 66-bit value:
        qty      bits 65..34
        price    bits 33..2
        undisc   bit  1
        implied  bit  0
    """
    return ((u32(qty) << 34)
            | (u32(price) << 2)
            | ((undisc & 1) << 1)
            | (implied & 1))


def to_signed32(v: int) -> int:
    """Interpret a 32-bit field as signed - prices can be negative."""
    return v - (1 << 32) if v & 0x80000000 else v


def split_value(v: int):
    if v is None:
        return None
    return {
        "qty": (v >> 34) & 0xFFFFFFFF,
        "price": to_signed32((v >> 2) & 0xFFFFFFFF),
        "undisc": (v >> 1) & 1,
        "implied": v & 1,
    }


def fmt_value(v):
    """Decomposed value plus the raw VAL_W-bit hex."""
    d = split_value(v)
    if d is None:
        return f"---- =0x{'?' * VAL_HEX}"
    return (f"qty={d['qty']} px={d['price']} u={d['undisc']} i={d['implied']}"
            f" =0x{v:0{VAL_HEX}X}")


def fmt_slot(slot):
    """Raw slot hex - valid, key and value as one word, as stored in RAM."""
    if slot is None:
        return "0x" + "?" * SLOT_HEX
    return f"0x{slot:0{SLOT_HEX}X}"

CAPACITY = NUM_TABLES * DEPTH        # 64 slots

# key_op encoding
OP_INSERT = 0b00
OP_LOOKUP = 0b01
OP_DELETE = 0b10
OP_MODIFY = 0b11

# ---------------------------------------------------------------------------
# Stimulus
#
# ASX order IDs look like 621f1282:0000e5ed - what appears to be a session or
# day prefix in the high word and a counter in the low word. These follow that
# shape, which also exercises the case that matters most for the hash: if the
# low bits really are a dense counter, table 0 collisions are driven almost
# entirely by them.
#
# Fill to 50% of capacity. Above that, fixed-order insertion starts producing
# long chains at table 0 regardless of hash quality, which muddies what the
# lookup and delete paths are being shown to do.
# ---------------------------------------------------------------------------
SESSION_PREFIX = 0x621F1282
FIRST_SEQ = 0x0000E5ED

N_INSERT = CAPACITY // 2             # 32 keys

# Which of the inserted keys to operate on afterwards, by index.
LOOKUP_IDX = [3, 11, 27]
DELETE_IDX = [5, 17, 30]
MODIFY_IDX = [1, 14, 22]

MAX_CYCLES = 80


def make_order_id(n: int) -> int:
    """ASX-shaped: fixed session prefix, incrementing sequence."""
    return (SESSION_PREFIX << 32) | ((FIRST_SEQ + n) & 0xFFFFFFFF)


def make_key(order_id: int, side: int) -> int:
    """Matches the RTL:  key <= s_order_id & s_side.  Side is bit 0."""
    return ((order_id & ((1 << ORDER_ID_W) - 1)) << 1) | (side & 1)


def split_key(key: int):
    return (key >> 1) & ((1 << ORDER_ID_W) - 1), key & 1


# The traffic: alternating sides, sequential IDs, and a distinct quantity and
# price per order so a value written to the wrong slot is obvious.
INSERTS = [
    (make_order_id(i), i % 2, 100 * (i + 1), 2600 + i)
    for i in range(N_INSERT)
]


# ---------------------------------------------------------------------------
# Hash mirror
#
# Mirrors build_masks in hash65_pkg exactly: one xorshift64 draw per key bit,
# most significant first, then the low ADDR_W bits overwritten one-hot.
#
# Used only to annotate the printout with candidate slots. Every check in this
# file is made against what is actually in the RAM, so a drift here misleads
# the log but cannot produce a false pass.
# ---------------------------------------------------------------------------
M64 = (1 << 64) - 1


def xorshift64(x: int) -> int:
    x ^= (x << 13) & M64
    x ^= x >> 7
    x ^= (x << 17) & M64
    return x & M64


def build_masks():
    masks = [[0] * ADDR_W for _ in range(NUM_TABLES)]
    s = 0x9E3779B97F4A7C15
    for t in range(NUM_TABLES):
        for b in range(ADDR_W):
            v = 0
            for i in range(KEY_W - 1, -1, -1):
                s = xorshift64(s)
                v |= (s & 1) << i
            v &= ~((1 << ADDR_W) - 1)      # clear low ADDR_W bits
            v |= (1 << b)                   # one-hot at b
            masks[t][b] = v
    return masks


HASH_MASK = build_masks()


def parity(v: int) -> int:
    p = 0
    while v:
        p ^= v & 1
        v >>= 1
    return p


def hash_tbl(key: int, tbl: int) -> int:
    a = 0
    for b in range(ADDR_W):
        a |= parity(key & HASH_MASK[tbl][b]) << b
    return a


def hash_all(key: int):
    return [hash_tbl(key, t) for t in range(NUM_TABLES)]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def safe_int(handle):
    try:
        return int(handle.value)
    except (ValueError, TypeError):
        return None


def fmt(v):
    return "?" if v is None else str(v)


def fmt_key(key):
    """
    Render a key as  <hi>:<lo><B|S> =0x<raw>.

    The decomposed form is what you reason about; the raw hex is what appears
    on the bus and in the RAM, so both are printed. The raw value is the full
    KEY_W bits including the side bit at position 0.
    """
    if key is None:
        return f"{'....':>17} =0x{'?' * KEY_HEX}"
    oid, side = split_key(key)
    return (f"{oid >> 32:08X}:{oid & 0xFFFFFFFF:08X}{'B' if side == 0 else 'S'}"
            f" =0x{key:0{KEY_HEX}X}")


CELL_W = 5          # "E5EDB" - low 16 bits of the order ID plus B/S

# Hex digits needed for each field, so the raw values can be compared straight
# against a waveform or a RAM dump.
KEY_HEX = (KEY_W + 3) // 4       # 65 bits -> 17
VAL_HEX = (VAL_W + 3) // 4       # 66 bits -> 17
SLOT_HEX = (SLOT_W + 3) // 4     # 132 bits -> 33


def fmt_key_short(key):
    """Low half of the order ID plus side, in exactly CELL_W characters."""
    if key is None:
        return "?" * CELL_W
    oid, side = split_key(key)
    return f"{oid & 0xFFFF:04X}{'B' if side == 0 else 'S'}"


def fmt_cell(slot):
    """One table cell, always CELL_W wide so columns line up."""
    if slot is None:
        return "?" * CELL_W
    if (slot >> VALID_BIT) & 1:
        return fmt_key_short(slot_key(slot))
    return "." * CELL_W


# ---------------------------------------------------------------------------
# Reaching the RAM contents through the hierarchy
# ---------------------------------------------------------------------------
def find_ram_handles(dut):
    arr = dut.u_ram_arr
    attempts = []
    handles = []

    for t in range(NUM_TABLES):
        h = None
        try:
            h = arr.g_tables[t].u_ram.ram
        except Exception as e:            # noqa: BLE001
            attempts.append(f"u_ram_arr.g_tables[{t}].u_ram.ram -> {e}")

        if h is None:
            for name in (f"g_tables({t})", f"g_tables[{t}]", f"g_tables_{t}"):
                try:
                    h = getattr(arr, name).u_ram.ram
                    break
                except Exception as e:    # noqa: BLE001
                    attempts.append(f"u_ram_arr.{name}.u_ram.ram -> {e}")

        if h is None:
            raise AssertionError(
                "Could not reach the RAM contents through the hierarchy.\n"
                "Tried:\n  " + "\n  ".join(attempts) +
                "\n\nRun with NVC's --preserve-case (the runner already does) "
                "and check the instance names in order_book_top.vhd and "
                "ram_array.vhd match those above."
            )
        handles.append(h)

    return handles


def read_tables(rams):
    """Snapshot all tables as ints. Call from ReadOnly."""
    return [[safe_int(rams[t][a]) for a in range(DEPTH)]
            for t in range(NUM_TABLES)]


def dump(log, tables, label=""):
    """
    Print every table as one block.

    Emitted as a single log call with embedded newlines rather than one call
    per table: cocotb prefixes each record with a timestamp, level and logger
    name, which is about 50 columns. Paying that once instead of NUM_TABLES
    times is what keeps the rows from wrapping.
    """
    lines = []
    if label:
        lines.append(label)

    # Column header - slot index, right-aligned over each cell.
    lines.append("       " + " ".join(f"{a:>{CELL_W}d}" for a in range(DEPTH)))

    for t in range(NUM_TABLES):
        cells = " ".join(fmt_cell(tables[t][a]) for a in range(DEPTH))
        lines.append(f"    T{t} " + cells)

    log.info("%s", "\n".join(lines))


def occupancy(tables):
    return sum(1
               for t in range(NUM_TABLES)
               for s in tables[t]
               if s is not None and (s >> VALID_BIT) & 1)


def find_key(tables, key):
    for t in range(NUM_TABLES):
        for a in range(DEPTH):
            s = tables[t][a]
            if s is not None and (s >> VALID_BIT) & 1 and slot_key(s) == key:
                return (t, a)
    return None


# ---------------------------------------------------------------------------
# Bus tracing
# ---------------------------------------------------------------------------
def trace(dut, cycle):
    """
    Print the bus state for the current cycle, and return the write observed.

    Call from ReadOnly after a FallingEdge, so the values shown are the ones in
    effect during this cycle - what the RAM will act on at the next rising
    edge. Sampling after RisingEdge would show the registers already updated
    for the following cycle.
    """
    we = safe_int(dut.we)
    wsel = safe_int(dut.wsel)
    waddr = safe_int(dut.waddr)
    wdata = safe_int(dut.wdata)
    busy = safe_int(dut.busy)
    tvalid = safe_int(dut.s_tvalid)
    tready = safe_int(dut.s_tready)
    kop = safe_int(dut.key_op)
    lfound = safe_int(dut.lookup_found)
    lret = safe_int(dut.lookup_return)

    raddr = [safe_int(dut.raddr[t]) for t in range(NUM_TABLES)]

    wr = "-"
    observed = None
    if we == 1 and wdata is not None and wsel is not None and waddr is not None:
        vbit = (wdata >> VALID_BIT) & 1
        # Key hex rather than the full slot word: the slot is 33 hex digits
        # and pushes this line past any sensible terminal width. The complete
        # slot is printed in the per-operation summaries instead.
        wr = (f"T{wsel}[{waddr:2d}]<={'V' if vbit else 'x'} "
              f"0x{slot_key(wdata):0{KEY_HEX}X}")
        observed = (wsel, waddr, slot_key(wdata), vbit)

    dut._log.info(
        "cyc %2d | tv=%s tr=%s op=%s busy=%s | raddr=%s | write %s "
        "| found=%s ret=%s",
        cycle, fmt(tvalid), fmt(tready), fmt(kop), fmt(busy),
        raddr, wr, fmt(lfound),
        "...." if lret is None else f"0x{lret & KEY_MASK:0{KEY_HEX}X}",
    )
    return observed


# ---------------------------------------------------------------------------
# Stimulus drivers
# ---------------------------------------------------------------------------
async def issue(dut, order_id, side, op, qty=0, price=0, undisc=0, implied=0,
                settle=5, quiet=False):
    """
    Offer one command and wait for it to be consumed.

    Holds s_tvalid until a rising edge where s_tready is also high, then drops
    it. Every input is held through the cycles that follow: the RTL samples
    key_op while looking_r is high, and the read addresses are combinational
    off the key.

    Returns (writes, found) where found is one (cycle, lookup_found,
    lookup_return) tuple per cycle observed.

    Sampling every cycle matters: lookup_found is asserted for exactly ONE
    cycle. The RTL clears it in the else branch of the lookup process, and on
    a plain lookup op_r is "01", so neither the looking_r branch nor the
    delete/modify branch matches on the cycle after the compare - it falls
    straight through to the clear. Sampling once after the operation has
    settled therefore always reads zero.

    The value is carried on s_qty / s_price / s_undisc / s_implied, which the
    RTL concatenates into its value field. On MODIFY those carry the NEW value
    - there is no separate key_modify path any more.

    s_qty and s_price are std_logic_vector rather than unsigned/signed, so
    values are converted to their 32-bit two's complement representation
    before being driven.
    """
    dut.s_order_id.value = order_id
    dut.s_side.value = side
    dut.s_qty.value = u32(qty)
    dut.s_price.value = u32(price)
    dut.s_undisc.value = undisc
    dut.s_implied.value = implied
    dut.key_op.value = op
    dut.s_tvalid.value = 1

    cycle = 0
    writes = []
    found = []          # (cycle, lookup_found, lookup_return) every cycle

    def sample(c):
        if not quiet:
            w = trace(dut, c)
            if w is not None:
                writes.append(w)
        found.append((c,
                      safe_int(dut.lookup_found),
                      safe_int(dut.lookup_return)))

    while cycle < MAX_CYCLES:
        await FallingEdge(dut.clk)
        await ReadOnly()
        accepted = safe_int(dut.s_tready) == 1
        sample(cycle)
        await RisingEdge(dut.clk)
        cycle += 1
        if accepted:
            break

    dut.s_tvalid.value = 0

    # Follow the operation until the engine is idle again, or for a fixed
    # window if it never asserted busy (lookup, delete, modify).
    while cycle < MAX_CYCLES:
        await FallingEdge(dut.clk)
        await ReadOnly()
        sample(cycle)
        busy = safe_int(dut.busy)
        await RisingEdge(dut.clk)
        cycle += 1
        if busy == 0 and cycle >= settle:
            break

    dut.key_op.value = OP_INSERT
    await RisingEdge(dut.clk)
    return writes, found


async def snapshot(dut, rams):
    await FallingEdge(dut.clk)
    await ReadOnly()
    t = read_tables(rams)
    await RisingEdge(dut.clk)
    return t


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_normal_traffic(dut):
    """
    Fill to 50%, then three lookups, three deletions, three modifications.
    """
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    # ---- reset -----------------------------------------------------------
    dut.resetn.value = 0
    dut.s_tvalid.value = 0
    dut.key_op.value = OP_INSERT

    dut.s_op.value = 0
    dut.s_order_id.value = 0
    dut.s_book_id.value = 0
    dut.s_side.value = 0
    dut.s_qty.value = 0
    dut.s_price.value = 0
    dut.s_px_valid.value = 0
    dut.s_undisc.value = 0
    dut.s_implied.value = 0

    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.resetn.value = 1
    await RisingEdge(dut.clk)

    rams = find_ram_handles(dut)

    dut._log.info("=" * 88)
    dut._log.info("geometry : %d tables x %d slots = %d capacity",
                  NUM_TABLES, DEPTH, CAPACITY)
    dut._log.info("key      : %d bits, order_id(64) & side(1), side at bit 0",
                  KEY_W)
    dut._log.info("slot     : %d bits = valid(1) key(%d) value(%d)",
                  SLOT_W, KEY_W, VAL_W)
    dut._log.info("value    : qty(32) price(32) undisc(1) implied(1), "
                  "driven as std_logic_vector")
    dut._log.info("traffic  : %d inserts (%.0f%% load), then 3 lookups, "
                  "3 deletes, 3 modifies",
                  N_INSERT, 100.0 * N_INSERT / CAPACITY)
    dut._log.info("cells shown as  <low16 of order id><B|S>")
    dut._log.info("=" * 88)

    problems = []

    # ---- fill ------------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("INSERTS")
    dut._log.info("=" * 88)

    for i, (oid, side, qty, price) in enumerate(INSERTS):
        key = make_key(oid, side)
        val = make_value(qty, price)
        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("INSERT %2d/%d  %s  [%s]   candidates: %s",
                      i + 1, N_INSERT, fmt_key(key), fmt_value(val),
                      ", ".join(f"T{t}[{a}]"
                                for t, a in enumerate(hash_all(key))))
        dut._log.info("-" * 88)

        writes, _ = await issue(dut, oid, side, OP_INSERT,
                                qty=qty, price=price)

        tables = await snapshot(dut, rams)
        if writes:
            path = " -> ".join(f"T{t}[{a}]" for t, a, _, _ in writes)
            dut._log.info("    path  : %s   (%d hop%s)",
                          path, len(writes), "" if len(writes) == 1 else "s")
        else:
            dut._log.info("    path  : no write observed")
            problems.append(f"insert {fmt_key(key)}: no write")

        where = find_key(tables, key)
        if where:
            raw = tables[where[0]][where[1]]
            stored = slot_val(raw)
            dut._log.info("    rests : T%d[%d]  slot %s   occupancy %d/%d",
                          where[0], where[1], fmt_slot(raw),
                          occupancy(tables), CAPACITY)
            dut._log.info("            value [%s]", fmt_value(stored))
            if stored != val:
                problems.append(f"insert {fmt_key(key)}: stored value "
                                f"[{fmt_value(stored)}], expected "
                                f"[{fmt_value(val)}]")
        else:
            dut._log.info("    rests : NOT FOUND   occupancy %d/%d",
                          occupancy(tables), CAPACITY)
            problems.append(f"insert {fmt_key(key)}: not in any table")

    tables = await snapshot(dut, rams)
    dut._log.info("")
    dump(dut._log, tables,
         f"AFTER FILL  (occupancy {occupancy(tables)}/{CAPACITY}, "
         f"expected {N_INSERT})")

    if occupancy(tables) != N_INSERT:
        problems.append(f"fill: occupancy {occupancy(tables)}, "
                        f"expected {N_INSERT}")

    # ---- lookups ---------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("LOOKUPS")
    dut._log.info("=" * 88)

    for idx in LOOKUP_IDX:
        oid, side, qty, price = INSERTS[idx]
        key = make_key(oid, side)
        before = await snapshot(dut, rams)
        at = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("LOOKUP %s   (inserted as #%d, currently at %s)",
                      fmt_key(key), idx,
                      f"T{at[0]}[{at[1]}]" if at else "NOWHERE")
        dut._log.info("-" * 88)

        _, samples = await issue(dut, oid, side, OP_LOOKUP)

        # lookup_found is high for one cycle only, so scan the window rather
        # than sampling at a fixed offset. lookup_return carries the KEY only
        # at this stage - the value is not brought out yet.
        hit_at = None
        for c, f, r in samples:
            if f == 1 and r is not None and (r & KEY_MASK) == key:
                hit_at = (c, r & KEY_MASK)
                break

        if hit_at:
            dut._log.info("    HIT   at cycle %d  found=1  return=%s",
                          hit_at[0], fmt_key(hit_at[1]))
        else:
            dut._log.info("    MISS  found never asserted with the right key")
            dut._log.info("    window: %s",
                          ", ".join(
                              f"c{c}:f={fmt(f)}"
                              f"/0x{(r & KEY_MASK):0{KEY_HEX}X}"
                              if r is not None else f"c{c}:f={fmt(f)}/----"
                              for c, f, r in samples))
            problems.append(f"lookup {fmt_key(key)}: no hit in window")

    # ---- deletions -------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("DELETIONS")
    dut._log.info("=" * 88)

    for idx in DELETE_IDX:
        oid, side, qty, price = INSERTS[idx]
        key = make_key(oid, side)
        before = await snapshot(dut, rams)
        at = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("DELETE %s   (inserted as #%d, currently at %s)",
                      fmt_key(key), idx,
                      f"T{at[0]}[{at[1]}]" if at else "NOWHERE")
        dut._log.info("-" * 88)

        await issue(dut, oid, side, OP_DELETE, qty=qty, price=price)
        after = await snapshot(dut, rams)

        dump(dut._log, after,
             f"    after delete  (occupancy {occupancy(after)}/{CAPACITY})")

        if find_key(after, key) is None:
            dut._log.info("    DELETED")
        else:
            w = find_key(after, key)
            dut._log.info("    NOT DELETED - still at T%d[%d]", w[0], w[1])
            problems.append(f"delete {fmt_key(key)}: still present")

        changed = [(t, a) for t in range(NUM_TABLES) for a in range(DEPTH)
                   if before[t][a] != after[t][a]]
        if at is not None and changed != [at]:
            dut._log.warning("    unexpected slot changes: %s",
                             ", ".join(f"T{t}[{a}]" for t, a in changed))
            problems.append(f"delete {fmt_key(key)}: collateral damage")

    # ---- modifications ---------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("MODIFICATIONS")
    dut._log.info("=" * 88)
    dut._log.info("The key is unchanged - only the value is rewritten, at the "
                  "same address. This is")
    dut._log.info("what an EXEC or a REPLACE does: the hash is over the key, "
                  "so the slot cannot move.")

    for n, idx in enumerate(MODIFY_IDX):
        oid, side, qty, price = INSERTS[idx]
        key = make_key(oid, side)
        old_val = make_value(qty, price)

        # New value: quantity reduced, price moved, flags set - so every field
        # differs from what was stored.
        new_qty = qty // 2
        new_price = price + 500
        new_val = make_value(new_qty, new_price, undisc=1, implied=0)

        before = await snapshot(dut, rams)
        at = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("MODIFY %s   (inserted as #%d, currently at %s)",
                      fmt_key(key), idx,
                      f"T{at[0]}[{at[1]}]" if at else "NOWHERE")
        dut._log.info("    value [%s] -> [%s]",
                      fmt_value(old_val), fmt_value(new_val))
        dut._log.info("-" * 88)

        await issue(dut, oid, side, OP_MODIFY,
                    qty=new_qty, price=new_price, undisc=1, implied=0)
        after = await snapshot(dut, rams)

        dump(dut._log, after,
             f"    after modify  (occupancy {occupancy(after)}/{CAPACITY})")

        if at is None:
            problems.append(f"modify {fmt_key(key)}: was not present")
            continue

        t, a = at
        slot = after[t][a]
        valid = slot is not None and (slot >> VALID_BIT) & 1 == 1
        got_key = slot_key(slot)
        got_val = slot_val(slot)

        # Three separate things must hold: the slot is still valid, the key is
        # untouched, and the value is the new one.
        if not valid:
            dut._log.info("    FAILED  T%d[%d] valid bit cleared - that is a "
                          "delete, not a modify", t, a)
            problems.append(f"modify {fmt_key(key)}: valid cleared")
        elif got_key != key:
            dut._log.info("    FAILED  T%d[%d] key changed to %s - the hash is "
                          "over the key, so it must not move",
                          t, a, fmt_key(got_key))
            problems.append(f"modify {fmt_key(key)}: key changed")
        elif got_val != new_val:
            dut._log.info("    FAILED  T%d[%d] value is [%s], expected [%s]",
                          t, a, fmt_value(got_val), fmt_value(new_val))
            problems.append(f"modify {fmt_key(key)}: value [{fmt_value(got_val)}]")
        else:
            dut._log.info("    MODIFIED  T%d[%d] key unchanged, value now [%s]",
                          t, a, fmt_value(new_val))

        if occupancy(after) != occupancy(before):
            dut._log.warning("    occupancy changed %d -> %d - a modify is a "
                             "rewrite, not a delete",
                             occupancy(before), occupancy(after))
            problems.append(f"modify {fmt_key(key)}: occupancy changed")

    # ---- summary ---------------------------------------------------------
    tables = await snapshot(dut, rams)

    dut._log.info("")
    dut._log.info("=" * 88)
    dump(dut._log, tables, "FINAL STATE")
    dut._log.info("")

    expected_final = N_INSERT - len(DELETE_IDX)
    dut._log.info("  occupancy %d of %d  (%d inserted, %d deleted, "
                  "%d modified in place -> expect %d)",
                  occupancy(tables), CAPACITY, N_INSERT,
                  len(DELETE_IDX), len(MODIFY_IDX), expected_final)

    if problems:
        dut._log.warning("")
        dut._log.warning("  %d problem(s):", len(problems))
        for p in problems:
            dut._log.warning("    %s", p)
    else:
        dut._log.info("  all inserts placed, all lookups hit, all deletions "
                      "and modifications clean")

    dut._log.info("=" * 88)
