"""
example_packets_sim - the live hardware test, replayed in simulation.

The packets are the ones in order_book_test_packets.txt, the file imported
into the Order Book Test Interface and fired at the FPGA. The frames built
here are byte-for-byte the frames the interface put on the wire: the same
MACs, IPs, ports, IP ids, MoldUDP64 session and sequence numbers, ITCH
timestamps, order ids, positions and match ids, and a real UDP checksum. So
a live run's events.csv and capture.pcap can be read side by side with this
log.

    Ethernet -> IPv4 -> UDP -> MoldUDP64 -> ITCH -> book_input_stage
                -> order_fifo -> order_book -> price_storage
                                     |              |
                                 ram_array     level_array

    packet 1   8 x A   O1-O4 buy, O5-O8 sell
    packet 2   2 x D   O4, O6
    packet 3   2 x U   O2 qty 200 -> 400 at the same price
                       O5 55000 -> 60000, qty 50 -> 75
    packet 4   2 x E   O1 filled (100), O8 partial (50 of 100)

    expected end state
        bids  40000: 400 (O2)   30000: 300 (O3)
        asks  55000:  50 (O7)   60000:  75 (O5)   65000: 50 (O8)

ONE TEST

  test_live_gapped
      The four packets one at a time, each driven as its own run with the
      chain drained and idle between packets - "Fire queue" with a pause
      between packets. The book is checked after every packet.

UNLIKE test_market_data, THIS ONE CHECKS

Each step is compared against a small Python model of the book (BookModel,
below) that applies the same messages. Level quantities are read from the
harness's shadow of the level write bus; resting orders from a shadow of
the order-table write bus. Every difference is logged as MISMATCH and the
test fails at the end if there were any. The dumps are still printed in
full.

ORDER TABLE DEPTH

md_harness mirrors ADDR_W = 4 (16 slots per table) but ram_pkg now has
C_ADDR_W = 9 (512). harness.read_tables() and dump_orders() only look at
addresses 0-15, so they miss most orders. This file does not use them: it
builds its own view of the order tables from every write on the order RAM
bus, at whatever address, and cross-checks those slots against the RAM
directly when the simulator allows.

Run with example_packets_sim.ps1. The test has the elaboration to itself,
so it starts on empty memories and the end state is absolute.

Simulator: NVC (also runs under GHDL). VHDL-2008. cocotb 2.x.
"""

import struct

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

import book_model as bm
import xgmii as xg
from md_harness import (
    BOOK_ID, BUY, DRAIN_CYCLES, LEVELS, NUM_SIDES, NUM_TABLES, SELL,
    SIDE_BYTE, Harness, Obs, banner, dump_levels, dump_pls, fmt_side,
    frame_many, px_index, safe_int, slot_key, slot_val, split_key,
    split_level, split_value, trace, report, VALID_BIT,
)


# ===========================================================================
# The live test, as data
# ===========================================================================
ORDER_PREFIX = 0x62018A81                # order N is 62018a81:0000000N
MATCH_PREFIX = 0x00FB30C2_00000036       # match N is 00fb30c2:00000036:0000000N


def oid(n: int) -> int:
    return (ORDER_PREFIX << 32) | n


# (type, timestamp, order n, side, ...) - fields after side by type:
#   A  position, qty, price          U  position, qty, price
#   E  executed qty, match n         D  (none)
PACKETS = [
    [("A", 100000000, 1, BUY, 1, 100, 30000),
     ("A", 100000100, 2, BUY, 1, 200, 40000),
     ("A", 100000200, 3, BUY, 3, 300, 30000),
     ("A", 100000300, 4, BUY, 1, 400, 50000),
     ("A", 100000400, 5, SELL, 1, 50, 55000),
     ("A", 100000500, 6, SELL, 2, 75, 60000),
     ("A", 100000600, 7, SELL, 2, 50, 55000),
     ("A", 100000700, 8, SELL, 4, 100, 65000)],
    [("D", 200000000, 4, BUY),
     ("D", 200000100, 6, SELL)],
    [("U", 300000000, 2, BUY, 1, 400, 40000),
     ("U", 300000100, 5, SELL, 2, 75, 60000)],
    [("E", 400000000, 1, BUY, 100, 1),
     ("E", 400000100, 8, SELL, 50, 2)],
]
PACKET_NAMES = ["8 adds", "2 deletes", "2 replaces", "2 executions"]
PRICES = (30000, 40000, 50000, 55000, 60000, 65000)

# Headers exactly as the test interface sent them (see capture.pcap).
LIVE_HDR = dict(
    dst_mac="ff:ff:ff:ff:ff:ff",
    src_mac="02:00:00:00:00:02",
    src_ip="169.254.125.163",
    dst_ip="169.254.71.75",
    udp_src_port=30000,
    udp_dst_port=30001,
    mold_session=b"SESSION001",
)
OWNER, COUNTERPARTY = b"PART01 ", b"PART02 "


def build_msg(m) -> bytes:
    kind, ts, n, side = m[:4]
    s = SIDE_BYTE[side]
    if kind == "A":
        pos, qty, px = m[4:]
        return bm.build_add(order_id=oid(n), book_id=BOOK_ID, side=s,
                            qty=qty, price=px, position=pos, extype=0,
                            lot=2, timestamp=ts)
    if kind == "U":
        pos, qty, px = m[4:]
        return bm.build_replace(order_id=oid(n), book_id=BOOK_ID, side=s,
                                qty=qty, price=px, position=pos, extype=0,
                                timestamp=ts)
    if kind == "E":
        qty, match = m[4:]
        b = bytearray(bm.build_exec(order_id=oid(n), book_id=BOOK_ID, side=s,
                                    qty=qty,
                                    match_id=(MATCH_PREFIX << 32) | match,
                                    timestamp=ts))
        b[38:45], b[45:52] = OWNER, COUNTERPARTY
        return bytes(b)
    if kind == "D":
        return bm.build_delete(order_id=oid(n), book_id=BOOK_ID, side=s,
                               timestamp=ts)
    raise ValueError(kind)


def _csum16(data: bytes) -> int:
    if len(data) % 2:
        data += b"\x00"
    s = sum(struct.unpack(f">{len(data) // 2}H", data))
    while s >> 16:
        s = (s & 0xFFFF) + (s >> 16)
    return ~s & 0xFFFF


def with_udp_checksum(frame: bytes) -> bytes:
    """Fill in the UDP checksum the way the test interface does."""
    ip_off = 14
    ihl = (frame[ip_off] & 0x0F) * 4
    u = ip_off + ihl
    udp = frame[u:u + 6] + b"\x00\x00" + frame[u + 8:]
    pseudo = (frame[ip_off + 12:ip_off + 20] + b"\x00\x11"
              + struct.pack(">H", len(udp)))
    c = _csum16(pseudo + udp) or 0xFFFF
    return frame[:u + 6] + struct.pack(">H", c) + frame[u + 8:]


def live_frames():
    """The four frames, numbered as the interface numbers them.

    frame_many takes the MoldUDP64 sequence from md_harness's counter,
    which Harness.start resets to 1, so packets get 1, 9, 11, 13 - the
    same as the live run. IP ids are 1..4.
    """
    out = []
    for n, pkt_msgs in enumerate(PACKETS):
        f = frame_many([build_msg(m) for m in pkt_msgs], ip_id=n + 1,
                       **LIVE_HDR)
        out.append(with_udp_checksum(f))
    return out


# ===========================================================================
# XGMII
# ===========================================================================
GAP_IDLE = 16       # IDLE beats ahead of each packet, on top of the drain


def beats_for(frame):
    """One frame as XGMII beats, /S/ in lane 0, with idle ahead of it."""
    return xg.idle_beats(GAP_IDLE) + xg.to_xgmii(frame)


# ===========================================================================
# Driving and watching
# ===========================================================================
async def run_beats(h, beats, drain=DRAIN_CYCLES):
    """md_harness.run, driving a prepared XGMII beat list."""
    dut = h.dut
    obs = Obs()

    async def drive():
        for rxd, rxc in beats:
            dut.xgmii_rxd.value = rxd
            dut.xgmii_rxc.value = rxc
            await RisingEdge(dut.clk)
        dut.xgmii_rxd.value = xg.IDLE_RXD
        dut.xgmii_rxc.value = xg.IDLE_RXC

    async def sample():
        await FallingEdge(dut.clk)
        await ReadOnly()
        trace(h, obs)
        await RisingEdge(dut.clk)
        h.cycle += 1

    driver = cocotb.start_soon(drive())
    while not driver.done():
        await sample()
    for _ in range(drain):
        await sample()
    return obs


class LiveHarness(Harness):
    """Harness that survives an order RAM the simulator will not index.

    Harness.start does the clock and reset, then reaches for the order RAMs
    and raises if it cannot. Everything this file needs comes from the
    write buses, so a missing RAM handle only turns off the cross-check.
    """

    async def start(self):
        try:
            await super().start()
        except AssertionError as e:
            self.dut._log.info("order RAM not reachable (%s) - using the write "
                               "bus only", str(e).splitlines()[0])
            self.rams = None
            self.lvls = self._level_handles()


class OrderShadow:
    """The order tables as written: (table, addr) -> slot, from the write bus."""

    def __init__(self):
        self.slots = {}

    def apply(self, obs):
        for _, t, a, key, val, valid in obs.owrites:
            self.slots[(t, a)] = (key, val, valid)

    def resting(self):
        """{(order id, side): (qty, price, table, addr)} for valid slots."""
        out = {}
        for (t, a), (key, val, valid) in self.slots.items():
            if not valid or key is None:
                continue
            o, side = split_key(key)
            v = split_value(val)
            out[(o, side)] = (v["qty"], v["price"], t, a)
        return out


# ===========================================================================
# Reference model
# ===========================================================================
class BookModel:
    """What the book should hold, applying the spec rules the RTL implements:
    absolute qty on A/U, delta on E, order removed when it reaches zero."""

    def __init__(self):
        self.orders = {}                 # (order id, side) -> [qty, price]

    def apply(self, m):
        kind, _, n, side = m[:4]
        k = (oid(n), side)
        if kind in ("A", "U"):
            _, qty, px = m[4:]
            self.orders[k] = [qty, px]
        elif kind == "D":
            self.orders.pop(k, None)
        elif kind == "E":
            if k in self.orders:
                self.orders[k][0] -= m[4]
                if self.orders[k][0] <= 0:
                    del self.orders[k]

    def levels(self):
        out = {}
        for (_, side), (qty, px) in self.orders.items():
            out[(side, px)] = out.get((side, px), 0) + qty
        return out


# ===========================================================================
# Dumps and checks
# ===========================================================================
def fmt_oid(o):
    return f"{o >> 32:08x}:{o & 0xFFFFFFFF:08x}"


def order_label(o):
    return f"O{o & 0xFFFFFFFF}" if (o >> 32) == ORDER_PREFIX else fmt_oid(o)


async def dump_state(h, shadow, label):
    """Level memory, resting orders (any address) and price_storage."""
    dut, log = h.dut, h.dut._log
    await FallingEdge(dut.clk)
    await ReadOnly()

    log.info("    %s", label)
    levels = h.read_levels()
    dump_levels(log, levels, h.level_source, h.level_owners(levels), h.number)

    rest = shadow.resting()
    lines = [f"    RESTING ORDERS (order RAM write bus, all {NUM_TABLES} tables, "
             f"any address)"]
    if not rest:
        lines.append("      none")
    for (o, side), (qty, px, t, a) in sorted(rest.items()):
        ram = ""
        if h.rams is not None:
            try:
                slot = safe_int(h.rams[t][a])
                ok = (slot is not None and (slot >> VALID_BIT) & 1
                      and slot_key(slot) == ((o << 1) | side)
                      and split_value(slot_val(slot))["qty"] == qty)
                ram = "  ram ok" if ok else f"  RAM DISAGREES ({slot})"
            except Exception:              # noqa: BLE001
                ram = "  (ram not readable)"
        lines.append(f"      {order_label(o):<4} {fmt_oid(o)} {fmt_side(side):<4} "
                     f"qty {qty:>5}  px {px:>6}   T{t}[{a:3d}]{ram}")
    log.info("%s", "\n".join(lines))

    try:
        dump_pls(log, dut)
    except Exception as e:                 # noqa: BLE001
        log.info("    PRICE STORAGE  (not printed: %s)", e)
    await RisingEdge(dut.clk)


def check(h, step, model, shadow, problems):
    """Compare the shadows against the model and log a side-by-side table."""
    log = h.dut._log
    exp_lv = model.levels()
    want_orders = {k: tuple(v) for k, v in model.orders.items()}

    lines = [f"    CHECK after {step}",
             "      level          expected     got",]
    bad = []

    # Every level the test can touch, plus anything live that it should not.
    keys = {(s, p) for s in (BUY, SELL) for p in PRICES}
    for s in range(NUM_SIDES):
        for a, v in LEVELS.mem[s].items():
            d = split_level(v)
            if d and d["qty"]:
                keys.add((s, d["price"]))
    for side, px in sorted(keys, key=lambda k: (-k[0], -k[1])):
        want = exp_lv.get((side, px), 0)
        d = split_level(LEVELS.read(side, px_index(px)))
        got = d["qty"] if d else 0
        good = got == want and (not want or d["price"] == px)
        if want or got:
            lines.append(f"      {fmt_side(side):<4} {px:>6}   {want:>8}  "
                         f"{got:>6}   {'ok' if good else 'MISMATCH'}")
        if not good:
            bad.append(f"{step}: {fmt_side(side)} level {px} expected {want}, "
                       f"got {got}" + ("" if not d or not got or d["price"] == px
                                       else f" (stored px {d['price']})"))

    lines.append("      order          expected        got")
    rest = shadow.resting()
    for k in sorted(set(want_orders) | set(rest)):
        o, side = k
        w = want_orders.get(k)
        g = rest.get(k)
        ws = f"{w[0]}@{w[1]}" if w else "gone"
        gs = f"{g[0]}@{g[1]}" if g else "gone"
        good = (w is None and g is None) or (w and g and w == g[:2])
        lines.append(f"      {order_label(o):<4} {fmt_side(side):<4}  {ws:>12}  "
                     f"{gs:>12}   {'ok' if good else 'MISMATCH'}")
        if not good:
            bad.append(f"{step}: {order_label(o)} {fmt_side(side)} expected {ws}, "
                       f"got {gs}")

    lines.append(f"      -> {'MATCH' if not bad else f'{len(bad)} MISMATCH(ES)'}")
    log.info("%s", "\n".join(lines))
    problems.extend(bad)


def check_counts(h, step, obs, n_frames, n_msgs, problems):
    """Frames off the wire, messages out of the parser, commands into the book."""
    got = (len(obs.pkts), len(obs.msgs), len(obs.cmds))
    want = (n_frames, n_msgs, n_msgs)
    h.dut._log.info("    COUNTS after %s: frames %d/%d  parser msgs %d/%d  "
                    "commands %d/%d   %s", step, got[0], want[0], got[1],
                    want[1], got[2], want[2],
                    "ok" if got == want else "MISMATCH")
    if got != want:
        what = ("frame never reached the parser" if got[0] < want[0] else
                "messages lost after the converter")
        problems.append(f"{step}: frames/msgs/cmds {got} expected {want} - {what}")


def header(h, title, lines):
    dut = h.dut
    depth = "unknown"
    if h.rams is not None:
        try:
            depth = str(len(h.rams[0]))
        except Exception:                  # noqa: BLE001
            pass
    dut._log.info("=" * 100)
    dut._log.info("%s", title)
    dut._log.info("=" * 100)
    dut._log.info("source      : order_book_test_packets.txt, as fired at the FPGA")
    dut._log.info("frames      : byte-identical to the test interface's "
                  "(MACs, IPs, ports 30000->30001,")
    dut._log.info("              SESSION001, seq 1/9/11/13, IP id 1-4, UDP checksum)")
    dut._log.info("book id     : %d", BOOK_ID)
    dut._log.info("order table : %d tables x %s slots (RTL). md_harness mirrors 16, "
                  "so orders here come", NUM_TABLES, depth)
    dut._log.info("              from the RAM write bus, not harness.read_tables()")
    dut._log.info("level source: %s", h.level_source)
    for ln in lines:
        dut._log.info("%s", ln)
    dut._log.info("this test CHECKS: each step is compared with BookModel")
    dut._log.info("=" * 100)


def verdict(h, problems):
    log = h.dut._log
    banner(h.dut, "VERDICT", rule="=")
    if not problems:
        log.info("  all steps match the model")
    for p in problems:
        log.error("  %s", p)
    assert not problems, f"{len(problems)} mismatch(es) - see VERDICT above"


async def start(dut):
    h = LiveHarness(dut)
    await h.start()
    for p in PRICES:
        h.expect(p)
    return h


# ===========================================================================
# The test: packet by packet, idle between
# ===========================================================================
@cocotb.test()
async def test_live_gapped(dut):
    """The four packets one at a time, checked after each."""
    h = await start(dut)
    header(h, "LIVE PACKETS - one packet at a time, idle between, checked after each",
           [f"stimulus    : each frame is its own run: {GAP_IDLE} IDLE beats, the frame, "
            f"then a {DRAIN_CYCLES}-cycle drain"])

    frames, model, shadow, problems = live_frames(), BookModel(), OrderShadow(), []

    for n, (frame, msgs) in enumerate(zip(frames, PACKETS)):
        step = f"packet {n + 1} ({PACKET_NAMES[n]})"
        banner(dut, f"PACKET {n + 1}/4 - {PACKET_NAMES[n]}, {len(frame)} bytes")
        for m in msgs:
            dut._log.info("    %s", m)
            model.apply(m)
        obs = await run_beats(h, beats_for(frame))
        shadow.apply(obs)
        report(h, obs, expect_msgs=len(msgs))
        await dump_state(h, shadow, f"AFTER PACKET {n + 1}")
        check_counts(h, step, obs, 1, len(msgs), problems)
        check(h, step, model, shadow, problems)

    verdict(h, problems)
