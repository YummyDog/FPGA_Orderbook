"""
cocotb testbench for itch_parser (stage 5).

Standalone: s_fields is driven by the testbench rather than by real upstream
parsers, so this module is verified on its own.

This stage emits N events per packet rather than one field bus at tlast, so
the testbench collects an event stream and compares it against the reference
model in itch_model.py.

Core cases:

  1  test_single_asx_packet      T, A, D, E - four framed, three emitted
  2  test_vlan_tagged            payload moves from byte 62 to byte 66
  3  test_all_decoded_types      A F E C U D P - all seven decode layouts
  4  test_undecoded_types        S O L Z - reported by type and length only
  5  test_single_message         one Add Order, nothing else
  6  test_heartbeat              message_count = 0, no payload, no events
  7  test_seconds_only           one T - framed but never emitted
  8  test_back_to_back           two packets, sequence continuity
  9  test_tvalid_gaps            bubbles through the payload
 10  test_sequence_numbering     T interspersed - indices must still advance
 11  test_reset_mid_packet       recovery from a mid-frame reset
 12  test_length_mismatch        wire length disagrees with the spec length

Edge cases:

 13  test_unknown_type           a type byte not in the message table
 14  test_double_completion      two messages complete in ONE beat
 15  test_large_undecoded        R at 113 bytes - beyond the 64-byte buffer
 16  test_truncated_mid_message  frame ends inside a message body
 17  test_count_mismatch         Mold count disagrees with the length chain
 18  test_long_burst             20 messages back to back

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import struct

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import asx_packets as pkt
import mold_model as mold
import itch_model as itch

CLK_PERIOD_NS = 6.4          # 156.25 MHz

# Cycles to wait after the last beat for trailing events to emerge
DRAIN_CYCLES = 24


def safe_int(handle):
    """Signals read 'U' before reset; treat unresolvable as absent."""
    try:
        return int(handle.value)
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Expected packet context - the 523-bit Ethernet + IPv4 + UDP + Mold bus
# ---------------------------------------------------------------------------
def pack_mold_fields(f: dict) -> int:
    v = 0
    v |= (f["session"] & ((1 << 80) - 1)) << mold.MOLD_SESSION_LOC
    v |= (f["sequence_num"] & ((1 << 64) - 1)) << mold.MOLD_SEQNUM_LOC
    v |= (f["message_count"] & 0xFFFF) << mold.MOLD_MSGCNT_LOC
    v |= (f["heartbeat"] & 1) << mold.MOLD_HEARTBEAT_LOC
    v |= (f["end_of_session"] & 1) << mold.MOLD_EOS_LOC
    v |= (f["hdr_truncated"] & 1) << mold.MOLD_TRUNC_LOC
    return v


def expected_pkt_fields(frame: bytes, tagged: bool = False,
                        vlan_tci: int = 0) -> int:
    upstream = mold.upstream_field_vector(frame, tagged=tagged,
                                          vlan_tci=vlan_tci)
    m = pack_mold_fields(mold.expected_mold_fields(frame, tagged=tagged))
    return (m << mold.MOLD_BASE) | upstream


# ---------------------------------------------------------------------------
# Testbench harness
# ---------------------------------------------------------------------------
class ItchTb:
    def __init__(self, dut):
        self.dut = dut
        self.out_beats = []
        self.events = []
        self.pkt_done_snaps = []

    async def start(self):
        cocotb.start_soon(Clock(self.dut.clk, CLK_PERIOD_NS, unit="ns").start())
        await self.reset()
        cocotb.start_soon(self._monitor())

    async def reset(self, cycles: int = 5):
        d = self.dut
        d.s_axis_tdata.value = 0
        d.s_axis_tkeep.value = 0
        d.s_axis_tvalid.value = 0
        d.s_axis_tlast.value = 0
        d.s_fields.value = 0
        d.m_axis_tready.value = 1      # ignored by the DUT, driven for realism
        d.resetn.value = 0
        for _ in range(cycles):
            await RisingEdge(d.clk)
        d.resetn.value = 1
        await RisingEdge(d.clk)

    def clear(self):
        self.out_beats.clear()
        self.events.clear()
        self.pkt_done_snaps.clear()

    async def _monitor(self):
        d = self.dut
        while True:
            await RisingEdge(d.clk)
            await ReadOnly()

            if safe_int(d.m_axis_tvalid) == 1:
                self.out_beats.append((
                    safe_int(d.m_axis_tdata),
                    safe_int(d.m_axis_tkeep),
                    safe_int(d.m_axis_tlast),
                ))

            if safe_int(d.msg_valid) == 1:
                self.events.append({
                    "index": safe_int(d.msg_index),
                    "seqnum": safe_int(d.msg_seqnum),
                    "type": safe_int(d.msg_type),
                    "length": safe_int(d.msg_length),
                    "fields": safe_int(d.msg_fields),
                    "status": safe_int(d.msg_status),
                    "pkt_fields": safe_int(d.pkt_fields),
                })

            if safe_int(d.pkt_done) == 1:
                self.pkt_done_snaps.append((
                    safe_int(d.pkt_msg_count),
                    safe_int(d.pkt_count_mismatch),
                ))

    async def drive(self, beats, upstream: int, gaps=None, idle_after=True):
        """
        Push one frame, holding the upstream field bus constant.

        Constant s_fields is valid stimulus: upstream stages hold their fields
        through tlast, and itch_parser reads only vlan_present and the Mold
        sequence number, both settled long before the payload.
        """
        d = self.dut
        d.s_fields.value = upstream

        for i, (tdata, tkeep, tlast) in enumerate(beats):
            for _ in range(gaps[i] if gaps else 0):
                await RisingEdge(d.clk)
                d.s_axis_tvalid.value = 0
                d.s_axis_tlast.value = 0
            await RisingEdge(d.clk)
            d.s_axis_tdata.value = tdata
            d.s_axis_tkeep.value = tkeep
            d.s_axis_tvalid.value = 1
            d.s_axis_tlast.value = 1 if tlast else 0

        if idle_after:
            await RisingEdge(d.clk)
            d.s_axis_tvalid.value = 0
            d.s_axis_tlast.value = 0

    async def drive_frames(self, items, idle_after=True):
        """Push several frames back to back, each with its own s_fields."""
        d = self.dut
        for beats, upstream in items:
            for tdata, tkeep, tlast in beats:
                await RisingEdge(d.clk)
                d.s_fields.value = upstream
                d.s_axis_tdata.value = tdata
                d.s_axis_tkeep.value = tkeep
                d.s_axis_tvalid.value = 1
                d.s_axis_tlast.value = 1 if tlast else 0

        if idle_after:
            await RisingEdge(d.clk)
            d.s_axis_tvalid.value = 0
            d.s_axis_tlast.value = 0

    async def drain(self, cycles: int = DRAIN_CYCLES):
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)

    def check_passthrough(self, beats, ctx=""):
        assert len(self.out_beats) == len(beats), (
            f"{ctx}beat count mismatch: drove {len(beats)}, "
            f"observed {len(self.out_beats)} (throughput rule violated)")
        for i, ((it, ik, il), (ot, ok, ol)) in enumerate(
                zip(beats, self.out_beats)):
            assert ot == it, f"{ctx}beat {i} tdata corrupted"
            assert ok == ik, f"{ctx}beat {i} tkeep corrupted"
            assert ol == (1 if il else 0), f"{ctx}beat {i} tlast misaligned"

    def check_tready(self):
        assert self.dut.s_axis_tready.value == 1, "s_axis_tready must be tied high"


# ---------------------------------------------------------------------------
# Event comparison
# ---------------------------------------------------------------------------
# The model reports count_mismatch on its last event; the RTL exposes it as a
# packet-level output at pkt_done. Compare only the per-message bits.
PER_MSG_STATUS_MASK = ((1 << itch.ST_DECODED) |
                       (1 << itch.ST_LEN_MISMATCH) |
                       (1 << itch.ST_MSG_TRUNCATED) |
                       (1 << itch.ST_UNKNOWN_TYPE))


def compare_events(got, expected, dut, ctx=""):
    assert len(got) == len(expected), (
        f"{ctx}event count: DUT emitted {len(got)}, model expects "
        f"{len(expected)}\n"
        f"  DUT types:   {[chr(e['type']) for e in got]}\n"
        f"  model types: {[chr(e.msg_type) for e in expected]}")

    for n, (g, e) in enumerate(zip(got, expected)):
        tag = f"{ctx}event {n} ({chr(e.msg_type)}) "

        assert g["type"] == e.msg_type, (
            f"{tag}type: got {chr(g['type'])}, expected {chr(e.msg_type)}")
        assert g["length"] == e.msg_length, (
            f"{tag}length: got {g['length']}, expected {e.msg_length}")
        assert g["index"] == e.msg_index, (
            f"{tag}index: got {g['index']}, expected {e.msg_index}")
        assert g["seqnum"] == e.msg_seqnum, (
            f"{tag}seqnum: got {g['seqnum']}, expected {e.msg_seqnum}")

        assert (g["status"] & PER_MSG_STATUS_MASK) == \
               (e.status & PER_MSG_STATUS_MASK), (
            f"{tag}status: got {g['status']:#x}, expected "
            f"{e.status & PER_MSG_STATUS_MASK:#x}")

        assert g["fields"] == e.fields_int, (
            f"{tag}fields mismatch\n"
            f"  DUT   {itch.decode_msg_fields(g['fields'])}\n"
            f"  model {e.fields}")

        dut._log.info("%sok  index=%d seq=%d len=%d",
                      tag, g["index"], g["seqnum"], g["length"])


def check_pkt_fields(tb, upstream, ctx=""):
    for n, g in enumerate(tb.events):
        assert g["pkt_fields"] == upstream, (
            f"{ctx}event {n}: pkt_fields corrupted")


# ---------------------------------------------------------------------------
# Message shorthands
# ---------------------------------------------------------------------------
ORD1 = 0x0621F1282E5ED
BOOK = 85603
MATCH = 0x0123456789ABCDEF01234567


def std_messages():
    return [
        itch.msg_seconds(1_700_000_000),
        itch.msg_add_order(ts=1234, order_id=ORD1, book=BOOK, side="B",
                           position=1, quantity=1000, price=55000, lot=2),
        itch.msg_order_delete(ts=2345, order_id=ORD1, book=BOOK, side="B"),
        itch.msg_order_executed(ts=3456, order_id=ORD1 + 1, book=BOOK,
                                side="S", qty=250, match_id=MATCH),
    ]


# ===========================================================================
# 1. Baseline
# ===========================================================================
@cocotb.test()
async def test_single_asx_packet(dut):
    """
    Seconds, Add Order, Order Delete, Order Executed.

    Four messages framed but only THREE events - the Seconds message is
    consumed as clock state. It still advances the sequence, so the Add Order
    carries sequence 1001, not 1000.
    """
    tb = ItchTb(dut)
    await tb.start()

    frame = itch.build_frame(std_messages(), mold_seqnum=1000)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, exp_secs, exp_framed = itch.expected_events(frame)

    dut._log.info("frame %d bytes, %d beats", len(frame), len(beats))
    dut._log.info("%d framed, %d events expected", exp_framed, len(exp))

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    compare_events(tb.events, exp, dut)
    check_pkt_fields(tb, upstream)

    assert safe_int(dut.exchange_seconds) == exp_secs, (
        f"exchange_seconds: got {safe_int(dut.exchange_seconds)}, "
        f"expected {exp_secs}")

    assert len(tb.pkt_done_snaps) == 1
    count, mismatch = tb.pkt_done_snaps[0]
    assert count == exp_framed, f"pkt_msg_count: got {count}, expected {exp_framed}"
    assert mismatch == 0

    # the suppressed T must still have advanced the sequence
    assert tb.events[0]["seqnum"] == 1001, (
        "the Add Order should carry sequence 1001 - the Seconds message "
        "consumes 1000 even though it emits nothing")


# ===========================================================================
# 2. VLAN tagged
# ===========================================================================
@cocotb.test()
async def test_vlan_tagged(dut):
    """
    A tag moves the payload from byte 62 to byte 66, and the parser's start
    position from beat 7 lane 6 to beat 8 lane 2.
    """
    tb = ItchTb(dut)
    await tb.start()

    vid = 100
    tci = pkt.make_tci(vid=vid)
    frame = itch.build_frame(std_messages(), mold_seqnum=2000, vlan_vid=vid)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame, tagged=True, vlan_tci=tci)
    exp, exp_secs, exp_framed = itch.expected_events(frame, tagged=True)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    compare_events(tb.events, exp, dut)
    check_pkt_fields(tb, upstream)

    assert tb.events[0]["seqnum"] == 2001
    assert len(frame) == len(itch.build_frame(std_messages(),
                                              mold_seqnum=2000)) + 4, (
        "tag was not inserted")


# ===========================================================================
# 3. Every decoded type
# ===========================================================================
@cocotb.test()
async def test_all_decoded_types(dut):
    """
    A, F, E, C, U, D, P in one packet - all seven decode layouts.

    Note P differs structurally from the rest: match_id comes first and there
    is no order_id, so a decode that assumed a common prefix would fail here
    and nowhere else.
    """
    tb = ItchTb(dut)
    await tb.start()

    messages = [
        itch.msg_add_order(ts=11, order_id=1, book=BOOK, side="B",
                           position=1, quantity=100, price=1000),
        itch.msg_add_order_pid(ts=22, order_id=2, book=BOOK, side="S",
                               position=2, quantity=200, price=2000,
                               participant="AU550"),
        itch.msg_order_executed(ts=33, order_id=1, book=BOOK, side="B",
                                qty=50, match_id=MATCH),
        itch.msg_order_executed_price(ts=44, order_id=2, book=BOOK, side="S",
                                      qty=60, match_id=MATCH + 1,
                                      owner="AU550", cp="AU551", price=2001),
        itch.msg_order_replace(ts=55, order_id=1, book=BOOK, side="B",
                               position=3, quantity=300, price=3000),
        itch.msg_order_delete(ts=66, order_id=2, book=BOOK, side="S"),
        itch.msg_trade(ts=77, match_id=MATCH + 2, side="B", qty=400,
                       book=BOOK, price=4000, owner="AU552", cp="AU553"),
    ]

    frame = itch.build_frame(messages, mold_seqnum=500)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, exp_framed = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.events) == 7, f"expected 7 events, saw {len(tb.events)}"
    compare_events(tb.events, exp, dut)

    for g in tb.events:
        assert (g["status"] >> itch.ST_DECODED) & 1 == 1, (
            f"type {chr(g['type'])} should be decoded")


# ===========================================================================
# 4. Undecoded types
# ===========================================================================
@cocotb.test()
async def test_undecoded_types(dut):
    """
    S, O, L, Z are framed and reported by type and length, but carry no
    decoded fields. msg_fields must read zero for all of them.
    """
    tb = ItchTb(dut)
    await tb.start()

    messages = [
        itch.msg_system_event(ts=1, code="O"),
        itch.msg_order_book_state(ts=2, book=BOOK, state="OPEN"),
        itch.msg_tick_size(ts=3, book=BOOK),
        itch.msg_equilibrium(ts=4, book=BOOK),
    ]

    frame = itch.build_frame(messages, mold_seqnum=100)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 4
    compare_events(tb.events, exp, dut)

    for g in tb.events:
        assert (g["status"] >> itch.ST_DECODED) & 1 == 0, (
            f"type {chr(g['type'])} should NOT be decoded")
        assert (g["status"] >> itch.ST_UNKNOWN_TYPE) & 1 == 0, (
            f"type {chr(g['type'])} is a known type")
        assert (g["status"] >> itch.ST_LEN_MISMATCH) & 1 == 0
        assert g["fields"] == 0, "msg_fields must be zero for undecoded types"


# ===========================================================================
# 5. A single message
# ===========================================================================
@cocotb.test()
async def test_single_message(dut):
    """One Add Order, nothing else - the minimal non-empty payload."""
    tb = ItchTb(dut)
    await tb.start()

    messages = [itch.msg_add_order(ts=999, order_id=ORD1, book=BOOK,
                                   side="B", position=7, quantity=12345,
                                   price=678900)]
    frame = itch.build_frame(messages, mold_seqnum=42)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, exp_framed = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.events) == 1
    compare_events(tb.events, exp, dut)

    assert tb.events[0]["index"] == 0
    assert tb.events[0]["seqnum"] == 42, "the first message carries the Mold sequence"

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 1 and mismatch == 0


# ===========================================================================
# 6. Heartbeat
# ===========================================================================
@cocotb.test()
async def test_heartbeat(dut):
    """
    message_count = 0 and no payload at all. The Mold header ends the frame,
    so the parser sees no payload bytes and emits nothing.
    """
    tb = ItchTb(dut)
    await tb.start()

    frame = itch.build_frame([], mold_seqnum=7777, mold_msg_count=0)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)

    assert len(frame) == 62, f"a heartbeat frame should be 62 bytes, got {len(frame)}"

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.events) == 0, (
        f"a heartbeat carries no messages, but {len(tb.events)} events fired")

    assert len(tb.pkt_done_snaps) == 1
    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 0, f"pkt_msg_count: got {count}, expected 0"
    assert mismatch == 0, "0 framed vs count 0 is not a mismatch"


# ===========================================================================
# 7. Seconds only
# ===========================================================================
@cocotb.test()
async def test_seconds_only(dut):
    """
    A packet containing exactly one Seconds message.

    One message is framed and the sequence advances, but no event fires -
    the strongest isolation of the T special case.
    """
    tb = ItchTb(dut)
    await tb.start()

    secs = 1_234_567_890
    frame = itch.build_frame([itch.msg_seconds(secs)], mold_seqnum=55)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.events) == 0, (
        f"a Seconds message must not emit, but {len(tb.events)} events fired")

    assert safe_int(dut.exchange_seconds) == secs, (
        f"exchange_seconds: got {safe_int(dut.exchange_seconds)}, "
        f"expected {secs}")

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 1, (
        f"pkt_msg_count: got {count}, expected 1 - a suppressed message is "
        "still framed and still consumes a sequence number")
    assert mismatch == 0


# ===========================================================================
# 8. Back to back
# ===========================================================================
@cocotb.test()
async def test_back_to_back(dut):
    """
    Two packets with zero idle between them, with continuous sequencing:
    packet 0 carries sequences 3000..3002, packet 1 starts at 3003.
    """
    tb = ItchTb(dut)
    await tb.start()

    m1 = [itch.msg_add_order(ts=1, order_id=1, book=BOOK, side="B"),
          itch.msg_order_delete(ts=2, order_id=1, book=BOOK, side="B"),
          itch.msg_add_order(ts=3, order_id=2, book=BOOK, side="S")]
    m2 = [itch.msg_order_delete(ts=4, order_id=2, book=BOOK, side="S"),
          itch.msg_add_order(ts=5, order_id=3, book=BOOK, side="B")]

    f1 = itch.build_frame(m1, mold_seqnum=3000)
    f2 = itch.build_frame(m2, mold_seqnum=3003)

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)
    u1, u2 = expected_pkt_fields(f1), expected_pkt_fields(f2)

    e1, _, n1 = itch.expected_events(f1)
    e2, _, n2 = itch.expected_events(f2)

    await tb.drive_frames([(b1, u1), (b2, u2)])
    await tb.drain()

    tb.check_passthrough(b1 + b2)
    compare_events(tb.events, e1 + e2, dut)

    assert len(tb.pkt_done_snaps) == 2, (
        f"expected 2 pkt_done pulses, saw {len(tb.pkt_done_snaps)}")
    assert tb.pkt_done_snaps[0] == (n1, 0)
    assert tb.pkt_done_snaps[1] == (n2, 0)

    # msg_index must restart per packet while the sequence keeps running
    assert tb.events[3]["index"] == 0, "msg_index should restart each packet"
    assert tb.events[3]["seqnum"] == 3003, "sequence must continue across packets"


# ===========================================================================
# 9. tvalid bubbles
# ===========================================================================
@cocotb.test()
async def test_tvalid_gaps(dut):
    """
    Idle cycles scattered through the payload. Framing advances on transfers,
    not clock edges, so the event stream must be identical to the gapless
    case.
    """
    tb = ItchTb(dut)
    await tb.start()

    frame = itch.build_frame(std_messages(), mold_seqnum=1000)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, exp_secs, _ = itch.expected_events(frame)

    gaps = [0] * len(beats)
    for i in (7, 8, 11, 14, 18):
        if i < len(gaps):
            gaps[i] = 2

    await tb.drive(beats, upstream, gaps=gaps)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    compare_events(tb.events, exp, dut)
    assert safe_int(dut.exchange_seconds) == exp_secs


# ===========================================================================
# 10. Sequence numbering across suppressed messages
# ===========================================================================
@cocotb.test()
async def test_sequence_numbering(dut):
    """
    Seconds messages interspersed through the payload.

    Six messages framed, three emitted, and the emitted indices must be
    1, 3, 5 - not 0, 1, 2. This is the single most consequential thing the
    module can get wrong: an off-by-one here silently breaks gap detection
    downstream.
    """
    tb = ItchTb(dut)
    await tb.start()

    messages = [
        itch.msg_seconds(1000),
        itch.msg_add_order(ts=1, order_id=1, book=BOOK, side="B"),
        itch.msg_seconds(1001),
        itch.msg_order_delete(ts=2, order_id=1, book=BOOK, side="B"),
        itch.msg_seconds(1002),
        itch.msg_add_order(ts=3, order_id=2, book=BOOK, side="S"),
    ]

    frame = itch.build_frame(messages, mold_seqnum=9000)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, exp_secs, exp_framed = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 3, f"expected 3 events, saw {len(tb.events)}"
    compare_events(tb.events, exp, dut)

    assert [g["index"] for g in tb.events] == [1, 3, 5], (
        f"indices {[g['index'] for g in tb.events]} - suppressed Seconds "
        "messages must still consume an index")
    assert [g["seqnum"] for g in tb.events] == [9001, 9003, 9005]

    assert safe_int(dut.exchange_seconds) == 1002, (
        "exchange_seconds should hold the LAST Seconds value")

    count, _ = tb.pkt_done_snaps[0]
    assert count == 6, f"pkt_msg_count: got {count}, expected 6"


# ===========================================================================
# 11. Reset mid-packet
# ===========================================================================
@cocotb.test()
async def test_reset_mid_packet(dut):
    """Reset part-way through a frame; the next packet must parse cleanly."""
    tb = ItchTb(dut)
    await tb.start()

    partial = pkt.to_beats(itch.build_frame(std_messages()))[:10]
    for tdata, tkeep, _ in partial:
        await RisingEdge(dut.clk)
        dut.s_axis_tdata.value = tdata
        dut.s_axis_tkeep.value = tkeep
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tlast.value = 0

    await RisingEdge(dut.clk)
    dut.s_axis_tvalid.value = 0

    await tb.reset()
    tb.clear()

    frame = itch.build_frame(std_messages(), mold_seqnum=8000)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, exp_framed = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    compare_events(tb.events, exp, dut)

    count, mismatch = tb.pkt_done_snaps[-1]
    assert count == exp_framed and mismatch == 0


# ===========================================================================
# 12. Length mismatch
# ===========================================================================
@cocotb.test()
async def test_length_mismatch(dut):
    """
    An Add Order carried in a 40-byte block instead of 37.

    The length field is authoritative for framing, so the parser consumes 40
    bytes and decodes the first 37 correctly - but len_mismatch flags that
    the wire length disagrees with the spec. Two independent sources for the
    same fact, which is the point of carrying the type table in hardware.
    """
    tb = ItchTb(dut)
    await tb.start()

    body = itch.msg_add_order(ts=1, order_id=ORD1, book=BOOK, side="B")
    body = body + b"\x00\x00\x00"          # 37 -> 40 bytes
    assert len(body) == 40

    frame = itch.build_frame([body], mold_seqnum=1)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 1
    compare_events(tb.events, exp, dut)

    g = tb.events[0]
    assert g["length"] == 40, "msg_length reports the WIRE length"
    assert (g["status"] >> itch.ST_LEN_MISMATCH) & 1 == 1, "len_mismatch not set"
    assert (g["status"] >> itch.ST_DECODED) & 1 == 1, (
        "an over-long Add Order is still decoded - fields sit at fixed offsets")


# ===========================================================================
# EDGE CASES
# ===========================================================================

# ---------------------------------------------------------------------------
# 13. Unknown type
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_unknown_type(dut):
    """
    A type byte that is not in the message table.

    Framing still works - it depends only on the length chain - so the parser
    consumes the message cleanly and flags the type rather than losing sync.
    """
    tb = ItchTb(dut)
    await tb.start()

    body = b"X" + bytes(17)                # 18 bytes, type 'X'
    messages = [body,
                itch.msg_add_order(ts=5, order_id=ORD1, book=BOOK, side="B")]

    frame = itch.build_frame(messages, mold_seqnum=300)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 2
    compare_events(tb.events, exp, dut)

    g = tb.events[0]
    assert (g["status"] >> itch.ST_UNKNOWN_TYPE) & 1 == 1, "unknown_type not set"
    assert (g["status"] >> itch.ST_DECODED) & 1 == 0
    assert g["fields"] == 0

    # framing survived: the following Add Order is intact
    assert tb.events[1]["type"] == ord("A"), (
        "an unknown type must not desynchronise the length chain")


# ---------------------------------------------------------------------------
# 14. Two messages completing in one beat
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_double_completion(dut):
    """
    The case the 'T is clock state' decision exists to handle.

    A Tick Size block is 27 bytes. Starting at frame byte 62 it ends at byte
    88, which is beat 11 lane 0. The following Seconds block is 7 bytes and
    ends at byte 95 - beat 11 lane 7. Two messages therefore complete in the
    SAME beat.

    Because Seconds emits nothing, only one event fires and multi_complete
    must stay clear. If T were emitted like any other message this packet
    would need two events in one cycle.
    """
    tb = ItchTb(dut)
    await tb.start()

    messages = [
        itch.msg_tick_size(ts=1, book=BOOK),        # block 27
        itch.msg_seconds(1_600_000_000),            # block 7
        itch.msg_add_order(ts=2, order_id=ORD1, book=BOOK, side="B"),
    ]

    frame = itch.build_frame(messages, mold_seqnum=400)

    # confirm the alignment this test depends on
    end_l = 62 + 27 - 1
    end_t = end_l + 7
    assert end_l // 8 == end_t // 8, (
        f"messages must end in the same beat: byte {end_l} is beat "
        f"{end_l // 8}, byte {end_t} is beat {end_t // 8}")
    dut._log.info("Tick Size ends byte %d, Seconds ends byte %d, both beat %d",
                  end_l, end_t, end_l // 8)

    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, exp_secs, exp_framed = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.events) == 2, (
        f"expected 2 events (L and A; T suppressed), saw {len(tb.events)}")
    compare_events(tb.events, exp, dut)

    for g in tb.events:
        assert (g["status"] >> itch.ST_MULTI_COMPLETE) & 1 == 0, (
            "multi_complete set - two EMITTING messages landed in one beat, "
            "which the T special case is supposed to make impossible")

    assert safe_int(dut.exchange_seconds) == exp_secs
    count, _ = tb.pkt_done_snaps[0]
    assert count == 3


# ---------------------------------------------------------------------------
# 15. A message larger than the assembly buffer
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_large_undecoded(dut):
    """
    An Order Book Directory is 113 bytes - well past the 64-byte assembly
    buffer. It is framed and counted correctly but never decoded, so nothing
    is lost.

    The message after it proves framing stayed in sync across a message the
    buffer could not hold.
    """
    tb = ItchTb(dut)
    await tb.start()

    r_msg = b"R" + bytes(112)              # 113 bytes, matches the spec length
    assert len(r_msg) == 113

    messages = [r_msg,
                itch.msg_order_delete(ts=9, order_id=ORD1, book=BOOK, side="S")]

    frame = itch.build_frame(messages, mold_seqnum=600)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, exp_framed = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 2
    compare_events(tb.events, exp, dut)

    g = tb.events[0]
    assert g["type"] == ord("R")
    assert g["length"] == 113
    assert (g["status"] >> itch.ST_DECODED) & 1 == 0
    assert (g["status"] >> itch.ST_LEN_MISMATCH) & 1 == 0, (
        "113 is the correct spec length for R")

    assert tb.events[1]["type"] == ord("D"), (
        "framing must stay in sync across an oversized message")


# ---------------------------------------------------------------------------
# 16. Frame ends inside a message body
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_truncated_mid_message(dut):
    """
    The frame is cut inside an Add Order's data.

    The partial message is still reported, flagged msg_truncated and not
    decoded. Nothing is dropped from the data path.

    The cut is deliberately placed inside the BODY rather than inside a
    length field - a length field cut in half is an unspecified case where
    the RTL and the model currently disagree.
    """
    tb = ItchTb(dut)
    await tb.start()

    messages = [itch.msg_add_order(ts=1, order_id=ORD1, book=BOOK, side="B")]
    full = itch.build_frame(messages, mold_seqnum=700)

    # payload starts at 62; the length field is 62..63, the body 64..100
    frame = pkt.truncate(full, 80)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(full)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)      # forwarded, not dropped

    assert len(tb.events) == 1, (
        f"a truncated message should still be reported, saw {len(tb.events)}")
    compare_events(tb.events, exp, dut)

    g = tb.events[0]
    assert (g["status"] >> itch.ST_MSG_TRUNCATED) & 1 == 1, "msg_truncated not set"
    assert (g["status"] >> itch.ST_DECODED) & 1 == 0, (
        "a truncated message must not be decoded")
    assert g["type"] == ord("A")
    assert g["length"] == 37, "msg_length reports what the header claimed"


# ---------------------------------------------------------------------------
# 17. Mold count disagrees with the length chain
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_count_mismatch(dut):
    """
    The Mold header claims 5 messages; the payload contains 2.

    Framing follows the LENGTH CHAIN, so both messages are parsed correctly
    and the disagreement is reported rather than causing the parser to walk
    off the end chasing three messages that do not exist.
    """
    tb = ItchTb(dut)
    await tb.start()

    messages = [itch.msg_add_order(ts=1, order_id=1, book=BOOK, side="B"),
                itch.msg_order_delete(ts=2, order_id=1, book=BOOK, side="B")]

    frame = itch.build_frame(messages, mold_seqnum=800, mold_msg_count=5)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, exp_framed = itch.expected_events(frame)

    await tb.drive(beats, upstream)
    await tb.drain()

    tb.check_passthrough(beats)

    assert len(tb.events) == 2, (
        f"the length chain holds 2 messages, saw {len(tb.events)} events")
    compare_events(tb.events, exp, dut)

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 2, f"pkt_msg_count: got {count}, expected 2"
    assert mismatch == 1, (
        "pkt_count_mismatch should be set when the Mold count disagrees "
        "with the framed count")


# ---------------------------------------------------------------------------
# 18. Long burst
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_long_burst(dut):
    """
    Twenty Order Delete messages in one packet.

    Block size is 20 bytes, so message boundaries land on every byte offset
    modulo 8 in turn - which means length fields straddling beat boundaries
    happen repeatedly rather than by luck.
    """
    tb = ItchTb(dut)
    await tb.start()

    n = 20
    messages = [itch.msg_order_delete(ts=i, order_id=1000 + i, book=BOOK,
                                      side="B" if i % 2 == 0 else "S")
                for i in range(n)]

    frame = itch.build_frame(messages, mold_seqnum=10_000)
    beats = pkt.to_beats(frame)
    upstream = expected_pkt_fields(frame)
    exp, _, exp_framed = itch.expected_events(frame)

    dut._log.info("frame %d bytes, %d beats, %d messages",
                  len(frame), len(beats), n)

    await tb.drive(beats, upstream)
    await tb.drain(DRAIN_CYCLES + n)

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.events) == n, f"expected {n} events, saw {len(tb.events)}"
    compare_events(tb.events, exp, dut)

    # indices and sequences must be strictly consecutive
    assert [g["index"] for g in tb.events] == list(range(n))
    assert [g["seqnum"] for g in tb.events] == list(range(10_000, 10_000 + n))

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == n and mismatch == 0
