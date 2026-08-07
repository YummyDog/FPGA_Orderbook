--------------------------------------------------------------------------------
-- mold_parser_pkg
--
-- Field-bus layout for the MoldUDP64 stage of the market-data header parser
-- pipeline.
--
-- Mold fields are appended ABOVE everything received from upstream, so on
-- every bus from this stage onwards:
--
--     bits [129:0]                       Ethernet   (130 bits)
--     bits [293:130]                     IPv4       (164 bits)
--     bits [359:294]                     UDP        ( 66 bits)
--     bits [522:360]                     MoldUDP64  (163 bits)
--                                                   ----------
--                                        total       523 bits
--
-- All upstream accessors keep working unchanged on the wider bus, because no
-- earlier slice ever moves.
--
-- Byte order: multi-byte fields are stored in wire order, first byte on the
-- wire in the most significant position. session(79 downto 72) is the first
-- session byte; sequence_num is a big-endian 64-bit integer.
--
-- NOTE the first ITCH message length (bytes 62-63 untagged) is deliberately
-- NOT carried here. It is an ITCH framing field, and the ITCH parser sees the
-- same beat on its own AXI-Stream input.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;
use work.udp_parser_pkg.all;

package mold_parser_pkg is

  ------------------------------------------------------------------------------
  -- Field widths. The MoldUDP64 downstream header is exactly 160 bits and
  -- every bit is carried, plus 3 informational status bits.
  ------------------------------------------------------------------------------
  constant C_MOLD_SESSION_W : natural := 80;   -- 10 ASCII bytes
  constant C_MOLD_SEQNUM_W  : natural := 64;   -- big-endian, first message
  constant C_MOLD_MSGCNT_W  : natural := 16;

  ------------------------------------------------------------------------------
  -- Offsets WITHIN the Mold slice (use these on the standalone 163-bit vector)
  ------------------------------------------------------------------------------
  constant C_MOLD_SESSION_LOC : natural := 0;
  constant C_MOLD_SEQNUM_LOC  : natural := C_MOLD_SESSION_LOC + C_MOLD_SESSION_W; --  80
  constant C_MOLD_MSGCNT_LOC  : natural := C_MOLD_SEQNUM_LOC  + C_MOLD_SEQNUM_W;  -- 144

  -- Informational status bits. None gate the data path.
  --   heartbeat      : message_count = 0
  --   end_of_session : message_count = 0xFFFF
  --   truncated      : the frame ended before the Mold header completed
  constant C_MOLD_HEARTBEAT_LOC : natural := C_MOLD_MSGCNT_LOC + C_MOLD_MSGCNT_W; -- 160
  constant C_MOLD_EOS_LOC       : natural := C_MOLD_HEARTBEAT_LOC + 1;            -- 161
  constant C_MOLD_TRUNC_LOC     : natural := C_MOLD_EOS_LOC + 1;                  -- 162

  constant C_MOLD_FIELDS_W : natural := C_MOLD_TRUNC_LOC + 1;                     -- 163

  ------------------------------------------------------------------------------
  -- Position of the Mold slice within the chained bus
  ------------------------------------------------------------------------------
  constant C_MOLD_BASE  : natural := C_UDP_BUS_W;                     -- 360
  constant C_MOLD_BUS_W : natural := C_MOLD_BASE + C_MOLD_FIELDS_W;   -- 523

  ------------------------------------------------------------------------------
  -- Accessors. These take the FULL chained bus.
  ------------------------------------------------------------------------------
  function mold_session       (f : std_logic_vector) return std_logic_vector;
  function mold_sequence_num  (f : std_logic_vector) return std_logic_vector;
  function mold_message_count (f : std_logic_vector) return std_logic_vector;

  function mold_heartbeat      (f : std_logic_vector) return std_logic;
  function mold_end_of_session (f : std_logic_vector) return std_logic;
  function mold_hdr_truncated  (f : std_logic_vector) return std_logic;

  -- The Mold slice on its own, for standalone comparison
  function mold_slice (f : std_logic_vector) return std_logic_vector;

end package mold_parser_pkg;


package body mold_parser_pkg is

  function mold_session (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_MOLD_BASE + C_MOLD_SESSION_LOC;
  begin
    return ff(LO + C_MOLD_SESSION_W - 1 downto LO);
  end function;

  function mold_sequence_num (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_MOLD_BASE + C_MOLD_SEQNUM_LOC;
  begin
    return ff(LO + C_MOLD_SEQNUM_W - 1 downto LO);
  end function;

  function mold_message_count (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
    constant LO : natural := C_MOLD_BASE + C_MOLD_MSGCNT_LOC;
  begin
    return ff(LO + C_MOLD_MSGCNT_W - 1 downto LO);
  end function;

  function mold_heartbeat (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_MOLD_BASE + C_MOLD_HEARTBEAT_LOC);
  end function;

  function mold_end_of_session (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_MOLD_BASE + C_MOLD_EOS_LOC);
  end function;

  function mold_hdr_truncated (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_MOLD_BASE + C_MOLD_TRUNC_LOC);
  end function;

  function mold_slice (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_MOLD_BASE + C_MOLD_FIELDS_W - 1 downto C_MOLD_BASE);
  end function;

end package body mold_parser_pkg;
