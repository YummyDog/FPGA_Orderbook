"""
cocotb testbench for udp_parser (stage 3).

Standalone: s_fields is driven by the testbench rather than by real upstream
parsers, so this module is verified on its own.

One test case to start:

  1  test_single_asx_packet   one untagged ASX ITCH frame

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import asx_packets as pkt
import udp_model as mdl

CLK_PERIOD_NS = 6.4          # 156.25 MHz


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

    # -- hard requirements -------------------------------------------------
    tb.check_tready()
    tb.check_passthrough(beats)

    # -- completion timing -------------------------------------------------
    assert len(tb.pulses) == 1, (
        f"expected 1 fields_valid pulse, saw {len(tb.pulses)}"
    )
    idx, bus = tb.pulses[0]
    assert idx == 5, (
        f"UDP header should complete on beat 5, pulsed on beat {idx}"
    )

    # -- UDP field values --------------------------------------------------
    got = tb.fields()
    check_fields(got, expected)

    dut._log.info("src_port      = %d", got["src_port"])
    dut._log.info("dst_port      = %d", got["dst_port"])
    dut._log.info("length        = %d", got["length"])
    dut._log.info("checksum      = %04x", got["checksum"])
    dut._log.info("status: len_invalid %d  trunc %d",
                  got["len_invalid"], got["hdr_truncated"])

    # dst_port should be the ASX Channel A / Partition 1 multicast port
    assert got["dst_port"] == pkt.ASX_DST_PORT, (
        f"dst_port: got {got['dst_port']}, expected {pkt.ASX_DST_PORT}"
    )

    # -- upstream slice must pass through untouched ------------------------
    assert mdl.upstream_slice_of(bus) == upstream, (
        f"Ethernet + IPv4 slice corrupted: "
        f"got {mdl.upstream_slice_of(bus):#x}, expected {upstream:#x}"
    )

    # -- held to tlast -----------------------------------------------------
    assert tb.bus_at_tlast, "no tlast observed"
    held = mdl.decode_udp_fields(mdl.udp_slice_of(tb.bus_at_tlast[0]))
    assert held == got, "field bus not held to tlast"

    # -- internal 66-bit vector, if VHPI exposes it -------------------------
    # udp_fields is an internal signal, not a port. Reading it through NVC's
    # VHPI is best-effort; m_fields is the authoritative check above.
    try:
        internal = int(dut.udp_fields.value)
        assert internal == mdl.udp_slice_of(tb.bus_at_tlast[0]), (
            "internal udp_fields disagrees with the m_fields slice"
        )
        dut._log.info("internal udp_fields matches m_fields slice")
    except (AttributeError, ValueError) as e:
        dut._log.info("internal udp_fields not readable via VHPI (%s)", e)
