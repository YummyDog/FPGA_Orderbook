"""
single_test - one hand-written frame through market_data_top, and the
timestamp frames that come back out of the TX side.

A separate simulation from test_market_data: its own runner
(single_test_sim.ps1), its own build folder and results file, its own
waveform. It shares md_harness, xgmii, asx_packets and book_model with the
main suite and changes none of them.

THE FRAME IN

FRAME_HEX below is sent byte for byte. The harness wraps it the way the PCS
would put it on the wire:

    IDLE  ->  /S/ + six preamble bytes + SFD (one beat)
          ->  the 101 bytes below
          ->  a correct Ethernet FCS
          ->  /T/, then IDLE

The given bytes stop at the end of the ITCH message and carry no FCS, so the
harness appends one (zlib.crc32, least significant byte first). Without it
xgmii_crc32_rx64 would fail the frame and order_fifo would dump the command.

What the bytes say:

    Ethernet  dst ff:ff:ff:ff:ff:ff  src 02:00:00:00:00:02  type 0x0800
    IPv4      169.254.125.163 -> 169.254.71.75  UDP  total length 87
              id 0x0017  header checksum 0x2194 (correct)
    UDP       30000 -> 30001  length 67  checksum 0xF4D3
    MoldUDP64 session "SESSION001"  seq 1  1 message
    ITCH      A - add order, 37 bytes
                timestamp  0
                order id   0x00000000AAAAAAAA
                book id    0
                side       'B'
                position   1
                quantity   32
                price      30
                ext type   0
                lot type   2

THE FRAMES OUT

One add order produces four timestamp events - input, fifo, order and price -
and tx_top turns each into one UDP/IPv4/Ethernet frame on xgmii_txd /
xgmii_txc. TxMonitor watches those two outputs from the moment the test
starts, cuts the beat stream into frames at /S/ and /T/, and after the send
prints every frame it saw:

    - the raw beats, lane 0 first, with txc
    - whether the preamble/SFD beat is well formed and the FCS checks out
      (the CRC register reaches 0xDEBB20E3 over frame + FCS)
    - the Ethernet, IPv4 and UDP headers, with the IPv4 header checksum
      recomputed
    - the 87-bit payload, decoded into event type, op, data, side and
      timestamp

and then, in a section of its own, every frame again as raw bytes from the
destination MAC onward (no /S/, preamble or SFD), sixteen to a row: once
including the four FCS bytes and once without them.

It also records every event the engine handed to the transmitter (ev_valid
and ev_ready both high) and says whether each frame's payload is the event
taken in the same position. EXPECTED_TX_FRAMES is 4; the test waits up to
TX_WAIT_CYCLES for them and reports how many actually came out.

The monitor counts cycles from the same falling edge as the harness trace,
so while the frame is being sent its "cyc" numbers and the trace's line up.

BOOK ID 0

book_input_stage drops every message whose order book id is not
G_ORDER_BOOK_ID, and this one's is 0. The runner therefore elaborates with
G_ORDER_BOOK_ID = 0 by default, so the add reaches the book. Run it with
-BookId 85603 to see the filter drop it instead. A filtered message never
pulses in_tvalid, so that run produces no events and no TX frames, and the
"expected 4" warning is the point. The value in use is passed in through
SINGLE_TEST_BOOK_ID and printed in the header.

Like the main suite this checks nothing. It drives the frame and prints the
trace, the report, both memories and the TX frames.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import os
import struct

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly

from md_harness import (
    Harness, header, report, run, dump_all, banner,
    px_index, safe_int, to_signed32, DRAIN_CYCLES,
)
import xgmii as xg


# ===========================================================================
# The frame, exactly as given. No FCS - the harness adds it.
# ===========================================================================
FRAME_HEX = """
ff ff ff ff ff ff 02 00 00 00 00 02 08 00 45 00
00 57 00 17 40 00 40 11 21 94 a9 fe 7d a3 a9 fe
47 4b 75 30 75 31 00 43 f4 d3 53 45 53 53 49 4f
4e 30 30 31 00 00 00 00 00 00 00 01 00 01 00 25
41 00 00 00 00 00 00 00 00 aa aa aa aa 00 00 00
00 42 00 00 00 01 00 00 00 00 00 00 00 20 00 00
00 1e 00 00 02
"""

FRAME = bytes.fromhex(" ".join(FRAME_HEX.split()))
assert len(FRAME) == 101, f"frame is {len(FRAME)} bytes, expected 101"

PRICE = 30                 # the add order's price, for the level window


# ===========================================================================
# TX side - mirrors order_tx_pkg. NOT derived from it.
#
# If C_PAYLOAD_BITS or the header lengths change there, change them here or
# the payload decodes from the wrong offset.
# ===========================================================================
EXPECTED_TX_FRAMES = 4     # input, fifo, order, price - one add order
TX_WAIT_CYCLES = 400       # after the send, how long to wait for them
TX_TAIL_CYCLES = 24        # then a little longer, to catch an unexpected one

TX_HDR_LEN = 14 + 20 + 8                       # Ethernet + IPv4 + UDP
TX_PAYLOAD_BITS = 87                           # C_PAYLOAD_BITS
TX_MSG_LEN = (TX_PAYLOAD_BITS + 7) // 8        # 11 bytes, right-justified

# m_payload, MSB first: event_type(2) op(2) data(64) side(1) ts(18)
EV_TS_W, EV_SIDE_LO, EV_DATA_LO, EV_OP_LO, EV_TYPE_LO = 18, 18, 19, 83, 85

EV_TYPE_NAME = {0: "price", 1: "order", 2: "input", 3: "fifo"}
EV_OP_NAME = {0: "ADD", 1: "EXEC", 2: "REPLACE", 3: "DELETE"}


def decode_event(p):
    """An 87-bit event payload as its fields."""
    if p is None:
        return None
    return {
        "type": (p >> EV_TYPE_LO) & 0x3,
        "op": (p >> EV_OP_LO) & 0x3,
        "data": (p >> EV_DATA_LO) & ((1 << 64) - 1),
        "side": (p >> EV_SIDE_LO) & 0x1,
        "ts": p & ((1 << EV_TS_W) - 1),
    }


def fmt_event(ev):
    if ev is None:
        return "?"
    name = EV_TYPE_NAME.get(ev["type"], "?")
    side = "BUY" if ev["side"] == 0 else "SELL"
    if ev["type"] == 0:
        # price: data is the level written, qty & price
        qty = ev["data"] >> 32
        px = to_signed32(ev["data"] & 0xFFFFFFFF)
        what = f"level qty {qty} px {px}"
    else:
        what = f"order id 0x{ev['data']:016X}"
    return (f"{name:<5}  op {EV_OP_NAME[ev['op']]:<7}  {side:<4}  {what}  "
            f"ts {ev['ts']}")


def ipv4_checksum_ok(hdr):
    """True if the one's complement sum over the header, checksum included,
    folds to 0xFFFF."""
    s = 0
    for i in range(0, len(hdr), 2):
        s += (hdr[i] << 8) | hdr[i + 1]
    while s >> 16:
        s = (s & 0xFFFF) + (s >> 16)
    return s == 0xFFFF


class TxMonitor:
    """
    Watches xgmii_txd / xgmii_txc and the engine's event port.

    Frames are cut at /S/ in lane 0 and /T/ in any lane, the same way
    xgmii.decode does it, but live and with the cycle each beat arrived.
    """

    def __init__(self, dut):
        self.dut = dut
        self.cycle = 0
        self.frames = []
        self.cur = None
        self.events = []            # (cycle, payload) taken by the transmitter
        self.stray = 0              # non-idle beats outside a frame
        self.running = True

        # The engine's event port, for matching frames to the events that
        # produced them. Optional - the frames are decoded either way.
        try:
            e = dut.u_engine
            self.ev = (e.ev_valid, e.ev_ready, e.ev_payload)
            _ = e.ev_valid.value
        except Exception:                        # noqa: BLE001
            self.ev = None

    @property
    def busy(self):
        return self.cur is not None

    async def run(self):
        dut = self.dut
        while self.running:
            await FallingEdge(dut.clk)
            await ReadOnly()

            if self.ev is not None:
                v, r, p = (safe_int(h) for h in self.ev)
                if v == 1 and r == 1:
                    self.events.append((self.cycle, p))

            txd = safe_int(dut.xgmii_txd)
            txc = safe_int(dut.xgmii_txc)
            if txd is not None and txc is not None:
                self._beat(txd, txc)

            await RisingEdge(dut.clk)
            self.cycle += 1

    def _beat(self, txd, txc):
        lanes = txd.to_bytes(8, "little")

        if txc & 1 and lanes[0] == xg.START:
            if self.cur is not None:
                self.cur["note"] = "no /T/ before the next /S/"
                self.frames.append(self.cur)
            self.cur = {
                "start": self.cycle,
                "beats": [(self.cycle, txd, txc)],
                "data": bytearray(),
                "pre_ok": (txc == 0x01
                           and list(lanes[1:7]) == [xg.PREAMBLE] * 6
                           and lanes[7] == xg.SFD),
                "note": "",
            }
            return

        if self.cur is None:
            if not (txc == 0xFF and txd == xg.IDLE_RXD):
                self.stray += 1
            return

        self.cur["beats"].append((self.cycle, txd, txc))
        term = next((i for i in range(8)
                     if (txc >> i) & 1 and lanes[i] == xg.TERM), None)
        if term is not None:
            self.cur["data"] += lanes[:term]
            self.cur["end"] = self.cycle
            self.frames.append(self.cur)
            self.cur = None
        elif txc == 0:
            self.cur["data"] += lanes
        else:
            self.cur["note"] = (f"control character mid-frame at cyc "
                                f"{self.cycle}")


def hex_rows(b, per=16):
    """Bytes as rows of space-separated hex, 16 to a row - the layout the
    frame in was given in, so the two read alike."""
    return [" ".join(f"{x:02x}" for x in b[i:i + per])
            for i in range(0, len(b), per)]


def raw_frame_lines(n, fr):
    """
    One TX frame as raw bytes, twice.

    Both start at the first byte after the SFD - destination MAC first - so
    the /S/, preamble and SFD beat is never included. The first copy runs to
    the end of the FCS; the second stops before it.
    """
    wire = bytes(fr["data"])
    body = wire[:-4] if len(wire) >= 4 else b""
    out = [f"TX PACKET {n + 1}   cyc {fr['start']}..{fr.get('end', '?')}"]
    out.append(f"  with FCS ({len(wire)} bytes)")
    out += [f"    {r}" for r in hex_rows(wire)]
    out.append(f"  without FCS ({len(body)} bytes)")
    out += [f"    {r}" for r in hex_rows(body)]
    return out


def tx_frame_lines(n, fr, taken):
    """Everything worth printing about one TX frame."""
    wire = bytes(fr["data"])
    out = [f"TX FRAME {n + 1}   cyc {fr['start']}..{fr.get('end', '?')}   "
           f"{len(fr['beats'])} beats   {len(wire)} bytes incl. FCS"]

    for c, txd, txc in fr["beats"]:
        lanes = " ".join(f"{b:02x}" for b in txd.to_bytes(8, "little"))
        out.append(f"  cyc {c:4d}  txc {txc:08b}  lanes 0..7: {lanes}")

    fcs_ok = (len(wire) >= 4
              and xg.crc_upd(0xFFFFFFFF, wire) == xg.CRC_RESIDUE)
    out.append(f"  preamble/SFD {'ok' if fr['pre_ok'] else 'BAD'}   "
               f"FCS {'ok' if fcs_ok else 'BAD'}"
               + (f"   NOTE: {fr['note']}" if fr["note"] else ""))

    if len(wire) < TX_HDR_LEN + TX_MSG_LEN + 4:
        out.append("  too short to decode")
        return out

    f = wire[:-4]
    fcs = wire[-4:]
    out.append(f"  fcs       {fcs.hex(' ')}  (expected "
               f"{xg.fcs(f).hex(' ')})")

    etype = struct.unpack(">H", f[12:14])[0]
    out.append(f"  ethernet  dst {':'.join(f'{b:02x}' for b in f[0:6])}  "
               f"src {':'.join(f'{b:02x}' for b in f[6:12])}  "
               f"type 0x{etype:04X}")

    ip = f[14:34]
    total, ident, flags, ttl, proto, csum = struct.unpack(">HHHBBH",
                                                          ip[2:12])
    out.append(f"  ipv4      {'.'.join(str(b) for b in ip[12:16])} -> "
               f"{'.'.join(str(b) for b in ip[16:20])}  total {total}  "
               f"id 0x{ident:04X}  flags 0x{flags:04X}  ttl {ttl}  "
               f"proto {proto}  csum 0x{csum:04X} "
               f"({'ok' if ipv4_checksum_ok(ip) else 'BAD'})")

    sport, dport, ulen, ucsum = struct.unpack(">HHHH", f[34:42])
    out.append(f"  udp       {sport} -> {dport}  length {ulen}  "
               f"csum 0x{ucsum:04X}")

    body = f[TX_HDR_LEN:]
    msg = body[:TX_MSG_LEN]
    pad = body[TX_MSG_LEN:]
    out.append(f"  payload   {msg.hex(' ')}   + {len(pad)} pad bytes"
               + ("" if not any(pad) else "  (pad NOT zero)"))

    p = int.from_bytes(msg, "big")
    if p >> TX_PAYLOAD_BITS:
        out.append("  NOTE: bits above the 87-bit payload are set")
    p &= (1 << TX_PAYLOAD_BITS) - 1
    out.append(f"  event     {fmt_event(decode_event(p))}")

    if taken is None:
        out.append("  source    engine event port not visible - no match")
    elif n < len(taken):
        c, tp = taken[n]
        same = tp == p
        out.append(f"  source    event {n + 1} taken by the transmitter at "
                   f"cyc {c}: {'payload matches' if same else 'MISMATCH'}")
        if not same:
            out.append(f"            taken   {fmt_event(decode_event(tp))}")
    else:
        out.append("  source    no event was taken for this frame")

    return out


# ===========================================================================
# Decoding the frame in, for the log only
# ===========================================================================
def _mac(b):
    return ":".join(f"{x:02x}" for x in b)


def _ip(b):
    return ".".join(str(x) for x in b)


def decode_frame(f):
    """The frame's fields as printable lines. Labels only - nothing checks."""
    lines = []

    etype = struct.unpack(">H", f[12:14])[0]
    lines.append(f"ethernet  dst {_mac(f[0:6])}  src {_mac(f[6:12])}  "
                 f"type 0x{etype:04X}")

    ip = f[14:34]
    ihl = (ip[0] & 0x0F) * 4
    total, ident, flags, ttl, proto, csum = struct.unpack(
        ">HHHBBH", ip[2:12])
    lines.append(f"ipv4      {_ip(ip[12:16])} -> {_ip(ip[16:20])}  "
                 f"ihl {ihl}  total {total}  id 0x{ident:04X}  "
                 f"flags 0x{flags:04X}  ttl {ttl}  proto {proto}  "
                 f"csum 0x{csum:04X}")

    u = 14 + ihl
    sport, dport, ulen, ucsum = struct.unpack(">HHHH", f[u:u + 8])
    lines.append(f"udp       {sport} -> {dport}  length {ulen}  "
                 f"csum 0x{ucsum:04X}")

    m = u + 8
    session = f[m:m + 10].decode("ascii", errors="replace")
    seq = struct.unpack(">Q", f[m + 10:m + 18])[0]
    count = struct.unpack(">H", f[m + 18:m + 20])[0]
    lines.append(f"moldudp64 session '{session}'  seq {seq}  "
                 f"count {count}")

    p = m + 20
    for k in range(count):
        mlen = struct.unpack(">H", f[p:p + 2])[0]
        msg = f[p + 2:p + 2 + mlen]
        mtype = chr(msg[0]) if msg else "?"
        lines.append(f"itch[{k}]   type '{mtype}'  length {mlen}")
        if mtype == "A" and mlen >= 37:
            ts = struct.unpack(">I", msg[1:5])[0]
            oid = struct.unpack(">Q", msg[5:13])[0]
            book = struct.unpack(">I", msg[13:17])[0]
            side = chr(msg[17])
            pos = struct.unpack(">I", msg[18:22])[0]
            qty = struct.unpack(">Q", msg[22:30])[0]
            price = struct.unpack(">i", msg[30:34])[0]
            ext = struct.unpack(">H", msg[34:36])[0]
            lot = msg[36]
            lines += [
                f"            timestamp {ts}",
                f"            order id  0x{oid:016X}",
                f"            book id   {book}",
                f"            side      '{side}'",
                f"            position  {pos}",
                f"            quantity  {qty}",
                f"            price     {price}  (level index "
                f"{px_index(price)})",
                f"            ext type  0x{ext:04X}",
                f"            lot type  {lot}",
            ]
        p += 2 + mlen

    return lines


def beat_lines(frame):
    """The XGMII beats for one frame, lane 0 first, as the driver sends them."""
    out = []
    for n, (rxd, rxc) in enumerate(xg.to_xgmii(frame)):
        lanes = " ".join(f"{b:02x}" for b in rxd.to_bytes(8, "little"))
        out.append(f"beat {n:2d}  rxc {rxc:08b}  lanes 0..7: {lanes}")
    return out


# ===========================================================================
# The test
# ===========================================================================
@cocotb.test()
async def test_single_frame(dut):
    """One add order in, four timestamp frames out."""
    book = os.environ.get("SINGLE_TEST_BOOK_ID", "?")

    h = Harness(dut)
    await h.start()
    header(h, "SINGLE FRAME - one add order in, timestamp frames out",
           [f"engine book : G_ORDER_BOOK_ID = {book} for this run "
            "(single_test_sim.ps1 -BookId).",
            "              The 'book id' line above is the main suite's "
            "default and does not apply.",
            f"frame       : {len(FRAME)} bytes as given, "
            f"{len(xg.append_fcs(FRAME))} on the wire with the FCS",
            f"tx          : {EXPECTED_TX_FRAMES} frames expected on "
            "xgmii_txd/txc - input, fifo, order, price"])

    h.expect(PRICE)

    # Watch the TX outputs from before the first beat goes in.
    mon = TxMonitor(dut)
    cocotb.start_soon(mon.run())
    if mon.ev is None:
        dut._log.warning("engine event port (u_engine.ev_valid / ev_ready / "
                         "ev_payload) not reachable - TX frames will be "
                         "decoded but not matched to events")

    banner(dut, "THE FRAME")
    for ln in decode_frame(FRAME):
        dut._log.info("    %s", ln)

    banner(dut, "ON THE WIRE - preamble + SFD, the frame, FCS, /T/")
    for ln in beat_lines(FRAME):
        dut._log.info("    %s", ln)

    banner(dut, "SEND")
    obs = await run(h, FRAME, drain=DRAIN_CYCLES * 2)
    report(h, obs, expect_msgs=1)
    await dump_all(h, "AFTER THE FRAME")

    # The transmitter needs a whole frame per event, so the last of the four
    # can still be going out after the drain. Wait for them, then a little
    # longer in case there is a fifth.
    waited = 0
    while (len(mon.frames) < EXPECTED_TX_FRAMES or mon.busy) \
            and waited < TX_WAIT_CYCLES:
        await RisingEdge(dut.clk)
        waited += 1
    for _ in range(TX_TAIL_CYCLES):
        await RisingEdge(dut.clk)
    mon.running = False

    banner(dut, f"TX OUTPUT - {len(mon.frames)} frame(s) seen, "
                f"{EXPECTED_TX_FRAMES} expected", rule="=")
    if len(mon.frames) != EXPECTED_TX_FRAMES:
        dut._log.warning("    expected %d TX frames, saw %d",
                         EXPECTED_TX_FRAMES, len(mon.frames))
    if mon.busy:
        dut._log.warning("    a frame was still open when the monitor "
                         "stopped (no /T/ seen)")
    if mon.stray:
        dut._log.warning("    %d non-idle beat(s) outside any frame",
                         mon.stray)

    taken = mon.events if mon.ev is not None else None
    if taken is not None:
        dut._log.info("    events taken by the transmitter: %d", len(taken))
        for k, (c, p) in enumerate(taken):
            dut._log.info("      %d @cyc %d  %s", k + 1, c,
                          fmt_event(decode_event(p)))

    for n, fr in enumerate(mon.frames):
        dut._log.info("%s", "\n".join(tx_frame_lines(n, fr, taken)))

    # The same frames as plain bytes, preamble and SFD stripped, ready to
    # copy out - once with the FCS and once without.
    banner(dut, "RAW TX PACKETS - no preamble/SFD; with FCS, then without",
           rule="=")
    if not mon.frames:
        dut._log.info("    none")
    for n, fr in enumerate(mon.frames):
        dut._log.info("%s", "\n".join(raw_frame_lines(n, fr)))
