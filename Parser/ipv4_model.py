"""
Reference model for ipv4_parser.

Separate from asx_packets.py (the frame builder) so the two parser
testbenches can live side by side in one directory. Frames still come from
asx_packets; this module only models what ipv4_parser should extract, and
packs/unpacks the field bus.

Field bus layout, mirrors ipv4_parser_pkg:

    Ethernet slice   bits [129:0]     130 bits
    IPv4 slice       bits [293:130]   164 bits
                                      --------
    total                             294 bits

No cocotb dependency - importable standalone.
"""

# ---------------------------------------------------------------------------
# Ethernet slice, mirrors eth_parser_pkg (130 bits)
# ---------------------------------------------------------------------------
E_DST_MAC_LO, E_DST_MAC_W = 0, 48
E_SRC_MAC_LO, E_SRC_MAC_W = 48, 48
E_ETHERTYPE_LO, E_ETHERTYPE_W = 96, 16
E_VLAN_TCI_LO, E_VLAN_TCI_W = 112, 16
E_VLAN_PRESENT_LO = 128
E_TRUNC_LO = 129
ETH_FIELDS_W = 130

# ---------------------------------------------------------------------------
# IPv4 slice, offsets WITHIN the slice (164 bits)
# ---------------------------------------------------------------------------
IP_VERSION_LOC, IP_VERSION_W = 0, 4
IP_IHL_LOC, IP_IHL_W = 4, 4
IP_DSCPECN_LOC, IP_DSCPECN_W = 8, 8
IP_TOTLEN_LOC, IP_TOTLEN_W = 16, 16
IP_ID_LOC, IP_ID_W = 32, 16
IP_FLAGS_LOC, IP_FLAGS_W = 48, 3
IP_FRAGOFF_LOC, IP_FRAGOFF_W = 51, 13
IP_TTL_LOC, IP_TTL_W = 64, 8
IP_PROTO_LOC, IP_PROTO_W = 72, 8
IP_CKSUM_LOC, IP_CKSUM_W = 80, 16
IP_SRCIP_LOC, IP_SRCIP_W = 96, 32
IP_DSTIP_LOC, IP_DSTIP_W = 128, 32

IP_IHL_INVALID_LOC = 160
IP_VER_INVALID_LOC = 161
IP_FRAG_PRESENT_LOC = 162
IP_TRUNC_LOC = 163

IPV4_FIELDS_W = 164
IPV4_BASE = ETH_FIELDS_W          # 130
IPV4_BUS_W = IPV4_BASE + IPV4_FIELDS_W   # 294


# ---------------------------------------------------------------------------
# Bit helpers
# ---------------------------------------------------------------------------
def slice_bits(value: int, lo: int, width: int) -> int:
    return (value >> lo) & ((1 << width) - 1)


# ---------------------------------------------------------------------------
# Ethernet field bus - what eth_parser would present upstream
# ---------------------------------------------------------------------------
def eth_field_vector(frame: bytes, vlan_tci: int = 0,
                     vlan_present: int = 0, truncated: int = 0) -> int:
    """
    Pack the 130-bit Ethernet field bus for a frame.

    Used to drive ipv4_parser's s_fields when testing it standalone. Driving
    this as a constant for the whole packet is valid: eth_parser holds its
    fields from header completion through tlast, and ipv4_parser only reads
    vlan_present from its beat 1 onwards.
    """
    if vlan_present:
        ethertype = int.from_bytes(frame[16:18], "big")
    else:
        ethertype = int.from_bytes(frame[12:14], "big")

    v = int.from_bytes(frame[0:6], "big") << E_DST_MAC_LO
    v |= int.from_bytes(frame[6:12], "big") << E_SRC_MAC_LO
    v |= ethertype << E_ETHERTYPE_LO
    v |= (vlan_tci & 0xFFFF) << E_VLAN_TCI_LO
    v |= (vlan_present & 1) << E_VLAN_PRESENT_LO
    v |= (truncated & 1) << E_TRUNC_LO
    return v


def decode_eth_fields(raw: int) -> dict:
    return {
        "dst_mac": slice_bits(raw, E_DST_MAC_LO, E_DST_MAC_W),
        "src_mac": slice_bits(raw, E_SRC_MAC_LO, E_SRC_MAC_W),
        "ethertype": slice_bits(raw, E_ETHERTYPE_LO, E_ETHERTYPE_W),
        "vlan_tci": slice_bits(raw, E_VLAN_TCI_LO, E_VLAN_TCI_W),
        "vlan_present": slice_bits(raw, E_VLAN_PRESENT_LO, 1),
        "hdr_truncated": slice_bits(raw, E_TRUNC_LO, 1),
    }


# ---------------------------------------------------------------------------
# IPv4 slice
# ---------------------------------------------------------------------------
def decode_ipv4_fields(raw_slice: int) -> dict:
    """Unpack the 164-bit IPv4 slice."""
    return {
        "version": slice_bits(raw_slice, IP_VERSION_LOC, IP_VERSION_W),
        "ihl": slice_bits(raw_slice, IP_IHL_LOC, IP_IHL_W),
        "dscp_ecn": slice_bits(raw_slice, IP_DSCPECN_LOC, IP_DSCPECN_W),
        "total_length": slice_bits(raw_slice, IP_TOTLEN_LOC, IP_TOTLEN_W),
        "identification": slice_bits(raw_slice, IP_ID_LOC, IP_ID_W),
        "flags": slice_bits(raw_slice, IP_FLAGS_LOC, IP_FLAGS_W),
        "frag_offset": slice_bits(raw_slice, IP_FRAGOFF_LOC, IP_FRAGOFF_W),
        "ttl": slice_bits(raw_slice, IP_TTL_LOC, IP_TTL_W),
        "protocol": slice_bits(raw_slice, IP_PROTO_LOC, IP_PROTO_W),
        "header_cksum": slice_bits(raw_slice, IP_CKSUM_LOC, IP_CKSUM_W),
        "src_ip": slice_bits(raw_slice, IP_SRCIP_LOC, IP_SRCIP_W),
        "dst_ip": slice_bits(raw_slice, IP_DSTIP_LOC, IP_DSTIP_W),
        "ihl_invalid": slice_bits(raw_slice, IP_IHL_INVALID_LOC, 1),
        "version_invalid": slice_bits(raw_slice, IP_VER_INVALID_LOC, 1),
        "frag_present": slice_bits(raw_slice, IP_FRAG_PRESENT_LOC, 1),
        "hdr_truncated": slice_bits(raw_slice, IP_TRUNC_LOC, 1),
    }


def ipv4_slice_of(bus: int) -> int:
    """Extract the IPv4 slice from the full 294-bit chained bus."""
    return slice_bits(bus, IPV4_BASE, IPV4_FIELDS_W)


def eth_slice_of(bus: int) -> int:
    """Extract the Ethernet slice from the full 294-bit chained bus."""
    return slice_bits(bus, 0, ETH_FIELDS_W)


# ---------------------------------------------------------------------------
# Reference model
# ---------------------------------------------------------------------------
def expected_ipv4_fields(frame: bytes, tagged: bool = False) -> dict:
    """
    What ipv4_parser should extract from a complete frame.

    The IPv4 header starts at byte 14 untagged, byte 18 with a single tag.
    """
    off = 18 if tagged else 14
    h = frame[off:off + 20]
    assert len(h) == 20, "frame too short to contain a full IPv4 header"

    ver_ihl = h[0]
    version = ver_ihl >> 4
    ihl = ver_ihl & 0x0F

    flags_frag = int.from_bytes(h[6:8], "big")
    flags = flags_frag >> 13            # reserved, DF, MF
    frag_offset = flags_frag & 0x1FFF
    more_fragments = (flags_frag >> 13) & 0x1

    return {
        "version": version,
        "ihl": ihl,
        "dscp_ecn": h[1],
        "total_length": int.from_bytes(h[2:4], "big"),
        "identification": int.from_bytes(h[4:6], "big"),
        "flags": flags,
        "frag_offset": frag_offset,
        "ttl": h[8],
        "protocol": h[9],
        "header_cksum": int.from_bytes(h[10:12], "big"),
        "src_ip": int.from_bytes(h[12:16], "big"),
        "dst_ip": int.from_bytes(h[16:20], "big"),
        "ihl_invalid": 1 if ihl != 5 else 0,
        "version_invalid": 1 if version != 4 else 0,
        "frag_present": 1 if (more_fragments or frag_offset) else 0,
        "hdr_truncated": 0,
    }
