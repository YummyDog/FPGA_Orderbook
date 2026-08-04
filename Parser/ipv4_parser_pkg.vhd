--------------------------------------------------------------------------------
-- ipv4_parser_pkg
--
-- Field-bus layout for the IPv4 stage of the market-data header parser
-- pipeline.
--
-- The IPv4 fields are appended ABOVE the Ethernet fields received from
-- upstream, so on every bus in the chain:
--
--     bits [C_ETH_FIELDS_W-1 : 0]                    Ethernet   (130 bits)
--     bits [C_IPV4_BUS_W-1 : C_IPV4_BASE]            IPv4       (164 bits)
--
-- Ethernet accessors from eth_parser_pkg keep working unchanged on the wider
-- bus, because the Ethernet slice never moves.
--
-- Byte order: all multi-byte fields are stored in wire order, first byte on
-- the wire in the most significant position. src_ip(31 downto 24) is the
-- first byte of the source address.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.eth_parser_pkg.all;

package ipv4_parser_pkg is

  ------------------------------------------------------------------------------
  -- Field widths. The IPv4 header is exactly 160 bits and every bit of it is
  -- carried, plus 4 informational status bits.
  ------------------------------------------------------------------------------
  constant C_IP_VERSION_W      : natural := 4;
  constant C_IP_IHL_W          : natural := 4;
  constant C_IP_DSCPECN_W      : natural := 8;
  constant C_IP_TOTLEN_W       : natural := 16;
  constant C_IP_ID_W           : natural := 16;
  constant C_IP_FLAGS_W        : natural := 3;
  constant C_IP_FRAGOFF_W      : natural := 13;
  constant C_IP_TTL_W          : natural := 8;
  constant C_IP_PROTO_W        : natural := 8;
  constant C_IP_CKSUM_W        : natural := 16;
  constant C_IP_SRCIP_W        : natural := 32;
  constant C_IP_DSTIP_W        : natural := 32;

  ------------------------------------------------------------------------------
  -- Offsets WITHIN the IPv4 slice (use these on the standalone 164-bit vector)
  ------------------------------------------------------------------------------
  constant C_IP_VERSION_LOC : natural := 0;
  constant C_IP_IHL_LOC     : natural := C_IP_VERSION_LOC + C_IP_VERSION_W;  --   4
  constant C_IP_DSCPECN_LOC : natural := C_IP_IHL_LOC     + C_IP_IHL_W;      --   8
  constant C_IP_TOTLEN_LOC  : natural := C_IP_DSCPECN_LOC + C_IP_DSCPECN_W;  --  16
  constant C_IP_ID_LOC      : natural := C_IP_TOTLEN_LOC  + C_IP_TOTLEN_W;   --  32
  constant C_IP_FLAGS_LOC   : natural := C_IP_ID_LOC      + C_IP_ID_W;       --  48
  constant C_IP_FRAGOFF_LOC : natural := C_IP_FLAGS_LOC   + C_IP_FLAGS_W;    --  51
  constant C_IP_TTL_LOC     : natural := C_IP_FRAGOFF_LOC + C_IP_FRAGOFF_W;  --  64
  constant C_IP_PROTO_LOC   : natural := C_IP_TTL_LOC     + C_IP_TTL_W;      --  72
  constant C_IP_CKSUM_LOC   : natural := C_IP_PROTO_LOC   + C_IP_PROTO_W;    --  80
  constant C_IP_SRCIP_LOC   : natural := C_IP_CKSUM_LOC   + C_IP_CKSUM_W;    --  96
  constant C_IP_DSTIP_LOC   : natural := C_IP_SRCIP_LOC   + C_IP_SRCIP_W;    -- 128

  -- Informational status bits. None of these gate the data path.
  constant C_IP_IHL_INVALID_LOC  : natural := C_IP_DSTIP_LOC + C_IP_DSTIP_W; -- 160
  constant C_IP_VER_INVALID_LOC  : natural := C_IP_IHL_INVALID_LOC  + 1;     -- 161
  constant C_IP_FRAG_PRESENT_LOC : natural := C_IP_VER_INVALID_LOC  + 1;     -- 162
  constant C_IP_TRUNC_LOC        : natural := C_IP_FRAG_PRESENT_LOC + 1;     -- 163

  constant C_IPV4_FIELDS_W : natural := C_IP_TRUNC_LOC + 1;                  -- 164

  ------------------------------------------------------------------------------
  -- Position of the IPv4 slice within the chained bus
  ------------------------------------------------------------------------------
  constant C_IPV4_BASE  : natural := C_ETH_FIELDS_W;                         -- 130
  constant C_IPV4_BUS_W : natural := C_IPV4_BASE + C_IPV4_FIELDS_W;          -- 294

  ------------------------------------------------------------------------------
  -- Accessors. These take the FULL chained bus.
  ------------------------------------------------------------------------------
  function ip_version       (f : std_logic_vector) return std_logic_vector;
  function ip_ihl           (f : std_logic_vector) return std_logic_vector;
  function ip_dscp_ecn      (f : std_logic_vector) return std_logic_vector;
  function ip_total_length  (f : std_logic_vector) return std_logic_vector;
  function ip_identification(f : std_logic_vector) return std_logic_vector;
  function ip_flags         (f : std_logic_vector) return std_logic_vector;
  function ip_frag_offset   (f : std_logic_vector) return std_logic_vector;
  function ip_ttl           (f : std_logic_vector) return std_logic_vector;
  function ip_protocol      (f : std_logic_vector) return std_logic_vector;
  function ip_header_cksum  (f : std_logic_vector) return std_logic_vector;
  function ip_src_ip        (f : std_logic_vector) return std_logic_vector;
  function ip_dst_ip        (f : std_logic_vector) return std_logic_vector;

  function ip_ihl_invalid    (f : std_logic_vector) return std_logic;
  function ip_version_invalid(f : std_logic_vector) return std_logic;
  function ip_frag_present   (f : std_logic_vector) return std_logic;
  function ip_hdr_truncated  (f : std_logic_vector) return std_logic;

  -- The IPv4 slice on its own, for standalone comparison
  function ipv4_slice (f : std_logic_vector) return std_logic_vector;

  -- boolean -> std_logic, for registering status bits at capture time
  function to_sl (b : boolean) return std_logic;

end package ipv4_parser_pkg;


package body ipv4_parser_pkg is

  function to_sl (b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end function;

  function ip_version (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_VERSION_LOC;
  begin
    return ff(LO + C_IP_VERSION_W - 1 downto LO);
  end function;

  function ip_ihl (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_IHL_LOC;
  begin
    return ff(LO + C_IP_IHL_W - 1 downto LO);
  end function;

  function ip_dscp_ecn (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_DSCPECN_LOC;
  begin
    return ff(LO + C_IP_DSCPECN_W - 1 downto LO);
  end function;

  function ip_total_length (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_TOTLEN_LOC;
  begin
    return ff(LO + C_IP_TOTLEN_W - 1 downto LO);
  end function;

  function ip_identification (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_ID_LOC;
  begin
    return ff(LO + C_IP_ID_W - 1 downto LO);
  end function;

  function ip_flags (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_FLAGS_LOC;
  begin
    return ff(LO + C_IP_FLAGS_W - 1 downto LO);
  end function;

  function ip_frag_offset (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_FRAGOFF_LOC;
  begin
    return ff(LO + C_IP_FRAGOFF_W - 1 downto LO);
  end function;

  function ip_ttl (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_TTL_LOC;
  begin
    return ff(LO + C_IP_TTL_W - 1 downto LO);
  end function;

  function ip_protocol (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_PROTO_LOC;
  begin
    return ff(LO + C_IP_PROTO_W - 1 downto LO);
  end function;

  function ip_header_cksum (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_CKSUM_LOC;
  begin
    return ff(LO + C_IP_CKSUM_W - 1 downto LO);
  end function;

  function ip_src_ip (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_SRCIP_LOC;
  begin
    return ff(LO + C_IP_SRCIP_W - 1 downto LO);
  end function;

  function ip_dst_ip (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_IPV4_BASE + C_IP_DSTIP_LOC;
  begin
    return ff(LO + C_IP_DSTIP_W - 1 downto LO);
  end function;

  function ip_ihl_invalid (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_IPV4_BASE + C_IP_IHL_INVALID_LOC);
  end function;

  function ip_version_invalid (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_IPV4_BASE + C_IP_VER_INVALID_LOC);
  end function;

  function ip_frag_present (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_IPV4_BASE + C_IP_FRAG_PRESENT_LOC);
  end function;

  function ip_hdr_truncated (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_IPV4_BASE + C_IP_TRUNC_LOC);
  end function;

  function ipv4_slice (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_IPV4_BASE + C_IPV4_FIELDS_W - 1 downto C_IPV4_BASE);
  end function;

end package body ipv4_parser_pkg;
