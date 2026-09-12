"""
cocotb tests for market_data_top - the whole chain, driven by real frames.

    Ethernet -> IPv4 -> UDP -> MoldUDP64 -> ITCH -> book_input_stage
                -> order_fifo -> order_book -> price_storage
                                     |              |
                                 ram_array     level_array

Every order that reaches the table got there as bytes on a wire. Nothing is
driven onto the command bus; the command bus, the mutation bus and both
memories are observed only.

A VISIBILITY HARNESS. No assertions, no expected values, no verdict beyond
"the run completed". See README_tests.md for what each test drives and what
to look for in its output.

Run one test at a time - the logs are long:

    powershell -File .\\market_data_sim.ps1 -Test test_price_ladder *> ladder.log

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import cocotb

from md_harness import (
    Harness, banner, header, report, run, dump_all,
    frame_one, frame_many,
    msg_add, msg_replace, msg_exec, msg_delete,
    make_order_id, px_index, px_on_tick, px_tick,
    BUY, SELL, PX, BOOK_ID, CAPACITY, DRAIN_CYCLES,
    fmt, fmt_side, safe_int,
)
import book_model as bm


# ===========================================================================
# 1. Baseline - one price, one side, one message per packet
# ===========================================================================
@cocotb.test()
async def test_single_level_traffic(dut):
    """
    Adds, deletes, replaces and executions, all SELL at one price, each in
    its own packet. Everything lands in a single level, which is the case
    that stresses the level table hardest: repeated mutation of one index.

    This is the regression baseline - it is the closest of these tests to
    test_book_PLS, so the two logs should read alike.
    """
    h = Harness(dut)
    await h.start()
    header(h, "1. BASELINE - single level, single side, one message per packet",
           [f"side        : SELL at price {PX['ref']} "
            f"(index {px_index(PX['ref'])}), on every message",
            "packets     : one ITCH message each, full dump after every one"])

    h.expect(PX["ref"])
    n_add = 16
    qty = {}

    banner(dut, "ADDS")
    for i in range(n_add):
        oid = make_order_id(i)
        qty[i] = 100 * (i + 1)
        banner(dut, f"ADD {i + 1}/{n_add}  order {i}  qty {qty[i]}")
        obs = await run(h, frame_one(msg_add(oid, SELL, qty[i], PX["ref"],
                                             pos=i + 1)))
        report(h, obs, expect_msgs=1)
        await dump_all(h)

    banner(dut, "DELETES")
    for i in (3, 9, 14):
        banner(dut, f"DELETE order {i}  (was resting {qty[i]})")
        obs = await run(h, frame_one(msg_delete(make_order_id(i), SELL)))
        report(h, obs, expect_msgs=1)
        await dump_all(h)
        qty[i] = 0

    banner(dut, "REPLACES - the forwarding branch should fire, double=1")
    for i in (1, 7):
        new = qty[i] * 2
        banner(dut, f"REPLACE order {i}  qty {qty[i]} -> {new}, "
                    f"price unchanged")
        obs = await run(h, frame_one(msg_replace(make_order_id(i), SELL, new,
                                                 PX["ref"])))
        report(h, obs, expect_msgs=1)
        await dump_all(h)
        qty[i] = new

    banner(dut, "EXECUTIONS")
    for i, full in ((5, False), (11, False), (2, True)):
        take = qty[i] if full else qty[i] // 4
        banner(dut, f"EXEC order {i}  take {take} of {qty[i]}"
                    f"{'  [fills the order]' if full else ''}")
        obs = await run(h, frame_one(msg_exec(make_order_id(i), SELL, take)))
        report(h, obs, expect_msgs=1)
        await dump_all(h)
        qty[i] = max(0, qty[i] - take)

    banner(dut, "FINAL STATE", rule="=")
    await dump_all(h)
    dut._log.info("  level writes seen on the bus: %d", h.shadow.writes)


# ===========================================================================
# 2. Two-sided book
# ===========================================================================
@cocotb.test()
async def test_two_sided_book(dut):
    """
    Buys and sells at several prices, so both level tables populate.

    Everything before this drove SELL only, which means side 0 of the level
    memory was never written and lvl_wsel never changed. Here the sides
    interleave, so the wsel decode in level_array and the side bit stored in
    each slot both get exercised.

    The bid ladder sits below the ask ladder, as a real book would: buys at
    20000/35000, sells at 50000/65000.
    """
    h = Harness(dut)
    await h.start()
    header(h, "2. TWO-SIDED BOOK - both level tables, interleaved sides",
           ["bids        : 20000 (idx %d), 35000 (idx %d)"
            % (px_index(PX["low"]), px_index(PX["mid"])),
            "asks        : 50000 (idx %d), 65000 (idx %d)"
            % (px_index(PX["ref"]), px_index(PX["high"])),
            "packets     : one message each, sides alternating"])

    book = [
        (0, BUY, 500, PX["low"]),
        (1, SELL, 400, PX["ref"]),
        (2, BUY, 600, PX["mid"]),
        (3, SELL, 300, PX["high"]),
        (4, BUY, 700, PX["low"]),
        (5, SELL, 200, PX["ref"]),
        (6, BUY, 800, PX["mid"]),
        (7, SELL, 900, PX["high"]),
    ]
    for _, _, _, p in book:
        h.expect(p)

    for n, side, q, p in book:
        banner(dut, f"ADD order {n}  {fmt_side(side)}  qty {q}  px {p}  "
                    f"-> level index {px_index(p)}")
        obs = await run(h, frame_one(msg_add(make_order_id(n), side, q, p)))
        report(h, obs, expect_msgs=1)
        await dump_all(h)

    banner(dut, "Now take one order off each side")
    for n, side in ((0, BUY), (3, SELL)):
        banner(dut, f"DELETE order {n} {fmt_side(side)}")
        obs = await run(h, frame_one(msg_delete(make_order_id(n), side)))
        report(h, obs, expect_msgs=1)
        await dump_all(h)

    banner(dut, "FINAL STATE", rule="=")
    await dump_all(h)


# ===========================================================================
# 3. Price ladder
# ===========================================================================
@cocotb.test()
async def test_price_ladder(dut):
    """
    One order at each of eight consecutive on-tick prices.

    Each should land on its own level index, one apart, since the tick in
    this band is 10 price units per level. That makes the whole ladder
    visible in one dump and is the cheapest check that px_index is monotonic
    and correctly scaled - an off-by-ten in C_PX_PER_CENT would show as
    indices ten apart, or all the same.
    """
    h = Harness(dut)
    await h.start()

    base = PX["ref"]
    tick = px_tick(base)
    prices = [base + k * tick for k in range(8)]
    header(h, "3. PRICE LADDER - eight consecutive on-tick prices, one side",
           [f"tick        : {tick} price units in this band",
            f"prices      : {prices[0]} .. {prices[-1]}",
            f"expected idx: {px_index(prices[0])} .. {px_index(prices[-1])} "
            f"(consecutive)"])

    for p in prices:
        h.expect(p)

    for n, p in enumerate(prices):
        banner(dut, f"ADD order {n}  SELL qty {100 * (n + 1)}  px {p}  "
                    f"-> level index {px_index(p)}")
        obs = await run(h, frame_one(msg_add(make_order_id(n), SELL,
                                             100 * (n + 1), p)))
        report(h, obs, expect_msgs=1)
        await dump_all(h)

    banner(dut, "FINAL STATE - the ladder should be eight adjacent indices",
           rule="=")
    await dump_all(h)


# ===========================================================================
# 4. Several messages per packet
# ===========================================================================
@cocotb.test()
async def test_multi_message_packet(dut):
    """
    Six ITCH messages in ONE MoldUDP64 packet.

    The per-message tests give the chain a whole packet gap between messages.
    This one does not: the parser retires msg_valid six times in quick
    succession. book_input_stage has no buffering - one register stage,
    accepting a message every cycle - so the pressure lands on order_fifo.

    Mixed sides and prices so the level writes go to different indices on
    different sides back to back, which is where an address collision in
    price_storage would show.
    """
    h = Harness(dut)
    await h.start()
    header(h, "4. MULTI-MESSAGE PACKET - six messages, one frame",
           ["mixed sides and prices, so consecutive level writes hit "
            "different indices"])

    for p in (PX["low"], PX["ref"], PX["high"]):
        h.expect(p)

    msgs = [
        msg_add(make_order_id(0), BUY, 100, PX["low"]),
        msg_add(make_order_id(1), SELL, 200, PX["ref"]),
        msg_add(make_order_id(2), BUY, 300, PX["low"]),
        msg_exec(make_order_id(0), BUY, 50),
        msg_add(make_order_id(3), SELL, 400, PX["high"]),
        msg_delete(make_order_id(1), SELL),
    ]
    frame = frame_many(msgs)
    dut._log.info("frame: %d bytes, %d beats, %d messages",
                  len(frame), (len(frame) + 7) // 8, len(msgs))
    for n, m in enumerate(msgs):
        dut._log.info("  msg %d: type %s, %d bytes",
                      n, bm.TYPE_NAME.get(m[0], "?"), len(m))

    obs = await run(h, frame, drain=DRAIN_CYCLES * 2)
    report(h, obs, expect_msgs=len(msgs))
    await dump_all(h, "AFTER THE PACKET")


# ===========================================================================
# 5. Back-to-back packets
# ===========================================================================
@cocotb.test()
async def test_back_to_back_packets(dut):
    """
    Eight packets with NO idle cycle between them - each frame's first beat
    follows the previous frame's tlast immediately.

    This is the sustained-rate case. Every stage has to accept a new packet
    while still finishing the last one: the parser's per-packet state reset,
    the input stage, the FIFO, and a cuckoo insert that may still be walking
    an eviction chain when the next command arrives.

    fifo_full and fifo_overflow in the status line are the things to watch.
    """
    h = Harness(dut)
    await h.start()
    header(h, "5. BACK-TO-BACK PACKETS - eight frames, zero gap",
           ["each frame's first beat follows the previous tlast with no idle "
            "cycle",
            "watch fifo_full and fifo_overflow in the status line"])

    for p in (PX["ref"], PX["mid"]):
        h.expect(p)

    frames = []
    for n in range(8):
        side = SELL if n % 2 else BUY
        price = PX["ref"] if n % 2 else PX["mid"]
        frames.append(frame_one(msg_add(make_order_id(n), side,
                                        100 * (n + 1), price)))

    dut._log.info("driving %d frames, %d beats total",
                  len(frames), sum((len(f) + 7) // 8 for f in frames))

    obs = await run(h, frames, gap=0, drain=DRAIN_CYCLES * 2)
    report(h, obs, expect_msgs=len(frames))
    await dump_all(h, "AFTER THE BURST")

    banner(dut, "Same traffic again with a 4-cycle gap, for comparison")
    dut._log.info("NOTE: order ids are offset by 0x100 for this run. Reset "
                  "clears the logic but NOT")
    dut._log.info("      the memories, so reusing the first run's ids would "
                  "re-add live keys.")
    h2 = Harness(dut)
    await h2.start()
    for p in (PX["ref"], PX["mid"]):
        h2.expect(p)
    frames = []
    for n in range(8):
        side = SELL if n % 2 else BUY
        price = PX["ref"] if n % 2 else PX["mid"]
        frames.append(frame_one(msg_add(make_order_id(0x100 + n), side,
                                        100 * (n + 1), price)))
    obs = await run(h2, frames, gap=4, drain=DRAIN_CYCLES * 2)
    report(h2, obs, expect_msgs=len(frames))
    await dump_all(h2, "AFTER THE GAPPED RUN - levels should be double the "
                       "burst run, 16 orders resting")


# ===========================================================================
# 6. Replace - same price and moved price
# ===========================================================================
@cocotb.test()
async def test_replace_same_and_new_price(dut):
    """
    The two shapes of REPLACE, which take different paths through
    price_storage.

    order_book emits a replace as a delete followed by an add on consecutive
    cycles. When the price is UNCHANGED both halves target the same level
    index on the same side, so the forwarding branch fires: the first result
    is held in lvl_r rather than written, the second is computed from it, and
    ONE write covers both. Look for double=1 and a single level write.

    When the price MOVES the two halves target different indices, the
    forwarding condition fails, and there should be TWO level writes - a
    subtraction at the old index and an addition at the new one. Look for
    double=0 and two writes at different addresses.
    """
    h = Harness(dut)
    await h.start()
    header(h, "6. REPLACE - same price vs moved price",
           ["same price  : one level write, double=1",
            "moved price : two level writes at different indices, double=0"])

    for p in (PX["ref"], PX["ref1"], PX["high"]):
        h.expect(p)

    oid_a, oid_b = make_order_id(0), make_order_id(1)

    banner(dut, "Seed two SELL orders at the reference price")
    obs = await run(h, [frame_one(msg_add(oid_a, SELL, 1000, PX["ref"])),
                        frame_one(msg_add(oid_b, SELL, 2000, PX["ref"]))],
                    gap=8)
    report(h, obs, expect_msgs=2)
    await dump_all(h)

    banner(dut, f"REPLACE at the SAME price: order 0, qty 1000 -> 1500, "
                f"px stays {PX['ref']} (idx {px_index(PX['ref'])})")
    obs = await run(h, frame_one(msg_replace(oid_a, SELL, 1500, PX["ref"])))
    report(h, obs, expect_msgs=1)
    dut._log.info("    ^ expect ONE level write and double=1 below")
    await dump_all(h)

    banner(dut, f"REPLACE to a NEW price: order 1, qty 2000 -> 2000, "
                f"px {PX['ref']} (idx {px_index(PX['ref'])}) -> "
                f"{PX['high']} (idx {px_index(PX['high'])})")
    obs = await run(h, frame_one(msg_replace(oid_b, SELL, 2000, PX["high"])))
    report(h, obs, expect_msgs=1)
    dut._log.info("    ^ expect TWO level writes at different indices, "
                  "double=0")
    await dump_all(h)

    banner(dut, f"REPLACE one tick up: order 0, px {PX['ref']} -> "
                f"{PX['ref1']} (adjacent indices)")
    obs = await run(h, frame_one(msg_replace(oid_a, SELL, 1500, PX["ref1"])))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, "FINAL STATE", rule="=")
    await dump_all(h)


# ===========================================================================
# 7. Execution down to zero
# ===========================================================================
@cocotb.test()
async def test_execution_to_zero(dut):
    """
    Partial fills followed by the one that empties the order.

    Executed quantity is a DELTA, and the spec says an order is removed when
    its visible quantity reaches zero - normally with no Order Delete message
    following. So the last execution here must clear the slot in the order
    table as well as decrementing the level.

    Watch the order table: the key should disappear on the final exec, not
    linger with qty 0.
    """
    h = Harness(dut)
    await h.start()
    header(h, "7. EXECUTION TO ZERO - cumulative deltas, slot cleared at 0",
           ["exec qty is a delta, not an absolute",
            "the final exec should clear the order slot, not leave qty=0"])

    h.expect(PX["ref"])
    oid = make_order_id(0)

    banner(dut, "ADD  SELL qty 1000 at the reference price")
    obs = await run(h, frame_one(msg_add(oid, SELL, 1000, PX["ref"])))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    resting = 1000
    for take in (250, 250, 300, 200):
        banner(dut, f"EXEC take {take} of {resting}"
                    f"{'   [this one fills it]' if take == resting else ''}")
        obs = await run(h, frame_one(msg_exec(oid, SELL, take)))
        report(h, obs, expect_msgs=1)
        await dump_all(h)
        resting -= take

    banner(dut, "An EXEC for an order that no longer exists", rule="=")
    obs = await run(h, frame_one(msg_exec(oid, SELL, 100)))
    report(h, obs, expect_msgs=1)
    await dump_all(h)


# ===========================================================================
# 8. Out of scope types
# ===========================================================================
@cocotb.test()
async def test_out_of_scope_types(dut):
    """
    F and C reach the engine and are dropped by book_input_stage.

    itch_parser decodes both - is_decoded_type includes them - so msg_valid
    fires and msg_fields is populated. f_is_scoped does not, so no command is
    emitted and neither memory moves.

    The order tables either side of this test should be identical. Also sends
    a few types the parser never decodes (T, S, P) so both drop paths appear
    in one log.
    """
    h = Harness(dut)
    await h.start()
    header(h, "8. OUT OF SCOPE - F and C dropped at the engine, T/S/P at the "
              "parser",
           ["F = add with participant id, C = execution with trade price",
            "both are decoded upstream and rejected by f_is_scoped",
            "the order tables must not move anywhere in this test"])

    h.expect(PX["ref"])

    banner(dut, "Seed one in-scope order so the tables are not empty")
    obs = await run(h, frame_one(msg_add(make_order_id(0), SELL, 1000,
                                         PX["ref"])))
    report(h, obs, expect_msgs=1)
    before, _ = await dump_all(h, "BEFORE")

    banner(dut, "F - add order with participant id")
    obs = await run(h, frame_one(msg_add(make_order_id(1), SELL, 4242,
                                         PX["ref"], pid=True)))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, "C - execution with trade price")
    obs = await run(h, frame_one(msg_exec(make_order_id(0), SELL, 10,
                                          trade_price=99999)))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, "P - trade. Never affects the displayed book (spec 2.7)")
    obs = await run(h, frame_one(bm.build_trade(book_id=BOOK_ID)))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, "T and S - seconds and system event")
    obs = await run(h, [frame_one(bm.build_other(bm.T_SECONDS)),
                        frame_one(bm.build_other(bm.T_SYSEVENT))], gap=6)
    report(h, obs, expect_msgs=2)
    after, _ = await dump_all(h, "AFTER - compare against BEFORE")

    same = (before == after)
    dut._log.info("  order tables unchanged across this test: %s", same)


# ===========================================================================
# 9. Filtering - wrong book, bad side
# ===========================================================================
@cocotb.test()
async def test_filtering(dut):
    """
    The two filters inside book_input_stage.

    book_hit compares the message's order book id against G_ORDER_BOOK_ID, so
    a well-formed message for another instrument is dropped. side_ok accepts
    only 'B' and 'S', so anything else - a blank from a Centre Point trade,
    or junk - drops the message and pulses stat_bad_side.

    Watch stat_bad_side in the status line: it should pulse for the bad-side
    messages and stay low for the wrong-book ones, since a wrong book is not
    a malformed message.
    """
    h = Harness(dut)
    await h.start()
    header(h, "9. FILTERING - wrong order book, unrecognised side byte",
           [f"this engine tracks book {BOOK_ID} only",
            "side must be 'B' or 'S'; anything else pulses stat_bad_side"])

    h.expect(PX["ref"])

    banner(dut, "A valid order first, for contrast")
    obs = await run(h, frame_one(msg_add(make_order_id(0), SELL, 500,
                                         PX["ref"])))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, f"Wrong order book: {BOOK_ID + 1}")
    wrong = bm.build_add(order_id=make_order_id(1), book_id=BOOK_ID + 1,
                         side=bm.SIDE_SELL, qty=999, price=PX["ref"])
    obs = await run(h, frame_one(wrong))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, "Blank side byte (0x20) - a Centre Point trade's side")
    blank = bm.build_add(order_id=make_order_id(2), book_id=BOOK_ID,
                         side=bm.SIDE_BLANK, qty=888, price=PX["ref"])
    obs = await run(h, frame_one(blank))
    report(h, obs, expect_msgs=1)
    dut._log.info("    ^ expect stat_bad_side to have pulsed")
    await dump_all(h)

    banner(dut, "Junk side byte ('X')")
    junk = bm.build_add(order_id=make_order_id(3), book_id=BOOK_ID,
                        side=ord("X"), qty=777, price=PX["ref"])
    obs = await run(h, frame_one(junk))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, "FINAL STATE - only the first order should be resting",
           rule="=")
    await dump_all(h)


# ===========================================================================
# 10. Quantity saturation
# ===========================================================================
@cocotb.test()
async def test_qty_saturation(dut):
    """
    The wire quantity is 64 bits and the command bus is 32.

    book_input_stage saturates rather than truncating, so an oversized
    quantity becomes 0xFFFFFFFF and pulses stat_qty_ovf - it cannot silently
    become a small number. Drives the boundary either side plus one clearly
    over.

    Note what saturation means downstream: the level aggregate is now wrong
    by construction, and a later exec of the true quantity will not bring it
    back to zero. stat_qty_ovf is the only warning of that.
    """
    h = Harness(dut)
    await h.start()
    header(h, "10. QUANTITY SATURATION - 64-bit wire field, 32-bit bus",
           ["saturates to 0xFFFFFFFF and pulses stat_qty_ovf",
            "a saturated quantity permanently desynchronises that level"])

    h.expect(PX["ref"])

    cases = [
        (0, 0xFFFFFFFE, "one below the boundary"),
        (1, 0xFFFFFFFF, "exactly the boundary"),
        (2, 0x1_0000_0000, "one above - saturates"),
        (3, 0xDEAD_BEEF_CAFE, "far above - saturates"),
    ]
    for n, q, note in cases:
        banner(dut, f"ADD qty {q} (0x{q:X}) - {note}")
        obs = await run(h, frame_one(msg_add(make_order_id(n), SELL, q,
                                             PX["ref"])))
        report(h, obs, expect_msgs=1)
        await dump_all(h)

    banner(dut, "FINAL STATE", rule="=")
    await dump_all(h)


# ===========================================================================
# 11. Price aliasing - the px_legal hole
# ===========================================================================
@cocotb.test()
async def test_price_aliasing(dut):
    """
    What happens now that px_legal is gone.

    px_index truncates within a band, so two prices inside one tick map to
    the SAME level index - their quantities merge and index_price can no
    longer recover which was meant. And a price outside every band falls
    through the loop and returns 0, so it aggregates into level 0, a real
    level at price 0.

    Nothing rejects either case. This test makes both visible:

      - two orders one price unit apart, which should share an index
      - an order above the $100 cap, which should land on index 0
      - a negative price, which unsigned-reinterprets to a huge value and
        also lands on index 0

    Compare each slot's stored price against the "maps to" column in the
    level dump. Where they disagree, the aliasing has happened.
    """
    h = Harness(dut)
    await h.start()

    on_tick = PX["ref"]
    off_tick = PX["ref"] + 5          # inside the same 10-unit tick
    over_cap = 100000                 # C_LVL_MAX_CENT * C_PX_PER_CENT
    header(h, "11. PRICE ALIASING - no px_legal, nothing rejects a bad price",
           [f"{on_tick} on-tick  -> index {px_index(on_tick)}",
            f"{off_tick} off-tick -> index {px_index(off_tick)}  "
            f"(same index, quantities merge)",
            f"{over_cap} over cap -> index {px_index(over_cap)}  "
            f"(level 0, a real level at price 0)",
            "negative      -> index 0 as well, via unsigned reinterpretation"])

    h.expect(on_tick)
    h.note(0)

    banner(dut, f"ADD SELL qty 1000 at {on_tick} (on tick, "
                f"index {px_index(on_tick)})")
    obs = await run(h, frame_one(msg_add(make_order_id(0), SELL, 1000,
                                         on_tick)))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, f"ADD SELL qty 7 at {off_tick} (off tick by 5, "
                f"on_tick={px_on_tick(off_tick)})")
    dut._log.info("    this should land on index %d - the SAME slot - and "
                  "merge with the 1000", px_index(off_tick))
    obs = await run(h, frame_one(msg_add(make_order_id(1), SELL, 7,
                                         off_tick)))
    report(h, obs, expect_msgs=1)
    dut._log.info("    ^ the slot's stored price is whichever arrived last; "
                  "the index cannot distinguish them")
    await dump_all(h)

    banner(dut, f"ADD SELL qty 33 at {over_cap} - above the $100 cap")
    obs = await run(h, frame_one(msg_add(make_order_id(2), SELL, 33,
                                         over_cap)))
    report(h, obs, expect_msgs=1)
    dut._log.info("    ^ expect a write at index 0, and oor still undriven")
    await dump_all(h)

    banner(dut, "ADD SELL qty 44 at a NEGATIVE price")
    obs = await run(h, frame_one(msg_add(make_order_id(3), SELL, 44, -25)))
    report(h, obs, expect_msgs=1)
    await dump_all(h)

    banner(dut, "FINAL STATE - look at index 0 and at the on-tick index",
           rule="=")
    await dump_all(h)


# ===========================================================================
# 12. Mixed session
# ===========================================================================
@cocotb.test()
async def test_mixed_session(dut):
    """
    A session-shaped run: multiple packets, several messages each, both
    sides, several prices, all four in-scope types interleaved, with
    out-of-scope and non-book types mixed in as a real feed would carry them.

    This is the closest thing here to a capture replay. It is also the test
    most likely to surface an interaction the focused tests miss, because
    nothing about it is tidy: a delete lands in the same packet as an add at
    the same price, an exec follows a replace one message later, and the
    packet boundaries fall wherever they fall.
    """
    h = Harness(dut)
    await h.start()
    header(h, "12. MIXED SESSION - five packets, mixed types, sides, prices",
           ["the closest thing here to a capture replay",
            "packet boundaries deliberately cut across related messages"])

    for p in (PX["low"], PX["mid"], PX["ref"], PX["high"]):
        h.expect(p)

    def build_packets(base):
        """The same session, with order ids offset so a second run cannot
        collide with the first - reset does not clear the memories."""
        o = [make_order_id(base + n) for n in range(12)]
        return [
            # Open the book on both sides.
            [msg_add(o[0], BUY, 1000, PX["mid"]),
             msg_add(o[1], SELL, 800, PX["ref"]),
             msg_add(o[2], BUY, 500, PX["low"])],

            # A non-book message in the middle of book traffic.
            [bm.build_other(bm.T_SECONDS),
             msg_add(o[3], SELL, 600, PX["high"]),
             msg_exec(o[0], BUY, 250)],

            # Replace at the same price, then one that moves price.
            [msg_replace(o[1], SELL, 1200, PX["ref"]),
             msg_add(o[4], BUY, 900, PX["mid"]),
             msg_replace(o[2], BUY, 500, PX["mid"])],

            # Out of scope mixed with in scope.
            [msg_add(o[5], SELL, 300, PX["ref"], pid=True),      # F, dropped
             msg_exec(o[1], SELL, 600),
             msg_delete(o[3], SELL),
             msg_add(o[6], BUY, 450, PX["low"])],

            # Fill an order out and delete another.
            [msg_exec(o[0], BUY, 750),                            # fills it
             msg_delete(o[4], BUY),
             msg_add(o[7], SELL, 1100, PX["high"])],
        ]

    packets = build_packets(0)

    for n, msgs in enumerate(packets):
        frame = frame_many(msgs)
        banner(dut, f"PACKET {n + 1}/{len(packets)} - {len(msgs)} messages, "
                    f"{len(frame)} bytes, {(len(frame) + 7) // 8} beats")
        for k, m in enumerate(msgs):
            dut._log.info("    msg %d: %s, %d bytes",
                          k, bm.TYPE_NAME.get(m[0], "?"), len(m))
        obs = await run(h, frame, drain=DRAIN_CYCLES * 2)
        report(h, obs, expect_msgs=len(msgs))
        await dump_all(h, f"AFTER PACKET {n + 1}")

    banner(dut, "Now the same five packets back to back, no gap", rule="=")
    dut._log.info("NOTE: order ids offset by 0x200 - the memories still hold "
                  "the gapped run's orders.")
    h2 = Harness(dut)
    await h2.start()
    for p in (PX["low"], PX["mid"], PX["ref"], PX["high"]):
        h2.expect(p)
    packets2 = build_packets(0x200)
    frames = [frame_many(msgs) for msgs in packets2]
    obs = await run(h2, frames, gap=0, drain=DRAIN_CYCLES * 3)
    report(h2, obs, expect_msgs=sum(len(m) for m in packets2))
    await dump_all(h2, "AFTER THE BURST - levels should be double the gapped run, 8 orders resting")
    dut._log.info("  fifo_full=%s fifo_overflow=%s",
                  fmt(safe_int(dut.fifo_full)),
                  fmt(safe_int(dut.fifo_overflow)))
