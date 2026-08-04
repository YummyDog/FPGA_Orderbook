"""
Frame builder for the market-data header parser testbenches.

Builds Ethernet / IPv4 / UDP / MoldUDP64 / ITCH frames matching the ASX Trade
ITCH multicast feed, and slices them into 64-bit AXI-Stream beats.

Addressing defaults are taken from the ASX Trade Connectivity Guide
(v2.4, March 2026), ITCH ALC Co-Location Production, Channel A Partition 1:

    multicast source IP   203.6.253.124
    multicast group       233.71.185.129
    destination UDP port  21001

The destination MAC is the standard IPv4 multicast mapping of the group
address: 01:00:5E plus the low 23 bits of the group IP.

NOTE: the ITCH message body is a placeholder. Real ASX ITCH message layouts
are specified when the ITCH parser module is built; nothing upstream of it
inspects the body.

No cocotb dependency - importable standalone for stimulus sanity checks.
"""

import struct

# ---------------------------------------------------------------------------
# ASX defaults
# ---------------------------------------------------------------------------
ASX_SRC_IP_A = "203.6.253.124"
ASX_SRC_IP_B = "203.6.253.157"
ASX_GRP_IP = "233.71.185.129"
ASX_DST_PORT = 21001
ASX_SRC_MAC = "00:1b:21:3c:4d:5e"

# Channel A and B, partitions 1..4: (name, source ip, group ip, udp port)
ASX_CHANNELS = [
    ("A1", ASX_SRC_IP_A, "233.71.185.129", 21001),
    ("A2", ASX_SRC_IP_A, "233.71.185.130", 21002),
    ("A3", ASX_SRC_IP_A, "233.71.185.131", 21003),
    ("A4", ASX_SRC_IP_A, "233.71.185.132", 21004),
    ("B1", ASX_SRC_IP_B, "233.71.185.145", 21101),
    ("B2", ASX_SRC_IP_B, "233.71.185.146", 21102),
    ("B3", ASX_SRC_IP_B, "233.71.185.147", 21103),
    ("B4", ASX_SRC_IP_B, "233.71.185.148", 21104),
]

ETHERTYPE_IPV4 = 0x0800
ETHERTYPE_ARP = 0x0806
ETHERTYPE_IPV6 = 0x86DD
TPID_8021Q = 0x8100
TPID_8021AD = 0x88A8
IP_PROTO_UDP = 0x11


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def mac_to_bytes(mac: str) -> bytes:
    return bytes(int(b, 16) for b in mac.split(":"))


def ip_to_bytes(ip: str) -> bytes:
    return bytes(int(b) for b in ip.split("."))


def multicast_mac_for(group_ip: str) -> str:
    """IPv4 multicast -> Ethernet MAC mapping (RFC 1112 section 6.4)."""
    o = [int(b) for b in group_ip.split(".")]
    return "01:00:5e:%02x:%02x:%02x" % (o[1] & 0x7F, o[2], o[3])


def ipv4_checksum(header: bytes) -> int:
    total = 0
    for i in range(0, len(header), 2):
        total += (header[i] << 8) | header[i + 1]
    while total >> 16:
        total = (total & 0xFFFF) + (total >> 16)
    return (~total) & 0xFFFF


def make_tci(pcp: int = 0, dei: int = 0, vid: int = 0) -> int:
    return ((pcp & 0x7) << 13) | ((dei & 0x1) << 12) | (vid & 0xFFF)


# ---------------------------------------------------------------------------
# Frame construction
# ---------------------------------------------------------------------------
def build_frame(
    dst_mac: str = None,
    src_mac: str = ASX_SRC_MAC,
    vlan_vid: int = None,          # None -> untagged
    vlan_pcp: int = 0,
    vlan_dei: int = 0,
    tpid: int = TPID_8021Q,
    src_ip: str = ASX_SRC_IP_A,
    dst_ip: str = ASX_GRP_IP,
    ip_id: int = 0x1234,
    ip_ttl: int = 64,
    ip_dscp_ecn: int = 0x00,
    ip_flags_frag: int = 0x4000,   # DF
    ihl: int = 5,
    udp_src_port: int = 50000,
    udp_dst_port: int = ASX_DST_PORT,
    mold_session: bytes = b"ASX0000001",   # 10 bytes
    mold_seqnum: int = 1,
    mold_msg_count: int = 1,
    itch_msg: bytes = None,
    ethertype: int = ETHERTYPE_IPV4,
) -> bytes:
    """Build one complete frame. Returns raw bytes in wire order."""

    if dst_mac is None:
        dst_mac = multicast_mac_for(dst_ip)

    if itch_msg is None:
        itch_msg = b"A" + bytes(range(19))     # placeholder 20-byte body

    assert len(mold_session) == 10, "MoldUDP64 session is 10 bytes"

    # --- MoldUDP64 downstream packet -------------------------------------
    mold = mold_session
    mold += struct.pack(">Q", mold_seqnum)
    mold += struct.pack(">H", mold_msg_count)
    mold += struct.pack(">H", len(itch_msg))
    mold += itch_msg

    # --- UDP --------------------------------------------------------------
    udp_len = 8 + len(mold)
    udp = struct.pack(">HHHH", udp_src_port, udp_dst_port, udp_len, 0x0000)
    udp += mold

    # --- IPv4 -------------------------------------------------------------
    ip_total_len = (ihl * 4) + len(udp)
    ip_hdr = struct.pack(
        ">BBHHHBBH",
        (4 << 4) | ihl,
        ip_dscp_ecn,
        ip_total_len,
        ip_id,
        ip_flags_frag,
        ip_ttl,
        IP_PROTO_UDP,
        0x0000,
    )
    ip_hdr += ip_to_bytes(src_ip) + ip_to_bytes(dst_ip)
    ip_hdr += bytes((ihl - 5) * 4)

    csum = ipv4_checksum(ip_hdr)
    ip_hdr = ip_hdr[:10] + struct.pack(">H", csum) + ip_hdr[12:]

    # --- Ethernet ---------------------------------------------------------
    eth = mac_to_bytes(dst_mac) + mac_to_bytes(src_mac)
    if vlan_vid is not None:
        eth += struct.pack(">HH", tpid, make_tci(vlan_pcp, vlan_dei, vlan_vid))
    eth += struct.pack(">H", ethertype)

    return eth + ip_hdr + udp


def truncate(frame: bytes, nbytes: int) -> bytes:
    """Cut a frame short, to exercise the informational truncation status."""
    assert nbytes <= len(frame)
    return frame[:nbytes]


# ---------------------------------------------------------------------------
# AXI-Stream slicing
# ---------------------------------------------------------------------------
def to_beats(frame: bytes, width_bytes: int = 8):
    """
    Slice a frame into AXI-Stream beats.

    Byte 0 of the frame (first on the wire) maps to tdata(7 downto 0), so a
    beat is assembled little-endian across the lanes.

    Returns a list of (tdata_int, tkeep_int, tlast_bool).
    """
    beats = []
    for off in range(0, len(frame), width_bytes):
        chunk = frame[off:off + width_bytes]
        tdata = int.from_bytes(chunk.ljust(width_bytes, b"\x00"), "little")
        tkeep = (1 << len(chunk)) - 1
        tlast = (off + width_bytes) >= len(frame)
        beats.append((tdata, tkeep, tlast))
    return beats


# ---------------------------------------------------------------------------
# Reference model
# ---------------------------------------------------------------------------
def expected_eth_fields(frame: bytes, vlan_vid: int = None,
                        vlan_pcp: int = 0, vlan_dei: int = 0,
                        tagged: bool = None):
    """
    The Ethernet fields eth_parser should extract from a complete frame.

    `tagged` defaults to (vlan_vid is not None). Pass it explicitly when the
    frame carries a tag the DUT is not configured to recognise - e.g. an
    0x88A8 S-tag while G_TPID is 0x8100 - since the parser will then treat
    the TPID as the ethertype and ignore the TCI.
    """
    if tagged is None:
        tagged = vlan_vid is not None

    dst_mac = int.from_bytes(frame[0:6], "big")
    src_mac = int.from_bytes(frame[6:12], "big")

    if not tagged:
        return {
            "dst_mac": dst_mac,
            "src_mac": src_mac,
            "ethertype": int.from_bytes(frame[12:14], "big"),
            "vlan_present": 0,
            "vlan_tci": 0,
            "hdr_truncated": 0,
        }

    return {
        "dst_mac": dst_mac,
        "src_mac": src_mac,
        "ethertype": int.from_bytes(frame[16:18], "big"),
        "vlan_present": 1,
        "vlan_tci": make_tci(vlan_pcp, vlan_dei, vlan_vid),
        "hdr_truncated": 0,
    }
