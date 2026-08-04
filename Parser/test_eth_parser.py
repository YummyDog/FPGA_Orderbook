"""
cocotb testbench for eth_parser (stage 1).

Test cases, in order:

  1  test_single_asx_packet        one untagged ASX ITCH frame (baseline)
  2  test_vlan_tagged              single 802.1Q tag, header completes beat 2
  3  test_vlan_tci_decode          PCP / DEI / VID all non-zero
  4  test_unrecognised_tpid        0x88A8 with G_TPID=0x8100 is NOT a tag
  5  test_non_ipv4_ethertype       ARP forwarded unmodified (error policy)
  6  test_back_to_back             two frames, zero idle between them
  7  test_alternating_vlan         tagged then untagged, checks state clearing
  8  test_tvalid_gaps              bubbles mid-frame must not advance the beat counter
  9  test_truncated_in_beat0       runt frame, informational status only
 10  test_truncated_tagged_beat1   tagged frame ending before the ethertype
 11  test_reset_mid_packet         recovery from a mid-frame reset
 12  test_all_asx_partitions       all 8 ASX channel/partition endpoints

Every test also re-checks the two hard requirements: one output beat per
input beat with the data unmodified, and s_axis_tready tied high.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import asx_packets as pkt

CLK_PERIOD_NS = 6.4          # 156.25 MHz

# Field-bus layout, mirrors eth_parser_pkg
F_DST_MAC_LO, F_DST_MAC_W = 0, 48
F_SRC_MAC_LO, F_SRC_MAC_W = 48, 48
F_ETHERTYPE_LO, F_ETHERTYPE_W = 96, 16
F_VLAN_TCI_LO, F_VLAN_TCI_W = 112, 16
F_VLAN_PRESENT_LO = 128
F_ETH_TRUNC_LO = 129
F_ETH_FIELDS_W = 130


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------
def slice_bits(value: int, lo: int, width: int) -> int:
    return (value >> lo) & ((1 << width) - 1)


def decode_fields(raw: int) -> dict:
    return {
        "dst_mac": slice_bits(raw, F_DST_MAC_LO, F_DST_MAC_W),
        "src_mac": slice_bits(raw, F_SRC_MAC_LO, F_SRC_MAC_W),
        "ethertype": slice_bits(raw, F_ETHERTYPE_LO, F_ETHERTYPE_W),
        "vlan_tci": slice_bits(raw, F_VLAN_TCI_LO, F_VLAN_TCI_W),
        "vlan_present": slice_bits(raw, F_VLAN_PRESENT_LO, 1),
        "hdr_truncated": slice_bits(raw, F_ETH_TRUNC_LO, 1),
    }


def safe_int(handle):
    """Signals read 'U' before reset; treat unresolvable as absent."""
    try:
        return int(handle.value)
    except ValueError:
        return None


def check_fields(got: dict, expected: dict, subset=None, ctx=""):
    """Compare decoded fields against expectations, optionally a subset."""
    keys = subset if subset else expected.keys()
    for name in keys:
        assert got[name] == expected[name], (
            f"{ctx}{name}: got {got[name]:#x}, expected {expected[name]:#x}"
        )


# ---------------------------------------------------------------------------
# Testbench harness
# ---------------------------------------------------------------------------
class EthTb:
    def __init__(self, dut):
        self.dut = dut
        self.out_beats = []          # (tdata, tkeep, tlast)
        self.pulses = []             # (beat_index_in_packet, fields_int)
        self.fields_at_tlast = []    # fields_int sampled on each tlast
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
        d.m_axis_tready.value = 1      # ignored by the DUT, driven for realism
        d.resetn.value = 0
        for _ in range(cycles):
            await RisingEdge(d.clk)
        d.resetn.value = 1
        await RisingEdge(d.clk)

    def clear(self):
        """Drop captured history and restart packet-relative beat indexing."""
        self.out_beats.clear()
        self.pulses.clear()
        self.fields_at_tlast.clear()
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
                    self.fields_at_tlast.append(safe_int(d.m_fields))
                    self._beat_idx = 0
                else:
                    self._beat_idx += 1

    # -- stimulus ----------------------------------------------------------
    async def drive(self, beats, gaps=None, idle_after=True):
        """
        Push beats in. `gaps[i]` inserts that many idle (tvalid low) cycles
        before beat i, to prove bubbles do not disturb the beat counter.
        """
        d = self.dut
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


# ===========================================================================
# 1. Baseline - the original single-packet test
# ===========================================================================
@cocotb.test()
async def test_single_asx_packet(dut):
    """One untagged ASX ITCH Channel A / Partition 1 frame."""
    tb = EthTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)
    expected = pkt.expected_eth_fields(frame)

    dut._log.info("Frame length: %d bytes, %d beats", len(frame), len(beats))
    dut._log.info("dst MAC %s (multicast map of %s)",
                  pkt.multicast_mac_for(pkt.ASX_GRP_IP), pkt.ASX_GRP_IP)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 fields_valid pulse, saw {len(tb.pulses)}"
    idx, raw = tb.pulses[0]
    assert idx == 1, f"untagged header should complete on beat 1, pulsed on beat {idx}"

    got = decode_fields(raw)
    check_fields(got, expected)

    dut._log.info("dst_mac   = %012x", got["dst_mac"])
    dut._log.info("src_mac   = %012x", got["src_mac"])
    dut._log.info("ethertype = %04x", got["ethertype"])
    dut._log.info("vlan      = present %d, tci %04x",
                  got["vlan_present"], got["vlan_tci"])

    assert tb.fields_at_tlast, "no tlast observed"
    assert decode_fields(tb.fields_at_tlast[0]) == got, "field bus not held to tlast"


# ===========================================================================
# 2. VLAN tagged
# ===========================================================================
@cocotb.test()
async def test_vlan_tagged(dut):
    """Single 802.1Q tag: ethertype comes from beat 2, all offsets shift by 4."""
    tb = EthTb(dut)
    await tb.start()

    frame = pkt.build_frame(vlan_vid=100)
    beats = pkt.to_beats(frame)
    expected = pkt.expected_eth_fields(frame, vlan_vid=100)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    idx, raw = tb.pulses[0]
    assert idx == 2, f"tagged header should complete on beat 2, pulsed on beat {idx}"

    got = decode_fields(raw)
    check_fields(got, expected)
    assert got["ethertype"] == pkt.ETHERTYPE_IPV4, (
        "ethertype must be the real type, not the TPID"
    )

    # Stimulus self-check: confirm the builder actually inserted the tag.
    # Compare BYTES, not beats - 84 and 88 bytes both round to 11 beats, so a
    # beat-count check would not detect a missing tag.
    untagged_frame = pkt.build_frame()
    assert len(frame) == len(untagged_frame) + 4, (
        f"tagged frame should be 4 bytes longer: "
        f"{len(frame)} vs {len(untagged_frame)}"
    )


# ===========================================================================
# 3. TCI sub-field decode
# ===========================================================================
@cocotb.test()
async def test_vlan_tci_decode(dut):
    """PCP, DEI and VID all non-zero, to catch a mis-packed TCI."""
    tb = EthTb(dut)
    await tb.start()

    pcp, dei, vid = 5, 1, 0xABC
    frame = pkt.build_frame(vlan_vid=vid, vlan_pcp=pcp, vlan_dei=dei)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1
    got = decode_fields(tb.pulses[0][1])

    tci = got["vlan_tci"]
    assert (tci >> 13) & 0x7 == pcp, f"PCP: got {(tci >> 13) & 0x7}, expected {pcp}"
    assert (tci >> 12) & 0x1 == dei, f"DEI: got {(tci >> 12) & 0x1}, expected {dei}"
    assert tci & 0xFFF == vid, f"VID: got {tci & 0xFFF:#x}, expected {vid:#x}"
    assert got["vlan_present"] == 1


# ===========================================================================
# 4. Unrecognised TPID
# ===========================================================================
@cocotb.test()
async def test_unrecognised_tpid(dut):
    """
    An 0x88A8 S-tag while G_TPID is 0x8100 must NOT be treated as a tag.

    The parser sees 0x88A8 at bytes 12-13, fails the compare, and reports it
    as the ethertype. Documents that only the configured TPID matches.
    """
    tb = EthTb(dut)
    await tb.start()

    frame = pkt.build_frame(vlan_vid=200, tpid=pkt.TPID_8021AD)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1
    idx, raw = tb.pulses[0]
    assert idx == 1, "unmatched TPID means the header completes on beat 1"

    got = decode_fields(raw)
    assert got["vlan_present"] == 0, "0x88A8 must not match G_TPID=0x8100"
    assert got["ethertype"] == pkt.TPID_8021AD, (
        f"ethertype should read {pkt.TPID_8021AD:#06x}, got {got['ethertype']:#06x}"
    )
    assert got["vlan_tci"] == 0, "TCI must be zero when no tag is recognised"


# ===========================================================================
# 5. Non-IPv4 ethertype
# ===========================================================================
@cocotb.test()
async def test_non_ipv4_ethertype(dut):
    """
    Error policy: never drop, stall or modify. A non-IPv4 frame is parsed and
    forwarded exactly like any other; the ethertype is simply reported.
    """
    tb = EthTb(dut)
    await tb.start()

    frame = pkt.build_frame(ethertype=pkt.ETHERTYPE_ARP)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # nothing gated

    assert len(tb.pulses) == 1
    got = decode_fields(tb.pulses[0][1])
    assert got["ethertype"] == pkt.ETHERTYPE_ARP
    assert got["hdr_truncated"] == 0, "a non-IPv4 ethertype is not a truncation"


# ===========================================================================
# 6. Back-to-back frames
# ===========================================================================
@cocotb.test()
async def test_back_to_back(dut):
    """Two frames with zero idle cycles between them - the line-rate case."""
    tb = EthTb(dut)
    await tb.start()

    f1 = pkt.build_frame(src_mac="00:11:22:33:44:55", dst_ip="233.71.185.129")
    f2 = pkt.build_frame(src_mac="aa:bb:cc:dd:ee:ff", dst_ip="233.71.185.132")

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)
    e1 = pkt.expected_eth_fields(f1)
    e2 = pkt.expected_eth_fields(f2)

    await tb.drive(b1 + b2)          # single contiguous burst
    await tb.settle()

    tb.check_passthrough(b1 + b2)

    assert len(tb.pulses) == 2, (
        f"expected 2 fields_valid pulses, saw {len(tb.pulses)} "
        "(beat counter may not be resetting on tlast)"
    )
    for n, (idx, raw) in enumerate(tb.pulses):
        assert idx == 1, f"packet {n}: header should complete on beat 1, got {idx}"

    check_fields(decode_fields(tb.pulses[0][1]), e1, ctx="packet 0 ")
    check_fields(decode_fields(tb.pulses[1][1]), e2, ctx="packet 1 ")

    assert len(tb.fields_at_tlast) == 2, "expected two tlast samples"
    check_fields(decode_fields(tb.fields_at_tlast[1]), e2, ctx="packet 1 at tlast ")


# ===========================================================================
# 7. Alternating tagged / untagged
# ===========================================================================
@cocotb.test()
async def test_alternating_vlan(dut):
    """
    Tagged frame followed immediately by an untagged one.

    Catches stale VLAN state: vlan_present and vlan_tci must both clear for
    the second frame, and its header must complete a beat earlier.
    """
    tb = EthTb(dut)
    await tb.start()

    f1 = pkt.build_frame(vlan_vid=42, src_mac="00:11:22:33:44:55")
    f2 = pkt.build_frame(src_mac="aa:bb:cc:dd:ee:ff")

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)
    e1 = pkt.expected_eth_fields(f1, vlan_vid=42)
    e2 = pkt.expected_eth_fields(f2)

    await tb.drive(b1 + b2)
    await tb.settle()

    tb.check_passthrough(b1 + b2)
    assert len(tb.pulses) == 2, f"expected 2 pulses, saw {len(tb.pulses)}"

    idx1, raw1 = tb.pulses[0]
    idx2, raw2 = tb.pulses[1]
    assert idx1 == 2, f"tagged frame should complete on beat 2, got {idx1}"
    assert idx2 == 1, f"untagged frame should complete on beat 1, got {idx2}"

    check_fields(decode_fields(raw1), e1, ctx="tagged ")

    got2 = decode_fields(raw2)
    check_fields(got2, e2, ctx="untagged ")
    assert got2["vlan_present"] == 0, "vlan_present leaked from the previous frame"
    assert got2["vlan_tci"] == 0, "vlan_tci leaked from the previous frame"


# ===========================================================================
# 8. tvalid bubbles
# ===========================================================================
@cocotb.test()
async def test_tvalid_gaps(dut):
    """
    Idle cycles scattered through the frame. The beat counter advances on
    transfers, not on clock edges, so the fields must be identical to the
    gapless case and the header must still complete on beat 1.
    """
    tb = EthTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)
    expected = pkt.expected_eth_fields(frame)

    # bubbles before beats 1, 2 and 5 - straddling the header boundary
    gaps = [0] * len(beats)
    gaps[1] = 3
    gaps[2] = 1
    gaps[5] = 4

    await tb.drive(beats, gaps=gaps)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # gaps must not create or lose beats

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    idx, raw = tb.pulses[0]
    assert idx == 1, f"gaps must not advance the beat counter, pulsed on beat {idx}"
    check_fields(decode_fields(raw), expected)


# ===========================================================================
# 9. Runt frame, ends inside beat 0
# ===========================================================================
@cocotb.test()
async def test_truncated_in_beat0(dut):
    """
    An 8-byte frame ends before the header exists.

    Per the error policy this is informational only: the beat is forwarded
    untouched and hdr_truncated is set. dst_mac is still valid because all
    six of its bytes arrived; ethertype and the low half of src_mac never
    did, so they are not checked.
    """
    tb = EthTb(dut)
    await tb.start()

    frame = pkt.truncate(pkt.build_frame(), 8)
    beats = pkt.to_beats(frame)
    assert len(beats) == 1

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # forwarded, not dropped

    assert len(tb.pulses) == 1, "a truncated header should still settle the bus"
    got = decode_fields(tb.pulses[0][1])

    assert got["hdr_truncated"] == 1, "hdr_truncated not set on a runt frame"
    assert got["dst_mac"] == int.from_bytes(frame[0:6], "big")
    assert got["vlan_present"] == 0


# ===========================================================================
# 10. Tagged frame ending before the ethertype
# ===========================================================================
@cocotb.test()
async def test_truncated_tagged_beat1(dut):
    """
    A tagged frame cut at 16 bytes: the TCI arrived but the real ethertype
    (bytes 16-17) never did. MACs and TCI are valid, ethertype is not, and
    hdr_truncated flags it.
    """
    tb = EthTb(dut)
    await tb.start()

    vid = 0x123
    frame = pkt.truncate(pkt.build_frame(vlan_vid=vid), 16)
    beats = pkt.to_beats(frame)
    assert len(beats) == 2

    await tb.drive(beats)
    await tb.settle()

    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1
    idx, raw = tb.pulses[0]
    assert idx == 1, "truncation should settle the bus on the final beat"

    got = decode_fields(raw)
    assert got["hdr_truncated"] == 1, "hdr_truncated not set"
    assert got["vlan_present"] == 1, "tag was present and should be reported"
    assert got["vlan_tci"] & 0xFFF == vid
    assert got["dst_mac"] == int.from_bytes(frame[0:6], "big")
    assert got["src_mac"] == int.from_bytes(frame[6:12], "big")
    # ethertype deliberately unchecked - those bytes never arrived


# ===========================================================================
# 11. Reset mid-frame
# ===========================================================================
@cocotb.test()
async def test_reset_mid_packet(dut):
    """
    Reset asserted part-way through a frame. The parser must come back clean
    and treat the next beat it sees as beat 0 of a new frame.
    """
    tb = EthTb(dut)
    await tb.start()

    partial = pkt.to_beats(pkt.build_frame())[:3]
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

    frame = pkt.build_frame(src_mac="de:ad:be:ef:00:01")
    beats = pkt.to_beats(frame)
    expected = pkt.expected_eth_fields(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, (
        f"expected 1 pulse after reset, saw {len(tb.pulses)} "
        "(beat counter may not have cleared)"
    )
    idx, raw = tb.pulses[0]
    assert idx == 1, f"post-reset frame should complete on beat 1, got {idx}"
    check_fields(decode_fields(raw), expected)


# ===========================================================================
# 12. All ASX channels and partitions
# ===========================================================================
@cocotb.test()
async def test_all_asx_partitions(dut):
    """
    One frame per ASX endpoint: Channel A and B, partitions 1-4.

    Each has a distinct multicast group, so each has a distinct destination
    MAC under the RFC 1112 mapping - a good sweep of dst_mac bit patterns.
    """
    tb = EthTb(dut)
    await tb.start()

    all_beats = []
    expects = []
    for name, src_ip, grp_ip, port in pkt.ASX_CHANNELS:
        f = pkt.build_frame(src_ip=src_ip, dst_ip=grp_ip, udp_dst_port=port)
        all_beats += pkt.to_beats(f)
        expects.append((name, grp_ip, pkt.expected_eth_fields(f)))

    await tb.drive(all_beats)
    await tb.settle()

    tb.check_passthrough(all_beats)

    assert len(tb.pulses) == len(expects), (
        f"expected {len(expects)} pulses, saw {len(tb.pulses)}"
    )

    for (name, grp_ip, exp), (idx, raw) in zip(expects, tb.pulses):
        assert idx == 1, f"{name}: header should complete on beat 1, got {idx}"
        got = decode_fields(raw)
        check_fields(got, exp, ctx=f"{name} ")
        dut._log.info("%s  group %-16s dst_mac %012x",
                      name, grp_ip, got["dst_mac"])
