library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regFile is
    generic (
		--data bus width
		WORD_WIDTH: natural := 8;
		--register address width
		REG_ADDRESS_WIDTH: natural := 5
    );
    port (
		CLK, ARST, WE, CS: in std_logic;
		--register address inputs
		source_register, target_register, destination_register: std_logic_vector(REG_ADDRESS_WIDTH-1 downto 0);
		--data bus
		data_bus: inout std_logic_vector(WORD_WIDTH-1 downto 0);
		--Read outputs (source and target)
		source_out, target_out: out std_logic_vector(WORD_WIDTH-1 downto 0)
    );
end entity regFile;

architecture regFileRTL of regFile is
	--register array
	type regFileArray is array(0 to (2**REG_ADDRESS_WIDTH)-1) of std_logic_vector(WORD_WIDTH-1 downto 0);
	signal registers: regFileArray;
begin
	--SEQUENTIAL PART
	s0: process(CLK, ARST)
	begin
	   if ARST = '1' then
	       --using the zeros constant as this is more friendly for higher bit widths
		   registers <= (others => std_logic_vector(TO_UNSIGNED(0, WORD_WIDTH)));
       elsif rising_edge(CLK) then
           if CS = '1' then
               --write and bypass
		       if WE = '1' then
		           --write to destination register
		           registers(to_integer(unsigned(destination_register))) <= data_bus(WORD_WIDTH-1 downto 0);
		       end if;
		   end if;
	   end if;
	end process s0;
	
	--OUTPUT PART
	source_out <= registers(to_integer(unsigned(source_register)))(WORD_WIDTH-1 downto 0);
	target_out <= registers(to_integer(unsigned(target_register)))(WORD_WIDTH-1 downto 0);
	data_bus <= registers(to_integer(unsigned(source_register)))(WORD_WIDTH-1 downto 0) when CS = '1' and WE = '0' else (others => 'Z');
end architecture regFileRTL;