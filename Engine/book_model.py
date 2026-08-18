"""
Reference model for book_input_stage.

Builds raw ASX ITCH messages and predicts the normalised command that
book_input_stage should emit for each, mirroring order_book_pkg.

Message layouts, byte offsets from the start of the ITCH message:

    A (37) / F (44)       U (36)                E (52) / C (58)      D (18)
    ------------------    ------------------    ------------------   ---------
    0     type            0     type            0     type           0    type
    1-4   timestamp       1-4   timestamp       1-4   timestamp      1-4  ts
    5-12  order id        5-12  order id        5-12  order id       5-12 oid
    13-16 book id         13-16 book id         13-16 book id        13-16 bid
    17    side            17    side            17    side           17   side
    18-21 position        18-21 position        18-25 quantity
    22-29 quantity        22-29 quantity        26-37 match id
    30-33 price           30-33 price           38-44 owner
    34-35 exch ord type   34-35 exch ord type   45-51 counterparty
    36    lot type                              52-55 price  (C only)
    37-43 owner (F only)                        56    cross  (C only)
                                                57    print  (C only)

The three semantic rules the model encodes, and the DUT must reproduce:

  * quantity is ABSOLUTE on A/F/U but an executed DELTA on E/C
  * price is the resting price on A/F/U; on C it is the TRADE price and must
    be suppressed (px_valid low), on E there is no price field at all
  * exchange order type exists only on A/F/U, so undisclosed and implied are
    zero everywhere else

No cocotb dependency - importable standalone.
"""

# ---------------------------------------------------------------------------
# Message types
# ---------------------------------------------------------------------------
T_SECONDS = 0x54  # T
T_SYSEVENT = 0x53  # S
T_BOOKDIR = 0x52  # R
T_COMBODIR = 0x4D  # M
T_TICKSIZE = 0x4C  # L
T_BOOKSTATE = 0x4F  # O
T_ADD = 0x41  # A
T_ADD_PID = 0x46  # F
T_EXEC = 0x45  # E
T_EXEC_PRICE = 0x43  # C
T_REPLACE = 0x55  # U
T_DELETE = 0x44  # D
T_TRADE = 0x50  # P
T_EQUILIBRIUM = 0x5A  # Z

BOOK_TYPES = (T_ADD, T_ADD_PID, T_EXEC, T_EXEC_PRICE, T_REPLACE, T_DELETE)

# Every framed type the parser can emit, including the ones the book ignores.
ALL_TYPES = (
    T_SECONDS, T_SYSEVENT, T_BOOKDIR, T_COMBODIR, T_TICKSIZE, T_BOOKSTATE,
    T_ADD, T_ADD_PID, T_EXEC, T_EXEC_PRICE, T_REPLACE, T_DELETE,
    T_TRADE, T_EQUILIBRIUM,
)

SPEC_LEN = {
    T_SECONDS: 5, T_SYSEVENT: 6, T_DELETE: 18, T_TICKSIZE: 25,
    T_BOOKSTATE: 29, T_REPLACE: 36, T_ADD: 37, T_ADD_PID: 44,
    T_TRADE: 50, T_EXEC: 52, T_EQUILIBRIUM: 53, T_EXEC_PRICE: 58,
    T_BOOKDIR: 113, T_COMBODIR: 261,
}

TYPE_NAME = {
    T_SECONDS: "T", T_SYSEVENT: "S", T_BOOKDIR: "R", T_COMBODIR: "M",
    T_TICKSIZE: "L", T_BOOKSTATE: "O", T_ADD: "A", T_ADD_PID: "F",
    T_EXEC: "E", T_EXEC_PRICE: "C", T_REPLACE: "U", T_DELETE: "D",
    T_TRADE: "P", T_EQUILIBRIUM: "Z",
}

# ---------------------------------------------------------------------------
# Side bytes
# ---------------------------------------------------------------------------
SIDE_BUY = 0x42   # 'B'
SIDE_SELL = 0x53  # 'S'
SIDE_BLANK = 0x20  # ' '  - Centre Point trades, not valid on a book message

# ---------------------------------------------------------------------------
# Exchange Order Type bitmap (A/F/U only)
# ---------------------------------------------------------------------------
EXT_MARKET_BID = 1 << 2    # 4
EXT_PRICE_STAB = 1 << 3    # 8
EXT_UNDISCLOSED = 1 << 5   # 32
EXT_IMPLIED = 1 << 13      # 8192

# ---------------------------------------------------------------------------
# Book operations. Index order must match t_book_op in order_book_pkg.
# ---------------------------------------------------------------------------
OP_ADD, OP_EXEC, OP_REPLACE, OP_DELETE = 0, 1, 2, 3
OP_NAMES = ("OP_ADD", "OP_EXEC", "OP_REPLACE", "OP_DELETE")

OP_OF_TYPE = {
    T_ADD: OP_ADD,
    T_ADD_PID: OP_ADD,
    T_REPLACE: OP_REPLACE,
    T_EXEC: OP_EXEC,
    T_EXEC_PRICE: OP_EXEC,
    T_DELETE: OP_DELETE,
}

# ---------------------------------------------------------------------------
# Sizing
# ---------------------------------------------------------------------------
MSG_BYTES = 64            # G_MSG_BYTES, matches the parser's assembly buffer
QTY_MAX = 0xFFFFFFFF      # saturation value when the wire quantity exceeds 32b

# A representative ASX order book id, used as the default instrument.
DEFAULT_BOOK_ID = 85603


# ---------------------------------------------------------------------------
# Byte packing
# ---------------------------------------------------------------------------
def _put(buf: bytearray, off: int, value: int, width: int) -> None:
    """Write a big-endian field of `width` bytes at byte offset `off`."""
    buf[off:off + width] = (value & ((1 << (8 * width)) - 1)).to_bytes(width, "big")


def to_int(msg: bytes, nbytes: int = MSG_BYTES) -> int:
    """
    Pack a message into the integer the DUT's s_msg expects.

    Byte 0 occupies the least significant byte, matching msg_byte() in
    order_book_pkg. Short messages are zero-padded to the buffer width.
    """
    assert len(msg) <= nbytes, f"message of {len(msg)} exceeds {nbytes}-byte buffer"
    v = 0
    for i, b in enumerate(msg):
        v |= b << (8 * i)
    return v


def signed32(v: int) -> int:
    """Two's complement 32-bit, for prices."""
    return v & 0xFFFFFFFF


def to_signed(v: int) -> int:
    """Interpret an unsigned 32-bit read-back as signed."""
    return v - (1 << 32) if v & 0x80000000 else v


# ---------------------------------------------------------------------------
# Message builders
#
# Every builder returns a bytes object of exactly the spec length, with all
# fields the book ignores filled with recognisable junk so that a decode
# picking up the wrong offset shows as an obviously wrong value rather than
# a plausible zero.
# ---------------------------------------------------------------------------
def build_add(order_id: int, book_id: int = DEFAULT_BOOK_ID,
              side: int = SIDE_BUY, qty: int = 100, price: int = 1000,
              position: int = 1, extype: int = 0, lot: int = 0,
              timestamp: int = 0x11223344, with_pid: bool = False) -> bytes:
    """Add Order - A (37 bytes), or F (44) when with_pid."""
    mtype = T_ADD_PID if with_pid else T_ADD
    b = bytearray(SPEC_LEN[mtype])
    b[0] = mtype
    _put(b, 1, timestamp, 4)
    _put(b, 5, order_id, 8)
    _put(b, 13, book_id, 4)
    b[17] = side
    _put(b, 18, position, 4)
    _put(b, 22, qty, 8)
    _put(b, 30, signed32(price), 4)
    _put(b, 34, extype, 2)
    b[36] = lot
    if with_pid:
        b[37:44] = b"ABC1234"          # participant id, ignored by the book
    return bytes(b)


def build_replace(order_id: int, book_id: int = DEFAULT_BOOK_ID,
                  side: int = SIDE_BUY, qty: int = 100, price: int = 1000,
                  position: int = 1, extype: int = 0,
                  timestamp: int = 0x11223344) -> bytes:
    """Order Replace - U (36 bytes). Same layout as A up to the extype."""
    b = bytearray(SPEC_LEN[T_REPLACE])
    b[0] = T_REPLACE
    _put(b, 1, timestamp, 4)
    _put(b, 5, order_id, 8)
    _put(b, 13, book_id, 4)
    b[17] = side
    _put(b, 18, position, 4)
    _put(b, 22, qty, 8)
    _put(b, 30, signed32(price), 4)
    _put(b, 34, extype, 2)
    return bytes(b)


def build_exec(order_id: int, book_id: int = DEFAULT_BOOK_ID,
               side: int = SIDE_BUY, qty: int = 50,
               trade_price: int = None, match_id: int = 0xDEADBEEFCAFE,
               timestamp: int = 0x11223344) -> bytes:
    """
    Order Executed - E (52 bytes), or C (58) when trade_price is given.

    The C variant's price field is the TRADE price. It is placed here
    deliberately so the testbench can prove it never reaches the output.
    """
    is_c = trade_price is not None
    mtype = T_EXEC_PRICE if is_c else T_EXEC
    b = bytearray(SPEC_LEN[mtype])
    b[0] = mtype
    _put(b, 1, timestamp, 4)
    _put(b, 5, order_id, 8)
    _put(b, 13, book_id, 4)
    b[17] = side
    _put(b, 18, qty, 8)
    _put(b, 26, match_id, 12)
    b[38:45] = b"OWNER01"              # participant, ignored
    b[45:52] = b"CPARTY1"              # counterparty, ignored
    if is_c:
        _put(b, 52, signed32(trade_price), 4)
        b[56] = ord("Y")               # occurred in auction
        b[57] = ord("Y")               # printable
    return bytes(b)


def build_delete(order_id: int, book_id: int = DEFAULT_BOOK_ID,
                 side: int = SIDE_BUY, timestamp: int = 0x11223344) -> bytes:
    """Order Delete - D (18 bytes). Identity only."""
    b = bytearray(SPEC_LEN[T_DELETE])
    b[0] = T_DELETE
    _put(b, 1, timestamp, 4)
    _put(b, 5, order_id, 8)
    _put(b, 13, book_id, 4)
    b[17] = side
    return bytes(b)


def build_trade(book_id: int = DEFAULT_BOOK_ID, side: int = SIDE_BLANK,
                qty: int = 500, price: int = 1000,
                timestamp: int = 0x11223344) -> bytes:
    """
    Trade - P (50 bytes). Never affects the displayed book (spec 2.7).

    Layout differs from E/C: match id comes first and there is no order id,
    so a decoder that treats P like an execution reads garbage.
    """
    b = bytearray(SPEC_LEN[T_TRADE])
    b[0] = T_TRADE
    _put(b, 1, timestamp, 4)
    _put(b, 5, 0xABCDEF0123456789ABCD, 12)   # match id
    b[17] = side
    _put(b, 18, qty, 8)
    _put(b, 26, book_id, 4)
    _put(b, 30, signed32(price), 4)
    b[34:41] = b"OWNER02"
    b[41:48] = b"CPARTY2"
    b[48] = ord("Y")
    b[49] = ord("N")
    return bytes(b)


def build_other(mtype: int, book_id: int = DEFAULT_BOOK_ID,
                fill: int = 0xA5) -> bytes:
    """
    Any non-book message type, filled with junk.

    The fill matters: it puts non-zero bytes where a book message would carry
    its order id, side and quantity, so a DUT that fails to gate on type emits
    a visibly wrong command rather than a harmless zero one.

    R (113) and M (261) exceed the 64-byte buffer, so they are clipped here -
    the parser cannot assemble them either.
    """
    n = min(SPEC_LEN[mtype], MSG_BYTES)
    b = bytearray([fill] * n)
    b[0] = mtype
    if n >= 17:
        _put(b, 13, book_id, 4)        # right instrument, wrong type
    return bytes(b)


# ---------------------------------------------------------------------------
# Reference decode
# ---------------------------------------------------------------------------
def expected_cmd(msg: bytes, book_id: int = DEFAULT_BOOK_ID):
    """
    What book_input_stage should emit for this message.

    Returns None if the message must be dropped - wrong type, wrong order
    book, or an unrecognised side byte. Otherwise a dict of the command bus.

    book_id is included even though a surviving command always matches the
    configured instrument: the DUT must forward it, not zero it, so that a
    later multi-symbol engine can key its order table on it.
    """
    mtype = msg[0]

    if mtype not in BOOK_TYPES:
        return None

    msg_book = int.from_bytes(msg[13:17], "big")
    if msg_book != book_id:
        return None

    side_byte = msg[17]
    if side_byte == SIDE_BUY:
        side = 0
    elif side_byte == SIDE_SELL:
        side = 1
    else:
        return None

    op = OP_OF_TYPE[mtype]
    order_id = int.from_bytes(msg[5:13], "big")

    qty_wire = 0
    price = 0
    px_valid = 0
    undisc = 0
    implied = 0

    if mtype in (T_ADD, T_ADD_PID, T_REPLACE):
        qty_wire = int.from_bytes(msg[22:30], "big")
        price = to_signed(int.from_bytes(msg[30:34], "big"))
        px_valid = 1
        ext = int.from_bytes(msg[34:36], "big")
        undisc = 1 if ext & EXT_UNDISCLOSED else 0
        implied = 1 if ext & EXT_IMPLIED else 0

    elif mtype in (T_EXEC, T_EXEC_PRICE):
        qty_wire = int.from_bytes(msg[18:26], "big")
        # px_valid stays 0. C's price at bytes 52-55 is the trade price and
        # must not escape; the resting price comes from the order table.

    # DELETE carries neither quantity nor price.

    if qty_wire > 0xFFFFFFFF:
        qty = QTY_MAX
    else:
        qty = qty_wire

    return {
        "op": op,
        "order_id": order_id,
        "book_id": msg_book,
        "side": side,
        "qty": qty,
        "price": price,
        "px_valid": px_valid,
        "undisc": undisc,
        "implied": implied,
    }


def expected_stream(msgs, book_id: int = DEFAULT_BOOK_ID):
    """Expected commands for a list of messages, drops removed."""
    out = []
    for m in msgs:
        e = expected_cmd(m, book_id)
        if e is not None:
            out.append(e)
    return out
