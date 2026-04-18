library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_sync is
  port (
    CLK, ARST: in std_logic;
    RST_O: out std_logic
  ) ;
end entity reset_sync;

architecture reset_sync_rtl of reset_sync is

    signal arst_ff: std_logic;

begin

    --SEQUENTIAL PART
    s0: process(CLK)
    begin
        if rising_edge(CLK) then
            arst_ff <= ARST;
        end if;
    end process s0;

    --COMBINATIONAL PART
    RST_O <= ARST or arst_ff;

end architecture reset_sync_rtl;