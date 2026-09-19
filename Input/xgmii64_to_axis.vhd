--------------------------------------------------------------------------------
-- 64-bit XGMII to AXI4-Stream. Strips the first beat (preamble + SFD) and
-- presents the rest of the frame, FCS included, as a packet.
--
-- Assumes /S/ is always in lane 0, so preamble and SFD occupy exactly the
-- first beat and the payload is 8-byte aligned.
--
-- The data path holds one beat so tlast can be placed on the correct beat when
-- /T/ lands in lane 0. tdata appears 3 cycles after its word was on the XGMII
-- bus. tready is monitored but cannot stall anything; overflow pulses if a beat
-- is presented while tready is low.
--
-- tuser(0) on the last beat flags a bad frame: bad preamble/SFD, a control
-- character before /T/, or a frame closed by a new /S/ or by loss of data.
-- The FCS is not checked here.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xgmii64_to_axis is
  generic (
    G_CHECK_PREAMBLE : boolean := true
  );
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;  -- synchronous, active high
    xgmii_rxd     : in  std_logic_vector(63 downto 0);
    xgmii_rxc     : in  std_logic_vector(7 downto 0);
    m_axis_tdata  : out std_logic_vector(63 downto 0);
    m_axis_tkeep  : out std_logic_vector(7 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;
    m_axis_tlast  : out std_logic;
    m_axis_tuser  : out std_logic_vector(0 downto 0);
    overflow      : out std_logic
  );
end entity;

architecture rtl of xgmii64_to_axis is

  constant C_START : std_logic_vector(7 downto 0)  := x"FB";
  constant C_TERM  : std_logic_vector(7 downto 0)  := x"FD";
  constant C_PRE   : std_logic_vector(55 downto 0) := x"D5555555555555";

  -- tkeep for a final beat carrying n bytes
  function keep_of(n : unsigned(2 downto 0)) return std_logic_vector is
    variable k : std_logic_vector(7 downto 0) := (others => '0');
  begin
    for i in 0 to 7 loop
      if i < to_integer(n) then
        k(i) := '1';
      end if;
    end loop;
    return k;
  end function;

  -- Stage 0: registered input and decode
  signal s0_d      : std_logic_vector(63 downto 0) := (others => '0');
  signal s0_data   : std_logic := '0';
  signal s0_start  : std_logic := '0';
  signal s0_pre_ok : std_logic := '0';
  signal s0_term   : std_logic := '0';
  signal s0_terr   : std_logic := '0';
  signal s0_tsel   : unsigned(2 downto 0) := (others => '0');

  -- Stage 1: held beat
  signal in_frame : std_logic := '0';
  signal frm_err  : std_logic := '0';
  signal h_v      : std_logic := '0';
  signal h_d      : std_logic_vector(63 downto 0) := (others => '0');
  signal h_keep   : std_logic_vector(7 downto 0) := (others => '0');
  signal h_last   : std_logic := '0';
  signal h_err    : std_logic := '0';

  signal o_v    : std_logic := '0';
  signal o_d    : std_logic_vector(63 downto 0) := (others => '0');
  signal o_keep : std_logic_vector(7 downto 0) := (others => '0');
  signal o_last : std_logic := '0';
  signal o_err  : std_logic := '0';

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

      if xgmii_rxc(7 downto 1) = "0000000" and
         (xgmii_rxd(63 downto 8) = C_PRE or not G_CHECK_PREAMBLE) then
        s0_pre_ok <= '1';
      else
        s0_pre_ok <= '0';
      end if;

      -- First /T/ sets the tail length; any control before it is an error
      s0_term <= is_t(0) or is_t(1) or is_t(2) or is_t(3) or
                 is_t(4) or is_t(5) or is_t(6) or is_t(7);
      ctl := '0';
      for i in 0 to 7 loop          -- control present in a lane below lane i
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
  stage1 : process(clk)
    variable push, force_last, err_now : std_logic;
    variable n_keep : std_logic_vector(7 downto 0);
    variable n_last : std_logic;
  begin
    if rising_edge(clk) then
      push       := '0';
      force_last := '0';
      n_keep     := x"FF";
      n_last     := '0';
      err_now    := frm_err;

      if s0_start = '1' then
        if in_frame = '1' then
          force_last := '1';        -- close the previous packet
          err_now    := '1';
        end if;
        in_frame <= '1';
        frm_err  <= not s0_pre_ok;

      elsif in_frame = '1' then
        if s0_term = '1' then
          err_now  := frm_err or s0_terr;
          in_frame <= '0';
          if s0_tsel = 0 then
            force_last := '1';      -- last data beat was the held one
          else
            push   := '1';
            n_last := '1';
            n_keep := keep_of(s0_tsel);
          end if;
        elsif s0_data = '1' then
          push := '1';
        else
          force_last := '1';        -- data lost, close the packet
          err_now    := '1';
          in_frame   <= '0';
        end if;
      end if;

      -- Emit the held beat when a new one arrives or the packet must close
      o_v <= '0';
      if h_v = '1' and (push or h_last or force_last) = '1' then
        o_v    <= '1';
        o_d    <= h_d;
        o_keep <= h_keep;
        o_last <= h_last or force_last;
        o_err  <= h_err or (force_last and err_now);
        h_v    <= '0';
      end if;

      if push = '1' then
        h_v    <= '1';
        h_d    <= s0_d;
        h_keep <= n_keep;
        h_last <= n_last;
        h_err  <= err_now and n_last;
      end if;

      if rst = '1' then
        in_frame <= '0';
        h_v      <= '0';
        h_last   <= '0';
        o_v      <= '0';
      end if;
    end if;
  end process;

  m_axis_tdata  <= o_d;
  m_axis_tkeep  <= o_keep;
  m_axis_tvalid <= o_v;
  m_axis_tlast  <= o_last;
  m_axis_tuser(0) <= o_err;

  overflow <= o_v and not m_axis_tready;

end architecture;
