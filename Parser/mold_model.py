"""
Reference model for mold_parser.

Builds on udp_model (which builds on ipv4_model, which carries the Ethernet
layout), so all four testbenches share one consistent view of the field bus.

Field bus layout, mirrors mold_parser_pkg:

    Ethernet slice   bits [129:0]     130 bits
    IPv4 slice       bits [293:130]   164 bits
    UDP slice        bits [359:294]    66 bits
    Mold slice       bits [522:360]   163 bits
                                      --------
    total                             523 bits

No cocotb dependency - importable standalone.
"""

import ipv4_model as ip4
import udp_model as udp

# ---------------------------------------------------------------------------
# Mold slice, offsets WITHIN the slice (163 bits)
# ---------------------------------------------------------------------------
MOLD_SESSION_LOC, MOLD_SESSION_W = 0, 80
MOLD_SEQNUM_LOC, MOLD_SEQNUM_W = 80, 64
MOLD_MSGCNT_LOC, MOLD_MSGCNT_W = 144, 16

MOLD_HEARTBEAT_LOC = 160
MOLD_EOS_LOC = 161
MOLD_TRUNC_LOC = 162

MOLD_FIELDS_W = 163
MOLD_BASE = udp.UDP_BUS_W                    # 360
MOLD_BUS_W = MOLD_BASE + MOLD_FIELDS_W       # 523

# Byte offset of the MoldUDP64 header
# Ethernet 14 + IPv4 20 + UDP 8 = 42, +4 when tagged
MOLD_OFF_UNTAGGED = 42
MOLD_OFF_TAGGED = 46

# Completion beat differs with the tag in this stage, unlike ipv4 and udp
MOLD_LAST_BEAT_UNTAGGED = 7
MOLD_LAST_BEAT_TAGGED = 8


def slice_bits(value: int, lo: int, width: int) -> int:
    return (value >> lo) & ((1 << width) - 1)


# ---------------------------------------------------------------------------
# Upstream field bus - what udp_parser would present
# ---------------------------------------------------------------------------
def pack_udp_fields(f: dict) -> int:
    """Pack a udp_model reference dict into the 66-bit UDP slice."""
    v = 0
    v |= (f["src_port"] & 0xFFFF) << udp.UDP_SRCPORT_LOC
    v |= (f["dst_port"] & 0xFFFF) << udp.UDP_DSTPORT_LOC
    v |= (f["length"] & 0xFFFF) << udp.UDP_LENGTH_LOC
    v |= (f["checksum"] & 0xFFFF) << udp.UDP_CKSUM_LOC
    v |= (f["len_invalid"] & 1) << udp.UDP_LEN_INVALID_LOC
    v |= (f["hdr_truncated"] & 1) << udp.UDP_TRUNC_LOC
    return v


def upstream_field_vector(frame: bytes, tagged: bool = False,
                          vlan_tci: int = 0) -> int:
    """
    Pack the 360-bit Ethernet + IPv4 + UDP bus for a frame.

    Used to drive mold_parser's s_fields when testing it standalone. Driving
    this as a constant for the whole packet is valid: upstream stages hold
    their fields through tlast, and mold_parser only reads vlan_present from
    its beat 5 onwards.
    """
    up = udp.upstream_field_vector(frame, tagged=tagged, vlan_tci=vlan_tci)
    u = pack_udp_fields(udp.expected_udp_fields(frame, tagged=tagged))
    return (u << udp.UDP_BASE) | up


# ---------------------------------------------------------------------------
# Mold slice
# ---------------------------------------------------------------------------
def decode_mold_fields(raw_slice: int) -> dict:
    """Unpack the 163-bit Mold slice."""
    return {
        "session": slice_bits(raw_slice, MOLD_SESSION_LOC, MOLD_SESSION_W),
        "sequence_num": slice_bits(raw_slice, MOLD_SEQNUM_LOC, MOLD_SEQNUM_W),
        "message_count": slice_bits(raw_slice, MOLD_MSGCNT_LOC, MOLD_MSGCNT_W),
        "heartbeat": slice_bits(raw_slice, MOLD_HEARTBEAT_LOC, 1),
        "end_of_session": slice_bits(raw_slice, MOLD_EOS_LOC, 1),
        "hdr_truncated": slice_bits(raw_slice, MOLD_TRUNC_LOC, 1),
    }


def mold_slice_of(bus: int) -> int:
    """Extract the Mold slice from the full 523-bit chained bus."""
    return slice_bits(bus, MOLD_BASE, MOLD_FIELDS_W)


def upstream_slice_of(bus: int) -> int:
    """Extract the Ethernet + IPv4 + UDP portion from the full 523-bit bus."""
    return slice_bits(bus, 0, MOLD_BASE)


def session_ascii(value: int) -> str:
    """Render an 80-bit session field back to its 10 ASCII characters."""
    return value.to_bytes(10, "big").decode("ascii", errors="replace")


# ---------------------------------------------------------------------------
# Reference model
# ---------------------------------------------------------------------------
def expected_mold_fields(frame: bytes, tagged: bool = False) -> dict:
    """
    What mold_parser should extract from a complete frame.

    Assumes IHL=5. With IPv4 options present everything below IPv4 shifts and
    the parser latches the wrong bytes - the documented consequence of not
    supporting options.
    """
    off = MOLD_OFF_TAGGED if tagged else MOLD_OFF_UNTAGGED
    h = frame[off:off + 20]
    assert len(h) == 20, "frame too short to contain a full MoldUDP64 header"

    count = int.from_bytes(h[18:20], "big")

    return {
        "session": int.from_bytes(h[0:10], "big"),
        "sequence_num": int.from_bytes(h[10:18], "big"),
        "message_count": count,
        "heartbeat": 1 if count == 0 else 0,
        "end_of_session": 1 if count == 0xFFFF else 0,
        "hdr_truncated": 0,
    }


def expected_last_beat(tagged: bool = False) -> int:
    return MOLD_LAST_BEAT_TAGGED if tagged else MOLD_LAST_BEAT_UNTAGGED
