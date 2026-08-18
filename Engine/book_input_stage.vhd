--------------------------------------------------------------------------------
-- book_input_stage
--
-- Module 1 of the ASX ITCH order book engine.
--
-- Takes raw ITCH message bytes from the parser FIFO, decodes the six
-- book-affecting types for the configured order book, and emits a uniform
-- command bus. Everything else is dropped.
--
-- s_tdata holds one complete ITCH message, byte 0 = message type, framed by
-- the parser. Ethernet / IPv4 / UDP / MoldUDP64 headers have already been
-- stripped upstream and are not visible here. Stream integrity (sequence
-- gaps, parser drops, truncation) is handled elsewhere.
--
-- All ITCH knowledge - byte offsets, field widths, and the quantity and price
-- semantic overloads - lives in order_book_pkg.decode_book_msg. This module is
-- filter, handshake, and registers only.
--
-- m_book_id is forwarded even though this engine instance tracks a single
-- instrument, so every command it emits carries the same value. It is on the
-- bus for multi-symbol: the order table key is (order_id, side) per book, and
-- Order IDs are only unique within a book and side, so a shared table would
-- need the instrument to disambiguate. Carrying it now costs 32 wires and no
-- logic, and avoids re-cutting the interface later. Downstream may ignore it.
--
-- Latency: 1 cycle. Output is fully registered; there is no combinational
-- path from s_tdata to any master payload signal.
--
-- Throughput: one message per cycle sustained while m_tready is high. Worst
-- case input rate is one book message per 2.5 cycles (D at 18 bytes over a
-- 64-bit datapath), so this never limits the engine.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.order_book_pkg.all;

entity book_input_stage is
  generic (
    -- Instrument this engine instance tracks; all other order books dropped.
    --
    -- A natural rather than a vector so it can be overridden from the
    -- simulator command line (nvc -e -gG_ORDER_BOOK_ID=85603). ASX order book
    -- identifiers are 4-byte numerics, so nothing is lost.
    G_ORDER_BOOK_ID : natural := 85603;

    -- Raw message buffer width. Largest book-affecting message is C at 58
    -- bytes; defaults to the parser's 64-byte assembly buffer.
    G_MSG_BYTES     : natural := 64
  );
  port (
    clk        : in  std_logic;
    resetn     : in  std_logic;

    ----------------------------------------------------------------------------
    -- Slave: raw ITCH messages from the parser FIFO
    ----------------------------------------------------------------------------
    s_tvalid   : in  std_logic;
    s_tready   : out std_logic;
    s_ttype    : in  std_logic_vector(7 downto 0);          -- also s_tdata byte 0
    s_tdata    : in  std_logic_vector(G_MSG_BYTES*8-1 downto 0);

    ----------------------------------------------------------------------------
    -- Master: normalised command bus
    ----------------------------------------------------------------------------
    m_tvalid   : out std_logic;
    m_tready   : in  std_logic;

    m_op       : out t_book_op;                     -- ADD / EXEC / REPLACE / DELETE
    m_order_id : out std_logic_vector(63 downto 0);
    m_book_id  : out std_logic_vector(31 downto 0); -- instrument, see note below
    m_side     : out std_logic;                     -- 0 = buy, 1 = sell
    m_qty      : out unsigned(31 downto 0);         -- absolute on ADD/REPLACE, delta on EXEC
    m_price    : out signed(31 downto 0);           -- valid on ADD/REPLACE only
    m_px_valid : out std_logic;
    m_undisc   : out std_logic;                     -- exchange order type bit 5
    m_implied  : out std_logic                      -- exchange order type bit 13
  );
end entity book_input_stage;


architecture rtl of book_input_stage is

  constant C_BOOK_ID : std_logic_vector(31 downto 0)
    := std_logic_vector(to_unsigned(G_ORDER_BOOK_ID, 32));

  ------------------------------------------------------------------------------
  -- Combinational decode and filter
  ------------------------------------------------------------------------------
  signal cmd        : t_book_cmd;
  signal book_hit   : std_logic;
  signal pass       : std_logic;   -- decoded, right book, usable side

  ------------------------------------------------------------------------------
  -- Handshake
  ------------------------------------------------------------------------------
  signal s_tready_i : std_logic;
  signal s_xfer     : std_logic;   -- slave  handshake completes this cycle
  signal m_xfer     : std_logic;   -- master handshake completes this cycle

  ------------------------------------------------------------------------------
  -- Output holding register
  ------------------------------------------------------------------------------
  signal r_tvalid   : std_logic := '0';
  signal r_cmd      : t_book_cmd := C_BOOK_CMD_NULL;

begin

  ------------------------------------------------------------------------------
  -- Decode.
  --
  -- decode_book_msg is called unconditionally. It returns valid = '0' for
  -- every type that does not affect the book, so no separate type check is
  -- needed here.
  ------------------------------------------------------------------------------
  cmd <= decode_book_msg(s_tdata, s_ttype);

  book_hit <= '1' when cmd.book_id = C_BOOK_ID else '0';

  -- A message is forwarded only if it decoded to a book operation, belongs to
  -- the configured instrument, and carried a recognised side byte. Anything
  -- else is accepted from the FIFO and discarded.
  pass <= cmd.valid and book_hit and cmd.side_ok;

  ------------------------------------------------------------------------------
  -- Handshakes.
  --
  -- A transfer occurs only when valid AND ready are both high on the same
  -- clock edge. Nothing else counts as the command having been delivered.
  --
  -- The output register is a holding stage. Once loaded it keeps its command
  -- until the master handshake completes - m_tvalid stays high and the payload
  -- is frozen, however long m_tready stays low. While the register is holding
  -- an undelivered command, s_tready is deasserted, so the upstream FIFO
  -- cannot overwrite it.
  --
  -- s_tready is high when the register is empty, OR when it is being emptied
  -- this cycle. The second term is what allows a new message to be accepted on
  -- the same edge the old one departs, sustaining one message per cycle with
  -- no bubble.
  ------------------------------------------------------------------------------
  s_tready_i <= '1' when (r_tvalid = '0') or (m_tready = '1') else '0';
  s_tready   <= s_tready_i;

  s_xfer <= s_tvalid and s_tready_i;
  m_xfer <= r_tvalid and m_tready;

  ------------------------------------------------------------------------------
  -- Output holding register.
  --
  -- Three mutually exclusive outcomes each cycle:
  --
  --   load    a message was accepted - r_tvalid takes pass, so a message that
  --           failed the filter clears the register instead of filling it
  --   drain   the command was delivered and nothing replaced it
  --   hold    neither handshake completed - the command sits here untouched
  --
  -- The payload is written only on a load, so a held command cannot be
  -- disturbed by whatever the FIFO happens to be presenting.
  ------------------------------------------------------------------------------
  p_reg : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        r_tvalid <= '0';
        r_cmd    <= C_BOOK_CMD_NULL;
      else

        if s_xfer = '1' then
          -- Slave handshake: s_tvalid and s_tready both high
          r_tvalid <= pass;
          r_cmd    <= cmd;

        elsif m_xfer = '1' then
          -- Master handshake with no replacement: register empties
          r_tvalid <= '0';

        end if;
        -- otherwise: hold. r_tvalid and r_cmd keep their values.

      end if;
    end if;
  end process p_reg;

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------
  m_tvalid   <= r_tvalid;
  m_op       <= r_cmd.op;
  m_order_id <= r_cmd.order_id;
  m_book_id  <= r_cmd.book_id;
  m_side     <= r_cmd.side;
  m_qty      <= r_cmd.qty;
  m_price    <= r_cmd.price;
  m_px_valid <= r_cmd.px_valid;
  m_undisc   <= r_cmd.undisc;
  m_implied  <= r_cmd.implied;

end architecture rtl;
