library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_ITF is
    generic (
        n: natural := 8; --data width
        k: natural := 8  --memory address width
    );
    Port (
        --control signals
        CLK: in std_logic;
        WE, CS: in std_logic;
        --bus connections
        din: in std_logic_vector(n-1 downto 0);
        dout: out std_logic_vector(n-1 downto 0);
        address: in std_logic_vector(k-1 downto 0)
    );
end entity Memory_ITF;

--this module is designed specifically for BRAM implementation
-- this inherently results in a 2 clock cycle read time
architecture Memory_ITF_RTL of Memory_ITF is
    --ram data type
    type ram_type is array (0 to (2**k)-1) of std_logic_vector(n-1 downto 0);
    --ram declaration
    signal ram: ram_type;
begin
    --SEQUENTIAL PART
    s0: process(CLK) is
    begin
        if rising_edge(CLK) then
            if CS = '1' then
                if WE = '1' then
                    ram(to_integer(unsigned(address))) <= din;
                else
                    dout <= ram(to_integer(unsigned(address)));
                end if;
            end if;
        end if;
    end process s0;
end Memory_ITF_RTL;
