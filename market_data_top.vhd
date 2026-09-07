--------------------------------------------------------------------------------
-- market_data_top
--
-- Final top: the five-stage packet parser feeding the order book engine.
--
--   fullparser -> [msg_beats adapter] -> order_book_engine_top
--
-- THE ADAPTER, AND WHY IT SHOULD NOT SURVIVE
--
-- book_input_stage wants ITCH message bytes 8 per beat so it can decode while
-- the message streams past. itch_parser does not offer that. It offers
-- msg_fields, a 512-bit union of already-extracted, already-byte-swapped
-- fields, emitted once the message is complete.
--
-- So the adapter below does two things, neither of which should exist:
--
--   1. Repacks msg_fields into the raw byte layout decode_book_msg reads,
--      byte-swapping each field back to wire order. Pure rewiring.
--   2. Serialises that buffer into beats and hands them to the engine.
--
-- The cost is the whole point of the streaming rewrite: instead of decoding
-- alongside the parser, book_input_stage now decodes a reconstruction of a
-- message the parser already finished with. Latency is msg_valid + emit_beat
-- + 1 rather than emit_beat + 1.
--
-- The fix is a message-beat master on itch_parser - it already computes the
-- framing internally (start/end offsets, in_block, current type). With that,
-- this adapter deletes, book_input_stage connects straight to it, and the two
-- run in parallel rather than in series.
--
-- Serialisation stops at the emit beat rather than running to the full message
-- length, so the adapter always keeps up with the wire: the shortest book
-- message, D at 18 bytes, occupies 3 packet beats and needs 3 adapter beats.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.itch_parser_pkg.all;

entity market_data_top is
  generic (
    G_TPID          : std_logic_vector(15 downto 0) := x"8100";
    G_ORDER_BOOK_ID : natural                       := 85603;
    G_FIFO_DEPTH    : positive                      := 16;
    G_MAX_ORDERS    : natural                       := 16384
  );
  port (
    clk              : in    std_logic;
    resetn           : in    std_logic;

    ----------------------------------------------------------------------------
    -- Slave: raw Ethernet frames
    ----------------------------------------------------------------------------
    s_axis_tdata     : in    std_logic_vector(63 downto 0);
    s_axis_tkeep     : in    std_logic_vector(7 downto 0);
    s_axis_tvalid    : in    std_logic;
    s_axis_tready    : out   std_logic;
    s_axis_tlast     : in    std_logic;

    ----------------------------------------------------------------------------
    -- Master: packet passthrough. Leave open to let Vivado trim the parser's
    -- output path when only the book is being measured.
    ----------------------------------------------------------------------------
    m_axis_tdata     : out   std_logic_vector(63 downto 0);
    m_axis_tkeep     : out   std_logic_vector(7 downto 0);
    m_axis_tvalid    : out   std_logic;
    m_axis_tready    : in    std_logic;
    m_axis_tlast     : out   std_logic;

    ----------------------------------------------------------------------------
    -- Price window
    ----------------------------------------------------------------------------
    base_price       : in    std_logic_vector(31 downto 0);

    ----------------------------------------------------------------------------
    -- Master: top of book
    ----------------------------------------------------------------------------
    m_tvalid         : out   std_logic;
    m_tready         : in    std_logic;

    m_bid_price      : out   std_logic_vector(31 downto 0);
    m_bid_qty        : out   std_logic_vector(31 downto 0);
    m_ask_price      : out   std_logic_vector(31 downto 0);
    m_ask_qty        : out   std_logic_vector(31 downto 0);
    m_valid          : out   std_logic_vector(1 downto 0);

    ----------------------------------------------------------------------------
    -- Status
    ----------------------------------------------------------------------------
    exchange_seconds : out   std_logic_vector(31 downto 0);
    pkt_done         : out   std_logic;
    pkt_msg_count    : out   std_logic_vector(15 downto 0);
    msg_status       : out   std_logic_vector(C_MSG_STATUS_W - 1 downto 0);

    book_busy        : out   std_logic;
    level_busy       : out   std_logic;
    oor              : out   std_logic;
    fifo_full        : out   std_logic;
    fifo_overflow    : out   std_logic;
    msg_dropped      : out   std_logic   -- adapter was busy when a message arrived
  );
end entity market_data_top;

architecture rtl of market_data_top is

  ------------------------------------------------------------------------------
  -- Adapter geometry. Mirrors book_input_stage: 8-byte beats, 5 beats of
  -- buffer, and the same per-type last-byte-read table.
  ------------------------------------------------------------------------------
  constant C_BEAT_BYTES : natural := 8;
  constant C_BEAT_W     : natural := C_BEAT_BYTES * 8;

  constant C_LAST_AFU   : natural := 35;
  constant C_LAST_EC    : natural := 25;
  constant C_LAST_D     : natural := 17;

  constant C_BEATS      : natural := C_LAST_AFU / C_BEAT_BYTES + 1;   -- 5
  constant C_RAW_W      : natural := C_BEATS * C_BEAT_W;              -- 320

  function f_last_beat (t : std_logic_vector(7 downto 0)) return natural is
  begin
    case t is
      when C_TYPE_A | C_TYPE_F | C_TYPE_U => return C_LAST_AFU / C_BEAT_BYTES;
      when C_TYPE_E | C_TYPE_C            => return C_LAST_EC / C_BEAT_BYTES;
      when others                         => return C_LAST_D / C_BEAT_BYTES;
    end case;
  end function f_last_beat;

  -- Reverse byte order. A field held numerically in msg_fields becomes the
  -- wire-order bytes decode_book_msg's be32/be64 will reassemble.
  function f_bswap (v : std_logic_vector) return std_logic_vector is
    alias    vv : std_logic_vector(v'length - 1 downto 0) is v;
    variable r  : std_logic_vector(v'length - 1 downto 0);
  begin
    for i in 0 to v'length / 8 - 1 loop
      r(8 * i + 7 downto 8 * i) :=
        vv(v'length - 1 - 8 * i downto v'length - 8 - 8 * i);
    end loop;
    return r;
  end function f_bswap;

  ------------------------------------------------------------------------------
  -- fullparser -> adapter
  ------------------------------------------------------------------------------
  signal msg_valid_i  : std_logic;
  signal msg_type_i   : std_logic_vector(7 downto 0);
  signal msg_fields_i : std_logic_vector(C_MSG_FIELDS_W - 1 downto 0);
  signal msg_status_i : std_logic_vector(C_MSG_STATUS_W - 1 downto 0);

  signal msg_take     : std_logic;   -- message the engine should see
  signal raw          : std_logic_vector(C_RAW_W - 1 downto 0);

  ------------------------------------------------------------------------------
  -- adapter -> engine
  ------------------------------------------------------------------------------
  signal raw_r      : std_logic_vector(C_RAW_W - 1 downto 0) := (others => '0');
  signal last_r     : natural range 0 to C_BEATS - 1         := 0;
  signal beat_r     : natural range 0 to C_BEATS - 1         := 0;
  signal busy_r     : std_logic                              := '0';

  signal eng_tvalid : std_logic;
  signal eng_tready : std_logic;
  signal eng_tdata  : std_logic_vector(C_BEAT_W - 1 downto 0);
  signal eng_tlast  : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Stage 1-5 : packet parsing
  ------------------------------------------------------------------------------
  u_fullparser : entity work.fullparser
    generic map (
      G_TPID => G_TPID
    )
    port map (
      clk               => clk,
      resetn            => resetn,

      s_axis_tdata      => s_axis_tdata,
      s_axis_tkeep      => s_axis_tkeep,
      s_axis_tvalid     => s_axis_tvalid,
      s_axis_tready     => s_axis_tready,
      s_axis_tlast      => s_axis_tlast,

      m_axis_tdata      => m_axis_tdata,
      m_axis_tkeep      => m_axis_tkeep,
      m_axis_tvalid     => m_axis_tvalid,
      m_axis_tready     => m_axis_tready,
      m_axis_tlast      => m_axis_tlast,

      msg_valid         => msg_valid_i,
      msg_index         => open,
      msg_seqnum        => open,
      msg_type          => msg_type_i,
      msg_length        => open,
      msg_fields        => msg_fields_i,
      msg_status        => msg_status_i,
      pkt_fields        => open,

      exchange_seconds  => exchange_seconds,

      pkt_done          => pkt_done,
      pkt_msg_count     => pkt_msg_count,

      eth_fields_valid  => open,
      ipv4_fields_valid => open,
      udp_fields_valid  => open,
      mold_fields_valid => open
    );

  msg_status <= msg_status_i;

  ------------------------------------------------------------------------------
  -- Only present a message the parser fully decoded. msg_fields is zeroed for
  -- undecoded types, and a truncated or short message would otherwise be
  -- rebuilt into a well-formed command from partial fields.
  ------------------------------------------------------------------------------
  msg_take <= msg_valid_i
              and msg_status_i(C_ST_DECODED)
              and not msg_status_i(C_ST_MSG_TRUNCATED)
              and not msg_status_i(C_ST_LEN_MISMATCH);

  ------------------------------------------------------------------------------
  -- Repack msg_fields into the raw byte layout decode_book_msg expects.
  --
  -- Offsets are from the ASX ITCH spec and must match the ones in
  -- order_book_pkg.decode_book_msg. E/C carry quantity at byte 18 and no
  -- price; A/F/U carry position, quantity at 22, price and exchange order
  -- type. Bytes not listed are never read for a book-affecting type.
  ------------------------------------------------------------------------------
  p_repack : process (all) is
    variable r : std_logic_vector(C_RAW_W - 1 downto 0);
  begin
    r := (others => '0');

    r(8 * 0 + 7 downto 8 * 0)    := msg_type_i;
    r(8 * 5 + 63 downto 8 * 5)   := f_bswap(itch_order_id(msg_fields_i));
    r(8 * 13 + 31 downto 8 * 13) := f_bswap(itch_order_book_id(msg_fields_i));
    r(8 * 17 + 7 downto 8 * 17)  := itch_side(msg_fields_i);

    if msg_type_i = C_TYPE_E or msg_type_i = C_TYPE_C then
      r(8 * 18 + 63 downto 8 * 18) := f_bswap(itch_quantity(msg_fields_i));
    else
      r(8 * 18 + 31 downto 8 * 18) := f_bswap(itch_position(msg_fields_i));
      r(8 * 22 + 63 downto 8 * 22) := f_bswap(itch_quantity(msg_fields_i));
      r(8 * 30 + 31 downto 8 * 30) := f_bswap(itch_price(msg_fields_i));
      r(8 * 34 + 15 downto 8 * 34) :=
        f_bswap(msg_fields_i(C_FLD_EXTYPE_LO + 15 downto C_FLD_EXTYPE_LO));
    end if;

    raw <= r;
  end process p_repack;

  ------------------------------------------------------------------------------
  -- Serialise. One beat per cycle up to the type's emit beat, tlast there.
  ------------------------------------------------------------------------------
  p_serialise : process (clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        busy_r  <= '0';
        beat_r  <= 0;
        last_r  <= 0;
        raw_r   <= (others => '0');
      else

        if busy_r = '0' then
          if msg_take = '1' then
            raw_r  <= raw;
            last_r <= f_last_beat(msg_type_i);
            beat_r <= 0;
            busy_r <= '1';
          end if;
        else
          if beat_r = last_r then
            busy_r <= '0';
            beat_r <= 0;
          else
            beat_r <= beat_r + 1;
          end if;
        end if;

      end if;
    end if;
  end process p_serialise;

  eng_tvalid <= busy_r;
  eng_tlast  <= '1' when busy_r = '1' and beat_r = last_r else '0';

  p_lane : process (all) is
  begin
    eng_tdata <= (others => '0');
    for k in 0 to C_BEATS - 1 loop
      if k = beat_r then
        eng_tdata <= raw_r(C_BEAT_W * k + C_BEAT_W - 1 downto C_BEAT_W * k);
      end if;
    end loop;
  end process p_lane;

  -- A message arriving while the previous one is still being shifted out is
  -- lost. Serialising only to the emit beat keeps the adapter at line rate for
  -- every book type, so this should never fire.
  msg_dropped <= msg_take and busy_r;

  assert not (rising_edge(clk) and msg_take = '1' and busy_r = '1')
    report "market_data_top: message dropped, adapter still serialising"
    severity failure;

  ------------------------------------------------------------------------------
  -- Order book engine
  ------------------------------------------------------------------------------
  u_engine : entity work.order_book_engine_top
    generic map (
      G_ORDER_BOOK_ID => G_ORDER_BOOK_ID,
      G_FIFO_DEPTH    => G_FIFO_DEPTH,
      G_MAX_ORDERS    => G_MAX_ORDERS
    )
    port map (
      clk           => clk,
      resetn        => resetn,

      s_tvalid      => eng_tvalid,
      s_tready      => eng_tready,
      s_tdata       => eng_tdata,
      s_tlast       => eng_tlast,

      base_price    => base_price,

      m_tvalid      => m_tvalid,
      m_tready      => m_tready,
      m_bid_price   => m_bid_price,
      m_bid_qty     => m_bid_qty,
      m_ask_price   => m_ask_price,
      m_ask_qty     => m_ask_qty,
      m_valid       => m_valid,

      book_busy     => book_busy,
      level_busy    => level_busy,
      oor           => oor,
      fifo_full     => fifo_full,
      fifo_overflow => fifo_overflow
    );

end architecture rtl;
