----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.07.2025 15:00:35
-- Design Name: 
-- Module Name: POM8_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--pomegranate libraries
use WORK.pomegranate_inst_conf.ALL;

entity POM8_tb is
--  Port ( );
end POM8_tb;

architecture Behavioral of POM8_tb is

--component under test
component POM8_Top is
    Port (
        CLK, RST: in std_logic;
        --I/O pins
        pins: inout std_logic_vector(7 downto 0);
        --simulation
        op1: out opcode;
        fnct1: out funct;
        data: out std_logic_vector(word_w-1 downto 0);
        data_address: out std_logic_vector(Maddr_w-1 downto 0);
        instruction: out std_logic_vector(instruction_w-1 downto 0);
        instruction_address: out std_logic_vector(Iaddr_w-1 downto 0);
        flag: out std_logic_vector(4 downto 0)
    );
end component POM8_Top;

signal CLK, RST: std_logic := '0';
signal op: opcode;
signal fnct: funct;
signal pins: std_logic_vector(7 downto 0) := "ZZZZZZZZ";
signal inst_bus: std_logic_vector(instruction_w-1 downto 0);
signal inst_adr_bus: std_logic_vector(Iaddr_w-1 downto 0);
signal dat_bus: std_logic_vector(word_w-1 downto 0);
signal dat_adr_bus: std_logic_vector(Maddr_w-1 downto 0);
signal flg_bus: std_logic_vector(4 downto 0);

begin

--instantiate the unit under test
DUT: POM8_Top port map (
    CLK => CLK, RST => RST, pins => pins, op1 => op, fnct1 => fnct, instruction => inst_bus, instruction_address => inst_adr_bus,
    data => dat_bus, data_address => dat_adr_bus, flag => flg_bus
);

pins <= "ZZZZZZZZ";

--perform reset
RST <= '1' after 1ns, '0' after 2ns;

--setup the clock
CLK <= not CLK after 5ns;

end Behavioral;
