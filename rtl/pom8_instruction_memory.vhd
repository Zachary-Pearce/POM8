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
    0 => "010000000000000000000001",
    1 => "010000111000000000000001",
    2 => "010000111100000000000000",
    3 => "010011000000001000000010",
    4 => "000100000000000000011001",
    5 => "010100000000000000000000",
    6 => "001100000000000000000000",
    7 => "000101000000000000001111",
    8 => "010000000100000011111111",
    9 => "001100000100010000000001",
    10 => "000101000000000000001100",
    11 => "000100000000000000001001",
    12 => "001100000000000000000001",
    13 => "000101000000000000001111",
    14 => "000100000000000000001000",
    15 => "010101000000000000000000",
    16 => "000011000000000000000000",
    17 => "010011000011101000000001",
    18 => "000010000000000000000101",
    19 => "010100000000000000000000",
    20 => "000000000000110000000001",
    21 => "010011000011111000000001",
    22 => "000010000000000000000101",
    23 => "010101000000000000000000",
    24 => "000011000000000000000000",
    25 => "010000000000000000000000",
    26 => "010000001100000001111111",
    27 => "000010000000000000010001",
    28 => "001011000000000000000001",
    29 => "000000001000110000000001",
    30 => "000101000000000000100000",
    31 => "000100000000000000011011",
    32 => "001100000000000000000001",
    33 => "000101000000000000011001",
    34 => "000010000000000000010001",
    35 => "000100000000000000100000",
    others => "000000000000000000000000"
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
