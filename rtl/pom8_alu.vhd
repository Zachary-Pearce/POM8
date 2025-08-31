library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    generic (
        WORD_WIDTH: natural := 8; --data width
        FLAG_NUM: natural := 6    --num of status flags
    );
    Port (
        EN: in std_logic;
        OP: in std_logic_vector(3 downto 0);
        Rs, Rt: in std_logic_vector(WORD_WIDTH-1 downto 0);
        result_out: out std_logic_vector(WORD_WIDTH-1 downto 0);
        C_flag_in: in std_logic;
        flag_bus: out std_logic_vector(FLAG_NUM-1 downto 0)
    );
end entity ALU;

architecture ALU_RTL of ALU is
--signals
signal result: std_logic_vector(WORD_WIDTH downto 0);
--flags
signal C_flag_out, Z_flag_out, N_flag_out, P_flag_out, V_flag_out: std_logic;
begin
    --select ALU operation
    with OP select
        result <=   std_logic_vector(unsigned('0' & Rs) + unsigned('0' & Rt)) when "0000",
                    std_logic_vector(unsigned('0' & Rs) - unsigned('0' & Rt)) when "0001",
                    '0' & Rs and '0' & Rt when "0010",
                    '0' & Rs or '0' & Rt when "0011",
                    '0' & Rs xor '0' & Rt when "0100",
                    '0' & (not Rs) when "0101",
                    std_logic_vector(shift_left(unsigned('0' & Rs), 1)) when "0110",
                    std_logic_vector(shift_right(unsigned('0' & Rs), 1)) when "0111",
                    std_logic_vector(unsigned('0' & Rs) + unsigned('0' & Rt) + ("" & C_flag_in)) when "1000",
                    std_logic_vector(unsigned('0' & Rs) - unsigned('0' & Rt) - ("" & C_flag_in)) when "1001",
                    "000000000" when others;
    
    --OUTPUT PART
    result_out <= result(WORD_WIDTH-1 downto 0) when ALU_EN = '1' else (others => 'Z');
    
    Z_flag_out <= '1' when unsigned(result(WORD_WIDTH-1 downto 0)) = 0 else '0';
    N_flag_out <= result(WORD_WIDTH-1); --2's complement, if the MSB is set then the result is negative
    P_flag_out <= not result(WORD_WIDTH-1); --2's complement, if the MSB is cleared then the result is positive
    C_flag_out <= result(WORD_WIDTH); --the last bit of the result signal is the carry
    V_flag_out <= (not Rs(7) and not Rt(7) and result(7)) or (Rs(7) and Rt(7) and not result(7))
    flag_bus <= Z_flag_out & N_flag_out & P_flag_out & C_flag_out & '0' when ALU_EN = '1' else (others => 'Z');
end ALU_RTL;
