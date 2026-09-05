"""
test_level_ram_model.py - self-test for the level RAM model.

This tests level_ram_model.py. It does NOT test any VHDL, does not need a
simulator, and does not need cocotb. Plain Python:

    python -m unittest test_level_ram_model -v

It exists because level_ram_model.LevelRam is now standing in for hardware. A
model with a timing bug does not fail loudly - it quietly reports the wrong
thing about the design connected to it, and the time goes into hunting a
problem in the RTL that is actually in the model. So the timing contract the
model claims in its header is pinned down here:

    read latency 1
    read during write follows the UG573 collision table for the write mode
    write goes to the side named by wsel
    unusable writes are dropped and recorded, never guessed at

None of this says anything about whether price_storage is correct.
"""

import unittest

from level_ram_model import (LevelRam, make_level, split_level,
                             LVL_DEPTH, LEVEL_W)


def lvl(side, qty, price):
    return make_level(side, qty, price)


# The traffic this model sits under, from test_book_PLS.py: one side, one
# price, varying quantity. PRICE is what goes in the slot's price field; LEVEL
# is the index a price of 50000 maps to at the default band table - band 2,
# base 480, tick 10, so (50000 - 2000) / 10 + 480. Neither number means
# anything to the model, which addresses by index and stores the price field
# opaquely; they are here so the cases read like the real thing.
PRICE = 50000
LEVEL = 5280


class TestPacking(unittest.TestCase):

    def test_roundtrip(self):
        for side in (0, 1):
            for qty, price in ((0, 0), (1, 1), (3200, PRICE),
                               (0xFFFFFFFF, 0xFFFFFFFF)):
                d = split_level(lvl(side, qty, price))
                self.assertEqual((d["side"], d["qty"], d["price"]),
                                 (side, qty, price))

    def test_fields_do_not_overlap(self):
        # Each field alone must leave the others clear, or a wide quantity
        # would silently corrupt the side bit.
        self.assertEqual(split_level(lvl(1, 0, 0)),
                         {"side": 1, "qty": 0, "price": 0})
        self.assertEqual(split_level(lvl(0, 0xFFFFFFFF, 0)),
                         {"side": 0, "qty": 0xFFFFFFFF, "price": 0})
        self.assertEqual(split_level(lvl(0, 0, 0xFFFFFFFF)),
                         {"side": 0, "qty": 0, "price": 0xFFFFFFFF})

    def test_slot_width(self):
        self.assertEqual(LEVEL_W, 65)
        self.assertLess(lvl(1, 0xFFFFFFFF, 0xFFFFFFFF), 1 << LEVEL_W)


class TestReadLatency(unittest.TestCase):

    def test_latency_is_one(self):
        """
        step() returns the new contents of the output register, which the
        design sees during the NEXT cycle. So the fetch for the address passed
        to step() comes straight back out - the one cycle of latency is the
        driver presenting it for the following cycle, not a stage in here.

        This is what was wrong before: a pipeline latency stages deep, on top
        of a driver that already delayed by one, made rdata arrive a cycle
        late. Pinned down here so it cannot come back.
        """
        r = LevelRam()
        r.poke(1, LEVEL, lvl(1, 3200, PRICE))

        out0 = r.step(0, 0, 0, None, None, LEVEL)   # fetch at this edge
        out1 = r.step(1, 0, 0, None, None, 0)       # a different address

        self.assertEqual(out0[1], lvl(1, 3200, PRICE),
                         "fetch did not come back at the edge that made it")
        self.assertEqual(out1, [0, 0])

    def test_pipeline_depth_is_latency_minus_one(self):
        self.assertEqual(len(LevelRam(latency=1).pipe), 0)
        self.assertEqual(len(LevelRam(latency=2).pipe), 1)
        self.assertEqual(len(LevelRam(latency=3).pipe), 2)

    def test_addresses_come_back_in_order(self):
        """Two addresses back to back, each fetched at its own edge."""
        r = LevelRam()
        r.poke(0, 10, lvl(0, 111, 10))
        r.poke(0, 20, lvl(0, 222, 20))

        out0 = r.step(0, 0, 0, None, None, 10)
        out1 = r.step(1, 0, 0, None, None, 20)
        out2 = r.step(2, 0, 0, None, None, 0)

        self.assertEqual(split_level(out0[0])["qty"], 111)
        self.assertEqual(split_level(out1[0])["qty"], 222)
        self.assertEqual(out2[0], 0)

    def test_latency_two_is_configurable(self):
        """
        C_LVL_RAM_OUT_REG true would make this the correct model: one extra
        register between the array and the pin, so one extra edge.
        """
        r = LevelRam(latency=2)
        r.poke(1, 7, lvl(1, 99, 7))

        out0 = r.step(0, 0, 0, None, None, 7)
        out1 = r.step(1, 0, 0, None, None, 0)

        self.assertEqual(out0, [0, 0], "the extra stage was not there")
        self.assertEqual(out1[1], lvl(1, 99, 7))


class TestReadDuringWrite(unittest.TestCase):

    def test_returns_old_data(self):
        """
        READ_FIRST: the read is scheduled before the write lands, so a
        same-cycle read and write to one address gives the PRE-write value.

        This is the behaviour price_storage has to forward around if it wants
        to aggregate two events at the same level back to back, so getting it
        backwards in the model would hide exactly the bug worth finding.
        """
        r = LevelRam(write_mode="READ_FIRST")
        r.poke(1, LEVEL, lvl(1, 100, PRICE))

        # read and write the SAME index at the same edge
        out0 = r.step(0, 1, 1, LEVEL, lvl(1, 999, PRICE), LEVEL)

        self.assertEqual(split_level(out0[1])["qty"], 100,
                         "read-during-write returned NEW data")

        # and the write did land
        self.assertEqual(split_level(r.peek(1, LEVEL))["qty"], 999)

    def test_next_read_sees_the_write(self):
        r = LevelRam(write_mode="READ_FIRST")
        r.step(0, 1, 1, LEVEL, lvl(1, 999, PRICE), LEVEL)   # write
        out1 = r.step(1, 0, 0, None, None, LEVEL)           # read after it
        self.assertEqual(split_level(out1[1])["qty"], 999)


class TestWriteModes(unittest.TestCase):
    """
    The UG573 common-clock collision table, for write port WE=1 and read port
    WE=0:

        write port mode    read port sees      memory
        READ_FIRST         old memory data     new data
        WRITE_FIRST        X  (undefined)      new data
        NO_CHANGE          X  (undefined)      new data

    WRITE_FIRST is transparent write on the port DOING the write. In simple
    dual-port that port's output is unused, so it says nothing about what the
    read port gets - and what the read port gets is undefined.
    """

    def _collide(self, mode):
        r = LevelRam(write_mode=mode)
        r.poke(1, LEVEL, lvl(1, 100, PRICE))
        out = r.step(0, 1, 1, LEVEL, lvl(1, 999, PRICE), LEVEL)
        return r, out

    def test_read_first_returns_old_data(self):
        r, out = self._collide("READ_FIRST")
        self.assertEqual(split_level(out[1])["qty"], 100)
        self.assertEqual(split_level(r.peek(1, LEVEL))["qty"], 999)

    def test_write_first_read_port_is_undefined(self):
        r, out = self._collide("WRITE_FIRST")
        self.assertIsNone(out[1],
                          "WRITE_FIRST must not hand back a defined value on "
                          "the read port - the hardware does not guarantee one")
        self.assertEqual(split_level(r.peek(1, LEVEL))["qty"], 999,
                         "the write itself always succeeds")

    def test_write_first_does_not_return_new_data(self):
        """The specific wrong answer worth guarding against."""
        r, out = self._collide("WRITE_FIRST")
        self.assertNotEqual(out[1], lvl(1, 999, PRICE))

    def test_no_change_read_port_is_undefined(self):
        r, out = self._collide("NO_CHANGE")
        self.assertIsNone(out[1])
        self.assertEqual(split_level(r.peek(1, LEVEL))["qty"], 999)

    def test_default_is_write_first(self):
        """Matches the block RAM default, so an unconfigured model matches."""
        self.assertEqual(LevelRam().write_mode, "WRITE_FIRST")

    def test_other_side_is_unaffected_by_a_collision(self):
        """Only the colliding side loses its read value."""
        r = LevelRam(write_mode="WRITE_FIRST")
        r.poke(0, LEVEL, lvl(0, 55, PRICE))
        out = r.step(0, 1, 1, LEVEL, lvl(1, 999, PRICE), LEVEL)
        self.assertEqual(split_level(out[0])["qty"], 55)
        self.assertIsNone(out[1])

    def test_no_collision_when_addresses_differ(self):
        for mode in LevelRam.WRITE_MODES:
            r = LevelRam(write_mode=mode)
            r.poke(1, LEVEL, lvl(1, 100, PRICE))
            out = r.step(0, 1, 1, LEVEL + 1, lvl(1, 999, PRICE), LEVEL)
            self.assertEqual(split_level(out[1])["qty"], 100, mode)
            self.assertEqual(r.collisions, 0, mode)

    def test_collision_follows_the_written_side(self):
        """
        The read address is broadcast to BOTH sides, so a write to side 0 at
        that address collides on side 0 and leaves side 1 alone. Which side is
        undefined follows wsel, not the address.
        """
        r = LevelRam(write_mode="WRITE_FIRST")
        r.poke(0, LEVEL, lvl(0, 100, PRICE))
        r.poke(1, LEVEL, lvl(1, 200, PRICE))
        out = r.step(0, 1, 0, LEVEL, lvl(0, 999, PRICE), LEVEL)

        self.assertIsNone(out[0], "the written side should be undefined")
        self.assertEqual(split_level(out[1])["qty"], 200,
                         "the other side is a separate memory")
        self.assertEqual(r.collisions, 1)

    def test_collisions_counted_even_when_defined(self):
        r, _ = self._collide("READ_FIRST")
        self.assertEqual(r.collisions, 1)
        self.assertTrue(any(h[0] == "collision" for h in r.history))

    def test_bad_write_mode_rejected(self):
        with self.assertRaises(ValueError):
            LevelRam(write_mode="TRANSPARENT")


class TestSinglePortTransparency(unittest.TestCase):
    """
    SINGLE_PORT: one port per side does both the read and the write, so the
    write mode describes THAT port's output and WRITE_FIRST transparency is
    real - new data, next cycle.

    The catch is structural: one port carries one address per cycle, so it
    cannot read one level while writing another. port_conflicts counts how
    often the design asks for that, which is the number to look at before
    committing to this arrangement.
    """

    def _collide(self, mode):
        r = LevelRam(write_mode=mode, port_config="SINGLE_PORT")
        r.poke(1, LEVEL, lvl(1, 100, PRICE))
        r.step(0, 0, 0, None, None, LEVEL)            # a plain read first
        out = r.step(1, 1, 1, LEVEL, lvl(1, 999, PRICE), LEVEL)
        return r, out

    def test_write_first_is_transparent(self):
        r, out = self._collide("WRITE_FIRST")
        self.assertEqual(split_level(out[1])["qty"], 999,
                         "WRITE_FIRST on the writing port must show new data")

    def test_read_first_still_gives_old_data(self):
        r, out = self._collide("READ_FIRST")
        self.assertEqual(split_level(out[1])["qty"], 100)

    def test_no_change_holds_the_previous_output(self):
        r, out = self._collide("NO_CHANGE")
        self.assertEqual(split_level(out[1])["qty"], 100,
                         "NO_CHANGE holds the last read, it does not refetch")

    def test_differing_addresses_are_a_port_conflict(self):
        r = LevelRam(write_mode="WRITE_FIRST", port_config="SINGLE_PORT")
        r.step(0, 1, 1, LEVEL, lvl(1, 999, PRICE), LEVEL + 1)
        self.assertEqual(r.port_conflicts, 1)
        self.assertTrue(any(h[0] == "port_conflict" for h in r.history))

    def test_same_address_is_not_a_port_conflict(self):
        r, _ = self._collide("WRITE_FIRST")
        self.assertEqual(r.port_conflicts, 0)

    def test_sdp_never_reports_port_conflicts(self):
        """Two ports, two addresses - that is what SDP is for."""
        r = LevelRam(port_config="SDP")
        r.step(0, 1, 1, LEVEL, lvl(1, 999, PRICE), LEVEL + 1)
        self.assertEqual(r.port_conflicts, 0)

    def test_bad_port_config_rejected(self):
        with self.assertRaises(ValueError):
            LevelRam(port_config="TDP")

    def test_default_is_sdp(self):
        self.assertEqual(LevelRam().port_config, "SDP")


class TestWritePort(unittest.TestCase):

    def test_wsel_picks_the_side(self):
        r = LevelRam()
        r.step(0, 1, 0, LEVEL, lvl(0, 11, PRICE), None)
        r.step(1, 1, 1, LEVEL, lvl(1, 22, PRICE), None)
        self.assertEqual(split_level(r.peek(0, LEVEL))["qty"], 11)
        self.assertEqual(split_level(r.peek(1, LEVEL))["qty"], 22)

    def test_sides_are_independent(self):
        r = LevelRam()
        r.step(0, 1, 1, LEVEL, lvl(1, 22, PRICE), None)
        self.assertEqual(r.peek(0, LEVEL), 0, "write bled across sides")

    def test_no_write_when_we_low(self):
        r = LevelRam()
        r.step(0, 0, 1, LEVEL, lvl(1, 22, PRICE), None)
        self.assertEqual(r.peek(1, LEVEL), 0)
        self.assertEqual(r.writes, 0)

    def test_read_only_traffic_writes_nothing(self):
        """
        The current state of price_storage: lvl_we never rises. The model must
        stay empty rather than accumulating anything of its own.
        """
        r = LevelRam()
        for c in range(50):
            r.step(c, 0, 0, None, None, LEVEL)
        self.assertEqual(r.writes, 0)
        self.assertEqual(r.written_levels(), [])


class TestUnusableWrites(unittest.TestCase):
    """
    lvl_waddr is undriven in price_storage today, so it arrives as None. The
    model must refuse those writes rather than picking an address, and must
    say so.
    """

    def _drop_reason(self, we, wsel, waddr, wdata):
        r = LevelRam()
        r.step(0, we, wsel, waddr, wdata, None)
        self.assertEqual(r.writes, 0)
        self.assertEqual(r.dropped, 1)
        rec = r.history[-1]
        self.assertEqual(rec[0], "write_dropped")
        return rec[5]

    def test_metavalue_address(self):
        self.assertIn("metavalue",
                      self._drop_reason(1, 1, None, lvl(1, 1, 1)))

    def test_metavalue_data(self):
        self.assertIn("metavalue", self._drop_reason(1, 1, LEVEL, None))

    def test_metavalue_wsel(self):
        self.assertIn("metavalue",
                      self._drop_reason(1, None, LEVEL, lvl(1, 1, 1)))

    def test_address_out_of_range(self):
        self.assertIn("outside",
                      self._drop_reason(1, 1, LVL_DEPTH, lvl(1, 1, 1)))

    def test_dropped_write_leaves_memory_untouched(self):
        r = LevelRam()
        r.poke(1, LEVEL, lvl(1, 100, PRICE))
        r.step(0, 1, 1, None, lvl(1, 999, PRICE), None)
        self.assertEqual(split_level(r.peek(1, LEVEL))["qty"], 100)


class TestUnusableReads(unittest.TestCase):

    def test_metavalue_address_gives_none(self):
        r = LevelRam()
        self.assertEqual(r.step(0, 0, 0, None, None, None), [None, None])

    def test_out_of_range_address_is_recorded(self):
        r = LevelRam()
        r.step(0, 0, 0, None, None, LVL_DEPTH + 5)
        self.assertEqual(r.history[-1][0], "read_oob")


class TestInspection(unittest.TestCase):

    def test_unwritten_slot_reads_zero(self):
        r = LevelRam()
        self.assertEqual(r.peek(0, 1234), 0)
        self.assertEqual(r.peek(1, 0), 0)

    def test_written_levels_tracks_writes_only(self):
        r = LevelRam()
        for c in range(10):
            r.step(c, 0, 0, None, None, c)       # reads only
        self.assertEqual(r.written_levels(), [])
        r.step(99, 1, 1, LEVEL, lvl(1, 1, PRICE), None)
        self.assertEqual(r.written_levels(), [LEVEL])

    def test_written_levels_merges_sides(self):
        r = LevelRam()
        r.step(0, 1, 0, 10, lvl(0, 1, 10), None)
        r.step(1, 1, 1, 20, lvl(1, 1, 20), None)
        self.assertEqual(r.written_levels(), [10, 20])

    def test_clear_empties_everything(self):
        r = LevelRam()
        r.step(0, 1, 1, LEVEL, lvl(1, 1, PRICE), None)
        r.clear()
        self.assertEqual(r.written_levels(), [])
        self.assertEqual(r.peek(1, LEVEL), 0)

    def test_dump_shows_written_and_extra(self):
        r = LevelRam()
        r.step(0, 1, 1, LEVEL, lvl(1, 3200, PRICE), None)
        text = r.dump(extra_levels=[LEVEL - 1, LEVEL + 1])
        self.assertIn(str(LEVEL), text)
        self.assertIn("3200", text)
        self.assertIn(str(LEVEL - 1), text)      # never written, still shown
        self.assertIn("written", text)

    def test_dump_when_empty(self):
        self.assertIn("nothing", LevelRam().dump())


class TestPriceStorageShapedTraffic(unittest.TestCase):
    """
    The pattern this model exists to sit under: many events at ONE price level
    on one side, back to back, which is what test_book_PLS.py drives.
    """

    def test_thirty_two_writes_to_one_level(self):
        r = LevelRam()
        running = 0
        for i in range(32):
            running += 100 * (i + 1)
            # read the level, then write the accumulated total to it
            r.step(i, 1, 1, LEVEL, lvl(1, running, PRICE), LEVEL)

        self.assertEqual(r.writes, 32)
        self.assertEqual(r.written_levels(), [LEVEL])
        self.assertEqual(split_level(r.peek(1, LEVEL))["qty"], running)
        self.assertEqual(running, 100 * 32 * 33 // 2)

    def test_back_to_back_reads_lag_by_one(self):
        """
        Consecutive same-address read/write pairs: every read returns the
        value written two cycles earlier, not one. This is the hazard
        price_storage has to forward around.
        """
        r = LevelRam(write_mode="READ_FIRST")
        seen = []
        for i in range(5):
            out = r.step(i, 1, 1, LEVEL, lvl(1, i + 1, PRICE), LEVEL)
            seen.append(None if out[1] is None
                        else split_level(out[1])["qty"])
        # Each edge fetches before its own write lands, so what comes back is
        # the value written at the PREVIOUS edge. That one-cycle staleness is
        # the hazard price_storage has to forward around when two events hit
        # the same level back to back.
        self.assertEqual(seen, [0, 1, 2, 3, 4])


if __name__ == "__main__":
    unittest.main(verbosity=2)
