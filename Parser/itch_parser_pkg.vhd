--------------------------------------------------------------------------------
-- itch_parser_pkg
--
-- Output definitions for the ASX ITCH parser (stage 5).
--
-- This stage BREAKS the common skeleton: it emits N events per packet, one
-- per message, rather than one field bus alongside tlast. The accumulated
-- 523-bit upstream bus is re-presented with every event so a downstream
-- checker still sees the full Ethernet/IPv4/UDP/Mold context per message.
--
-- msg_fields is a 512-bit union of the seven order-book message types
-- (A F E C U D P). Reference data (R, M, L) and the state/event types
-- (S, O, Z) are reported by type and length only - decoding them would push
-- the union past 2000 bits for start-of-day data that is not latency
-- critical, and the AXI-Stream passthrough still carries their bytes.
--
-- Field lengths are from the ASX Trade ITCH Specification v3.4 (May 2026).
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mold_parser_pkg.all;

package itch_parser_pkg is

  ------------------------------------------------------------------------------
  -- Upstream context, carried with every event
  ------------------------------------------------------------------------------
  constant C_ITCH_PKT_W : natural := C_MOLD_BUS_W;                 -- 523

  ------------------------------------------------------------------------------
  -- Message assembly buffer.
  --
  -- 64 bytes. The largest DECODED message is C at 58 bytes; R (113) and
  -- M (261) are framed and counted but never assembled, so the buffer does
  -- not need to hold them.
  ------------------------------------------------------------------------------
  constant C_MSG_BUF_BYTES : natural := 64;
  constant C_MSG_BUF_W     : natural := C_MSG_BUF_BYTES * 8;       -- 512

  ------------------------------------------------------------------------------
  -- msg_fields layout - 512 bits
  ------------------------------------------------------------------------------
  constant C_FLD_TS_NS_LO   : natural := 0;    constant C_FLD_TS_NS_W   : natural := 32;
  constant C_FLD_ORDID_LO   : natural := 32;   constant C_FLD_ORDID_W   : natural := 64;
  constant C_FLD_BOOKID_LO  : natural := 96;   constant C_FLD_BOOKID_W  : natural := 32;
  constant C_FLD_SIDE_LO    : natural := 128;  constant C_FLD_SIDE_W    : natural := 8;
  constant C_FLD_POS_LO     : natural := 136;  constant C_FLD_POS_W     : natural := 32;
  constant C_FLD_QTY_LO     : natural := 168;  constant C_FLD_QTY_W     : natural := 64;
  constant C_FLD_PRICE_LO   : natural := 232;  constant C_FLD_PRICE_W   : natural := 32;
  constant C_FLD_EXTYPE_LO  : natural := 264;  constant C_FLD_EXTYPE_W  : natural := 16;
  constant C_FLD_LOT_LO     : natural := 280;  constant C_FLD_LOT_W     : natural := 8;
  constant C_FLD_MATCHID_LO : natural := 288;  constant C_FLD_MATCHID_W : natural := 96;
  constant C_FLD_POWNER_LO  : natural := 384;  constant C_FLD_POWNER_W  : natural := 56;
  constant C_FLD_PCP_LO     : natural := 440;  constant C_FLD_PCP_W     : natural := 56;
  constant C_FLD_PRINT_LO   : natural := 496;  constant C_FLD_PRINT_W   : natural := 8;
  constant C_FLD_CROSS_LO   : natural := 504;  constant C_FLD_CROSS_W   : natural := 8;

  constant C_MSG_FIELDS_W : natural := 512;

  ------------------------------------------------------------------------------
  -- msg_status - informational only, gates nothing
  ------------------------------------------------------------------------------
  constant C_ST_DECODED        : natural := 0;  -- msg_fields is valid
  constant C_ST_LEN_MISMATCH   : natural := 1;  -- length /= the type's spec length
  constant C_ST_MSG_TRUNCATED  : natural := 2;  -- message ran past the packet end
  constant C_ST_UNKNOWN_TYPE   : natural := 3;  -- type byte not in the table
  constant C_ST_COUNT_MISMATCH : natural := 4;  -- framed count /= mold message_count
  constant C_ST_MULTI_COMPLETE : natural := 5;  -- two emitting messages in one beat

  constant C_MSG_STATUS_W : natural := 6;

  ------------------------------------------------------------------------------
  -- Message type codes (ASCII)
  ------------------------------------------------------------------------------
  constant C_TYPE_T : std_logic_vector(7 downto 0) := x"54";  -- Seconds
  constant C_TYPE_S : std_logic_vector(7 downto 0) := x"53";  -- System Event
  constant C_TYPE_R : std_logic_vector(7 downto 0) := x"52";  -- Order Book Dir
  constant C_TYPE_M : std_logic_vector(7 downto 0) := x"4D";  -- Combination Dir
  constant C_TYPE_L : std_logic_vector(7 downto 0) := x"4C";  -- Tick Size
  constant C_TYPE_O : std_logic_vector(7 downto 0) := x"4F";  -- Order Book State
  constant C_TYPE_A : std_logic_vector(7 downto 0) := x"41";  -- Add Order
  constant C_TYPE_F : std_logic_vector(7 downto 0) := x"46";  -- Add Order + PID
  constant C_TYPE_E : std_logic_vector(7 downto 0) := x"45";  -- Order Executed
  constant C_TYPE_C : std_logic_vector(7 downto 0) := x"43";  -- Order Exec Price
  constant C_TYPE_U : std_logic_vector(7 downto 0) := x"55";  -- Order Replace
  constant C_TYPE_D : std_logic_vector(7 downto 0) := x"44";  -- Order Delete
  constant C_TYPE_P : std_logic_vector(7 downto 0) := x"50";  -- Trade
  constant C_TYPE_Z : std_logic_vector(7 downto 0) := x"5A";  -- Equilibrium

  ------------------------------------------------------------------------------
  -- Helpers
  ------------------------------------------------------------------------------
  function mb (buf : std_logic_vector; i : natural) return std_logic_vector;
  function spec_msg_len (t : std_logic_vector(7 downto 0)) return natural;
  function is_decoded_type (t : std_logic_vector(7 downto 0)) return boolean;

  function decode_msg (buf : std_logic_vector;
                       t   : std_logic_vector(7 downto 0))
    return std_logic_vector;

  -- Accessors on msg_fields
  function itch_order_id      (f : std_logic_vector) return std_logic_vector;
  function itch_order_book_id (f : std_logic_vector) return std_logic_vector;
  function itch_side          (f : std_logic_vector) return std_logic_vector;
  function itch_quantity      (f : std_logic_vector) return std_logic_vector;
  function itch_price         (f : std_logic_vector) return std_logic_vector;
  function itch_position      (f : std_logic_vector) return std_logic_vector;
  function itch_match_id      (f : std_logic_vector) return std_logic_vector;
  function itch_timestamp_ns  (f : std_logic_vector) return std_logic_vector;

end package itch_parser_pkg;


package body itch_parser_pkg is

  function mb (buf : std_logic_vector; i : natural) return std_logic_vector is
    alias bb : std_logic_vector(buf'length-1 downto 0) is buf;
  begin
    return bb(8*i + 7 downto 8*i);
  end function;

  function spec_msg_len (t : std_logic_vector(7 downto 0)) return natural is
  begin
    case t is
      when C_TYPE_T => return 5;
      when C_TYPE_S => return 6;
      when C_TYPE_D => return 18;
      when C_TYPE_L => return 25;
      when C_TYPE_O => return 29;
      when C_TYPE_U => return 36;
      when C_TYPE_A => return 37;
      when C_TYPE_F => return 44;
      when C_TYPE_P => return 50;
      when C_TYPE_E => return 52;
      when C_TYPE_Z => return 53;
      when C_TYPE_C => return 58;
      when C_TYPE_R => return 113;
      when C_TYPE_M => return 261;
      when others   => return 0;
    end case;
  end function;

  function is_decoded_type (t : std_logic_vector(7 downto 0)) return boolean is
  begin
    return t = C_TYPE_A or t = C_TYPE_F or t = C_TYPE_E or t = C_TYPE_C or
           t = C_TYPE_U or t = C_TYPE_D or t = C_TYPE_P;
  end function;

  ------------------------------------------------------------------------------
  -- Fixed-offset decode.
  --
  -- Once framing has located a message, every field sits at a compile-time
  -- offset relative to its start - the same problem the four header parsers
  -- already solve. All the difficulty is upstream in the framing.
  ------------------------------------------------------------------------------
  function decode_msg (buf : std_logic_vector;
                       t   : std_logic_vector(7 downto 0))
    return std_logic_vector is
    variable f : std_logic_vector(C_MSG_FIELDS_W-1 downto 0)
               := (others => '0');
  begin
    -- Timestamp-nanoseconds is bytes 1..4 in every decoded type
    f(C_FLD_TS_NS_LO + 31 downto C_FLD_TS_NS_LO) :=
      mb(buf,1) & mb(buf,2) & mb(buf,3) & mb(buf,4);

    case t is

      -- A: Add Order, no participant ID (37 bytes)
      -- F: Add Order, with participant ID (44) - A plus bytes 37..43
      when C_TYPE_A | C_TYPE_F =>
        f(C_FLD_ORDID_LO + 63 downto C_FLD_ORDID_LO) :=
          mb(buf,5) & mb(buf,6) & mb(buf,7) & mb(buf,8) &
          mb(buf,9) & mb(buf,10) & mb(buf,11) & mb(buf,12);
        f(C_FLD_BOOKID_LO + 31 downto C_FLD_BOOKID_LO) :=
          mb(buf,13) & mb(buf,14) & mb(buf,15) & mb(buf,16);
        f(C_FLD_SIDE_LO + 7 downto C_FLD_SIDE_LO) := mb(buf,17);
        f(C_FLD_POS_LO + 31 downto C_FLD_POS_LO) :=
          mb(buf,18) & mb(buf,19) & mb(buf,20) & mb(buf,21);
        f(C_FLD_QTY_LO + 63 downto C_FLD_QTY_LO) :=
          mb(buf,22) & mb(buf,23) & mb(buf,24) & mb(buf,25) &
          mb(buf,26) & mb(buf,27) & mb(buf,28) & mb(buf,29);
        f(C_FLD_PRICE_LO + 31 downto C_FLD_PRICE_LO) :=
          mb(buf,30) & mb(buf,31) & mb(buf,32) & mb(buf,33);
        f(C_FLD_EXTYPE_LO + 15 downto C_FLD_EXTYPE_LO) :=
          mb(buf,34) & mb(buf,35);
        f(C_FLD_LOT_LO + 7 downto C_FLD_LOT_LO) := mb(buf,36);
        if t = C_TYPE_F then
          f(C_FLD_POWNER_LO + 55 downto C_FLD_POWNER_LO) :=
            mb(buf,37) & mb(buf,38) & mb(buf,39) & mb(buf,40) &
            mb(buf,41) & mb(buf,42) & mb(buf,43);
        end if;

      -- E: Order Executed (52 bytes)
      -- C: Order Executed with Price (58) - E plus bytes 52..57
      when C_TYPE_E | C_TYPE_C =>
        f(C_FLD_ORDID_LO + 63 downto C_FLD_ORDID_LO) :=
          mb(buf,5) & mb(buf,6) & mb(buf,7) & mb(buf,8) &
          mb(buf,9) & mb(buf,10) & mb(buf,11) & mb(buf,12);
        f(C_FLD_BOOKID_LO + 31 downto C_FLD_BOOKID_LO) :=
          mb(buf,13) & mb(buf,14) & mb(buf,15) & mb(buf,16);
        f(C_FLD_SIDE_LO + 7 downto C_FLD_SIDE_LO) := mb(buf,17);
        f(C_FLD_QTY_LO + 63 downto C_FLD_QTY_LO) :=
          mb(buf,18) & mb(buf,19) & mb(buf,20) & mb(buf,21) &
          mb(buf,22) & mb(buf,23) & mb(buf,24) & mb(buf,25);
        f(C_FLD_MATCHID_LO + 95 downto C_FLD_MATCHID_LO) :=
          mb(buf,26) & mb(buf,27) & mb(buf,28) & mb(buf,29) &
          mb(buf,30) & mb(buf,31) & mb(buf,32) & mb(buf,33) &
          mb(buf,34) & mb(buf,35) & mb(buf,36) & mb(buf,37);
        f(C_FLD_POWNER_LO + 55 downto C_FLD_POWNER_LO) :=
          mb(buf,38) & mb(buf,39) & mb(buf,40) & mb(buf,41) &
          mb(buf,42) & mb(buf,43) & mb(buf,44);
        f(C_FLD_PCP_LO + 55 downto C_FLD_PCP_LO) :=
          mb(buf,45) & mb(buf,46) & mb(buf,47) & mb(buf,48) &
          mb(buf,49) & mb(buf,50) & mb(buf,51);
        if t = C_TYPE_C then
          f(C_FLD_PRICE_LO + 31 downto C_FLD_PRICE_LO) :=
            mb(buf,52) & mb(buf,53) & mb(buf,54) & mb(buf,55);
          f(C_FLD_CROSS_LO + 7 downto C_FLD_CROSS_LO) := mb(buf,56);
          f(C_FLD_PRINT_LO + 7 downto C_FLD_PRINT_LO) := mb(buf,57);
        end if;

      -- U: Order Replace (36 bytes)
      when C_TYPE_U =>
        f(C_FLD_ORDID_LO + 63 downto C_FLD_ORDID_LO) :=
          mb(buf,5) & mb(buf,6) & mb(buf,7) & mb(buf,8) &
          mb(buf,9) & mb(buf,10) & mb(buf,11) & mb(buf,12);
        f(C_FLD_BOOKID_LO + 31 downto C_FLD_BOOKID_LO) :=
          mb(buf,13) & mb(buf,14) & mb(buf,15) & mb(buf,16);
        f(C_FLD_SIDE_LO + 7 downto C_FLD_SIDE_LO) := mb(buf,17);
        f(C_FLD_POS_LO + 31 downto C_FLD_POS_LO) :=
          mb(buf,18) & mb(buf,19) & mb(buf,20) & mb(buf,21);
        f(C_FLD_QTY_LO + 63 downto C_FLD_QTY_LO) :=
          mb(buf,22) & mb(buf,23) & mb(buf,24) & mb(buf,25) &
          mb(buf,26) & mb(buf,27) & mb(buf,28) & mb(buf,29);
        f(C_FLD_PRICE_LO + 31 downto C_FLD_PRICE_LO) :=
          mb(buf,30) & mb(buf,31) & mb(buf,32) & mb(buf,33);
        f(C_FLD_EXTYPE_LO + 15 downto C_FLD_EXTYPE_LO) :=
          mb(buf,34) & mb(buf,35);

      -- D: Order Delete (18 bytes)
      when C_TYPE_D =>
        f(C_FLD_ORDID_LO + 63 downto C_FLD_ORDID_LO) :=
          mb(buf,5) & mb(buf,6) & mb(buf,7) & mb(buf,8) &
          mb(buf,9) & mb(buf,10) & mb(buf,11) & mb(buf,12);
        f(C_FLD_BOOKID_LO + 31 downto C_FLD_BOOKID_LO) :=
          mb(buf,13) & mb(buf,14) & mb(buf,15) & mb(buf,16);
        f(C_FLD_SIDE_LO + 7 downto C_FLD_SIDE_LO) := mb(buf,17);

      -- P: Trade (50 bytes). Layout differs from E/C - match_id comes first
      -- and there is no order_id.
      when C_TYPE_P =>
        f(C_FLD_MATCHID_LO + 95 downto C_FLD_MATCHID_LO) :=
          mb(buf,5) & mb(buf,6) & mb(buf,7) & mb(buf,8) &
          mb(buf,9) & mb(buf,10) & mb(buf,11) & mb(buf,12) &
          mb(buf,13) & mb(buf,14) & mb(buf,15) & mb(buf,16);
        f(C_FLD_SIDE_LO + 7 downto C_FLD_SIDE_LO) := mb(buf,17);
        f(C_FLD_QTY_LO + 63 downto C_FLD_QTY_LO) :=
          mb(buf,18) & mb(buf,19) & mb(buf,20) & mb(buf,21) &
          mb(buf,22) & mb(buf,23) & mb(buf,24) & mb(buf,25);
        f(C_FLD_BOOKID_LO + 31 downto C_FLD_BOOKID_LO) :=
          mb(buf,26) & mb(buf,27) & mb(buf,28) & mb(buf,29);
        f(C_FLD_PRICE_LO + 31 downto C_FLD_PRICE_LO) :=
          mb(buf,30) & mb(buf,31) & mb(buf,32) & mb(buf,33);
        f(C_FLD_POWNER_LO + 55 downto C_FLD_POWNER_LO) :=
          mb(buf,34) & mb(buf,35) & mb(buf,36) & mb(buf,37) &
          mb(buf,38) & mb(buf,39) & mb(buf,40);
        f(C_FLD_PCP_LO + 55 downto C_FLD_PCP_LO) :=
          mb(buf,41) & mb(buf,42) & mb(buf,43) & mb(buf,44) &
          mb(buf,45) & mb(buf,46) & mb(buf,47);
        f(C_FLD_PRINT_LO + 7 downto C_FLD_PRINT_LO) := mb(buf,48);
        f(C_FLD_CROSS_LO + 7 downto C_FLD_CROSS_LO) := mb(buf,49);

      when others =>
        f := (others => '0');

    end case;

    return f;
  end function;

  ------------------------------------------------------------------------------
  -- Accessors
  ------------------------------------------------------------------------------
  function itch_order_id (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_ORDID_LO + C_FLD_ORDID_W - 1 downto C_FLD_ORDID_LO);
  end function;

  function itch_order_book_id (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_BOOKID_LO + C_FLD_BOOKID_W - 1 downto C_FLD_BOOKID_LO);
  end function;

  function itch_side (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_SIDE_LO + C_FLD_SIDE_W - 1 downto C_FLD_SIDE_LO);
  end function;

  function itch_quantity (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_QTY_LO + C_FLD_QTY_W - 1 downto C_FLD_QTY_LO);
  end function;

  function itch_price (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_PRICE_LO + C_FLD_PRICE_W - 1 downto C_FLD_PRICE_LO);
  end function;

  function itch_position (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_POS_LO + C_FLD_POS_W - 1 downto C_FLD_POS_LO);
  end function;

  function itch_match_id (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_MATCHID_LO + C_FLD_MATCHID_W - 1 downto C_FLD_MATCHID_LO);
  end function;

  function itch_timestamp_ns (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_FLD_TS_NS_LO + C_FLD_TS_NS_W - 1 downto C_FLD_TS_NS_LO);
  end function;

end package body itch_parser_pkg;
