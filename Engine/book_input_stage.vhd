--------------------------------------------------------------------------------
-- book_input_stage
--
-- Decodes ASX ITCH order book messages arriving 8 bytes per beat and emits a
-- normalised command as early as the message allows.
--
-- EMIT AS SOON AS POSSIBLE
--
-- A command is emitted on the beat carrying the last field the decode needs,
-- not on tlast. The last needed byte is 35 for A/F/U (exchange order type),
-- 25 for E/C (quantity), and 17 for D (side), so:
--
--   type   last byte   emit beat   beats in message   beats saved
--   A      35          4           5                  0
--   F      35          4           6                  1
--   U      35          4           5                  0
--   E      25          3           7                  3
--   C      25          3           8                  4
--   D      17          2           3                  0
--
-- Trailing beats are consumed and ignored. Nothing downstream waits for them.
--
-- OUTPUT IS A ONE-CYCLE PULSE
--
-- m_tvalid is high for exactly one cycle per accepted message and there is no
-- m_tready: the consumer must be able to take a command every cycle. order_fifo
-- is, by construction - its s_tready is hardwired high. A consumer that can
-- stall needs a holding register in front of it.
--
-- FRAMING
--
-- Beat 0 is the first beat after reset or after a tlast. The type byte is beat
-- 0 byte 0, so no separate type port is needed. Byte i of the message sits at
-- bits 8i+7 downto 8i of its beat, matching msg_byte() in order_book_pkg and
-- the lane order the parser chain uses.
--
-- Only the first 5 beats are stored - 40 bytes, enough to cover byte 35. Stale
-- bytes from a previous message can never be read, because a message always
-- emits on the beat that completes the fields it needs.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.ram_pkg.all;
  use work.order_book_pkg.all;

entity book_input_stage is
  generic (
    -- Instrument this engine instance tracks; all other order books dropped.
    --
    -- A natural rather than a vector so it can be overridden from the
    -- simulator command line (nvc -e -gG_ORDER_BOOK_ID=85603).
    G_ORDER_BOOK_ID : natural := 85603
  );
  port (
    clk        : in    std_logic;
    resetn     : in    std_logic;

    ----------------------------------------------------------------------------
    -- Slave: ITCH message bytes, 8 per beat, first byte in the low lane
    ----------------------------------------------------------------------------
    s_tvalid   : in    std_logic;
    s_tready   : out   std_logic;                     -- tied high, never stalls
    s_tdata    : in    std_logic_vector(63 downto 0);
    s_tlast    : in    std_logic;                     -- ends the message

    ----------------------------------------------------------------------------
    -- Master: normalised command. Valid for ONE cycle. No handshake.
    ----------------------------------------------------------------------------
    m_tvalid   : out   std_logic;

    m_op       : out   t_book_op;                     -- ADD / EXEC / REPLACE / DELETE
    m_order_id : out   std_logic_vector(63 downto 0);
    m_book_id  : out   std_logic_vector(31 downto 0);
    m_side     : out   std_logic;                     -- 0 = buy, 1 = sell
    m_qty      : out   unsigned(31 downto 0);         -- absolute on ADD/REPLACE, delta on EXEC
    m_price    : out   signed(31 downto 0);           -- valid on ADD/REPLACE only
    m_px_valid : out   std_logic;
    m_undisc   : out   std_logic;                     -- exchange order type bit 5
    m_implied  : out   std_logic                      -- exchange order type bit 13
  );
end entity book_input_stage;

architecture rtl of book_input_stage is

  ------------------------------------------------------------------------------
  -- Geometry
  ------------------------------------------------------------------------------
  constant C_BEAT_BYTES : natural := 8;
  constant C_BEAT_W     : natural := C_BEAT_BYTES * 8;

  -- Last message byte the decode reads, per type family. Taken from the field
  -- offsets in decode_book_msg; if those change, these change with them.
  constant C_LAST_AFU : natural := 35;   -- exchange order type, bytes 34-35
  constant C_LAST_EC  : natural := 25;   -- quantity, bytes 18-25
  constant C_LAST_D   : natural := 17;   -- side, byte 17

  function f_beat_of (byte_idx : natural) return natural is
  begin
    return byte_idx / C_BEAT_BYTES;
  end function f_beat_of;

  -- Beats that must be buffered to cover the deepest field.
  constant C_BEATS : natural := f_beat_of(C_LAST_AFU) + 1;   -- 5
  constant C_BUF_W : natural := C_BEATS * C_BEAT_W;          -- 320

  -- The beat on which each type has everything it needs.
  function f_emit_beat (t : std_logic_vector(7 downto 0)) return natural is
  begin
    case t is
      when C_TYPE_A | C_TYPE_F | C_TYPE_U => return f_beat_of(C_LAST_AFU);
      when C_TYPE_E | C_TYPE_C            => return f_beat_of(C_LAST_EC);
      when C_TYPE_D                       => return f_beat_of(C_LAST_D);
      when others                         => return 0;   -- never emits
    end case;
  end function f_emit_beat;

  constant C_BOOK_ID : std_logic_vector(31 downto 0) :=
    std_logic_vector(to_unsigned(G_ORDER_BOOK_ID, 32));

  ------------------------------------------------------------------------------
  -- Assembly
  ------------------------------------------------------------------------------
  signal buf      : std_logic_vector(C_BUF_W - 1 downto 0) := (others => '0');
  signal msg_next : std_logic_vector(C_BUF_W - 1 downto 0);
  signal beat     : natural range 0 to C_BEATS             := 0;

  ------------------------------------------------------------------------------
  -- Decode
  ------------------------------------------------------------------------------
  signal mtype    : std_logic_vector(7 downto 0);
  signal cmd      : t_book_cmd;
  signal book_hit : std_logic;
  signal pass     : std_logic;   -- decoded, right book, usable side
  signal emit     : std_logic;   -- this beat completes the fields we need

  ------------------------------------------------------------------------------
  -- Output
  ------------------------------------------------------------------------------
  signal r_tvalid : std_logic  := '0';
  signal r_cmd    : t_book_cmd := C_BOOK_CMD_NULL;

begin

  -- Nothing here can stall: the buffer is overwritten in place and the output
  -- is a pulse, so there is no state that a slow consumer could back up into.
  s_tready <= '1';

  ------------------------------------------------------------------------------
  -- Merge the beat being presented into the stored ones. Static slices with a
  -- compare per lane, so this is a mux rather than a variable shifter.
  ------------------------------------------------------------------------------
  p_merge : process (all) is
    variable v : std_logic_vector(C_BUF_W - 1 downto 0);
  begin
    v := buf;
    for k in 0 to C_BEATS - 1 loop
      if k = beat then
        v(C_BEAT_W * k + C_BEAT_W - 1 downto C_BEAT_W * k) := s_tdata;
      end if;
    end loop;
    msg_next <= v;
  end process p_merge;

  ------------------------------------------------------------------------------
  -- Decode.
  --
  -- decode_book_msg is called unconditionally on the merged buffer. It returns
  -- valid = '0' for every type that does not affect the book, so no separate
  -- type check is needed for the payload - only for the emit beat.
  --
  -- The type byte survives in lane 0 for the whole message, so mtype is stable
  -- from beat 0 onwards.
  ------------------------------------------------------------------------------
  mtype <= msg_byte(msg_next, 0);
  cmd   <= decode_book_msg(msg_next, mtype);

  book_hit <= '1' when cmd.book_id = C_BOOK_ID else '0';

  -- Forwarded only if it decoded to a book operation, belongs to the configured
  -- instrument, and carried a recognised side byte.
  pass <= cmd.valid and book_hit and cmd.side_ok;

  emit <= '1' when s_tvalid = '1'
                and is_book_msg(mtype)
                and beat = f_emit_beat(mtype)
          else '0';

  ------------------------------------------------------------------------------
  -- Beat counter, buffer and output pulse.
  --
  -- The counter saturates at C_BEATS so a long message cannot wrap round and
  -- hit its emit beat twice; tlast returns it to 0 for the next message.
  ------------------------------------------------------------------------------
  p_reg : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        buf      <= (others => '0');
        beat     <= 0;
        r_tvalid <= '0';
        r_cmd    <= C_BOOK_CMD_NULL;
      else

        r_tvalid <= '0';   -- default, so m_tvalid is a one-cycle pulse

        if s_tvalid = '1' then

          buf <= msg_next;

          if s_tlast = '1' then
            beat <= 0;
          elsif beat < C_BEATS then
            beat <= beat + 1;
          end if;

          if emit = '1' and pass = '1' then
            r_tvalid <= '1';
            r_cmd    <= cmd;
          end if;

        end if;

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
