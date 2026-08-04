--------------------------------------------------------------------------------
-- eth_parser_pkg
--
-- Field-bus layout for the Ethernet stage of the market-data header parser
-- pipeline.
--
-- The field bus is a flat std_logic_vector. Each parser stage appends its own
-- fields ABOVE the fields it received from upstream, so the Ethernet slice
-- always occupies bits [C_ETH_FIELDS_W-1 : 0] of every bus in the chain.
--
-- Byte order: all multi-byte fields are stored in wire order, first byte on
-- the wire in the most significant position. dst_mac(47 downto 40) is the
-- first byte of the frame.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package eth_parser_pkg is

  ------------------------------------------------------------------------------
  -- Field widths
  ------------------------------------------------------------------------------
  constant C_DST_MAC_W      : natural := 48;
  constant C_SRC_MAC_W      : natural := 48;
  constant C_ETHERTYPE_W    : natural := 16;  -- post-VLAN, the real type
  constant C_VLAN_TCI_W     : natural := 16;  -- PCP(3) DEI(1) VID(12)
  constant C_VLAN_PRESENT_W : natural := 1;
  constant C_ETH_TRUNC_W    : natural := 1;   -- informational status

  ------------------------------------------------------------------------------
  -- Bit offsets within the Ethernet slice of the field bus
  ------------------------------------------------------------------------------
  constant C_DST_MAC_LO      : natural := 0;
  constant C_SRC_MAC_LO      : natural := C_DST_MAC_LO      + C_DST_MAC_W;       --  48
  constant C_ETHERTYPE_LO    : natural := C_SRC_MAC_LO      + C_SRC_MAC_W;       --  96
  constant C_VLAN_TCI_LO     : natural := C_ETHERTYPE_LO    + C_ETHERTYPE_W;     -- 112
  constant C_VLAN_PRESENT_LO : natural := C_VLAN_TCI_LO     + C_VLAN_TCI_W;      -- 128
  constant C_ETH_TRUNC_LO    : natural := C_VLAN_PRESENT_LO + C_VLAN_PRESENT_W;  -- 129

  constant C_ETH_FIELDS_W    : natural := C_ETH_TRUNC_LO + C_ETH_TRUNC_W;        -- 130

  ------------------------------------------------------------------------------
  -- Accessors. Use these from the testbench and from downstream stages rather
  -- than hard-coded slices, so the layout can move without breaking callers.
  ------------------------------------------------------------------------------
  function eth_dst_mac       (f : std_logic_vector) return std_logic_vector;
  function eth_src_mac       (f : std_logic_vector) return std_logic_vector;
  function eth_ethertype     (f : std_logic_vector) return std_logic_vector;
  function eth_vlan_tci      (f : std_logic_vector) return std_logic_vector;
  function eth_vlan_present  (f : std_logic_vector) return std_logic;
  function eth_hdr_truncated (f : std_logic_vector) return std_logic;

  -- Convenience decode of the TCI
  function eth_vlan_pcp (f : std_logic_vector) return std_logic_vector;  -- 3 bits
  function eth_vlan_dei (f : std_logic_vector) return std_logic;
  function eth_vlan_vid (f : std_logic_vector) return std_logic_vector;  -- 12 bits

end package eth_parser_pkg;


package body eth_parser_pkg is

  function eth_dst_mac (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_DST_MAC_LO + C_DST_MAC_W - 1 downto C_DST_MAC_LO);
  end function;

  function eth_src_mac (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_SRC_MAC_LO + C_SRC_MAC_W - 1 downto C_SRC_MAC_LO);
  end function;

  function eth_ethertype (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_ETHERTYPE_LO + C_ETHERTYPE_W - 1 downto C_ETHERTYPE_LO);
  end function;

  function eth_vlan_tci (f : std_logic_vector) return std_logic_vector is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_VLAN_TCI_LO + C_VLAN_TCI_W - 1 downto C_VLAN_TCI_LO);
  end function;

  function eth_vlan_present (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_VLAN_PRESENT_LO);
  end function;

  function eth_hdr_truncated (f : std_logic_vector) return std_logic is
    alias ff : std_logic_vector(f'length-1 downto 0) is f;
  begin
    return ff(C_ETH_TRUNC_LO);
  end function;

  function eth_vlan_pcp (f : std_logic_vector) return std_logic_vector is
    variable tci : std_logic_vector(15 downto 0);
  begin
    tci := eth_vlan_tci(f);
    return tci(15 downto 13);
  end function;

  function eth_vlan_dei (f : std_logic_vector) return std_logic is
    variable tci : std_logic_vector(15 downto 0);
  begin
    tci := eth_vlan_tci(f);
    return tci(12);
  end function;

  function eth_vlan_vid (f : std_logic_vector) return std_logic_vector is
    variable tci : std_logic_vector(15 downto 0);
  begin
    tci := eth_vlan_tci(f);
    return tci(11 downto 0);
  end function;

end package body eth_parser_pkg;
