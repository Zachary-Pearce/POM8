library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_reg_prim is
    generic (
        ADDRESS_WIDTH: natural := 8;
        INIT: std_logic_vector(ADDRESS_WIDTH-1 downto 0) := "00000000"
    );
    port (
        CLK, ARST: in std_logic;
        WE: in std_logic;
        address_next: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        address_out: out std_logic_vector(ADDRESS_WIDTH-1 downto 0)
    );
end entity counter_reg_prim;

architecture counter_reg_prim_rtl of counter_reg_prim is
    --signals
    signal counter_reg: std_logic_vector(ADDRESS_WIDTH-1 downto 0);
begin
    --SEQUENTIAL PART
    counter_update: process (CLK, ARST) is
    begin
        if ARST = '1' then
            counter_reg <= (others => '0');
        elsif rising_edge(CLK):
            if WE = '1' then
                counter_reg <= address_next;
            end if;
        end if;
    end process counter_update;

    --OUTPUT PART
    address_out <= counter_reg;
end architecture counter_reg_prim_rtl;