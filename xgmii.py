"""
XGMII wire encoding for the market_data_top testbenches.

Takes the Ethernet frames asx_packets builds and presents them the way the
PCS does: 64-bit XGMII with lane 0 in bits 7:0, a control bit per lane.

    IDLE   0x07 in every lane, rxc = 0xFF
    /S/    0xFB in lane 0 (control), 0x55 in lanes 1-6, 0xD5 in lane 7,
           rxc = 0x01  - preamble and SFD share the start word
    data   eight payload bytes, rxc = 0x00
    /T/    the tail bytes in lanes 0..r-1, 0xFD in lane r, IDLE above,
           rxc = bits r..7 set

Both xgmii64_to_axis and xgmii_crc32_rx64 assume /S/ is always in lane 0, so
every frame starts 8-byte aligned and the tail length alone decides where
/T/ lands.

THE FCS MATTERS NOW. order_fifo gates commands on the FCS verdict, so a
frame with a wrong CRC produces no command at all. append_fcs() computes the
standard Ethernet FCS - zlib.crc32 over the frame, appended least
significant byte first - which is what drives xgmii_crc32_rx64's register to
its residue of 0xDEBB20E3.

No cocotb dependency - importable standalone. Run it directly for a
self-check on the encoding.
"""

import zlib

# ---------------------------------------------------------------------------
# XGMII control characters
# ---------------------------------------------------------------------------
IDLE = 0x07
START = 0xFB
TERM = 0xFD
PREAMBLE = 0x55
SFD = 0xD5

IDLE_RXD = int.from_bytes(bytes([IDLE] * 8), "little")
IDLE_RXC = 0xFF

# xgmii_crc32_rx64 only accepts a frame once it has seen eight full data
# beats before /T/ (cnt(3) in stage1), which is the 64-byte Ethernet minimum.
MIN_FRAME_BYTES = 64

# The CRC register's value after a good frame plus its FCS, from the RTL.
CRC_RESIDUE = 0xDEBB20E3


# ---------------------------------------------------------------------------
# FCS
# ---------------------------------------------------------------------------
def fcs(frame: bytes) -> bytes:
    """The four FCS bytes for a frame, in wire order (least significant first)."""
    return (zlib.crc32(frame) & 0xFFFFFFFF).to_bytes(4, "little")


def append_fcs(frame: bytes) -> bytes:
    """Frame with a correct FCS, padded to the 64-byte minimum first."""
    if len(frame) < MIN_FRAME_BYTES - 4:
        frame = frame + bytes(MIN_FRAME_BYTES - 4 - len(frame))
    return frame + fcs(frame)


def append_bad_fcs(frame: bytes, flip: int = 0) -> bytes:
    """
    Frame with a deliberately wrong FCS.

    Not used by the current tests - every frame they send is good - but the
    gate in order_fifo only has one side exercised without it, so it is here
    for when that changes.
    """
    good = bytearray(append_fcs(frame))
    good[-1] ^= (1 << (flip & 7))
    return bytes(good)


# ---------------------------------------------------------------------------
# Beat construction
# ---------------------------------------------------------------------------
def _beat(lanes) -> int:
    """Eight lane bytes to a 64-bit word. Lane 0 is bits 7:0."""
    return int.from_bytes(bytes(lanes), "little")


def idle_beats(n: int = 1):
    return [(IDLE_RXD, IDLE_RXC) for _ in range(n)]


def start_beat():
    """/S/ plus the six preamble bytes and the SFD, all in one word."""
    return (_beat([START] + [PREAMBLE] * 6 + [SFD]), 0x01)


def to_xgmii(frame: bytes, idle_before: int = 1, add_fcs: bool = True):
    """
    One framed packet as XGMII beats.

    Returns a list of (rxd, rxc). idle_before is the number of IDLE beats
    emitted ahead of /S/; one is the tightest spacing the receiver accepts
    while still keeping /S/ in lane 0, and is well under a real inter-packet
    gap.
    """
    wire = append_fcs(frame) if add_fcs else frame

    beats = idle_beats(idle_before)
    beats.append(start_beat())

    full, tail = divmod(len(wire), 8)
    for k in range(full):
        beats.append((_beat(wire[8 * k:8 * k + 8]), 0x00))

    # The terminate word: whatever is left, then /T/, then idles.
    lanes = list(wire[8 * full:]) + [TERM] + [IDLE] * (7 - tail)
    rxc = (0xFF << tail) & 0xFF            # /T/ and every lane above it
    beats.append((_beat(lanes), rxc))

    return beats


def stream(frames, gap: int = 0, lead_idle: int = 4):
    """
    Several frames as one continuous XGMII beat list.

    gap is EXTRA idle beats between frames, on top of the single idle beat
    every frame already carries - so gap=0 is back to back, the next /S/
    landing on the beat after the previous /T/ word.
    """
    out = list(idle_beats(lead_idle))
    for n, f in enumerate(frames):
        out += to_xgmii(f, idle_before=(1 + gap) if n else 1)
    return out


# ---------------------------------------------------------------------------
# Decoder - a Python model of what the RTL should make of these beats.
#
# It exists to prove the encoder emits what it claims, not to judge the
# design. Nothing in the tests compares the DUT against it.
# ---------------------------------------------------------------------------
POLY = 0xEDB88320


def crc_upd(crc: int, data: bytes) -> int:
    """Reflected CRC32 update, LSB of each byte first. Mirrors crc_upd()."""
    c = crc
    for b in data:
        for i in range(8):
            fb = (c ^ (b >> i)) & 1
            c = (c >> 1) ^ (POLY if fb else 0)
    return c


def decode(beats):
    """
    Pull frames back out of a beat list.

    Returns a list of dicts: the bytes carried, whether the preamble/SFD word
    was well formed, the number of full data beats, and whether the CRC
    register reaches the residue.
    """
    frames, cur = [], None

    for rxd, rxc in beats:
        lanes = rxd.to_bytes(8, "little")

        if rxc & 1 and lanes[0] == START:
            cur = {"data": bytearray(), "beats": 0,
                   "pre_ok": (rxc & 0xFE) == 0
                             and list(lanes[1:7]) == [PREAMBLE] * 6
                             and lanes[7] == SFD}
            continue

        if cur is None:
            continue

        term = next((i for i in range(8)
                     if (rxc >> i) & 1 and lanes[i] == TERM), None)
        if term is not None:
            cur["data"] += lanes[:term]
            cur["residue_ok"] = crc_upd(0xFFFFFFFF,
                                        bytes(cur["data"])) == CRC_RESIDUE
            cur["long_enough"] = cur["beats"] >= 8
            frames.append(cur)
            cur = None
        elif rxc == 0:
            cur["data"] += lanes
            cur["beats"] += 1

    return frames


# ---------------------------------------------------------------------------
# Self-check
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import asx_packets as pkt
    import book_model as bm

    msgs = {"A": bm.build_add(1, qty=100, price=50000),
            "D": bm.build_delete(1),
            "E": bm.build_exec(1, qty=50)}

    print(f"{'msg':>4} {'frame':>6} {'wire':>6} {'beats':>6} {'T lane':>7} "
          f"{'pre':>6} {'len':>6} {'crc':>6}")
    for name, m in msgs.items():
        frame = pkt.build_frame(itch_msg=m, mold_seqnum=1, mold_msg_count=1)
        beats = to_xgmii(frame)
        d = decode(beats)[0]
        wire = append_fcs(frame)
        assert bytes(d["data"]) == wire, f"{name}: payload round-trip failed"
        print(f"{name:>4} {len(frame):>6} {len(wire):>6} {len(beats):>6} "
              f"{len(wire) % 8:>7} {str(d['pre_ok']):>6} "
              f"{str(d['long_enough']):>6} {str(d['residue_ok']):>6}")

    frame = pkt.build_frame(itch_msg=msgs["A"], mold_seqnum=1, mold_msg_count=1)
    bad = decode(to_xgmii(append_bad_fcs(frame), add_fcs=False))[0]
    print("\ncorrupt frame residue_ok:", bad["residue_ok"], "(must be False)")

    multi = stream([frame] * 3, gap=0)
    print("three frames back to back:", len(decode(multi)), "decoded,",
          len(multi), "beats")
