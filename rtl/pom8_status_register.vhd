library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Status_Register is
    Generic (
        WORD_WIDTH: natural := 8;
        FLAG_NUM: natural := 6
    );
    Port (
        CLK: in std_logic;
        ARST: in std_logic;
        WE, DAT, FLG, CnS: in std_logic;
        C_out: out std_logic;
        flag_bus: inout std_logic_vector(FLAG_NUM-1 downto 0);
        data_bus: inout std_logic_vector(WORD_WIDTH-1 downto 0)
    );
end entity Status_Register;

architecture Behavioral of Status_Register is

--signals
--flag order: Z | N | P | C | V
signal flag_reg: std_logic_vector(FLAG_NUM-1 downto 0);

begin
--SEQUENTIAL PART
s0: process (CLK, ARST) is
begin
    if ARST = '1' then
        --reset the flag registers
        flag_reg <= (others => '0');
    elsif rising_edge(CLK) then
        if WE = '1' then
            if FLG = '1' then
                flag_reg <= flag_bus;
            elsif DAT = '1' then
                flag_reg <= data_bus(WORD_WIDTH-1 downto WORD_WIDTH-FLAG_NUM);
            else
                if CnS = '1' then
                    --we AND here so we can clear one flag at a time using a mask
                    flag_reg <= flag_bus and flag_reg;
                else
                    --we OR here so we can set one flag at a time using a mask
                    flag_reg <= flag_bus or flag_reg;
                end if;
            end if;
        end if;
    end if;
end process s0;

--OUTPUT PART
--send carry status to ALU
C_out <= flag_reg(1);

--sending the control signals to the control unit
flag_bus <= flag_reg when WE = '0' else (others => 'Z');

--the status register will occupy the MSB of the data bus
data_bus(WORD_WIDTH-1 downto WORD_WIDTH-FLAG_NUM) <= flag_reg when DAT = '1' and WE = '0' else (others => 'Z');
--fill the remainder of the databus with 0's
data_bus(WORD_WIDTH-FLAG_NUM-1 downto 0) <= (others => '0') when DAT = '1' and WE = '0' else (others => 'Z');

end Behavioral;
