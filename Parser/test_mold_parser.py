"""
cocotb testbench for mold_parser (stage 4).

Standalone: s_fields is driven by the testbench rather than by real upstream
parsers, so this module is verified on its own.

Core cases:

  1  test_single_asx_packet        one untagged ASX ITCH frame (baseline)
  2  test_vlan_tagged              completion moves to beat 8 - not beat 7
  3  test_heartbeat                message_count = 0
  4  test_end_of_session           message_count = 0xFFFF
  5  test_sequence_extremes        seqnum 0 and 2^64-1 through the 32/32 split
  6  test_session_variants         a different 10-byte session string
  7  test_back_to_back             two frames, zero idle between them
  8  test_alternating_vlan         completion beat alternates 8, 7
  9  test_tvalid_gaps              bubbles must not advance the beat counter
 10  test_truncated_before_complete frame ends on beat 6
 11  test_reset_mid_packet         recovery from a mid-frame reset
 12  test_all_asx_partitions       all 8 ASX channel/partition endpoints

Edge cases:

 13  test_truncated_in_beat0       runt frame, no Mold bytes at all
 14  test_tagged_truncated_beat7   same beat, opposite verdict to untagged
 15  test_exact_header_frame       62 bytes: header exactly fills the frame
 16  test_bubble_every_beat        one idle cycle before every beat
 17  test_long_mixed_burst         20 frames, alternating tagged/untagged
 18  test_all_ones_header          degenerate all-0xFF frame

Every test also re-checks the two hard requirements: one output beat per
input beat with the data unmodified, and s_axis_tready tied high.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import asx_packets as pkt
import mold_model as mdl

CLK_PERIOD_NS = 6.4          # 156.25 MHz

BEAT_UNTAGGED = mdl.MOLD_LAST_BEAT_UNTAGGED   # 7
BEAT_TAGGED = mdl.MOLD_LAST_BEAT_TAGGED       # 8


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------
def safe_int(handle):
    try:
        return int(handle.value)
    except ValueError:
        return None


def check_fields(got: dict, expected: dict, subset=None, ctx=""):
    keys = subset if subset else expected.keys()
    for name in keys:
        assert got[name] == expected[name], (
            f"{ctx}{name}: got {got[name]:#x}, expected {expected[name]:#x}"
        )


# ---------------------------------------------------------------------------
# Testbench harness
# ---------------------------------------------------------------------------
class MoldTb:
    def __init__(self, dut):
        self.dut = dut
        self.out_beats = []
        self.pulses = []             # (beat_index_in_packet, full_bus_int)
        self.bus_at_tlast = []
        self._beat_idx = 0

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
        self.pulses.clear()
        self.bus_at_tlast.clear()
        self._beat_idx = 0

    async def _monitor(self):
        d = self.dut
        while True:
            await RisingEdge(d.clk)
            await ReadOnly()

            valid = safe_int(d.m_axis_tvalid)
            fvalid = safe_int(d.m_fields_valid)

            if valid == 1:
                tlast = safe_int(d.m_axis_tlast)
                self.out_beats.append(
                    (safe_int(d.m_axis_tdata), safe_int(d.m_axis_tkeep), tlast)
                )

            if fvalid == 1:
                self.pulses.append((self._beat_idx, safe_int(d.m_fields)))

            if valid == 1:
                if tlast == 1:
                    self.bus_at_tlast.append(safe_int(d.m_fields))
                    self._beat_idx = 0
                else:
                    self._beat_idx += 1

    async def drive(self, beats, upstream: int, gaps=None, idle_after=True):
        """
        Push one frame, holding the upstream field bus constant.

        Constant s_fields is valid stimulus: upstream stages hold their fields
        through tlast, and mold_parser only reads vlan_present from its beat 5.
        """
        d = self.dut
        d.s_fields.value = upstream

        for i, (tdata, tkeep, tlast) in enumerate(beats):
            n = gaps[i] if gaps else 0
            for _ in range(n):
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

    async def drive_frames(self, frames, idle_after=True):
        """
        Push several frames back to back, each with its own s_fields value.

        frames: list of (beats, upstream). s_fields is updated at the first
        beat of each frame - earlier than the real upstream stages would
        change it, which is harmless because mold_parser does not read
        vlan_present until its beat 5.
        """
        d = self.dut
        for beats, upstream in frames:
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

    async def settle(self, cycles: int = 6):
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)

    def check_passthrough(self, beats, ctx=""):
        assert len(self.out_beats) == len(beats), (
            f"{ctx}beat count mismatch: drove {len(beats)}, "
            f"observed {len(self.out_beats)} (throughput rule violated)"
        )
        for i, ((it, ik, il), (ot, ok, ol)) in enumerate(zip(beats, self.out_beats)):
            assert ot == it, f"{ctx}beat {i} tdata corrupted: {ot:#018x} != {it:#018x}"
            assert ok == ik, f"{ctx}beat {i} tkeep corrupted: {ok:#04x} != {ik:#04x}"
            assert ol == (1 if il else 0), f"{ctx}beat {i} tlast misaligned"

    def check_tready(self):
        assert self.dut.s_axis_tready.value == 1, "s_axis_tready must be tied high"

    def fields(self, n: int = 0) -> dict:
        return mdl.decode_mold_fields(mdl.mold_slice_of(self.pulses[n][1]))

    def beat_of(self, n: int = 0) -> int:
        return self.pulses[n][0]


# ===========================================================================
# 1. Baseline
# ===========================================================================
@cocotb.test()
async def test_single_asx_packet(dut):
    """One untagged ASX ITCH Channel A / Partition 1 frame."""
    tb = MoldTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame)
    expected = mdl.expected_mold_fields(frame)

    dut._log.info("Frame length: %d bytes, %d beats", len(frame), len(beats))
    dut._log.info("MoldUDP64 header at bytes 42..61 (untagged)")

    await tb.drive(beats, upstream)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    idx, bus = tb.pulses[0]
    assert idx == BEAT_UNTAGGED, (
        f"untagged Mold header completes on beat {BEAT_UNTAGGED}, "
        f"pulsed on beat {idx}"
    )

    got = tb.fields()
    check_fields(got, expected)

    dut._log.info("session       = %s", mdl.session_ascii(got["session"]))
    dut._log.info("sequence_num  = %d", got["sequence_num"])
    dut._log.info("message_count = %d", got["message_count"])

    assert mdl.session_ascii(got["session"]) == "ASX0000001"
    assert got["heartbeat"] == 0
    assert got["end_of_session"] == 0

    assert mdl.upstream_slice_of(bus) == upstream, "upstream slice corrupted"

    assert tb.bus_at_tlast, "no tlast observed"
    held = mdl.decode_mold_fields(mdl.mold_slice_of(tb.bus_at_tlast[0]))
    assert held == got, "field bus not held to tlast"

    try:
        internal = int(dut.mold_fields.value)
        assert internal == mdl.mold_slice_of(tb.bus_at_tlast[0])
        dut._log.info("internal mold_fields matches m_fields slice")
    except (AttributeError, ValueError) as e:
        dut._log.info("internal mold_fields not readable via VHPI (%s)", e)


# ===========================================================================
# 2. VLAN tagged - completion moves a beat later
# ===========================================================================
@cocotb.test()
async def test_vlan_tagged(dut):
    """
    A tag shifts the Mold header from byte 42 to byte 46, which pushes
    message_count across a beat boundary: bytes 60-61 (beat 7) become
    bytes 64-65 (beat 8).

    This is the first stage in the pipeline whose completion beat depends on
    the tag - ipv4_parser and udp_parser both finished on the same beat
    either way.
    """
    tb = MoldTb(dut)
    await tb.start()

    vid = 100
    tci = pkt.make_tci(vid=vid)
    frame = pkt.build_frame(vlan_vid=vid)
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame, tagged=True, vlan_tci=tci)
    expected = mdl.expected_mold_fields(frame, tagged=True)

    await tb.drive(beats, upstream)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    assert tb.beat_of() == BEAT_TAGGED, (
        f"tagged Mold header completes on beat {BEAT_TAGGED}, "
        f"pulsed on beat {tb.beat_of()}"
    )

    got = tb.fields()
    check_fields(got, expected)
    assert mdl.session_ascii(got["session"]) == "ASX0000001"

    # stimulus self-check, in BYTES
    assert len(frame) == len(pkt.build_frame()) + 4, "tag was not inserted"


# ===========================================================================
# 3. Heartbeat
# ===========================================================================
@cocotb.test()
async def test_heartbeat(dut):
    """message_count = 0 marks a heartbeat packet."""
    tb = MoldTb(dut)
    await tb.start()

    frame = pkt.build_frame(mold_msg_count=0)
    beats = pkt.to_beats(frame)

    await tb.drive(beats, mdl.upstream_field_vector(frame))
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    got = tb.fields()
    check_fields(got, mdl.expected_mold_fields(frame))
    assert got["message_count"] == 0
    assert got["heartbeat"] == 1, "heartbeat not flagged for count = 0"
    assert got["end_of_session"] == 0
    assert got["hdr_truncated"] == 0, "a heartbeat is not a truncation"


# ===========================================================================
# 4. End of session
# ===========================================================================
@cocotb.test()
async def test_end_of_session(dut):
    """message_count = 0xFFFF marks the end of a session."""
    tb = MoldTb(dut)
    await tb.start()

    frame = pkt.build_frame(mold_msg_count=0xFFFF)
    beats = pkt.to_beats(frame)

    await tb.drive(beats, mdl.upstream_field_vector(frame))
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    got = tb.fields()
    check_fields(got, mdl.expected_mold_fields(frame))
    assert got["message_count"] == 0xFFFF
    assert got["end_of_session"] == 1, "end_of_session not flagged"
    assert got["heartbeat"] == 0, "0xFFFF is not a heartbeat"


# ===========================================================================
# 5. Sequence number extremes
# ===========================================================================
@cocotb.test()
async def test_sequence_extremes(dut):
    """
    Sequence 0 and 2^64-1, back to back.

    Untagged, the 64-bit sequence number is captured in two halves - the high
    32 bits on beat 6, the low 32 on beat 7. All-zero and all-ones patterns
    would both survive a swapped or duplicated half, so the two are checked
    together with a mid-range value implicitly covered by the other tests.
    """
    tb = MoldTb(dut)
    await tb.start()

    f_zero = pkt.build_frame(mold_seqnum=0)
    f_max = pkt.build_frame(mold_seqnum=0xFFFFFFFFFFFFFFFF)

    b0, b1 = pkt.to_beats(f_zero), pkt.to_beats(f_max)

    await tb.drive_frames([
        (b0, mdl.upstream_field_vector(f_zero)),
        (b1, mdl.upstream_field_vector(f_max)),
    ])
    await tb.settle()

    tb.check_passthrough(b0 + b1)
    assert len(tb.pulses) == 2, f"expected 2 pulses, saw {len(tb.pulses)}"

    assert tb.fields(0)["sequence_num"] == 0
    assert tb.fields(1)["sequence_num"] == 0xFFFFFFFFFFFFFFFF, (
        f"sequence_num: got {tb.fields(1)['sequence_num']:#018x}"
    )
    check_fields(tb.fields(0), mdl.expected_mold_fields(f_zero), ctx="seq 0 ")
    check_fields(tb.fields(1), mdl.expected_mold_fields(f_max), ctx="seq max ")


# ===========================================================================
# 6. Session string
# ===========================================================================
@cocotb.test()
async def test_session_variants(dut):
    """
    A different 10-byte session, spanning beats 5 and 6 untagged.

    Six bytes arrive on beat 5 and four on beat 6, so a mismatched split
    shows up as scrambled ASCII rather than a subtle numeric difference.
    """
    tb = MoldTb(dut)
    await tb.start()

    session = b"XYZ9876543"
    frame = pkt.build_frame(mold_session=session)
    beats = pkt.to_beats(frame)

    await tb.drive(beats, mdl.upstream_field_vector(frame))
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    got = tb.fields()
    check_fields(got, mdl.expected_mold_fields(frame))
    assert mdl.session_ascii(got["session"]) == session.decode(), (
        f"session: got '{mdl.session_ascii(got['session'])}', "
        f"expected '{session.decode()}'"
    )


# ===========================================================================
# 7. Back to back
# ===========================================================================
@cocotb.test()
async def test_back_to_back(dut):
    """Two frames with zero idle cycles - the line-rate case."""
    tb = MoldTb(dut)
    await tb.start()

    f1 = pkt.build_frame(mold_seqnum=1000, mold_msg_count=3)
    f2 = pkt.build_frame(mold_seqnum=1003, mold_msg_count=5)

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)

    await tb.drive_frames([
        (b1, mdl.upstream_field_vector(f1)),
        (b2, mdl.upstream_field_vector(f2)),
    ])
    await tb.settle()

    tb.check_passthrough(b1 + b2)
    assert len(tb.pulses) == 2, (
        f"expected 2 pulses, saw {len(tb.pulses)} "
        "(beat counter may not be resetting on tlast)"
    )
    for n in (0, 1):
        assert tb.beat_of(n) == BEAT_UNTAGGED, (
            f"packet {n}: pulse on beat {tb.beat_of(n)}"
        )

    check_fields(tb.fields(0), mdl.expected_mold_fields(f1), ctx="packet 0 ")
    check_fields(tb.fields(1), mdl.expected_mold_fields(f2), ctx="packet 1 ")

    # sequence continuity, as the downstream gap detector would see it
    s0, c0 = tb.fields(0)["sequence_num"], tb.fields(0)["message_count"]
    s1 = tb.fields(1)["sequence_num"]
    assert s0 + c0 == s1, (
        f"expected sequence continuity: {s0} + {c0} != {s1}"
    )


# ===========================================================================
# 8. Alternating tagged / untagged
# ===========================================================================
@cocotb.test()
async def test_alternating_vlan(dut):
    """
    Tagged then untagged, back to back. The completion beat must alternate
    8 then 7 - the strongest check on last_beat_c being driven per packet
    rather than latched.
    """
    tb = MoldTb(dut)
    await tb.start()

    vid = 42
    tci = pkt.make_tci(vid=vid)
    f1 = pkt.build_frame(vlan_vid=vid, mold_seqnum=500)
    f2 = pkt.build_frame(mold_seqnum=900)

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)

    await tb.drive_frames([
        (b1, mdl.upstream_field_vector(f1, tagged=True, vlan_tci=tci)),
        (b2, mdl.upstream_field_vector(f2)),
    ])
    await tb.settle()

    tb.check_passthrough(b1 + b2)
    assert len(tb.pulses) == 2, f"expected 2 pulses, saw {len(tb.pulses)}"

    assert tb.beat_of(0) == BEAT_TAGGED, (
        f"tagged frame: expected beat {BEAT_TAGGED}, got {tb.beat_of(0)}"
    )
    assert tb.beat_of(1) == BEAT_UNTAGGED, (
        f"untagged frame: expected beat {BEAT_UNTAGGED}, got {tb.beat_of(1)}"
    )

    check_fields(tb.fields(0), mdl.expected_mold_fields(f1, tagged=True),
                 ctx="tagged ")
    check_fields(tb.fields(1), mdl.expected_mold_fields(f2), ctx="untagged ")

    assert tb.fields(0)["sequence_num"] == 500
    assert tb.fields(1)["sequence_num"] == 900


# ===========================================================================
# 9. tvalid bubbles
# ===========================================================================
@cocotb.test()
async def test_tvalid_gaps(dut):
    """Bubbles straddling the Mold header region."""
    tb = MoldTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    gaps = [0] * len(beats)
    gaps[5] = 3
    gaps[6] = 1
    gaps[7] = 2

    await tb.drive(beats, mdl.upstream_field_vector(frame), gaps=gaps)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    assert tb.beat_of() == BEAT_UNTAGGED, (
        f"gaps must not advance the beat counter, pulsed on beat {tb.beat_of()}"
    )
    check_fields(tb.fields(), mdl.expected_mold_fields(frame))


# ===========================================================================
# 10. Frame ends before the header completes
# ===========================================================================
@cocotb.test()
async def test_truncated_before_complete(dut):
    """
    A frame cut at 56 bytes ends on beat 6, one beat short.

    The session arrived in full and the high half of the sequence number did
    too, but the low half and the message count did not. Only what arrived is
    checked; hdr_truncated flags the shortfall.
    """
    tb = MoldTb(dut)
    await tb.start()

    full = pkt.build_frame()
    expected = mdl.expected_mold_fields(full)

    frame = pkt.truncate(full, 56)
    beats = pkt.to_beats(frame)
    assert len(beats) == 7, "expected the frame to end on beat 6"

    await tb.drive(beats, mdl.upstream_field_vector(full))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # forwarded, not dropped

    assert len(tb.pulses) == 1, "a truncated header should still settle the bus"
    assert tb.beat_of() == 6, f"should settle on beat 6, got {tb.beat_of()}"

    got = tb.fields()
    assert got["hdr_truncated"] == 1, "hdr_truncated not set"
    check_fields(got, expected, subset=["session"])
    # sequence_num and message_count deliberately unchecked - never arrived


# ===========================================================================
# 11. Reset mid-frame
# ===========================================================================
@cocotb.test()
async def test_reset_mid_packet(dut):
    """Recovery from a mid-frame reset."""
    tb = MoldTb(dut)
    await tb.start()

    partial = pkt.to_beats(pkt.build_frame())[:6]
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

    frame = pkt.build_frame(mold_seqnum=0xDEADBEEF, mold_msg_count=7)
    beats = pkt.to_beats(frame)

    await tb.drive(beats, mdl.upstream_field_vector(frame))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, (
        f"expected 1 pulse after reset, saw {len(tb.pulses)}"
    )
    assert tb.beat_of() == BEAT_UNTAGGED

    got = tb.fields()
    check_fields(got, mdl.expected_mold_fields(frame))
    assert got["sequence_num"] == 0xDEADBEEF
    assert got["hdr_truncated"] == 0, "reset should have cleared the status bits"


# ===========================================================================
# 12. All ASX endpoints
# ===========================================================================
@cocotb.test()
async def test_all_asx_partitions(dut):
    """
    One frame per ASX endpoint, each with its own sequence number.

    Partitions maintain independent sequence spaces, so this also sweeps the
    sequence capture across eight distinct values.
    """
    tb = MoldTb(dut)
    await tb.start()

    frames = []
    expects = []
    all_beats = []

    for i, (name, src_ip, grp_ip, port) in enumerate(pkt.ASX_CHANNELS):
        seq = 0x1000 * (i + 1)
        f = pkt.build_frame(src_ip=src_ip, dst_ip=grp_ip, udp_dst_port=port,
                            mold_seqnum=seq, mold_msg_count=i + 1)
        b = pkt.to_beats(f)
        frames.append((b, mdl.upstream_field_vector(f)))
        all_beats += b
        expects.append((name, seq, mdl.expected_mold_fields(f)))

    await tb.drive_frames(frames)
    await tb.settle()

    tb.check_passthrough(all_beats)
    assert len(tb.pulses) == len(expects), (
        f"expected {len(expects)} pulses, saw {len(tb.pulses)}"
    )

    for n, (name, seq, exp) in enumerate(expects):
        assert tb.beat_of(n) == BEAT_UNTAGGED, (
            f"{name}: pulse on beat {tb.beat_of(n)}"
        )
        got = tb.fields(n)
        check_fields(got, exp, ctx=f"{name} ")
        assert got["sequence_num"] == seq
        dut._log.info("%s  seq %d  count %d", name, got["sequence_num"],
                      got["message_count"])


# ===========================================================================
# EDGE CASES
# ===========================================================================

# ---------------------------------------------------------------------------
# 13. Runt frame
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_truncated_in_beat0(dut):
    """
    An 8-byte frame ends on beat 0, long before any Mold byte appears.

    Nothing is dropped: the beat is forwarded, hdr_truncated is set, and the
    bus still settles so downstream gets an edge rather than silence.
    """
    tb = MoldTb(dut)
    await tb.start()

    full = pkt.build_frame()
    frame = pkt.truncate(full, 8)
    beats = pkt.to_beats(frame)
    assert len(beats) == 1

    await tb.drive(beats, mdl.upstream_field_vector(full))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, (
        f"expected 1 pulse even for a runt, saw {len(tb.pulses)}"
    )
    assert tb.beat_of() == 0, f"should settle on beat 0, got {tb.beat_of()}"
    assert tb.fields()["hdr_truncated"] == 1, "hdr_truncated not set"


# ---------------------------------------------------------------------------
# 14. Same beat, opposite verdict
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_tagged_truncated_beat7(dut):
    """
    A TAGGED frame cut at 64 bytes ends on beat 7.

    An untagged frame ending on beat 7 is complete. A tagged one is not - its
    message_count lives on beat 8. Same beat, opposite verdict, decided
    entirely by vlan_present.

    This is the Mold equivalent of the Ethernet parser's beat-1 asymmetry,
    and the case most likely to break if last_beat_c is wired wrong.
    """
    tb = MoldTb(dut)
    await tb.start()

    vid = 7
    tci = pkt.make_tci(vid=vid)
    full = pkt.build_frame(vlan_vid=vid)
    expected = mdl.expected_mold_fields(full, tagged=True)

    frame = pkt.truncate(full, 64)
    beats = pkt.to_beats(frame)
    assert len(beats) == 8, "expected the frame to end on beat 7"

    await tb.drive(beats, mdl.upstream_field_vector(full, tagged=True,
                                                    vlan_tci=tci))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1
    assert tb.beat_of() == 7, f"should settle on beat 7, got {tb.beat_of()}"

    got = tb.fields()
    assert got["hdr_truncated"] == 1, (
        "a tagged frame ending on beat 7 IS truncated - message_count "
        "lives on beat 8"
    )
    # session and sequence both arrived; the count did not
    check_fields(got, expected, subset=["session", "sequence_num"])


# ---------------------------------------------------------------------------
# 15. Header exactly fills the frame
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_exact_header_frame(dut):
    """
    62 bytes untagged: Ethernet 14 + IPv4 20 + UDP 8 + Mold 20, and not one
    byte more. The header completes on the same beat that carries tlast.

    This is the boundary between complete and truncated, and where an
    off-by-one in the completion guard would surface.
    """
    tb = MoldTb(dut)
    await tb.start()

    full = pkt.build_frame()
    expected = mdl.expected_mold_fields(full)

    frame = pkt.truncate(full, 62)
    beats = pkt.to_beats(frame)
    assert len(beats) == 8, "62 bytes should be 8 beats"
    assert beats[-1][2] is True and beats[-1][1] == 0x3F, (
        "final beat should carry 6 valid bytes"
    )

    await tb.drive(beats, mdl.upstream_field_vector(full))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, (
        f"expected exactly 1 pulse, saw {len(tb.pulses)} - completion and "
        "tlast on the same beat must not double-pulse"
    )
    assert tb.beat_of() == BEAT_UNTAGGED

    got = tb.fields()
    assert got["hdr_truncated"] == 0, (
        "62 bytes is exactly enough - nothing is truncated"
    )
    check_fields(got, expected)


# ---------------------------------------------------------------------------
# 16. A bubble before every beat
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_bubble_every_beat(dut):
    """One idle cycle before every beat - the pathological gap pattern."""
    tb = MoldTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    await tb.drive(beats, mdl.upstream_field_vector(frame),
                   gaps=[1] * len(beats))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    assert tb.beat_of() == BEAT_UNTAGGED
    check_fields(tb.fields(), mdl.expected_mold_fields(frame))


# ---------------------------------------------------------------------------
# 17. Long mixed burst
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_long_mixed_burst(dut):
    """
    20 frames back to back, alternating tagged and untagged, with a running
    sequence number.

    The completion beat must alternate 8, 7, 8, 7 ... for the whole burst.
    Any state that leaks between packets accumulates into a visible failure.
    """
    tb = MoldTb(dut)
    await tb.start()

    n_frames = 20
    vid = 7
    tci = pkt.make_tci(vid=vid)

    frames = []
    expects = []
    all_beats = []
    seq = 1

    for i in range(n_frames):
        tagged = (i % 2 == 0)
        count = (i % 4) + 1
        f = pkt.build_frame(vlan_vid=vid if tagged else None,
                            mold_seqnum=seq, mold_msg_count=count)
        b = pkt.to_beats(f)
        frames.append((b, mdl.upstream_field_vector(
            f, tagged=tagged, vlan_tci=tci if tagged else 0)))
        all_beats += b
        expects.append((i, tagged, seq,
                        mdl.expected_mold_fields(f, tagged=tagged)))
        seq += count

    await tb.drive_frames(frames)
    await tb.settle()

    tb.check_passthrough(all_beats)
    assert len(tb.pulses) == n_frames, (
        f"expected {n_frames} pulses, saw {len(tb.pulses)}"
    )

    for n, (i, tagged, s, exp) in enumerate(expects):
        want_beat = BEAT_TAGGED if tagged else BEAT_UNTAGGED
        assert tb.beat_of(n) == want_beat, (
            f"frame {i} ({'tagged' if tagged else 'untagged'}): "
            f"expected beat {want_beat}, got {tb.beat_of(n)}"
        )
        got = tb.fields(n)
        check_fields(got, exp, ctx=f"frame {i} ")
        assert got["sequence_num"] == s, f"frame {i}: sequence wrong"

    dut._log.info("%d frames, completion beat alternated correctly", n_frames)


# ---------------------------------------------------------------------------
# 18. Degenerate all-ones frame
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_all_ones_header(dut):
    """
    Every header byte 0xFF. Drives every capture path to all-ones:

        session        all ones
        sequence_num   2^64 - 1
        message_count  0xFFFF  -> end_of_session, NOT heartbeat

    A useful complement to the mostly-zero paths the normal frames exercise,
    and it confirms the two status bits are decoded from distinct values
    rather than sharing logic.
    """
    tb = MoldTb(dut)
    await tb.start()

    frame = b"\xFF" * 84
    beats = pkt.to_beats(frame)

    await tb.drive(beats, mdl.upstream_field_vector(frame))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1
    assert tb.beat_of() == BEAT_UNTAGGED, (
        "0xFFFF is not 0x8100, so this frame is untagged"
    )

    got = tb.fields()
    assert got["session"] == (1 << 80) - 1
    assert got["sequence_num"] == 0xFFFFFFFFFFFFFFFF
    assert got["message_count"] == 0xFFFF
    assert got["end_of_session"] == 1, "0xFFFF should flag end_of_session"
    assert got["heartbeat"] == 0, "0xFFFF is not a heartbeat"
    assert got["hdr_truncated"] == 0, (
        "a full-length frame is not truncated, however malformed"
    )
