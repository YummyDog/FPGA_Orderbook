library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity timestamp_counter is
    generic (
        WIDTH : positive := 18
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;  -- active low, synchronous
        count_o : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity timestamp_counter;
 
architecture rtl of timestamp_counter is
    signal count : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
 
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                count <= (others => '0');
            else
                count <= count + 1;  -- wraps naturally
            end if;
        end if;
    end process;
 
    count_o <= std_logic_vector(count);
 
end architecture rtl;
 