"""
cocotb testbench for order_book - realistic traffic walkthrough.

Drives ASX-shaped order IDs through the AXI-Stream slave interface, fills the
tables to roughly 50%, then runs lookups, deletes, replaces and executions.
Table contents are printed after every operation.

No assertions. This is a visibility harness - it reports what happened and
flags anything that looks wrong, rather than failing the run.

OPERATIONS

The operation is carried on s_op as a t_book_op enumeration, matching what
book_input_stage emits. There is no separate key_op:

    OP_ADD      0   insert
    OP_EXEC     1   probe, subtract the executed quantity from what rests
    OP_REPLACE  2   probe, then rewrite price and quantity in place
    OP_DELETE   3   probe, then clear the slot
    OP_NULL     4   no operation - used while s_lookup probes

A probe-only lookup is driven by raising s_lookup with s_op at OP_NULL, since
no ITCH message is a bare lookup.

TOPLEVEL IS order_book_top

order_book exposes its memory ports rather than owning the memory, so it
cannot run standalone. order_book_top wires it to a real ram_array. The table
contents below are read straight out of that RAM through the design hierarchy,
so read latency and read-during-write are whatever the RTL actually does.

KEY LAYOUT

The RTL builds its key as  s_order_id & s_side,  so side is bit 0 and the
order ID occupies bits 64..1. This is NOT the layout in hash65_pkg's make_key,
which puts side at bit 64. The testbench follows the RTL.

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

CAPACITY = NUM_TABLES * DEPTH        # 64 slots

CELL_W = 5          # "E5EDB" - low 16 bits of the order ID plus B/S

KEY_HEX = (KEY_W + 3) // 4       # 65 bits -> 17
VAL_HEX = (VAL_W + 3) // 4       # 66 bits -> 17
SLOT_HEX = (SLOT_W + 3) // 4     # 132 bits -> 33

# ---------------------------------------------------------------------------
# t_book_op - ordinals must match the declaration order in order_book_pkg
# ---------------------------------------------------------------------------
# ASSUMES OP_NULL is declared LAST in order_book_pkg:
#
#     type t_book_op is (OP_ADD, OP_EXEC, OP_REPLACE, OP_DELETE, OP_NULL);
#
# cocotb drives the enumeration by ordinal, so if OP_NULL was inserted anywhere
# other than the end, every value below shifts and the testbench will silently
# drive the wrong operations. Reorder this tuple to match the declaration.
OP_NAMES = ("OP_ADD", "OP_EXEC", "OP_REPLACE", "OP_DELETE", "OP_NULL")
OP_SHORT = ("ADD", "EXEC", "REPL", "DEL", "NULL")

OP_ADD     = OP_NAMES.index("OP_ADD")
OP_EXEC    = OP_NAMES.index("OP_EXEC")
OP_REPLACE = OP_NAMES.index("OP_REPLACE")
OP_DELETE  = OP_NAMES.index("OP_DELETE")
OP_NULL    = OP_NAMES.index("OP_NULL")

# ---------------------------------------------------------------------------
# Stimulus
#
# ASX order IDs look like 621f1282:0000e5ed - what appears to be a session or
# day prefix in the high word and a counter in the low word. These follow that
# shape, which also exercises the case that matters most for the hash: if the
# low bits really are a dense counter, table 0 collisions are driven almost
# entirely by them.
#
# Fill to 50% of capacity. Above that, fixed-order insertion produces long
# chains at table 0 regardless of hash quality, which muddies what the other
# operations are being shown to do.
# ---------------------------------------------------------------------------
SESSION_PREFIX = 0x621F1282
FIRST_SEQ = 0x0000E5ED

N_INSERT = CAPACITY // 2             # 32 orders

# Which inserted orders each phase operates on, by index.
LOOKUP_IDX = [3, 11, 27]

# Executions. Three partial fills, then one that takes the whole resting
# quantity - which must remove the order, since ITCH sends no Delete for an
# order that fills completely (spec 2.6.2.4). Undisclosed orders are the
# exception to that rule and are not exercised here.
EXEC_PARTIAL_IDX = [7, 19, 25]
EXEC_FULL_IDX = [9]
REPLACE_IDX = [1, 14, 22]
DELETE_IDX = [5, 17, 30]

MAX_CYCLES = 80

# Cycles of write-port silence before an operation is considered finished.
# Only inserts assert busy, so for everything else this is the completion test.
TAIL_CYCLES = 4


def make_order_id(n: int) -> int:
    """ASX-shaped: fixed session prefix, incrementing sequence."""
    return (SESSION_PREFIX << 32) | ((FIRST_SEQ + n) & 0xFFFFFFFF)


def make_key(order_id: int, side: int) -> int:
    """Matches the RTL:  key <= s_order_id & s_side.  Side is bit 0."""
    return ((order_id & ((1 << ORDER_ID_W) - 1)) << 1) | (side & 1)


def split_key(key: int):
    return (key >> 1) & ((1 << ORDER_ID_W) - 1), key & 1


def u32(v: int) -> int:
    """
    Two's complement 32-bit.

    s_qty and s_price are std_logic_vector, not unsigned/signed, so cocotb
    will not accept a negative int - it has no sign to work from. Prices are
    genuinely signed on the wire, so anything negative is converted here.
    """
    return v & 0xFFFFFFFF


def to_signed32(v: int) -> int:
    return v - (1 << 32) if v & 0x80000000 else v


def make_value(qty: int, price: int, undisc: int = 0, implied: int = 0) -> int:
    """
    Matches the RTL:  value <= s_qty & s_price & s_undisc & s_implied.

        qty      bits 65..34
        price    bits 33..2
        undisc   bit  1
        implied  bit  0
    """
    return ((u32(qty) << 34)
            | (u32(price) << 2)
            | ((undisc & 1) << 1)
            | (implied & 1))


def split_value(v: int):
    if v is None:
        return None
    return {
        "qty": (v >> 34) & 0xFFFFFFFF,
        "price": to_signed32((v >> 2) & 0xFFFFFFFF),
        "undisc": (v >> 1) & 1,
        "implied": v & 1,
    }


def slot_key(slot):
    return None if slot is None else (slot >> VAL_W) & KEY_MASK


def slot_val(slot):
    return None if slot is None else slot & VAL_MASK


# The traffic: alternating sides, sequential IDs, a distinct quantity and price
# per order so a value written to the wrong slot is obvious.
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
# Annotation only. Every check is made against what is actually in the RAM, so
# a drift here misleads the log but cannot produce a false pass.
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
            v &= ~((1 << ADDR_W) - 1)
            v |= (1 << b)
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
# Formatting
# ---------------------------------------------------------------------------
def safe_int(handle):
    try:
        return int(handle.value)
    except (ValueError, TypeError):
        return None


def read_op(handle):
    """
    Read t_book_op as an index into OP_NAMES.

    NVC may present a VHDL enumeration as either its ordinal or its literal
    name depending on cocotb version, so both are accepted.
    """
    v = handle.value
    try:
        return int(v)
    except (ValueError, TypeError):
        name = str(v).strip().upper()
        if name in OP_NAMES:
            return OP_NAMES.index(name)
        return None


def fmt(v):
    return "?" if v is None else str(v)


def fmt_op(idx):
    if idx is None or idx >= len(OP_SHORT):
        return "????"
    return OP_SHORT[idx]


def fmt_key(key):
    """Decomposed key plus the raw KEY_W-bit hex."""
    if key is None:
        return f"{'....':>17} =0x{'?' * KEY_HEX}"
    oid, side = split_key(key)
    return (f"{oid >> 32:08X}:{oid & 0xFFFFFFFF:08X}{'B' if side == 0 else 'S'}"
            f" =0x{key:0{KEY_HEX}X}")


def fmt_value(v):
    d = split_value(v)
    if d is None:
        return f"---- =0x{'?' * VAL_HEX}"
    return (f"qty={d['qty']} px={d['price']} u={d['undisc']} i={d['implied']}"
            f" =0x{v:0{VAL_HEX}X}")


def fmt_slot(slot):
    if slot is None:
        return "0x" + "?" * SLOT_HEX
    return f"0x{slot:0{SLOT_HEX}X}"


def fmt_key_short(key):
    if key is None:
        return "?" * CELL_W
    oid, side = split_key(key)
    return f"{oid & 0xFFFF:04X}{'B' if side == 0 else 'S'}"


def fmt_cell(slot):
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
    return [[safe_int(rams[t][a]) for a in range(DEPTH)]
            for t in range(NUM_TABLES)]


def dump(log, tables, label=""):
    """
    Print every table as one block.

    One log call with embedded newlines rather than one per table: cocotb
    prefixes each record with about 50 columns of timestamp and logger name,
    and paying that once is what keeps the rows from wrapping.
    """
    lines = []
    if label:
        lines.append(label)
    lines.append("       " + " ".join(f"{a:>{CELL_W}d}" for a in range(DEPTH)))
    for t in range(NUM_TABLES):
        lines.append(f"    T{t} " +
                     " ".join(fmt_cell(tables[t][a]) for a in range(DEPTH)))
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
    op = read_op(dut.s_op)
    lk = safe_int(dut.s_lookup)
    lfound = safe_int(dut.lookup_found)
    lret = safe_int(dut.lookup_return)

    raddr = [safe_int(dut.raddr[t]) for t in range(NUM_TABLES)]

    wr = "-"
    observed = None
    if we == 1 and wdata is not None and wsel is not None and waddr is not None:
        vbit = (wdata >> VALID_BIT) & 1
        wr = (f"T{wsel}[{waddr:2d}]<={'V' if vbit else 'x'} "
              f"0x{slot_key(wdata):0{KEY_HEX}X}")
        observed = (cycle, wsel, waddr, slot_key(wdata), slot_val(wdata), vbit)

    dut._log.info(
        "cyc %2d | tv=%s tr=%s op=%-4s lk=%s busy=%s | raddr=%s | write %s "
        "| found=%s ret=%s",
        cycle, fmt(tvalid), fmt(tready), fmt_op(op), fmt(lk), fmt(busy),
        raddr, wr, fmt(lfound),
        "...." if lret is None else f"0x{lret & KEY_MASK:0{KEY_HEX}X}",
    )
    return observed


def report_writes(log, writes, indent="    "):
    """
    Print every write seen on the bus during an operation.

    This separates the ways an operation can fail: no write at all, a write to
    the wrong slot, or a write of the wrong data. Comparing table snapshots
    alone cannot tell them apart.
    """
    if not writes:
        log.info("%sno write observed on the bus", indent)
        return
    for n, (c, t, a, k, v, vbit) in enumerate(writes):
        log.info("%swrite %d @ cycle %d: T%d[%d]  valid=%d  key=%s",
                 indent, n, c, t, a, vbit, fmt_key(k))
        log.info("%s          value [%s]", indent, fmt_value(v))


# ---------------------------------------------------------------------------
# Stimulus drivers
# ---------------------------------------------------------------------------
async def issue(dut, order_id, side, op, qty=0, price=0, undisc=0, implied=0,
                lookup=0, settle=3, quiet=False):
    """
    Offer one command and wait for it to complete.

    Holds s_tvalid until a rising edge where s_tready is also high, then drops
    it. Every input is held through the cycles that follow: the RTL samples the
    operation while its probe is in flight, and the read addresses are
    combinational off the key.

    Returns (writes, probes):
        writes  (cycle, wsel, waddr, key, value, valid) per observed write
        probes  (cycle, lookup_found, lookup_return) per cycle

    Sampling every cycle matters. lookup_found is asserted for a single cycle,
    so a fixed-offset sample reads zero. Completion is likewise detected by the
    write port going quiet rather than by a cycle count: only OP_ADD asserts
    busy, so for everything else there is no other completion signal.
    """
    dut.s_order_id.value = order_id
    dut.s_side.value = side
    dut.s_qty.value = u32(qty)
    dut.s_price.value = u32(price)
    dut.s_undisc.value = undisc
    dut.s_implied.value = implied
    dut.s_op.value = op
    dut.s_lookup.value = lookup
    dut.s_px_valid.value = 1 if op in (OP_ADD, OP_REPLACE) else 0
    dut.s_tvalid.value = 1

    cycle = 0
    writes = []
    probes = []

    def sample(c):
        if not quiet:
            w = trace(dut, c)
            if w is not None:
                writes.append(w)
        probes.append((c,
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

    quiet_for = 0
    while cycle < MAX_CYCLES:
        await FallingEdge(dut.clk)
        await ReadOnly()
        before_n = len(writes)
        sample(cycle)
        busy = safe_int(dut.busy)
        await RisingEdge(dut.clk)
        cycle += 1

        if len(writes) > before_n:
            quiet_for = 0
        else:
            quiet_for += 1

        if busy == 0 and cycle >= settle and quiet_for >= TAIL_CYCLES:
            break

    dut.s_op.value = OP_ADD
    dut.s_lookup.value = 0
    await RisingEdge(dut.clk)
    return writes, probes


async def snapshot(dut, rams):
    await FallingEdge(dut.clk)
    await ReadOnly()
    t = read_tables(rams)
    await RisingEdge(dut.clk)
    return t


def check_probe(log, probes, key, problems, what):
    """
    Every operation except ADD probes the table first. lookup_found is a
    one-cycle pulse, so scan the window for it.
    """
    for c, f, r in probes:
        if f == 1 and r is not None and (r & KEY_MASK) == key:
            log.info("    PROBE hit at cycle %d, returned %s", c, fmt_key(r & KEY_MASK))
            return True
    log.info("    PROBE never hit with the right key")
    log.info("    window: %s",
             ", ".join(f"c{c}:f={fmt(f)}" for c, f, _ in probes))
    problems.append(f"{what} {fmt_key(key)}: probe missed")
    return False


def check_single_write(log, writes, exp_t, exp_a, problems, what, key):
    """One write, to the slot the key already occupies. Returns it, or None."""
    if len(writes) != 1:
        log.info("    BUS  expected 1 write, saw %d", len(writes))
        problems.append(f"{what} {fmt_key(key)}: {len(writes)} writes")
        return None
    c, wt, wa, wk, wv, wvalid = writes[0]
    if (wt, wa) != (exp_t, exp_a):
        log.info("    BUS  wrote T%d[%d], expected T%d[%d] - wrong slot",
                 wt, wa, exp_t, exp_a)
        problems.append(f"{what} {fmt_key(key)}: wrote T{wt}[{wa}]")
        return None
    return writes[0]


def collateral(before, after, allowed):
    """Slots that changed other than the one expected to."""
    return [(t, a) for t in range(NUM_TABLES) for a in range(DEPTH)
            if before[t][a] != after[t][a] and (t, a) != allowed]


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_normal_traffic(dut):
    """
    Fill to 50%, then three lookups, three deletes, three replaces, and four
    executions - three partial fills and one that empties the order.
    """
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    # ---- reset -----------------------------------------------------------
    dut.resetn.value = 0
    dut.s_tvalid.value = 0
    dut.s_op.value = OP_ADD
    dut.s_lookup.value = 0
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
    dut._log.info("value    : qty(32) price(32) undisc(1) implied(1)")
    dut._log.info("ops      : s_op carries t_book_op; "
                  "s_lookup + OP_NULL probes only")
    dut._log.info("traffic  : %d adds (%.0f%% load), then %d lookups, "
                  "%d deletes, %d replaces, %d execs",
                  N_INSERT, 100.0 * N_INSERT / CAPACITY, len(LOOKUP_IDX),
                  len(DELETE_IDX), len(REPLACE_IDX),
                  len(EXEC_PARTIAL_IDX) + len(EXEC_FULL_IDX))
    dut._log.info("cells    : <low16 of order id><B|S>")
    dut._log.info("=" * 88)

    problems = []

    # ---- OP_ADD ----------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("ADDS  (s_op = OP_ADD)")
    dut._log.info("=" * 88)

    for i, (oid, side, qty, price) in enumerate(INSERTS):
        key = make_key(oid, side)
        val = make_value(qty, price)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("ADD %2d/%d  %s  [%s]", i + 1, N_INSERT,
                      fmt_key(key), fmt_value(val))
        dut._log.info("    candidates: %s",
                      ", ".join(f"T{t}[{a}]"
                                for t, a in enumerate(hash_all(key))))
        dut._log.info("-" * 88)

        writes, _ = await issue(dut, oid, side, OP_ADD, qty=qty, price=price)
        tables = await snapshot(dut, rams)

        if writes:
            path = " -> ".join(f"T{t}[{a}]" for _, t, a, _, _, _ in writes)
            dut._log.info("    path  : %s   (%d hop%s)",
                          path, len(writes), "" if len(writes) == 1 else "s")
        else:
            dut._log.info("    path  : no write observed")
            problems.append(f"add {fmt_key(key)}: no write")

        where = find_key(tables, key)
        if where:
            raw = tables[where[0]][where[1]]
            dut._log.info("    rests : T%d[%d]  slot %s   occupancy %d/%d",
                          where[0], where[1], fmt_slot(raw),
                          occupancy(tables), CAPACITY)
            if slot_val(raw) != val:
                dut._log.info("    value : [%s], expected [%s]",
                              fmt_value(slot_val(raw)), fmt_value(val))
                problems.append(f"add {fmt_key(key)}: wrong value stored")
        else:
            dut._log.info("    rests : NOT FOUND   occupancy %d/%d",
                          occupancy(tables), CAPACITY)
            problems.append(f"add {fmt_key(key)}: not in any table")

    tables = await snapshot(dut, rams)
    dut._log.info("")
    dump(dut._log, tables,
         f"AFTER FILL  (occupancy {occupancy(tables)}/{CAPACITY}, "
         f"expected {N_INSERT})")
    if occupancy(tables) != N_INSERT:
        problems.append(f"fill: occupancy {occupancy(tables)}, "
                        f"expected {N_INSERT}")

    # ---- lookups ---------------------------------------------------------
    #
    # s_lookup probes without writing, with s_op held at OP_NULL so no
    # operation is requested alongside it.
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("LOOKUPS  (s_lookup = 1, probe only)")
    dut._log.info("=" * 88)

    for idx in LOOKUP_IDX:
        oid, side, qty, price = INSERTS[idx]
        key = make_key(oid, side)

        before = await snapshot(dut, rams)
        at = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("LOOKUP %s   (added as #%d, at %s)",
                      fmt_key(key), idx,
                      f"T{at[0]}[{at[1]}]" if at else "NOWHERE")
        dut._log.info("-" * 88)

        writes, probes = await issue(dut, oid, side, OP_NULL, lookup=1)
        after = await snapshot(dut, rams)

        check_probe(dut._log, probes, key, problems, "lookup")

        # A lookup must not disturb the tables at all.
        if writes:
            report_writes(dut._log, writes)
            dut._log.info("    BUS  a lookup must not write")
            problems.append(f"lookup {fmt_key(key)}: {len(writes)} writes")
        if before != after:
            dut._log.info("    RAM  contents changed during a lookup")
            problems.append(f"lookup {fmt_key(key)}: tables modified")

    # ---- OP_DELETE -------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("DELETES  (s_op = OP_DELETE)")
    dut._log.info("=" * 88)

    for idx in DELETE_IDX:
        oid, side, qty, price = INSERTS[idx]
        key = make_key(oid, side)

        before = await snapshot(dut, rams)
        at = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("DELETE %s   (added as #%d, at %s)",
                      fmt_key(key), idx,
                      f"T{at[0]}[{at[1]}]" if at else "NOWHERE")
        dut._log.info("-" * 88)

        writes, probes = await issue(dut, oid, side, OP_DELETE)
        after = await snapshot(dut, rams)

        report_writes(dut._log, writes)
        check_probe(dut._log, probes, key, problems, "delete")

        if at is None:
            problems.append(f"delete {fmt_key(key)}: was not present")
            continue

        t, a = at
        w = check_single_write(dut._log, writes, t, a, problems, "delete", key)
        if w is not None:
            _, _, _, _, _, wvalid = w
            if wvalid != 0:
                dut._log.info("    BUS  valid bit still set - the slot was "
                              "rewritten, not cleared")
                problems.append(f"delete {fmt_key(key)}: valid still set")

        if find_key(after, key) is None:
            dut._log.info("    DELETED")
        else:
            w2 = find_key(after, key)
            dut._log.info("    NOT DELETED - still at T%d[%d]", w2[0], w2[1])
            problems.append(f"delete {fmt_key(key)}: still present")

        for ct, ca in collateral(before, after, at):
            dut._log.warning("    collateral change at T%d[%d]", ct, ca)
            problems.append(f"delete {fmt_key(key)}: collateral T{ct}[{ca}]")

        dump(dut._log, after,
             f"    after delete  (occupancy {occupancy(after)}/{CAPACITY})")

    # ---- OP_REPLACE ------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("REPLACES  (s_op = OP_REPLACE)")
    dut._log.info("=" * 88)
    dut._log.info("A replace rewrites price and quantity at the SAME address.")
    dut._log.info("The hash is over the key, and the key does not change, so")
    dut._log.info("the slot cannot move. The order loses queue priority, but")
    dut._log.info("that is a price-level concern, not a table one.")

    for idx in REPLACE_IDX:
        oid, side, qty, price = INSERTS[idx]
        key = make_key(oid, side)

        new_qty = qty + 500
        new_price = price + 25
        new_val = make_value(new_qty, new_price, undisc=1)

        before = await snapshot(dut, rams)
        at = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("REPLACE %s   (added as #%d, at %s)",
                      fmt_key(key), idx,
                      f"T{at[0]}[{at[1]}]" if at else "NOWHERE")
        dut._log.info("    value [%s] -> [%s]",
                      fmt_value(make_value(qty, price)), fmt_value(new_val))
        dut._log.info("-" * 88)

        writes, probes = await issue(dut, oid, side, OP_REPLACE,
                                     qty=new_qty, price=new_price, undisc=1)
        after = await snapshot(dut, rams)

        report_writes(dut._log, writes)
        check_probe(dut._log, probes, key, problems, "replace")

        if at is None:
            problems.append(f"replace {fmt_key(key)}: was not present")
            continue

        t, a = at
        w = check_single_write(dut._log, writes, t, a, problems, "replace", key)
        if w is not None:
            _, _, _, wk, wv, wvalid = w
            if wvalid != 1:
                dut._log.info("    BUS  valid bit cleared - that is a delete")
                problems.append(f"replace {fmt_key(key)}: valid cleared")
            elif wk != key:
                dut._log.info("    BUS  key changed to %s - the slot must not "
                              "move", fmt_key(wk))
                problems.append(f"replace {fmt_key(key)}: key changed")
            elif wv != new_val:
                dut._log.info("    BUS  value [%s], expected [%s]",
                              fmt_value(wv), fmt_value(new_val))
                problems.append(f"replace {fmt_key(key)}: wrong value")
            else:
                dut._log.info("    REPLACE OK  T%d[%d] key unchanged, value "
                              "now [%s]", t, a, fmt_value(new_val))

        if occupancy(after) != occupancy(before):
            dut._log.warning("    occupancy %d -> %d - a replace is a rewrite",
                             occupancy(before), occupancy(after))
            problems.append(f"replace {fmt_key(key)}: occupancy changed")

        for ct, ca in collateral(before, after, at):
            dut._log.warning("    collateral change at T%d[%d]", ct, ca)
            problems.append(f"replace {fmt_key(key)}: collateral T{ct}[{ca}]")

        dump(dut._log, after,
             f"    after replace  (occupancy {occupancy(after)}/{CAPACITY})")

    # ---- OP_EXEC ---------------------------------------------------------
    #
    # s_qty carries the executed quantity, to be subtracted from what is
    # resting. Note the RTL takes the non-quantity fields of the value from the
    # COMMAND rather than from the stored slot, so the testbench drives the
    # original price to keep the stored value coherent. On the wire an EXEC
    # carries no price at all (s_px_valid is low), so this is a place the RTL
    # and the message format do not yet agree.
    dut._log.info("")
    dut._log.info("=" * 88)
    dut._log.info("EXECUTIONS  (s_op = OP_EXEC)")
    dut._log.info("=" * 88)

    exec_cases = ([(i, False) for i in EXEC_PARTIAL_IDX]
                  + [(i, True) for i in EXEC_FULL_IDX])

    for idx, full in exec_cases:
        oid, side, qty, price = INSERTS[idx]
        key = make_key(oid, side)

        exec_qty = qty if full else qty // 4
        rem_qty = qty - exec_qty
        new_val = make_value(rem_qty, price)

        before = await snapshot(dut, rams)
        at = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 88)
        dut._log.info("EXEC %s   (added as #%d, at %s)",
                      fmt_key(key), idx,
                      f"T{at[0]}[{at[1]}]" if at else "NOWHERE")
        dut._log.info("    resting qty %d, executed %d, remaining %d%s",
                      qty, exec_qty, rem_qty,
                      "  -> FULL FILL, order must be removed" if full else "")
        dut._log.info("-" * 88)

        writes, probes = await issue(dut, oid, side, OP_EXEC,
                                     qty=exec_qty, price=price)
        after = await snapshot(dut, rams)

        report_writes(dut._log, writes)
        check_probe(dut._log, probes, key, problems, "exec")

        if at is None:
            problems.append(f"exec {fmt_key(key)}: was not present")
            continue

        t, a = at
        w = check_single_write(dut._log, writes, t, a, problems, "exec", key)

        if full:
            # A complete fill removes the order. No Delete message follows, so
            # the engine has to do this itself.
            if w is not None:
                _, _, _, _, wv, wvalid = w
                if wvalid == 0:
                    dut._log.info("    BUS  slot cleared - correct for a "
                                  "full fill")
                else:
                    dut._log.info("    BUS  valid bit still set with qty %d - "
                                  "a fully filled order must be removed",
                                  split_value(wv)["qty"] if wv else 0)
                    problems.append(f"exec {fmt_key(key)}: full fill left "
                                    f"the order resting")

            if find_key(after, key) is None:
                dut._log.info("    REMOVED")
            else:
                w2 = find_key(after, key)
                dut._log.info("    NOT REMOVED - still at T%d[%d] with [%s]",
                              w2[0], w2[1], fmt_value(slot_val(after[w2[0]][w2[1]])))
                problems.append(f"exec {fmt_key(key)}: still present after "
                                f"full fill")
        else:
            if w is not None:
                _, _, _, wk, wv, wvalid = w
                if wvalid != 1:
                    dut._log.info("    BUS  valid bit cleared - a partial fill "
                                  "leaves the order resting")
                    problems.append(f"exec {fmt_key(key)}: valid cleared")
                elif wk != key:
                    dut._log.info("    BUS  key changed to %s", fmt_key(wk))
                    problems.append(f"exec {fmt_key(key)}: key changed")
                elif wv != new_val:
                    got = split_value(wv)
                    dut._log.info("    BUS  value [%s], expected [%s]",
                                  fmt_value(wv), fmt_value(new_val))
                    if got and got["qty"] > qty:
                        dut._log.info("         quantity larger than what was "
                                      "resting - the subtract wrapped, so the "
                                      "operands or the comparison are the "
                                      "wrong way round")
                    problems.append(f"exec {fmt_key(key)}: wrong value")
                else:
                    dut._log.info("    EXEC OK  T%d[%d] qty %d -> %d",
                                  t, a, qty, rem_qty)

        for ct, ca in collateral(before, after, at):
            dut._log.warning("    collateral change at T%d[%d]", ct, ca)
            problems.append(f"exec {fmt_key(key)}: collateral T{ct}[{ca}]")

        dump(dut._log, after,
             f"    after exec  (occupancy {occupancy(after)}/{CAPACITY})")

    # ---- summary ---------------------------------------------------------
    tables = await snapshot(dut, rams)

    dut._log.info("")
    dut._log.info("=" * 88)
    dump(dut._log, tables, "FINAL STATE")

    # Each full fill removes an order, same as a delete.
    expected_final = N_INSERT - len(DELETE_IDX) - len(EXEC_FULL_IDX)
    dut._log.info("")
    dut._log.info("  occupancy %d of %d  (%d added, %d deleted, %d replaced "
                  "in place, %d partly filled, %d fully filled -> expect %d)",
                  occupancy(tables), CAPACITY, N_INSERT, len(DELETE_IDX),
                  len(REPLACE_IDX), len(EXEC_PARTIAL_IDX),
                  len(EXEC_FULL_IDX), expected_final)

    # Per-table load, which is the interesting asymmetry under fixed-order
    # insertion: table 0 takes every add, so the distribution is skewed and
    # the later tables stay nearly empty at moderate load.
    dut._log.info("")
    dut._log.info("  load per table:")
    for t in range(NUM_TABLES):
        n = sum(1 for s in tables[t]
                if s is not None and (s >> VALID_BIT) & 1)
        dut._log.info("    T%d  %2d/%2d  %s", t, n, DEPTH, "#" * n)

    if problems:
        dut._log.warning("")
        dut._log.warning("  %d problem(s):", len(problems))
        for p in problems:
            dut._log.warning("    %s", p)
    else:
        dut._log.info("  all adds placed, all probes hit, all execs, replaces "
                      "and deletes clean")

    dut._log.info("=" * 88)
