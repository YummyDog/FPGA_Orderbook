--------------------------------------------------------------------------------
-- order_tx_xgmii
--
-- Builds one UDP/IPv4/Ethernet frame per enable pulse and drives it out on a
-- 64-bit XGMII bus, preamble and SFD included, FCS appended, followed by the
-- interpacket gap.
--
-- Everything editable (addresses, ports, payload layout) is in order_tx_pkg.
--
-- enable is a single-cycle pulse; side, qty and price are sampled with it and
-- ignored while busy is high. The preamble beat goes out one cycle after the
-- pulse is sampled.
--
-- Frame on the wire:
--   beat 0        S 55 55 55 55 55 55 D5
--   beats 1..N    Ethernet + IPv4 + UDP + payload  (N = C_WORDS)
--   beat N+1      FCS[4] T I I I
--   then          G_IPG_WORDS idle beats
--
-- The payload padding in the package makes the pre-FCS length a multiple of 8,
-- so the CRC is complete and registered before the FCS beat is driven. No
-- combinational CRC tail, no straddled beat.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.order_tx_pkg.all;

entity order_tx_xgmii is
  generic (
    -- Idle beats after the terminate beat. The terminate beat already carries
    -- 3 idle bytes, so 2 gives a 19-byte gap; 1 still meets the 12-byte minimum.
    G_IPG_WORDS : positive := 2
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;                      -- synchronous, active high

    enable    : in  std_logic;                      -- 1-cycle pulse
    side      : in  std_logic;                      -- '0' buy, '1' sell
    qty       : in  std_logic_vector(31 downto 0);
    price     : in  std_logic_vector(31 downto 0);
    busy      : out std_logic;

    xgmii_txd : out std_logic_vector(63 downto 0);
    xgmii_txc : out std_logic_vector(7 downto 0)
  );
end entity order_tx_xgmii;

architecture rtl of order_tx_xgmii is

  constant C_POLY : std_logic_vector(31 downto 0) := x"EDB88320";

  constant C_IDLE_D : std_logic_vector(63 downto 0) :=
    C_XGMII_IDLE & C_XGMII_IDLE & C_XGMII_IDLE & C_XGMII_IDLE &
    C_XGMII_IDLE & C_XGMII_IDLE & C_XGMII_IDLE & C_XGMII_IDLE;

  -- Preamble beat: lane 0 is the /S/, lane 7 the SFD
  constant C_PRE_D : std_logic_vector(63 downto 0) :=
    x"D5" & x"55" & x"55" & x"55" & x"55" & x"55" & x"55" & C_XGMII_START;

  -- Reflected CRC32 update over nb bytes, LSB first
  function crc_upd (crc : std_logic_vector(31 downto 0);
                    d   : std_logic_vector;
                    nb  : natural) return std_logic_vector is
    variable c  : std_logic_vector(31 downto 0) := crc;
    variable dv : std_logic_vector(d'length - 1 downto 0) := d;
    variable fb : std_logic;
  begin
    for i in 0 to nb * 8 - 1 loop
      fb := c(0) xor dv(i);
      c  := ('0' & c(31 downto 1)) xor (C_POLY and (C_POLY'range => fb));
    end loop;
    return c;
  end function crc_upd;

  -- Byte n of the frame becomes lane n of its beat
  function f_word (f : t_bytes; idx : natural) return std_logic_vector is
    variable w : std_logic_vector(63 downto 0);
  begin
    for k in 0 to 7 loop
      w(8 * k + 7 downto 8 * k) := f(8 * idx + k);
    end loop;
    return w;
  end function f_word;

  type t_state is (S_IDLE, S_DATA, S_FCS, S_GAP);

  signal state   : t_state := S_IDLE;
  signal idx     : natural range 0 to C_WORDS - 1 := 0;
  signal gap_cnt : natural range 0 to G_IPG_WORDS := 0;

  signal side_r  : std_logic_vector(7 downto 0) := (others => '0');
  signal qty_r   : std_logic_vector(31 downto 0) := (others => '0');
  signal price_r : std_logic_vector(31 downto 0) := (others => '0');

  signal crc     : std_logic_vector(31 downto 0) := (others => '1');

  signal txd_r   : std_logic_vector(63 downto 0) := C_IDLE_D;
  signal txc_r   : std_logic_vector(7 downto 0)  := (others => '1');

  signal frame_c : t_bytes(0 to C_FRAME_LEN - 1);
  signal word_c  : std_logic_vector(63 downto 0);

begin

  ------------------------------------------------------------------------------
  -- The frame, built combinationally from the sampled fields. Only the nine
  -- payload bytes vary; everything else folds to constants.
  ------------------------------------------------------------------------------
  frame_c <= f_frame(side_r, qty_r, price_r);
  word_c  <= f_word(frame_c, idx);

  ------------------------------------------------------------------------------
  process (clk) is
  begin
    if rising_edge(clk) then

      txd_r <= C_IDLE_D;
      txc_r <= (others => '1');

      case state is

        when S_IDLE =>
          if enable = '1' then
            side_r  <= C_SIDE_SELL when side = '1' else C_SIDE_BUY;
            qty_r   <= qty;
            price_r <= price;

            txd_r   <= C_PRE_D;
            txc_r   <= "00000001";           -- /S/ in lane 0
            crc     <= (others => '1');
            idx     <= 0;
            state   <= S_DATA;
          end if;

        when S_DATA =>
          txd_r <= word_c;
          txc_r <= (others => '0');
          crc   <= crc_upd(crc, word_c, 8);

          if idx = C_WORDS - 1 then
            state <= S_FCS;
          else
            idx <= idx + 1;
          end if;

        when S_FCS =>
          -- FCS is the complement of the register, low byte first
          txd_r <= C_XGMII_IDLE & C_XGMII_IDLE & C_XGMII_IDLE & C_XGMII_TERM &
                   not crc(31 downto 24) & not crc(23 downto 16) &
                   not crc(15 downto 8)  & not crc(7 downto 0);
          txc_r   <= "11110000";             -- /T/ in lane 4, idles above
          gap_cnt <= 0;
          state   <= S_GAP;

        when S_GAP =>
          if gap_cnt = G_IPG_WORDS - 1 then
            state <= S_IDLE;
          else
            gap_cnt <= gap_cnt + 1;
          end if;

      end case;

      if rst = '1' then
        state <= S_IDLE;
        idx   <= 0;
        txd_r <= C_IDLE_D;
        txc_r <= (others => '1');
      end if;
    end if;
  end process;

  xgmii_txd <= txd_r;
  xgmii_txc <= txc_r;

  busy <= '0' when state = S_IDLE else '1';

end architecture rtl;
