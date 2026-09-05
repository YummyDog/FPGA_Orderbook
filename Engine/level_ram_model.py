"""
level_ram_model.py - a Python model of the price level memory.

Replaces level_array.vhd. price_storage's level bus comes out to the pins of
book_PLS_top and this sits on the other end of it.

WHAT IT IS MODELLING

level_array was C_NUM_SIDES independent ram_sdp instances, one per side, and
this reproduces that structure and its timing exactly:

    read latency 1        address presented on cycle N, data valid on N+1,
                          because step() runs at the edge ending cycle N and
                          what it returns is driven for cycle N+1
    read during write     depends on WRITE_MODE - see below
    one write port        one side at a time, chosen by wsel ('0' = side 0)
    one read port/side    both sides read at the SAME address, because
                          price_storage issues one lvl_raddr and indexes the
                          returned pair by side
    no reset              ram_sdp has no reset on its array; real block RAM
                          has none either
    zero init             contents start at zero in SIMULATION ONLY. The RTL
                          comment is explicit that real BRAM contents after
                          configuration are part-dependent, so nothing may
                          assume a slot it has not written reads as zero. The
                          model starts at zero to match the simulator, not
                          because zero is meaningful.

If C_LVL_RAM_OUT_REG is ever set true in level_pkg, read latency becomes 2 and
LevelRam(latency=2) has to be passed to match. Nothing detects that mismatch
automatically - it would show up as data arriving a cycle early.


WRITE MODE, AND WHY WRITE_FIRST DOES NOT GIVE YOU NEW DATA

The write mode is a property of ONE PORT and governs what that port puts on
its own output after a write edge. WRITE_FIRST is transparent write: the data
going in also appears on the output OF THE PORT DOING THE WRITING.

In simple dual-port there are two ports - A writes, B reads - and the write
port's data output is not connected to anything. So the write mode does not
describe the read port at all. What the read port sees during a same-address
collision is given by the collision table in UG573 (common clock, write port
WE=1, read port WE=0):

    write port mode    read port sees      memory
    READ_FIRST         old memory data     new data
    WRITE_FIRST        X  (undefined)      new data
    NO_CHANGE          X  (undefined)      new data

Only READ_FIRST is defined on the read port. WRITE_FIRST and NO_CHANGE both
leave it undeterministic, and an independent clock makes even READ_FIRST
undefined - so the common clock is load-bearing.

This model implements all three. On a collision it returns:

    READ_FIRST         the pre-write contents
    WRITE_FIRST        None, surfaced as 'X' by the harness
    NO_CHANGE          None, surfaced as 'X' by the harness

None rather than the new data, because "undeterministic" is not a value the
model is entitled to invent. A model that returned new data here would work
in simulation and fail on the board, which is the failure mode worth the most
to avoid. Every collision is recorded in history whichever mode is set, so
they can be counted even when the returned value is defined.

If what you want is the read port returning the NEW data, no block RAM mode
provides it in SDP. That is bypass logic in fabric - the write-forwarding
already needed for the one- and two-cycle cases, where the memory is not
involved at all.

AMD's default is WRITE_FIRST, and it is also this model's default, so an
unconfigured LevelRam matches an unconfigured block RAM. READ_FIRST costs
about 15% more power than NO_CHANGE and AMD recommends it only where needed
for functionality or collision mitigation - so if forwarding guarantees no
collision ever reaches the memory, NO_CHANGE is the cheaper setting and the
undefined value never arises.

TWO PIECES

    LevelRam            pure Python, no cocotb. The memory itself.
    drive_level_ram()   a cocotb coroutine that binds a LevelRam to the DUT.

LevelRam has no simulator dependency at all, so it can be driven from a plain
unit test, from a different harness, or by hand.

SAMPLING, AND WHY IT IS DONE AT THE FALLING EDGE

The driver samples the write and read controls at the falling edge and applies
them at the rising edge that follows. That is the same convention the tracing
in test_book_PLS.py uses, and it is what makes the model deterministic: at the
falling edge every driver has settled, so the values read are exactly the ones
the memory would capture at the next rising edge. Sampling at the rising edge
instead would race the registers inside price_storage updating on that same
edge, and whether the model saw the old or new value would depend on delta
ordering rather than on the design.
"""

try:
    from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly
    from cocotb.types import LogicArray
    _HAVE_COCOTB = True
except ImportError:                            # standalone use, no simulator
    _HAVE_COCOTB = False


# What the driver puts on lvl_rdata when the model has no defined value.
# True drives X, which propagates and makes the dependency visible.
UNDEFINED_DRIVES_X = True


# ---------------------------------------------------------------------------
# Geometry - must match level_pkg
# ---------------------------------------------------------------------------
NUM_SIDES = 2                # C_NUM_SIDES
LVL_ADDR_W = 14              # C_LVL_ADDR_W
LVL_DEPTH = 2 ** LVL_ADDR_W  # C_LVL_DEPTH

LVL_SIDE_W = 1               # C_LVL_SIDE_W
LVL_QTY_W = 32               # C_LVL_QTY_W
LVL_PRICE_W = 32             # C_LVL_PRICE_W
LEVEL_W = LVL_SIDE_W + LVL_QTY_W + LVL_PRICE_W

LVL_QTY_MASK = (1 << LVL_QTY_W) - 1
LVL_PRICE_MASK = (1 << LVL_PRICE_W) - 1
LEVEL_MASK = (1 << LEVEL_W) - 1


def split_level(v):
    """
    side / qty / price out of a level slot.

        MSB                                      LSB
       +------+---------------+------------------+
       | side |      qty      |      price       |
       +------+---------------+------------------+
    """
    if v is None:
        return None
    return {
        "side": (v >> (LVL_QTY_W + LVL_PRICE_W)) & 1,
        "qty": (v >> LVL_PRICE_W) & LVL_QTY_MASK,
        "price": v & LVL_PRICE_MASK,
    }


def make_level(side, qty, price):
    """Pack a level slot. For priming the model before a case."""
    return (((side & 1) << (LVL_QTY_W + LVL_PRICE_W))
            | ((qty & LVL_QTY_MASK) << LVL_PRICE_W)
            | (price & LVL_PRICE_MASK))


def fmt_level(v, width=34):
    if v is None:
        return "?" * width
    d = split_level(v)
    return (f"{'B' if d['side'] == 0 else 'S'}  "
            f"qty={d['qty']:<10d} px={d['price']:<8d}")


# ---------------------------------------------------------------------------
# The memory
# ---------------------------------------------------------------------------
class LevelRam:
    """
    C_NUM_SIDES independent memories with one shared write port.

    Storage is a dict per side rather than a flat list of 16384 entries. Not
    for speed - it is so that "which levels have ever been written" is a
    question the model can answer directly, which a zero-filled array cannot.
    Anything never written reads as zero, same as the simulator.

    Nothing here checks anything. It records what it was told to do and
    returns what it holds.
    """

    WRITE_MODES = ("WRITE_FIRST", "READ_FIRST", "NO_CHANGE")
    PORT_CONFIGS = ("SDP", "SINGLE_PORT")

    def __init__(self, sides=NUM_SIDES, depth=LVL_DEPTH, latency=1,
                 write_mode="WRITE_FIRST", port_config="SDP"):
        if write_mode not in self.WRITE_MODES:
            raise ValueError(
                f"write_mode must be one of {self.WRITE_MODES}, "
                f"got {write_mode!r}")
        if port_config not in self.PORT_CONFIGS:
            raise ValueError(
                f"port_config must be one of {self.PORT_CONFIGS}, "
                f"got {port_config!r}")

        self.sides = sides
        self.depth = depth
        self.latency = latency
        self.write_mode = write_mode
        self.port_config = port_config

        # mem[side][index] -> packed slot. Absent means never written.
        self.mem = [dict() for _ in range(sides)]

        # Read data pipeline.
        #
        # DEPTH IS latency - 1, NOT latency. step() is called AT a clock edge
        # and returns the new contents of the output register, which is what
        # the design sees during the cycle that FOLLOWS. That presentation is
        # itself the first cycle of latency, so only the cycles beyond the
        # first need storing:
        #
        #   latency 1   ram_sdp with G_OUT_REG false
        #               rdata_1 <= ram(raddr)
        #               nothing to store, step returns the fetch directly
        #
        #   latency 2   G_OUT_REG true
        #               rdata_1 <= ram(raddr); rdata_2 <= rdata_1
        #               one stage, step returns the previous fetch
        #
        # Getting this wrong is not obvious from the outside - the data still
        # arrives and still looks plausible, just a cycle after the design
        # expected it.
        self.pipe = [[0] * sides for _ in range(latency - 1)]

        # Everything that happened, in order, for the log.
        #   ("write", cycle, side, addr, data)
        #   ("write_dropped", cycle, side, addr, data, reason)
        #   ("read",  cycle, addr, [per-side values returned])
        #   ("collision", cycle, side, addr, write_mode, note)
        self.history = []

        self.writes = 0
        self.dropped = 0
        self.reads = 0
        self.collisions = 0
        self.port_conflicts = 0

        # Last value presented, for NO_CHANGE hold behaviour.
        self._last_out = [0] * sides

    # -- inspection --------------------------------------------------------
    def peek(self, side, addr):
        """Contents of one slot without disturbing anything."""
        if addr is None or not (0 <= addr < self.depth):
            return None
        return self.mem[side].get(addr, 0)

    def poke(self, side, addr, value):
        """Prime a slot directly, bypassing the write port."""
        self.mem[side][addr] = value & LEVEL_MASK

    def written_levels(self):
        """Every index ever written, on any side, sorted."""
        out = set()
        for side in range(self.sides):
            out |= set(self.mem[side].keys())
        return sorted(out)

    def clear(self):
        """
        Wipe the contents.

        Note this has no counterpart in hardware - the RTL has no reset on the
        array and could not have one without stopping the synthesiser
        inferring a memory. Use it between cases if you want a clean start,
        not to model anything the design does.
        """
        self.mem = [dict() for _ in range(self.sides)]
        self.pipe = [[0] * self.sides for _ in range(self.latency - 1)]

    # -- the memory itself -------------------------------------------------
    def step(self, cycle, we, wsel, waddr, wdata, raddr):
        """
        One clock edge.

        Returns the NEW CONTENTS OF THE OUTPUT REGISTER, which is what the
        design sees during the cycle after this edge. It is not "the data for
        the address you just passed in, available now" - that distinction is
        the whole of the read latency, so read it carefully if you are driving
        this by hand.

        Order matters and mirrors ram_sdp: the read is sampled from the array
        BEFORE the write is applied, which is what makes read-during-write
        return old data.

        Any of the arguments may be None, which is how a metavalue on the bus
        arrives. A write with an unknown address or unknown data is dropped
        and recorded - there is no address to put it at, and inventing one
        would hide the problem.

        Returns the per-side values now being presented on the read port.
        """
        # 1. read, from the pre-write array
        #
        # A collision is a write and a read to the same address on the same
        # side in the same cycle. What the read port is allowed to return then
        # is set by the write mode - see the table in the header. Recorded
        # either way, so collisions can be counted even in READ_FIRST where the
        # value returned is defined and nothing looks wrong.
        if raddr is not None and 0 <= raddr < self.depth:
            fetched = [self.mem[s].get(raddr, 0) for s in range(self.sides)]
            self.reads += 1

            writing = (we == 1 and wsel is not None
                       and 0 <= wsel < self.sides)
            collided = writing and waddr is not None and waddr == raddr

            if self.port_config == "SINGLE_PORT":
                # One port per side does both the read and the write, so the
                # write mode describes what THIS port shows and transparency
                # is real.
                if writing:
                    if waddr is not None and raddr != waddr:
                        # Structurally impossible: a single port carries one
                        # address per cycle. Recorded rather than resolved,
                        # because which one wins is a design decision.
                        self.port_conflicts += 1
                        self.history.append(
                            ("port_conflict", cycle, wsel, raddr, waddr,
                             "single port cannot read one address and write "
                             "another in the same cycle"))
                    if self.write_mode == "WRITE_FIRST":
                        fetched[wsel] = (wdata & LEVEL_MASK
                                         if wdata is not None else None)
                    elif self.write_mode == "NO_CHANGE":
                        fetched[wsel] = self._last_out[wsel]
                    # READ_FIRST already holds the pre-write contents
                    if collided:
                        self.collisions += 1
                        self.history.append(
                            ("collision", cycle, wsel, raddr, self.write_mode,
                             "SINGLE_PORT: " + {
                                 "WRITE_FIRST": "new data, transparent",
                                 "READ_FIRST": "pre-write contents",
                                 "NO_CHANGE": "output holds previous read",
                             }[self.write_mode]))

            elif collided:
                # SDP. The write mode describes the WRITE port's own output,
                # which SDP does not use. What the read port gets is the
                # UG573 collision table, and only READ_FIRST is defined.
                self.collisions += 1
                if self.write_mode != "READ_FIRST":
                    # Not the new data - the model is not entitled to invent
                    # a value the hardware does not guarantee.
                    fetched[wsel] = None
                self.history.append(
                    ("collision", cycle, wsel, raddr, self.write_mode,
                     "SDP: defined, old data"
                     if self.write_mode == "READ_FIRST"
                     else "SDP: UNDEFINED on the read port"))

            self.history.append(("read", cycle, raddr, list(fetched)))
        else:
            # Unknown address. The real memory would index with a metavalue;
            # None propagates instead so it is visible rather than plausible.
            fetched = [None] * self.sides
            if raddr is not None:
                self.history.append(("read_oob", cycle, raddr, None))

        # 2. write, after the read has been taken
        if we == 1:
            reason = None
            if waddr is None:
                reason = "address is a metavalue"
            elif not (0 <= waddr < self.depth):
                reason = f"address {waddr} outside 0..{self.depth - 1}"
            elif wdata is None:
                reason = "data is a metavalue"
            elif wsel is None:
                reason = "wsel is a metavalue"
            elif not (0 <= wsel < self.sides):
                reason = f"wsel {wsel} names no side"

            if reason is None:
                self.mem[wsel][waddr] = wdata & LEVEL_MASK
                self.writes += 1
                self.history.append(("write", cycle, wsel, waddr, wdata))
            else:
                self.dropped += 1
                self.history.append(
                    ("write_dropped", cycle, wsel, waddr, wdata, reason))

        # 3. advance the output pipeline
        #
        # With latency 1 the pipe is empty, so this appends and immediately
        # pops the same value back out - the fetch is presented for the next
        # cycle with no further delay. With latency 2 there is one stage and
        # the previous fetch comes out instead.
        self.pipe.append(fetched)
        out = self.pipe.pop(0)
        self._last_out = list(out)
        return out

    # -- reporting ---------------------------------------------------------
    def summary(self):
        out = (f"{self.port_config}, WRITE_MODE={self.write_mode}, "
               f"latency={self.latency} | "
               f"{self.writes} write(s), {self.dropped} dropped, "
               f"{self.reads} read(s), "
               f"{len(self.written_levels())} level(s) ever written")
        if self.collisions:
            defined = (self.port_config == "SINGLE_PORT"
                       or self.write_mode == "READ_FIRST")
            out += (f" | {self.collisions} read-during-write collision(s), "
                    + ("read data defined" if defined
                       else "READ DATA UNDEFINED in this mode"))
        if self.port_conflicts:
            out += (f" | {self.port_conflicts} SINGLE_PORT conflict(s) - "
                    "read and write wanted different addresses")
        return out

    def dump(self, extra_levels=(), width=34):
        """
        Text picture of the memory.

        Shows every level ever written, plus whatever extra indices are asked
        for so that a level the design never touched still appears as zero
        rather than silently going missing.
        """
        show = sorted(set(self.written_levels()) | set(extra_levels))

        lines = [f"      {self.summary()}"]
        if not show:
            lines.append("      (nothing written and nothing to show)")
            return "\n".join(lines)

        lines.append(f"      {'idx':>6}   {'side 0 (bid)':<{width}}  "
                     f"{'side 1 (ask)':<{width}}")
        for idx in show:
            a = fmt_level(self.peek(0, idx), width)
            b = fmt_level(self.peek(1, idx), width)
            mark = "  <- written" if any(
                idx in self.mem[s] for s in range(self.sides)) else ""
            lines.append(f"      {idx:>6}   {a:<{width}}  {b:<{width}}{mark}")
        return "\n".join(lines)


# ---------------------------------------------------------------------------
# cocotb binding
# ---------------------------------------------------------------------------
def _safe_int(handle):
    try:
        return int(handle.value)
    except (ValueError, TypeError):
        return None


async def drive_level_ram(dut, ram):
    """
    Bind a LevelRam to book_PLS_top's level bus. Start with cocotb.start_soon.

    Runs forever. Each iteration is one clock period:

        falling edge   sample we / wsel / waddr / wdata / raddr, which are
                       stable by now and are what the memory would capture
        rising edge    apply them, then drive the read data out

    Driving immediately after the rising edge puts the new read data in the
    same region as every register in the design updating on that edge, which
    is what a memory with an output register does. price_storage sees it for
    the whole of the following cycle.

    The cycle counter is the model's own and starts at zero when this
    coroutine starts, so it will not line up with the per-message cycle
    numbers in the bus trace. It is there to order the history, nothing else.
    """
    if not _HAVE_COCOTB:
        raise RuntimeError(
            "drive_level_ram needs cocotb. The LevelRam class itself does "
            "not - import that on its own if you are driving it by hand."
        )

    cycle = 0

    # Drive the output before the first edge. ram_sdp declares its read
    # register as
    #
    #     signal rdata_1 : ... := (others => '0');
    #
    # so the RTL presented zero from time zero, not 'U'. price_storage reads
    # lvl_rdata combinationally into qty_c, so leaving these undriven until
    # the first rising edge would push a metavalue through it for the first
    # cycle and a half - a difference from the design that has nothing to do
    # with the design.
    dut.lvl_rdata0.value = 0
    dut.lvl_rdata1.value = 0

    while True:
        await FallingEdge(dut.clk)
        await ReadOnly()

        we = _safe_int(dut.lvl_we)
        wsel = _safe_int(dut.lvl_wsel)
        waddr = _safe_int(dut.lvl_waddr)
        wdata = _safe_int(dut.lvl_wdata)
        raddr = _safe_int(dut.lvl_raddr)

        await RisingEdge(dut.clk)

        out = ram.step(cycle, we, wsel, waddr, wdata, raddr)
        cycle += 1

        # None means the model has no defined value to give: either the read
        # address made no sense, or this was a collision in a write mode where
        # the hardware does not guarantee the read data.
        #
        # UNDEFINED_DRIVES_X decides what goes on the bus. 'X' is the honest
        # answer and it propagates into price_storage, which is the point -
        # a design that depends on collision data will visibly break here
        # rather than silently working in simulation and failing on the board.
        # Set it False to drive zero instead if the X-propagation makes an
        # unrelated problem hard to see.
        for port, value in ((dut.lvl_rdata0, out[0]), (dut.lvl_rdata1, out[1])):
            if value is not None:
                port.value = value
            elif UNDEFINED_DRIVES_X:
                port.value = LogicArray("X" * LEVEL_W)
            else:
                port.value = 0
