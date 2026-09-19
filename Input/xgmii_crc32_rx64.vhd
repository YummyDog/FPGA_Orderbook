--------------------------------------------------------------------------------
-- XGMII (64-bit) receive FCS checker
-- Lane 0 = rxd(7:0)/rxc(0), bit 0 first on the wire.
-- Expects preamble/SFD present in one beat: |S 55 55 55 55 55 55 D5| data ...
-- Assumes /S/ is always in lane 0.
-- Latency: crc_complete aligns with the terminating word delayed by
-- C_XGMII_CRC32_LATENCY registers. Aborted frames (new /S/ before /T/)
-- report fcs_false aligned with that /S/ word instead.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package xgmii_crc32_rx64_pkg is
  constant C_XGMII_CRC32_LATENCY : natural := 3;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xgmii_crc32_rx64 is
  generic (
    G_CHECK_PREAMBLE : boolean := true  -- false: only SFD byte is checked
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;  -- synchronous, active high
    xgmii_rxd    : in  std_logic_vector(63 downto 0);
    xgmii_rxc    : in  std_logic_vector(7 downto 0);
    crc_complete : out std_logic;
    fcs_true     : out std_logic;
    fcs_false    : out std_logic
  );
end entity;

architecture rtl of xgmii_crc32_rx64 is

  constant C_POLY    : std_logic_vector(31 downto 0) := x"EDB88320";
  constant C_RESIDUE : std_logic_vector(31 downto 0) := x"DEBB20E3";
  constant C_START   : std_logic_vector(7 downto 0)  := x"FB";
  constant C_TERM    : std_logic_vector(7 downto 0)  := x"FD";
  constant C_PRE     : std_logic_vector(55 downto 0) := x"D5555555555555";

  -- Reflected CRC32 update over nb bytes, LSB first
  function crc_upd(crc : std_logic_vector(31 downto 0);
                   d   : std_logic_vector;
                   nb  : natural) return std_logic_vector is
    variable c  : std_logic_vector(31 downto 0) := crc;
    variable dv : std_logic_vector(d'length-1 downto 0) := d;
    variable fb : std_logic;
  begin
    for i in 0 to nb*8-1 loop
      fb := c(0) xor dv(i);
      c  := ('0' & c(31 downto 1)) xor (C_POLY and (C_POLY'range => fb));
    end loop;
    return c;
  end function;

  type t_cand is array (0 to 7) of std_logic_vector(31 downto 0);

  -- Stage 0: registered input and decode
  signal s0_d      : std_logic_vector(63 downto 0) := (others => '0');
  signal s0_data   : std_logic := '0';
  signal s0_start  : std_logic := '0';
  signal s0_pre_ok : std_logic := '0';
  signal s0_term   : std_logic := '0';
  signal s0_terr   : std_logic := '0';
  signal s0_tsel   : unsigned(2 downto 0) := (others => '0');

  -- Stage 1: frame tracking and CRC
  signal in_frame : std_logic := '0';
  signal bad      : std_logic := '0';
  signal cnt      : unsigned(3 downto 0) := (others => '0');
  signal crc      : std_logic_vector(31 downto 0) := (others => '1');
  signal crc_init : std_logic;
  signal crc_ce   : std_logic;
  signal cand     : t_cand := (others => (others => '0'));
  signal s1_tsel  : unsigned(2 downto 0) := (others => '0');
  signal s1_evt   : std_logic := '0';
  signal s1_ok    : std_logic := '0';

begin

  ------------------------------------------------------------------------------
  stage0 : process(clk)
    variable is_t      : std_logic_vector(7 downto 0);
    variable ctl       : std_logic;
    variable ctl_below : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      for i in 0 to 7 loop
        if xgmii_rxc(i) = '1' and xgmii_rxd(8*i+7 downto 8*i) = C_TERM then
          is_t(i) := '1';
        else
          is_t(i) := '0';
        end if;
      end loop;

      s0_d     <= xgmii_rxd;
      s0_data  <= '1' when xgmii_rxc = x"00" else '0';
      s0_start <= '1' when xgmii_rxc(0) = '1' and xgmii_rxd(7 downto 0) = C_START else '0';

      -- Preamble and SFD share the /S/ word
      if xgmii_rxc(7 downto 1) = "0000000" and xgmii_rxd(63 downto 56) = x"D5" and
         (xgmii_rxd(55 downto 8) = C_PRE(47 downto 0) or not G_CHECK_PREAMBLE) then
        s0_pre_ok <= '1';
      else
        s0_pre_ok <= '0';
      end if;

      -- First /T/ sets the tail length; any control before it is an error
      s0_term <= is_t(0) or is_t(1) or is_t(2) or is_t(3) or
                 is_t(4) or is_t(5) or is_t(6) or is_t(7);

      ctl := '0';
      for i in 0 to 7 loop
        ctl_below(i) := ctl;
        ctl := ctl or xgmii_rxc(i);
      end loop;

      s0_tsel <= "111";
      s0_terr <= '0';
      for i in 7 downto 0 loop      -- lowest /T/ assigned last, so it wins
        if is_t(i) = '1' then
          s0_tsel <= to_unsigned(i, 3);
          s0_terr <= ctl_below(i);
        end if;
      end loop;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Kept as simple decodes so they map to FDSE S/CE pins
  crc_init <= s0_start;
  crc_ce   <= '1' when in_frame = '1' and s0_start = '0' and s0_term = '0'
                     and s0_data = '1' else '0';

  crc_reg : process(clk)
  begin
    if rising_edge(clk) then
      if crc_init = '1' then
        crc <= (others => '1');
      elsif crc_ce = '1' then
        crc <= crc_upd(crc, s0_d, 8);
      end if;
    end if;
  end process;

  stage1 : process(clk)
    variable evt : std_logic;
    variable ok  : std_logic;
  begin
    if rising_edge(clk) then
      cand(0) <= crc;
      for n in 1 to 7 loop
        cand(n) <= crc_upd(crc, s0_d(8*n-1 downto 0), n);
      end loop;
      s1_tsel <= s0_tsel;

      evt := '0';
      ok  := '0';

      if s0_start = '1' then
        if in_frame = '1' then
          evt := '1';  -- previous frame never terminated
        end if;
        in_frame <= '1';
        bad      <= not s0_pre_ok;
        cnt      <= (others => '0');

      elsif in_frame = '1' then
        if s0_term = '1' then
          evt      := '1';
          ok       := not (bad or s0_terr) and cnt(3);  -- >= 64 bytes
          in_frame <= '0';
        elsif s0_data = '1' then
          if cnt(3) = '0' then
            cnt <= cnt + 1;
          end if;
        else
          bad <= '1';
        end if;
      end if;

      s1_evt <= evt;
      s1_ok  <= ok;

      if rst = '1' then
        in_frame <= '0';
        s1_evt   <= '0';
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  stage2 : process(clk)
    variable csel  : std_logic_vector(31 downto 0);
    variable match : std_logic;
  begin
    if rising_edge(clk) then
      csel  := cand(to_integer(s1_tsel));
      match := '1' when csel = C_RESIDUE else '0';

      crc_complete <= s1_evt;
      fcs_true     <= s1_evt and s1_ok and match;
      fcs_false    <= s1_evt and not (s1_ok and match);

      if rst = '1' then
        crc_complete <= '0';
        fcs_true     <= '0';
        fcs_false    <= '0';
      end if;
    end if;
  end process;

end architecture;
