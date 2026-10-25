--------------------------------------------------------------------------------
-- fan_pwm
--
-- Fan PWM for the block design (add as a Module Reference).
--
-- Runs on the board's free-running 25 MHz oscillator, not on the GT clock, so
-- the fan spins as soon as the FPGA is configured - even if the transceiver
-- reference clock is missing or the PCS never comes out of reset.
--
-- PWM frequency 25 kHz: the Intel 4-wire fan spec asks for 21-28 kHz, and
-- anything above ~20 kHz is inaudible if the pin is instead switching fan
-- power through a transistor. (The old 1 kHz was below the 4-wire range and
-- whines on a switched fan.)
--
-- 1000 steps per period (0.1 % resolution) at 25 MHz / 25 kHz.
--
-- Duty is a generic for now. 100 % gives a constant "on" level with no
-- toggling. Any non-zero duty below G_MIN_DUTY_PCT is raised to it, since most
-- fans stall or fail to start below ~20-30 %.
--
-- No reset: the counter and output start from their configuration values.
--
-- VHDL-93 / VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity fan_pwm is
  generic (
    G_CLK_HZ       : positive               := 25_000_000;
    G_PWM_HZ       : positive               := 25_000;
    G_DUTY_PCT     : natural range 0 to 100 := 100;  -- always on for now
    G_MIN_DUTY_PCT : natural range 0 to 100 := 30;
    G_ACTIVE_HIGH  : boolean                := true   -- false if the board inverts
  );
  port (
    clk : in    std_logic;
    fan : out   std_logic
  );

  -- Tells the block design this is a 25 MHz clock pin
  attribute X_INTERFACE_INFO      : string;
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_INFO      of clk : signal is "xilinx.com:signal:clock:1.0 clk CLK";
  attribute X_INTERFACE_PARAMETER of clk : signal is "FREQ_HZ 25000000";
end entity fan_pwm;

architecture rtl of fan_pwm is

  constant C_PERIOD : positive := G_CLK_HZ / G_PWM_HZ;   -- 1000 at defaults

  function clamp_duty (pct, min_pct : natural) return natural is
  begin
    if pct = 0 then
      return 0;
    elsif pct < min_pct then
      return min_pct;
    else
      return pct;
    end if;
  end function;

  constant C_DUTY_PCT : natural  := clamp_duty(G_DUTY_PCT, G_MIN_DUTY_PCT);
  constant C_ON_COUNT : natural  := (C_PERIOD * C_DUTY_PCT) / 100;

  function on_level (active_high : boolean) return std_logic is
  begin
    if active_high then
      return '1';
    else
      return '0';
    end if;
  end function;

  constant C_ON  : std_logic := on_level(G_ACTIVE_HIGH);
  constant C_OFF : std_logic := not C_ON;

  signal count : natural range 0 to C_PERIOD - 1 := 0;
  signal pwm_r : std_logic := C_ON;   -- on from the first cycle after configuration

begin

  process (clk)
  begin
    if rising_edge(clk) then
      if count = C_PERIOD - 1 then
        count <= 0;
      else
        count <= count + 1;
      end if;

      if count < C_ON_COUNT then
        pwm_r <= C_ON;
      else
        pwm_r <= C_OFF;
      end if;
    end if;
  end process;

  fan <= pwm_r;

end architecture rtl;
