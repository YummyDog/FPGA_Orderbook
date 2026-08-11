--------------------------------------------------------------------------------
-- fullparser
--
-- Top-level wrapper chaining all five parser stages:
--
--   eth_parser -> ipv4_parser -> udp_parser -> mold_parser -> itch_parser
--
-- AXI-Stream in, AXI-Stream out, plus the per-message ITCH event stream and
-- the accumulated 523-bit field bus.
--
--   bits [129:0]     Ethernet   (130 bits)
--   bits [293:130]   IPv4       (164 bits)
--   bits [359:294]   UDP        ( 66 bits)
--   bits [522:360]   MoldUDP64  (163 bits)
--                                ----------
--                                 523 bits
--
-- Latency: 5 register stages on the data path, one per module, matched by
-- 5 stages on the field bus. That is what keeps the two aligned end to end.
-- ITCH events emerge two cycles after the beat that completed a message.
--
-- Throughput: one 8-byte beat per cycle from input to output. Only the ITCH
-- stage holds any storage (its 64-byte message assembly buffer).
--
-- The per-stage fields_valid pulses are brought out for verification. They
-- are NOT time-aligned with m_axis: eth_fields_valid fires four cycles
-- before the beat it describes reaches the output, because it originates
-- four register stages upstream.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;
use work.udp_parser_pkg.all;
use work.mold_parser_pkg.all;
use work.itch_parser_pkg.all;

entity fullparser is
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

    -- Per-message ITCH event -------------------------------------------------
    msg_valid     : out std_logic;
    msg_index     : out std_logic_vector(15 downto 0);
    msg_seqnum    : out std_logic_vector(63 downto 0);
    msg_type      : out std_logic_vector(7 downto 0);
    msg_length    : out std_logic_vector(15 downto 0);
    msg_fields    : out std_logic_vector(C_MSG_FIELDS_W-1 downto 0);
    msg_status    : out std_logic_vector(C_MSG_STATUS_W-1 downto 0);
    pkt_fields    : out std_logic_vector(C_ITCH_PKT_W-1 downto 0);

    -- Exchange clock, from the most recent Seconds message --------------------
    exchange_seconds : out std_logic_vector(31 downto 0);

    -- Packet-level status, pulsed with the outgoing tlast --------------------
    pkt_done           : out std_logic;
    pkt_msg_count      : out std_logic_vector(15 downto 0);

    -- Per-stage completion pulses, for verification --------------------------
    eth_fields_valid  : out std_logic;
    ipv4_fields_valid : out std_logic;
    udp_fields_valid  : out std_logic;
    mold_fields_valid : out std_logic
  );
end entity fullparser;


architecture rtl of fullparser is

  -- eth -> ipv4
  signal e_tdata  : std_logic_vector(63 downto 0);
  signal e_tkeep  : std_logic_vector(7 downto 0);
  signal e_tvalid : std_logic;
  signal e_tready : std_logic;
  signal e_tlast  : std_logic;
  signal e_fields : std_logic_vector(C_ETH_FIELDS_W-1 downto 0);
  signal e_fvalid : std_logic;

  -- ipv4 -> udp
  signal i_tdata  : std_logic_vector(63 downto 0);
  signal i_tkeep  : std_logic_vector(7 downto 0);
  signal i_tvalid : std_logic;
  signal i_tready : std_logic;
  signal i_tlast  : std_logic;
  signal i_fields : std_logic_vector(C_IPV4_BUS_W-1 downto 0);
  signal i_fvalid : std_logic;

  -- udp -> mold
  signal u_tdata  : std_logic_vector(63 downto 0);
  signal u_tkeep  : std_logic_vector(7 downto 0);
  signal u_tvalid : std_logic;
  signal u_tready : std_logic;
  signal u_tlast  : std_logic;
  signal u_fields : std_logic_vector(C_UDP_BUS_W-1 downto 0);
  signal u_fvalid : std_logic;

  -- mold -> itch
  signal d_tdata  : std_logic_vector(63 downto 0);
  signal d_tkeep  : std_logic_vector(7 downto 0);
  signal d_tvalid : std_logic;
  signal d_tready : std_logic;
  signal d_tlast  : std_logic;
  signal d_fields : std_logic_vector(C_MOLD_BUS_W-1 downto 0);
  signal d_fvalid : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Stage 1 : Ethernet
  ------------------------------------------------------------------------------
  u_eth : entity work.eth_parser
    generic map (G_TPID => G_TPID)
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => s_axis_tdata,
      s_axis_tkeep  => s_axis_tkeep,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready,
      s_axis_tlast  => s_axis_tlast,

      m_axis_tdata  => e_tdata,
      m_axis_tkeep  => e_tkeep,
      m_axis_tvalid => e_tvalid,
      m_axis_tready => e_tready,
      m_axis_tlast  => e_tlast,

      m_fields       => e_fields,
      m_fields_valid => e_fvalid
    );

  ------------------------------------------------------------------------------
  -- Stage 2 : IPv4
  ------------------------------------------------------------------------------
  u_ipv4 : entity work.ipv4_parser
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => e_tdata,
      s_axis_tkeep  => e_tkeep,
      s_axis_tvalid => e_tvalid,
      s_axis_tready => e_tready,
      s_axis_tlast  => e_tlast,

      m_axis_tdata  => i_tdata,
      m_axis_tkeep  => i_tkeep,
      m_axis_tvalid => i_tvalid,
      m_axis_tready => i_tready,
      m_axis_tlast  => i_tlast,

      s_fields       => e_fields,
      m_fields       => i_fields,
      m_fields_valid => i_fvalid
    );

  ------------------------------------------------------------------------------
  -- Stage 3 : UDP
  ------------------------------------------------------------------------------
  u_udp : entity work.udp_parser
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => i_tdata,
      s_axis_tkeep  => i_tkeep,
      s_axis_tvalid => i_tvalid,
      s_axis_tready => i_tready,
      s_axis_tlast  => i_tlast,

      m_axis_tdata  => u_tdata,
      m_axis_tkeep  => u_tkeep,
      m_axis_tvalid => u_tvalid,
      m_axis_tready => u_tready,
      m_axis_tlast  => u_tlast,

      s_fields       => i_fields,
      m_fields       => u_fields,
      m_fields_valid => u_fvalid
    );

  ------------------------------------------------------------------------------
  -- Stage 4 : MoldUDP64
  ------------------------------------------------------------------------------
  u_mold : entity work.mold_parser
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => u_tdata,
      s_axis_tkeep  => u_tkeep,
      s_axis_tvalid => u_tvalid,
      s_axis_tready => u_tready,
      s_axis_tlast  => u_tlast,

      m_axis_tdata  => d_tdata,
      m_axis_tkeep  => d_tkeep,
      m_axis_tvalid => d_tvalid,
      m_axis_tready => d_tready,
      m_axis_tlast  => d_tlast,

      s_fields       => u_fields,
      m_fields       => d_fields,
      m_fields_valid => d_fvalid
    );

  ------------------------------------------------------------------------------
  -- Stage 5 : ITCH
  ------------------------------------------------------------------------------
  u_itch : entity work.itch_parser
    port map (
      clk    => clk,
      resetn => resetn,

      s_axis_tdata  => d_tdata,
      s_axis_tkeep  => d_tkeep,
      s_axis_tvalid => d_tvalid,
      s_axis_tready => d_tready,
      s_axis_tlast  => d_tlast,

      m_axis_tdata  => m_axis_tdata,
      m_axis_tkeep  => m_axis_tkeep,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,
      m_axis_tlast  => m_axis_tlast,

      s_fields => d_fields,

      msg_valid  => msg_valid,
      msg_index  => msg_index,
      msg_seqnum => msg_seqnum,
      msg_type   => msg_type,
      msg_length => msg_length,
      msg_fields => msg_fields,
      msg_status => msg_status,
      pkt_fields => pkt_fields,

      exchange_seconds => exchange_seconds,

      pkt_done           => pkt_done,
      pkt_msg_count      => pkt_msg_count
    );

  ------------------------------------------------------------------------------
  -- Verification taps
  ------------------------------------------------------------------------------
  eth_fields_valid  <= e_fvalid;
  ipv4_fields_valid <= i_fvalid;
  udp_fields_valid  <= u_fvalid;
  mold_fields_valid <= d_fvalid;

end architecture rtl;
