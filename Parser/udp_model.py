"""
Reference model for udp_parser.

Builds on ipv4_model (which itself carries the Ethernet layout), so the three
testbenches share one consistent view of the field bus.

Field bus layout, mirrors udp_parser_pkg:

    Ethernet slice   bits [129:0]     130 bits
    IPv4 slice       bits [293:130]   164 bits
    UDP slice        bits [359:294]    66 bits
                                      --------
    total                             360 bits

No cocotb dependency - importable standalone.
"""

import ipv4_model as ip4

# ---------------------------------------------------------------------------
# UDP slice, offsets WITHIN the slice (66 bits)
# ---------------------------------------------------------------------------
UDP_SRCPORT_LOC, UDP_SRCPORT_W = 0, 16
UDP_DSTPORT_LOC, UDP_DSTPORT_W = 16, 16
UDP_LENGTH_LOC, UDP_LENGTH_W = 32, 16
UDP_CKSUM_LOC, UDP_CKSUM_W = 48, 16

UDP_LEN_INVALID_LOC = 64
UDP_TRUNC_LOC = 65

UDP_FIELDS_W = 66
UDP_BASE = ip4.IPV4_BUS_W                 # 294
UDP_BUS_W = UDP_BASE + UDP_FIELDS_W       # 360

# Byte offset of the UDP header (Ethernet 14 + IPv4 20, +4 when tagged)
UDP_OFF_UNTAGGED = 34
UDP_OFF_TAGGED = 38


def slice_bits(value: int, lo: int, width: int) -> int:
    return (value >> lo) & ((1 << width) - 1)


# ---------------------------------------------------------------------------
# Upstream field bus - what ipv4_parser would present
# ---------------------------------------------------------------------------
def pack_ipv4_fields(f: dict) -> int:
    """Pack an ipv4_model reference dict into the 164-bit IPv4 slice."""
    v = 0
    v |= (f["version"] & 0xF) << ip4.IP_VERSION_LOC
    v |= (f["ihl"] & 0xF) << ip4.IP_IHL_LOC
    v |= (f["dscp_ecn"] & 0xFF) << ip4.IP_DSCPECN_LOC
    v |= (f["total_length"] & 0xFFFF) << ip4.IP_TOTLEN_LOC
    v |= (f["identification"] & 0xFFFF) << ip4.IP_ID_LOC
    v |= (f["flags"] & 0x7) << ip4.IP_FLAGS_LOC
    v |= (f["frag_offset"] & 0x1FFF) << ip4.IP_FRAGOFF_LOC
    v |= (f["ttl"] & 0xFF) << ip4.IP_TTL_LOC
    v |= (f["protocol"] & 0xFF) << ip4.IP_PROTO_LOC
    v |= (f["header_cksum"] & 0xFFFF) << ip4.IP_CKSUM_LOC
    v |= (f["src_ip"] & 0xFFFFFFFF) << ip4.IP_SRCIP_LOC
    v |= (f["dst_ip"] & 0xFFFFFFFF) << ip4.IP_DSTIP_LOC
    v |= (f["ihl_invalid"] & 1) << ip4.IP_IHL_INVALID_LOC
    v |= (f["version_invalid"] & 1) << ip4.IP_VER_INVALID_LOC
    v |= (f["frag_present"] & 1) << ip4.IP_FRAG_PRESENT_LOC
    v |= (f["hdr_truncated"] & 1) << ip4.IP_TRUNC_LOC
    return v


def upstream_field_vector(frame: bytes, tagged: bool = False,
                          vlan_tci: int = 0) -> int:
    """
    Pack the 294-bit Ethernet + IPv4 bus for a frame.

    Used to drive udp_parser's s_fields when testing it standalone. Driving
    this as a constant for the whole packet is valid: upstream stages hold
    their fields through tlast, and udp_parser only reads vlan_present from
    its beat 4 onwards.
    """
    eth = ip4.eth_field_vector(frame, vlan_tci=vlan_tci,
                               vlan_present=1 if tagged else 0)
    ipv4 = pack_ipv4_fields(ip4.expected_ipv4_fields(frame, tagged=tagged))
    return (ipv4 << ip4.IPV4_BASE) | eth


# ---------------------------------------------------------------------------
# UDP slice
# ---------------------------------------------------------------------------
def decode_udp_fields(raw_slice: int) -> dict:
    """Unpack the 66-bit UDP slice."""
    return {
        "src_port": slice_bits(raw_slice, UDP_SRCPORT_LOC, UDP_SRCPORT_W),
        "dst_port": slice_bits(raw_slice, UDP_DSTPORT_LOC, UDP_DSTPORT_W),
        "length": slice_bits(raw_slice, UDP_LENGTH_LOC, UDP_LENGTH_W),
        "checksum": slice_bits(raw_slice, UDP_CKSUM_LOC, UDP_CKSUM_W),
        "len_invalid": slice_bits(raw_slice, UDP_LEN_INVALID_LOC, 1),
        "hdr_truncated": slice_bits(raw_slice, UDP_TRUNC_LOC, 1),
    }


def udp_slice_of(bus: int) -> int:
    """Extract the UDP slice from the full 360-bit chained bus."""
    return slice_bits(bus, UDP_BASE, UDP_FIELDS_W)


def upstream_slice_of(bus: int) -> int:
    """Extract the Ethernet + IPv4 portion from the full 360-bit bus."""
    return slice_bits(bus, 0, UDP_BASE)


# ---------------------------------------------------------------------------
# Reference model
# ---------------------------------------------------------------------------
def expected_udp_fields(frame: bytes, tagged: bool = False) -> dict:
    """
    What udp_parser should extract from a complete frame.

    Assumes IHL=5. With IPv4 options present the real UDP header sits further
    on and the parser will latch the wrong bytes - that is the documented
    consequence of not supporting options.
    """
    off = UDP_OFF_TAGGED if tagged else UDP_OFF_UNTAGGED
    h = frame[off:off + 8]
    assert len(h) == 8, "frame too short to contain a full UDP header"

    length = int.from_bytes(h[4:6], "big")

    return {
        "src_port": int.from_bytes(h[0:2], "big"),
        "dst_port": int.from_bytes(h[2:4], "big"),
        "length": length,
        "checksum": int.from_bytes(h[6:8], "big"),
        "len_invalid": 1 if length < 8 else 0,
        "hdr_truncated": 0,
    }
