--------------------------------------------------------------------------------
-- order_book_pkg
--
-- Shared types and the message decode for the ASX ITCH order book engine.
--
-- decode_book_msg takes one framed ITCH message and its type byte and returns
-- a normalised command. All ITCH-specific knowledge - byte offsets, field
-- widths, and the semantic overloads - lives here and nowhere else downstream.
--
-- Semantic normalisation applied:
--
--   * QUANTITY is absolute on A/F/U but an executed DELTA on E/C. The op
--     field tells downstream which. Narrowed 64 -> 32 bits with saturation;
--     qty_ovf flags the (not expected) case of a real value exceeding 32 bits.
--
--   * PRICE is the order's book price on A/F/U. On C it is the TRADE price
--     (spec 2.6.2.2 - executions at a price differing from the display price,
--     i.e. auction crossings) and must NOT reach the book: px_valid is held
--     low on every EXEC so the resting price can only come from the order
--     table. E carries no price field at all.
--
--   * EXCHANGE ORDER TYPE exists only on A/F/U, so undisc and implied must be
--     captured at add/replace time and stored in the order record. They are
--     unrecoverable at execution time.
--
--   * SIDE is an ASCII byte. Anything other than 'B' or 'S' sets side_ok low.
--     (P carries a literal blank for Centre Point, but P is not decoded here.)
--
-- Byte layouts are from the ASX Trade ITCH Message Specification and match
-- decode_msg in itch_parser_pkg. If the spec is revised, both must change.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;

package order_book_pkg is

  ------------------------------------------------------------------------------
  -- Message type codes (ASCII)
  ------------------------------------------------------------------------------
  constant C_TYPE_A : std_logic_vector(7 downto 0) := x"41";  -- Add Order
  constant C_TYPE_F : std_logic_vector(7 downto 0) := x"46";  -- Add Order + participant
  constant C_TYPE_E : std_logic_vector(7 downto 0) := x"45";  -- Order Executed
  constant C_TYPE_C : std_logic_vector(7 downto 0) := x"43";  -- Order Executed with Price
  constant C_TYPE_U : std_logic_vector(7 downto 0) := x"55";  -- Order Replace
  constant C_TYPE_D : std_logic_vector(7 downto 0) := x"44";  -- Order Delete

  ------------------------------------------------------------------------------
  -- Side bytes
  ------------------------------------------------------------------------------
  constant C_SIDE_BUY  : std_logic_vector(7 downto 0) := x"42";  -- 'B'
  constant C_SIDE_SELL : std_logic_vector(7 downto 0) := x"53";  -- 'S'

  ------------------------------------------------------------------------------
  -- Exchange Order Type bitmap (A/F/U only)
  ------------------------------------------------------------------------------
  constant C_EXTYPE_BIT_MARKET_BID   : natural := 2;   -- value 4
  constant C_EXTYPE_BIT_PRICE_STAB   : natural := 3;   -- value 8
  constant C_EXTYPE_BIT_UNDISCLOSED  : natural := 5;   -- value 32
  constant C_EXTYPE_BIT_IMPLIED      : natural := 13;  -- value 8192



  ------------------------------------------------------------------------------
  -- Normalised command
  --
  -- valid   - message was a book-affecting type and decoded cleanly
  -- book_id - caller compares against its configured instrument
  -- side_ok - side byte was recognised; if low, drop and count
  -- qty_ovf - wire quantity exceeded 32 bits; qty is saturated
  ------------------------------------------------------------------------------
  type t_book_cmd is record
    valid     : std_logic;
    op        : t_book_op;
    order_id  : std_logic_vector(63 downto 0);
    book_id   : std_logic_vector(31 downto 0);
    side      : std_logic;                      -- 0 = buy, 1 = sell
    side_ok   : std_logic;
    qty       : unsigned(31 downto 0);
    qty_ovf   : std_logic;
    price     : signed(31 downto 0);
    px_valid  : std_logic;
    undisc    : std_logic;
    implied   : std_logic;
    position  : unsigned(31 downto 0);          -- captured, unused in v1
  end record t_book_cmd;

  constant C_BOOK_CMD_NULL : t_book_cmd := (
    valid    => '0',
    op       => OP_DELETE,
    order_id => (others => '0'),
    book_id  => (others => '0'),
    side     => '0',
    side_ok  => '0',
    qty      => (others => '0'),
    qty_ovf  => '0',
    price    => (others => '0'),
    px_valid => '0',
    undisc   => '0',
    implied  => '0',
    position => (others => '0')
  );

  ------------------------------------------------------------------------------
  -- Helpers
  ------------------------------------------------------------------------------

  -- Byte i of a message buffer. Matches mb() in itch_parser_pkg: byte 0 is the
  -- least significant byte of the vector.
  function msg_byte (msg : std_logic_vector; i : natural)
    return std_logic_vector;

  -- True for the six book-affecting types. P (Trade) is deliberately excluded:
  -- trade messages do not alter the displayed book (spec 2.7).
  function is_book_msg (t : std_logic_vector(7 downto 0)) return boolean;

  function decode_book_msg (msg : std_logic_vector;
                            t   : std_logic_vector(7 downto 0))
    return t_book_cmd;

end package order_book_pkg;


package body order_book_pkg is

  ------------------------------------------------------------------------------
  function msg_byte (msg : std_logic_vector; i : natural)
    return std_logic_vector is
    alias m : std_logic_vector(msg'length-1 downto 0) is msg;
  begin
    return m(8*i + 7 downto 8*i);
  end function;

  ------------------------------------------------------------------------------
  function is_book_msg (t : std_logic_vector(7 downto 0)) return boolean is
  begin
    return t = C_TYPE_A or t = C_TYPE_F or t = C_TYPE_E or
           t = C_TYPE_C or t = C_TYPE_U or t = C_TYPE_D;
  end function;

  ------------------------------------------------------------------------------
  -- Big-endian field assembly. ITCH numeric fields are most significant byte
  -- first on the wire, so the lowest byte index becomes the high bits.
  ------------------------------------------------------------------------------
  function be32 (msg : std_logic_vector; i : natural)
    return std_logic_vector is
  begin
    return msg_byte(msg, i)   & msg_byte(msg, i+1) &
           msg_byte(msg, i+2) & msg_byte(msg, i+3);
  end function;

  function be64 (msg : std_logic_vector; i : natural)
    return std_logic_vector is
  begin
    return msg_byte(msg, i)   & msg_byte(msg, i+1) &
           msg_byte(msg, i+2) & msg_byte(msg, i+3) &
           msg_byte(msg, i+4) & msg_byte(msg, i+5) &
           msg_byte(msg, i+6) & msg_byte(msg, i+7);
  end function;

  function be16 (msg : std_logic_vector; i : natural)
    return std_logic_vector is
  begin
    return msg_byte(msg, i) & msg_byte(msg, i+1);
  end function;

  ------------------------------------------------------------------------------
  -- Decode side byte
  ------------------------------------------------------------------------------
  procedure decode_side (b       : in  std_logic_vector(7 downto 0);
                         side    : out std_logic;
                         side_ok : out std_logic) is
  begin
    case b is
      when C_SIDE_BUY  => side := '0'; side_ok := '1';
      when C_SIDE_SELL => side := '1'; side_ok := '1';
      when others      => side := '0'; side_ok := '0';
    end case;
  end procedure;

  ------------------------------------------------------------------------------
  -- Narrow the 64-bit wire quantity to 32 bits, saturating rather than
  -- truncating so an out-of-range value cannot silently become a small one.
  ------------------------------------------------------------------------------
  procedure narrow_qty (q    : in  std_logic_vector(63 downto 0);
                        qty  : out unsigned(31 downto 0);
                        ovf  : out std_logic) is
  begin
    if q(63 downto 32) /= (q(63 downto 32)'range => '0') then
      qty := (others => '1');
      ovf := '1';
    else
      qty := unsigned(q(31 downto 0));
      ovf := '0';
    end if;
  end procedure;

  ------------------------------------------------------------------------------
  -- decode_book_msg
  --
  -- Byte layouts, all offsets from the start of the ITCH message:
  --
  --   A (37) / F (44)      U (36)              E (52) / C (58)     D (18)
  --   ----------------     ----------------    ----------------    ---------
  --   0     type           0     type          0     type          0   type
  --   1-4   timestamp      1-4   timestamp     1-4   timestamp     1-4 timestamp
  --   5-12  order id       5-12  order id      5-12  order id      5-12 order id
  --   13-16 book id        13-16 book id       13-16 book id       13-16 book id
  --   17    side           17    side          17    side          17  side
  --   18-21 position       18-21 position      18-25 quantity
  --   22-29 quantity       22-29 quantity      26-37 match id
  --   30-33 price          30-33 price         38-44 owner
  --   34-35 exch ord type  34-35 exch ord type 45-51 counterparty
  --   36    lot type                           52-55 price   (C only)
  --   37-43 owner (F only)                     56    cross   (C only)
  --                                            57    print   (C only)
  ------------------------------------------------------------------------------
  function decode_book_msg (msg : std_logic_vector;
                            t   : std_logic_vector(7 downto 0))
    return t_book_cmd is
    variable c       : t_book_cmd := C_BOOK_CMD_NULL;
    variable v_side  : std_logic;
    variable v_sok   : std_logic;
    variable v_qty   : unsigned(31 downto 0);
    variable v_ovf   : std_logic;
    variable v_ext   : std_logic_vector(15 downto 0);
  begin

    -- Common to all six types
    c.order_id := be64(msg, 5);
    c.book_id  := be32(msg, 13);

    decode_side(msg_byte(msg, 17), v_side, v_sok);
    c.side    := v_side;
    c.side_ok := v_sok;

    case t is

      --------------------------------------------------------------------------
      -- A / F : Add Order. Quantity absolute, price is the resting price.
      --------------------------------------------------------------------------
      when C_TYPE_A | C_TYPE_F =>
        c.valid    := '1';
        c.op       := OP_ADD;
        c.position := unsigned(be32(msg, 18));
        narrow_qty(be64(msg, 22), v_qty, v_ovf);
        c.qty      := v_qty;
        c.qty_ovf  := v_ovf;
        c.price    := signed(be32(msg, 30));
        c.px_valid := '1';
        v_ext      := be16(msg, 34);
        c.undisc   := v_ext(C_EXTYPE_BIT_UNDISCLOSED);
        c.implied  := v_ext(C_EXTYPE_BIT_IMPLIED);

      --------------------------------------------------------------------------
      -- U : Order Replace. Same layout as A up to the exchange order type.
      --------------------------------------------------------------------------
      when C_TYPE_U =>
        c.valid    := '1';
        c.op       := OP_REPLACE;
        c.position := unsigned(be32(msg, 18));
        narrow_qty(be64(msg, 22), v_qty, v_ovf);
        c.qty      := v_qty;
        c.qty_ovf  := v_ovf;
        c.price    := signed(be32(msg, 30));
        c.px_valid := '1';
        v_ext      := be16(msg, 34);
        c.undisc   := v_ext(C_EXTYPE_BIT_UNDISCLOSED);
        c.implied  := v_ext(C_EXTYPE_BIT_IMPLIED);

      --------------------------------------------------------------------------
      -- E / C : Order Executed. Quantity is a DELTA to subtract.
      --
      -- px_valid stays low for both. E has no price field; C's price is the
      -- trade price, not the resting price. The resting price must be read
      -- from the order table.
      --------------------------------------------------------------------------
      when C_TYPE_E | C_TYPE_C =>
        c.valid    := '1';
        c.op       := OP_EXEC;
        narrow_qty(be64(msg, 18), v_qty, v_ovf);
        c.qty      := v_qty;
        c.qty_ovf  := v_ovf;
        c.px_valid := '0';

      --------------------------------------------------------------------------
      -- D : Order Delete. Identity only.
      --------------------------------------------------------------------------
      when C_TYPE_D =>
        c.valid := '1';
        c.op    := OP_DELETE;

      --------------------------------------------------------------------------
      -- Everything else - reference data, state, trades, unknown types.
      --------------------------------------------------------------------------
      when others =>
        c := C_BOOK_CMD_NULL;

    end case;

    return c;
  end function;

end package body order_book_pkg;
