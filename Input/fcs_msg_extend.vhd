--------------------------------------------------------------------------------
-- Stretches crc_complete / fcs_true / fcs_false to msg_count cycles in the
-- core clock domain. The FCS result (from the 312.5 MHz domain) and
-- msg_count_valid (core domain) are paired in arrival order, one of each per
-- packet; whichever arrives first is held until the other arrives.
-- Consecutive results may run back-to-back with no low cycle between them.
-- pair_err pulses if a second result or count arrives while one is still
-- waiting for its partner (the newer one is discarded).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fcs_msg_extend is
  generic (
    G_COUNT_W     : positive := 16;
    G_ZERO_AS_ONE : boolean  := true  -- false: count of 0 produces no output
  );
  port (
    -- 312.5 MHz domain
    src_clk          : in  std_logic;
    src_crc_complete : in  std_logic;
    src_fcs_true     : in  std_logic;
    src_fcs_false    : in  std_logic;
    src_drop         : out std_logic;
    -- core domain (synchronous active-high reset)
    clk              : in  std_logic;
    rst              : in  std_logic;
    msg_count        : in  std_logic_vector(G_COUNT_W-1 downto 0);
    msg_count_valid  : in  std_logic;
    ext_complete     : out std_logic;
    ext_fcs_true     : out std_logic;
    ext_fcs_false    : out std_logic;
    pair_err         : out std_logic
  );
end entity;

architecture rtl of fcs_msg_extend is

  signal in_cmp, in_true, in_false : std_logic;

  signal res_v   : std_logic := '0';
  signal res_t   : std_logic := '0';
  signal res_f   : std_logic := '0';
  signal cnt_v   : std_logic := '0';
  signal cnt_h   : unsigned(G_COUNT_W-1 downto 0) := (others => '0');

  signal active  : std_logic := '0';
  signal remain  : unsigned(G_COUNT_W-1 downto 0) := (others => '0');
  signal o_true  : std_logic := '0';
  signal o_false : std_logic := '0';
  signal err_r   : std_logic := '0';

begin

  u_cdc : entity work.fcs_cdc
    port map (
      src_clk       => src_clk,
      src_complete  => src_crc_complete,
      src_fcs_true  => src_fcs_true,
      src_fcs_false => src_fcs_false,
      src_drop      => src_drop,
      dst_clk       => clk,
      dst_rst       => rst,
      dst_complete  => in_cmp,
      dst_fcs_true  => in_true,
      dst_fcs_false => in_false
    );

  process(clk)
    variable h_rv, h_rt, h_rf : std_logic;
    variable h_cv             : std_logic;
    variable h_c              : unsigned(G_COUNT_W-1 downto 0);
    variable free, load, zero : boolean;
  begin
    if rising_edge(clk) then
      err_r <= '0';

      -- Head of each queue: held entry first, else this cycle's arrival
      if res_v = '1' then
        h_rv := '1'; h_rt := res_t; h_rf := res_f;
      else
        h_rv := in_cmp; h_rt := in_true; h_rf := in_false;
      end if;

      if cnt_v = '1' then
        h_cv := '1'; h_c := cnt_h;
      else
        h_cv := msg_count_valid; h_c := unsigned(msg_count);
      end if;

      free := active = '0' or remain = 0;
      load := free and h_rv = '1' and h_cv = '1';
      zero := h_c = 0;

      -- Extension counter
      if load and not (zero and not G_ZERO_AS_ONE) then
        active  <= '1';
        o_true  <= h_rt;
        o_false <= h_rf;
        if zero then
          remain <= (others => '0');
        else
          remain <= h_c - 1;
        end if;
      elsif free then
        active  <= '0';
        o_true  <= '0';
        o_false <= '0';
      else
        remain <= remain - 1;
      end if;

      -- Result hold
      if res_v = '1' then
        if load then
          res_v <= in_cmp; res_t <= in_true; res_f <= in_false;
        elsif in_cmp = '1' then
          err_r <= '1';
        end if;
      elsif not load then
        res_v <= in_cmp; res_t <= in_true; res_f <= in_false;
      end if;

      -- Count hold
      if cnt_v = '1' then
        if load then
          cnt_v <= msg_count_valid; cnt_h <= unsigned(msg_count);
        elsif msg_count_valid = '1' then
          err_r <= '1';
        end if;
      elsif not load then
        cnt_v <= msg_count_valid; cnt_h <= unsigned(msg_count);
      end if;

      if rst = '1' then
        res_v   <= '0';
        cnt_v   <= '0';
        active  <= '0';
        o_true  <= '0';
        o_false <= '0';
        err_r   <= '0';
      end if;
    end if;
  end process;

  ext_complete  <= active;
  ext_fcs_true  <= o_true;
  ext_fcs_false <= o_false;
  pair_err      <= err_r;

end architecture;
