library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reg_prim is
    generic (
        REGISTER_WIDTH: natural := 8
    );
    port (
        CLK, ARST: in std_logic;
        WE: in std_logic;
        din: in std_logic_vector(REGISTER_WIDTH-1 downto 0);
        dout: out std_logic_vector(REGISTER_WIDTH-1 downto 0)
    );
end entity;

architecture reg_prim_rtl of reg_prim is
    signal reg: std_logic_vector(REGISTER_WIDTH-1 downto 0);
begin
    --SEQUENTIAL PART
    register_write: process (CLK, ARST) is
    begin
        if ARST = '1' then
            reg <= (others => '0');
        elsif rising_edge(CLK) then
            if WE = '1' then
                reg <= din;
            end if;
        end if;
    end process register_write;

    --OUTPUT PART
    dout <= reg;
end architecture;