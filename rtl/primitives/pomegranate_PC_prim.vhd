library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PC_prim is
    generic (
        ADDRESS_WIDTH: natural := 8
    );
    port (
        CLK, ARST: in std_logic;
        WE: in std_logic;
        address_next: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        address_out: out std_logic_vector(ADDRESS_WIDTH-1 downto 0)
    );
end entity;

architecture PC_prim_rtl of PC_prim is
    --signals
    signal counter_reg: std_logic_vector(ADDRESS_WIDTH-1 downto 0);
begin
    --SEQUENTIAL PART
    PC_update: process (CLK, ARST) is
    begin
        if ARST = '1' then
            counter_reg <= (others => '0');
        elsif rising_edge(CLK):
            if WE = '1' then
                counter_reg <= address_next;
            end if;
        end if;
    end process PC_update;

    --OUTPUT PART
    address_out <= counter_reg;
end architecture PC_prim_rtl;