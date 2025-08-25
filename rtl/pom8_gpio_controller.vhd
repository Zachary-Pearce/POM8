library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity GPIO_Controller is
    generic (
        --this design is made for a number of pins greater than or equal to the word width
        PIN_NUM: natural := 16;
        WORD_WIDTH: natural := 8;
        REGISTER_ADDRESS_WIDTH: natural := 3
    );
    port (
        CLK: in std_logic;
        ARST: in std_logic;
        CS: in std_logic;
        RnW: in std_logic;
        RS: in std_logic_vector(REGISTER_ADDRESS_WIDTH-1 downto 0);
        
        -- the size of each register in bits is given by the number of pins divided by the number of registers
        din: in std_logic_vector(WORD_WIDTH-1 downto 0);
        dout: out std_logic_vector(WORD_WIDTH-1 downto 0);
        pins: inout std_logic_vector(PIN_NUM-1 downto 0)
    );
end entity GPIO_Controller;

architecture Behavioral of GPIO_Controller is

-- define the internal registers
type register_array is array (0 to (2**REGISTER_ADDRESS_WIDTH)-1) of std_logic_vector(WORD_WIDTH-1 downto 0);
signal IO_registers: register_array;

-- we need to keep track of where the DDR registers are in the file
-- we will assume that the DDRs for the ports are one after the other
constant DDR_REG_LOCATION: integer := 2;

begin

--SEQUENTIAL PART
s0: process (CLK, ARST) is
begin
    if ARST = '1' then
        IO_registers <= (others => std_logic_vector(TO_UNSIGNED(0, WORD_WIDTH)));
    elsif rising_edge(CLK) then
        if (CS = '1') then
            if (RnW = '0') then
                -- we shouldn't write to input buffers
                -- there is one input buffer per port...
                -- assuming the input buffers are the first registers then the register address would be less than (PIN_NUM/WORD_WIDTH)-1
                if (TO_INTEGER(unsigned(RS)) > (PIN_NUM/WORD_WIDTH)-1) then
                    IO_registers(TO_INTEGER(unsigned(RS))) <= din;
                end if;
            end if;
        else
            -- read input pins
            -- number of input registers is equal to PIN_NUM/WORD_WIDTH
            -- this works assuming the input buffers are the first registers in the file
            for ii in 0 to (PIN_NUM/WORD_WIDTH)-1 loop
                for jj in 0 to WORD_WIDTH-1 loop
                    if IO_registers(ii+DDR_REG_LOCATION)(jj) = '0' then
                        IO_registers(ii)(jj) <= pins(jj+(ii*WORD_WIDTH));
                    else
                        IO_registers(ii)(jj) <= '0';
                    end if;
                end loop;
            end loop;
        end if;
    end if;
end process s0;

--OUTPUT PART
-- output to the databus when reading (performing a load)
dout <= IO_registers(TO_INTEGER(unsigned(RS))) when CS = '1' and RnW = '1' else (others => 'Z');

-- output buffer contents through the pins
gen_output_port: for ii in 0 to (PIN_NUM/WORD_WIDTH)-1 generate
    gen_output_pin: for jj in 0 to WORD_WIDTH-1 generate
        pins(jj+(ii*WORD_WIDTH)) <= IO_registers(ii+PIN_NUM/WORD_WIDTH)(jj) when IO_registers(ii+DDR_REG_LOCATION)(jj) = '1' else 'Z';
    end generate gen_output_pin;
end generate gen_output_port;

end Behavioral;
