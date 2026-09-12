# market_data_top test suite

Twelve cocotb tests driving the full chain from Ethernet frames to both
memories.

```
Ethernet -> IPv4 -> UDP -> MoldUDP64 -> ITCH -> book_input_stage
            -> order_fifo -> order_book -> price_storage
                                 |              |
                             ram_array     level_array
```

Every order that reaches the order table got there as bytes on a wire. The
command bus, the mutation bus and both memories are observed, never driven.

## Each test starts with empty memories

Neither `ram_sdp` nor `level_array` resets its array — real block RAM has no
reset on its contents, and forcing one would stop Vivado inferring a memory.
So `resetn` clears the logic and leaves both memories exactly as they were.

cocotb would normally run all twelve tests inside one simulation, which means
test 2 starting on top of test 1's resting orders. Across the suite that
pushes the order table well past a sensible load factor and cuckoo inserts
begin failing for reasons unrelated to the test being run.

`market_data_sim.ps1` therefore **analyses once and then elaborates and runs
separately for each test**. Elaboration is what re-initialises the memories,
so every test below starts empty and every intended end state is absolute,
not cumulative.

The cost is elaboration time — `ram_sdp`'s initialiser walks 2 × 16384 × 65
bits of level RAM before each run. `-Fast` runs everything in one elaboration
instead, which is quicker but leaves the memories dirty between tests; the
end states below will not match in that mode, and the runner says so in
yellow when you use it.

## These tests check nothing

There are no assertions and no pass/fail verdict beyond "the run completed".
A green result means the simulator did not fall over.

What each test *should* end up with is written out below as an **intended end
state**: which orders should be resting, with what quantity and price, and
what each touched level should hold. Compare the final dump against the table
for that test. A mismatch is the finding.

These tables were derived from the ASX ITCH spec rules the design implements
— absolute quantity on A/U, delta on E, order removed at zero, replace as
delete-then-add — not from a run of the RTL. If the design disagrees, at
least one of the two is wrong, and the table says which behaviour was
intended.

## Running

```powershell
# one test - preferred, the logs are long
.\market_data_sim.ps1 -Test test_price_ladder *> ladder.log

# everything, fresh elaboration per test
.\market_data_sim.ps1 *> run.log

# list the test names without running anything
.\market_data_sim.ps1 -List

# one .fst per test
.\market_data_sim.ps1 -Waves

# all tests in ONE elaboration - faster, but memories are NOT cleared
# between tests and the end states below will not match
.\market_data_sim.ps1 -Fast
```

Elaboration is slow: `level_array` is 2 × 16384 × 65 bits and `ram_sdp`'s
simulation initialiser walks it element by element. Expect a long pause before
the first line, longer with `-Waves`.

## Files

| file | what it is |
|---|---|
| `test_market_data.py` | the twelve tests |
| `md_harness.py` | geometry, band map, frame building, driver, dumps |
| `book_model.py` | ASX ITCH message builders |
| `asx_packets.py` | Ethernet/IPv4/UDP/MoldUDP64 frame builder |
| `market_data_sim.ps1` | NVC + cocotb runner |

## Reading a dump

- **ORDER TABLES** — the four hash tables twice, once as keys
  (`<low 16 bits of order id><B|S>`, `.` for empty) and once as quantities.
- **LEVEL MEMORY** — the watched index window, both sides, with a `maps to`
  column giving the price each index corresponds to. **When a slot's stored
  price disagrees with its `maps to` price, aliasing has happened.**
- **PRICE STORAGE** — mutation bus, `inserting`/`double`/`index`/`lvl_r`,
  both level ports, status line.

**Slot placement is not predictable.** Which table and index an order lands in
depends on `hash65` and on the eviction path taken, so the tables below give
the *set* of resting orders and the occupancy count, not positions. Occupancy
and per-order quantity are the things to compare.

## Level memory: RTL or shadow

NVC's VHPI will not index an array as large as the level RAMs, so a direct
read raises `Unable to obtain constraints for an indexable object`. The
harness probes once at startup and falls back to a shadow built from the write
bus, saying which it used in the header and every dump label.

`level_array` is still the design either way — the RTL memory is what
`price_storage` reads back through `lvl_rdata` and what every aggregation
decision is computed from. Only the printed contents come from the write bus.

## Prices used

Band map is `0–10c` at 0.1c, `10c–$2` at 0.5c, `$2+` at 1c: 10280 levels,
14 address bits. All test prices sit in the top band, one tick = 10 units.

| name | price | $ | level index |
|---|---|---|---|
| `low` | 20000 | $20.00 | 2280 |
| `mid` | 35000 | $35.00 | 3780 |
| `ref` | 50000 | $50.00 | 5280 |
| `ref1` | 50010 | $50.01 | 5281 |
| `high` | 65000 | $65.00 | 6780 |

Order ids are `0x621F1282_0000NNNN`; the tables below show the low 16 bits.

---

# The tests

## 1. `test_single_level_traffic` — baseline

16 SELL adds at 50000 (qty 100…1600), delete 3/9/14, replace 1 and 7 to
double quantity, execute 25% off 5 and 11, fill 2 completely. One message per
packet, full dump after each.

**Intended end state — 12 orders, occupancy 12/64**

| id | side | qty | price |
|---|---|---|---|
| 0000 | SELL | 100 | 50000 |
| 0001 | SELL | 400 | 50000 |
| 0004 | SELL | 500 | 50000 |
| 0005 | SELL | 450 | 50000 |
| 0006 | SELL | 700 | 50000 |
| 0007 | SELL | 1600 | 50000 |
| 0008 | SELL | 900 | 50000 |
| 000a | SELL | 1100 | 50000 |
| 000b | SELL | 900 | 50000 |
| 000c | SELL | 1300 | 50000 |
| 000d | SELL | 1400 | 50000 |
| 000f | SELL | 1600 | 50000 |

| level | side | qty | stored px |
|---|---|---|---|
| 5280 | 1 (sell) | **10950** | 50000 |

Orders 2, 3, 9 and 14 must be gone — 2 by execution reaching zero, the rest by
delete. 10950 is the sum of the twelve resting quantities.

## 2. `test_two_sided_book` — both level tables

Eight adds alternating BUY/SELL across four prices, then delete order 0 (BUY)
and order 3 (SELL).

**Intended end state — 6 orders, occupancy 6/64**

| id | side | qty | price |
|---|---|---|---|
| 0001 | SELL | 400 | 50000 |
| 0002 | BUY | 600 | 35000 |
| 0004 | BUY | 700 | 20000 |
| 0005 | SELL | 200 | 50000 |
| 0006 | BUY | 800 | 35000 |
| 0007 | SELL | 900 | 65000 |

| level | side | qty | stored px |
|---|---|---|---|
| 2280 | 0 (buy) | 700 | 20000 |
| 3780 | 0 (buy) | 1400 | 35000 |
| 5280 | 1 (sell) | 600 | 50000 |
| 6780 | 1 (sell) | 900 | 65000 |

Both columns of the level dump must be populated — this is the first test
where side 0 is written at all.

## 3. `test_price_ladder` — px_index scaling

One SELL order at each of eight consecutive on-tick prices.

**Intended end state — 8 orders, occupancy 8/64**

| level | side | qty | stored px | from order |
|---|---|---|---|---|
| 5280 | 1 | 100 | 50000 | 0000 |
| 5281 | 1 | 200 | 50010 | 0001 |
| 5282 | 1 | 300 | 50020 | 0002 |
| 5283 | 1 | 400 | 50030 | 0003 |
| 5284 | 1 | 500 | 50040 | 0004 |
| 5285 | 1 | 600 | 50050 | 0005 |
| 5286 | 1 | 700 | 50060 | 0006 |
| 5287 | 1 | 800 | 50070 | 0007 |

Eight **adjacent** indices. Indices ten apart, or all identical, means
`C_PX_PER_CENT` is wrong — the one constant in `level_pkg` that cannot be
derived and that breaks the map silently.

## 4. `test_multi_message_packet` — no gap between messages

Six messages in one MoldUDP64 packet: add BUY 100@20000, add SELL 200@50000,
add BUY 300@20000, exec 50 off the first, add SELL 400@65000, delete the
SELL at 50000.

**Intended end state — 3 orders, occupancy 3/64**

| id | side | qty | price |
|---|---|---|---|
| 0000 | BUY | 50 | 20000 |
| 0002 | BUY | 300 | 20000 |
| 0003 | SELL | 400 | 65000 |

| level | side | qty | stored px |
|---|---|---|---|
| 2280 | 0 (buy) | 350 | 20000 |
| 5280 | 1 (sell) | **0** | 50000 |
| 6780 | 1 (sell) | 400 | 65000 |

Index 5280 should be zero, not absent — the level was written and then
written back to zero by the delete. Six commands out for six messages in, and
`fifo_full` should stay low.

## 5. `test_back_to_back_packets` — sustained rate

Eight single-message packets with zero gap, then the same traffic again with
a 4-cycle gap. **The second run uses order ids offset by 0x100**, because
reset clears the logic but not the memories.

**After the burst (run 1) — 8 orders, occupancy 8/64**

| level | side | qty | stored px |
|---|---|---|---|
| 3780 | 0 (buy) | 1600 | 35000 |
| 5280 | 1 (sell) | 2000 | 50000 |

Buys are the even-numbered orders (100+300+500+700), sells the odd
(200+400+600+800).

**After the gapped run (run 2) — 16 orders, occupancy 16/64**

| level | side | qty | stored px |
|---|---|---|---|
| 3780 | 0 (buy) | 3200 | 35000 |
| 5280 | 1 (sell) | 4000 | 50000 |

Exactly double, because run 2 adds the same quantities under different ids.
**If the burst and gapped runs produce different level deltas, something is
rate-dependent** — that is the whole point of this test. Watch `fifo_full`
and `fifo_overflow`.

## 6. `test_replace_same_and_new_price` — the forwarding branch

Seed two SELL orders at 50000 (1000 and 2000). Replace order 0 to qty 1500 at
the same price. Replace order 1 to 65000. Replace order 0 up one tick to
50010.

**Intended end state — 2 orders, occupancy 2/64**

| id | side | qty | price |
|---|---|---|---|
| 0000 | SELL | 1500 | 50010 |
| 0001 | SELL | 2000 | 65000 |

| level | side | qty | stored px |
|---|---|---|---|
| 5280 | 1 | **0** | 50000 |
| 5281 | 1 | 1500 | 50010 |
| 6780 | 1 | 2000 | 65000 |

**The per-step behaviour matters more than the end state here:**

| step | level writes | `double` |
|---|---|---|
| replace at same price | **1** | **1** |
| replace to 65000 | **2**, different indices | 0 |
| replace up one tick | **2**, adjacent indices | 0 |

Two writes in the same-price case means the forwarding branch did not fire
and the level has been double-counted. Intermediate value at 5280 after the
first replace should be 3500 (3000 − 1000 + 1500).

## 7. `test_execution_to_zero` — cumulative deltas

Add SELL 1000 at 50000, then execute 250, 250, 300, 200. Then one more
execution of 100 against the now-missing order.

**Intended end state — 0 orders, occupancy 0/64**

| level | side | qty | stored px |
|---|---|---|---|
| 5280 | 1 | **0** | 50000 |

Running total after each execution: 750, 500, 200, 0. The key must
**disappear** from the order table on the fourth execution, not linger with
quantity 0 — the spec says no Order Delete follows a complete fill. The
trailing execution must find nothing and change neither memory.

## 8. `test_out_of_scope_types` — two different drop paths

Seed one valid order, then send F, C, P, T and S.

**Intended end state — 1 order, occupancy 1/64, unchanged from the seed**

| id | side | qty | price |
|---|---|---|---|
| 0000 | SELL | 1000 | 50000 |

| level | side | qty | stored px |
|---|---|---|---|
| 5280 | 1 | 1000 | 50000 |

The `order tables unchanged across this test` line at the end should read
`True`. The trace distinguishes the two drop paths: F and C show
`msg=1 gate=1` with no command (decoded upstream, rejected by `f_is_scoped`);
T, S and P show `msg=1 gate=0` (never decoded).

## 9. `test_filtering` — wrong book, bad side

A valid order, then one for book 85604, then one with a blank side byte
(0x20), then one with `'X'`.

**Intended end state — 1 order, occupancy 1/64**

| id | side | qty | price |
|---|---|---|---|
| 0000 | SELL | 500 | 50000 |

| level | side | qty | stored px |
|---|---|---|---|
| 5280 | 1 | 500 | 50000 |

`stat_bad_side` should pulse for the two malformed-side messages and stay low
for the wrong-book one — a wrong book is not a malformed message.

## 10. `test_qty_saturation` — 64-bit field, 32-bit bus

Four SELL adds at 50000 with quantities `0xFFFFFFFE`, `0xFFFFFFFF`,
`0x1_0000_0000`, `0xDEAD_BEEF_CAFE`.

**Intended end state — 4 orders, occupancy 4/64**

| id | qty on the bus | note |
|---|---|---|
| 0000 | 4294967294 (`0xFFFFFFFE`) | passes through |
| 0001 | 4294967295 (`0xFFFFFFFF`) | boundary, passes through |
| 0002 | 4294967295 | **saturated**, `stat_qty_ovf` pulses |
| 0003 | 4294967295 | **saturated**, `stat_qty_ovf` pulses |

| level | side | qty | stored px |
|---|---|---|---|
| 5280 | 1 | **4294967291** (`0xFFFFFFFB`) | 50000 |

The true sum is `0x3FFFFFFFB`, which **wraps** in the 32-bit level field. Two
separate lossy behaviours stack here: the input saturates, and then the level
accumulator wraps. Both are silent apart from `stat_qty_ovf`, and a later
execution of the true quantity will not bring the level back to zero.

## 11. `test_price_aliasing` — the `px_legal` hole

Four SELL adds: 1000 at 50000, 7 at 50005, 33 at 100000 (above the $100 cap),
44 at −25.

**Intended end state — 4 orders, occupancy 4/64**

The order table keeps the true prices:

| id | qty | price |
|---|---|---|
| 0000 | 1000 | 50000 |
| 0001 | 7 | 50005 |
| 0002 | 33 | 100000 |
| 0003 | 44 | −25 |

The level table cannot:

| level | side | qty | stored px | why |
|---|---|---|---|---|
| 0 | 1 | **77** | **−25** | 100000 and −25 both fall through every band → index 0 |
| 5280 | 1 | **1007** | **50005** | 50005 is inside 50000's tick → same index |

Two things to see. At 5280 the quantities **merged** — 1000 + 7 — and the
stored price is whichever arrived last, so `index_price` can no longer
recover which price was meant. At index 0, an over-cap and a negative price
have aggregated into a real level at price 0. `oor` stays undriven throughout.

Compare each slot's stored price against the `maps to` column: where they
disagree is exactly where aliasing happened.

This test documents known behaviour, not a bug being hunted. If you add a
range and tick check to `price_storage`, this is the test that should change.

## 12. `test_mixed_session` — capture-replay shaped

Five packets of 3–4 messages: both sides, four prices, all four in-scope
types interleaved, plus an F and a T. Packet boundaries cut across related
messages. Then the same five packets back to back with no gap, **order ids
offset by 0x200**.

**After the gapped run — 4 orders, occupancy 4/64**

| id | side | qty | price |
|---|---|---|---|
| 0001 | SELL | 600 | 50000 |
| 0002 | BUY | 500 | 35000 |
| 0006 | BUY | 450 | 20000 |
| 0007 | SELL | 1100 | 65000 |

| level | side | qty | stored px |
|---|---|---|---|
| 2280 | 0 (buy) | 450 | 20000 |
| 3780 | 0 (buy) | 500 | 35000 |
| 5280 | 1 (sell) | 600 | 50000 |
| 6780 | 1 (sell) | 1100 | 65000 |

Order 0000 is filled out by the two executions (250 then 750 of 1000), 0003
is deleted, 0004 is deleted, 0005 is the F and never arrives. Order 0002
moves from 20000 to 35000 by replace, which is why 2280 ends up holding only
order 0006.

**After the burst run — 8 orders, occupancy 8/64**

| level | side | qty | stored px |
|---|---|---|---|
| 2280 | 0 (buy) | 900 | 20000 |
| 3780 | 0 (buy) | 1000 | 35000 |
| 5280 | 1 (sell) | 1200 | 50000 |
| 6780 | 1 (sell) | 2200 | 65000 |

Exactly double. **Any difference between the two runs' deltas is a
rate-dependent bug**, and this is the cheapest place to catch one.

---

# Known issues these tests will show

Already understood, so they are not mistaken for new findings:

**`price_storage` drives no status outputs.** `s_tready`, `oor` and `busy`
are never assigned and read `U` in every dump. The mutation link is
fire-and-forget both ways: `order_book` declares `m_tready` and never reads
it.

**Top of book is never published.** `m_tvalid`, `m_bid_*`, `m_ask_*` and
`m_valid` sit at reset values throughout. The level memory fills correctly;
nothing reads it back out yet. Every "intended end state" above is about the
memories, not the top-of-book port.

**Out-of-range and off-tick prices alias.** See test 11.

**The 32-bit level accumulator wraps.** See test 10.

**`fullparser` needs one edit to elaborate.** It still maps `m_axis_*` on its
`u_itch` instance and the new `itch_parser` has no such ports. Either
re-source `fullparser`'s `m_axis_*` from the mold stage or delete the
passthrough.

**`price_storage` lines 117–121** assign `delete` and `insert` twice,
identically. Simulation resolves it; Vivado will flag multi-driven nets.

**Reset does not clear the memories.** Real block RAM has no reset on its
contents, which is why the runner re-elaborates per test. It also means a
single test that resets mid-run keeps its own earlier state: tests 5 and 12
each run their traffic twice and offset the second run's order ids by 0x100
and 0x200 for exactly this reason. Reusing ids would re-add live keys, and
the second run's expected levels are double the first, not equal to it.

**Order table capacity is 64.** `C_ADDR_W = 4` gives 16 slots per table
across 4 tables. Every test stays well under that, but it is a bring-up value
— 16-deep memories defeat BRAM inference entirely.

# Changing the geometry

`md_harness.py` mirrors the RTL constants; it does not derive them. If you
change `C_ADDR_W`, `C_KEY_W`, `C_VAL_W` or `C_LVL_MAX_CENT`, update the
matching constants at the top of the harness or the dumps decode against the
wrong layout and print plausible garbage rather than failing. Every level
index in the tables above also moves.

`level_array` prints its real geometry as an elaboration-time assertion note,
so the first lines of any run are where to check.
