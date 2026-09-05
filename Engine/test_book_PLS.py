"""
cocotb testbench for book_PLS_top - order_book with the price level stage.

A VISIBILITY HARNESS. It drives traffic and prints state. It does not check
anything, model anything, or decide whether the design is correct - there are
no assertions, no expected values and no pass/fail verdict beyond "the run
completed". Reading the dumps is the verification step, and that is yours.


THE TRAFFIC

Same shape and count as test_order_book - 32 adds, 3 deletes, 3 replaces, and
4 executions - but every message is on ONE SIDE at ONE PRICE:

    side   = 1  (sell)  on every message
    price  = 50000      on every message
    qty    varies       100, 200, 300 ... 3200

so the only thing that distinguishes one order from another is its ID and its
quantity. Everything lands in a single price level, which is the case that
exercises the level table hardest: consecutive mutations to the same index,
back to back, with the read-during-write behaviour that level_array's header
says price_storage has to forward around.

Change SIDE, PRICE, or the quantity rules in the CONFIGURATION block below.


WHAT GETS PRINTED, PER MESSAGE

    1. the command issued
    2. the cycle-by-cycle bus trace while it drains
    3. any book event that came out on m_*
    4. every write seen on either write port
    5. the four order hash tables, as keys and again as quantities
    6. the level memory model - every level ever written, plus the window
    7. the price_storage bus and output state, including what the model is
       driving back on lvl_rdata

That is the whole point of this file, so it is verbose by design. Expect a
hundred-odd lines per message across 42 messages. Redirect to a file:

    powershell -ExecutionPolicy Bypass -File .\book_PLS_sim.ps1 *> run.log


WHAT THE PREVIOUS VERSION DID THAT THIS ONE DOES NOT

The price-map sweep test is gone. It varied price across every band, which is
the opposite of a single fixed price, and it worked by comparing the RTL
against a Python mirror of the band table - a check, not a dump. Both reasons
put it outside what this file is now for. There is ONE test here, not two.

Also gone: the Python aggregation model, the px_index mirror, and the problem
list. Nothing in this file computes what the answer should be. The only
arithmetic left is unpacking slots into their fields for display.


TOPLEVEL IS book_PLS_top, AND THE LEVEL MEMORY IS PYTHON

level_array.vhd has been taken out. price_storage's level bus comes out to the
pins and level_ram_model.LevelRam answers it from here - one write port with a
single-bit wsel, one read address broadcast to both sides, read latency 1,
read-during-write returns old data. The model's header states the timing it is
reproducing.

The order table is still real memory, read through the hierarchy:

    u_ram_arr.g_tables[t].u_ram.ram[addr]      order slot, 132 bit

so the two halves of the picture come from different places: the order tables
are what the RTL actually holds, the level tables are what the model was told
to hold. Both are printed after every message and the log says which is which.

The event bus handshake is not closed inside the toplevel - price_storage does
not drive s_tready, so m_tready is driven here. See book_PLS_top.vhd.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly

from level_ram_model import (LevelRam, drive_level_ram, fmt_level,
                             LVL_DEPTH, LVL_ADDR_W, LEVEL_W,
                             LVL_SIDE_W, LVL_QTY_W, LVL_PRICE_W,
                             NUM_SIDES)

CLK_PERIOD_NS = 6.4          # 156.25 MHz

# ===========================================================================
# CONFIGURATION - the stimulus
# ===========================================================================

# Every message carries these. 1 = sell.
#
# 50000 price units. At C_PX_PER_CENT = 10 that is 5000 cents, $50.00, which
# sits in the top band where the tick is 10 units - so the price is on-tick and
# px_legal would accept it. Nothing here depends on that; it is just worth
# knowing that an off-tick price would still map to a level and the design
# would carry on without complaint.
SIDE = 1
PRICE = 50000


def add_qty(i: int) -> int:
    """Quantity of added order i."""
    return 100 * (i + 1)                # 100, 200, 300 ... 3200


def replace_qty(i: int, old: int) -> int:
    """Quantity a replace rewrites order i to."""
    return old * 2


def exec_qty(i: int, old: int, full: bool) -> int:
    """Quantity an execution takes off order i."""
    return old if full else old // 4


# Which added orders each phase acts on, by index. Counts match
# test_order_book: 3 deletes, 3 replaces, 3 partial fills, 1 full fill.
DELETE_IDX = [5, 17, 30]
REPLACE_IDX = [1, 14, 22]
EXEC_PARTIAL_IDX = [7, 19, 25]
EXEC_FULL_IDX = [9]

# Block RAM write mode the level memory is modelled with. See the table in
# level_ram_model.py. WRITE_FIRST is the block RAM default and does NOT give
# the read port new data on a collision - it gives an undefined value, which
# the model surfaces as X. READ_FIRST is the only mode with a defined read
# during write.
LVL_WRITE_MODE = "WRITE_FIRST"

# Which level indices get printed after every message.
#
# Nothing is hardcoded and nothing is computed from the price. The window
# FOLLOWS THE DESIGN: whatever index turns up on lvl_raddr or lvl_waddr gets
# added, along with WATCH_SPAN neighbours either side so the levels next to the
# active one are visible too. That way the dump cannot go stale when PRICE
# changes, and it cannot quietly miss the level if the price maps somewhere
# other than where you expected.
#
# WATCH_SEED is for indices you want shown regardless of whether the design
# ever addresses them. Usually empty.
WATCH_SEED = set()
WATCH_SPAN = 5

WATCH_LEVELS = set(WATCH_SEED)

# ---------------------------------------------------------------------------
# Order table geometry - must match ram_pkg
# ---------------------------------------------------------------------------
NUM_TABLES = 4
ADDR_W = 4
DEPTH = 2 ** ADDR_W
ORDER_ID_W = 64
KEY_W = ORDER_ID_W + 1
VAL_W = 66
SLOT_W = 1 + KEY_W + VAL_W
VALID_BIT = SLOT_W - 1
KEY_MASK = (1 << KEY_W) - 1
VAL_MASK = (1 << VAL_W) - 1
CAPACITY = NUM_TABLES * DEPTH

KEY_HEX = (KEY_W + 3) // 4

CELL_W = 5          # "E5EDS" - low 16 bits of the order ID plus B/S
QCELL_W = 6         # quantity cell

# ---------------------------------------------------------------------------
# Level table geometry
#
# Imported from level_ram_model rather than restated, so the model and the
# harness cannot drift apart. level_array.vhd is gone; the model IS the level
# memory now.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# t_book_op - ordinals must match the declaration order in ram_pkg
#
# NOTE: t_book_op is declared in ram_pkg, NOT order_book_pkg, and it has FOUR
# literals:
#
#     type t_book_op is (OP_ADD, OP_EXEC, OP_REPLACE, OP_DELETE);
#
# test_order_book.py carries a fifth, OP_NULL. It never drives it, so nothing
# breaks there, but the tuple does not describe the RTL.
# ---------------------------------------------------------------------------
OP_NAMES = ("OP_ADD", "OP_EXEC", "OP_REPLACE", "OP_DELETE")
OP_SHORT = ("ADD", "EXEC", "REPL", "DEL")

OP_ADD = OP_NAMES.index("OP_ADD")
OP_EXEC = OP_NAMES.index("OP_EXEC")
OP_REPLACE = OP_NAMES.index("OP_REPLACE")
OP_DELETE = OP_NAMES.index("OP_DELETE")

# ---------------------------------------------------------------------------
# Order IDs - ASX shaped, fixed session prefix and an incrementing sequence
# ---------------------------------------------------------------------------
SESSION_PREFIX = 0x621F1282
FIRST_SEQ = 0x0000E5ED

N_INSERT = CAPACITY // 2             # 32 orders

MAX_CYCLES = 80
TAIL_CYCLES = 4


def make_order_id(n: int) -> int:
    return (SESSION_PREFIX << 32) | ((FIRST_SEQ + n) & 0xFFFFFFFF)


def make_key(order_id: int, side: int) -> int:
    """Matches the RTL:  key <= s_order_id & s_side.  Side is bit 0."""
    return ((order_id & ((1 << ORDER_ID_W) - 1)) << 1) | (side & 1)


def split_key(key: int):
    return (key >> 1) & ((1 << ORDER_ID_W) - 1), key & 1


def u32(v: int) -> int:
    """s_qty and s_price are std_logic_vector, so cocotb needs an unsigned."""
    return v & 0xFFFFFFFF


def to_signed32(v: int) -> int:
    return v - (1 << 32) if v & 0x80000000 else v


def split_value(v):
    """Matches the RTL:  value <= s_qty & s_price & s_undisc & s_implied."""
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


# The traffic. Every order on the same side at the same price; only the ID and
# the quantity move.
INSERTS = [
    (make_order_id(i), SIDE, add_qty(i), PRICE)
    for i in range(N_INSERT)
]


# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------
def safe_int(handle):
    try:
        return int(handle.value)
    except (ValueError, TypeError):
        return None


def read_op(handle):
    """t_book_op as an index into OP_NAMES. NVC may give ordinal or name."""
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
    if key is None:
        return f"{'....':>17} =0x{'?' * KEY_HEX}"
    oid, side = split_key(key)
    return (f"{oid >> 32:08X}:{oid & 0xFFFFFFFF:08X}"
            f"{'B' if side == 0 else 'S'} =0x{key:0{KEY_HEX}X}")


def fmt_key_short(key):
    if key is None:
        return "?" * CELL_W
    oid, side = split_key(key)
    return f"{oid & 0xFFFF:04X}{'B' if side == 0 else 'S'}"


def fmt_value(v):
    d = split_value(v)
    if d is None:
        return "?"
    return (f"qty={d['qty']} px={d['price']} "
            f"undisc={d['undisc']} implied={d['implied']}")


def fmt_cell(slot):
    """Order table cell, as a key."""
    if slot is None:
        return "?" * CELL_W
    if (slot >> VALID_BIT) & 1:
        return fmt_key_short(slot_key(slot))
    return "." * CELL_W


def fmt_qcell(slot):
    """
    Order table cell, as a quantity.

    With every order at the same side and the same price, quantity is the only
    field that tells one resting order from another, so it gets its own grid.
    """
    if slot is None:
        return "?" * QCELL_W
    if not ((slot >> VALID_BIT) & 1):
        return "." * QCELL_W
    d = split_value(slot_val(slot))
    return f"{d['qty']:>{QCELL_W}d}" if d else "?" * QCELL_W


LVL_FIELD_W = 34


# ---------------------------------------------------------------------------
# Reaching the ORDER table contents through the hierarchy
#
# Only the order table. The level memory is level_ram_model.LevelRam and is
# read by calling it, not by walking the design.
# ---------------------------------------------------------------------------
def _reach(parent, gen_label, index, what):
    """One RAM handle out of a generate, however the simulator names it."""
    attempts = []
    try:
        return getattr(parent, gen_label)[index].u_ram.ram
    except Exception as e:                     # noqa: BLE001
        attempts.append(f"{gen_label}[{index}] -> {e}")

    for name in (f"{gen_label}({index})", f"{gen_label}[{index}]",
                 f"{gen_label}_{index}"):
        try:
            return getattr(parent, name).u_ram.ram
        except Exception as e:                 # noqa: BLE001
            attempts.append(f"{name} -> {e}")

    raise AssertionError(
        f"Could not reach the {what} RAM contents through the hierarchy.\n"
        "Tried:\n  " + "\n  ".join(attempts) +
        "\n\nRun with NVC's --preserve-case (the runner already does) and "
        "check the instance names in book_PLS_top.vhd, ram_array.vhd and "
        "level_array.vhd match those above."
    )


def find_ram_handles(dut):
    return [_reach(dut.u_ram_arr, "g_tables", t, "order")
            for t in range(NUM_TABLES)]


def read_tables(rams):
    return [[safe_int(rams[t][a]) for a in range(DEPTH)]
            for t in range(NUM_TABLES)]


# ---------------------------------------------------------------------------
# Dumps
# ---------------------------------------------------------------------------
def dump_orders(log, tables, label=""):
    """
    The four order tables, twice - once as keys, once as quantities.

    One log call with embedded newlines rather than one per row: cocotb
    prefixes each record with about 50 columns of timestamp and logger name,
    and paying that once is what keeps the rows from wrapping.
    """
    lines = []
    if label:
        lines.append(label)

    lines.append("      keys")
    lines.append("         " + " ".join(f"{a:>{CELL_W}d}"
                                        for a in range(DEPTH)))
    for t in range(NUM_TABLES):
        lines.append(f"      T{t} " +
                     " ".join(fmt_cell(tables[t][a]) for a in range(DEPTH)))

    lines.append("      quantities")
    lines.append("         " + " ".join(f"{a:>{QCELL_W}d}"
                                        for a in range(DEPTH)))
    for t in range(NUM_TABLES):
        lines.append(f"      T{t} " +
                     " ".join(fmt_qcell(tables[t][a]) for a in range(DEPTH)))

    n = sum(1 for t in range(NUM_TABLES) for s in tables[t]
            if s is not None and (s >> VALID_BIT) & 1)
    lines.append(f"      occupancy {n}/{CAPACITY}")

    log.info("%s", "\n".join(lines))


def dump_levels(log, ram, label=""):
    """
    The level memory, out of the model.

    The model shows every index it has ever been written at, plus the watched
    window, so a level the design never touched still appears as zero rather
    than quietly going missing.
    """
    lines = []
    if label:
        lines.append(label)
    lines.append(ram.dump(extra_levels=WATCH_LEVELS, width=LVL_FIELD_W))
    log.info("%s", "\n".join(lines))


def dump_pls(log, dut, label=""):
    """
    The price_storage bus and outputs, exactly as they stand.

    'U' on an output means price_storage is not driving it. Reported as read,
    with no interpretation.
    """
    # Read data is what the MODEL is driving back, split one port per side.
    rdata = [safe_int(dut.lvl_rdata0), safe_int(dut.lvl_rdata1)]

    lines = []
    if label:
        lines.append(label)
    lines.append(f"      level write : we={fmt(safe_int(dut.lvl_we))} "
                 f"wsel={fmt(safe_int(dut.lvl_wsel))} "
                 f"waddr={fmt(safe_int(dut.lvl_waddr))}")
    lines.append(f"                    "
                 f"wdata={fmt_level(safe_int(dut.lvl_wdata), LVL_FIELD_W)}")
    lines.append(f"      level read  : raddr={fmt(safe_int(dut.lvl_raddr))}")
    for s in range(NUM_SIDES):
        lines.append(f"                    rdata[{s}]="
                     f"{fmt_level(rdata[s], LVL_FIELD_W)} (from the model)")
    lines.append(f"      handshake   : "
                 f"s_tready={fmt(safe_int(dut.pls_tready))} "
                 f"busy={fmt(safe_int(dut.pls_busy))} "
                 f"oor={fmt(safe_int(dut.pls_oor))}")
    lines.append(f"      top of book : "
                 f"tvalid={fmt(safe_int(dut.tob_tvalid))} "
                 f"valid={fmt(safe_int(dut.tob_valid))}")
    lines.append(f"                    bid px={fmt(safe_int(dut.tob_bid_price))}"
                 f" qty={fmt(safe_int(dut.tob_bid_qty))}")
    lines.append(f"                    ask px={fmt(safe_int(dut.tob_ask_price))}"
                 f" qty={fmt(safe_int(dut.tob_ask_qty))}")
    log.info("%s", "\n".join(lines))


# ---------------------------------------------------------------------------
# Bus tracing
# ---------------------------------------------------------------------------
def trace(dut, cycle):
    """
    Print the bus state for the current cycle and return what was seen.

    Call from ReadOnly after a FallingEdge, so the values shown are the ones
    in effect during this cycle - what the memories will act on at the next
    rising edge. Sampling after RisingEdge would show the registers already
    updated for the following cycle.
    """
    we = safe_int(dut.we)
    wsel = safe_int(dut.wsel)
    waddr = safe_int(dut.waddr)
    wdata = safe_int(dut.wdata)
    busy = safe_int(dut.busy)
    tready = safe_int(dut.s_tready)

    ev_v = safe_int(dut.m_tvalid)
    ev_r = safe_int(dut.m_tready)
    ev_op = read_op(dut.m_op)

    lwe = safe_int(dut.lvl_we)
    lwaddr = safe_int(dut.lvl_waddr)
    lraddr = safe_int(dut.lvl_raddr)

    # Whatever level the design touches gets added to the printed window,
    # with its neighbours, so the surrounding levels are visible too.
    for a in (lwaddr, lraddr):
        if a is not None and 0 <= a < LVL_DEPTH:
            WATCH_LEVELS.update(
                range(max(0, a - WATCH_SPAN),
                      min(LVL_DEPTH - 1, a + WATCH_SPAN) + 1))

    wr = "-"
    order_write = None
    if we == 1 and None not in (wdata, wsel, waddr):
        vbit = (wdata >> VALID_BIT) & 1
        wr = (f"T{wsel}[{waddr:2d}]<={'V' if vbit else 'x'} "
              f"0x{slot_key(wdata):0{KEY_HEX}X}")
        order_write = (cycle, wsel, waddr, slot_key(wdata), slot_val(wdata),
                       vbit)

    lw = "-"
    level_write = None
    if lwe == 1:
        lwdata = safe_int(dut.lvl_wdata)
        lwsel = safe_int(dut.lvl_wsel)
        lw = f"S{fmt(lwsel)}[{fmt(lwaddr)}]<= {fmt_level(lwdata, LVL_FIELD_W)}"
        level_write = (cycle, lwsel, lwaddr, lwdata)

    event = None
    if ev_v == 1 and ev_r == 1:
        event = (cycle, ev_op, safe_int(dut.m_side), safe_int(dut.m_qty),
                 safe_int(dut.m_price))

    dut._log.info(
        "cyc %2d | tr=%s busy=%s | order %s | ev=%s %s | "
        "lvl raddr=%s write %s",
        cycle, fmt(tready), fmt(busy), wr, fmt(ev_v),
        fmt_op(ev_op) if ev_v == 1 else "", fmt(lraddr), lw,
    )
    return order_write, event, level_write


# ---------------------------------------------------------------------------
# Stimulus driver
# ---------------------------------------------------------------------------
async def issue(dut, order_id, side, op, qty=0, price=0, undisc=0, implied=0,
                settle=3):
    """
    Offer one command and wait for it to drain.

    Holds s_tvalid until a rising edge where s_tready is also high, then drops
    it. Every input is held through the cycles that follow: the RTL samples
    the operation while its probe is in flight, and the read addresses are
    combinational off the key.

    Completion is detected by both write ports going quiet rather than by a
    cycle count: only OP_ADD asserts busy, so for everything else there is no
    other completion signal.

    Returns (order_writes, events, level_writes).
    """
    dut.s_order_id.value = order_id
    dut.s_side.value = side
    dut.s_qty.value = u32(qty)
    dut.s_price.value = u32(price)
    dut.s_undisc.value = undisc
    dut.s_implied.value = implied
    dut.s_op.value = op
    dut.s_px_valid.value = 1 if op in (OP_ADD, OP_REPLACE) else 0
    dut.s_tvalid.value = 1

    cycle = 0
    order_writes = []
    events = []
    level_writes = []

    def sample(c):
        w, e, lw = trace(dut, c)
        if w is not None:
            order_writes.append(w)
        if e is not None:
            events.append(e)
        if lw is not None:
            level_writes.append(lw)

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
        before = len(order_writes) + len(level_writes)
        sample(cycle)
        busy = safe_int(dut.busy)
        await RisingEdge(dut.clk)
        cycle += 1

        if len(order_writes) + len(level_writes) > before:
            quiet_for = 0
        else:
            quiet_for += 1

        if busy == 0 and cycle >= settle and quiet_for >= TAIL_CYCLES:
            break

    dut.s_op.value = OP_ADD
    await RisingEdge(dut.clk)
    return order_writes, events, level_writes


async def message(dut, rams, ram, banner, order_id, side, op,
                  qty=0, price=0):
    """
    Send one command, then dump everything.

    This is the unit the whole file is built around: one message in, one full
    picture of both memories out.
    """
    key = make_key(order_id, side)

    # Where the model's history stands before this message, so the entries it
    # adds can be pulled out afterwards.
    hist_mark = len(ram.history)
    writes_before = ram.writes
    dropped_before = ram.dropped

    dut._log.info("")
    dut._log.info("-" * 100)
    dut._log.info("%s", banner)
    dut._log.info("    command : op=%s  key=%s  side=%d  qty=%d  price=%d",
                  fmt_op(op), fmt_key(key), side, qty, price)
    dut._log.info("-" * 100)

    order_writes, events, level_writes = await issue(
        dut, order_id, side, op, qty=qty, price=price)

    # ---- what came out on the event bus ----------------------------------
    if events:
        for c, eop, es, eq, ep in events:
            dut._log.info("    event : @cyc %d  op=%s side=%s qty=%s price=%s",
                          c, fmt_op(eop), fmt(es), fmt(eq),
                          fmt(None if ep is None else to_signed32(ep)))
    else:
        dut._log.info("    event : none emitted")

    # ---- what hit the order tables ---------------------------------------
    if order_writes:
        for n, (c, t, a, k, v, vbit) in enumerate(order_writes):
            dut._log.info("    order write %d @cyc %d: T%d[%d] valid=%d "
                          "key=%s", n, c, t, a, vbit, fmt_key(k))
            dut._log.info("                             value %s",
                          fmt_value(v))
    else:
        dut._log.info("    order write : none")

    # ---- what hit the level memory ---------------------------------------
    #
    # Two separate things, and the difference matters when a quantity does not
    # turn up where it should:
    #
    #   "seen on the bus"  - lvl_we was high and this is what was on the pins
    #   "taken/REJECTED"   - what the model then did with it
    #
    # A write can be seen and still not stored. The model refuses anything it
    # cannot place - a metavalue on lvl_waddr or lvl_wdata, an address past the
    # end - and records why rather than guessing. If the bus shows a write and
    # the model shows a rejection, the reason line below is the answer.
    if level_writes:
        for n, (c, s, a, d) in enumerate(level_writes):
            dut._log.info("    level write %d seen on the bus @cyc %d: "
                          "side %s [%s] <= %s",
                          n, c, fmt(s), fmt(a), fmt_level(d, LVL_FIELD_W))
    else:
        dut._log.info("    level write : nothing on the bus "
                      "(lvl_we stayed low)")

    took = ram.writes - writes_before
    lost = ram.dropped - dropped_before

    for rec in ram.history[hist_mark:]:
        if rec[0] == "collision":
            _, c, wsel, addr, mode, note = rec
            dut._log.warning("    COLLISION @cyc %d: side %s level %s read "
                             "and written in the same cycle", c, fmt(wsel),
                             fmt(addr))
            dut._log.warning("               %s -> %s", mode, note)

    if took:
        for rec in ram.history[hist_mark:]:
            if rec[0] == "write":
                _, c, wsel, waddr, wdata = rec
                dut._log.info("    model TOOK    side %s [%s] <= %s",
                              fmt(wsel), fmt(waddr),
                              fmt_level(wdata, LVL_FIELD_W))
    if lost:
        for rec in ram.history[hist_mark:]:
            if rec[0] == "write_dropped":
                _, c, wsel, waddr, wdata, why = rec
                dut._log.warning("    model REJECTED @cyc %d: side %s [%s] "
                                 "<= %s", c, fmt(wsel), fmt(waddr),
                                 fmt_level(wdata, LVL_FIELD_W))
                dut._log.warning("                   reason: %s", why)
    if level_writes and not took and not lost:
        dut._log.warning("    model SAW NOTHING although lvl_we was high on "
                         "the bus - the model driver and the design are not "
                         "sampling the same cycles")

    # ---- the two memories ------------------------------------------------
    await FallingEdge(dut.clk)
    await ReadOnly()
    tables = read_tables(rams)
    dump_orders(dut._log, tables, "    ORDER TABLES")
    dump_levels(dut._log, ram, "    LEVEL MEMORY (model)")
    dump_pls(dut._log, dut, "    PRICE STORAGE")
    await RisingEdge(dut.clk)


async def reset(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    dut.resetn.value = 0
    dut.s_tvalid.value = 0
    dut.s_op.value = OP_ADD
    dut.s_order_id.value = 0
    dut.s_book_id.value = 0
    dut.s_side.value = 0
    dut.s_qty.value = 0
    dut.s_price.value = 0
    dut.s_px_valid.value = 0
    dut.s_undisc.value = 0
    dut.s_implied.value = 0

    # Event bus consumer. price_storage does not drive s_tready, so the
    # testbench is what closes this handshake - see book_PLS_top.vhd.
    dut.m_tready.value = 1

    # Price window and top-of-book consumer.
    dut.base_price.value = 0
    dut.tob_tready.value = 1

    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.resetn.value = 1
    await RisingEdge(dut.clk)

    # NOTE: this resets the logic, not the memories. Neither ram_sdp nor
    # level_array resets its array - real block RAM has no reset on its
    # contents, and forcing one would stop the synthesiser inferring a memory
    # at all.


# ===========================================================================
# The run
# ===========================================================================
@cocotb.test()
async def test_single_level_traffic(dut):
    """
    32 adds, 3 deletes, 3 replaces and 4 executions, all on side 1 at price
    50000 with varying quantities. Both memories are printed after every
    message.
    """
    await reset(dut)

    rams = find_ram_handles(dut)

    # The level memory. Started after reset so the model's first sample is of
    # a design that is already out of reset - it has no reset of its own, by
    # design, because ram_sdp has none either.
    ram = LevelRam(write_mode=LVL_WRITE_MODE)
    cocotb.start_soon(drive_level_ram(dut, ram))

    dut._log.info("=" * 100)
    dut._log.info("order table : %d tables x %d slots = %d capacity, "
                  "slot %d bits", NUM_TABLES, DEPTH, CAPACITY, SLOT_W)
    dut._log.info("level table : %d sides x %d slots, %d addr bits, "
                  "slot %d bits  -- PYTHON MODEL, not RTL",
                  NUM_SIDES, LVL_DEPTH, LVL_ADDR_W, LEVEL_W)
    dut._log.info("              WRITE_MODE=%s. On a read-during-write "
                  "collision this mode gives", LVL_WRITE_MODE)
    dut._log.info("              %s on the read port.",
                  "the pre-write contents"
                  if LVL_WRITE_MODE == "READ_FIRST"
                  else "an UNDEFINED value, driven as X")
    dut._log.info("key         : %d bits, order_id(64) & side(1), "
                  "side at bit 0", KEY_W)
    dut._log.info("value       : qty(32) price(32) undisc(1) implied(1)")
    dut._log.info("level slot  : side(%d) qty(%d) price(%d)",
                  LVL_SIDE_W, LVL_QTY_W, LVL_PRICE_W)
    dut._log.info("")
    dut._log.info("stimulus    : side=%d, price=%d on EVERY message; "
                  "only quantity varies", SIDE, PRICE)
    dut._log.info("              %d adds, %d deletes, %d replaces, %d execs "
                  "(%d partial, %d full)",
                  N_INSERT, len(DELETE_IDX), len(REPLACE_IDX),
                  len(EXEC_PARTIAL_IDX) + len(EXEC_FULL_IDX),
                  len(EXEC_PARTIAL_IDX), len(EXEC_FULL_IDX))
    dut._log.info("              add quantities %d .. %d",
                  add_qty(0), add_qty(N_INSERT - 1))
    dut._log.info("")
    dut._log.info("cells       : keys as <low16 of order id><B|S>, "
                  "'.' is an empty slot")
    dut._log.info("              this harness checks nothing - read the dumps")
    dut._log.info("=" * 100)

    # What each order was last known to carry, so a delete or an exec banner
    # can say what it is acting on. Bookkeeping for the log only - nothing is
    # ever compared against it.
    qty_now = {}

    # ---- adds ------------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("ADDS")
    dut._log.info("=" * 100)

    for i, (oid, side, qty, price) in enumerate(INSERTS):
        qty_now[i] = qty
        await message(dut, rams, ram,
                      f"ADD {i + 1}/{N_INSERT}   order index {i}",
                      oid, side, OP_ADD, qty=qty, price=price)

    # ---- deletes ---------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("DELETES")
    dut._log.info("=" * 100)

    for i in DELETE_IDX:
        oid, side, _, price = INSERTS[i]
        await message(dut, rams, ram,
                      f"DELETE   order index {i}   "
                      f"(was resting {qty_now[i]})",
                      oid, side, OP_DELETE, qty=0, price=price)
        qty_now[i] = 0

    # ---- replaces --------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("REPLACES")
    dut._log.info("=" * 100)

    for i in REPLACE_IDX:
        oid, side, _, price = INSERTS[i]
        new_qty = replace_qty(i, qty_now[i])
        await message(dut, rams, ram,
                      f"REPLACE  order index {i}   qty {qty_now[i]} -> "
                      f"{new_qty}, price unchanged at {price}",
                      oid, side, OP_REPLACE, qty=new_qty, price=price)
        qty_now[i] = new_qty

    # ---- executions ------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("EXECUTIONS")
    dut._log.info("=" * 100)

    for i in EXEC_PARTIAL_IDX + EXEC_FULL_IDX:
        oid, side, _, price = INSERTS[i]
        full = i in EXEC_FULL_IDX
        take = exec_qty(i, qty_now[i], full)
        await message(dut, rams, ram,
                      f"EXEC     order index {i}   take {take} of "
                      f"{qty_now[i]}"
                      f"{'   [fills the order]' if full else ''}",
                      oid, side, OP_EXEC, qty=take, price=price)
        qty_now[i] = max(0, qty_now[i] - take)

    # ---- final state -----------------------------------------------------
    await FallingEdge(dut.clk)
    await ReadOnly()
    tables = read_tables(rams)
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("FINAL STATE")
    dut._log.info("=" * 100)
    dump_orders(dut._log, tables, "    ORDER TABLES")
    dump_levels(dut._log, ram, "    LEVEL MEMORY (model)")
    dump_pls(dut._log, dut, "    PRICE STORAGE")
    await RisingEdge(dut.clk)

    dut._log.info("")
    dut._log.info("  per-table load:")
    for t in range(NUM_TABLES):
        n = sum(1 for s in tables[t]
                if s is not None and (s >> VALID_BIT) & 1)
        dut._log.info("    T%d  %2d/%2d  %s", t, n, DEPTH, "#" * n)
    dut._log.info("=" * 100)
