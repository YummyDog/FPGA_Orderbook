--------------------------------------------------------------------------------
-- time_event_fifo
-- 4-source event FIFO with a registered AXI-Stream style output.
-- Events arriving in the same clock are stacked price, order, input, fifo;
-- output order is first in, first out.
-- event_type: price "00", order "01", input "10", fifo "11".
-- Latency: 1 clock (event sampled on an edge is on the output after that edge).
-- Throughput: 1 beat per clock. Overflow is not handled.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity time_event_fifo is
  generic (
    DEPTH : positive := 32   -- power of two, >= 8
  );
  port (
    clk          : in  std_logic;
    rst_n        : in  std_logic;   -- synchronous, active low

    price_valid  : in  std_logic;
    price_op     : in  std_logic_vector(1 downto 0);
    price_data   : in  std_logic_vector(64 downto 0);
    price_ts     : in  std_logic_vector(17 downto 0);

    order_valid  : in  std_logic;
    order_op     : in  std_logic_vector(1 downto 0);
    order_data   : in  std_logic_vector(64 downto 0);
    order_ts     : in  std_logic_vector(17 downto 0);

    input_valid  : in  std_logic;
    input_op     : in  std_logic_vector(1 downto 0);
    input_data   : in  std_logic_vector(64 downto 0);
    input_ts     : in  std_logic_vector(17 downto 0);

    fifo_valid   : in  std_logic;
    fifo_op      : in  std_logic_vector(1 downto 0);
    fifo_data    : in  std_logic_vector(64 downto 0);
    fifo_ts      : in  std_logic_vector(17 downto 0);

    m_valid      : out std_logic;
    m_ready      : in  std_logic;
    m_event_type : out std_logic_vector(1 downto 0);
    m_op         : out std_logic_vector(1 downto 0);
    m_data       : out std_logic_vector(64 downto 0);
    m_ts         : out std_logic_vector(17 downto 0)
  );
end entity time_event_fifo;

architecture rtl of time_event_fifo is

  function clog2 (n : positive) return natural is
    variable r : natural  := 0;
    variable v : positive := 1;
  begin
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  constant N_SRC   : natural := 4;
  constant N_BANK  : natural := 4;
  constant IDX_W   : natural := clog2(DEPTH);
  constant PTR_W   : natural := IDX_W + 1;      -- extra bit so 32 stored /= empty
  constant BADDR_W : natural := IDX_W - 2;
  constant BDEPTH  : natural := DEPTH / N_BANK;

  constant ET_W    : natural := 2;
  constant OP_W    : natural := 2;
  constant DATA_W  : natural := 65;
  constant TS_W    : natural := 18;
  constant PL_W    : natural := ET_W + OP_W + DATA_W + TS_W;

  subtype payload_t     is std_logic_vector(PL_W - 1 downto 0);
  type    payload_arr_t is array (0 to N_SRC - 1) of payload_t;
  subtype src_vec_t     is std_logic_vector(N_SRC - 1 downto 0);
  subtype baddr_t       is unsigned(BADDR_W - 1 downto 0);
  type    bank_t        is array (0 to BDEPTH - 1) of payload_t;
  type    mem_t         is array (0 to N_BANK - 1) of bank_t;
  type    bank_rd_t     is array (0 to N_BANK - 1) of payload_t;

  -- Slot s is stored in bank s mod 4, entry s / 4.
  signal mem     : mem_t;

  signal in_v    : src_vec_t;
  signal in_pl   : payload_arr_t;
  signal any_v   : std_logic;
  signal first_pl: payload_t;

  signal wp      : unsigned(PTR_W - 1 downto 0) := (others => '0');
  signal rp      : unsigned(PTR_W - 1 downto 0) := (others => '0');
  signal st_ne   : std_logic := '0';            -- storage holds unread entries

  signal rd_bank : bank_rd_t;
  signal rd_pl   : payload_t;
  signal out_v   : std_logic := '0';
  signal out_pl  : payload_t;
  signal load    : std_logic;

  -- Number of valid higher-priority sources ahead of source i.
  function rank (v : src_vec_t; i : natural) return unsigned is
    variable r : unsigned(1 downto 0) := (others => '0');
  begin
    for k in 0 to N_SRC - 1 loop
      if k < i and v(k) = '1' then
        r := r + 1;
      end if;
    end loop;
    return r;
  end function;

  function popcount (v : src_vec_t) return unsigned is
    variable r : unsigned(2 downto 0) := (others => '0');
  begin
    for k in 0 to N_SRC - 1 loop
      if v(k) = '1' then
        r := r + 1;
      end if;
    end loop;
    return r;
  end function;

begin

  assert DEPTH >= 8 and 2 ** IDX_W = DEPTH
    report "time_event_fifo: DEPTH must be a power of two and >= 8"
    severity failure;

  -- Index = priority (0 highest).
  in_v     <= fifo_valid & input_valid & order_valid & price_valid;
  in_pl(0) <= "00" & price_op & price_data & price_ts;
  in_pl(1) <= "01" & order_op & order_data & order_ts;
  in_pl(2) <= "10" & input_op & input_data & input_ts;
  in_pl(3) <= "11" & fifo_op  & fifo_data  & fifo_ts;

  any_v    <= in_v(0) or in_v(1) or in_v(2) or in_v(3);
  first_pl <= in_pl(0) when in_v(0) = '1' else
              in_pl(1) when in_v(1) = '1' else
              in_pl(2) when in_v(2) = '1' else
              in_pl(3);

  -- Every valid event is written to slot wp + rank. When the FIFO is empty the
  -- first one is also loaded straight into the output and its slot skipped.
  p_wr : process (clk)
    variable wlo : unsigned(1 downto 0);
    variable row : baddr_t;
    variable adr : baddr_t;
    variable wd  : payload_t;
    variable we  : std_logic;
  begin
    if rising_edge(clk) then
      wlo := wp(1 downto 0);
      row := wp(IDX_W - 1 downto 2);
      for b in 0 to N_BANK - 1 loop
        wd := (others => '0');
        we := '0';
        for i in 0 to N_SRC - 1 loop
          if in_v(i) = '1' and wlo + rank(in_v, i) = to_unsigned(b, 2) then
            wd := wd or in_pl(i);
            we := '1';
          end if;
        end loop;
        if to_unsigned(b, 2) < wlo then
          adr := row + 1;
        else
          adr := row;
        end if;
        for e in 0 to BDEPTH - 1 loop
          if we = '1' and adr = to_unsigned(e, BADDR_W) then
            mem(b)(e) <= wd;
          end if;
        end loop;
      end loop;
    end if;
  end process;

  g_rd : for b in 0 to N_BANK - 1 generate
    rd_bank(b) <= mem(b)(to_integer(rp(IDX_W - 1 downto 2)));
  end generate;
  rd_pl <= rd_bank(to_integer(rp(1 downto 0)));

  load <= (not out_v or m_ready) and (st_ne or any_v);

  p_ctl : process (clk)
    variable wp_n : unsigned(PTR_W - 1 downto 0);
    variable rp_n : unsigned(PTR_W - 1 downto 0);
  begin
    if rising_edge(clk) then
      wp_n := wp + resize(popcount(in_v), PTR_W);
      if load = '1' then
        rp_n := rp + 1;
      else
        rp_n := rp;
      end if;

      if load = '1' then
        if st_ne = '1' then
          out_pl <= rd_pl;
        else
          out_pl <= first_pl;
        end if;
        out_v <= '1';
      elsif m_ready = '1' then
        out_v <= '0';
      end if;

      wp <= wp_n;
      rp <= rp_n;
      if wp_n /= rp_n then
        st_ne <= '1';
      else
        st_ne <= '0';
      end if;

      if rst_n = '0' then
        wp    <= (others => '0');
        rp    <= (others => '0');
        st_ne <= '0';
        out_v <= '0';
      end if;
    end if;
  end process;

  m_valid      <= out_v;
  m_event_type <= out_pl(PL_W - 1 downto OP_W + DATA_W + TS_W);
  m_op         <= out_pl(OP_W + DATA_W + TS_W - 1 downto DATA_W + TS_W);
  m_data       <= out_pl(DATA_W + TS_W - 1 downto TS_W);
  m_ts         <= out_pl(TS_W - 1 downto 0);

end architecture rtl;
