library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.pomegranate_memory_map_conf.ALL;

entity Stack_Pointer is
    generic (
        a: natural := 8 --memory address width
    );
    Port (
        CLK, RST: in std_logic;
        enable, Pntr_INC: in std_logic;
        address: out std_logic_vector(a-1 downto 0)
    );
end Stack_Pointer;

architecture Behavioral of Stack_Pointer is
    --CONSTANTS
    -- starting address of the stack in main memory
    constant starting_address: unsigned(a-1 downto 0) := to_unsigned(get_partition_address(stack), a);
    --stack pointer register
    signal pointer_reg: unsigned(a-1 downto 0);
    --next pointer value
    signal pointer_reg_next: unsigned(a-1 downto 0);
begin
    --SEQUENTIAL PART
    s0: process (CLK, RST) is
    begin
        if RST = '1' then
            pointer_reg_next <= starting_address;
        elsif rising_edge(CLK) then
            if (enable = '1') then
                if (Pntr_INC = '1') then
                    pointer_reg_next <= pointer_reg + 1;
                else
                    pointer_reg_next <= pointer_reg - 1;
                end if;
            end if;
        end if;
    end process s0;
    
    --COMBINATIONAL PART
    pointer_reg <= pointer_reg_next;
    
    --OUTPUT PART
    --we drive the address bus with the current pointer when pushing
    address <= std_logic_vector(pointer_reg) when enable = '1' and Pntr_INC = '1' else (others => 'Z');
    --we drive the address bus with a decremented pointer when popping
    address <= std_logic_vector(pointer_reg-1) when enable = '1' and Pntr_INC = '0' else (others => 'Z');
end Behavioral;
