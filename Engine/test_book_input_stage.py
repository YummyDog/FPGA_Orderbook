"""
Testbench for book_input_stage.

The DUT takes ITCH messages 8 bytes per beat and emits a normalised command as
a ONE-CYCLE pulse on the beat carrying the last field it needs. Two properties
are checked throughout:

  * the payload matches book_model.expected_cmd for the message
  * the pulse lands on book_model.emit_beat(type) and is high for one cycle

There is no m_tready. The monitor samples every cycle, so a command held for
two cycles or emitted twice shows up as a duplicate rather than being missed.

Run with book_sim.ps1.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import book_model as bm

CLK_NS = 6.21          # 161 MHz, matching the synthesis constraint
BOOK_ID = bm.DEFAULT_BOOK_ID


# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------
class Harness:
    """Clock, reset, driver and monitor for one test."""

    def __init__(self, dut):
        self.dut = dut
        self.seen = []         # commands captured from the output pulse
        self.pulse_cycles = 0  # total cycles m_tvalid was high
        self.cycle = 0         # cycles since reset released

    async def start(self):
        cocotb.start_soon(Clock(self.dut.clk, CLK_NS, units="ns").start())

        self.dut.resetn.value = 0
        self.dut.s_tvalid.value = 0
        self.dut.s_tdata.value = 0
        self.dut.s_tlast.value = 0

        for _ in range(5):
            await RisingEdge(self.dut.clk)
        self.dut.resetn.value = 1
        await RisingEdge(self.dut.clk)

        cocotb.start_soon(self._monitor())

    async def _monitor(self):
        while True:
            await RisingEdge(self.dut.clk)
            await ReadOnly()
            self.cycle += 1
            if self.dut.m_tvalid.value == 1:
                self.pulse_cycles += 1
                self.seen.append(self._sample())

    def _sample(self):
        d = self.dut
        return {
            "op": int(d.m_op.value),
            "order_id": int(d.m_order_id.value),
            "book_id": int(d.m_book_id.value),
            "side": int(d.m_side.value),
            "qty": int(d.m_qty.value),
            "price": bm.to_signed(int(d.m_price.value)),
            "px_valid": int(d.m_px_valid.value),
            "undisc": int(d.m_undisc.value),
            "implied": int(d.m_implied.value),
            "cycle": self.cycle,
        }

    async def send(self, msg, gap=0, stall_before=None):
        """
        Drive one message.

        gap           idle cycles after the last beat
        stall_before  beat index to insert one idle cycle in front of, proving
                      the beat counter advances on handshake and not on time
        """
        beats = bm.to_beats(msg)
        last = len(beats) - 1
        for i, b in enumerate(beats):
            if stall_before is not None and i == stall_before:
                self.dut.s_tvalid.value = 0
                await RisingEdge(self.dut.clk)
            self.dut.s_tvalid.value = 1
            self.dut.s_tdata.value = b
            self.dut.s_tlast.value = 1 if i == last else 0
            await RisingEdge(self.dut.clk)
        self.dut.s_tvalid.value = 0
        self.dut.s_tlast.value = 0
        for _ in range(gap):
            await RisingEdge(self.dut.clk)

    async def drain(self, cycles=6):
        """Let a trailing pulse land before the checks run."""
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)


def check(actual, expected, what=""):
    """Compare a captured command against the model, field by field."""
    for k, v in expected.items():
        got = actual[k]
        assert got == v, (
            f"{what}: {k} = {got}, expected {v}\n"
            f"  got      {actual}\n  expected {expected}"
        )


# ---------------------------------------------------------------------------
# One message per type
# ---------------------------------------------------------------------------
async def _one_message(dut, msg, label):
    h = Harness(dut)
    await h.start()
    await h.send(msg)
    await h.drain()

    exp = bm.expected_cmd(msg, BOOK_ID)
    assert len(h.seen) == 1, f"{label}: {len(h.seen)} commands emitted, expected 1"
    check(h.seen[0], exp, label)
    assert h.pulse_cycles == 1, (
        f"{label}: m_tvalid high for {h.pulse_cycles} cycles, expected 1"
    )
    return h


@cocotb.test()
async def test_add_order(dut):
    """A - add order, absolute quantity and a resting price."""
    await _one_message(dut, bm.build_add(order_id=0x1122334455667788,
                                         qty=1234, price=5678), "A")


@cocotb.test()
async def test_add_order_with_pid(dut):
    """F - same fields as A plus a participant id the book must ignore."""
    await _one_message(dut, bm.build_add(order_id=0x99, qty=7, price=42,
                                         with_pid=True), "F")


@cocotb.test()
async def test_replace(dut):
    """U - replace, absolute quantity, price valid."""
    await _one_message(dut, bm.build_replace(order_id=0xABCD, qty=500,
                                             price=1500), "U")


@cocotb.test()
async def test_executed(dut):
    """E - quantity is a delta and there is no price field at all."""
    h = await _one_message(dut, bm.build_exec(order_id=0x55, qty=25), "E")
    assert h.seen[0]["px_valid"] == 0, "E must not carry a price"


@cocotb.test()
async def test_executed_with_price(dut):
    """
    C - the price field is the TRADE price and must never reach the book.

    The resting price comes from the order table, so px_valid stays low and
    the trade price is not allowed to appear on m_price.
    """
    trade_px = 0x7EAD
    msg = bm.build_exec(order_id=0x66, qty=30, trade_price=trade_px)
    h = await _one_message(dut, msg, "C")
    assert h.seen[0]["px_valid"] == 0, "C must not set px_valid"
    assert h.seen[0]["price"] != trade_px, "trade price leaked onto m_price"


@cocotb.test()
async def test_delete(dut):
    """D - identity only, neither quantity nor price."""
    h = await _one_message(dut, bm.build_delete(order_id=0x77,
                                                side=bm.SIDE_SELL), "D")
    assert h.seen[0]["side"] == 1
    assert h.seen[0]["px_valid"] == 0


# ---------------------------------------------------------------------------
# Emit timing - the point of the rewrite
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_emit_beat(dut):
    """
    Each type emits on the beat carrying its last needed field.

    The pulse is registered, so it lands one cycle after that beat. Sending
    each message from a known idle point makes the beat number recoverable
    from the capture cycle.
    """
    cases = [
        (bm.build_add(1), bm.T_ADD),
        (bm.build_add(2, with_pid=True), bm.T_ADD_PID),
        (bm.build_replace(3), bm.T_REPLACE),
        (bm.build_exec(4), bm.T_EXEC),
        (bm.build_exec(5, trade_price=100), bm.T_EXEC_PRICE),
        (bm.build_delete(6), bm.T_DELETE),
    ]

    for msg, mtype in cases:
        h = Harness(dut)
        await h.start()

        start = h.cycle
        await h.send(msg)
        await h.drain()

        name = bm.TYPE_NAME[mtype]
        assert len(h.seen) == 1, f"{name}: expected exactly one command"

        # Beat i is driven across cycle start+i; the pulse is sampled one
        # cycle later.
        got_beat = h.seen[0]["cycle"] - start - 1
        want_beat = bm.emit_beat(mtype)
        assert got_beat == want_beat, (
            f"{name}: emitted on beat {got_beat}, expected {want_beat}"
        )

        # And it must be strictly before the end of the message for the types
        # where that is possible at all.
        total = bm.n_beats(msg)
        if mtype in (bm.T_ADD_PID, bm.T_EXEC, bm.T_EXEC_PRICE):
            assert got_beat < total - 1, (
                f"{name}: emitted on the last beat, no saving"
            )


@cocotb.test()
async def test_stall_mid_message(dut):
    """Beats advance on handshake, not on time. An idle cycle changes nothing."""
    msg = bm.build_exec(order_id=0x88, qty=9, trade_price=1)
    h = Harness(dut)
    await h.start()
    await h.send(msg, stall_before=2)
    await h.drain()

    assert len(h.seen) == 1, "a gap mid-message must not lose the command"
    check(h.seen[0], bm.expected_cmd(msg, BOOK_ID), "stalled C")


# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_wrong_book_dropped(dut):
    """A well-formed message for another instrument is discarded."""
    h = Harness(dut)
    await h.start()
    await h.send(bm.build_add(order_id=1, book_id=BOOK_ID + 1))
    await h.drain()
    assert h.seen == [], "message for another order book was forwarded"


@cocotb.test()
async def test_bad_side_dropped(dut):
    """An unrecognised side byte drops the message."""
    h = Harness(dut)
    await h.start()
    await h.send(bm.build_add(order_id=1, side=bm.SIDE_BLANK))
    await h.send(bm.build_add(order_id=2, side=ord("X")))
    await h.drain()
    assert h.seen == [], "message with an unrecognised side was forwarded"


@cocotb.test()
async def test_non_book_types_dropped(dut):
    """
    Every framed type the book ignores, junk-filled.

    build_other puts non-zero bytes where a book message carries its order id,
    side and quantity, so a decode that fails to gate on type emits a visibly
    wrong command rather than a harmless zero one.
    """
    h = Harness(dut)
    await h.start()

    for t in bm.ALL_TYPES:
        if t in bm.BOOK_TYPES:
            continue
        await h.send(bm.build_other(t), gap=2)

    await h.drain()
    assert h.seen == [], f"non-book type forwarded: {h.seen}"


@cocotb.test()
async def test_trade_dropped(dut):
    """
    P - trade. Never affects the displayed book (spec 2.7).

    Its layout differs from E/C, so a decoder that treats P like an execution
    reads garbage rather than nothing.
    """
    h = Harness(dut)
    await h.start()
    await h.send(bm.build_trade())
    await h.drain()
    assert h.seen == [], "trade message reached the book"


# ---------------------------------------------------------------------------
# Field edges
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_qty_saturation(dut):
    """A wire quantity above 32 bits saturates rather than truncating."""
    msg = bm.build_add(order_id=1, qty=(1 << 40) + 7)
    h = await _one_message(dut, msg, "saturating qty")
    assert h.seen[0]["qty"] == bm.QTY_MAX, "quantity did not saturate"


@cocotb.test()
async def test_qty_boundary(dut):
    """The largest quantity that still fits 32 bits passes through intact."""
    await _one_message(dut, bm.build_add(order_id=1, qty=0xFFFFFFFF),
                       "boundary qty")


@cocotb.test()
async def test_negative_price(dut):
    """Price is signed and survives as two's complement."""
    h = await _one_message(dut, bm.build_add(order_id=1, price=-12345),
                           "negative price")
    assert h.seen[0]["price"] == -12345


@cocotb.test()
async def test_extype_bits(dut):
    """Undisclosed and implied come from the exchange order type bitmap."""
    for extype, undisc, implied in [
        (0, 0, 0),
        (bm.EXT_UNDISCLOSED, 1, 0),
        (bm.EXT_IMPLIED, 0, 1),
        (bm.EXT_UNDISCLOSED | bm.EXT_IMPLIED, 1, 1),
        (bm.EXT_MARKET_BID | bm.EXT_PRICE_STAB, 0, 0),   # neighbours, not ours
    ]:
        msg = bm.build_add(order_id=1, extype=extype)
        h = await _one_message(dut, msg, f"extype {extype:#x}")
        assert h.seen[0]["undisc"] == undisc
        assert h.seen[0]["implied"] == implied


@cocotb.test()
async def test_both_sides(dut):
    """Buy and sell both decode, and the polarity is the right way round."""
    h = Harness(dut)
    await h.start()
    await h.send(bm.build_add(order_id=1, side=bm.SIDE_BUY), gap=2)
    await h.send(bm.build_add(order_id=2, side=bm.SIDE_SELL), gap=2)
    await h.drain()

    assert len(h.seen) == 2
    assert h.seen[0]["side"] == 0, "'B' must decode to side 0"
    assert h.seen[1]["side"] == 1, "'S' must decode to side 1"


# ---------------------------------------------------------------------------
# Streams
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_back_to_back(dut):
    """
    A mixed stream with no gaps between messages.

    Drops are removed from the expectation by expected_stream, so this also
    proves the filtered messages leave no residue in the assembly buffer for
    the following message to pick up.
    """
    msgs = [
        bm.build_add(order_id=1, qty=100, price=1000),
        bm.build_exec(order_id=1, qty=40),
        bm.build_other(bm.T_SECONDS),
        bm.build_replace(order_id=1, qty=60, price=1010),
        bm.build_exec(order_id=1, qty=60, trade_price=999),
        bm.build_add(order_id=2, book_id=BOOK_ID + 1),        # dropped
        bm.build_add(order_id=3, side=bm.SIDE_SELL, qty=5, price=2000),
        bm.build_trade(),                                     # dropped
        bm.build_delete(order_id=3, side=bm.SIDE_SELL),
        bm.build_add(order_id=4, with_pid=True, qty=9, price=7),
    ]

    h = Harness(dut)
    await h.start()
    for m in msgs:
        await h.send(m)
    await h.drain()

    exp = bm.expected_stream(msgs, BOOK_ID)
    assert len(h.seen) == len(exp), (
        f"{len(h.seen)} commands emitted, expected {len(exp)}"
    )
    for i, (got, want) in enumerate(zip(h.seen, exp)):
        check(got, want, f"stream index {i}")

    assert h.pulse_cycles == len(exp), (
        f"m_tvalid high for {h.pulse_cycles} cycles, expected {len(exp)}"
    )


@cocotb.test()
async def test_short_after_long(dut):
    """
    A short message straight after a long one.

    D reads only up to byte 17, so beats 3 and 4 still hold the previous
    message. Nothing may leak from them into the emitted command.
    """
    h = Harness(dut)
    await h.start()
    await h.send(bm.build_add(order_id=0xAAAA, qty=999, price=888,
                              extype=bm.EXT_UNDISCLOSED | bm.EXT_IMPLIED))
    await h.send(bm.build_delete(order_id=0xBBBB))
    await h.drain()

    assert len(h.seen) == 2
    d = h.seen[1]
    check(d, bm.expected_cmd(bm.build_delete(order_id=0xBBBB), BOOK_ID),
          "delete after add")
    assert d["undisc"] == 0 and d["implied"] == 0, "extype leaked into D"
    assert d["qty"] == 0 and d["price"] == 0, "payload leaked into D"


@cocotb.test()
async def test_reset_mid_message(dut):
    """Reset part way through a message abandons it cleanly."""
    h = Harness(dut)
    await h.start()

    msg = bm.build_add(order_id=1)
    beats = bm.to_beats(msg)
    for b in beats[:3]:                      # stop before the emit beat
        dut.s_tvalid.value = 1
        dut.s_tdata.value = b
        dut.s_tlast.value = 0
        await RisingEdge(dut.clk)
    dut.s_tvalid.value = 0

    dut.resetn.value = 0
    await RisingEdge(dut.clk)
    dut.resetn.value = 1
    await RisingEdge(dut.clk)

    h.seen.clear()
    h.pulse_cycles = 0

    good = bm.build_add(order_id=0x1234, qty=11, price=22)
    await h.send(good)
    await h.drain()

    assert len(h.seen) == 1, "message after reset was lost or duplicated"
    check(h.seen[0], bm.expected_cmd(good, BOOK_ID), "after reset")
