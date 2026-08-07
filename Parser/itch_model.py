"""
Reference model for the ASX ITCH parser.

Built from the ASX Trade ITCH Specification v3.4 (May 2026). Defines the
message table, the MoldUDP64 payload framing, and the output event format the
RTL will be verified against.

--------------------------------------------------------------------------
OUTPUT MODEL
--------------------------------------------------------------------------
Unlike the four header parsers, this stage emits N events per packet - one
per message - rather than one field bus per packet. Each event carries:

    msg_index     0..count-1, position within the packet
    msg_seqnum    mold sequence_num + msg_index  (derived here, not on wire)
    msg_type      the ASCII type byte
    msg_length    the length field value (message data, excluding the 2
                  length bytes)
    msg_fields    512-bit decoded field bus, valid when decoded = 1
    msg_status    informational bits, gate nothing
    raw           the message data bytes, for undecoded types
    pkt_fields    the 523-bit upstream context, re-presented per message

--------------------------------------------------------------------------
SPECIAL CASE: 'T' SECONDS MESSAGES
--------------------------------------------------------------------------
A Seconds message block is 7 bytes (2 length + 5 data), smaller than one
8-byte beat. Two messages can therefore complete within a single beat
whenever the second is a T, which would break the one-event-per-cycle rule.

Per the chosen design, T is handled as CLOCK STATE, not as a message: its
4-byte seconds value is captured into a register and NO event is emitted.
Since T is the only type whose block is under 8 bytes, no two emitted events
can ever land in the same beat.

T still consumes a sequence number - every message in a Mold packet is
sequenced - so msg_index and msg_seqnum advance across it. The captured
seconds value is attached to every subsequent event as exchange_seconds,
which combined with each message's own nanoseconds field gives full
exchange time.

No cocotb dependency - importable standalone.
"""

import struct

import asx_packets as pkt
import mold_model as mold

# ===========================================================================
# Message table  (ASX Trade ITCH Specification v3.4)
#
# block length = message length + 2 (the length field itself)
# ===========================================================================
MSG_LEN = {
    "T": 5,      # Seconds                       block  7  <- special case
    "S": 6,      # System Event                  block  8
    "D": 18,     # Order Delete                  block 20
    "L": 25,     # Tick Size Table Entry         block 27
    "O": 29,     # Order Book State              block 31
    "U": 36,     # Order Replace                 block 38
    "A": 37,     # Add Order, no participant     block 39
    "F": 44,     # Add Order, with participant   block 46
    "P": 50,     # Trade                         block 52
    "E": 52,     # Order Executed                block 54
    "Z": 53,     # Equilibrium Price Update      block 55
    "C": 58,     # Order Executed with Price     block 60
    "R": 113,    # Order Book Directory          block 115
    "M": 261,    # Combination Order Book Dir    block 263
}

# Types decoded into msg_fields. Everything else is passed through as raw
# bytes plus msg_type: reference data (R, M, L) is start-of-day and not
# latency critical, and decoding it would widen the field bus enormously.
DECODED_TYPES = ("A", "F", "E", "C", "U", "D", "P")

MIN_BLOCK = min(MSG_LEN.values()) + 2       # 7, the T message
MAX_BLOCK = max(MSG_LEN.values()) + 2       # 263, a Combination Directory


# ===========================================================================
# msg_fields layout - 512 bits, union of the seven decoded types
# ===========================================================================
FLD_TIMESTAMP_NS_LO, FLD_TIMESTAMP_NS_W = 0, 32
FLD_ORDER_ID_LO, FLD_ORDER_ID_W = 32, 64
FLD_ORDER_BOOK_ID_LO, FLD_ORDER_BOOK_ID_W = 96, 32
FLD_SIDE_LO, FLD_SIDE_W = 128, 8
FLD_POSITION_LO, FLD_POSITION_W = 136, 32
FLD_QUANTITY_LO, FLD_QUANTITY_W = 168, 64
FLD_PRICE_LO, FLD_PRICE_W = 232, 32
FLD_EXCH_ORDER_TYPE_LO, FLD_EXCH_ORDER_TYPE_W = 264, 16
FLD_LOT_TYPE_LO, FLD_LOT_TYPE_W = 280, 8
FLD_MATCH_ID_LO, FLD_MATCH_ID_W = 288, 96
FLD_PART_OWNER_LO, FLD_PART_OWNER_W = 384, 56
FLD_PART_CP_LO, FLD_PART_CP_W = 440, 56
FLD_PRINTABLE_LO, FLD_PRINTABLE_W = 496, 8
FLD_OCCURRED_CROSS_LO, FLD_OCCURRED_CROSS_W = 504, 8

MSG_FIELDS_W = 512

FIELD_LAYOUT = [
    ("timestamp_ns", FLD_TIMESTAMP_NS_LO, FLD_TIMESTAMP_NS_W),
    ("order_id", FLD_ORDER_ID_LO, FLD_ORDER_ID_W),
    ("order_book_id", FLD_ORDER_BOOK_ID_LO, FLD_ORDER_BOOK_ID_W),
    ("side", FLD_SIDE_LO, FLD_SIDE_W),
    ("position", FLD_POSITION_LO, FLD_POSITION_W),
    ("quantity", FLD_QUANTITY_LO, FLD_QUANTITY_W),
    ("price", FLD_PRICE_LO, FLD_PRICE_W),
    ("exchange_order_type", FLD_EXCH_ORDER_TYPE_LO, FLD_EXCH_ORDER_TYPE_W),
    ("lot_type", FLD_LOT_TYPE_LO, FLD_LOT_TYPE_W),
    ("match_id", FLD_MATCH_ID_LO, FLD_MATCH_ID_W),
    ("participant_owner", FLD_PART_OWNER_LO, FLD_PART_OWNER_W),
    ("participant_cp", FLD_PART_CP_LO, FLD_PART_CP_W),
    ("printable", FLD_PRINTABLE_LO, FLD_PRINTABLE_W),
    ("occurred_at_cross", FLD_OCCURRED_CROSS_LO, FLD_OCCURRED_CROSS_W),
]

# ===========================================================================
# msg_status - informational only, gates nothing
# ===========================================================================
ST_DECODED = 0          # this type has valid msg_fields
ST_LEN_MISMATCH = 1     # length field disagrees with the type's spec length
ST_MSG_TRUNCATED = 2    # message ran past the end of the packet
ST_UNKNOWN_TYPE = 3     # type byte not in the message table
ST_COUNT_MISMATCH = 4   # messages framed != mold message_count (last event)
ST_MULTI_COMPLETE = 5   # two EMITTING messages completed in one beat
MSG_STATUS_W = 6

# Bits the model can produce. ST_MULTI_COMPLETE is an RTL-only condition -
# the model has no notion of beats - but the constant lives here so the
# testbench has one place to look up status bit positions.
MODEL_STATUS_BITS = (ST_DECODED, ST_LEN_MISMATCH, ST_MSG_TRUNCATED,
                     ST_UNKNOWN_TYPE, ST_COUNT_MISMATCH)


# ---------------------------------------------------------------------------
# Bit helpers
# ---------------------------------------------------------------------------
def slice_bits(value: int, lo: int, width: int) -> int:
    return (value >> lo) & ((1 << width) - 1)


def pack_msg_fields(f: dict) -> int:
    v = 0
    for name, lo, width in FIELD_LAYOUT:
        v |= (f.get(name, 0) & ((1 << width) - 1)) << lo
    return v


def decode_msg_fields(raw: int) -> dict:
    return {name: slice_bits(raw, lo, w) for name, lo, w in FIELD_LAYOUT}


def pack_status(decoded=0, len_mismatch=0, truncated=0,
                unknown_type=0, count_mismatch=0) -> int:
    return ((decoded & 1) << ST_DECODED |
            (len_mismatch & 1) << ST_LEN_MISMATCH |
            (truncated & 1) << ST_MSG_TRUNCATED |
            (unknown_type & 1) << ST_UNKNOWN_TYPE |
            (count_mismatch & 1) << ST_COUNT_MISMATCH)


def _u(b: bytes) -> int:
    return int.from_bytes(b, "big")


# ===========================================================================
# Per-type field decode
#
# Offsets are relative to the START of the message, so once framing has
# located a message these are all fixed - the same easy problem the four
# header parsers already solve.
# ===========================================================================
def decode_message(m: bytes) -> dict:
    """
    Decode one message's data bytes into the field dict.

    Returns {} for types not in DECODED_TYPES.
    """
    t = chr(m[0])

    if t == "A":                       # Add Order, no participant ID
        return {
            "timestamp_ns": _u(m[1:5]),
            "order_id": _u(m[5:13]),
            "order_book_id": _u(m[13:17]),
            "side": m[17],
            "position": _u(m[18:22]),
            "quantity": _u(m[22:30]),
            "price": _u(m[30:34]),
            "exchange_order_type": _u(m[34:36]),
            "lot_type": m[36],
        }

    if t == "F":                       # Add Order, with participant ID
        return {
            "timestamp_ns": _u(m[1:5]),
            "order_id": _u(m[5:13]),
            "order_book_id": _u(m[13:17]),
            "side": m[17],
            "position": _u(m[18:22]),
            "quantity": _u(m[22:30]),
            "price": _u(m[30:34]),
            "exchange_order_type": _u(m[34:36]),
            "lot_type": m[36],
            "participant_owner": _u(m[37:44]),
        }

    if t == "E":                       # Order Executed
        return {
            "timestamp_ns": _u(m[1:5]),
            "order_id": _u(m[5:13]),
            "order_book_id": _u(m[13:17]),
            "side": m[17],
            "quantity": _u(m[18:26]),
            "match_id": _u(m[26:38]),
            "participant_owner": _u(m[38:45]),
            "participant_cp": _u(m[45:52]),
        }

    if t == "C":                       # Order Executed with Price
        return {
            "timestamp_ns": _u(m[1:5]),
            "order_id": _u(m[5:13]),
            "order_book_id": _u(m[13:17]),
            "side": m[17],
            "quantity": _u(m[18:26]),
            "match_id": _u(m[26:38]),
            "participant_owner": _u(m[38:45]),
            "participant_cp": _u(m[45:52]),
            "price": _u(m[52:56]),
            "occurred_at_cross": m[56],
            "printable": m[57],
        }

    if t == "U":                       # Order Replace
        return {
            "timestamp_ns": _u(m[1:5]),
            "order_id": _u(m[5:13]),
            "order_book_id": _u(m[13:17]),
            "side": m[17],
            "position": _u(m[18:22]),
            "quantity": _u(m[22:30]),
            "price": _u(m[30:34]),
            "exchange_order_type": _u(m[34:36]),
        }

    if t == "D":                       # Order Delete
        return {
            "timestamp_ns": _u(m[1:5]),
            "order_id": _u(m[5:13]),
            "order_book_id": _u(m[13:17]),
            "side": m[17],
        }

    if t == "P":                       # Trade
        return {
            "timestamp_ns": _u(m[1:5]),
            "match_id": _u(m[5:17]),
            "side": m[17],
            "quantity": _u(m[18:26]),
            "order_book_id": _u(m[26:30]),
            "price": _u(m[30:34]),
            "participant_owner": _u(m[34:41]),
            "participant_cp": _u(m[41:48]),
            "printable": m[48],
            "occurred_at_cross": m[49],
        }

    return {}


# ===========================================================================
# Framing
# ===========================================================================
class ItchEvent:
    """One output event from the ITCH parser."""

    __slots__ = ("msg_index", "msg_seqnum", "msg_type", "msg_length",
                 "fields", "status", "raw", "exchange_seconds", "byte_offset")

    def __init__(self, **kw):
        for k in self.__slots__:
            setattr(self, k, kw.get(k))

    @property
    def fields_int(self) -> int:
        return pack_msg_fields(self.fields or {})

    def __repr__(self):
        return (f"<ItchEvent idx={self.msg_index} seq={self.msg_seqnum} "
                f"type={self.msg_type} len={self.msg_length} "
                f"status={self.status:#x}>")


def frame_payload(payload: bytes, sequence_num: int, message_count: int):
    """
    Walk the MoldUDP64 payload and produce the output events.

    Framing is driven by the LENGTH CHAIN plus the end of the payload, not by
    message_count. The count is used only as a cross-check, so a packet whose
    count disagrees with its contents is flagged rather than mis-framed.

    'T' messages are consumed as clock state and produce NO event, but do
    consume a sequence number.

    Returns (events, seconds, framed_count) where `seconds` is the last
    exchange Seconds value seen.
    """
    events = []
    pos = 0
    index = 0
    seconds = 0
    n = len(payload)

    while pos < n:
        # --- length field -------------------------------------------------
        if pos + 2 > n:
            # a length field cut in half by the end of the packet
            events.append(ItchEvent(
                msg_index=index, msg_seqnum=sequence_num + index,
                msg_type=0, msg_length=0, fields={},
                status=pack_status(truncated=1), raw=payload[pos:],
                exchange_seconds=seconds, byte_offset=pos))
            index += 1
            break

        length = _u(payload[pos:pos + 2])
        body = payload[pos + 2: pos + 2 + length]
        truncated = 1 if len(body) < length else 0

        # --- type and spec cross-check ------------------------------------
        if len(body) >= 1:
            tchar = chr(body[0])
            unknown = 0 if tchar in MSG_LEN else 1
            len_mismatch = (0 if (not unknown and MSG_LEN[tchar] == length)
                            else 1)
        else:
            tchar = None
            unknown = 1
            len_mismatch = 1

        # --- special case: Seconds is clock state, not a message ----------
        if tchar == "T" and not truncated:
            seconds = _u(body[1:5])
            index += 1                     # still consumes a sequence number
            pos += 2 + length
            continue

        # --- decode -------------------------------------------------------
        decoded = 1 if (tchar in DECODED_TYPES and not truncated) else 0
        fields = decode_message(body) if decoded else {}

        events.append(ItchEvent(
            msg_index=index,
            msg_seqnum=sequence_num + index,
            msg_type=ord(tchar) if tchar else 0,
            msg_length=length,
            fields=fields,
            status=pack_status(decoded=decoded, len_mismatch=len_mismatch,
                               truncated=truncated, unknown_type=unknown),
            raw=bytes(body),
            exchange_seconds=seconds,
            byte_offset=pos,
        ))

        index += 1
        if truncated:
            break
        pos += 2 + length

    # --- count cross-check, reported on the final event -------------------
    if events and index != message_count:
        last = events[-1]
        last.status |= pack_status(count_mismatch=1)

    return events, seconds, index


# ===========================================================================
# Payload and frame builders, for stimulus
# ===========================================================================
def message_block(msg: bytes) -> bytes:
    """Wrap message data in its 2-byte length prefix."""
    return struct.pack(">H", len(msg)) + msg


def build_payload(messages) -> bytes:
    """Concatenate message blocks into a MoldUDP64 payload."""
    return b"".join(message_block(m) for m in messages)


def build_frame(messages,
                vlan_vid=None, vlan_pcp=0, vlan_dei=0, tpid=pkt.TPID_8021Q,
                src_mac=pkt.ASX_SRC_MAC, dst_mac=None,
                src_ip=pkt.ASX_SRC_IP_A, dst_ip=pkt.ASX_GRP_IP,
                udp_src_port=50000, udp_dst_port=pkt.ASX_DST_PORT,
                mold_session=b"ASX0000001", mold_seqnum=1,
                mold_msg_count=None, ihl=5) -> bytes:
    """
    Build a complete Ethernet/IPv4/UDP/MoldUDP64 frame carrying a list of
    ITCH messages.

    asx_packets.build_frame only ever emits a single message block, so this
    replaces the Mold payload construction while reusing the lower layers.
    """
    if dst_mac is None:
        dst_mac = pkt.multicast_mac_for(dst_ip)
    if mold_msg_count is None:
        mold_msg_count = len(messages)

    payload = build_payload(messages)

    m = mold_session + struct.pack(">Q", mold_seqnum)
    m += struct.pack(">H", mold_msg_count) + payload

    udp_len = 8 + len(m)
    udp = struct.pack(">HHHH", udp_src_port, udp_dst_port, udp_len, 0) + m

    ip_total = (ihl * 4) + len(udp)
    ip = struct.pack(">BBHHHBBH", (4 << 4) | ihl, 0, ip_total, 0x1234,
                     0x4000, 64, pkt.IP_PROTO_UDP, 0)
    ip += pkt.ip_to_bytes(src_ip) + pkt.ip_to_bytes(dst_ip)
    ip += bytes((ihl - 5) * 4)
    ip = ip[:10] + struct.pack(">H", pkt.ipv4_checksum(ip)) + ip[12:]

    eth = pkt.mac_to_bytes(dst_mac) + pkt.mac_to_bytes(src_mac)
    if vlan_vid is not None:
        eth += struct.pack(">HH", tpid,
                           pkt.make_tci(vlan_pcp, vlan_dei, vlan_vid))
    eth += struct.pack(">H", pkt.ETHERTYPE_IPV4)

    return eth + ip + udp


def payload_offset(tagged: bool = False) -> int:
    """Byte offset where the MoldUDP64 payload begins."""
    return (mold.MOLD_OFF_TAGGED if tagged else mold.MOLD_OFF_UNTAGGED) + 20


def expected_events(frame: bytes, tagged: bool = False):
    """
    Run the reference model over a built frame.

    Returns (events, seconds, framed_count).
    """
    mf = mold.expected_mold_fields(frame, tagged=tagged)
    payload = frame[payload_offset(tagged):]
    return frame_payload(payload, mf["sequence_num"], mf["message_count"])


# ===========================================================================
# Message constructors, for building realistic stimulus
# ===========================================================================
def _alpha(s, n: int) -> bytes:
    """Left justified, space padded on the right - the ITCH alpha convention."""
    b = s.encode("latin-1") if isinstance(s, str) else s
    return b[:n].ljust(n, b" ")


def msg_seconds(second: int) -> bytes:
    return b"T" + struct.pack(">I", second)


def msg_system_event(ts=0, code="O") -> bytes:
    return b"S" + struct.pack(">I", ts) + _alpha(code, 1)


def msg_add_order(ts=0, order_id=1, book=85603, side="B", position=1,
                  quantity=100, price=55000, exch_type=0, lot=2) -> bytes:
    return (b"A" + struct.pack(">I", ts) + struct.pack(">Q", order_id) +
            struct.pack(">I", book) + _alpha(side, 1) +
            struct.pack(">I", position) + struct.pack(">Q", quantity) +
            struct.pack(">I", price) + struct.pack(">H", exch_type) +
            bytes([lot]))


def msg_add_order_pid(ts=0, order_id=1, book=85603, side="S", position=1,
                      quantity=100, price=55000, exch_type=0, lot=2,
                      participant="AU550") -> bytes:
    return (b"F" + struct.pack(">I", ts) + struct.pack(">Q", order_id) +
            struct.pack(">I", book) + _alpha(side, 1) +
            struct.pack(">I", position) + struct.pack(">Q", quantity) +
            struct.pack(">I", price) + struct.pack(">H", exch_type) +
            bytes([lot]) + _alpha(participant, 7))


def msg_order_executed(ts=0, order_id=1, book=85603, side="B", qty=1000,
                       match_id=0x123456789ABCDEF012345678,
                       owner="", cp="") -> bytes:
    return (b"E" + struct.pack(">I", ts) + struct.pack(">Q", order_id) +
            struct.pack(">I", book) + _alpha(side, 1) +
            struct.pack(">Q", qty) + match_id.to_bytes(12, "big") +
            _alpha(owner, 7) + _alpha(cp, 7))


def msg_order_executed_price(ts=0, order_id=1, book=85603, side="B", qty=10,
                             match_id=1, owner="AU550", cp="AU551", price=50,
                             cross="N", printable="N") -> bytes:
    return (b"C" + struct.pack(">I", ts) + struct.pack(">Q", order_id) +
            struct.pack(">I", book) + _alpha(side, 1) +
            struct.pack(">Q", qty) + match_id.to_bytes(12, "big") +
            _alpha(owner, 7) + _alpha(cp, 7) + struct.pack(">I", price) +
            _alpha(cross, 1) + _alpha(printable, 1))


def msg_order_replace(ts=0, order_id=1, book=85603, side="B", position=1,
                      quantity=2000, price=270300, exch_type=0) -> bytes:
    return (b"U" + struct.pack(">I", ts) + struct.pack(">Q", order_id) +
            struct.pack(">I", book) + _alpha(side, 1) +
            struct.pack(">I", position) + struct.pack(">Q", quantity) +
            struct.pack(">I", price) + struct.pack(">H", exch_type))


def msg_order_delete(ts=0, order_id=1, book=85603, side="S") -> bytes:
    return (b"D" + struct.pack(">I", ts) + struct.pack(">Q", order_id) +
            struct.pack(">I", book) + _alpha(side, 1))


def msg_trade(ts=0, match_id=1, side=" ", qty=48000, book=70669,
              price=270300, owner="", cp="", printable="Y",
              cross="N") -> bytes:
    return (b"P" + struct.pack(">I", ts) + match_id.to_bytes(12, "big") +
            _alpha(side, 1) + struct.pack(">Q", qty) +
            struct.pack(">I", book) + struct.pack(">I", price) +
            _alpha(owner, 7) + _alpha(cp, 7) + _alpha(printable, 1) +
            _alpha(cross, 1))


def msg_order_book_state(ts=0, book=85603, state="OPEN") -> bytes:
    return (b"O" + struct.pack(">I", ts) + struct.pack(">I", book) +
            _alpha(state, 20))


def msg_tick_size(ts=0, book=85603, tick=10, price_from=10,
                  price_to=990) -> bytes:
    return (b"L" + struct.pack(">I", ts) + struct.pack(">I", book) +
            struct.pack(">Q", tick) + struct.pack(">I", price_from) +
            struct.pack(">I", price_to))


def msg_equilibrium(ts=0, book=70639, bid_qty=66, ask_qty=53, eq_price=26100,
                    best_bid=26100, best_ask=26100, best_bid_qty=66,
                    best_ask_qty=53) -> bytes:
    return (b"Z" + struct.pack(">I", ts) + struct.pack(">I", book) +
            struct.pack(">Q", bid_qty) + struct.pack(">Q", ask_qty) +
            struct.pack(">I", eq_price) + struct.pack(">I", best_bid) +
            struct.pack(">I", best_ask) + struct.pack(">Q", best_bid_qty) +
            struct.pack(">Q", best_ask_qty))


# ---------------------------------------------------------------------------
# Self-check: every constructor must produce the spec length
# ---------------------------------------------------------------------------
def _self_check():
    checks = [
        (msg_seconds(1), "T"), (msg_system_event(), "S"),
        (msg_add_order(), "A"), (msg_add_order_pid(), "F"),
        (msg_order_executed(), "E"), (msg_order_executed_price(), "C"),
        (msg_order_replace(), "U"), (msg_order_delete(), "D"),
        (msg_trade(), "P"), (msg_order_book_state(), "O"),
        (msg_tick_size(), "L"), (msg_equilibrium(), "Z"),
    ]
    for m, t in checks:
        assert chr(m[0]) == t, f"{t}: type byte is {chr(m[0])}"
        assert len(m) == MSG_LEN[t], (
            f"{t}: built {len(m)} bytes, spec says {MSG_LEN[t]}"
        )
    return True


if __name__ == "__main__":
    _self_check()
    print("message table self-check passed")
    print(f"min block {MIN_BLOCK} bytes (T), max block {MAX_BLOCK} bytes (M)")

    msgs = [msg_seconds(1700000000), msg_add_order(order_id=0x621F1282E5ED),
            msg_order_delete(order_id=0x621F1282E5ED),
            msg_order_executed(order_id=7)]
    f = build_frame(msgs)
    evs, secs, n = expected_events(f)
    print(f"\nframe {len(f)} bytes, {n} messages framed, "
          f"{len(evs)} events emitted, seconds={secs}")
    for e in evs:
        print("  ", e)
