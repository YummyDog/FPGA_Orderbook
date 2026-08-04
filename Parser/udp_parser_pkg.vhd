--------------------------------------------------------------------------------
-- udp_parser_pkg
--
-- Field-bus layout for the UDP stage of the market-data header parser
-- pipeline.
--
-- UDP fields are appended ABOVE everything received from upstream, so on
-- every bus from this stage onwards:
--
--     bits [129:0]                       Ethernet   (130 bits)
--     bits [293:130]                     IPv4       (164 bits)
--     bits [359:294]                     UDP        ( 66 bits)
--                                                   ----------
--                                        total       360 bits
--
-- Ethernet and IPv4 accessors keep working unchanged on the wider bus,
-- because neither slice ever moves.
--
-- Byte order: multi-byte fields are stored in wire order, first byte on the
-- wire in the most significant position.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;

package udp_parser_pkg is

  ------------------------------------------------------------------------------
  -- Field widths. The UDP header is exactly 64 bits and every bit is carried,
  -- plus 2 informational status bits.
  ------------------------------------------------------------------------------
  constant C_UDP_SRCPORT_W : natural := 16;
  constant C_UDP_DSTPORT_W : natural := 16;
  constant C_UDP_LENGTH_W  : natural := 16;
  constant C_UDP_CKSUM_W   : natural := 16;

  ------------------------------------------------------------------------------
  -- Offsets WITHIN the UDP slice (use these on the standalone 66-bit vector)
  ------------------------------------------------------------------------------
  constant C_UDP_SRCPORT_LOC : natural := 0;
  constant C_UDP_DSTPORT_LOC : natural := C_UDP_SRCPORT_LOC + C_UDP_SRCPORT_W; -- 16
  constant C_UDP_LENGTH_LOC  : natural := C_UDP_DSTPORT_LOC + C_UDP_DSTPORT_W; -- 32
  constant C_UDP_CKSUM_LOC   : natural := C_UDP_LENGTH_LOC  + C_UDP_LENGTH_W;  -- 48

  -- Informational status bits. Neither gates the data path.
  --   len_invalid : udp_length < 8, i.e. shorter than the header itself
  --   truncated   : the frame ended before the UDP header completed
  constant C_UDP_LEN_INVALID_LOC : natural := C_UDP_CKSUM_LOC + C_UDP_CKSUM_W;  -- 64
  constant C_UDP_TRUNC_LOC       : natural := C_UDP_LEN_INVALID_LOC + 1;        -- 65

  constant C_UDP_FIELDS_W : natural := C_UDP_TRUNC_LOC + 1;                     -- 66

  ------------------------------------------------------------------------------
  -- Position of the UDP slice within the chained bus
  ------------------------------------------------------------------------------
  constant C_UDP_BASE  : natural := C_IPV4_BUS_W;                    -- 294
  constant C_UDP_BUS_W : natural := C_UDP_BASE + C_UDP_FIELDS_W;     -- 360

  ------------------------------------------------------------------------------
  -- Accessors. These take the FULL chained bus.
  ------------------------------------------------------------------------------
  function udp_src_port  (f : std_logic_vector) return std_logic_vector;
  function udp_dst_port  (f : std_logic_vector) return std_logic_vector;
  function udp_length    (f : std_logic_vector) return std_logic_vector;
  function udp_checksum  (f : std_logic_vector) return std_logic_vector;

  function udp_len_invalid   (f : std_logic_vector) return std_logic;
  function udp_hdr_truncated (f : std_logic_vector) return std_logic;

  -- The UDP slice on its own, for standalone comparison
  function udp_slice (f : std_logic_vector) return std_logic_vector;

end package udp_parser_pkg;


package body udp_parser_pkg is

  function udp_src_port (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_UDP_BASE + C_UDP_SRCPORT_LOC;
  begin
    return ff(LO + C_UDP_SRCPORT_W - 1 downto LO);
  end function;

  function udp_dst_port (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_UDP_BASE + C_UDP_DSTPORT_LOC;
  begin
    return ff(LO + C_UDP_DSTPORT_W - 1 downto LO);
  end function;

  function udp_length (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_UDP_BASE + C_UDP_LENGTH_LOC;
  begin
    return ff(LO + C_UDP_LENGTH_W - 1 downto LO);
  end function;

  function udp_checksum (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_UDP_BASE + C_UDP_CKSUM_LOC;
  begin
    return ff(LO + C_UDP_CKSUM_W - 1 downto LO);
  end function;

  function udp_len_invalid (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_UDP_BASE + C_UDP_LEN_INVALID_LOC);
  end function;

  function udp_hdr_truncated (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_UDP_BASE + C_UDP_TRUNC_LOC);
  end function;

  function udp_slice (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_UDP_BASE + C_UDP_FIELDS_W - 1 downto C_UDP_BASE);
  end function;

end package body udp_parser_pkg;
