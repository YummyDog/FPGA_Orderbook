"""
cocotb testbench for threeparserpipline (stages 1-3 chained).

    eth_parser -> ipv4_parser -> udp_parser

Nothing is driven into s_fields: every field on the 360-bit output bus was
produced by a real upstream parser. This is the test of the chaining
mechanism itself, not of the individual extraction logic.

Core cases:

  1  test_single_asx_packet        one untagged ASX ITCH frame (baseline)
  2  test_vlan_tagged              tag propagates eth -> ipv4 -> udp
  3  test_back_to_back             two frames, zero idle between them
  4  test_alternating_vlan         vlan_present must track per packet
  5  test_tvalid_gaps              bubbles must not disturb any stage
  6  test_all_asx_partitions       all 8 ASX channel/partition endpoints
  7  test_reset_mid_packet         whole pipeline recovers together
  8  test_ihl_options_misparse     IHL=6 shifts UDP - documents the real cost
  9  test_fragmented               frag_present propagates to the output bus
 10  test_truncated_udp_only       ends beat 4: eth ok, ipv4 ok, udp short
 11  test_truncated_ipv4_and_udp   ends beat 3: eth ok, ipv4 and udp short
 12  test_truncated_all_three      ends beat 0: every stage short

Edge cases:

 13  test_min_ethernet_frame       60-byte minimum-size frame
 14  test_exact_header_frame       42 bytes: headers exactly fill the frame
 15  test_partial_final_beat       41 bytes: documents the tkeep limitation
 16  test_bubble_every_beat        one idle cycle between every beat
 17  test_long_mixed_burst         20 frames, alternating tagged/untagged
 18  test_all_ones_header          degenerate all-0xFF frame

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import asx_packets as pkt
import ipv4_model as ip4
import udp_model as mdl

CLK_PERIOD_NS = 6.4          # 156.25 MHz


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


def patch16(frame: bytes, index: int, value: int) -> bytes:
    b = bytearray(frame)
    b[index] = (value >> 8) & 0xFF
    b[index + 1] = value & 0xFF
    return bytes(b)


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
        "udp": mdl.decode_udp_fields(mdl.udp_slice_of(bus)),
    }


def trunc_triple(bus: int):
    d = decode_all(bus)
    return (d["eth"]["hdr_truncated"],
            d["ipv4"]["hdr_truncated"],
            d["udp"]["hdr_truncated"])


def pack_udp_fields(f: dict) -> int:
    v = 0
    v |= (f["src_port"] & 0xFFFF) << mdl.UDP_SRCPORT_LOC
    v |= (f["dst_port"] & 0xFFFF) << mdl.UDP_DSTPORT_LOC
    v |= (f["length"] & 0xFFFF) << mdl.UDP_LENGTH_LOC
    v |= (f["checksum"] & 0xFFFF) << mdl.UDP_CKSUM_LOC
    v |= (f["len_invalid"] & 1) << mdl.UDP_LEN_INVALID_LOC
    v |= (f["hdr_truncated"] & 1) << mdl.UDP_TRUNC_LOC
    return v


def expected_full_bus(frame: bytes, tagged: bool = False,
                      vlan_tci: int = 0) -> int:
    """The complete 360-bit bus the pipeline should produce."""
    upstream = mdl.upstream_field_vector(frame, tagged=tagged,
                                         vlan_tci=vlan_tci)
    udp = pack_udp_fields(mdl.expected_udp_fields(frame, tagged=tagged))
    return (udp << mdl.UDP_BASE) | upstream


# ---------------------------------------------------------------------------
# Testbench harness
# ---------------------------------------------------------------------------
class PipelineTb:
    def __init__(self, dut):
        self.dut = dut
        self.out_beats = []
        self.pulses = []             # (beat_index, cycle, full_bus_int)
        self.eth_pulses = []
        self.ipv4_pulses = []
        self.bus_at_tlast = []
        self.first_out_cycle = None
        self._beat_idx = 0
        self._cycle = 0

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
        d.m_axis_tready.value = 1
        d.resetn.value = 0
        for _ in range(cycles):
            await RisingEdge(d.clk)
        d.resetn.value = 1
        await RisingEdge(d.clk)

    def clear(self):
        self.out_beats.clear()
        self.pulses.clear()
        self.eth_pulses.clear()
        self.ipv4_pulses.clear()
        self.bus_at_tlast.clear()
        self.first_out_cycle = None
        self._beat_idx = 0

    async def _monitor(self):
        d = self.dut
        while True:
            await RisingEdge(d.clk)
            await ReadOnly()
            self._cycle += 1

            valid = safe_int(d.m_axis_tvalid)
            fvalid = safe_int(d.m_fields_valid)

            if safe_int(d.eth_fields_valid) == 1:
                self.eth_pulses.append(self._cycle)
            if safe_int(d.ipv4_fields_valid) == 1:
                self.ipv4_pulses.append(self._cycle)

            if valid == 1:
                if self.first_out_cycle is None:
                    self.first_out_cycle = self._cycle
                tlast = safe_int(d.m_axis_tlast)
                self.out_beats.append(
                    (safe_int(d.m_axis_tdata), safe_int(d.m_axis_tkeep), tlast)
                )

            if fvalid == 1:
                self.pulses.append(
                    (self._beat_idx, self._cycle, safe_int(d.m_fields))
                )

            if valid == 1:
                if tlast == 1:
                    self.bus_at_tlast.append(safe_int(d.m_fields))
                    self._beat_idx = 0
                else:
                    self._beat_idx += 1

    async def drive(self, beats, gaps=None, idle_after=True):
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

    async def settle(self, cycles: int = 8):
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

    def bus(self, n: int = 0) -> int:
        return self.pulses[n][2]

    def beat_of(self, n: int = 0) -> int:
        return self.pulses[n][0]


# ===========================================================================
# 1. Baseline
# ===========================================================================
@cocotb.test()
async def test_single_asx_packet(dut):
    """One untagged ASX ITCH Channel A / Partition 1 frame through all three."""
    tb = PipelineTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    exp_eth = pkt.expected_eth_fields(frame)
    exp_ip4 = ip4.expected_ipv4_fields(frame)
    exp_udp = mdl.expected_udp_fields(frame)
    exp_bus = expected_full_bus(frame)

    dut._log.info("Frame length: %d bytes, %d beats", len(frame), len(beats))

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.eth_pulses) == 1, f"eth: {len(tb.eth_pulses)} pulses"
    assert len(tb.ipv4_pulses) == 1, f"ipv4: {len(tb.ipv4_pulses)} pulses"
    assert len(tb.pulses) == 1, f"udp: {len(tb.pulses)} pulses"

    eth_c, ip4_c = tb.eth_pulses[0], tb.ipv4_pulses[0]
    beat_idx, udp_c, bus = tb.pulses[0]
    assert eth_c < ip4_c < udp_c, (
        f"stages out of order: eth {eth_c}, ipv4 {ip4_c}, udp {udp_c}"
    )
    dut._log.info("completion cycles: eth %d, ipv4 %d, udp %d", eth_c, ip4_c, udp_c)

    assert beat_idx == 5, (
        f"UDP completes on beat 5, pulse landed on output beat {beat_idx}"
    )

    got = decode_all(bus)
    check_fields(got["eth"], exp_eth, ctx="eth ")
    check_fields(got["ipv4"], exp_ip4, ctx="ipv4 ")
    check_fields(got["udp"], exp_udp, ctx="udp ")

    dut._log.info("eth : dst_mac %012x  ethertype %04x",
                  got["eth"]["dst_mac"], got["eth"]["ethertype"])
    dut._log.info("ipv4: src_ip %08x  dst_ip %08x", got["ipv4"]["src_ip"],
                  got["ipv4"]["dst_ip"])
    dut._log.info("udp : src %d  dst %d  len %d", got["udp"]["src_port"],
                  got["udp"]["dst_port"], got["udp"]["length"])

    assert bus == exp_bus, (
        f"full bus mismatch:\n  got      {bus:#092x}\n  expected {exp_bus:#092x}"
    )
    assert trunc_triple(bus) == (0, 0, 0), "truncation set on a complete frame"

    assert tb.bus_at_tlast, "no tlast observed"
    assert tb.bus_at_tlast[0] == bus, "bus not held from completion to tlast"


# ===========================================================================
# 2. VLAN tagged, end to end
# ===========================================================================
@cocotb.test()
async def test_vlan_tagged(dut):
    """
    A tag detected by eth_parser must steer BOTH downstream stages.

    This is the chained version of the mux tests: vlan_present is produced by
    real hardware here, not driven by the testbench, so it also proves the
    timing claim - eth registers it at its beat 1 and it reaches ipv4 in the
    same cycle as the beat it describes.
    """
    tb = PipelineTb(dut)
    await tb.start()

    vid = 100
    tci = pkt.make_tci(vid=vid)
    frame = pkt.build_frame(vlan_vid=vid)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    bus = tb.bus()
    got = decode_all(bus)

    assert got["eth"]["vlan_present"] == 1, "tag not detected"
    assert got["eth"]["vlan_tci"] == tci
    assert got["eth"]["ethertype"] == pkt.ETHERTYPE_IPV4, "TPID leaked as ethertype"

    check_fields(got["ipv4"], ip4.expected_ipv4_fields(frame, tagged=True),
                 ctx="ipv4 ")
    check_fields(got["udp"], mdl.expected_udp_fields(frame, tagged=True),
                 ctx="udp ")

    assert got["udp"]["dst_port"] == pkt.ASX_DST_PORT, (
        "tagged frame: UDP read from the wrong offset"
    )
    assert bus == expected_full_bus(frame, tagged=True, vlan_tci=tci)
    assert trunc_triple(bus) == (0, 0, 0)


# ===========================================================================
# 3. Back to back
# ===========================================================================
@cocotb.test()
async def test_back_to_back(dut):
    """Two frames, zero idle cycles - the line-rate case, all three stages."""
    tb = PipelineTb(dut)
    await tb.start()

    f1 = pkt.build_frame(dst_ip="233.71.185.129", udp_dst_port=21001,
                         src_mac="00:11:22:33:44:55")
    f2 = pkt.build_frame(dst_ip="233.71.185.132", udp_dst_port=21004,
                         src_mac="aa:bb:cc:dd:ee:ff")

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)

    await tb.drive(b1 + b2)
    await tb.settle()

    tb.check_passthrough(b1 + b2)

    assert len(tb.eth_pulses) == 2, f"eth: {len(tb.eth_pulses)} pulses"
    assert len(tb.ipv4_pulses) == 2, f"ipv4: {len(tb.ipv4_pulses)} pulses"
    assert len(tb.pulses) == 2, f"udp: {len(tb.pulses)} pulses"

    for n in (0, 1):
        assert tb.beat_of(n) == 5, f"packet {n}: pulse on beat {tb.beat_of(n)}"

    assert tb.bus(0) == expected_full_bus(f1), "packet 0 bus mismatch"
    assert tb.bus(1) == expected_full_bus(f2), "packet 1 bus mismatch"

    assert decode_all(tb.bus(0))["udp"]["dst_port"] == 21001
    assert decode_all(tb.bus(1))["udp"]["dst_port"] == 21004


# ===========================================================================
# 4. Alternating tagged / untagged
# ===========================================================================
@cocotb.test()
async def test_alternating_vlan(dut):
    """
    Tagged then untagged, back to back. vlan_present must change with the
    packet and steer all three stages correctly on each.
    """
    tb = PipelineTb(dut)
    await tb.start()

    vid = 42
    tci = pkt.make_tci(vid=vid)
    f1 = pkt.build_frame(vlan_vid=vid, udp_dst_port=21002)
    f2 = pkt.build_frame(udp_dst_port=21103)

    b1, b2 = pkt.to_beats(f1), pkt.to_beats(f2)

    await tb.drive(b1 + b2)
    await tb.settle()

    tb.check_passthrough(b1 + b2)
    assert len(tb.pulses) == 2, f"expected 2 pulses, saw {len(tb.pulses)}"

    g0, g1 = decode_all(tb.bus(0)), decode_all(tb.bus(1))

    assert g0["eth"]["vlan_present"] == 1, "packet 0 should be tagged"
    assert g1["eth"]["vlan_present"] == 0, "vlan_present leaked into packet 1"
    assert g1["eth"]["vlan_tci"] == 0, "vlan_tci leaked into packet 1"

    assert g0["udp"]["dst_port"] == 21002, "tagged frame misparsed"
    assert g1["udp"]["dst_port"] == 21103, "untagged frame misparsed"

    assert tb.bus(0) == expected_full_bus(f1, tagged=True, vlan_tci=tci)
    assert tb.bus(1) == expected_full_bus(f2)


# ===========================================================================
# 5. tvalid bubbles
# ===========================================================================
@cocotb.test()
async def test_tvalid_gaps(dut):
    """Bubbles scattered across all three stages' header regions."""
    tb = PipelineTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    gaps = [0] * len(beats)
    gaps[1] = 3      # inside the Ethernet header
    gaps[3] = 2      # inside the IPv4 header
    gaps[5] = 4      # inside the UDP header
    gaps[8] = 1

    await tb.drive(beats, gaps=gaps)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    assert tb.beat_of() == 5, f"pulse on beat {tb.beat_of()}, expected 5"
    assert tb.bus() == expected_full_bus(frame), "bubbles changed the result"


# ===========================================================================
# 6. All ASX endpoints
# ===========================================================================
@cocotb.test()
async def test_all_asx_partitions(dut):
    """One frame per ASX endpoint, back to back through the whole pipeline."""
    tb = PipelineTb(dut)
    await tb.start()

    all_beats = []
    expects = []
    for name, src_ip, grp_ip, port in pkt.ASX_CHANNELS:
        f = pkt.build_frame(src_ip=src_ip, dst_ip=grp_ip, udp_dst_port=port)
        all_beats += pkt.to_beats(f)
        expects.append((name, port, expected_full_bus(f)))

    await tb.drive(all_beats)
    await tb.settle()

    tb.check_passthrough(all_beats)
    assert len(tb.pulses) == len(expects), (
        f"expected {len(expects)} pulses, saw {len(tb.pulses)}"
    )

    for n, (name, port, exp_bus) in enumerate(expects):
        assert tb.beat_of(n) == 5, f"{name}: pulse on beat {tb.beat_of(n)}"
        assert tb.bus(n) == exp_bus, f"{name}: bus mismatch"
        g = decode_all(tb.bus(n))
        dut._log.info("%s  dst_mac %012x  dst_ip %08x  dst_port %d",
                      name, g["eth"]["dst_mac"], g["ipv4"]["dst_ip"],
                      g["udp"]["dst_port"])


# ===========================================================================
# 7. Reset mid-frame
# ===========================================================================
@cocotb.test()
async def test_reset_mid_packet(dut):
    """All three stages must recover together from a mid-frame reset."""
    tb = PipelineTb(dut)
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
    tb.clear()

    frame = pkt.build_frame(dst_ip="233.71.185.148", udp_dst_port=21104,
                            src_mac="de:ad:be:ef:00:01")
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, (
        f"expected 1 pulse after reset, saw {len(tb.pulses)}"
    )
    assert tb.beat_of() == 5
    assert tb.bus() == expected_full_bus(frame)
    assert trunc_triple(tb.bus()) == (0, 0, 0), "reset left status bits set"


# ===========================================================================
# 8. IPv4 options - the real downstream cost
# ===========================================================================
@cocotb.test()
async def test_ihl_options_misparse(dut):
    """
    IHL=6 puts the UDP header 4 bytes further on than udp_parser assumes.

    The IPv4 stage is entirely correct - options sit after the addresses - and
    it raises ihl_invalid. The UDP stage then reads the wrong bytes, which is
    exactly the documented consequence of not supporting options.

    Nothing is gated. This test pins down what actually happens so the
    behaviour is a decision rather than a surprise.
    """
    tb = PipelineTb(dut)
    await tb.start()

    frame = pkt.build_frame(ihl=6)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # nothing dropped
    assert len(tb.pulses) == 1

    got = decode_all(tb.bus())

    # IPv4 stage: correct, and flags the problem
    check_fields(got["ipv4"], ip4.expected_ipv4_fields(frame), ctx="ipv4 ")
    assert got["ipv4"]["ihl_invalid"] == 1, "ihl_invalid not raised"

    # UDP stage: reads the fixed offset regardless, so it is wrong
    assert got["udp"]["dst_port"] != pkt.ASX_DST_PORT, (
        "expected the UDP header to be misparsed with options present"
    )
    # ...and wrong in exactly the predictable way: bytes 34-41 verbatim
    check_fields(got["udp"], mdl.expected_udp_fields(frame), ctx="udp ")

    assert trunc_triple(tb.bus()) == (0, 0, 0), (
        "options are not a truncation - the frame is full length"
    )
    dut._log.info("with IHL=6, udp read src %d dst %d (true dst is %d)",
                  got["udp"]["src_port"], got["udp"]["dst_port"],
                  pkt.ASX_DST_PORT)


# ===========================================================================
# 9. Fragmentation propagates
# ===========================================================================
@cocotb.test()
async def test_fragmented(dut):
    """frag_present must reach the output bus for the checker to act on."""
    tb = PipelineTb(dut)
    await tb.start()

    frame = pkt.build_frame(ip_flags_frag=0x2000)   # MF set
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    got = decode_all(tb.bus())
    assert got["ipv4"]["frag_present"] == 1, "frag_present not set"
    assert got["ipv4"]["flags"] & 0x1 == 1, "MF bit lost"
    assert trunc_triple(tb.bus()) == (0, 0, 0)
    assert tb.bus() == expected_full_bus(frame)


# ===========================================================================
# 10-12. Nested truncation
# ===========================================================================
@cocotb.test()
async def test_truncated_udp_only(dut):
    """
    40 bytes: ends on beat 4. Ethernet and IPv4 both complete; only UDP is
    short. Proves the three truncation bits are independent and correct.
    """
    tb = PipelineTb(dut)
    await tb.start()

    full = pkt.build_frame()
    frame = pkt.truncate(full, 40)
    beats = pkt.to_beats(frame)
    assert len(beats) == 5

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)      # forwarded, not dropped
    assert len(tb.pulses) == 1

    bus = tb.bus()
    assert trunc_triple(bus) == (0, 0, 1), (
        f"expected (eth,ipv4,udp) = (0,0,1), got {trunc_triple(bus)}"
    )

    got = decode_all(bus)
    check_fields(got["eth"], pkt.expected_eth_fields(full), ctx="eth ")
    check_fields(got["ipv4"], ip4.expected_ipv4_fields(full), ctx="ipv4 ")
    # UDP ports and length arrived on beat 4; the checksum did not
    check_fields(got["udp"], mdl.expected_udp_fields(full),
                 subset=["src_port", "dst_port", "length"], ctx="udp ")


@cocotb.test()
async def test_truncated_ipv4_and_udp(dut):
    """32 bytes: ends on beat 3. Ethernet complete, IPv4 and UDP both short."""
    tb = PipelineTb(dut)
    await tb.start()

    full = pkt.build_frame()
    frame = pkt.truncate(full, 32)
    beats = pkt.to_beats(frame)
    assert len(beats) == 4

    await tb.drive(beats)
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    bus = tb.bus()
    assert trunc_triple(bus) == (0, 1, 1), (
        f"expected (0,1,1), got {trunc_triple(bus)}"
    )

    got = decode_all(bus)
    check_fields(got["eth"], pkt.expected_eth_fields(full), ctx="eth ")
    # everything up to src_ip arrived; dst_ip did not
    check_fields(got["ipv4"], ip4.expected_ipv4_fields(full),
                 subset=["version", "ihl", "total_length", "ttl", "protocol",
                         "src_ip"], ctx="ipv4 ")


@cocotb.test()
async def test_truncated_all_three(dut):
    """8 bytes: ends on beat 0. Every stage reports truncation."""
    tb = PipelineTb(dut)
    await tb.start()

    full = pkt.build_frame()
    frame = pkt.truncate(full, 8)
    beats = pkt.to_beats(frame)
    assert len(beats) == 1

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1, "a runt must still settle the bus"

    bus = tb.bus()
    assert trunc_triple(bus) == (1, 1, 1), (
        f"expected (1,1,1), got {trunc_triple(bus)}"
    )

    # dst_mac is the only field whose bytes all arrived
    got = decode_all(bus)
    assert got["eth"]["dst_mac"] == int.from_bytes(frame[0:6], "big")


# ===========================================================================
# EDGE CASES
# ===========================================================================

# ---------------------------------------------------------------------------
# 13. Minimum-size Ethernet frame
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_min_ethernet_frame(dut):
    """
    60 bytes - the Ethernet minimum excluding FCS, which is the shortest
    frame a conforming MAC will ever emit.

    All three headers finish by byte 42, so everything completes normally.
    Worth pinning down because it is the real-world lower bound.
    """
    tb = PipelineTb(dut)
    await tb.start()

    full = pkt.build_frame()
    frame = pkt.truncate(full, 60)
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1
    assert tb.beat_of() == 5

    bus = tb.bus()
    assert trunc_triple(bus) == (0, 0, 0), (
        "a 60-byte frame contains every header in full"
    )
    assert bus == expected_full_bus(full), (
        "headers should decode identically to the full-length frame"
    )


# ---------------------------------------------------------------------------
# 14. Headers exactly fill the frame
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_exact_header_frame(dut):
    """
    42 bytes - Ethernet 14 + IPv4 20 + UDP 8, and not one byte more.

    The UDP header completes on the SAME beat that carries tlast. This is the
    boundary between complete and truncated, and the place an off-by-one in
    the completion guard would show up.
    """
    tb = PipelineTb(dut)
    await tb.start()

    full = pkt.build_frame()
    frame = pkt.truncate(full, 42)
    beats = pkt.to_beats(frame)
    assert len(beats) == 6, "42 bytes should be 6 beats"
    assert beats[-1][2] is True and beats[-1][1] == 0x03, (
        "final beat should carry 2 valid bytes"
    )

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)

    assert len(tb.pulses) == 1, (
        f"expected exactly 1 pulse, saw {len(tb.pulses)} - completion and "
        "tlast on the same beat must not double-pulse"
    )
    assert tb.beat_of() == 5

    bus = tb.bus()
    assert trunc_triple(bus) == (0, 0, 0), (
        "42 bytes is exactly enough - nothing is truncated"
    )
    assert bus == expected_full_bus(full)


# ---------------------------------------------------------------------------
# 15. Partial final beat - documents a known limitation
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_partial_final_beat(dut):
    """
    41 bytes: the UDP checksum's high byte arrives, its low byte does not.

    Truncation is tracked per BEAT, not per byte, and tkeep is not inspected.
    So the pipeline reports a complete UDP header while the checksum is half
    real and half zero-padding.

    This test asserts the CURRENT behaviour deliberately, so that adding
    tkeep-accurate truncation later is a conscious change rather than an
    accidental regression. See the tkeep discussion in the module notes.
    """
    tb = PipelineTb(dut)
    await tb.start()

    # distinctive checksum so the half-capture is visible
    full = patch16(pkt.build_frame(), mdl.UDP_OFF_UNTAGGED + 6, 0xABCD)
    frame = pkt.truncate(full, 41)
    beats = pkt.to_beats(frame)
    assert beats[-1][1] == 0x01, "final beat should carry 1 valid byte"

    await tb.drive(beats)
    await tb.settle()

    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    got = decode_all(tb.bus())

    assert got["udp"]["hdr_truncated"] == 0, (
        "current design tracks truncation per beat, not per byte"
    )
    assert got["udp"]["checksum"] == 0xAB00, (
        f"expected the low byte to read as zero padding, "
        f"got {got['udp']['checksum']:#06x}"
    )
    dut._log.info("KNOWN LIMITATION: checksum %04x, true value ABCD, "
                  "udp_hdr_truncated=0", got["udp"]["checksum"])


# ---------------------------------------------------------------------------
# 16. A bubble before every single beat
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_bubble_every_beat(dut):
    """
    One idle cycle before every beat - the pathological gap pattern.

    Halves the effective rate and puts a bubble at every header boundary in
    all three stages at once.
    """
    tb = PipelineTb(dut)
    await tb.start()

    frame = pkt.build_frame()
    beats = pkt.to_beats(frame)

    await tb.drive(beats, gaps=[1] * len(beats))
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1, f"expected 1 pulse, saw {len(tb.pulses)}"
    assert tb.beat_of() == 5
    assert tb.bus() == expected_full_bus(frame)


# ---------------------------------------------------------------------------
# 17. Long mixed burst
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_long_mixed_burst(dut):
    """
    20 frames back to back, alternating tagged and untagged, cycling through
    the ASX partitions.

    Stresses the per-packet beat counters and the vlan_present mux far harder
    than a two-packet test: any state that leaks between packets accumulates
    into a visible failure.
    """
    tb = PipelineTb(dut)
    await tb.start()

    n_frames = 20
    vid = 7
    tci = pkt.make_tci(vid=vid)

    all_beats = []
    expects = []
    for i in range(n_frames):
        name, src_ip, grp_ip, port = pkt.ASX_CHANNELS[i % len(pkt.ASX_CHANNELS)]
        tagged = (i % 2 == 0)
        f = pkt.build_frame(src_ip=src_ip, dst_ip=grp_ip, udp_dst_port=port,
                            vlan_vid=vid if tagged else None)
        all_beats += pkt.to_beats(f)
        expects.append((i, tagged, port,
                        expected_full_bus(f, tagged=tagged,
                                          vlan_tci=tci if tagged else 0)))

    await tb.drive(all_beats)
    await tb.settle()

    tb.check_passthrough(all_beats)
    assert len(tb.pulses) == n_frames, (
        f"expected {n_frames} pulses, saw {len(tb.pulses)}"
    )

    for n, (i, tagged, port, exp_bus) in enumerate(expects):
        assert tb.beat_of(n) == 5, f"frame {i}: pulse on beat {tb.beat_of(n)}"
        g = decode_all(tb.bus(n))
        assert g["eth"]["vlan_present"] == (1 if tagged else 0), (
            f"frame {i}: vlan_present wrong"
        )
        assert g["udp"]["dst_port"] == port, f"frame {i}: dst_port wrong"
        assert tb.bus(n) == exp_bus, f"frame {i}: bus mismatch"

    dut._log.info("%d frames, all buses correct", n_frames)


# ---------------------------------------------------------------------------
# 18. Degenerate all-ones frame
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_all_ones_header(dut):
    """
    Every header byte 0xFF. Not a valid packet by any measure, but it drives
    every capture path to all-ones and lights up most status bits at once:

        ethertype  0xFFFF  (not 0x8100, so NOT treated as a tag)
        version    15      -> version_invalid
        IHL        15      -> ihl_invalid
        flags/frag all set -> frag_present
        ports/len/cksum    0xFFFF

    A useful complement to the all-zero paths the normal frames exercise.
    """
    tb = PipelineTb(dut)
    await tb.start()

    frame = b"\xFF" * 84
    beats = pkt.to_beats(frame)

    await tb.drive(beats)
    await tb.settle()

    tb.check_tready()
    tb.check_passthrough(beats)
    assert len(tb.pulses) == 1

    got = decode_all(tb.bus())

    assert got["eth"]["vlan_present"] == 0, "0xFFFF must not match G_TPID"
    assert got["eth"]["ethertype"] == 0xFFFF
    assert got["eth"]["dst_mac"] == (1 << 48) - 1

    assert got["ipv4"]["version"] == 0xF
    assert got["ipv4"]["ihl"] == 0xF
    assert got["ipv4"]["version_invalid"] == 1
    assert got["ipv4"]["ihl_invalid"] == 1
    assert got["ipv4"]["frag_present"] == 1
    assert got["ipv4"]["src_ip"] == 0xFFFFFFFF
    assert got["ipv4"]["dst_ip"] == 0xFFFFFFFF

    assert got["udp"]["src_port"] == 0xFFFF
    assert got["udp"]["dst_port"] == 0xFFFF
    assert got["udp"]["length"] == 0xFFFF
    assert got["udp"]["checksum"] == 0xFFFF
    assert got["udp"]["len_invalid"] == 0, "0xFFFF is not < 8"

    assert trunc_triple(tb.bus()) == (0, 0, 0), (
        "a full-length frame is not truncated, however malformed"
    )
