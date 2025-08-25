library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PC is
    generic (
        a: natural := 8
    );
    Port (
        CLK, RST: in std_logic;
        PC_INC, DAT_PC, PC_LDA: in std_logic;
        data_bus: inout std_logic_vector(a-1 downto 0);
        instruction_bus: in std_logic_vector(a-1 downto 0);
        address_out: out std_logic_vector(a-1 downto 0)
    );
end PC;

architecture Behavioral of PC is
    --signals
    signal counter_reg, counter_next: unsigned(a-1 downto 0);
begin
    --SEQUENTIAL PART
    s0: process (CLK, RST) is
    begin
        if RST = '1' then
            counter_next <= to_unsigned(0, 8);
        elsif rising_edge(CLK) then
            --increment counter register
            if PC_INC = '1' then
                counter_next <= counter_reg + 1;
            --otherwise load a value into the program counter...
            elsif PC_LDA = '1'  then
                --from the data bus
                counter_next <= unsigned(data_bus);
            else
                --from the instruction bus
                counter_next <= unsigned(instruction_bus);
            end if;
        end if;
    end process s0;
    
    --COMBINATIONAL PART
    counter_reg <= counter_next;
    
    --OUTPUT PART
    address_out <= std_logic_vector(counter_reg);
    --output incremented counter reg so subroutine returns don't return to the line where we called the subroutine
    data_bus <= std_logic_vector(counter_reg+1) when DAT_PC = '1' else (others => 'Z');
end Behavioral;
