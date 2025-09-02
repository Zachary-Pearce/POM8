library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    generic (
		REGISTER_WIDTH: natural := 8;
		REG_ADDRESS_WIDTH: natural := 5
    );
    port (
		CLK, ARST, WE, CS: in std_logic;
		din: in std_logic_vector(REGISTER_WIDTH-1 downto 0);
		--register address inputs
		source_register, target_register, destination_register: in std_logic_vector(REG_ADDRESS_WIDTH-1 downto 0);
		--Read outputs (source and target)
		source_out, target_out: out std_logic_vector(REGISTER_WIDTH-1 downto 0)
    );
end entity reg_file;

architecture reg_file_rtl of reg_file is
	--register array
	type reg_file_t is array(0 to (2**REG_ADDRESS_WIDTH)-1) of std_logic_vector(REGISTER_WIDTH-1 downto 0);
	signal registers: reg_file_t;
begin
	--SEQUENTIAL PART
	s0: process(CLK, ARST)
	begin
	   if ARST = '1' then
	       --using the zeros constant as this is more friendly for higher bit widths
		   registers <= (others => std_logic_vector(TO_UNSIGNED(0, REGISTER_WIDTH)));
       elsif rising_edge(CLK) then
           if CS = '1' then
               --write and bypass
		       if WE = '1' then
		           --write to destination register
		           registers(to_integer(unsigned(destination_register))) <= din(REGISTER_WIDTH-1 downto 0);
		       end if;
		   end if;
	   end if;
	end process s0;
	
	--OUTPUT PART
	source_out <= registers(to_integer(unsigned(source_register)))(REGISTER_WIDTH - 1 downto 0);
	target_out <= registers(to_integer(unsigned(target_register)))(REGISTER_WIDTH - 1 downto 0);
end architecture reg_file_rtl;