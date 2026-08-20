"""
cocotb testbench for order_book - insertion walkthrough.

Drives five keys in through the AXI-Stream slave handshake and prints the
state of all four tables every cycle, so the eviction chain can be followed
step by step.

No assertions. This is a visibility harness, not a regression test.

TOPLEVEL IS order_book_top

order_book exposes its memory ports rather than owning the memory, so it
cannot run standalone. order_book_top wires it to a real ram_array. The
table contents printed below are read straight out of that RAM through the
design hierarchy - no Python model of the memory, so read latency and
read-during-write behaviour are whatever the RTL actually does.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly

CLK_PERIOD_NS = 6.4          # 156.25 MHz

# Geometry - must match ram_pkg
NUM_TABLES = 4
ADDR_W = 3
DEPTH = 2 ** ADDR_W          # 8 slots per table
KEY_W = 16
SLOT_W = 1 + KEY_W           # 17
VALID_BIT = SLOT_W - 1       # 16
KEY_MASK = (1 << KEY_W) - 1

# ---------------------------------------------------------------------------
# Stimulus
#
# Chosen so the eviction path is actually exercised. Every key below hashes to
# T0[0], so table 0 slot 0 is contested from the second key onwards and chains
# lengthen as the tables fill.
#
# Expected behaviour under fixed-order insertion (insert at table 0, victim
# moves to the next table, wrapping after table 3):
#
#   key     hops  path
#   ----    ----  ----------------------------------------------------------
#   F4BF      1   T0[0]                             empty, no eviction
#   2C01      2   T0[0] -> T1[3]                    first eviction
#   6922      2   T0[0] -> T1[4]
#   B5E1      2   T0[0] -> T1[1]
#   F530      2   T0[0] -> T1[6]
#   794B      3   T0[0] -> T1[4] -> T2[1]           two evictions in a row
#   17A0      3   T0[0] -> T1[4] -> T2[7]
#   19DA      3   T0[0] -> T1[6] -> T2[2]
#   D16C      3   T0[0] -> T1[1] -> T2[4]
#   B509      2   T0[0] -> T1[5]
#   59F2      2   T0[0] -> T1[2]
#   CF51      3   T0[0] -> T1[3] -> T2[0]
#   881B      4   T0[0] -> T1[6] -> T2[7] -> T3[5]  reaches the last table
#   01EE      8   T0[0] -> T1[5] -> T2[1] -> T3[5]
#                    -> T0[0] -> T1[1] -> T2[1] -> T3[1]
#                                                   WRAPS back through table 0
#
# The final key is the interesting one: it walks off the end of table 3 and
# re-enters table 0, where it displaces itself - the closest thing to a cycle
# this key set produces. Expected occupancy at the end is 14 of 32 slots.
# ---------------------------------------------------------------------------
KEYS = [
    0xF4BF, 0x2C01, 0x6922, 0xB5E1, 0xF530, 0x794B, 0x17A0,
    0x19DA, 0xD16C, 0xB509, 0x59F2, 0xCF51, 0x881B, 0x01EE,
]

# key -> expected hop count, for the log only. Nothing here asserts.
EXPECTED_HOPS = {
    0xF4BF: 1, 0x2C01: 2, 0x6922: 2, 0xB5E1: 2, 0xF530: 2, 0x794B: 3,
    0x17A0: 3, 0x19DA: 3, 0xD16C: 3, 0xB509: 2, 0x59F2: 2, 0xCF51: 3,
    0x881B: 4, 0x01EE: 8,
}

# Safety net - the RTL has no hop bound, so a cycling chain would otherwise
# run forever. The longest expected chain is 8 hops.
MAX_CYCLES = 80


# ---------------------------------------------------------------------------
# Hash mirror
#
# Mirrors C_HASH_MASK in hash_pkg, used only to annotate the printout with
# where each key could land. The DUT computes its own. If the masks in
# hash_pkg change, these must change with them.
# ---------------------------------------------------------------------------
HASH_MASK = [
    [0xACD1, 0x6962, 0xD38C],   # table 0, output bits 0/1/2
    [0xCB59, 0xB5A2, 0x5ADC],   # table 1
    [0xE539, 0x9CCA, 0x376C],   # table 2
    [0xDCA9, 0xA69A, 0x6E74],   # table 3
]


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
    """Signals read 'U' before reset; treat unresolvable as None."""
    try:
        return int(handle.value)
    except (ValueError, TypeError):
        return None


def fmt(v):
    return "?" if v is None else str(v)


# ---------------------------------------------------------------------------
# Reaching the RAM contents through the hierarchy
#
# The memory is a signal named `ram` inside ram_sdp, instantiated as `u_ram`
# inside the `g_tables` generate of ram_array, which is `u_ram_arr` in
# order_book_top. Simulators disagree about how generate loops are named and
# indexed, so several spellings are tried and whichever resolves is used.
# ---------------------------------------------------------------------------
def find_ram_handles(dut):
    """Return a list of handles, one per table, each the `ram` signal array."""
    arr = dut.u_ram_arr
    attempts = []
    handles = []

    for t in range(NUM_TABLES):
        h = None

        # Form 1: generate block indexed like a Python sequence
        try:
            h = arr.g_tables[t].u_ram.ram
        except Exception as e:            # noqa: BLE001
            attempts.append(f"u_ram_arr.g_tables[{t}].u_ram.ram -> {e}")

        # Form 2: flattened name, e.g. g_tables(0)
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
    out = []
    for t in range(NUM_TABLES):
        row = []
        for a in range(DEPTH):
            row.append(safe_int(rams[t][a]))
        out.append(row)
    return out


def dump(log, tables, label=""):
    if label:
        log.info(label)
    for t in range(NUM_TABLES):
        cells = []
        for a in range(DEPTH):
            slot = tables[t][a]
            if slot is None:
                cells.append(" ?? ")
            elif (slot >> VALID_BIT) & 1:
                cells.append(f"{slot & KEY_MASK:04X}")
            else:
                cells.append(" .. ")
        log.info("    T%d | %s", t, " ".join(cells))


def occupancy(tables):
    n = 0
    for t in range(NUM_TABLES):
        for a in range(DEPTH):
            s = tables[t][a]
            if s is not None and (s >> VALID_BIT) & 1:
                n += 1
    return n


def find_key(tables, key):
    for t in range(NUM_TABLES):
        for a in range(DEPTH):
            s = tables[t][a]
            if s is not None and (s >> VALID_BIT) & 1 and (s & KEY_MASK) == key:
                return (t, a)
    return None


# ---------------------------------------------------------------------------
# Bus tracing
# ---------------------------------------------------------------------------
def trace(dut, cycle):
    """
    Print the bus state for the current cycle.

    Call from ReadOnly after a FallingEdge, so the values shown are the ones
    in effect during this cycle - what the RAM will act on at the next rising
    edge. Sampling after RisingEdge instead would show the registers as
    already updated for the following cycle.
    """
    raddr = [safe_int(dut.raddr[t]) for t in range(NUM_TABLES)]
    rdata = [safe_int(dut.rdata[t]) for t in range(NUM_TABLES)]

    we = safe_int(dut.we)
    wsel = safe_int(dut.wsel)
    waddr = safe_int(dut.waddr)
    wdata = safe_int(dut.wdata)
    busy = safe_int(dut.busy)
    tvalid = safe_int(dut.s_tvalid)
    tready = safe_int(dut.s_tready)

    rd = []
    for v in rdata:
        if v is None:
            rd.append("  ? ")
        elif (v >> VALID_BIT) & 1:
            rd.append(f"{v & KEY_MASK:04X}")
        else:
            rd.append(" .. ")

    wr = "-"
    observed = None
    if we == 1 and wdata is not None and wsel is not None and waddr is not None:
        vbit = (wdata >> VALID_BIT) & 1
        wr = f"T{wsel}[{waddr}] <= {'V' if vbit else 'x'}:{wdata & KEY_MASK:04X}"
        observed = (wsel, waddr, wdata & KEY_MASK)

    dut._log.info(
        "cyc %2d | tvalid=%s tready=%s busy=%s | raddr=%s rdata=[%s] | write %s",
        cycle, fmt(tvalid), fmt(tready), fmt(busy),
        raddr, " ".join(rd), wr,
    )
    return observed


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_insert_eviction_chains(dut):
    """
    Insert the key sequence one at a time, printing every cycle.

    Each key is offered on the slave interface with a proper handshake:
    s_tvalid is raised and held until a rising edge where s_tready is also
    high, then dropped. The insert chain that follows is watched until busy
    falls.
    """
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    # ---- reset -----------------------------------------------------------
    dut.resetn.value = 0
    dut.s_tvalid.value = 0
    dut.key.value = 0

    # Command bus is unused by the insert path but must not sit at 'U'.
    dut.s_op.value = 0                 # OP_ADD
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

    dut._log.info("=" * 78)
    dut._log.info("geometry: %d tables x %d slots, %d-bit key, %d-bit slot",
                  NUM_TABLES, DEPTH, KEY_W, SLOT_W)
    dut._log.info("RAM read through hierarchy: u_ram_arr.g_tables[t].u_ram.ram")
    dut._log.info("=" * 78)

    # Block RAM contents are not guaranteed cleared on a real part. ram_sdp
    # initialises its array for simulation, so this should show all empty -
    # worth seeing, since the engine has no init sequence yet.
    await FallingEdge(dut.clk)
    await ReadOnly()
    dump(dut._log, read_tables(rams), "tables at start of traffic")
    await RisingEdge(dut.clk)

    # ---- drive each key --------------------------------------------------
    for idx, key in enumerate(KEYS):

        dut._log.info("")
        dut._log.info("-" * 78)
        dut._log.info("KEY %d of %d: %04X   candidate slots: %s   expect %s hop(s)",
                      idx + 1, len(KEYS), key,
                      ", ".join(f"T{t}[{a}]"
                                for t, a in enumerate(hash_all(key))),
                      EXPECTED_HOPS.get(key, "?"))
        dut._log.info("-" * 78)

        dut.key.value = key
        dut.s_tvalid.value = 1

        # Hold until a rising edge where s_tready is also high.
        cycle = 0
        while True:
            await FallingEdge(dut.clk)
            await ReadOnly()
            accepted = safe_int(dut.s_tready) == 1
            trace(dut, cycle)
            await RisingEdge(dut.clk)
            cycle += 1
            if accepted:
                break

        dut.s_tvalid.value = 0
        dut._log.info("    ... handshake complete, key accepted")

        # Follow the chain until busy falls, recording every write.
        writes = []
        while cycle < MAX_CYCLES:
            await FallingEdge(dut.clk)
            await ReadOnly()
            w = trace(dut, cycle)
            if w is not None:
                writes.append(w)
            busy = safe_int(dut.busy)
            await RisingEdge(dut.clk)
            cycle += 1
            if busy == 0:
                break

        if cycle >= MAX_CYCLES:
            dut._log.warning("    chain did not terminate within %d cycles",
                             MAX_CYCLES)

        # Let the final write commit, then read the tables.
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        await ReadOnly()
        tables = read_tables(rams)
        await RisingEdge(dut.clk)

        dump(dut._log, tables,
             f"tables after inserting {key:04X}  "
             f"(occupancy {occupancy(tables)}/{NUM_TABLES * DEPTH})")

        # Observed eviction path, from the writes seen on the bus.
        if writes:
            path = " -> ".join(f"T{t}[{a}]" for t, a, _ in writes)
            dut._log.info("    observed path : %s", path)
            dut._log.info("    observed hops : %d   (expected %s)",
                          len(writes), EXPECTED_HOPS.get(key, "?"))
            if len(writes) > NUM_TABLES:
                dut._log.info("    chain WRAPPED past table %d back to table 0",
                              NUM_TABLES - 1)
        else:
            dut._log.info("    no write observed")

        where = find_key(tables, key)
        if where:
            dut._log.info("    %04X rests at T%d[%d]", key, where[0], where[1])
        else:
            dut._log.info("    %04X is NOT in any table", key)

    # ---- summary ---------------------------------------------------------
    await FallingEdge(dut.clk)
    await ReadOnly()
    tables = read_tables(rams)

    dut._log.info("")
    dut._log.info("=" * 78)
    dump(dut._log, tables, "FINAL STATE")
    dut._log.info("")
    for key in KEYS:
        where = find_key(tables, key)
        if where:
            dut._log.info("  %04X  ->  T%d[%d]", key, where[0], where[1])
        else:
            dut._log.info("  %04X  ->  missing", key)
    dut._log.info("  occupancy %d of %d slots  (expected 14)",
                  occupancy(tables), NUM_TABLES * DEPTH)
    dut._log.info("=" * 78)
