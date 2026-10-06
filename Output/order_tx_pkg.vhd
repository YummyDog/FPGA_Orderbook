--------------------------------------------------------------------------------
-- order_tx_pkg
--
-- Every field of the outgoing frame that you are expected to edit lives here:
-- MAC addresses, IP addresses, UDP ports, TTL, and the payload layout.
--
-- Derived constants (lengths, padding, the IPv4 header checksum) are computed
-- from those at elaboration, so changing an address or a payload field needs no
-- edit to the RTL.
--
-- Payload layout, as shipped (C_PAYLOAD_BITS = 83):
--   byte 0       "00000" & payload(82 downto 80)
--   bytes 1-10   payload(79 downto 0)  (big endian, network order)
--   bytes 11..   zero padding
--
-- The payload vector is right-justified in the smallest whole number of bytes
-- and sent most significant byte first; the unused high bits of byte 0 are
-- zero.
--
-- Reshape f_payload to change it. The padding keeps the frame at or above the
-- 64-byte minimum and makes its length a multiple of 8, which is what lets the
-- FCS sit in a beat of its own.
--
-- No VLAN tag. The UDP checksum is zero, which IPv4 permits.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package order_tx_pkg is

  type t_bytes is array (natural range <>) of std_logic_vector(7 downto 0);

  ------------------------------------------------------------------------------
  -- EDIT HERE
  ------------------------------------------------------------------------------

  -- Ethernet, byte 0 first on the wire
  constant C_MAC_DST   : t_bytes(0 to 5) := (x"00", x"0A", x"35", x"01", x"02", x"03");
  constant C_MAC_SRC   : t_bytes(0 to 5) := (x"00", x"0A", x"35", x"AA", x"BB", x"CC");

  -- IPv4, byte 0 first on the wire: 192.168.10.20 -> 192.168.10.1
  constant C_IP_SRC    : t_bytes(0 to 3) := (x"C0", x"A8", x"0A", x"14");
  constant C_IP_DST    : t_bytes(0 to 3) := (x"C0", x"A8", x"0A", x"01");

  constant C_IP_TTL    : std_logic_vector(7 downto 0)  := x"40";
  constant C_IP_DSCP   : std_logic_vector(7 downto 0)  := x"00";
  constant C_IP_ID     : std_logic_vector(15 downto 0) := x"0000";
  constant C_IP_FLAGS  : std_logic_vector(15 downto 0) := x"4000";  -- don't fragment

  -- UDP
  constant C_UDP_SPORT : std_logic_vector(15 downto 0) := x"C350";  -- 50000
  constant C_UDP_DPORT : std_logic_vector(15 downto 0) := x"C351";  -- 50001

  -- Width of the payload vector handed to the transmitter
  constant C_PAYLOAD_BITS : positive := 87;

  ------------------------------------------------------------------------------
  -- Derived. Nothing below needs editing.
  ------------------------------------------------------------------------------

  constant C_ETHERTYPE  : std_logic_vector(15 downto 0) := x"0800";

  constant C_ETH_LEN    : natural := 14;
  constant C_IP_LEN     : natural := 20;
  constant C_UDP_LEN    : natural := 8;
  constant C_HDR_LEN    : natural := C_ETH_LEN + C_IP_LEN + C_UDP_LEN;   -- 42

  -- Bytes of payload actually used by f_payload before padding
  constant C_MSG_LEN    : natural := (C_PAYLOAD_BITS + 7) / 8;           -- 11

  -- Payload padded to keep the frame >= 60 bytes before the FCS (so the frame
  -- with FCS is >= 64), and to make the pre-FCS length a multiple of 8.
  constant C_PAYLOAD_MIN : natural := maximum(C_MSG_LEN, 18);
  constant C_PAYLOAD_LEN : natural :=
    C_PAYLOAD_MIN + ((8 - ((C_HDR_LEN + C_PAYLOAD_MIN) mod 8)) mod 8);

  constant C_FRAME_LEN  : natural := C_HDR_LEN + C_PAYLOAD_LEN;  -- without FCS
  constant C_WORDS      : natural := C_FRAME_LEN / 8;

  -- XGMII control characters
  constant C_XGMII_START : std_logic_vector(7 downto 0) := x"FB";
  constant C_XGMII_TERM  : std_logic_vector(7 downto 0) := x"FD";
  constant C_XGMII_IDLE  : std_logic_vector(7 downto 0) := x"07";

  function f_ip_checksum (h : t_bytes) return std_logic_vector;

  function f_payload (payload : std_logic_vector(C_PAYLOAD_BITS - 1 downto 0))
    return t_bytes;

  function f_frame (payload : std_logic_vector(C_PAYLOAD_BITS - 1 downto 0))
    return t_bytes;

end package order_tx_pkg;


package body order_tx_pkg is

  ------------------------------------------------------------------------------
  -- One's complement sum over the header, checksum field already zero.
  ------------------------------------------------------------------------------
  function f_ip_checksum (h : t_bytes) return std_logic_vector is
    variable sum : unsigned(31 downto 0) := (others => '0');
    variable w   : unsigned(15 downto 0);
  begin
    for i in 0 to h'length / 2 - 1 loop
      w   := unsigned(std_logic_vector'(h(h'low + 2 * i) & h(h'low + 2 * i + 1)));
      sum := sum + resize(w, 32);
    end loop;
    while sum(31 downto 16) /= 0 loop
      sum := resize(sum(31 downto 16), 32) + resize(sum(15 downto 0), 32);
    end loop;
    return std_logic_vector(not sum(15 downto 0));
  end function f_ip_checksum;

  ------------------------------------------------------------------------------
  -- Right-justify the payload in C_MSG_LEN bytes, most significant byte first.
  ------------------------------------------------------------------------------
  function f_payload (payload : std_logic_vector(C_PAYLOAD_BITS - 1 downto 0))
    return t_bytes is
    variable p : t_bytes(0 to C_PAYLOAD_LEN - 1) := (others => x"00");
    variable v : std_logic_vector(8 * C_MSG_LEN - 1 downto 0)
               := (others => '0');
  begin
    v(C_PAYLOAD_BITS - 1 downto 0) := payload;
    for i in 0 to C_MSG_LEN - 1 loop
      p(i) := v(8 * (C_MSG_LEN - i) - 1 downto 8 * (C_MSG_LEN - 1 - i));
    end loop;
    return p;
  end function f_payload;

  ------------------------------------------------------------------------------
  function f_frame (payload : std_logic_vector(C_PAYLOAD_BITS - 1 downto 0))
    return t_bytes is
    variable f      : t_bytes(0 to C_FRAME_LEN - 1) := (others => x"00");
    variable ip     : t_bytes(0 to C_IP_LEN - 1)    := (others => x"00");
    variable csum   : std_logic_vector(15 downto 0);
    variable ip_tot : unsigned(15 downto 0);
    variable ud_len : unsigned(15 downto 0);
    variable pl     : t_bytes(0 to C_PAYLOAD_LEN - 1);
  begin
    ip_tot := to_unsigned(C_IP_LEN + C_UDP_LEN + C_PAYLOAD_LEN, 16);
    ud_len := to_unsigned(C_UDP_LEN + C_PAYLOAD_LEN, 16);

    -- Ethernet
    for i in 0 to 5 loop
      f(i)     := C_MAC_DST(i);
      f(6 + i) := C_MAC_SRC(i);
    end loop;
    f(12) := C_ETHERTYPE(15 downto 8);
    f(13) := C_ETHERTYPE(7 downto 0);

    -- IPv4, checksum field left zero for the sum
    ip(0)  := x"45";                       -- version 4, IHL 5
    ip(1)  := C_IP_DSCP;
    ip(2)  := std_logic_vector(ip_tot(15 downto 8));
    ip(3)  := std_logic_vector(ip_tot(7 downto 0));
    ip(4)  := C_IP_ID(15 downto 8);
    ip(5)  := C_IP_ID(7 downto 0);
    ip(6)  := C_IP_FLAGS(15 downto 8);
    ip(7)  := C_IP_FLAGS(7 downto 0);
    ip(8)  := C_IP_TTL;
    ip(9)  := x"11";                       -- protocol 17, UDP
    ip(10) := x"00";
    ip(11) := x"00";
    for i in 0 to 3 loop
      ip(12 + i) := C_IP_SRC(i);
      ip(16 + i) := C_IP_DST(i);
    end loop;

    csum   := f_ip_checksum(ip);
    ip(10) := csum(15 downto 8);
    ip(11) := csum(7 downto 0);

    for i in 0 to C_IP_LEN - 1 loop
      f(C_ETH_LEN + i) := ip(i);
    end loop;

    -- UDP, checksum zero
    f(34) := C_UDP_SPORT(15 downto 8);
    f(35) := C_UDP_SPORT(7 downto 0);
    f(36) := C_UDP_DPORT(15 downto 8);
    f(37) := C_UDP_DPORT(7 downto 0);
    f(38) := std_logic_vector(ud_len(15 downto 8));
    f(39) := std_logic_vector(ud_len(7 downto 0));
    f(40) := x"00";
    f(41) := x"00";

    -- Payload
    pl := f_payload(payload);
    for i in 0 to C_PAYLOAD_LEN - 1 loop
      f(C_HDR_LEN + i) := pl(i);
    end loop;

    return f;
  end function f_frame;

end package body order_tx_pkg;
