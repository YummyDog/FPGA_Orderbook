"""
cocotb testbench for book_input_stage (module 1 of the order book engine).

Standalone: raw ITCH messages are built by the testbench rather than sourced
from the real parser, so this module is verified on its own.

Test cases, in order:

  1  test_add_order              baseline A - absolute quantity, valid price
  2  test_add_with_participant   F decodes identically to A
  3  test_order_executed         E - quantity is a DELTA, no price
  4  test_executed_with_price    C - trade price must NOT reach the output
  5  test_order_replace          U - absolute quantity, valid price, flags
  6  test_order_delete           D - identity only
  7  test_side_decode            'B' and 'S' map to 0 and 1
  8  test_bad_side_dropped       any other side byte is discarded
  9  test_wrong_order_book       other instruments filtered out
 10  test_non_book_types         T S R M L O Z all discarded
 11  test_trade_message_dropped  P discarded despite being a real ITCH message
 12  test_extype_flags           undisclosed and implied bit decode
 13  test_negative_price         combination books use negative prices
 14  test_price_sentinel         0x80000000 passes through unmangled
 15  test_undisclosed_zero_qty   undisclosed orders rest with quantity 0
 16  test_quantity_saturation    >32-bit quantity saturates, never truncates
 17  test_back_to_back           consecutive messages, no bubble
 18  test_backpressure           m_tready low holds output, stalls s_tready
 19  test_drop_between_valid     discards must not disturb neighbours
 20  test_reset_mid_stream       recovery from a mid-stream reset
 21  test_book_id_forwarded      m_book_id carries the instrument, not zero
 22  test_random_stream          randomised mix checked against the model

Every test also re-checks the hard requirement: exactly one output command
per accepted book message, and nothing at all for anything else.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import book_model as mdl

CLK_PERIOD_NS = 6.4          # 156.25 MHz

BOOK_ID = mdl.DEFAULT_BOOK_ID
OTHER_BOOK = 70669           # a different real-looking ASX order book id


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------
def safe_int(handle):
    """Signals read 'U' before reset; treat unresolvable as absent."""
    try:
        return int(handle.value)
    except ValueError:
        return None


def read_op(handle):
    """
    Read t_book_op as an index into mdl.OP_NAMES.

    NVC may present a VHDL enumeration as either its ordinal or its literal
    name depending on cocotb version, so both are accepted.
    """
    v = handle.value
    try:
        return int(v)
    except (ValueError, TypeError):
        name = str(v).strip().upper()
        if name in mdl.OP_NAMES:
            return mdl.OP_NAMES.index(name)
        raise AssertionError(f"unrecognised t_book_op value: {v!r}")


def check_fields(got: dict, expected: dict, subset=None, ctx=""):
    keys = subset if subset else expected.keys()
    for name in keys:
        assert got[name] == expected[name], (
            f"{ctx}{name}: got {got[name]}, expected {expected[name]}"
        )


# ---------------------------------------------------------------------------
# Testbench harness
# ---------------------------------------------------------------------------
class BookInputTb:
    def __init__(self, dut):
        self.dut = dut
        self.cmds = []               # one dict per output transfer

    # -- lifecycle ---------------------------------------------------------
    async def start(self):
        cocotb.start_soon(Clock(self.dut.clk, CLK_PERIOD_NS, unit="ns").start())
        await self.reset()
        cocotb.start_soon(self._monitor())

    async def reset(self, cycles: int = 5):
        d = self.dut
        d.s_tvalid.value = 0
        d.s_ttype.value = 0
        d.s_tdata.value = 0
        d.m_tready.value = 1
        d.resetn.value = 0
        for _ in range(cycles):
            await RisingEdge(d.clk)
        d.resetn.value = 1
        await RisingEdge(d.clk)

    def clear(self):
        self.cmds.clear()

    # -- monitor -----------------------------------------------------------
    async def _monitor(self):
        """Capture every completed output handshake."""
        d = self.dut
        while True:
            await RisingEdge(d.clk)
            await ReadOnly()

            if safe_int(d.m_tvalid) == 1 and safe_int(d.m_tready) == 1:
                self.cmds.append({
                    "op": read_op(d.m_op),
                    "order_id": safe_int(d.m_order_id),
                    "book_id": safe_int(d.m_book_id),
                    "side": safe_int(d.m_side),
                    "qty": safe_int(d.m_qty),
                    "price": mdl.to_signed(safe_int(d.m_price)),
                    "px_valid": safe_int(d.m_px_valid),
                    "undisc": safe_int(d.m_undisc),
                    "implied": safe_int(d.m_implied),
                })

    # -- stimulus ----------------------------------------------------------
    async def send(self, msg: bytes, gap: int = 0):
        """Push one message, honouring s_tready. Optional idle cycles first."""
        d = self.dut
        for _ in range(gap):
            await RisingEdge(d.clk)
            d.s_tvalid.value = 0

        await RisingEdge(d.clk)
        d.s_ttype.value = msg[0]
        d.s_tdata.value = mdl.to_int(msg)
        d.s_tvalid.value = 1

        # Hold until the DUT accepts the beat.
        while True:
            await ReadOnly()
            if safe_int(d.s_tready) == 1:
                break
            await RisingEdge(d.clk)

        await RisingEdge(d.clk)
        d.s_tvalid.value = 0

    async def send_stream(self, msgs, gaps=None):
        """Push several messages back to back."""
        d = self.dut
        for i, m in enumerate(msgs):
            await self.send(m, gap=(gaps[i] if gaps else 0))
        d.s_tvalid.value = 0

    async def settle(self, cycles: int = 8):
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)

    # -- checks ------------------------------------------------------------
    def expect_count(self, n: int, ctx=""):
        assert len(self.cmds) == n, (
            f"{ctx}expected {n} command(s), saw {len(self.cmds)}"
        )

    def expect_dropped(self, ctx=""):
        assert len(self.cmds) == 0, (
            f"{ctx}expected the message to be dropped, "
            f"saw {len(self.cmds)} command(s): {self.cmds}"
        )

    def cmd(self, n: int = 0) -> dict:
        assert len(self.cmds) > n, f"no command at index {n}"
        return self.cmds[n]


# ===========================================================================
# 1. Baseline - Add Order
# ===========================================================================
@cocotb.test()
async def test_add_order(dut):
    """A: quantity is absolute, price is the resting price and is valid."""
    tb = BookInputTb(dut)
    await tb.start()

    msg = mdl.build_add(order_id=5, qty=1000, price=2610, position=1)
    expected = mdl.expected_cmd(msg)

    await tb.send(msg)
    await tb.settle()

    tb.expect_count(1)
    check_fields(tb.cmd(), expected)
    assert tb.cmd()["op"] == mdl.OP_ADD
    assert tb.cmd()["px_valid"] == 1, "A must carry a usable price"

    dut._log.info("A: order %d qty %d price %d",
                  tb.cmd()["order_id"], tb.cmd()["qty"], tb.cmd()["price"])


# ===========================================================================
# 2. Add Order with participant id
# ===========================================================================
@cocotb.test()
async def test_add_with_participant(dut):
    """
    F is A plus a 7-byte participant id at bytes 37-43.

    The extra field sits past everything the book reads, so F must decode
    identically to an A with the same values.
    """
    tb = BookInputTb(dut)
    await tb.start()

    a = mdl.build_add(order_id=77, qty=250, price=1550, side=mdl.SIDE_SELL)
    f = mdl.build_add(order_id=77, qty=250, price=1550, side=mdl.SIDE_SELL,
                      with_pid=True)

    await tb.send(a)
    await tb.send(f)
    await tb.settle()

    tb.expect_count(2)
    assert tb.cmd(0) == tb.cmd(1), (
        f"F decoded differently from A:\n  A: {tb.cmd(0)}\n  F: {tb.cmd(1)}"
    )
    check_fields(tb.cmd(1), mdl.expected_cmd(f))


# ===========================================================================
# 3. Order Executed
# ===========================================================================
@cocotb.test()
async def test_order_executed(dut):
    """
    E: quantity at bytes 18-25 is the EXECUTED amount, a delta to subtract.

    E carries no price field at all, so px_valid must be low - the resting
    price can only come from the order table downstream.
    """
    tb = BookInputTb(dut)
    await tb.start()

    msg = mdl.build_exec(order_id=5, qty=300)
    expected = mdl.expected_cmd(msg)

    await tb.send(msg)
    await tb.settle()

    tb.expect_count(1)
    check_fields(tb.cmd(), expected)
    assert tb.cmd()["op"] == mdl.OP_EXEC
    assert tb.cmd()["qty"] == 300, "executed quantity must pass through as a delta"
    assert tb.cmd()["px_valid"] == 0, "E has no price field, px_valid must be low"


# ===========================================================================
# 4. Order Executed with Price - the trade price must not escape
# ===========================================================================
@cocotb.test()
async def test_executed_with_price(dut):
    """
    C carries a price at bytes 52-55, but it is the TRADE price, not the
    order's resting price (spec 2.6.2.2 - auction crossings).

    Letting it through would decrement a price level the order never sat at,
    leaving the real level permanently overstated. px_valid must be low, and
    the trade price must not appear on m_price.
    """
    tb = BookInputTb(dut)
    await tb.start()

    resting_price = 2610
    trade_price = 2595

    add = mdl.build_add(order_id=5, qty=500, price=resting_price)
    c = mdl.build_exec(order_id=5, qty=500, trade_price=trade_price)

    await tb.send(add)
    await tb.send(c)
    await tb.settle()

    tb.expect_count(2)

    got = tb.cmd(1)
    assert got["op"] == mdl.OP_EXEC
    assert got["qty"] == 500
    assert got["px_valid"] == 0, (
        "px_valid must be low on C - the trade price is not the book price"
    )
    assert got["price"] != trade_price, (
        f"trade price {trade_price} leaked onto m_price"
    )

    check_fields(got, mdl.expected_cmd(c))


# ===========================================================================
# 5. Order Replace
# ===========================================================================
@cocotb.test()
async def test_order_replace(dut):
    """U: absolute quantity and a valid price, same offsets as A."""
    tb = BookInputTb(dut)
    await tb.start()

    msg = mdl.build_replace(order_id=7, side=mdl.SIDE_SELL, qty=100,
                            price=3000, position=2,
                            extype=mdl.EXT_UNDISCLOSED | mdl.EXT_IMPLIED)
    expected = mdl.expected_cmd(msg)

    await tb.send(msg)
    await tb.settle()

    tb.expect_count(1)
    check_fields(tb.cmd(), expected)
    assert tb.cmd()["op"] == mdl.OP_REPLACE
    assert tb.cmd()["px_valid"] == 1
    assert tb.cmd()["undisc"] == 1
    assert tb.cmd()["implied"] == 1


# ===========================================================================
# 6. Order Delete
# ===========================================================================
@cocotb.test()
async def test_order_delete(dut):
    """
    D is 18 bytes: identity only, no quantity and no price.

    px_valid must be low. The bytes past 17 in the buffer are stale from
    whatever came before, so a decoder that reads a price here would emit
    a plausible-looking wrong value.
    """
    tb = BookInputTb(dut)
    await tb.start()

    # Prime the buffer with a large A first so stale bytes are non-zero.
    await tb.send(mdl.build_add(order_id=1, qty=9999, price=5555))
    await tb.send(mdl.build_delete(order_id=0xAB, side=mdl.SIDE_SELL))
    await tb.settle()

    tb.expect_count(2)

    got = tb.cmd(1)
    assert got["op"] == mdl.OP_DELETE
    assert got["order_id"] == 0xAB
    assert got["side"] == 1
    assert got["px_valid"] == 0, "D carries no price"


# ===========================================================================
# 7. Side decode
# ===========================================================================
@cocotb.test()
async def test_side_decode(dut):
    """'B' (0x42) maps to 0, 'S' (0x53) maps to 1."""
    tb = BookInputTb(dut)
    await tb.start()

    await tb.send(mdl.build_add(order_id=1, side=mdl.SIDE_BUY))
    await tb.send(mdl.build_add(order_id=2, side=mdl.SIDE_SELL))
    await tb.settle()

    tb.expect_count(2)
    assert tb.cmd(0)["side"] == 0, "'B' must decode to 0"
    assert tb.cmd(1)["side"] == 1, "'S' must decode to 1"


# ===========================================================================
# 8. Unrecognised side byte
# ===========================================================================
@cocotb.test()
async def test_bad_side_dropped(dut):
    """
    Anything other than 'B' or 'S' is unusable - the command could not be
    routed to a side - so the message is consumed and discarded.
    """
    tb = BookInputTb(dut)
    await tb.start()

    for bad in (mdl.SIDE_BLANK, 0x00, 0xFF, ord("X")):
        tb.clear()
        await tb.send(mdl.build_add(order_id=1, side=bad))
        await tb.settle()
        tb.expect_dropped(ctx=f"side {bad:#04x}: ")


# ===========================================================================
# 9. Wrong order book
# ===========================================================================
@cocotb.test()
async def test_wrong_order_book(dut):
    """
    Only the configured instrument is tracked. A well-formed Add for a
    different order book must be discarded, and must not disturb the
    messages either side of it.
    """
    tb = BookInputTb(dut)
    await tb.start()

    await tb.send(mdl.build_add(order_id=1, book_id=BOOK_ID, qty=10))
    await tb.send(mdl.build_add(order_id=2, book_id=OTHER_BOOK, qty=20))
    await tb.send(mdl.build_add(order_id=3, book_id=BOOK_ID, qty=30))
    await tb.settle()

    tb.expect_count(2)
    assert tb.cmd(0)["order_id"] == 1
    assert tb.cmd(1)["order_id"] == 3, "the other book's message was not dropped"


# ===========================================================================
# 10. Non-book message types
# ===========================================================================
@cocotb.test()
async def test_non_book_types(dut):
    """
    The parser emits a valid pulse for every framed message, including
    reference data and state messages. Only A F E C U D affect the book.

    These are built with 0xA5 fill, so a DUT that fails to gate on type
    would emit a command with a visibly wrong order id rather than a
    harmless zero one.
    """
    tb = BookInputTb(dut)
    await tb.start()

    for mtype in (mdl.T_SECONDS, mdl.T_SYSEVENT, mdl.T_BOOKDIR,
                  mdl.T_COMBODIR, mdl.T_TICKSIZE, mdl.T_BOOKSTATE,
                  mdl.T_EQUILIBRIUM):
        tb.clear()
        await tb.send(mdl.build_other(mtype))
        await tb.settle()
        tb.expect_dropped(ctx=f"type {mdl.TYPE_NAME[mtype]}: ")
        dut._log.info("%s dropped", mdl.TYPE_NAME[mtype])


# ===========================================================================
# 11. Trade messages
# ===========================================================================
@cocotb.test()
async def test_trade_message_dropped(dut):
    """
    P is a real, fully decoded ITCH message but does not alter the displayed
    book (spec 2.7). Its layout also differs from E/C - match id comes first
    and there is no order id - so treating it as an execution reads garbage.
    """
    tb = BookInputTb(dut)
    await tb.start()

    await tb.send(mdl.build_add(order_id=1, qty=100))
    await tb.send(mdl.build_trade(qty=500, price=1234))
    await tb.send(mdl.build_add(order_id=2, qty=200))
    await tb.settle()

    tb.expect_count(2)
    assert tb.cmd(0)["order_id"] == 1
    assert tb.cmd(1)["order_id"] == 2, "P was not dropped"


# ===========================================================================
# 12. Exchange Order Type flags
# ===========================================================================
@cocotb.test()
async def test_extype_flags(dut):
    """
    Undisclosed (bit 5) and implied (bit 13) must be captured on A/F/U -
    they are unrecoverable at execution time and drive the removal rule
    downstream. Other bits in the bitmap must not disturb them.
    """
    tb = BookInputTb(dut)
    await tb.start()

    cases = [
        (0, 0, 0),
        (mdl.EXT_UNDISCLOSED, 1, 0),
        (mdl.EXT_IMPLIED, 0, 1),
        (mdl.EXT_UNDISCLOSED | mdl.EXT_IMPLIED, 1, 1),
        (mdl.EXT_MARKET_BID | mdl.EXT_PRICE_STAB, 0, 0),
        (0xFFFF, 1, 1),
    ]

    for i, (ext, _, _) in enumerate(cases):
        await tb.send(mdl.build_add(order_id=i, extype=ext))
    await tb.settle()

    tb.expect_count(len(cases))
    for i, (ext, exp_u, exp_i) in enumerate(cases):
        got = tb.cmd(i)
        assert got["undisc"] == exp_u, (
            f"extype {ext:#06x}: undisc got {got['undisc']}, expected {exp_u}"
        )
        assert got["implied"] == exp_i, (
            f"extype {ext:#06x}: implied got {got['implied']}, expected {exp_i}"
        )


# ===========================================================================
# 13. Negative prices
# ===========================================================================
@cocotb.test()
async def test_negative_price(dut):
    """
    ASX prices are signed - combination books quote negative values.
    An unsigned decode would turn -100 into 4294967196.
    """
    tb = BookInputTb(dut)
    await tb.start()

    for px in (-1, -100, -32768, -2147483647):
        tb.clear()
        msg = mdl.build_add(order_id=1, price=px)
        await tb.send(msg)
        await tb.settle()
        tb.expect_count(1, ctx=f"price {px}: ")
        assert tb.cmd()["price"] == px, (
            f"price got {tb.cmd()['price']}, expected {px}"
        )


# ===========================================================================
# 14. Null price sentinel
# ===========================================================================
@cocotb.test()
async def test_price_sentinel(dut):
    """
    0x80000000 (INT32_MIN) is the ITCH no-price sentinel. This module does
    not interpret it - it must pass through unmangled so downstream can.
    """
    tb = BookInputTb(dut)
    await tb.start()

    msg = mdl.build_add(order_id=1, price=-2147483648)
    await tb.send(msg)
    await tb.settle()

    tb.expect_count(1)
    assert tb.cmd()["price"] == -2147483648, "sentinel price was altered"
    assert tb.cmd()["px_valid"] == 1, "sentinel is still a present price field"


# ===========================================================================
# 15. Undisclosed orders rest with zero quantity
# ===========================================================================
@cocotb.test()
async def test_undisclosed_zero_qty(dut):
    """
    Undisclosed orders are added with Quantity = 0 and contribute nothing
    visible. A zero quantity is legitimate here and must still produce a
    command - it is not an error and must not be filtered.
    """
    tb = BookInputTb(dut)
    await tb.start()

    msg = mdl.build_add(order_id=42, qty=0, price=2000,
                        extype=mdl.EXT_UNDISCLOSED)
    await tb.send(msg)
    await tb.settle()

    tb.expect_count(1, ctx="zero-quantity undisclosed add: ")
    assert tb.cmd()["qty"] == 0
    assert tb.cmd()["undisc"] == 1
    assert tb.cmd()["op"] == mdl.OP_ADD


# ===========================================================================
# 16. Quantity saturation
# ===========================================================================
@cocotb.test()
async def test_quantity_saturation(dut):
    """
    Quantity is 8 bytes on the wire but 32 bits on the command bus. A value
    that does not fit must saturate, not truncate: truncating 0x100000005
    would silently produce 5.

    Not expected on real ASX data - this proves the failure mode is loud.
    """
    tb = BookInputTb(dut)
    await tb.start()

    cases = [
        (0xFFFFFFFF, 0xFFFFFFFF),          # largest value that still fits
        (0x100000000, mdl.QTY_MAX),        # one past
        (0x100000005, mdl.QTY_MAX),        # would truncate to 5
        (0xFFFFFFFFFFFFFFFF, mdl.QTY_MAX),  # all ones
    ]

    for i, (wire, exp) in enumerate(cases):
        tb.clear()
        await tb.send(mdl.build_add(order_id=i, qty=wire))
        await tb.settle()
        tb.expect_count(1, ctx=f"qty {wire:#x}: ")
        assert tb.cmd()["qty"] == exp, (
            f"qty {wire:#x}: got {tb.cmd()['qty']:#x}, expected {exp:#x}"
        )


# ===========================================================================
# 17. Back to back
# ===========================================================================
@cocotb.test()
async def test_back_to_back(dut):
    """
    Consecutive accepted messages must produce consecutive commands with no
    bubble and no reordering. Uses a realistic add/execute/delete sequence.
    """
    tb = BookInputTb(dut)
    await tb.start()

    msgs = [
        mdl.build_add(order_id=1, qty=1000, price=2610),
        mdl.build_add(order_id=2, qty=500, price=2600, side=mdl.SIDE_SELL),
        mdl.build_exec(order_id=1, qty=300),
        mdl.build_replace(order_id=2, qty=400, price=2605,
                          side=mdl.SIDE_SELL),
        mdl.build_delete(order_id=1),
    ]
    expected = mdl.expected_stream(msgs)

    await tb.send_stream(msgs)
    await tb.settle()

    tb.expect_count(len(expected))
    for i, exp in enumerate(expected):
        check_fields(tb.cmd(i), exp, ctx=f"msg {i} ")


# ===========================================================================
# 18. Backpressure
# ===========================================================================
@cocotb.test()
async def test_backpressure(dut):
    """
    With m_tready low the output must hold its value and s_tready must fall,
    so nothing is lost. Raising m_tready must then drain exactly one command.
    """
    tb = BookInputTb(dut)
    await tb.start()

    dut.m_tready.value = 0

    msg = mdl.build_add(order_id=0x21, qty=200, price=21)
    expected = mdl.expected_cmd(msg)

    await tb.send(msg)

    # Output should be presented and then held.
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert safe_int(dut.m_tvalid) == 1, "output not presented"
    held_qty = safe_int(dut.m_qty)

    for _ in range(5):
        await RisingEdge(dut.clk)
        await ReadOnly()
        assert safe_int(dut.m_tvalid) == 1, "m_tvalid dropped while stalled"
        assert safe_int(dut.m_qty) == held_qty, "payload changed while stalled"

    assert safe_int(dut.s_tready) == 0, (
        "s_tready must fall when the output register is full and stalled"
    )

    # The loop above ends inside ReadOnly, where cocotb forbids writes. Step
    # to the next edge before releasing the stall.
    await RisingEdge(dut.clk)
    dut.m_tready.value = 1
    await tb.settle()

    tb.expect_count(1)
    check_fields(tb.cmd(), expected)


# ===========================================================================
# 19. Drops between accepted messages
# ===========================================================================
@cocotb.test()
async def test_drop_between_valid(dut):
    """
    A long run of discarded messages between two accepted ones must leave
    both intact - the output register must not be corrupted by traffic it
    is filtering out.
    """
    tb = BookInputTb(dut)
    await tb.start()

    msgs = [mdl.build_add(order_id=100, qty=11, price=1)]
    msgs += [mdl.build_other(mdl.T_EQUILIBRIUM) for _ in range(4)]
    msgs += [mdl.build_trade()]
    msgs += [mdl.build_add(order_id=200, book_id=OTHER_BOOK)]
    msgs += [mdl.build_other(mdl.T_BOOKSTATE)]
    msgs += [mdl.build_add(order_id=101, qty=22, price=2)]
    expected = mdl.expected_stream(msgs)

    await tb.send_stream(msgs)
    await tb.settle()

    tb.expect_count(2)
    assert len(expected) == 2, "model disagrees with the intended stimulus"
    check_fields(tb.cmd(0), expected[0], ctx="before drops ")
    check_fields(tb.cmd(1), expected[1], ctx="after drops ")


# ===========================================================================
# 20. Reset mid-stream
# ===========================================================================
@cocotb.test()
async def test_reset_mid_stream(dut):
    """
    Reset asserted with traffic in flight. The module must come back clean:
    no stale command presented, and the next message decoded normally.
    """
    tb = BookInputTb(dut)
    await tb.start()

    dut.m_tready.value = 0                     # strand a command in the register
    await tb.send(mdl.build_add(order_id=999, qty=1234, price=99))
    await tb.settle(3)

    await tb.reset()
    tb.clear()
    dut.m_tready.value = 1

    await ReadOnly()
    assert safe_int(dut.m_tvalid) == 0, "m_tvalid did not clear on reset"

    msg = mdl.build_add(order_id=5, qty=1000, price=2610)
    expected = mdl.expected_cmd(msg)

    await tb.send(msg)
    await tb.settle()

    tb.expect_count(1, ctx="after reset: ")
    check_fields(tb.cmd(), expected, ctx="after reset ")


# ===========================================================================
# 21. Order book id is forwarded, not consumed by the filter
# ===========================================================================
@cocotb.test()
async def test_book_id_forwarded(dut):
    """
    m_book_id must carry the instrument the command belongs to.

    This engine instance tracks one order book, so every command carries the
    same value and nothing downstream needs it yet. It is checked because a
    multi-symbol engine keys its order table on (order_id, side, book_id) -
    Order IDs are only unique within a book and side - and an implementation
    that zeroed the field here would pass every other test in this file while
    making that impossible.
    """
    tb = BookInputTb(dut)
    await tb.start()

    msgs = [
        mdl.build_add(order_id=1, qty=10, price=100),
        mdl.build_exec(order_id=1, qty=4),
        mdl.build_replace(order_id=1, qty=6, price=101),
        mdl.build_delete(order_id=1),
    ]

    await tb.send_stream(msgs)
    await tb.settle()

    tb.expect_count(4)
    for i, c in enumerate(tb.cmds):
        assert c["book_id"] == BOOK_ID, (
            f"[{i}] m_book_id got {c['book_id']}, expected {BOOK_ID} "
            "(the filter must forward the instrument, not discard it)"
        )

    dut._log.info("book id %d forwarded on all %d commands",
                  BOOK_ID, len(tb.cmds))


# ===========================================================================
# 22. Randomised stream against the model
# ===========================================================================
@cocotb.test()
async def test_random_stream(dut):
    """
    A randomised mix of every message type, both order books, both sides,
    and occasional bad side bytes - checked message for message against the
    reference model.

    Seeded for reproducibility; change the seed to explore further.
    """
    tb = BookInputTb(dut)
    await tb.start()

    rng = random.Random(20260813)
    msgs = []

    for i in range(200):
        pick = rng.random()
        book = BOOK_ID if rng.random() < 0.8 else OTHER_BOOK
        side = rng.choice([mdl.SIDE_BUY, mdl.SIDE_SELL])
        if rng.random() < 0.05:
            side = rng.choice([mdl.SIDE_BLANK, 0x00, ord("X")])

        oid = rng.randrange(1, 1 << 40)
        qty = rng.choice([0, 1, rng.randrange(1, 100000), 0x1FFFFFFFF])
        px = rng.choice([rng.randrange(-5000, 500000), -1, -2147483648])
        ext = rng.choice([0, mdl.EXT_UNDISCLOSED, mdl.EXT_IMPLIED,
                          mdl.EXT_UNDISCLOSED | mdl.EXT_IMPLIED,
                          rng.randrange(0, 1 << 16)])

        if pick < 0.30:
            m = mdl.build_add(oid, book, side, qty, px, extype=ext,
                              with_pid=rng.random() < 0.3)
        elif pick < 0.50:
            m = mdl.build_exec(oid, book, side, qty)
        elif pick < 0.62:
            m = mdl.build_exec(oid, book, side, qty,
                               trade_price=rng.randrange(1, 100000))
        elif pick < 0.74:
            m = mdl.build_replace(oid, book, side, qty, px, extype=ext)
        elif pick < 0.88:
            m = mdl.build_delete(oid, book, side)
        elif pick < 0.94:
            m = mdl.build_trade(book)
        else:
            m = mdl.build_other(rng.choice([
                mdl.T_SECONDS, mdl.T_SYSEVENT, mdl.T_TICKSIZE,
                mdl.T_BOOKSTATE, mdl.T_EQUILIBRIUM,
            ]))
        msgs.append(m)

    expected = mdl.expected_stream(msgs)

    gaps = [rng.choice([0, 0, 0, 1, 2]) for _ in msgs]
    await tb.send_stream(msgs, gaps=gaps)
    await tb.settle(16)

    dut._log.info("drove %d messages, %d expected commands, %d observed",
                  len(msgs), len(expected), len(tb.cmds))

    tb.expect_count(len(expected))
    for i, exp in enumerate(expected):
        check_fields(tb.cmd(i), exp, ctx=f"[{i}] ")

    # Every execution in the stream must have had its price suppressed.
    for i, c in enumerate(tb.cmds):
        if c["op"] == mdl.OP_EXEC:
            assert c["px_valid"] == 0, f"[{i}] EXEC leaked a price"
