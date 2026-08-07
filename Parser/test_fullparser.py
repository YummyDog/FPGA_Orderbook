"""
cocotb testbench for fullparser - all five stages chained.

    eth_parser -> ipv4_parser -> udp_parser -> mold_parser -> itch_parser

Nothing is driven into any s_fields: every field on the 523-bit bus and every
ITCH event was produced by real hardware. This is the test of the assembled
pipeline, not of the individual extraction logic.

Core cases:

  1  test_single_asx_packet       T, A, D, E end to end
  2  test_vlan_tagged             a tag steers all five stages
  3  test_all_decoded_types       A F E C U D P
  4  test_undecoded_types         S O L Z
  5  test_heartbeat               Mold count 0, no payload, no events
  6  test_seconds_only            framed, sequenced, never emitted
  7  test_back_to_back            two packets, zero idle
  8  test_alternating_vlan        vlan_present must track per packet
  9  test_tvalid_gaps             bubbles through every stage at once
 10  test_sequence_numbering      Seconds interspersed
 11  test_reset_mid_packet        whole pipeline recovers together
 12  test_all_asx_partitions      all 8 ASX endpoints

Edge cases:

 13  test_double_completion       two messages complete in ONE beat
 14  test_unknown_type            a type byte outside the table
 15  test_large_undecoded         R at 113 bytes, past the assembly buffer
 16  test_truncated_mid_message   frame ends inside a message body
 17  test_truncated_before_mold   frame ends inside the Mold header
 18  test_count_mismatch          Mold count disagrees with the length chain
 19  test_ihl_options             IHL=6 shifts everything below IPv4
 20  test_long_burst              20 messages in one packet

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import asx_packets as pkt
import ipv4_model as ip4
import udp_model as udp
import mold_model as mold
import itch_model as itch

CLK_PERIOD_NS = 6.4          # 156.25 MHz
DRAIN_CYCLES = 32            # let trailing events emerge

BOOK = 85603
ORD1 = 0x0621F1282E5ED
MATCH = 0x0123456789ABCDEF01234567


def safe_int(handle):
    try:
        return int(handle.value)
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Expected field bus
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


def expected_pkt_fields(frame, tagged=False, vlan_tci=0) -> int:
    upstream = mold.upstream_field_vector(frame, tagged=tagged,
                                          vlan_tci=vlan_tci)
    m = pack_mold_fields(mold.expected_mold_fields(frame, tagged=tagged))
    return (m << mold.MOLD_BASE) | upstream


def decode_eth(bus: int) -> dict:
    return {
        "dst_mac": (bus >> ip4.E_DST_MAC_LO) & ((1 << 48) - 1),
        "src_mac": (bus >> ip4.E_SRC_MAC_LO) & ((1 << 48) - 1),
        "ethertype": (bus >> ip4.E_ETHERTYPE_LO) & 0xFFFF,
        "vlan_tci": (bus >> ip4.E_VLAN_TCI_LO) & 0xFFFF,
        "vlan_present": (bus >> ip4.E_VLAN_PRESENT_LO) & 1,
        "hdr_truncated": (bus >> ip4.E_TRUNC_LO) & 1,
    }


def decode_all(bus: int) -> dict:
    return {
        "eth": decode_eth(bus),
        "ipv4": ip4.decode_ipv4_fields(ip4.ipv4_slice_of(bus)),
        "udp": udp.decode_udp_fields(udp.udp_slice_of(bus)),
        "mold": mold.decode_mold_fields(mold.mold_slice_of(bus)),
    }


def trunc_quad(bus: int):
    d = decode_all(bus)
    return (d["eth"]["hdr_truncated"], d["ipv4"]["hdr_truncated"],
            d["udp"]["hdr_truncated"], d["mold"]["hdr_truncated"])


def check_fields(got, expected, subset=None, ctx=""):
    for name in (subset if subset else expected.keys()):
        assert got[name] == expected[name], (
            f"{ctx}{name}: got {got[name]:#x}, expected {expected[name]:#x}")


def check_upstream(bus, frame, dut, tagged=False, vlan_tci=0, ctx=""):
    """Verify all four header slices decoded by real hardware."""
    got = decode_all(bus)
    check_fields(got["eth"],
                 pkt.expected_eth_fields(frame, vlan_vid=(vlan_tci & 0xFFF)
                                         if tagged else None,
                                         tagged=tagged),
                 ctx=ctx + "eth ")
    check_fields(got["ipv4"], ip4.expected_ipv4_fields(frame, tagged=tagged),
                 ctx=ctx + "ipv4 ")
    check_fields(got["udp"], udp.expected_udp_fields(frame, tagged=tagged),
                 ctx=ctx + "udp ")
    check_fields(got["mold"], mold.expected_mold_fields(frame, tagged=tagged),
                 ctx=ctx + "mold ")
    return got


# ---------------------------------------------------------------------------
# Event comparison
# ---------------------------------------------------------------------------
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


def std_messages():
    return [
        itch.msg_seconds(1_700_000_000),
        itch.msg_add_order(ts=1234, order_id=ORD1, book=BOOK, side="B",
                           position=1, quantity=1000, price=55000, lot=2),
        itch.msg_order_delete(ts=2345, order_id=ORD1, book=BOOK, side="B"),
        itch.msg_order_executed(ts=3456, order_id=ORD1 + 1, book=BOOK,
                                side="S", qty=250, match_id=MATCH),
    ]


# ---------------------------------------------------------------------------
# Testbench harness
# ---------------------------------------------------------------------------
class FullTb:
    def __init__(self, dut):
        self.dut = dut
        self.out_beats = []
        self.events = []
        self.pkt_done_snaps = []
        self.stage_pulses = {"eth": 0, "ipv4": 0, "udp": 0, "mold": 0}

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
        d.m_axis_tready.value = 1      # ignored by the DUT
        d.resetn.value = 0
        for _ in range(cycles):
            await RisingEdge(d.clk)
        d.resetn.value = 1
        await RisingEdge(d.clk)

    def clear(self):
        self.out_beats.clear()
        self.events.clear()
        self.pkt_done_snaps.clear()
        for k in self.stage_pulses:
            self.stage_pulses[k] = 0

    async def _monitor(self):
        d = self.dut
        while True:
            await RisingEdge(d.clk)
            await ReadOnly()

            for k, h in (("eth", d.eth_fields_valid),
                         ("ipv4", d.ipv4_fields_valid),
                         ("udp", d.udp_fields_valid),
                         ("mold", d.mold_fields_valid)):
                if safe_int(h) == 1:
                    self.stage_pulses[k] += 1

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

    async def drive(self, beats, gaps=None, idle_after=True):
        d = self.dut
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

    def check_stage_pulses(self, n_packets: int):
        for k, v in self.stage_pulses.items():
            assert v == n_packets, (
                f"{k}_fields_valid pulsed {v} times, expected {n_packets}")


# ===========================================================================
# 1. Baseline
# ===========================================================================
@cocotb.test()
async def test_single_asx_packet(dut):
    """T, A, D, E through all five stages. Nothing is driven but the beats."""
    tb = FullTb(dut)
    await tb.start()

    frame = itch.build_frame(std_messages(), mold_seqnum=1000)
    beats = pkt.to_beats(frame)
    exp, exp_secs, exp_framed = itch.expected_events(frame)

    dut._log.info("frame %d bytes, %d beats", len(frame), len(beats))

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    tb.check_stage_pulses(1)

    compare_events(tb.events, exp, dut)

    bus = tb.events[0]["pkt_fields"]
    got = check_upstream(bus, frame, dut)
    assert bus == expected_pkt_fields(frame), "full 523-bit bus mismatch"
    assert trunc_quad(bus) == (0, 0, 0, 0)

    for g in tb.events:
        assert g["pkt_fields"] == bus, "pkt_fields differs between events"

    dut._log.info("eth  dst_mac %012x", got["eth"]["dst_mac"])
    dut._log.info("ipv4 dst_ip  %08x", got["ipv4"]["dst_ip"])
    dut._log.info("udp  dst_port %d", got["udp"]["dst_port"])
    dut._log.info("mold seq %d count %d", got["mold"]["sequence_num"],
                  got["mold"]["message_count"])

    assert safe_int(dut.exchange_seconds) == exp_secs
    count, mismatch = tb.pkt_done_snaps[0]
    assert count == exp_framed and mismatch == 0
    assert tb.events[0]["seqnum"] == 1001, "the suppressed T must consume 1000"


# ===========================================================================
# 2. VLAN tagged
# ===========================================================================
@cocotb.test()
async def test_vlan_tagged(dut):
    """
    A tag detected by eth_parser must steer all four downstream stages, and
    move the ITCH payload from byte 62 to byte 66.
    """
    tb = FullTb(dut)
    await tb.start()

    vid = 100
    tci = pkt.make_tci(vid=vid)
    frame = itch.build_frame(std_messages(), mold_seqnum=2000, vlan_vid=vid)
    beats = pkt.to_beats(frame)
    exp, exp_secs, exp_framed = itch.expected_events(frame, tagged=True)

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    tb.check_stage_pulses(1)

    compare_events(tb.events, exp, dut)

    bus = tb.events[0]["pkt_fields"]
    got = check_upstream(bus, frame, dut, tagged=True, vlan_tci=tci)
    assert got["eth"]["vlan_present"] == 1
    assert got["eth"]["ethertype"] == pkt.ETHERTYPE_IPV4, "TPID leaked"
    assert got["udp"]["dst_port"] == pkt.ASX_DST_PORT, "UDP read wrong offset"
    assert bus == expected_pkt_fields(frame, tagged=True, vlan_tci=tci)
    assert trunc_quad(bus) == (0, 0, 0, 0)
    assert tb.events[0]["seqnum"] == 2001


# ===========================================================================
# 3. Every decoded type
# ===========================================================================
@cocotb.test()
async def test_all_decoded_types(dut):
    """A F E C U D P through the whole chain - all seven decode layouts."""
    tb = FullTb(dut)
    await tb.start()

    messages = [
        itch.msg_add_order(ts=11, order_id=1, book=BOOK, side="B",
                           position=1, quantity=100, price=1000),
        itch.msg_add_order_pid(ts=22, order_id=2, book=BOOK, side="S",
                               position=2, quantity=200, price=2000),
        itch.msg_order_executed(ts=33, order_id=1, book=BOOK, side="B",
                                qty=50, match_id=MATCH),
        itch.msg_order_executed_price(ts=44, order_id=2, book=BOOK, side="S",
                                      qty=60, match_id=MATCH + 1, price=2001),
        itch.msg_order_replace(ts=55, order_id=1, book=BOOK, side="B",
                               position=3, quantity=300, price=3000),
        itch.msg_order_delete(ts=66, order_id=2, book=BOOK, side="S"),
        itch.msg_trade(ts=77, match_id=MATCH + 2, side="B", qty=400,
                       book=BOOK, price=4000),
    ]

    frame = itch.build_frame(messages, mold_seqnum=500)
    beats = pkt.to_beats(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 7
    compare_events(tb.events, exp, dut)

    for g in tb.events:
        assert (g["status"] >> itch.ST_DECODED) & 1 == 1
    assert tb.events[0]["seqnum"] == 500


# ===========================================================================
# 4. Undecoded types
# ===========================================================================
@cocotb.test()
async def test_undecoded_types(dut):
    """S, O, L, Z framed and reported, but never decoded."""
    tb = FullTb(dut)
    await tb.start()

    messages = [itch.msg_system_event(ts=1),
                itch.msg_order_book_state(ts=2, book=BOOK),
                itch.msg_tick_size(ts=3, book=BOOK),
                itch.msg_equilibrium(ts=4, book=BOOK)]

    frame = itch.build_frame(messages, mold_seqnum=100)
    beats = pkt.to_beats(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 4
    compare_events(tb.events, exp, dut)

    for g in tb.events:
        assert (g["status"] >> itch.ST_DECODED) & 1 == 0
        assert (g["status"] >> itch.ST_UNKNOWN_TYPE) & 1 == 0
        assert g["fields"] == 0


# ===========================================================================
# 5. Heartbeat
# ===========================================================================
@cocotb.test()
async def test_heartbeat(dut):
    """
    Mold count 0 and no payload. The Mold stage must flag heartbeat, and the
    ITCH stage must emit nothing.
    """
    tb = FullTb(dut)
    await tb.start()

    frame = itch.build_frame([], mold_seqnum=7777, mold_msg_count=0)
    beats = pkt.to_beats(frame)
    assert len(frame) == 62

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    tb.check_stage_pulses(1)

    assert len(tb.events) == 0, f"{len(tb.events)} events on a heartbeat"

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 0 and mismatch == 0

    # the Mold stage still has to report the heartbeat, but no event carries
    # pkt_fields on this packet - check via a following normal packet instead
    dut._log.info("heartbeat: 0 events, pkt_msg_count 0")


# ===========================================================================
# 6. Seconds only
# ===========================================================================
@cocotb.test()
async def test_seconds_only(dut):
    """One Seconds message: framed and sequenced, but never emitted."""
    tb = FullTb(dut)
    await tb.start()

    secs = 1_234_567_890
    frame = itch.build_frame([itch.msg_seconds(secs)], mold_seqnum=55)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 0
    assert safe_int(dut.exchange_seconds) == secs

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 1, "a suppressed message is still framed"
    assert mismatch == 0


# ===========================================================================
# 7. Back to back
# ===========================================================================
@cocotb.test()
async def test_back_to_back(dut):
    """Two packets, zero idle, continuous sequencing."""
    tb = FullTb(dut)
    await tb.start()

    m1 = [itch.msg_add_order(ts=1, order_id=1, book=BOOK, side="B"),
          itch.msg_order_delete(ts=2, order_id=1, book=BOOK, side="B"),
          itch.msg_add_order(ts=3, order_id=2, book=BOOK, side="S")]
    m2 = [itch.msg_order_delete(ts=4, order_id=2, book=BOOK, side="S"),
          itch.msg_add_order(ts=5, order_id=3, book=BOOK, side="B")]

    f1 = itch.build_frame(m1, mold_seqnum=3000)
    f2 = itch.build_frame(m2, mold_seqnum=3003)
    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)

    e1, _, n1 = itch.expected_events(f1)
    e2, _, n2 = itch.expected_events(f2)

    await tb.drive(b1 + b2)
    await tb.drain()

    tb.check_passthrough(b1 + b2)
    tb.check_stage_pulses(2)
    compare_events(tb.events, e1 + e2, dut)

    assert len(tb.pkt_done_snaps) == 2
    assert tb.pkt_done_snaps[0] == (n1, 0)
    assert tb.pkt_done_snaps[1] == (n2, 0)

    assert tb.events[3]["index"] == 0, "msg_index restarts each packet"
    assert tb.events[3]["seqnum"] == 3003, "sequence continues across packets"

    # each packet's events must carry that packet's context
    assert tb.events[0]["pkt_fields"] == expected_pkt_fields(f1)
    assert tb.events[3]["pkt_fields"] == expected_pkt_fields(f2)


# ===========================================================================
# 8. Alternating tagged / untagged
# ===========================================================================
@cocotb.test()
async def test_alternating_vlan(dut):
    """
    Tagged then untagged, back to back. vlan_present must change with the
    packet and steer all five stages on each - the strongest end-to-end test
    of the mux path.
    """
    tb = FullTb(dut)
    await tb.start()

    vid = 42
    tci = pkt.make_tci(vid=vid)
    f1 = itch.build_frame(std_messages(), mold_seqnum=4000, vlan_vid=vid)
    f2 = itch.build_frame(std_messages(), mold_seqnum=4004)

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)
    e1, _, n1 = itch.expected_events(f1, tagged=True)
    e2, _, n2 = itch.expected_events(f2)

    await tb.drive(b1 + b2)
    await tb.drain()

    tb.check_passthrough(b1 + b2)
    tb.check_stage_pulses(2)
    compare_events(tb.events, e1 + e2, dut)

    g0 = decode_all(tb.events[0]["pkt_fields"])
    g1 = decode_all(tb.events[3]["pkt_fields"])

    assert g0["eth"]["vlan_present"] == 1, "packet 0 should be tagged"
    assert g1["eth"]["vlan_present"] == 0, "vlan_present leaked into packet 1"
    assert g1["eth"]["vlan_tci"] == 0, "vlan_tci leaked into packet 1"

    assert g0["udp"]["dst_port"] == pkt.ASX_DST_PORT
    assert g1["udp"]["dst_port"] == pkt.ASX_DST_PORT
    assert g0["mold"]["sequence_num"] == 4000
    assert g1["mold"]["sequence_num"] == 4004


# ===========================================================================
# 9. tvalid bubbles
# ===========================================================================
@cocotb.test()
async def test_tvalid_gaps(dut):
    """Bubbles straddling every stage's header region at once."""
    tb = FullTb(dut)
    await tb.start()

    frame = itch.build_frame(std_messages(), mold_seqnum=1000)
    beats = pkt.to_beats(frame)
    exp, exp_secs, _ = itch.expected_events(frame)

    gaps = [0] * len(beats)
    for i in (1, 3, 5, 7, 9, 13):
        if i < len(gaps):
            gaps[i] = 2

    await tb.drive(beats, gaps=gaps)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    compare_events(tb.events, exp, dut)
    assert tb.events[0]["pkt_fields"] == expected_pkt_fields(frame)
    assert safe_int(dut.exchange_seconds) == exp_secs


# ===========================================================================
# 10. Sequence numbering across suppressed messages
# ===========================================================================
@cocotb.test()
async def test_sequence_numbering(dut):
    """
    Seconds interspersed: six framed, three emitted, indices 1, 3, 5.

    The Mold stage supplies the base sequence and the ITCH stage adds the
    index, so this checks the two stages agree end to end.
    """
    tb = FullTb(dut)
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
    exp, _, exp_framed = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 3
    compare_events(tb.events, exp, dut)

    assert [g["index"] for g in tb.events] == [1, 3, 5]
    assert [g["seqnum"] for g in tb.events] == [9001, 9003, 9005]
    assert safe_int(dut.exchange_seconds) == 1002, "should hold the LAST value"

    count, _ = tb.pkt_done_snaps[0]
    assert count == 6


# ===========================================================================
# 11. Reset mid-packet
# ===========================================================================
@cocotb.test()
async def test_reset_mid_packet(dut):
    """All five stages must recover together from a mid-frame reset."""
    tb = FullTb(dut)
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
    exp, _, exp_framed = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)
    tb.check_stage_pulses(1)
    compare_events(tb.events, exp, dut)

    bus = tb.events[0]["pkt_fields"]
    assert bus == expected_pkt_fields(frame)
    assert trunc_quad(bus) == (0, 0, 0, 0), "reset left status bits set"

    count, mismatch = tb.pkt_done_snaps[-1]
    assert count == exp_framed and mismatch == 0


# ===========================================================================
# 12. All ASX endpoints
# ===========================================================================
@cocotb.test()
async def test_all_asx_partitions(dut):
    """
    One packet per ASX endpoint, back to back. Each has its own multicast
    group, destination MAC, UDP port and sequence space.
    """
    tb = FullTb(dut)
    await tb.start()

    all_beats = []
    expects = []
    seq = 100

    for name, src_ip, grp_ip, port in pkt.ASX_CHANNELS:
        f = itch.build_frame(
            [itch.msg_add_order(ts=1, order_id=seq, book=BOOK, side="B")],
            src_ip=src_ip, dst_ip=grp_ip, udp_dst_port=port, mold_seqnum=seq)
        all_beats += pkt.to_beats(f)
        ev, _, n = itch.expected_events(f)
        expects.append((name, grp_ip, port, seq, f, ev))
        seq += 100

    await tb.drive(all_beats)
    await tb.drain()

    tb.check_passthrough(all_beats)
    tb.check_stage_pulses(len(pkt.ASX_CHANNELS))

    flat = [e for *_, ev in expects for e in ev]
    compare_events(tb.events, flat, dut)

    for n, (name, grp_ip, port, s, f, _) in enumerate(expects):
        g = decode_all(tb.events[n]["pkt_fields"])
        assert g["udp"]["dst_port"] == port, f"{name}: dst_port wrong"
        assert g["mold"]["sequence_num"] == s, f"{name}: sequence wrong"
        assert tb.events[n]["pkt_fields"] == expected_pkt_fields(f)
        dut._log.info("%s  dst_mac %012x  dst_ip %08x  port %d  seq %d",
                      name, g["eth"]["dst_mac"], g["ipv4"]["dst_ip"],
                      port, s)


# ===========================================================================
# EDGE CASES
# ===========================================================================

# ---------------------------------------------------------------------------
# 13. Two messages completing in one beat
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_double_completion(dut):
    """
    A 27-byte Tick Size block starting at byte 62 ends at byte 88; the
    following 7-byte Seconds block ends at byte 95. Both are in beat 11.

    Only one event fires because Seconds emits nothing. This is the case the
    T special case exists to make safe.
    """
    tb = FullTb(dut)
    await tb.start()

    messages = [itch.msg_tick_size(ts=1, book=BOOK),
                itch.msg_seconds(1_600_000_000),
                itch.msg_add_order(ts=2, order_id=ORD1, book=BOOK, side="B")]

    frame = itch.build_frame(messages, mold_seqnum=400)

    end_l = 62 + 27 - 1
    end_t = end_l + 7
    assert end_l // 8 == end_t // 8, (
        f"messages must end in the same beat: {end_l} -> beat {end_l // 8}, "
        f"{end_t} -> beat {end_t // 8}")
    dut._log.info("Tick Size ends byte %d, Seconds ends byte %d, both beat %d",
                  end_l, end_t, end_l // 8)

    beats = pkt.to_beats(frame)
    exp, exp_secs, exp_framed = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.events) == 2, (
        f"expected 2 events (L and A; T suppressed), saw {len(tb.events)}")
    compare_events(tb.events, exp, dut)

    for g in tb.events:
        assert (g["status"] >> itch.ST_MULTI_COMPLETE) & 1 == 0, (
            "multi_complete set - two EMITTING messages in one beat")

    assert [g["index"] for g in tb.events] == [0, 2]
    assert safe_int(dut.exchange_seconds) == exp_secs
    assert tb.pkt_done_snaps[0] == (3, 0)


# ---------------------------------------------------------------------------
# 14. Unknown message type
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_unknown_type(dut):
    """
    A type byte outside the table. Framing depends only on the length chain,
    so the parser consumes it cleanly and the following message is intact.
    """
    tb = FullTb(dut)
    await tb.start()

    messages = [b"X" + bytes(17),
                itch.msg_add_order(ts=5, order_id=ORD1, book=BOOK, side="B")]

    frame = itch.build_frame(messages, mold_seqnum=300)
    beats = pkt.to_beats(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 2
    compare_events(tb.events, exp, dut)

    assert (tb.events[0]["status"] >> itch.ST_UNKNOWN_TYPE) & 1 == 1
    assert tb.events[0]["fields"] == 0
    assert tb.events[1]["type"] == ord("A"), (
        "an unknown type must not desynchronise the length chain")


# ---------------------------------------------------------------------------
# 15. A message past the assembly buffer
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_large_undecoded(dut):
    """
    An Order Book Directory is 113 bytes, past the 64-byte assembly buffer.
    Framed and counted, never decoded, and framing stays in sync.
    """
    tb = FullTb(dut)
    await tb.start()

    r_msg = b"R" + bytes(112)
    messages = [r_msg,
                itch.msg_order_delete(ts=9, order_id=ORD1, book=BOOK, side="S")]

    frame = itch.build_frame(messages, mold_seqnum=600)
    beats = pkt.to_beats(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 2
    compare_events(tb.events, exp, dut)

    assert tb.events[0]["length"] == 113
    assert (tb.events[0]["status"] >> itch.ST_DECODED) & 1 == 0
    assert (tb.events[0]["status"] >> itch.ST_LEN_MISMATCH) & 1 == 0
    assert tb.events[1]["type"] == ord("D")


# ---------------------------------------------------------------------------
# 16. Frame ends inside a message body
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_truncated_mid_message(dut):
    """
    Cut at 80 bytes, inside an Add Order's body.

    All four header stages complete - the headers end at byte 61 - so only
    the ITCH message is short. The truncation quad must read (0,0,0,0) with
    the shortfall reported on the message instead.

    The cut is inside the BODY, not a length field: a length field cut in
    half is an unspecified case where RTL and model currently disagree.
    """
    tb = FullTb(dut)
    await tb.start()

    full = itch.build_frame(
        [itch.msg_add_order(ts=1, order_id=ORD1, book=BOOK, side="B")],
        mold_seqnum=700)
    frame = pkt.truncate(full, 80)
    beats = pkt.to_beats(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)      # forwarded, not dropped

    assert len(tb.events) == 1
    compare_events(tb.events, exp, dut)

    g = tb.events[0]
    assert (g["status"] >> itch.ST_MSG_TRUNCATED) & 1 == 1
    assert (g["status"] >> itch.ST_DECODED) & 1 == 0
    assert g["type"] == ord("A") and g["length"] == 37

    assert trunc_quad(g["pkt_fields"]) == (0, 0, 0, 0), (
        "all four headers fit in 80 bytes - only the ITCH message is short")


# ---------------------------------------------------------------------------
# 17. Frame ends inside the Mold header
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_truncated_before_mold(dut):
    """
    Cut at 56 bytes: Ethernet, IPv4 and UDP all complete, Mold does not, and
    there is no ITCH payload at all.

    Demonstrates the nested truncation bits across the assembled pipeline -
    something the standalone testbenches could only fake.
    """
    tb = FullTb(dut)
    await tb.start()

    full = itch.build_frame(std_messages(), mold_seqnum=900)
    frame = pkt.truncate(full, 56)
    beats = pkt.to_beats(frame)
    assert len(beats) == 7

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.events) == 0, (
        f"no payload survives a 56-byte frame, but {len(tb.events)} events fired")

    assert len(tb.pkt_done_snaps) == 1
    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 0, f"pkt_msg_count: got {count}, expected 0"
    # the Mold header never completed, so its message_count is stale/zero and
    # a mismatch against 0 framed messages is expected either way
    dut._log.info("truncated before Mold: 0 events, count %d, mismatch %d",
                  count, mismatch)


# ---------------------------------------------------------------------------
# 18. Mold count disagrees with the length chain
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_count_mismatch(dut):
    """
    The Mold header claims 5 messages; the payload holds 2. Framing follows
    the length chain, so both parse and the disagreement is reported.
    """
    tb = FullTb(dut)
    await tb.start()

    messages = [itch.msg_add_order(ts=1, order_id=1, book=BOOK, side="B"),
                itch.msg_order_delete(ts=2, order_id=1, book=BOOK, side="B")]

    frame = itch.build_frame(messages, mold_seqnum=800, mold_msg_count=5)
    beats = pkt.to_beats(frame)
    exp, _, _ = itch.expected_events(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_passthrough(beats)
    assert len(tb.events) == 2
    compare_events(tb.events, exp, dut)

    g = decode_all(tb.events[0]["pkt_fields"])
    assert g["mold"]["message_count"] == 5, "Mold must report what it read"

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == 2 and mismatch == 1, (
        f"expected (2, 1), got ({count}, {mismatch})")


# ---------------------------------------------------------------------------
# 19. IPv4 options shift everything below
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_ihl_options(dut):
    """
    IHL=6 adds 4 bytes of IPv4 options, so UDP, Mold and the ITCH payload all
    sit 4 bytes further on than the fixed offsets assume.

    The IPv4 stage is entirely correct and raises ihl_invalid. Everything
    below it reads the wrong bytes - the documented cost of not supporting
    options. Nothing is gated and the pipeline must not hang.

    Only the IPv4 slice and the data path are asserted; what the lower stages
    make of the shifted bytes is undefined by design.
    """
    tb = FullTb(dut)
    await tb.start()

    frame = itch.build_frame(std_messages(), mold_seqnum=1000, ihl=6)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.drain()

    tb.check_tready()
    tb.check_passthrough(beats)      # nothing dropped
    tb.check_stage_pulses(1)         # every stage still completes

    assert len(tb.pkt_done_snaps) == 1, "the pipeline must still finish the packet"

    if tb.events:
        g = decode_all(tb.events[0]["pkt_fields"])
        check_fields(g["ipv4"], ip4.expected_ipv4_fields(frame), ctx="ipv4 ")
        assert g["ipv4"]["ihl_invalid"] == 1, "ihl_invalid not raised"
        assert g["udp"]["dst_port"] != pkt.ASX_DST_PORT, (
            "expected UDP to be misparsed with options present")
        dut._log.info("IHL=6: ihl_invalid=1, udp dst_port read as %d "
                      "(true port is %d), %d ITCH events",
                      g["udp"]["dst_port"], pkt.ASX_DST_PORT, len(tb.events))
    else:
        dut._log.info("IHL=6: no ITCH events - the shifted payload did not "
                      "frame into anything")


# ---------------------------------------------------------------------------
# 20. Long burst
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_long_burst(dut):
    """
    Twenty Order Deletes in one packet. Block size 20 means message
    boundaries land on every offset modulo 8 in turn, so length fields
    straddling beat boundaries happen repeatedly rather than by luck.
    """
    tb = FullTb(dut)
    await tb.start()

    n = 20
    messages = [itch.msg_order_delete(ts=i, order_id=1000 + i, book=BOOK,
                                      side="B" if i % 2 == 0 else "S")
                for i in range(n)]

    frame = itch.build_frame(messages, mold_seqnum=10_000)
    beats = pkt.to_beats(frame)
    exp, _, exp_framed = itch.expected_events(frame)

    dut._log.info("frame %d bytes, %d beats, %d messages",
                  len(frame), len(beats), n)

    await tb.drive(beats)
    await tb.drain(DRAIN_CYCLES + n)

    tb.check_tready()
    tb.check_passthrough(beats)
    tb.check_stage_pulses(1)

    assert len(tb.events) == n
    compare_events(tb.events, exp, dut)

    assert [g["index"] for g in tb.events] == list(range(n))
    assert [g["seqnum"] for g in tb.events] == list(range(10_000, 10_000 + n))

    bus = expected_pkt_fields(frame)
    for g in tb.events:
        assert g["pkt_fields"] == bus, "pkt_fields must be identical per packet"

    count, mismatch = tb.pkt_done_snaps[0]
    assert count == n and mismatch == 0
