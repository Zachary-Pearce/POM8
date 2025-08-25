library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity program_memory is
    generic (
        i: natural := 32; --instruction width
        k: natural := 16  --memory address width
    );
    Port (
        address: in std_logic_vector(k-1 downto 0);
        dout: out std_logic_vector(i-1 downto 0)
    );
end program_memory;

--ROM is designed for low latency therefore we do not have an output register
-- adding an output register would increase the read time to 2 clock cycles but reduces the clock-to-output time
architecture Behavioral of program_memory is

--ROM contents
type rom_type is array (0 to (2**k)-1) of bit_vector(i-1 downto 0);
--rom definition, put the program in here
constant rom_contents: rom_type := (
    0 => "11101001000000100000000011110000",
    1 => "00010000000000000000000000000000",
    2 => "10100000000010010000000000001111",
    3 => "00000000000001000000000100001111",
    4 => "00000001000000110000001000000101",
    5 => "10110000000000000000001100000100",
    6 => "00000010000001011000001000000000",
    7 => "00000011000000111000001100000001",
    8 => "01010000000000001010000000000000",
    9 => "01000000000000000110000000000000",
    10 => "11010010000010010000000000010000",
    11 => "01000000000000000010000000000000",
    others => "00000000000000000000000000000000"
);

function GetRomCol (rom: in rom_type; col: in natural) return bit_vector is
    variable InitVector: bit_vector(0 to 255) := (others => '0');
begin
    for ii in 0 to 255 loop
        InitVector(255-ii) := rom(ii)(col);
    end loop;
    return InitVector;
end function GetRomCol;

begin

    g256cpy_generate: for ii in 0 to ((2**k)/256)-1 generate
        ibits_generate: for jj in 0 to i-1 generate
            --setup init string
            ROM256X1_inst : ROM256X1
            generic map (
                INIT => GetRomCol(rom_contents, jj))
            port map (
                O => dout(jj),   -- ROM output
                A0 => address(0), -- ROM address[0]p
                A1 => address(1), -- ROM address[1]
                A2 => address(2), -- ROM address[2]
                A3 => address(3), -- ROM address[3]
                A4 => address(4), -- ROM address[4]
                A5 => address(5), -- ROM address[5]
                A6 => address(6),  -- ROM address[6]
                A7 => address(7)  -- ROM address[7]
            );
        end generate ibits_generate;
    end generate g256cpy_generate;

end Behavioral;
