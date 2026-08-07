--------------------------------------------------------------------------------
-- threeparserpipline
--
-- Top-level wrapper chaining the first three parser stages:
--
--     eth_parser  ->  ipv4_parser  ->  udp_parser
--
-- AXI-Stream in, AXI-Stream out, plus the accumulated flat field bus:
--
--     bits [129:0]     Ethernet   (130 bits)
--     bits [293:130]   IPv4       (164 bits)
--     bits [359:294]   UDP        ( 66 bits)
--                                 ----------
--                                  360 bits
--
-- Latency: 3 cycles, one register stage per module, on BOTH the data path
-- and the field bus. That is what keeps the two aligned - m_fields_valid
-- coincides with the output beat that completed the UDP header.
--
-- Throughput: one 8-byte beat per cycle end to end. No buffering anywhere.
-- s_axis_tready is tied high by every stage.
--
-- The per-stage fields_valid pulses are brought out for verification. NOTE
-- they are NOT time-aligned with m_axis: eth_fields_valid fires two cycles
-- before the beat it describes reaches m_axis, because it originates two
-- register stages upstream. Only udp_fields_valid (= m_fields_valid) is
-- aligned with the output beat.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;
use work.udp_parser_pkg.all;

entity threeparserpipline is
  generic (
    G_TPID : std_logic_vector(15 downto 0) := x"8100"
  );
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;                        -- synchronous, active low

    -- AXI-Stream slave -------------------------------------------------------
    s_axis_tdata  : in  std_logic_vector(63 downto 0);
    s_axis_tkeep  : in  std_logic_vector(7 downto 0);
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic;                 -- tied high, never stalls
    s_axis_tlast  : in  std_logic;

    -- AXI-Stream master ------------------------------------------------------
    m_axis_tdata  : out std_logic_vector(63 downto 0);
    m_axis_tkeep  : out std_logic_vector(7 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;                 -- UNUSED, parsers never stall
    m_axis_tlast  : out std_logic;

    -- Accumulated field bus --------------------------------------------------
    m_fields       : out std_logic_vector(C_UDP_BUS_W-1 downto 0);
    m_fields_valid : out std_logic;                -- = udp_fields_valid

    -- Per-stage completion pulses, for verification --------------------------
    eth_fields_valid  : out std_logic;
    ipv4_fields_valid : out std_logic;
    udp_fields_valid  : out std_logic
  );
end entity threeparserpipline;


architecture rtl of threeparserpipline is

  -- eth_parser -> ipv4_parser
  signal e2i_tdata  : std_logic_vector(63 downto 0);
  signal e2i_tkeep  : std_logic_vector(7 downto 0);
  signal e2i_tvalid : std_logic;
  signal e2i_tready : std_logic;
  signal e2i_tlast  : std_logic;
  signal e2i_fields : std_logic_vector(C_ETH_FIELDS_W-1 downto 0);
  signal e2i_fvalid : std_logic;

  -- ipv4_parser -> udp_parser
  signal i2u_tdata  : std_logic_vector(63 downto 0);
  signal i2u_tkeep  : std_logic_vector(7 downto 0);
  signal i2u_tvalid : std_logic;
  signal i2u_tready : std_logic;
  signal i2u_tlast  : std_logic;
  signal i2u_fields : std_logic_vector(C_IPV4_BUS_W-1 downto 0);
  signal i2u_fvalid : std_logic;

  signal u_fvalid : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Stage 1 : Ethernet
  ------------------------------------------------------------------------------
  u_eth : entity work.eth_parser
    generic map (
      G_TPID => G_TPID
    )
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => s_axis_tdata,
      s_axis_tkeep  => s_axis_tkeep,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready,
      s_axis_tlast  => s_axis_tlast,

      m_axis_tdata  => e2i_tdata,
      m_axis_tkeep  => e2i_tkeep,
      m_axis_tvalid => e2i_tvalid,
      m_axis_tready => e2i_tready,
      m_axis_tlast  => e2i_tlast,

      m_fields       => e2i_fields,
      m_fields_valid => e2i_fvalid
    );

  ------------------------------------------------------------------------------
  -- Stage 2 : IPv4
  ------------------------------------------------------------------------------
  u_ipv4 : entity work.ipv4_parser
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => e2i_tdata,
      s_axis_tkeep  => e2i_tkeep,
      s_axis_tvalid => e2i_tvalid,
      s_axis_tready => e2i_tready,
      s_axis_tlast  => e2i_tlast,

      m_axis_tdata  => i2u_tdata,
      m_axis_tkeep  => i2u_tkeep,
      m_axis_tvalid => i2u_tvalid,
      m_axis_tready => i2u_tready,
      m_axis_tlast  => i2u_tlast,

      s_fields       => e2i_fields,
      m_fields       => i2u_fields,
      m_fields_valid => i2u_fvalid
    );

  ------------------------------------------------------------------------------
  -- Stage 3 : UDP
  ------------------------------------------------------------------------------
  u_udp : entity work.udp_parser
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => i2u_tdata,
      s_axis_tkeep  => i2u_tkeep,
      s_axis_tvalid => i2u_tvalid,
      s_axis_tready => i2u_tready,
      s_axis_tlast  => i2u_tlast,

      m_axis_tdata  => m_axis_tdata,
      m_axis_tkeep  => m_axis_tkeep,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,
      m_axis_tlast  => m_axis_tlast,

      s_fields       => i2u_fields,
      m_fields       => m_fields,
      m_fields_valid => u_fvalid
    );

  ------------------------------------------------------------------------------
  -- Verification taps
  ------------------------------------------------------------------------------
  eth_fields_valid  <= e2i_fvalid;
  ipv4_fields_valid <= i2u_fvalid;
  udp_fields_valid  <= u_fvalid;

  m_fields_valid <= u_fvalid;

end architecture rtl;
