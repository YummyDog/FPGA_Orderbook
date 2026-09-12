"""
cocotb testbench for market_data_top - the whole chain, driven by real frames.

    Ethernet -> IPv4 -> UDP -> MoldUDP64 -> ITCH -> book_input_stage
                -> order_fifo -> order_book -> price_storage
                                     |              |
                                 ram_array     level_array

A VISIBILITY HARNESS, same as test_book_PLS. It drives traffic and prints
state. It does not check anything, model anything, or decide whether the
design is correct - there are no assertions, no expected values and no
pass/fail verdict beyond "the run completed". Reading the dumps is the
verification step, and that is yours.


WHAT IS DIFFERENT FROM test_book_PLS

Nothing is driven onto the command bus. Every order reaching the table got
there as bytes on a wire: an ITCH message inside a MoldUDP64 packet inside
UDP inside IPv4 inside an Ethernet frame, built by asx_packets and
book_model, sliced into 64-bit beats and clocked into s_axis_tdata. The
command bus, the mutation bus and both memories are observed, never driven.

BOTH MEMORIES ARE REAL RTL. level_array is in the build. The order tables are
read out of the design through the hierarchy; the level tables are too when
the simulator allows it, and from a shadow of the write bus when it does not
(see LevelShadow). There is no Python model of either memory's behaviour.


WHAT CHANGED SINCE THE LAST VERSION

itch_parser now owns framing and field extraction, and book_input_stage takes
msg_fields directly. So the repack-and-serialise adapter in market_data_top
is gone, and with it eng_tvalid, eng_tlast, beat_r and msg_dropped. The chain
between msg_valid and the command pulse is now one register stage.

F and C are OUT OF SCOPE in the new book_input_stage - f_is_scoped accepts
only A, U, E and D. itch_parser still decodes F and C, so they arrive at the
engine and are dropped there. The stimulus uses A/U/E/D throughout, and one
phase sends an F and a C specifically to show them being dropped.

Two new status outputs are surfaced: stat_bad_side and stat_qty_ovf.


THE TRAFFIC

Same shape as test_book_PLS so the two logs read alike:

    side   = 1  (sell)  on every message
    price  = 50000      on every message
    qty    varies       100, 200, 300 ... 3200

so the only thing that distinguishes one order from another is its ID and
its quantity. Everything lands in a single price level, which is the case
that exercises the level table hardest: consecutive mutations at one index,
back to back, through the forwarding path price_storage uses to dodge an SDP
address collision.


THE LEVEL WRITE PATH

price_storage writes two cycles after every accepted transfer:

    cycle N     s_tvalid high. side/price/qty/op and the index are latched,
                inserting goes high. lvl_raddr is combinational off s_price,
                so the level read is already in flight.
    cycle N+1   lvl_rdata is back. lvl_we, lvl_waddr, lvl_wsel and lvl_wdata
                are registered from it.
    cycle N+2   the write is on the bus and lands in level_array.

The exception is a REPLACE, which order_book emits as a delete then an add
on consecutive cycles. Two back-to-back transfers at the same price and side
take the forwarding branch instead: the first result is held in lvl_r rather
than written, the second is computed from it, and one write covers both.
Watch for double=1 in the trace when a replace goes through.


WHAT GETS PRINTED, PER MESSAGE

    1. the message, as ITCH bytes and as the frame carrying it
    2. the cycle-by-cycle trace while the packet drains
    3. the command pulse out of book_input_stage
    4. any mutation that came out of order_book on m_*
    5. every write seen on either write port
    6. the four order hash tables, as keys and again as quantities
    7. the level memory around whatever index the design touched, both sides
    8. the price_storage bus and output state

Verbose by design - a hundred-odd lines per message across 44 messages.
Redirect it:

    powershell -ExecutionPolicy Bypass -File .\\market_data_sim.ps1 *> run.log


ELABORATION IS SLOW

level_array is 2 x 16384 x 65 bits and ram_sdp's simulation initialiser walks
it element by element at elaboration. Expect a long pause before the first
line. -Waves makes it worse: --dump-arrays has both level tables to dump as
well as the order tables.

Simulator: NVC. VHDL-2008. cocotb 2.x.
"""

import struct

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly

import asx_packets as pkt
import book_model as bm

CLK_PERIOD_NS = 6.21         # 161 MHz, matching the synthesis constraint

# ===========================================================================
# CONFIGURATION - the stimulus
# ===========================================================================

# Every message carries these. 1 = sell.
#
# 50000 price units. At C_PX_PER_CENT = 10 that is 5000 cents, $50.00, which
# sits in the top band where the tick is 10 units - so the price is on-tick
# and in range. With px_legal gone nothing checks that, so a price outside
# the bands would silently aggregate into level 0 instead of being rejected.
SIDE = 1
SIDE_BYTE = bm.SIDE_SELL if SIDE else bm.SIDE_BUY
PRICE = 50000

BOOK_ID = bm.DEFAULT_BOOK_ID          # 85603, must match G_ORDER_BOOK_ID


def add_qty(i: int) -> int:
    """Quantity of added order i."""
    return 100 * (i + 1)                # 100, 200, 300 ... 3200


def replace_qty(i: int, old: int) -> int:
    """Quantity a replace rewrites order i to."""
    return old * 2


def exec_qty(i: int, old: int, full: bool) -> int:
    """Quantity an execution takes off order i."""
    return old if full else old // 4


# Which added orders each phase acts on, by index.
DELETE_IDX = [5, 17, 30]
REPLACE_IDX = [1, 14, 22]
EXEC_PARTIAL_IDX = [7, 19, 25]
EXEC_FULL_IDX = [9]

# Which level indices get printed after every message.
#
# Nothing is hardcoded and nothing is computed from the price. The window
# FOLLOWS THE DESIGN: whatever index turns up on lvl_raddr or lvl_waddr gets
# added, along with WATCH_SPAN neighbours either side. That way the dump
# cannot go stale when PRICE changes, and cannot quietly miss the level if
# the price maps somewhere other than expected.
WATCH_SEED = set()
WATCH_SPAN = 3

WATCH_LEVELS = set(WATCH_SEED)

# ---------------------------------------------------------------------------
# Order table geometry - must match ram_pkg
# ---------------------------------------------------------------------------
NUM_TABLES = 4
ADDR_W = 4
DEPTH = 2 ** ADDR_W
ORDER_ID_W = 64
KEY_W = ORDER_ID_W + 1
VAL_W = 66
SLOT_W = 1 + KEY_W + VAL_W
VALID_BIT = SLOT_W - 1
KEY_MASK = (1 << KEY_W) - 1
VAL_MASK = (1 << VAL_W) - 1
CAPACITY = NUM_TABLES * DEPTH

KEY_HEX = (KEY_W + 3) // 4

CELL_W = 5          # "E5EDS" - low 16 bits of the order ID plus B/S
QCELL_W = 6         # quantity cell

# ---------------------------------------------------------------------------
# Level table geometry - must match level_pkg
#
# t_level is side(1) & qty(32) & price(32), so the side is the top bit and
# the price is the bottom 32.
# ---------------------------------------------------------------------------
NUM_SIDES = 2
LVL_ADDR_W = 14
LVL_DEPTH = 2 ** LVL_ADDR_W
LVL_SIDE_W = 1
LVL_QTY_W = 32
LVL_PRICE_W = 32
LEVEL_W = LVL_SIDE_W + LVL_QTY_W + LVL_PRICE_W

LVL_SIDE_BIT = LEVEL_W - 1
LVL_QTY_LO = LVL_PRICE_W
LVL_FIELD_W = 34    # column width for a formatted level slot

# ---------------------------------------------------------------------------
# t_book_op - ordinals must match the declaration order in ram_pkg
# ---------------------------------------------------------------------------
OP_NAMES = ("OP_ADD", "OP_EXEC", "OP_REPLACE", "OP_DELETE")
OP_SHORT = ("ADD", "EXEC", "REPL", "DEL")

OP_ADD = OP_NAMES.index("OP_ADD")
OP_EXEC = OP_NAMES.index("OP_EXEC")
OP_REPLACE = OP_NAMES.index("OP_REPLACE")
OP_DELETE = OP_NAMES.index("OP_DELETE")

# ---------------------------------------------------------------------------
# Message types the engine accepts.
#
# book_input_stage.f_is_scoped takes A, U, E and D only. itch_parser still
# decodes F and C, so those reach the engine and are dropped there rather
# than never arriving.
# ---------------------------------------------------------------------------
IN_SCOPE = (bm.T_ADD, bm.T_REPLACE, bm.T_EXEC, bm.T_DELETE)
OUT_OF_SCOPE = (bm.T_ADD_PID, bm.T_EXEC_PRICE)

# ---------------------------------------------------------------------------
# Order IDs - ASX shaped, fixed session prefix and an incrementing sequence
# ---------------------------------------------------------------------------
SESSION_PREFIX = 0x621F1282
FIRST_SEQ = 0x0000E5ED

N_INSERT = CAPACITY // 2             # 32 orders

# How long to let a packet work through the whole chain before dumping.
#
# Shorter than it needed to be with the adapter in place - five parser
# stages, then a single register in book_input_stage, the FIFO, the cuckoo
# insert and two more cycles for the level write - but kept generous because
# an eviction chain has no fixed length.
DRAIN_CYCLES = 60


def make_order_id(n: int) -> int:
    return (SESSION_PREFIX << 32) | ((FIRST_SEQ + n) & 0xFFFFFFFF)


def make_key(order_id: int, side: int) -> int:
    """Matches the RTL:  key <= s_order_id & s_side.  Side is bit 0."""
    return ((order_id & ((1 << ORDER_ID_W) - 1)) << 1) | (side & 1)


def split_key(key: int):
    return (key >> 1) & ((1 << ORDER_ID_W) - 1), key & 1


def to_signed32(v: int) -> int:
    return v - (1 << 32) if v & 0x80000000 else v


def split_value(v):
    """Matches the RTL:  value <= s_qty & s_price & s_undisc & s_implied."""
    if v is None:
        return None
    return {
        "qty": (v >> 34) & 0xFFFFFFFF,
        "price": to_signed32((v >> 2) & 0xFFFFFFFF),
        "undisc": (v >> 1) & 1,
        "implied": v & 1,
    }


def slot_key(slot):
    return None if slot is None else (slot >> VAL_W) & KEY_MASK


def slot_val(slot):
    return None if slot is None else slot & VAL_MASK


# The traffic. Every order on the same side at the same price; only the ID
# and the quantity move.
INSERTS = [
    (make_order_id(i), SIDE, add_qty(i), PRICE)
    for i in range(N_INSERT)
]


# ===========================================================================
# Frame building
#
# asx_packets.build_frame carries exactly one ITCH message per packet, which
# is what the per-message dump wants. build_multi below packs several into
# one MoldUDP64 block for the burst case, reusing asx_packets for every
# header below Mold.
# ===========================================================================
_seqnum = [1]


def next_seq(n: int = 1) -> int:
    s = _seqnum[0]
    _seqnum[0] += n
    return s


def frame_for(msg: bytes, **kw) -> bytes:
    """One ITCH message in one packet, with the next Mold sequence number."""
    return pkt.build_frame(itch_msg=msg, mold_seqnum=next_seq(),
                           mold_msg_count=1, **kw)


def build_multi(msgs, **kw) -> bytes:
    """
    Several ITCH messages in one MoldUDP64 packet.

    asx_packets.build_frame writes a single length-prefixed block, so the
    Mold payload is assembled here and handed to it as one opaque body with
    the count and the first length corrected. Everything below Mold - UDP
    length, IPv4 total length and checksum, Ethernet - still comes from
    asx_packets.
    """
    body = b"".join(struct.pack(">H", len(m)) + m for m in msgs)

    # build_frame emits: session + seq + count + len(itch_msg) + itch_msg.
    # Hand it the first message so that first length field is right, then
    # splice the remaining blocks on and fix the count.
    first, rest = msgs[0], body[2 + len(msgs[0]):]
    frame = pkt.build_frame(itch_msg=first, mold_seqnum=next_seq(len(msgs)),
                            mold_msg_count=len(msgs), **kw)
    frame += rest

    # Lengths below Mold have to grow with the spliced tail.
    eth_len = 14 if frame[12:14] != struct.pack(">H", pkt.TPID_8021Q) else 18
    ihl = (frame[eth_len] & 0x0F) * 4
    ip_off = eth_len
    udp_off = ip_off + ihl

    ip_total = ihl + (len(frame) - udp_off)
    frame = (frame[:ip_off + 2] + struct.pack(">H", ip_total)
             + frame[ip_off + 4:])
    frame = (frame[:ip_off + 10] + b"\x00\x00" + frame[ip_off + 12:])
    csum = pkt.ipv4_checksum(frame[ip_off:ip_off + ihl])
    frame = (frame[:ip_off + 10] + struct.pack(">H", csum)
             + frame[ip_off + 12:])

    udp_len = len(frame) - udp_off
    frame = (frame[:udp_off + 4] + struct.pack(">H", udp_len)
             + frame[udp_off + 6:])
    return frame


# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------
def safe_int(handle):
    try:
        return int(handle.value)
    except (ValueError, TypeError):
        return None


def read_op(handle):
    """t_book_op as an index into OP_NAMES. NVC may give ordinal or name."""
    v = handle.value
    try:
        return int(v)
    except (ValueError, TypeError):
        name = str(v).strip().upper()
        if name in OP_NAMES:
            return OP_NAMES.index(name)
        return None


def fmt(v):
    return "?" if v is None else str(v)


def fmt_op(idx):
    if idx is None or idx >= len(OP_SHORT):
        return "????"
    return OP_SHORT[idx]


def fmt_type(t):
    if t is None:
        return "??"
    name = bm.TYPE_NAME.get(t)
    return f"{name}(0x{t:02X})" if name else f"0x{t:02X}"


def fmt_key(key):
    if key is None:
        return f"{'....':>17} =0x{'?' * KEY_HEX}"
    oid, side = split_key(key)
    return (f"{oid >> 32:08X}:{oid & 0xFFFFFFFF:08X}"
            f"{'B' if side == 0 else 'S'} =0x{key:0{KEY_HEX}X}")


def fmt_key_short(key):
    if key is None:
        return "?" * CELL_W
    oid, side = split_key(key)
    return f"{oid & 0xFFFF:04X}{'B' if side == 0 else 'S'}"


def fmt_value(v):
    d = split_value(v)
    if d is None:
        return "?"
    return (f"qty={d['qty']} px={d['price']} "
            f"undisc={d['undisc']} implied={d['implied']}")


def fmt_cell(slot):
    """Order table cell, as a key."""
    if slot is None:
        return "?" * CELL_W
    if (slot >> VALID_BIT) & 1:
        return fmt_key_short(slot_key(slot))
    return "." * CELL_W


def fmt_qcell(slot):
    """
    Order table cell, as a quantity.

    With every order at the same side and the same price, quantity is the
    only field that tells one resting order from another, so it gets its own
    grid.
    """
    if slot is None:
        return "?" * QCELL_W
    if not ((slot >> VALID_BIT) & 1):
        return "." * QCELL_W
    d = split_value(slot_val(slot))
    return f"{d['qty']:>{QCELL_W}d}" if d else "?" * QCELL_W


def split_level(v):
    if v is None:
        return None
    return {
        "side": (v >> LVL_SIDE_BIT) & 1,
        "qty": (v >> LVL_QTY_LO) & 0xFFFFFFFF,
        "price": to_signed32(v & 0xFFFFFFFF),
    }


def fmt_level(v, width=LVL_FIELD_W):
    d = split_level(v)
    if d is None:
        return "?".ljust(width)
    s = f"side={d['side']} qty={d['qty']} px={d['price']}"
    return s.ljust(width)


# ---------------------------------------------------------------------------
# Reaching the memories through the hierarchy
# ---------------------------------------------------------------------------
def _reach(parent, gen_label, index, what):
    """One RAM handle out of a generate, however the simulator names it."""
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
        f"Could not reach the {what} RAM contents through the hierarchy.\n"
        "Tried:\n  " + "\n  ".join(attempts) +
        "\n\nRun with NVC's --preserve-case (the runner already does) and "
        "check the instance names in market_data_top.vhd, "
        "order_book_engine_top.vhd, ram_array.vhd and level_array.vhd "
        "match those above."
    )


def find_ram_handles(dut):
    return [_reach(dut.u_engine.u_ram_array, "g_tables", t, "order")
            for t in range(NUM_TABLES)]


class LevelShadow:
    """
    A copy of the level memory, built from what the design writes.

    NVC's VHPI will not hand out element constraints for the level RAMs -
    16384 x 65 bits per side is large enough that they are stored in a form
    it cannot index, and any read raises

        Unable to obtain constraints for an indexable object
        ...U_LEVEL_ARRAY.G_SIDES(0).U_RAM.RAM

    The 16 x 132 bit order tables are small enough to read directly, which is
    why only this one needs a shadow.

    level_array IS STILL THE DESIGN. This is not a model standing in for it:
    the RTL memory is what price_storage reads back through lvl_rdata and
    what every aggregation decision is made from. This only mirrors the write
    port so the contents can be printed. If the two ever disagreed it would
    show up immediately as price_storage computing from a value the log says
    is not there.

    Both sides start at zero, matching ram_sdp's simulation initialiser.
    """

    def __init__(self):
        self.mem = [{} for _ in range(NUM_SIDES)]
        self.writes = 0
        self.dropped = 0

    def reset(self):
        self.mem = [{} for _ in range(NUM_SIDES)]
        self.writes = 0
        self.dropped = 0

    def write(self, wsel, waddr, wdata):
        if wsel is None or waddr is None or wdata is None:
            self.dropped += 1
            return False
        if not (0 <= wsel < NUM_SIDES) or not (0 <= waddr < LVL_DEPTH):
            self.dropped += 1
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


LEVEL_SHADOW = LevelShadow()


def find_level_handles(dut):
    """
    Handles for the level RAMs, or None if VHPI will not index them.

    Probes with a single element read rather than assuming: on a smaller
    C_LVL_MAX_CENT the tables shrink and direct readback starts working
    again, and then the log should come from the RTL rather than the shadow.
    """
    try:
        rams = [_reach(dut.u_engine.u_level_array, "g_sides", s, "level")
                for s in range(NUM_SIDES)]
        _ = int(rams[0][0].value)
        dut._log.info("level memory: reading level_array directly")
        return rams
    except Exception as e:                     # noqa: BLE001
        dut._log.warning(
            "level memory: cannot index level_array through VHPI (%s)", e)
        dut._log.warning(
            "              falling back to a shadow built from lvl_we. The "
            "RTL memory is still")
        dut._log.warning(
            "              the design; only the printed contents come from "
            "the write bus.")
        return None


def level_label(lvls):
    return ("    LEVEL MEMORY (level_array)" if lvls is not None
            else "    LEVEL MEMORY (shadow of the write bus)")


def read_tables(rams):
    return [[safe_int(rams[t][a]) for a in range(DEPTH)]
            for t in range(NUM_TABLES)]


def read_levels(lvls, addrs):
    """
    Only the watched indices - the table is 16384 deep per side.

    From the RTL when VHPI allows it, from the shadow otherwise. Indices the
    design has written are always included, so a level cannot go missing just
    because the watch window drifted.
    """
    wanted = set(addrs) | LEVEL_SHADOW.touched()
    out = {}
    for a in sorted(wanted):
        if not (0 <= a < LVL_DEPTH):
            continue
        if lvls is not None:
            out[a] = [safe_int(lvls[s][a]) for s in range(NUM_SIDES)]
        else:
            out[a] = [LEVEL_SHADOW.read(s, a) for s in range(NUM_SIDES)]
    return out


# ---------------------------------------------------------------------------
# Dumps
# ---------------------------------------------------------------------------
def dump_orders(log, tables, label=""):
    """
    The four order tables, twice - once as keys, once as quantities.

    One log call with embedded newlines rather than one per row: cocotb
    prefixes each record with about 50 columns of timestamp and logger name,
    and paying that once is what keeps the rows from wrapping.
    """
    lines = []
    if label:
        lines.append(label)

    lines.append("      keys")
    lines.append("         " + " ".join(f"{a:>{CELL_W}d}"
                                        for a in range(DEPTH)))
    for t in range(NUM_TABLES):
        lines.append(f"      T{t} " +
                     " ".join(fmt_cell(tables[t][a]) for a in range(DEPTH)))

    lines.append("      quantities")
    lines.append("         " + " ".join(f"{a:>{QCELL_W}d}"
                                        for a in range(DEPTH)))
    for t in range(NUM_TABLES):
        lines.append(f"      T{t} " +
                     " ".join(fmt_qcell(tables[t][a]) for a in range(DEPTH)))

    n = sum(1 for t in range(NUM_TABLES) for s in tables[t]
            if s is not None and (s >> VALID_BIT) & 1)
    lines.append(f"      occupancy {n}/{CAPACITY}")

    log.info("%s", "\n".join(lines))


def dump_levels(log, levels, label=""):
    """
    The level memory.

    Only the watched window is shown. An index the design has never touched
    still appears, as whatever the memory holds, rather than going missing.
    """
    lines = []
    if label:
        lines.append(label)

    if not levels:
        lines.append("      no level index touched yet")
    else:
        lines.append(f"      {'index':>6}  {'side 0':<{LVL_FIELD_W}}  "
                     f"{'side 1':<{LVL_FIELD_W}}")
        for a, both in levels.items():
            lines.append(f"      {a:>6}  {fmt_level(both[0])}  "
                         f"{fmt_level(both[1])}")

    log.info("%s", "\n".join(lines))


def dump_pls(log, dut, label=""):
    """
    The price_storage bus and outputs, exactly as they stand.

    'U' on an output means price_storage is not driving it. Reported as read,
    with no interpretation.
    """
    e = dut.u_engine
    ps = e.u_price_storage

    lines = []
    if label:
        lines.append(label)
    lines.append(f"      mutation in : tvalid={fmt(safe_int(e.mut_tvalid))} "
                 f"tready={fmt(safe_int(e.mut_tready))} "
                 f"op={fmt_op(read_op(e.mut_op))} "
                 f"side={fmt(safe_int(e.mut_side))}")
    lines.append(f"                    qty={fmt(safe_int(e.mut_qty))} "
                 f"price={fmt(safe_int(e.mut_price))}")
    lines.append(f"      internal    : inserting={fmt(safe_int(ps.inserting))} "
                 f"double={fmt(safe_int(ps.double))} "
                 f"index={fmt(safe_int(ps.index))}")
    lines.append(f"                    lvl_r={fmt_level(safe_int(ps.lvl_r))}")
    lines.append(f"      level write : we={fmt(safe_int(e.lvl_we))} "
                 f"wsel={fmt(safe_int(e.lvl_wsel))} "
                 f"waddr={fmt(safe_int(e.lvl_waddr))}")
    lines.append(f"                    "
                 f"wdata={fmt_level(safe_int(e.lvl_wdata))}")
    lines.append(f"      level read  : raddr={fmt(safe_int(e.lvl_raddr))}")
    for s in range(NUM_SIDES):
        lines.append(f"                    rdata[{s}]="
                     f"{fmt_level(safe_int(e.lvl_rdata[s]))}")
    lines.append(f"      handshake   : "
                 f"s_tready={fmt(safe_int(ps.s_tready))} "
                 f"busy={fmt(safe_int(dut.level_busy))} "
                 f"oor={fmt(safe_int(dut.oor))}")
    lines.append(f"      top of book : "
                 f"tvalid={fmt(safe_int(dut.m_tvalid))} "
                 f"valid={fmt(safe_int(dut.m_valid))}")
    lines.append(f"                    bid "
                 f"px={fmt(safe_int(dut.m_bid_price))}"
                 f" qty={fmt(safe_int(dut.m_bid_qty))}")
    lines.append(f"                    ask "
                 f"px={fmt(safe_int(dut.m_ask_price))}"
                 f" qty={fmt(safe_int(dut.m_ask_qty))}")
    log.info("%s", "\n".join(lines))


# ---------------------------------------------------------------------------
# Bus tracing
# ---------------------------------------------------------------------------
def trace(dut, cycle, quiet=True):
    """
    Print the bus state for the current cycle and return what was seen.

    Call from ReadOnly after a FallingEdge, so the values shown are the ones
    in effect during this cycle - what the memories will act on at the next
    rising edge. Sampling after RisingEdge would show the registers already
    updated for the following cycle.

    quiet suppresses the line when nothing at all happened, which is most of
    a packet's beats.
    """
    e = dut.u_engine

    # parser out, and the gate in market_data_top that decides what the
    # engine is allowed to see
    mvalid = safe_int(dut.msg_valid_i)
    mtype = safe_int(dut.msg_type_i)
    gated = safe_int(dut.eng_valid)

    # command pulse out of book_input_stage
    cmd_v = safe_int(e.in_tvalid)
    cmd_op = read_op(e.in_op)

    # order table write port
    we = safe_int(e.ram_we)
    wsel = safe_int(e.ram_wsel)
    waddr = safe_int(e.ram_waddr)
    wdata = safe_int(e.ram_wdata)

    # mutation bus
    ev_v = safe_int(e.mut_tvalid)
    ev_op = read_op(e.mut_op)

    # level write port
    lwe = safe_int(e.lvl_we)
    lwaddr = safe_int(e.lvl_waddr)
    lraddr = safe_int(e.lvl_raddr)

    # Whatever level the design touches gets added to the printed window,
    # with its neighbours, so the surrounding levels are visible too.
    for a in (lwaddr, lraddr):
        if a is not None and 0 <= a < LVL_DEPTH:
            WATCH_LEVELS.update(
                range(max(0, a - WATCH_SPAN),
                      min(LVL_DEPTH - 1, a + WATCH_SPAN) + 1))

    wr = "-"
    order_write = None
    if we == 1 and None not in (wdata, wsel, waddr):
        vbit = (wdata >> VALID_BIT) & 1
        wr = (f"T{wsel}[{waddr:2d}]<={'V' if vbit else 'x'} "
              f"0x{slot_key(wdata):0{KEY_HEX}X}")
        order_write = (cycle, wsel, waddr, slot_key(wdata), slot_val(wdata),
                       vbit)

    lw = "-"
    level_write = None
    if lwe == 1:
        lwdata = safe_int(e.lvl_wdata)
        lwsel = safe_int(e.lvl_wsel)
        lw = f"S{fmt(lwsel)}[{fmt(lwaddr)}]<= {fmt_level(lwdata)}"
        level_write = (cycle, lwsel, lwaddr, lwdata)
        # lvl_we is high during this cycle, so the write commits at the edge
        # that ends it. Applying it here keeps the shadow in step with the
        # memory rather than a cycle ahead of it.
        if not LEVEL_SHADOW.write(lwsel, lwaddr, lwdata):
            lw += "  [shadow REJECTED: unusable address or data]"

    event = None
    if ev_v == 1:
        event = (cycle, ev_op, safe_int(e.mut_side), safe_int(e.mut_qty),
                 safe_int(e.mut_price))

    command = None
    if cmd_v == 1:
        command = (cycle, cmd_op, safe_int(e.in_order_id),
                   safe_int(e.in_side), safe_int(e.in_qty),
                   safe_int(e.in_price))

    # A message the parser decoded but the engine never turned into a
    # command: wrong book, unrecognised side, or a type out of scope.
    dropped = (mvalid == 1 and gated == 1)

    interesting = (mvalid == 1 or cmd_v == 1 or we == 1 or ev_v == 1
                   or lwe == 1)
    if interesting or not quiet:
        dut._log.info(
            "cyc %3d | msg=%s%s gate=%s | cmd=%s %s | order %s | "
            "mut=%s %s | lvl raddr=%s write %s",
            cycle,
            fmt(mvalid),
            f" {fmt_type(mtype)}" if mvalid == 1 else "",
            fmt(gated),
            fmt(cmd_v), fmt_op(cmd_op) if cmd_v == 1 else "",
            wr, fmt(ev_v), fmt_op(ev_op) if ev_v == 1 else "",
            fmt(lraddr), lw,
        )

    return order_write, event, level_write, command, dropped


# ---------------------------------------------------------------------------
# Stimulus driver
# ---------------------------------------------------------------------------
async def drive_frame(dut, frame, gaps=None):
    """Clock one Ethernet frame in, 8 bytes per beat."""
    beats = pkt.to_beats(frame)
    for i, (tdata, tkeep, tlast) in enumerate(beats):
        if gaps and gaps[i]:
            dut.s_axis_tvalid.value = 0
            for _ in range(gaps[i]):
                await RisingEdge(dut.clk)
        dut.s_axis_tdata.value = tdata
        dut.s_axis_tkeep.value = tkeep
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tlast.value = 1 if tlast else 0
        await RisingEdge(dut.clk)
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    return len(beats)


async def run_frame(dut, frame, gaps=None, drain=DRAIN_CYCLES):
    """
    Send one frame and watch the whole chain until it goes quiet.

    There is no handshake to wait on - the command bus is a one-cycle pulse
    and price_storage takes no back-pressure - so completion is a fixed drain
    rather than a quiet-window search. The trace only prints cycles where
    something happened.

    Returns (order_writes, events, level_writes, commands, msgs_seen).
    """
    order_writes = []
    events = []
    level_writes = []
    commands = []
    msgs_seen = []
    cycle = 0

    async def sample():
        nonlocal cycle
        await FallingEdge(dut.clk)
        await ReadOnly()
        w, ev, lw, cm, seen = trace(dut, cycle)
        if w is not None:
            order_writes.append(w)
        if ev is not None:
            events.append(ev)
        if lw is not None:
            level_writes.append(lw)
        if cm is not None:
            commands.append(cm)
        if seen:
            msgs_seen.append((cycle, safe_int(dut.msg_type_i)))
        await RisingEdge(dut.clk)
        cycle += 1

    # Drive and observe concurrently: the frame is long enough that the first
    # messages are already through the chain while later beats are still
    # arriving.
    driver = cocotb.start_soon(drive_frame(dut, frame, gaps))
    while not driver.done():
        await sample()
    for _ in range(drain):
        await sample()

    return order_writes, events, level_writes, commands, msgs_seen


async def message(dut, rams, lvls, banner, msg, order_id, op, qty=0,
                  price=0, frame=None, expect_drop=False):
    """
    Send one ITCH message inside one packet, then dump everything.

    This is the unit the whole file is built around: one message in, one full
    picture of both memories out.
    """
    key = make_key(order_id, SIDE)
    if frame is None:
        frame = frame_for(msg)

    dut._log.info("")
    dut._log.info("-" * 100)
    dut._log.info("%s", banner)
    dut._log.info("    command : op=%s  key=%s  side=%d  qty=%d  price=%d",
                  fmt_op(op), fmt_key(key), SIDE, qty, price)
    dut._log.info("    itch    : type %s, %d bytes  %s",
                  fmt_type(msg[0]), len(msg), msg[:20].hex(" "))
    dut._log.info("    frame   : %d bytes, %d beats  (mold seq %d)",
                  len(frame), (len(frame) + 7) // 8, _seqnum[0] - 1)
    if expect_drop:
        dut._log.info("    NOTE    : out of scope for book_input_stage - "
                      "the parser decodes it, the engine drops it")
    dut._log.info("-" * 100)

    (order_writes, events, level_writes,
     commands, msgs_seen) = await run_frame(dut, frame)

    # ---- what reached the engine's slave port ----------------------------
    for c, t in msgs_seen:
        dut._log.info("    parser out  : @cyc %d  type %s  (passed the "
                      "status gate)", c, fmt_type(t))
    if not msgs_seen:
        dut._log.info("    parser out  : nothing passed the status gate")

    # ---- what book_input_stage emitted -----------------------------------
    if commands:
        for c, cop, coid, cside, cqty, cpx in commands:
            dut._log.info("    command out : @cyc %d  op=%s side=%s qty=%s "
                          "price=%s", c, fmt_op(cop), fmt(cside), fmt(cqty),
                          fmt(None if cpx is None else to_signed32(cpx)))
            dut._log.info("                  order id 0x%016X",
                          coid if coid is not None else 0)
    else:
        dut._log.info("    command out : none - the message never became a "
                      "command")

    dut._log.info("    stat        : bad_side=%s qty_ovf=%s",
                  fmt(safe_int(dut.stat_bad_side)),
                  fmt(safe_int(dut.stat_qty_ovf)))

    # ---- what came out on the mutation bus -------------------------------
    if events:
        for c, eop, es, eq, ep in events:
            dut._log.info("    mutation : @cyc %d  op=%s side=%s qty=%s "
                          "price=%s", c, fmt_op(eop), fmt(es), fmt(eq),
                          fmt(None if ep is None else to_signed32(ep)))
    else:
        dut._log.info("    mutation : none emitted")

    # ---- what hit the order tables ---------------------------------------
    if order_writes:
        for n, (c, t, a, k, v, vbit) in enumerate(order_writes):
            dut._log.info("    order write %d @cyc %d: T%d[%d] valid=%d "
                          "key=%s", n, c, t, a, vbit, fmt_key(k))
            dut._log.info("                             value %s",
                          fmt_value(v))
    else:
        dut._log.info("    order write : none")

    # ---- what hit the level memory ---------------------------------------
    #
    # Two writes for a REPLACE would mean the forwarding branch did not fire.
    # One write covering both halves is the intended behaviour - watch
    # double= in the price_storage dump below.
    if level_writes:
        for n, (c, s, a, d) in enumerate(level_writes):
            dut._log.info("    level write %d @cyc %d: side %s [%s] <= %s",
                          n, c, fmt(s), fmt(a), fmt_level(d))
    else:
        dut._log.info("    level write : nothing on the bus "
                      "(lvl_we stayed low)")

    # ---- the two memories ------------------------------------------------
    await FallingEdge(dut.clk)
    await ReadOnly()
    tables = read_tables(rams)
    levels = read_levels(lvls, WATCH_LEVELS)
    dump_orders(dut._log, tables, "    ORDER TABLES")
    dump_levels(dut._log, levels, level_label(lvls))
    dump_pls(dut._log, dut, "    PRICE STORAGE")
    await RisingEdge(dut.clk)


async def reset(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    dut.resetn.value = 0

    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.m_axis_tready.value = 1        # ignored by the parser

    # Price window and top-of-book consumer.
    dut.base_price.value = 0
    dut.m_tready.value = 1

    LEVEL_SHADOW.reset()
    WATCH_LEVELS.clear()
    WATCH_LEVELS.update(WATCH_SEED)

    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.resetn.value = 1
    await RisingEdge(dut.clk)

    # NOTE: this resets the logic, not the memories. Neither ram_sdp nor
    # level_array resets its array - real block RAM has no reset on its
    # contents, and forcing one would stop the synthesiser inferring a memory
    # at all. The shadow is cleared above to match a fresh elaboration, so
    # after a mid-run reset it and the RTL will disagree about anything
    # written before it.


# ===========================================================================
# The run
# ===========================================================================
@cocotb.test()
async def test_single_level_traffic(dut):
    """
    32 adds, 3 deletes, 3 replaces and 4 executions, all on side 1 at price
    50000 with varying quantities, each delivered as a real ASX frame. Both
    memories are printed after every message.
    """
    await reset(dut)

    rams = find_ram_handles(dut)
    lvls = find_level_handles(dut)

    dut._log.info("=" * 100)
    dut._log.info("toplevel    : market_data_top - parser and engine, no "
                  "adapter between them")
    dut._log.info("order table : %d tables x %d slots = %d capacity, "
                  "slot %d bits", NUM_TABLES, DEPTH, CAPACITY, SLOT_W)
    dut._log.info("level table : %d sides x %d slots, %d addr bits, "
                  "slot %d bits", NUM_SIDES, LVL_DEPTH, LVL_ADDR_W, LEVEL_W)
    dut._log.info("key         : %d bits, order_id(64) & side(1), "
                  "side at bit 0", KEY_W)
    dut._log.info("value       : qty(32) price(32) undisc(1) implied(1)")
    dut._log.info("level slot  : side(%d) qty(%d) price(%d)",
                  LVL_SIDE_W, LVL_QTY_W, LVL_PRICE_W)
    dut._log.info("")
    dut._log.info("delivery    : one ITCH message per MoldUDP64 packet, "
                  "over UDP / IPv4 / Ethernet")
    dut._log.info("              %s -> %s port %d, book id %d",
                  pkt.ASX_SRC_IP_A, pkt.ASX_GRP_IP, pkt.ASX_DST_PORT,
                  BOOK_ID)
    dut._log.info("in scope    : A U E D. F and C are decoded by the parser "
                  "and dropped by")
    dut._log.info("              book_input_stage - see the OUT OF SCOPE "
                  "phase below")
    dut._log.info("stimulus    : side=%d, price=%d on EVERY message; "
                  "only quantity varies", SIDE, PRICE)
    dut._log.info("              %d adds, %d deletes, %d replaces, %d execs "
                  "(%d partial, %d full)",
                  N_INSERT, len(DELETE_IDX), len(REPLACE_IDX),
                  len(EXEC_PARTIAL_IDX) + len(EXEC_FULL_IDX),
                  len(EXEC_PARTIAL_IDX), len(EXEC_FULL_IDX))
    dut._log.info("              add quantities %d .. %d",
                  add_qty(0), add_qty(N_INSERT - 1))
    dut._log.info("")
    dut._log.info("level write : two cycles after each accepted transfer. A "
                  "REPLACE arrives as two")
    dut._log.info("              back-to-back transfers at one price and "
                  "takes the forwarding")
    dut._log.info("              branch instead - one write for both halves, "
                  "with double=1.")
    dut._log.info("")
    dut._log.info("cells       : keys as <low16 of order id><B|S>, "
                  "'.' is an empty slot")
    dut._log.info("              this harness checks nothing - read the dumps")
    dut._log.info("=" * 100)

    # What each order was last known to carry, so a delete, replace or exec
    # banner can say what it is acting on. Bookkeeping for the log only -
    # nothing is ever compared against it.
    qty_now = {}

    # ---- adds ------------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("ADDS")
    dut._log.info("=" * 100)

    for i, (oid, side, qty, price) in enumerate(INSERTS):
        qty_now[i] = qty
        msg = bm.build_add(order_id=oid, book_id=BOOK_ID, side=SIDE_BYTE,
                           qty=qty, price=price, position=i + 1)
        await message(dut, rams, lvls,
                      f"ADD {i + 1}/{N_INSERT}   order index {i}",
                      msg, oid, OP_ADD, qty=qty, price=price)

    # ---- deletes ---------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("DELETES")
    dut._log.info("=" * 100)

    for i in DELETE_IDX:
        oid, side, _, price = INSERTS[i]
        msg = bm.build_delete(order_id=oid, book_id=BOOK_ID, side=SIDE_BYTE)
        await message(dut, rams, lvls,
                      f"DELETE   order index {i}   "
                      f"(was resting {qty_now[i]})",
                      msg, oid, OP_DELETE, qty=0, price=price)
        qty_now[i] = 0

    # ---- replaces --------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("REPLACES   -   these are the ones that exercise the "
                  "forwarding branch")
    dut._log.info("=" * 100)

    for i in REPLACE_IDX:
        oid, side, _, price = INSERTS[i]
        new_qty = replace_qty(i, qty_now[i])
        msg = bm.build_replace(order_id=oid, book_id=BOOK_ID, side=SIDE_BYTE,
                               qty=new_qty, price=price, position=1)
        await message(dut, rams, lvls,
                      f"REPLACE  order index {i}   qty {qty_now[i]} -> "
                      f"{new_qty}, price unchanged at {price}",
                      msg, oid, OP_REPLACE, qty=new_qty, price=price)
        qty_now[i] = new_qty

    # ---- executions ------------------------------------------------------
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("EXECUTIONS")
    dut._log.info("=" * 100)

    for i in EXEC_PARTIAL_IDX + EXEC_FULL_IDX:
        oid, side, _, price = INSERTS[i]
        full = i in EXEC_FULL_IDX
        take = exec_qty(i, qty_now[i], full)
        msg = bm.build_exec(order_id=oid, book_id=BOOK_ID, side=SIDE_BYTE,
                            qty=take)
        await message(dut, rams, lvls,
                      f"EXEC     order index {i}   take {take} of "
                      f"{qty_now[i]}"
                      f"{'   [fills the order]' if full else ''}",
                      msg, oid, OP_EXEC, qty=take, price=price)
        qty_now[i] = max(0, qty_now[i] - take)

    # ---- out of scope ----------------------------------------------------
    #
    # F is an add with a participant id and C is an execution with a trade
    # price. itch_parser decodes both, so msg_valid fires and the fields are
    # populated - but f_is_scoped rejects them, so no command is emitted and
    # neither memory moves. The order tables either side of this phase should
    # be identical.
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("OUT OF SCOPE   -   F and C reach the engine and are "
                  "dropped by book_input_stage")
    dut._log.info("=" * 100)

    oid_f = make_order_id(0xF00)
    await message(dut, rams, lvls,
                  "F        add with participant id - out of scope",
                  bm.build_add(order_id=oid_f, book_id=BOOK_ID,
                               side=SIDE_BYTE, qty=4242, price=PRICE,
                               with_pid=True),
                  oid_f, OP_ADD, qty=4242, price=PRICE, expect_drop=True)

    oid_c = INSERTS[0][0]
    await message(dut, rams, lvls,
                  "C        execution with trade price - out of scope",
                  bm.build_exec(order_id=oid_c, book_id=BOOK_ID,
                                side=SIDE_BYTE, qty=10, trade_price=99999),
                  oid_c, OP_EXEC, qty=10, price=PRICE, expect_drop=True)

    # ---- final state -----------------------------------------------------
    await FallingEdge(dut.clk)
    await ReadOnly()
    tables = read_tables(rams)
    levels = read_levels(lvls, WATCH_LEVELS)
    dut._log.info("")
    dut._log.info("=" * 100)
    dut._log.info("FINAL STATE")
    dut._log.info("=" * 100)
    dump_orders(dut._log, tables, "    ORDER TABLES")
    dump_levels(dut._log, levels, level_label(lvls))
    dump_pls(dut._log, dut, "    PRICE STORAGE")
    await RisingEdge(dut.clk)

    dut._log.info("")
    dut._log.info("  per-table load:")
    for t in range(NUM_TABLES):
        n = sum(1 for s in tables[t]
                if s is not None and (s >> VALID_BIT) & 1)
        dut._log.info("    T%d  %2d/%2d  %s", t, n, DEPTH, "#" * n)
    dut._log.info("")
    dut._log.info("  fifo: full=%s overflow=%s   "
                  "input stage: bad_side=%s qty_ovf=%s",
                  fmt(safe_int(dut.fifo_full)),
                  fmt(safe_int(dut.fifo_overflow)),
                  fmt(safe_int(dut.stat_bad_side)),
                  fmt(safe_int(dut.stat_qty_ovf)))
    dut._log.info("  level writes seen on the bus: %d",
                  LEVEL_SHADOW.writes)
    dut._log.info("=" * 100)


@cocotb.test()
async def test_multi_message_packet(dut):
    """
    Several ITCH messages in ONE MoldUDP64 packet.

    The per-message test gives the chain a whole packet gap between messages.
    This one does not: four messages arrive back to back inside a single
    frame, so the parser retires msg_valid four times in quick succession and
    the input stage and FIFO have to keep up.

    book_input_stage has no buffering - it is one register stage and accepts
    a message every cycle - so the pressure lands on order_fifo. If it is
    going to overflow, it happens here.
    """
    await reset(dut)

    rams = find_ram_handles(dut)
    lvls = find_level_handles(dut)

    base = 0x900
    msgs = [
        bm.build_add(order_id=make_order_id(base + 0), book_id=BOOK_ID,
                     side=SIDE_BYTE, qty=1100, price=PRICE),
        bm.build_add(order_id=make_order_id(base + 1), book_id=BOOK_ID,
                     side=SIDE_BYTE, qty=1200, price=PRICE),
        bm.build_exec(order_id=make_order_id(base + 0), book_id=BOOK_ID,
                      side=SIDE_BYTE, qty=100),
        bm.build_delete(order_id=make_order_id(base + 1), book_id=BOOK_ID,
                        side=SIDE_BYTE),
    ]
    frame = build_multi(msgs)

    dut._log.info("=" * 100)
    dut._log.info("MULTI-MESSAGE PACKET: %d messages, %d bytes, %d beats",
                  len(msgs), len(frame), (len(frame) + 7) // 8)
    for n, m in enumerate(msgs):
        dut._log.info("    msg %d: type %s  %d bytes",
                      n, fmt_type(m[0]), len(m))
    dut._log.info("=" * 100)

    (order_writes, events, level_writes,
     commands, msgs_seen) = await run_frame(dut, frame,
                                            drain=DRAIN_CYCLES * 2)

    dut._log.info("")
    dut._log.info("    messages through the gate : %d of %d",
                  len(msgs_seen), len(msgs))
    for c, t in msgs_seen:
        dut._log.info("        @cyc %d  %s", c, fmt_type(t))
    dut._log.info("    commands out : %d   mutations : %d",
                  len(commands), len(events))
    dut._log.info("    order writes : %d   level writes : %d",
                  len(order_writes), len(level_writes))

    await FallingEdge(dut.clk)
    await ReadOnly()
    tables = read_tables(rams)
    levels = read_levels(lvls, WATCH_LEVELS)
    dump_orders(dut._log, tables, "    ORDER TABLES")
    dump_levels(dut._log, levels, level_label(lvls))
    dump_pls(dut._log, dut, "    PRICE STORAGE")
    dut._log.info("    fifo: full=%s overflow=%s   "
                  "input stage: bad_side=%s qty_ovf=%s",
                  fmt(safe_int(dut.fifo_full)),
                  fmt(safe_int(dut.fifo_overflow)),
                  fmt(safe_int(dut.stat_bad_side)),
                  fmt(safe_int(dut.stat_qty_ovf)))
    await RisingEdge(dut.clk)
