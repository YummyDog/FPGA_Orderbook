"""
Shared harness for the market_data_top testbenches.

Everything that is not a test lives here: geometry constants mirroring the
RTL packages, a Python copy of the band map, frame building, the stimulus
driver, the bus trace and the dump formatters.

NOTHING IN HERE CHECKS ANYTHING. It drives traffic and prints state. There
are no assertions, no expected values and no pass/fail verdict beyond "the
run completed". Reading the dumps is the verification step.

See README_tests.md for what each test does and what to look for.
"""

import struct

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly

import asx_packets as pkt
import book_model as bm

CLK_PERIOD_NS = 6.21         # 161 MHz, matching the synthesis constraint

# cocotb's formatter does msg.splitlines()[0], and "".splitlines() is [], so
# an EMPTY log message raises IndexError inside the formatter. A single space
# formats fine and still reads as a blank line.
BLANK = " "


def blank(dut, n=1):
    for _ in range(n):
        dut._log.info(BLANK)


BOOK_ID = bm.DEFAULT_BOOK_ID          # 85603, must match G_ORDER_BOOK_ID

BUY = 0
SELL = 1
SIDE_BYTE = {BUY: bm.SIDE_BUY, SELL: bm.SIDE_SELL}


# ===========================================================================
# GEOMETRY - mirrors the RTL packages. NOT derived from them.
#
# If C_ADDR_W, C_KEY_W, C_VAL_W or C_LVL_MAX_CENT change, these must change
# with them or the dumps decode against the wrong layout and print plausible
# garbage. level_array prints its real geometry as an elaboration note, so
# the first lines of any run are the place to check.
# ===========================================================================

# --- order tables, from ram_pkg -------------------------------------------
NUM_TABLES = 4
ADDR_W = 4
DEPTH = 2 ** ADDR_W
CAPACITY = NUM_TABLES * DEPTH        # 64

ORDER_ID_W = 64
KEY_W = 65                           # order_id(64) & side(1)
VAL_W = 66                           # qty(32) price(32) undisc(1) implied(1)
SLOT_W = 1 + KEY_W + VAL_W           # 132
VALID_BIT = SLOT_W - 1
KEY_MASK = (1 << KEY_W) - 1
VAL_MASK = (1 << VAL_W) - 1
KEY_HEX = (KEY_W + 3) // 4

CELL_W = 5                           # "E5EDS"
QCELL_W = 6

# --- level tables, from level_pkg -----------------------------------------
NUM_SIDES = 2
LVL_ADDR_W = 14
LVL_DEPTH = 2 ** LVL_ADDR_W
LVL_SIDE_W, LVL_QTY_W, LVL_PRICE_W = 1, 32, 32
LEVEL_W = LVL_SIDE_W + LVL_QTY_W + LVL_PRICE_W
LVL_SIDE_BIT = LEVEL_W - 1
LVL_QTY_LO = LVL_PRICE_W
LVL_FIELD_W = 34

# --- t_book_op, ordinals from ram_pkg -------------------------------------
OP_NAMES = ("OP_ADD", "OP_EXEC", "OP_REPLACE", "OP_DELETE")
OP_SHORT = ("ADD", "EXEC", "REPL", "DEL")
OP_ADD, OP_EXEC, OP_REPLACE, OP_DELETE = 0, 1, 2, 3

# --- message scope, from book_input_stage.f_is_scoped ---------------------
IN_SCOPE = (bm.T_ADD, bm.T_REPLACE, bm.T_EXEC, bm.T_DELETE)
OUT_OF_SCOPE = (bm.T_ADD_PID, bm.T_EXEC_PRICE)

DRAIN_CYCLES = 60
WATCH_SPAN = 2                       # level neighbours printed either side


# ===========================================================================
# BAND MAP - a Python copy of level_cfg_pkg, for LABELLING ONLY
#
# Used to print "index 5280 (px 50000)" next to a level and to pick on-tick
# prices for the stimulus. Never compared against the design: if the RTL
# disagrees, the log says so by showing a write at an index this predicts
# differently, which is exactly the signal you want.
# ===========================================================================
PX_PER_CENT = 10
MAX_CENT = 10000
BANDS_CFG = [(0, 1), (10, 5), (200, 10)]     # (lo_cent, tick in price units)


def _build_band_map():
    out, base = [], 0
    for i, (lo_c, tick) in enumerate(BANDS_CFG):
        lo = lo_c * PX_PER_CENT
        hi = (BANDS_CFG[i + 1][0] * PX_PER_CENT if i + 1 < len(BANDS_CFG)
              else MAX_CENT * PX_PER_CENT)
        n = (hi - lo) // tick
        out.append({"lo": lo, "hi": hi, "tick": tick, "n": n, "base": base})
        base += n
    return out, base


BAND_MAP, N_LEVELS = _build_band_map()       # 10280 levels -> 14 addr bits


def px_index(price: int):
    """Level index for a price, or 0 for anything outside the bands."""
    for b in BAND_MAP:
        if b["lo"] <= price < b["hi"]:
            return b["base"] + (price - b["lo"]) // b["tick"]
    return 0                                  # what px_index does too


def px_on_tick(price: int) -> bool:
    for b in BAND_MAP:
        if b["lo"] <= price < b["hi"]:
            return (price - b["lo"]) % b["tick"] == 0
    return False


def px_tick(price: int) -> int:
    for b in BAND_MAP:
        if b["lo"] <= price < b["hi"]:
            return b["tick"]
    return 0


# A few on-tick prices in the top band (tick 10 units = 1 cent), well clear
# of the band boundaries.
PX = {
    "low": 20000,        # $20.00  -> index 2280
    "mid": 35000,        # $35.00  -> index 3780
    "ref": 50000,        # $50.00  -> index 5280
    "ref1": 50010,       # one tick up
    "ref2": 50020,
    "high": 65000,       # $65.00  -> index 6780
}


# ===========================================================================
# Order identity
# ===========================================================================
SESSION_PREFIX = 0x621F1282


def make_order_id(n: int) -> int:
    return (SESSION_PREFIX << 32) | (n & 0xFFFFFFFF)


def make_key(order_id: int, side: int) -> int:
    """Matches the RTL:  key <= s_order_id & s_side.  Side is bit 0."""
    return ((order_id & ((1 << ORDER_ID_W) - 1)) << 1) | (side & 1)


def split_key(key: int):
    return (key >> 1) & ((1 << ORDER_ID_W) - 1), key & 1


def to_signed32(v: int) -> int:
    return v - (1 << 32) if v & 0x80000000 else v


def split_value(v):
    if v is None:
        return None
    return {"qty": (v >> 34) & 0xFFFFFFFF,
            "price": to_signed32((v >> 2) & 0xFFFFFFFF),
            "undisc": (v >> 1) & 1,
            "implied": v & 1}


def split_level(v):
    if v is None:
        return None
    return {"side": (v >> LVL_SIDE_BIT) & 1,
            "qty": (v >> LVL_QTY_LO) & 0xFFFFFFFF,
            "price": to_signed32(v & 0xFFFFFFFF)}


def slot_key(slot):
    return None if slot is None else (slot >> VAL_W) & KEY_MASK


def slot_val(slot):
    return None if slot is None else slot & VAL_MASK


# ===========================================================================
# Message and frame building
# ===========================================================================
_seq = [1]


def next_seq(n: int = 1) -> int:
    s = _seq[0]
    _seq[0] += n
    return s


def reset_seq():
    _seq[0] = 1


def msg_add(oid, side, qty, price, pos=1, extype=0, pid=False):
    return bm.build_add(order_id=oid, book_id=BOOK_ID, side=SIDE_BYTE[side],
                        qty=qty, price=price, position=pos, extype=extype,
                        with_pid=pid)


def msg_replace(oid, side, qty, price, pos=1, extype=0):
    return bm.build_replace(order_id=oid, book_id=BOOK_ID,
                            side=SIDE_BYTE[side], qty=qty, price=price,
                            position=pos, extype=extype)


def msg_exec(oid, side, qty, trade_price=None):
    return bm.build_exec(order_id=oid, book_id=BOOK_ID, side=SIDE_BYTE[side],
                         qty=qty, trade_price=trade_price)


def msg_delete(oid, side):
    return bm.build_delete(order_id=oid, book_id=BOOK_ID,
                           side=SIDE_BYTE[side])


def frame_one(msg: bytes, **kw) -> bytes:
    """One ITCH message in one MoldUDP64 packet."""
    return pkt.build_frame(itch_msg=msg, mold_seqnum=next_seq(),
                           mold_msg_count=1, **kw)


def frame_many(msgs, **kw) -> bytes:
    """
    Several ITCH messages in one MoldUDP64 packet.

    asx_packets.build_frame writes a single length-prefixed block, so the
    Mold payload is assembled here and spliced on. Everything below Mold -
    UDP length, IPv4 total length and checksum, Ethernet - is still built and
    then corrected using asx_packets' own helpers.
    """
    if len(msgs) == 1:
        return frame_one(msgs[0], **kw)

    body = b"".join(struct.pack(">H", len(m)) + m for m in msgs)
    first, rest = msgs[0], body[2 + len(msgs[0]):]

    frame = pkt.build_frame(itch_msg=first, mold_seqnum=next_seq(len(msgs)),
                            mold_msg_count=len(msgs), **kw)
    frame += rest

    eth_len = 14 if frame[12:14] != struct.pack(">H", pkt.TPID_8021Q) else 18
    ihl = (frame[eth_len] & 0x0F) * 4
    ip_off, udp_off = eth_len, eth_len + ihl

    ip_total = ihl + (len(frame) - udp_off)
    frame = frame[:ip_off + 2] + struct.pack(">H", ip_total) + frame[ip_off + 4:]
    frame = frame[:ip_off + 10] + b"\x00\x00" + frame[ip_off + 12:]
    csum = pkt.ipv4_checksum(frame[ip_off:ip_off + ihl])
    frame = frame[:ip_off + 10] + struct.pack(">H", csum) + frame[ip_off + 12:]

    udp_len = len(frame) - udp_off
    frame = frame[:udp_off + 4] + struct.pack(">H", udp_len) + frame[udp_off + 6:]
    return frame


# ===========================================================================
# Formatting
# ===========================================================================
def safe_int(handle):
    try:
        return int(handle.value)
    except (ValueError, TypeError):
        return None


def read_op(handle):
    """t_book_op as an index. NVC may give the ordinal or the literal name."""
    v = handle.value
    try:
        return int(v)
    except (ValueError, TypeError):
        name = str(v).strip().upper()
        return OP_NAMES.index(name) if name in OP_NAMES else None


def fmt(v):
    return "?" if v is None else str(v)


def fmt_op(i):
    return "????" if i is None or i >= len(OP_SHORT) else OP_SHORT[i]


def fmt_type(t):
    if t is None:
        return "??"
    n = bm.TYPE_NAME.get(t)
    return f"{n}(0x{t:02X})" if n else f"0x{t:02X}"


def fmt_side(s):
    return "?" if s is None else ("BUY" if s == BUY else "SELL")


def fmt_key(key):
    if key is None:
        return f"{'....':>17} =0x{'?' * KEY_HEX}"
    oid, side = split_key(key)
    return (f"{oid >> 32:08X}:{oid & 0xFFFFFFFF:08X}"
            f"{'B' if side == BUY else 'S'} =0x{key:0{KEY_HEX}X}")


def fmt_key_short(key):
    if key is None:
        return "?" * CELL_W
    oid, side = split_key(key)
    return f"{oid & 0xFFFF:04X}{'B' if side == BUY else 'S'}"


def fmt_value(v):
    d = split_value(v)
    if d is None:
        return "?"
    return (f"qty={d['qty']} px={d['price']} undisc={d['undisc']} "
            f"implied={d['implied']}")


def fmt_cell(slot):
    if slot is None:
        return "?" * CELL_W
    return (fmt_key_short(slot_key(slot)) if (slot >> VALID_BIT) & 1
            else "." * CELL_W)


def fmt_qcell(slot):
    if slot is None:
        return "?" * QCELL_W
    if not ((slot >> VALID_BIT) & 1):
        return "." * QCELL_W
    d = split_value(slot_val(slot))
    return f"{d['qty']:>{QCELL_W}d}" if d else "?" * QCELL_W


def fmt_level(v, width=LVL_FIELD_W):
    d = split_level(v)
    if d is None:
        return "?".ljust(width)
    return f"side={d['side']} qty={d['qty']} px={d['price']}".ljust(width)


# ===========================================================================
# Reaching the memories
# ===========================================================================
def _reach(parent, gen_label, index, what):
    attempts = []
    try:
        return getattr(parent, gen_label)[index].u_ram.ram
    except Exception as e:                     # noqa: BLE001
        attempts.append(f"{gen_label}[{index}] -> {e}")
    for name in (f"{gen_label}({index})", f"{gen_label}[{index}]",
                 f"{gen_label}_{index}"):
        try:
            return getattr(parent, name).u_ram.ram
        except Exception as e:                 # noqa: BLE001
            attempts.append(f"{name} -> {e}")
    raise AssertionError(
        f"Could not reach the {what} RAM through the hierarchy.\nTried:\n  "
        + "\n  ".join(attempts) +
        "\n\nCheck the instance names in market_data_top.vhd, "
        "order_book_engine_top.vhd, ram_array.vhd and level_array.vhd.")


class LevelShadow:
    """
    A copy of the level memory built from what the design writes.

    NVC's VHPI will not hand out element constraints for the level RAMs -
    16384 x 65 bits per side is stored in a form it cannot index, and a read
    raises "Unable to obtain constraints for an indexable object". The
    16 x 132 bit order tables are small enough to read directly.

    level_array IS STILL THE DESIGN. The RTL memory is what price_storage
    reads back through lvl_rdata and what every aggregation decision is made
    from. This mirrors the write port so the contents can be printed. If the
    two disagreed it would show as price_storage computing from a value the
    log says is not there.
    """

    def __init__(self):
        self.reset()

    def reset(self):
        self.mem = [{} for _ in range(NUM_SIDES)]
        self.writes = 0
        self.rejected = 0

    def write(self, wsel, waddr, wdata):
        if (wsel is None or waddr is None or wdata is None
                or not 0 <= wsel < NUM_SIDES or not 0 <= waddr < LVL_DEPTH):
            self.rejected += 1
            return False
        self.mem[wsel][waddr] = wdata
        self.writes += 1
        return True

    def read(self, side, addr):
        return self.mem[side].get(addr, 0)

    def touched(self):
        s = set()
        for side in self.mem:
            s.update(side.keys())
        return s


class Harness:
    """Handles, shadow and watch window for one test."""

    def __init__(self, dut):
        self.dut = dut
        self.rams = None
        self.lvls = None
        self.shadow = LevelShadow()
        self.watch = set()
        self.cycle = 0

    async def start(self):
        dut = self.dut

        cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

        dut.resetn.value = 0
        dut.s_axis_tdata.value = 0
        dut.s_axis_tkeep.value = 0
        dut.s_axis_tvalid.value = 0
        dut.s_axis_tlast.value = 0
        dut.m_axis_tready.value = 1        # ignored by the parser
        dut.base_price.value = 0
        dut.m_tready.value = 1

        reset_seq()
        for _ in range(5):
            await RisingEdge(dut.clk)
        dut.resetn.value = 1
        await RisingEdge(dut.clk)

        # NOTE: reset clears the logic, not the memories. Neither ram_sdp nor
        # level_array resets its array - real block RAM has no reset on its
        # contents. A test that resets mid-run will see stale slots.

        self.rams = [_reach(dut.u_engine.u_ram_array, "g_tables", t, "order")
                     for t in range(NUM_TABLES)]
        self.lvls = self._level_handles()

    def _level_handles(self):
        dut = self.dut
        try:
            rams = [_reach(dut.u_engine.u_level_array, "g_sides", s, "level")
                    for s in range(NUM_SIDES)]
            _ = int(rams[0][0].value)
            dut._log.info("level memory: reading level_array directly")
            return rams
        except Exception as e:                 # noqa: BLE001
            dut._log.info(
                "level memory: cannot index level_array through VHPI (%s)", e)
            dut._log.info(
                "              printing a shadow of the write bus instead; "
                "the RTL memory is")
            dut._log.info(
                "              still the design and still what "
                "price_storage reads back.")
            return None

    @property
    def level_source(self):
        return ("level_array" if self.lvls is not None
                else "shadow of the write bus")

    def note(self, addr):
        if addr is not None and 0 <= addr < LVL_DEPTH:
            self.watch.update(range(max(0, addr - WATCH_SPAN),
                                    min(LVL_DEPTH - 1, addr + WATCH_SPAN) + 1))

    def expect(self, price):
        """Add the level a price maps to, so a dump shows it even if unwritten."""
        self.note(px_index(price))

    def read_tables(self):
        return [[safe_int(self.rams[t][a]) for a in range(DEPTH)]
                for t in range(NUM_TABLES)]

    def read_levels(self):
        wanted = self.watch | self.shadow.touched()
        out = {}
        for a in sorted(wanted):
            if not 0 <= a < LVL_DEPTH:
                continue
            if self.lvls is not None:
                out[a] = [safe_int(self.lvls[s][a]) for s in range(NUM_SIDES)]
            else:
                out[a] = [self.shadow.read(s, a) for s in range(NUM_SIDES)]
        return out


# ===========================================================================
# Dumps
# ===========================================================================
def dump_orders(log, tables, label="    ORDER TABLES"):
    """
    The four order tables, twice - once as keys, once as quantities.

    One log call with embedded newlines rather than one per row: cocotb
    prefixes each record with ~50 columns of timestamp and logger name, and
    paying that once keeps the rows from wrapping.
    """
    lines = [label, "      keys",
             "         " + " ".join(f"{a:>{CELL_W}d}" for a in range(DEPTH))]
    for t in range(NUM_TABLES):
        lines.append(f"      T{t} " + " ".join(fmt_cell(tables[t][a])
                                               for a in range(DEPTH)))
    lines.append("      quantities")
    lines.append("         " + " ".join(f"{a:>{QCELL_W}d}"
                                        for a in range(DEPTH)))
    for t in range(NUM_TABLES):
        lines.append(f"      T{t} " + " ".join(fmt_qcell(tables[t][a])
                                               for a in range(DEPTH)))
    n = sum(1 for t in range(NUM_TABLES) for s in tables[t]
            if s is not None and (s >> VALID_BIT) & 1)
    lines.append(f"      occupancy {n}/{CAPACITY}")
    log.info("%s", "\n".join(lines))


def dump_levels(log, levels, source):
    """
    The level memory, for the watched window.

    The price each index maps to is printed from the Python band map, so a
    slot whose stored price disagrees with its index is visible at a glance -
    that is what an off-tick or out-of-range price looks like.
    """
    lines = [f"    LEVEL MEMORY ({source})"]
    if not levels:
        lines.append("      no level index touched yet")
    else:
        lines.append(f"      {'index':>6} {'maps to':>8}  "
                     f"{'side 0 (buy)':<{LVL_FIELD_W}}  "
                     f"{'side 1 (sell)':<{LVL_FIELD_W}}")
        for a, both in levels.items():
            px = "-"
            for b in BAND_MAP:
                if b["base"] <= a < b["base"] + b["n"]:
                    px = str(b["lo"] + (a - b["base"]) * b["tick"])
                    break
            lines.append(f"      {a:>6} {px:>8}  {fmt_level(both[0])}  "
                         f"{fmt_level(both[1])}")
    log.info("%s", "\n".join(lines))


def dump_pls(log, dut):
    """price_storage's bus and outputs, exactly as they stand."""
    e = dut.u_engine
    ps = e.u_price_storage
    lines = [
        "    PRICE STORAGE",
        f"      mutation in : tvalid={fmt(safe_int(e.mut_tvalid))} "
        f"tready={fmt(safe_int(e.mut_tready))} "
        f"op={fmt_op(read_op(e.mut_op))} side={fmt(safe_int(e.mut_side))}",
        f"                    qty={fmt(safe_int(e.mut_qty))} "
        f"price={fmt(safe_int(e.mut_price))}",
        f"      internal    : inserting={fmt(safe_int(ps.inserting))} "
        f"double={fmt(safe_int(ps.double))} index={fmt(safe_int(ps.index))}",
        f"                    lvl_r={fmt_level(safe_int(ps.lvl_r))}",
        f"      level write : we={fmt(safe_int(e.lvl_we))} "
        f"wsel={fmt(safe_int(e.lvl_wsel))} waddr={fmt(safe_int(e.lvl_waddr))}",
        f"                    wdata={fmt_level(safe_int(e.lvl_wdata))}",
        f"      level read  : raddr={fmt(safe_int(e.lvl_raddr))}",
    ]
    for s in range(NUM_SIDES):
        lines.append(f"                    rdata[{s}]="
                     f"{fmt_level(safe_int(e.lvl_rdata[s]))}")
    lines += [
        f"      handshake   : s_tready={fmt(safe_int(ps.s_tready))} "
        f"busy={fmt(safe_int(dut.level_busy))} oor={fmt(safe_int(dut.oor))}",
        f"      top of book : tvalid={fmt(safe_int(dut.m_tvalid))} "
        f"valid={fmt(safe_int(dut.m_valid))}",
        f"                    bid px={fmt(safe_int(dut.m_bid_price))} "
        f"qty={fmt(safe_int(dut.m_bid_qty))}",
        f"                    ask px={fmt(safe_int(dut.m_ask_price))} "
        f"qty={fmt(safe_int(dut.m_ask_qty))}",
        f"      status      : fifo_full={fmt(safe_int(dut.fifo_full))} "
        f"fifo_overflow={fmt(safe_int(dut.fifo_overflow))} "
        f"bad_side={fmt(safe_int(dut.stat_bad_side))} "
        f"qty_ovf={fmt(safe_int(dut.stat_qty_ovf))}",
    ]
    log.info("%s", "\n".join(lines))


async def dump_all(h, label=None):
    """Both memories and the price_storage state, at a quiet point."""
    await FallingEdge(h.dut.clk)
    await ReadOnly()
    tables = h.read_tables()
    levels = h.read_levels()
    if label:
        h.log.info("    %s", label)
    dump_orders(h.dut._log, tables)
    dump_levels(h.dut._log, levels, h.level_source)
    dump_pls(h.dut._log, h.dut)
    await RisingEdge(h.dut.clk)
    return tables, levels


# ===========================================================================
# Tracing and driving
# ===========================================================================
class Obs:
    """What one run of the driver saw."""

    def __init__(self):
        self.msgs = []      # (cycle, type)   reached the engine slave port
        self.cmds = []      # (cycle, op, order_id, side, qty, price)
        self.muts = []      # (cycle, op, side, qty, price)
        self.owrites = []   # (cycle, table, addr, key, value, valid)
        self.lwrites = []   # (cycle, wsel, waddr, wdata)


def trace(h, obs, quiet=True):
    """
    Sample the buses for the current cycle.

    Called from ReadOnly after a FallingEdge, so values are the ones in
    effect during this cycle - what the memories act on at the next rising
    edge. Sampling after RisingEdge would show registers already updated for
    the following cycle.
    """
    dut = h.dut
    e = dut.u_engine
    c = h.cycle

    mvalid = safe_int(dut.msg_valid_i)
    mtype = safe_int(dut.msg_type_i)
    gated = safe_int(dut.eng_valid)

    cmd_v = safe_int(e.in_tvalid)
    cmd_op = read_op(e.in_op)

    we = safe_int(e.ram_we)
    wsel = safe_int(e.ram_wsel)
    waddr = safe_int(e.ram_waddr)
    wdata = safe_int(e.ram_wdata)

    ev_v = safe_int(e.mut_tvalid)
    ev_op = read_op(e.mut_op)

    lwe = safe_int(e.lvl_we)
    lwaddr = safe_int(e.lvl_waddr)
    lraddr = safe_int(e.lvl_raddr)

    # The printed window follows the design: whatever index it touches, plus
    # neighbours, gets shown.
    h.note(lwaddr)
    h.note(lraddr)

    wr = "-"
    if we == 1 and None not in (wdata, wsel, waddr):
        vbit = (wdata >> VALID_BIT) & 1
        wr = (f"T{wsel}[{waddr:2d}]<={'V' if vbit else 'x'} "
              f"0x{slot_key(wdata):0{KEY_HEX}X}")
        obs.owrites.append((c, wsel, waddr, slot_key(wdata),
                            slot_val(wdata), vbit))

    lw = "-"
    if lwe == 1:
        lwdata = safe_int(e.lvl_wdata)
        lwsel = safe_int(e.lvl_wsel)
        lw = f"S{fmt(lwsel)}[{fmt(lwaddr)}]<= {fmt_level(lwdata)}"
        obs.lwrites.append((c, lwsel, lwaddr, lwdata))
        # lvl_we is high during this cycle, so the write commits at the edge
        # ending it. Applying here keeps the shadow in step, not a cycle
        # ahead.
        if not h.shadow.write(lwsel, lwaddr, lwdata):
            lw += "  [shadow REJECTED]"

    if ev_v == 1:
        obs.muts.append((c, ev_op, safe_int(e.mut_side), safe_int(e.mut_qty),
                         safe_int(e.mut_price)))

    if cmd_v == 1:
        obs.cmds.append((c, cmd_op, safe_int(e.in_order_id),
                         safe_int(e.in_side), safe_int(e.in_qty),
                         safe_int(e.in_price)))

    if mvalid == 1 and gated == 1:
        obs.msgs.append((c, mtype))

    if (mvalid == 1 or cmd_v == 1 or we == 1 or ev_v == 1 or lwe == 1
            or not quiet):
        dut._log.info(
            "cyc %3d | msg=%s%s gate=%s | cmd=%s %s | order %s | mut=%s %s "
            "| lvl raddr=%s write %s",
            c, fmt(mvalid), f" {fmt_type(mtype)}" if mvalid == 1 else "",
            fmt(gated), fmt(cmd_v), fmt_op(cmd_op) if cmd_v == 1 else "",
            wr, fmt(ev_v), fmt_op(ev_op) if ev_v == 1 else "",
            fmt(lraddr), lw)


async def _drive(dut, frames, gap):
    """Clock frames in, 8 bytes per beat, with gap idle cycles between."""
    for n, frame in enumerate(frames):
        if n and gap:
            dut.s_axis_tvalid.value = 0
            for _ in range(gap):
                await RisingEdge(dut.clk)
        for tdata, tkeep, tlast in pkt.to_beats(frame):
            dut.s_axis_tdata.value = tdata
            dut.s_axis_tkeep.value = tkeep
            dut.s_axis_tvalid.value = 1
            dut.s_axis_tlast.value = 1 if tlast else 0
            await RisingEdge(dut.clk)
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0


async def run(h, frames, gap=0, drain=DRAIN_CYCLES):
    """
    Drive frames and watch the chain until it goes quiet.

    gap = 0 means the next frame's first beat follows the previous frame's
    tlast with no idle cycle, which is the back-to-back case.

    There is no handshake to wait on - the command bus is a one-cycle pulse
    and price_storage takes no back-pressure - so completion is a fixed drain
    rather than a quiet-window search.
    """
    if isinstance(frames, (bytes, bytearray)):
        frames = [frames]
    obs = Obs()

    async def sample():
        await FallingEdge(h.dut.clk)
        await ReadOnly()
        trace(h, obs)
        await RisingEdge(h.dut.clk)
        h.cycle += 1

    driver = cocotb.start_soon(_drive(h.dut, frames, gap))
    while not driver.done():
        await sample()
    for _ in range(drain):
        await sample()
    return obs


def report(h, obs, expect_msgs=None):
    """Summarise what the run saw, before the memory dumps."""
    log = h.dut._log

    log.info("    parser out  : %d message(s) through the status gate%s",
             len(obs.msgs),
             "" if expect_msgs is None else f"  (sent {expect_msgs})")
    for c, t in obs.msgs:
        log.info("                  @cyc %d  %s", c, fmt_type(t))

    if obs.cmds:
        for c, op, oid, side, qty, px in obs.cmds:
            log.info("    command out : @cyc %d  op=%s side=%s qty=%s px=%s",
                     c, fmt_op(op), fmt_side(side), fmt(qty),
                     fmt(None if px is None else to_signed32(px)))
            log.info("                  order id 0x%016X", oid or 0)
    else:
        log.info("    command out : none")

    if obs.muts:
        for c, op, side, qty, px in obs.muts:
            log.info("    mutation    : @cyc %d  op=%s side=%s qty=%s px=%s",
                     c, fmt_op(op), fmt_side(side), fmt(qty),
                     fmt(None if px is None else to_signed32(px)))
    else:
        log.info("    mutation    : none emitted")

    if obs.owrites:
        for n, (c, t, a, k, v, vb) in enumerate(obs.owrites):
            log.info("    order write %d @cyc %d: T%d[%d] valid=%d key=%s",
                     n, c, t, a, vb, fmt_key(k))
            log.info("                             value %s", fmt_value(v))
    else:
        log.info("    order write : none")

    if obs.lwrites:
        for n, (c, s, a, d) in enumerate(obs.lwrites):
            log.info("    level write %d @cyc %d: side %s [%s] <= %s",
                     n, c, fmt(s), fmt(a), fmt_level(d))
    else:
        log.info("    level write : nothing on the bus (lvl_we stayed low)")


def banner(dut, text, rule="-"):
    blank(dut)
    dut._log.info(rule * 100)
    dut._log.info("%s", text)
    dut._log.info(rule * 100)


def header(h, title, lines=()):
    dut = h.dut
    dut._log.info("=" * 100)
    dut._log.info("%s", title)
    dut._log.info("=" * 100)
    dut._log.info("order table : %d x %d = %d slots, slot %d bits",
                  NUM_TABLES, DEPTH, CAPACITY, SLOT_W)
    dut._log.info("level table : %d sides x %d slots, %d addr bits, "
                  "%d reachable via px_index",
                  NUM_SIDES, LVL_DEPTH, LVL_ADDR_W, N_LEVELS)
    dut._log.info("level source: %s", h.level_source)
    dut._log.info("book id     : %d   in scope: A U E D   dropped: F C",
                  BOOK_ID)
    for ln in lines:
        dut._log.info("%s", ln)
    dut._log.info("this harness checks nothing - read the dumps")
    dut._log.info("=" * 100)
