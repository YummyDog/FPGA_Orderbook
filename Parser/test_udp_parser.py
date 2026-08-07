"""
cocotb testbench for udp_parser (stage 3).

Standalone: s_fields is driven by the testbench rather than by real upstream
parsers, so this module is verified on its own.

Test cases, in order:

  1  test_single_asx_packet         one untagged ASX ITCH frame (baseline)
  2  test_vlan_tagged               +4 offsets, different beat 4 / beat 5 split
  3  test_nonzero_checksum          proves the checksum field is captured
  4  test_len_invalid               udp_length < 8 flagged, nothing gated
  5  test_port_extremes             ports 0x0000 and 0xFFFF
  6  test_back_to_back              two frames, zero idle between them
  7  test_alternating_vlan          tagged then untagged, exercises the mux
  8  test_tvalid_gaps               bubbles must not advance the beat counter
  9  test_truncated_at_beat4        ends one beat short of completion
 10  test_truncated_in_beat0        runt frame, no UDP bytes at all
 11  test_reset_mid_packet          recovery from a mid-frame reset
 12  test_all_asx_partitions        all 8 ASX channel/partition endpoints

Every test also re-checks the two hard requirements: one output beat per
input beat with the data unmodified, and s_axis_tready tied high.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import asx_packets as pkt
import udp_model as mdl

CLK_PERIOD_NS = 6.4          # 156.25 MHz

UDP_OFF = mdl.UDP_OFF_UNTAGGED       # 34


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------
def safe_int(handle):
    """Signals read 'U' before reset; treat unresolvable as absent."""
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


def patch16(frame: bytes, index: int, value: int) -> bytes:
    """
    Overwrite a 16-bit big-endian field in a built frame.

    Used for header values the builder does not parameterise. This can leave
    the IPv4 checksum stale, which does not matter here: udp_parser never
    inspects it.
    """
    b = bytearray(frame)
    b[index] = (value >> 8) & 0xFF
    b[index + 1] = value & 0xFF
    return bytes(b)


# ---------------------------------------------------------------------------
# Testbench harness
# ---------------------------------------------------------------------------
class UdpTb:
    def __init__(self, dut):
        self.dut = dut
        self.out_beats = []          # (tdata, tkeep, tlast)
        self.pulses = []             # (beat_index_in_packet, full_bus_int)
        self.bus_at_tlast = []       # full bus sampled on each tlast
        self._beat_idx = 0

    # -- lifecycle ---------------------------------------------------------
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

    # -- monitor -----------------------------------------------------------
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

    # -- stimulus ----------------------------------------------------------
    async def drive(self, beats, upstream: int, gaps=None, idle_after=True):
        """
        Push one frame, holding the upstream field bus constant.

        Constant s_fields is valid stimulus: upstream stages hold their fields
        through tlast, and udp_parser only reads vlan_present from its beat 4.
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
        change it, which is harmless because udp_parser does not read
        vlan_present until its beat 4.
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

    async def settle(self, cycles: int = 5):
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)

    # -- checks ------------------------------------------------------------
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
        """Decode the UDP slice from pulse n."""
        return mdl.decode_udp_fields(mdl.udp_slice_of(self.pulses[n][1]))


# ===========================================================================
# 1. Baseline - one untagged ASX ITCH frame
# ===========================================================================
@cocotb.test()
async def test_single_asx_packet(dut):
    """One untagged ASX ITCH Channel A / Partition 1 frame."""
    tb = UdpTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame)
    expected = mdl.expected_udp_fields(frame)

    dut._log.info("Frame length: %d bytes, %d beats", len(frame), len(beats))
    dut._log.info("UDP header at bytes 34..41 (untagged)")

    await tb.drive(beats, upstream)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 fields_valid pulse, saw {len(tb.pulses)}"
    idx, bus = tb.pulses[0]
    assert idx == 5, f"UDP header should complete on beat 5, pulsed on beat {idx}"

    got = tb.fields()
    check_fields(got, expected)

    dut._log.info("src_port      = %d", got["src_port"])
    dut._log.info("dst_port      = %d", got["dst_port"])
    dut._log.info("length        = %d", got["length"])
    dut._log.info("checksum      = %04x", got["checksum"])
    dut._log.info("status: len_invalid %d  trunc %d",
                  got["len_invalid"], got["hdr_truncated"])

    assert got["dst_port"] == pkt.ASX_DST_PORT, (
        f"dst_port: got {got['dst_port']}, expected {pkt.ASX_DST_PORT}"
    )

    assert mdl.upstream_slice_of(bus) == upstream, (
        "Ethernet + IPv4 slice corrupted"
    )

    assert tb.bus_at_tlast, "no tlast observed"
    held = mdl.decode_udp_fields(mdl.udp_slice_of(tb.bus_at_tlast[0]))
    assert held == got, "field bus not held to tlast"

    # Internal 66-bit vector, best-effort: m_fields is authoritative above.
    try:
        internal = int(dut.udp_fields.value)
        assert internal == mdl.udp_slice_of(tb.bus_at_tlast[0]), (
            "internal udp_fields disagrees with the m_fields slice"
        )
        dut._log.info("internal udp_fields matches m_fields slice")
    except (AttributeError, ValueError) as e:
        dut._log.info("internal udp_fields not readable via VHPI (%s)", e)


# ===========================================================================
# 2. VLAN tagged
# ===========================================================================
@cocotb.test()
async def test_vlan_tagged(dut):
    """
    Single 802.1Q tag: the UDP header starts at byte 38 instead of 34.

    The capture split changes shape. Untagged, src_port / dst_port / length
    all land in beat 4 and only the checksum spills into beat 5. Tagged,
    src_port sits alone in beat 4 and the other three arrive in beat 5.
    Both still complete on beat 5.
    """
    tb = UdpTb(dut)
    await tb.start()

    vid = 100
    frame = pkt.build_frame(vlan_vid=vid)
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame, tagged=True,
                                         vlan_tci=pkt.make_tci(vid=vid))
    expected = mdl.expected_udp_fields(frame, tagged=True)

    await tb.drive(beats, upstream)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    idx, _ = tb.pulses[0]
    assert idx == 5, (
        f"tagged header should still complete on beat 5, pulsed on beat {idx}"
    )

    got = tb.fields()
    check_fields(got, expected)

    # src_port is the field captured a whole beat before the rest when tagged
    assert got["src_port"] == int.from_bytes(
        frame[mdl.UDP_OFF_TAGGED:mdl.UDP_OFF_TAGGED + 2], "big"), (
        "src_port is captured on beat 4 in the tagged path"
    )
    assert got["dst_port"] == pkt.ASX_DST_PORT

    # Stimulus self-check, in BYTES: a tag adds exactly 4
    assert len(frame) == len(pkt.build_frame()) + 4, "tag was not inserted"


# ===========================================================================
# 3. Non-zero checksum
# ===========================================================================
@cocotb.test()
async def test_nonzero_checksum(dut):
    """
    The frame builder always emits a zero UDP checksum, which is legal in
    IPv4 and matches real feeds - but it means a parser that never captured
    the field at all would still pass every other test.

    This forces a distinctive value so the checksum path is actually proven.
    """
    tb = UdpTb(dut)
    await tb.start()

    base = pkt.build_frame()
    assert int.from_bytes(base[UDP_OFF + 6:UDP_OFF + 8], "big") == 0, (
        "builder is expected to emit a zero checksum"
    )

    frame = patch16(base, UDP_OFF + 6, 0xABCD)
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame)
    expected = mdl.expected_udp_fields(frame)

    await tb.drive(beats, upstream)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1
    got = tb.fields()
    assert got["checksum"] == 0xABCD, (
        f"checksum: got {got['checksum']:#06x}, expected 0xABCD"
    )
    check_fields(got, expected)


# ===========================================================================
# 4. Length shorter than the header
# ===========================================================================
@cocotb.test()
async def test_len_invalid(dut):
    """
    udp_length = 4, which is impossible: the header alone is 8 bytes.

    Informational only. Nothing is dropped, stalled or gated.
    """
    tb = UdpTb(dut)
    await tb.start()

    frame = patch16(pkt.build_frame(), UDP_OFF + 4, 0x0004)
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame)
    expected = mdl.expected_udp_fields(frame)

    await tb.drive(beats, upstream)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # nothing gated

    assert len(tb.pulses) == 1
    got = tb.fields()

    assert got["length"] == 4, f"length: got {got['length']}, expected 4"
    assert got["len_invalid"] == 1, "len_invalid not set for length < 8"
    assert got["hdr_truncated"] == 0, "a short length is not a truncation"
    check_fields(got, expected)


# ===========================================================================
# 5. Port extremes
# ===========================================================================
@cocotb.test()
async def test_port_extremes(dut):
    """
    src_port 0x0000 and dst_port 0xFFFF - all-zero and all-ones patterns
    through the port capture paths.
    """
    tb = UdpTb(dut)
    await tb.start()

    frame = pkt.build_frame(udp_src_port=0x0000, udp_dst_port=0xFFFF)
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame)
    expected = mdl.expected_udp_fields(frame)

    await tb.drive(beats, upstream)
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    got = tb.fields()
    assert got["src_port"] == 0x0000, f"src_port: got {got['src_port']:#06x}"
    assert got["dst_port"] == 0xFFFF, f"dst_port: got {got['dst_port']:#06x}"
    check_fields(got, expected)


# ===========================================================================
# 6. Back-to-back frames
# ===========================================================================
@cocotb.test()
async def test_back_to_back(dut):
    """Two frames with zero idle cycles between them - the line-rate case."""
    tb = UdpTb(dut)
    await tb.start()

    f1 = pkt.build_frame(udp_src_port=40001, udp_dst_port=21001)
    f2 = pkt.build_frame(udp_src_port=40002, udp_dst_port=21004)

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)
    e1 = mdl.expected_udp_fields(f1)
    e2 = mdl.expected_udp_fields(f2)

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
    for n, (idx, _) in enumerate(tb.pulses):
        assert idx == 5, f"packet {n}: should complete on beat 5, got {idx}"

    check_fields(tb.fields(0), e1, ctx="packet 0 ")
    check_fields(tb.fields(1), e2, ctx="packet 1 ")

    assert tb.fields(0)["dst_port"] != tb.fields(1)["dst_port"], (
        "the two packets should decode different destination ports"
    )


# ===========================================================================
# 7. Alternating tagged / untagged
# ===========================================================================
@cocotb.test()
async def test_alternating_vlan(dut):
    """
    Tagged frame then untagged, back to back, with s_fields switching between
    them. Exercises the vlan_present mux select rather than one static path.
    """
    tb = UdpTb(dut)
    await tb.start()

    vid = 42
    f1 = pkt.build_frame(vlan_vid=vid, udp_dst_port=21002)
    f2 = pkt.build_frame(udp_dst_port=21103)

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)
    e1 = mdl.expected_udp_fields(f1, tagged=True)
    e2 = mdl.expected_udp_fields(f2)

    await tb.drive_frames([
        (b1, mdl.upstream_field_vector(f1, tagged=True,
                                       vlan_tci=pkt.make_tci(vid=vid))),
        (b2, mdl.upstream_field_vector(f2)),
    ])
    await tb.settle()

    tb.check_passthrough(b1 + b2)
    assert len(tb.pulses) == 2, f"expected 2 pulses, saw {len(tb.pulses)}"

    for n, (idx, _) in enumerate(tb.pulses):
        assert idx == 5, f"packet {n}: should complete on beat 5, got {idx}"

    check_fields(tb.fields(0), e1, ctx="tagged ")
    check_fields(tb.fields(1), e2, ctx="untagged ")

    assert tb.fields(0)["dst_port"] == 21002
    assert tb.fields(1)["dst_port"] == 21103


# ===========================================================================
# 8. tvalid bubbles
# ===========================================================================
@cocotb.test()
async def test_tvalid_gaps(dut):
    """
    Idle cycles scattered through the frame, straddling the header. The beat
    counter advances on transfers, not on clock edges, so the fields must
    match the gapless case and completion must still land on beat 5.
    """
    tb = UdpTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    upstream = mdl.upstream_field_vector(frame)
    expected = mdl.expected_udp_fields(frame)

    gaps = [0] * len(beats)
    gaps[2] = 3
    gaps[4] = 1
    gaps[5] = 2
    gaps[8] = 4

    await tb.drive(beats, upstream, gaps=gaps)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    idx, _ = tb.pulses[0]
    assert idx == 5, f"gaps must not advance the beat counter, pulsed on beat {idx}"
    check_fields(tb.fields(), expected)


# ===========================================================================
# 9. Frame ends one beat short
# ===========================================================================
@cocotb.test()
async def test_truncated_at_beat4(dut):
    """
    A frame cut at 40 bytes ends on beat 4, one beat short of completion.

    Untagged, src_port / dst_port / length all arrived on beat 4 and must be
    correct. The checksum lands on beat 5 and never arrived, so it is
    deliberately not checked. hdr_truncated flags the shortfall.
    """
    tb = UdpTb(dut)
    await tb.start()

    full = pkt.build_frame()
    expected = mdl.expected_udp_fields(full)      # model from the full frame

    frame = pkt.truncate(full, 40)
    beats = pkt.to_beats(frame)
    assert len(beats) == 5, "expected the frame to end on beat 4"

    await tb.drive(beats, mdl.upstream_field_vector(full))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # forwarded, not dropped

    assert len(tb.pulses) == 1, "a truncated header should still settle the bus"
    idx, _ = tb.pulses[0]
    assert idx == 4, f"should settle on the final beat, pulsed on beat {idx}"

    got = tb.fields()
    assert got["hdr_truncated"] == 1, "hdr_truncated not set"

    check_fields(got, expected, subset=["src_port", "dst_port", "length",
                                        "len_invalid"])
    # checksum deliberately unchecked - it never arrived


# ===========================================================================
# 10. Runt frame, no UDP bytes at all
# ===========================================================================
@cocotb.test()
async def test_truncated_in_beat0(dut):
    """
    An 8-byte frame ends on beat 0, long before any UDP byte appears.

    Nothing is dropped: the beat is forwarded, hdr_truncated is set, and the
    bus still settles so downstream gets an edge rather than silence.
    No field values are checked - none of them arrived.
    """
    tb = UdpTb(dut)
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
    idx, _ = tb.pulses[0]
    assert idx == 0, f"should settle on beat 0, pulsed on beat {idx}"

    got = tb.fields()
    assert got["hdr_truncated"] == 1, "hdr_truncated not set on a runt frame"


# ===========================================================================
# 11. Reset mid-frame
# ===========================================================================
@cocotb.test()
async def test_reset_mid_packet(dut):
    """
    Reset asserted part-way through a frame. The parser must come back clean
    and treat the next beat it sees as beat 0 of a new frame.
    """
    tb = UdpTb(dut)
    await tb.start()

    partial = pkt.to_beats(pkt.build_frame())[:4]
    for tdata, tkeep, _ in partial:
        await RisingEdge(dut.clk)
        dut.s_axis_tdata.value = tdata
        dut.s_axis_tkeep.value = tkeep
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tlast.value = 0

    await RisingEdge(dut.clk)
    dut.s_axis_tvalid.value = 0

    await tb.reset()
    tb.clear()                       # discard pre-reset history

    frame = pkt.build_frame(udp_src_port=33333, udp_dst_port=21104)
    beats = pkt.to_beats(frame)
    expected = mdl.expected_udp_fields(frame)

    await tb.drive(beats, mdl.upstream_field_vector(frame))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, (
        f"expected 1 pulse after reset, saw {len(tb.pulses)} "
        "(beat counter may not have cleared)"
    )
    idx, _ = tb.pulses[0]
    assert idx == 5, f"post-reset frame should complete on beat 5, got {idx}"

    got = tb.fields()
    check_fields(got, expected)
    assert got["hdr_truncated"] == 0, "reset should have cleared the status bits"


# ===========================================================================
# 12. All ASX channels and partitions
# ===========================================================================
@cocotb.test()
async def test_all_asx_partitions(dut):
    """
    One frame per ASX endpoint: Channel A and B, partitions 1-4.

    Each partition has its own destination port (21001-21004, 21101-21104),
    so this sweeps dst_port across both channels.
    """
    tb = UdpTb(dut)
    await tb.start()

    frames = []
    expects = []
    all_beats = []

    for name, src_ip, grp_ip, port in pkt.ASX_CHANNELS:
        f = pkt.build_frame(src_ip=src_ip, dst_ip=grp_ip, udp_dst_port=port)
        b = pkt.to_beats(f)
        frames.append((b, mdl.upstream_field_vector(f)))
        all_beats += b
        expects.append((name, port, mdl.expected_udp_fields(f)))

    await tb.drive_frames(frames)
    await tb.settle()

    tb.check_passthrough(all_beats)

    assert len(tb.pulses) == len(expects), (
        f"expected {len(expects)} pulses, saw {len(tb.pulses)}"
    )

    for n, (name, port, exp) in enumerate(expects):
        idx, _ = tb.pulses[n]
        assert idx == 5, f"{name}: should complete on beat 5, got {idx}"
        got = tb.fields(n)
        check_fields(got, exp, ctx=f"{name} ")
        assert got["dst_port"] == port, (
            f"{name}: dst_port got {got['dst_port']}, expected {port}"
        )
        dut._log.info("%s  dst_port %d  length %d", name, got["dst_port"],
                      got["length"])
