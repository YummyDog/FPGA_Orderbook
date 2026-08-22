"""
cocotb testbench for order_book - insertion walkthrough.

Drives keys in through the AXI-Stream slave handshake with key_op = INSERT,
printing the state of all four tables every cycle so the eviction chain can be
followed step by step. Three lookups follow, one against each of three
different tables, then two deletions and three in-place modifications.

No assertions. This is a visibility harness, not a regression test.

TOPLEVEL IS order_book_top

order_book exposes its memory ports rather than owning the memory, so it
cannot run standalone. order_book_top wires it to a real ram_array. The table
contents printed below are read straight out of that RAM through the design
hierarchy - no Python model of the memory, so read latency and
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

# key_op encoding
OP_INSERT = 0b00
OP_LOOKUP = 0b01
OP_DELETE = 0b10
OP_MODIFY = 0b11

# ---------------------------------------------------------------------------
# Stimulus
#
# Unlike the earlier set, these keys do NOT all collide at T0[0] - their
# table-0 addresses span six of the eight slots. That makes the run look like
# ordinary traffic: most inserts land in a free slot immediately, and chains
# appear only where the tables have genuinely filled.
#
# Expected behaviour under fixed-order insertion (start at table 0, victim
# moves to the next table, wrapping after table 3):
#
#   key    h0 h1 h2 h3  hops  path
#   ----   -- -- -- --  ----  ------------------------------------------
#   F4BF    0  3  0  2    1   T0[0]
#   DCF5    5  6  4  4    1   T0[5]
#   F2A5    2  6  7  4    1   T0[2]
#   D95C    0  7  7  7    2   T0[0] -> T1[3]
#   0E7B    1  6  7  3    1   T0[1]
#   1773    4  3  1  4    1   T0[4]
#   15BB    2  0  6  6    2   T0[2] -> T1[6]
#   5C6F    2  1  1  3    2   T0[2] -> T1[0]
#   D5E4    0  4  3  6    2   T0[0] -> T1[7]
#   2B4A    7  3  5  0    1   T0[7]
#   BC69    4  3  0  5    3   T0[4] -> T1[3] -> T2[0]
#   CF19    7  6  1  6    3   T0[7] -> T1[3] -> T2[1]
#   AB74    3  4  3  5    1   T0[3]
#   DA95    1  6  4  4    3   T0[1] -> T1[6] -> T2[7]
#   4EE3    7  5  2  0    4   T0[7] -> T1[6] -> T2[7] -> T3[4]
#   4068    3  7  5  7    2   T0[3] -> T1[4]
#
# Seven clean inserts, four single evictions, three double, one that reaches
# table 3. Final occupancy 16 of 32 slots - every key placed, none lost.
#
# No chain wraps past table 3 in this set. That case is exercised by the
# all-colliding key set, kept in git history.
# ---------------------------------------------------------------------------
KEYS = [
    0xF4BF, 0xDCF5, 0xF2A5, 0xD95C, 0x0E7B, 0x1773, 0x15BB, 0x5C6F,
    0xD5E4, 0x2B4A, 0xBC69, 0xCF19, 0xAB74, 0xDA95, 0x4EE3, 0x4068,
]

# key -> expected hop count, for the log only. Nothing here asserts.
EXPECTED_HOPS = {
    0xF4BF: 1, 0xDCF5: 1, 0xF2A5: 1, 0xD95C: 2, 0x0E7B: 1, 0x1773: 1,
    0x15BB: 2, 0x5C6F: 2, 0xD5E4: 2, 0x2B4A: 1, 0xBC69: 3, 0xCF19: 3,
    0xAB74: 1, 0xDA95: 3, 0x4EE3: 4, 0x4068: 2,
}

EXPECTED_OCCUPANCY = 16

# ---------------------------------------------------------------------------
# Lookups, run after all inserts.
#
# Chosen to land in three different tables, so the parallel compare is
# exercised rather than just table 0:
#
#   5C6F  ->  T0[2]
#   F4BF  ->  T2[0]
#   F2A5  ->  T3[4]
#
# All four tables are read at hash(key, i) whenever the engine is idle, so the
# addresses are driven during the handshake cycle and rdata is valid on the
# following cycle - which is the cycle looking_r is high and the compare runs.
#
# lookup_found and lookup_return are both outputs. Note lookup_found is sticky
# in the current RTL: nothing clears it between lookups, so a genuine miss
# after a hit will still read high. The check below requires found = 1 AND the
# returned key to match, which catches that.
# ---------------------------------------------------------------------------
LOOKUP_KEYS = [0x5C6F, 0xF4BF, 0xF2A5]

# ---------------------------------------------------------------------------
# Deletions, run after the lookups.
#
#   4068  ->  T0[3]
#   AB74  ->  T1[4]
#
# AB74 is the key 4068 displaced on the way in, so deleting both also confirms
# the eviction landed where the insert trace claimed it did.
#
# key_op must stay at 10 through the compare cycle, not just the handshake -
# the RTL samples it while looking_r is high, one cycle after the transfer.
# ---------------------------------------------------------------------------
DELETE_KEYS = [0x4068, 0xAB74]

# ---------------------------------------------------------------------------
# Modifications, run after the deletions.
#
#   4EE3 -> BEEF   at T0[7]
#   2B4A -> 1234   at T1[3]
#   F2A5 -> 4321   at T3[4]
#
# The slot is found by probing for the OLD key, then rewritten with the value
# on key_modify. The address does not change - modify is delete with different
# write data, not delete-then-insert.
#
# Note what that means while key and value are the same field: the new value
# ends up stored at hash(old_key), so a later lookup of BEEF will NOT find it.
# That is expected here and goes away once keys and values live in separate
# tables, where the key stays put and only the value is rewritten.
#
# key_op must stay at 11 through the compare cycle, and key_modify must be
# stable alongside it.
# ---------------------------------------------------------------------------
MODIFY_KEYS = [
    (0x4EE3, 0xBEEF),
    (0x2B4A, 0x1234),
    (0xF2A5, 0x4321),
]

EXPECTED_LOCATION = {
    0x5C6F: (0, 2),
    0xF4BF: (2, 0),
    0xF2A5: (3, 4),
    0x4068: (0, 3),
    0xAB74: (1, 4),
    0x4EE3: (0, 7),
    0x2B4A: (1, 3),
}

# Safety net - the RTL has no hop bound, so a cycling chain would otherwise
# run forever. The longest expected chain here is 4 hops.
MAX_CYCLES = 60


# ---------------------------------------------------------------------------
# Hash mirror
#
# Mirrors C_HASH_MASK in hash_pkg, used only to annotate the printout. The DUT
# computes its own. If the masks in hash_pkg change, these must change too.
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
    return sum(1
               for t in range(NUM_TABLES)
               for s in tables[t]
               if s is not None and (s >> VALID_BIT) & 1)


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
    Print the bus state for the current cycle, and return the write observed.

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
    kop = safe_int(dut.key_op)
    kmod = safe_int(dut.key_modify)
    lfound = safe_int(dut.lookup_found)
    lret = safe_int(dut.lookup_return)

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
        "cyc %2d | tvalid=%s tready=%s op=%s mod=%s busy=%s | raddr=%s "
        "rdata=[%s] | write %s | found=%s ret=%s",
        cycle, fmt(tvalid), fmt(tready), fmt(kop),
        "----" if kmod is None else f"{kmod:04X}", fmt(busy),
        raddr, " ".join(rd), wr,
        fmt(lfound),
        "----" if lret is None else f"{lret & KEY_MASK:04X}",
    )
    return observed


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_insert_lookup_delete_modify(dut):
    """
    Insert the key sequence one at a time with key_op = INSERT, then run
    three lookups with key_op = LOOKUP, two deletions with key_op = DELETE,
    then three modifications with key_op = MODIFY. Every cycle is printed.

    Each key is offered on the slave interface with a proper handshake:
    s_tvalid is raised and held until a rising edge where s_tready is also
    high, then dropped. The chain that follows is watched until busy falls.
    """
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    # ---- reset -----------------------------------------------------------
    dut.resetn.value = 0
    dut.s_tvalid.value = 0
    dut.key.value = 0
    dut.key_op.value = OP_INSERT
    dut.key_modify.value = 0

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

    dut._log.info("=" * 82)
    dut._log.info("geometry: %d tables x %d slots, %d-bit key, %d-bit slot",
                  NUM_TABLES, DEPTH, KEY_W, SLOT_W)
    dut._log.info("key_op: 00 = INSERT, 01 = LOOKUP, 10 = DELETE  "
                  "(this test drives INSERT only)")
    dut._log.info("RAM read through hierarchy: u_ram_arr.g_tables[t].u_ram.ram")
    dut._log.info("=" * 82)

    await FallingEdge(dut.clk)
    await ReadOnly()
    dump(dut._log, read_tables(rams), "tables at start of traffic")
    await RisingEdge(dut.clk)

    mismatches = []

    # ---- drive each key --------------------------------------------------
    for idx, key in enumerate(KEYS):

        dut._log.info("")
        dut._log.info("-" * 82)
        dut._log.info("KEY %2d of %d: %04X   candidates: %s   expect %s hop(s)",
                      idx + 1, len(KEYS), key,
                      ", ".join(f"T{t}[{a}]"
                                for t, a in enumerate(hash_all(key))),
                      EXPECTED_HOPS.get(key, "?"))
        dut._log.info("-" * 82)

        dut.key.value = key
        dut.key_op.value = OP_INSERT
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

        exp = EXPECTED_HOPS.get(key)
        if writes:
            path = " -> ".join(f"T{t}[{a}]" for t, a, _ in writes)
            dut._log.info("    observed path : %s", path)
            dut._log.info("    observed hops : %d   (expected %s)",
                          len(writes), exp)
            if exp is not None and len(writes) != exp:
                mismatches.append((key, len(writes), exp))
            if len(writes) > NUM_TABLES:
                dut._log.info("    chain WRAPPED past table %d back to table 0",
                              NUM_TABLES - 1)
        else:
            dut._log.info("    no write observed")
            mismatches.append((key, 0, exp))

        where = find_key(tables, key)
        if where:
            dut._log.info("    %04X rests at T%d[%d]", key, where[0], where[1])
        else:
            dut._log.info("    %04X is NOT in any table", key)

    # ---- lookups ---------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 82)
    dut._log.info("LOOKUPS  (key_op = 01)")
    dut._log.info("=" * 82)

    lookup_results = []

    for key in LOOKUP_KEYS:
        exp_t, exp_a = EXPECTED_LOCATION[key]

        dut._log.info("")
        dut._log.info("-" * 82)
        dut._log.info("LOOKUP %04X   candidates: %s   expect a hit at T%d[%d]",
                      key,
                      ", ".join(f"T{t}[{a}]"
                                for t, a in enumerate(hash_all(key))),
                      exp_t, exp_a)
        dut._log.info("-" * 82)

        dut.key.value = key
        dut.key_op.value = OP_LOOKUP
        dut.s_tvalid.value = 1

        # Hold until a rising edge where s_tready is also high.
        cycle = 0
        while cycle < MAX_CYCLES:
            await FallingEdge(dut.clk)
            await ReadOnly()
            accepted = safe_int(dut.s_tready) == 1
            trace(dut, cycle)
            await RisingEdge(dut.clk)
            cycle += 1
            if accepted:
                break

        dut.s_tvalid.value = 0
        # key is deliberately held stable: the read addresses are combinational
        # off it, and dropping it early would change what the RAM returns.

        # The compare runs on the cycle after the handshake, when rdata for
        # the addresses driven during the handshake is valid. Sample a short
        # window rather than one fixed cycle, so the check does not depend on
        # exactly how many cycles the RTL takes to present the result.
        samples = []
        for _ in range(4):
            await FallingEdge(dut.clk)
            await ReadOnly()
            trace(dut, cycle)
            raw = safe_int(dut.lookup_return)
            samples.append((safe_int(dut.lookup_found), raw))
            await RisingEdge(dut.clk)
            cycle += 1

        dut.key_op.value = OP_INSERT
        await RisingEdge(dut.clk)

        # lookup_return may be declared as t_key (16 bits) or as a full t_slot
        # (17 bits, valid bit included). Mask so the comparison works either
        # way - an unmasked 17-bit value reads as 0x1xxxx and never matches.
        def key_of(raw):
            return None if raw is None else raw & KEY_MASK

        # lookup_found is sticky in the current RTL - nothing clears it between
        # lookups - so the returned key is checked too. A stale hit from a
        # previous lookup shows as a mismatch rather than passing.
        hit = False
        found, got = samples[-1][0], key_of(samples[-1][1])
        for f, raw in samples:
            if f == 1 and key_of(raw) == key:
                hit, found, got = True, f, key_of(raw)
                break

        if not hit:
            dut._log.info("    samples (found, return): %s",
                          ", ".join(
                              f"({fmt(f)}, "
                              f"{'----' if key_of(r) is None else f'{key_of(r):04X}'})"
                              for f, r in samples))

        if hit:
            dut._log.info("    HIT   found=1  lookup_return = %04X  "
                          "(resting at T%d[%d])", got, exp_t, exp_a)
        else:
            dut._log.info("    MISS  found=%s  lookup_return = %s  "
                          "(expected %04X at T%d[%d])",
                          fmt(found), "----" if got is None else f"{got:04X}",
                          key, exp_t, exp_a)
        lookup_results.append((key, hit, found, got))

    # ---- deletions -------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 82)
    dut._log.info("DELETIONS  (key_op = 10)")
    dut._log.info("=" * 82)

    delete_results = []

    for key in DELETE_KEYS:
        exp_t, exp_a = EXPECTED_LOCATION[key]

        # Confirm it is actually there before asking for it to be removed,
        # so a failed delete cannot be confused with a key that was never
        # placed.
        await FallingEdge(dut.clk)
        await ReadOnly()
        before = read_tables(rams)
        await RisingEdge(dut.clk)

        present = find_key(before, key)

        dut._log.info("")
        dut._log.info("-" * 82)
        dut._log.info("DELETE %04X   candidates: %s   expect it at T%d[%d]",
                      key,
                      ", ".join(f"T{t}[{a}]"
                                for t, a in enumerate(hash_all(key))),
                      exp_t, exp_a)
        if present:
            dut._log.info("    before: resting at T%d[%d]", present[0], present[1])
        else:
            dut._log.info("    before: NOT PRESENT - nothing to delete")
        dut._log.info("-" * 82)

        dut.key.value = key
        dut.key_op.value = OP_DELETE
        dut.s_tvalid.value = 1

        cycle = 0
        while cycle < MAX_CYCLES:
            await FallingEdge(dut.clk)
            await ReadOnly()
            accepted = safe_int(dut.s_tready) == 1
            trace(dut, cycle)
            await RisingEdge(dut.clk)
            cycle += 1
            if accepted:
                break

        dut.s_tvalid.value = 0
        # key and key_op are both held: the RTL samples key_op on the compare
        # cycle, and the read addresses are combinational off key.

        for _ in range(4):
            await FallingEdge(dut.clk)
            await ReadOnly()
            trace(dut, cycle)
            await RisingEdge(dut.clk)
            cycle += 1

        dut.key_op.value = OP_INSERT
        await RisingEdge(dut.clk)

        await FallingEdge(dut.clk)
        await ReadOnly()
        after = read_tables(rams)
        await RisingEdge(dut.clk)

        dump(dut._log, after,
             f"tables after deleting {key:04X}  "
             f"(occupancy {occupancy(after)}/{NUM_TABLES * DEPTH})")

        still_there = find_key(after, key)
        if still_there is None:
            dut._log.info("    DELETED  %04X no longer in any table", key)
            gone = True
        else:
            dut._log.info("    NOT DELETED  %04X still at T%d[%d]",
                          key, still_there[0], still_there[1])
            gone = False

        # Nothing else should have moved.
        collateral = []
        for t in range(NUM_TABLES):
            for a in range(DEPTH):
                if before[t][a] != after[t][a]:
                    if (t, a) != (exp_t, exp_a):
                        collateral.append((t, a, before[t][a], after[t][a]))
        if collateral:
            dut._log.warning("    %d unexpected slot change(s):", len(collateral))
            for t, a, b, aft in collateral:
                dut._log.warning("      T%d[%d]  %s -> %s", t, a,
                                 "----" if b is None else f"{b:05X}",
                                 "----" if aft is None else f"{aft:05X}")

        delete_results.append((key, gone, len(collateral)))

    # ---- modifications ---------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 82)
    dut._log.info("MODIFICATIONS  (key_op = 11)")
    dut._log.info("=" * 82)

    modify_results = []

    for old_key, new_key in MODIFY_KEYS:
        exp_t, exp_a = EXPECTED_LOCATION[old_key]

        await FallingEdge(dut.clk)
        await ReadOnly()
        before = read_tables(rams)
        await RisingEdge(dut.clk)

        present = find_key(before, old_key)

        dut._log.info("")
        dut._log.info("-" * 82)
        dut._log.info("MODIFY %04X -> %04X   candidates: %s   expect it at T%d[%d]",
                      old_key, new_key,
                      ", ".join(f"T{t}[{a}]"
                                for t, a in enumerate(hash_all(old_key))),
                      exp_t, exp_a)
        if present:
            dut._log.info("    before: %04X at T%d[%d]",
                          old_key, present[0], present[1])
        else:
            dut._log.info("    before: %04X NOT PRESENT - nothing to modify",
                          old_key)
        dut._log.info("-" * 82)

        dut.key.value = old_key
        dut.key_modify.value = new_key
        dut.key_op.value = OP_MODIFY
        dut.s_tvalid.value = 1

        cycle = 0
        while cycle < MAX_CYCLES:
            await FallingEdge(dut.clk)
            await ReadOnly()
            accepted = safe_int(dut.s_tready) == 1
            trace(dut, cycle)
            await RisingEdge(dut.clk)
            cycle += 1
            if accepted:
                break

        dut.s_tvalid.value = 0
        # key, key_modify and key_op all held through the compare cycle.

        for _ in range(4):
            await FallingEdge(dut.clk)
            await ReadOnly()
            trace(dut, cycle)
            await RisingEdge(dut.clk)
            cycle += 1

        dut.key_op.value = OP_INSERT
        await RisingEdge(dut.clk)

        await FallingEdge(dut.clk)
        await ReadOnly()
        after = read_tables(rams)
        await RisingEdge(dut.clk)

        dump(dut._log, after,
             f"tables after modifying {old_key:04X} -> {new_key:04X}  "
             f"(occupancy {occupancy(after)}/{NUM_TABLES * DEPTH})")

        # The slot must now hold the new value, at the same address, still
        # valid. Occupancy must not change - this is a rewrite, not a delete.
        slot = after[exp_t][exp_a]
        ok_valid = slot is not None and (slot >> VALID_BIT) & 1 == 1
        ok_value = slot is not None and (slot & KEY_MASK) == new_key
        old_gone = find_key(after, old_key) is None

        if ok_valid and ok_value:
            dut._log.info("    MODIFIED  T%d[%d] now holds %04X (valid)",
                          exp_t, exp_a, new_key)
        else:
            dut._log.info("    NOT MODIFIED  T%d[%d] holds %s",
                          exp_t, exp_a,
                          "----" if slot is None else f"{slot:05X}")
        if not old_gone:
            where = find_key(after, old_key)
            dut._log.info("    old value %04X still present at T%d[%d]",
                          old_key, where[0], where[1])

        collateral = []
        for t in range(NUM_TABLES):
            for a in range(DEPTH):
                if before[t][a] != after[t][a] and (t, a) != (exp_t, exp_a):
                    collateral.append((t, a, before[t][a], after[t][a]))
        if collateral:
            dut._log.warning("    %d unexpected slot change(s):", len(collateral))
            for t, a, b, aft in collateral:
                dut._log.warning("      T%d[%d]  %s -> %s", t, a,
                                 "----" if b is None else f"{b:05X}",
                                 "----" if aft is None else f"{aft:05X}")

        modify_results.append((old_key, new_key,
                               ok_valid and ok_value, len(collateral)))

    # ---- summary ---------------------------------------------------------
    await FallingEdge(dut.clk)
    await ReadOnly()
    tables = read_tables(rams)

    dut._log.info("")
    dut._log.info("=" * 82)
    dump(dut._log, tables, "FINAL STATE")
    dut._log.info("")

    missing = []
    for key in KEYS:
        where = find_key(tables, key)
        if where:
            dut._log.info("  %04X  ->  T%d[%d]", key, where[0], where[1])
        else:
            dut._log.info("  %04X  ->  MISSING", key)
            missing.append(key)

    dut._log.info("")
    dut._log.info("  occupancy %d of %d slots  (expected %d after %d deletes)",
                  occupancy(tables), NUM_TABLES * DEPTH,
                  EXPECTED_OCCUPANCY - len(DELETE_KEYS), len(DELETE_KEYS))

    dut._log.info("")
    dut._log.info("  lookups:")
    bad_lookups = []
    for key, hit, found, got in lookup_results:
        t, a = EXPECTED_LOCATION[key]
        if hit:
            dut._log.info("    %04X  HIT   (rests at T%d[%d])", key, t, a)
        else:
            dut._log.info("    %04X  MISS  found=%s returned %s, "
                          "expected T%d[%d]",
                          key, fmt(found),
                          "----" if got is None else f"{got:04X}", t, a)
            bad_lookups.append(key)

    dut._log.info("")
    dut._log.info("  deletions:")
    bad_deletes = []
    for key, gone, coll in delete_results:
        t, a = EXPECTED_LOCATION[key]
        if gone and coll == 0:
            dut._log.info("    %04X  DELETED  (was at T%d[%d])", key, t, a)
        elif gone:
            dut._log.info("    %04X  DELETED  but %d other slot(s) changed",
                          key, coll)
            bad_deletes.append(key)
        else:
            dut._log.info("    %04X  NOT DELETED  (expected T%d[%d])", key, t, a)
            bad_deletes.append(key)

    dut._log.info("")
    dut._log.info("  modifications:")
    bad_modifies = []
    for old_key, new_key, ok, coll in modify_results:
        t, a = EXPECTED_LOCATION[old_key]
        if ok and coll == 0:
            dut._log.info("    %04X -> %04X  OK  (T%d[%d])",
                          old_key, new_key, t, a)
        elif ok:
            dut._log.info("    %04X -> %04X  written, but %d other slot(s) changed",
                          old_key, new_key, coll)
            bad_modifies.append(old_key)
        else:
            dut._log.info("    %04X -> %04X  FAILED  (expected T%d[%d])",
                          old_key, new_key, t, a)
            bad_modifies.append(old_key)

    if missing:
        dut._log.warning("  %d key(s) lost: %s",
                         len(missing), ", ".join(f"{k:04X}" for k in missing))
    if bad_lookups:
        dut._log.warning("  %d lookup(s) failed: %s", len(bad_lookups),
                         ", ".join(f"{k:04X}" for k in bad_lookups))
    if bad_deletes:
        dut._log.warning("  %d deletion(s) failed: %s", len(bad_deletes),
                         ", ".join(f"{k:04X}" for k in bad_deletes))
    if bad_modifies:
        dut._log.warning("  %d modification(s) failed: %s", len(bad_modifies),
                         ", ".join(f"{k:04X}" for k in bad_modifies))
    if mismatches:
        dut._log.warning("  %d hop-count mismatch(es):", len(mismatches))
        for k, got, exp in mismatches:
            dut._log.warning("    %04X  got %s hops, expected %s", k, got, exp)
    dut._log.info("")
    dut._log.info("  final occupancy %d of %d  (16 inserted, %d deleted, "
                  "%d modified in place)",
                  occupancy(tables), NUM_TABLES * DEPTH,
                  len(DELETE_KEYS), len(MODIFY_KEYS))

    if (not missing and not mismatches and not bad_lookups
            and not bad_deletes and not bad_modifies):
        dut._log.info("  all keys placed, all chain lengths as expected, "
                      "all lookups hit, all deletions and modifications clean")

    dut._log.info("=" * 82)
