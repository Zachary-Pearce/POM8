library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--pomegranate libraries
use WORK.pomegranate_inst_conf.ALL;

entity CU is
    Port (
        op: in opcode;
        fnct: in funct;
        flag_bus: inout std_logic_vector(4 downto 0);
        --control signals
        --ALU
        ALU_EN, ALU_IMM, ALU_ADR: out std_logic;
        ALU_OP: out std_logic_vector(3 downto 0);
        --Data memory
        MEM_WRITE, MEM_READ: out std_logic;
        --program counter
        PC_INC, DAT_PC, PC_LDA: out std_logic;
        --stack pointer
        stack_enable, Pntr_INC: out std_logic;
        --status register
        SR_WE, SR_DAT, SR_FLG, SR_CnS: out std_logic;
        --register file
        RF_WE, RF_CS: out std_logic;
        SRC_IMM: out std_logic;
        DAT_ADR: out std_logic_vector(1 downto 0)
    );
end entity CU;

architecture Behavioral of CU is
begin

--COMBINATIONAL PART - decoder
c0: process (op, fnct, flag_bus) is
begin
    --reset all control signals
    ALU_EN <= '0';
    ALU_IMM <= '0';
    ALU_OP <= "0000";
    MEM_WRITE <= '0';
    MEM_READ <= '0';
    PC_INC <= '0';
    DAT_PC <= '0';
    PC_LDA <= '0';
    stack_enable <= '0';
    Pntr_INC <= '0';
    SR_WE <= '0';
    SR_DAT <= '0';
    SR_FLG <= '0';
    SR_CnS <= '0';
    RF_WE <= '0';
    RF_CS <= '0';
    SRC_IMM <= '0';
    ALU_ADR <= '0';
    DAT_ADR <= "00";
    flag_bus <= "ZZZZZ";
    
    --REGISTER FORMAT?
    if RFormatCheck(op) = '1' then
        PC_INC <= '1';
        case (fnct) is
            when ADD | ADDI =>
                ALU_EN <= '1';
                ALU_OP <= "0000";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
                if fnct = ADDI then
                    --immediate source
                    ALU_IMM <= '1';
                end if;
            when SUB | SUBI =>
                ALU_EN <= '1';
                ALU_OP <= "0001";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
                if fnct = SUBI then
                    --immediate source
                    ALU_IMM <= '1';
                end if;
            when ANDG | ANDI =>
                ALU_EN <= '1';
                ALU_OP <= "0010";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
                if fnct = ANDI then
                    --immediate source
                    ALU_IMM <= '1';
                end if;
            when ORG | ORI =>
                ALU_EN <= '1';
                ALU_OP <= "0011";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
                if fnct = ORI then
                    --immediate source
                    ALU_IMM <= '1';
                end if;
            when NOTG =>
                ALU_EN <= '1';
                ALU_OP <= "0100";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
            when XORG | XORI =>
                ALU_EN <= '1';
                ALU_OP <= "0101";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
                if fnct = XORI then
                    --immediate source
                    ALU_IMM <= '1';
                end if;
            when LSL =>
                ALU_EN <= '1';
                ALU_OP <= "0110";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
            when LSR =>
                ALU_EN <= '1';
                ALU_OP <= "0111";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
            when ADDC =>
                ALU_EN <= '1';
                ALU_OP <= "1000";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
            when SUBC =>
                ALU_EN <= '1';
                ALU_OP <= "1001";
                RF_CS <= '1';
                RF_WE <= '1';
                --update the flags
                SR_WE <= '1';
                SR_FLG <= '1';
            when PUSH =>
                RF_CS <= '1';
                stack_enable <= '1';
                DAT_ADR <= "11";
                Pntr_INC <= '1';
                MEM_WRITE <= '1';
            when POP =>
                RF_CS <= '1';
                RF_WE <= '1';
                stack_enable <= '1';
                DAT_ADR <= "11";
                MEM_READ <= '1';
            when SETC =>
                SR_WE <= '1';
                SR_CnS <= '0';
                flag_bus <= "00010";
            when CLRC =>
                SR_WE <= '1';
                SR_CnS <= '1';
                flag_bus <= "11101";
            when SETV =>
                SR_WE <= '1';
                SR_CnS <= '0';
                flag_bus <= "00001";
            when others => --CLRV
                SR_WE <= '1';
                SR_CnS <= '1';
                flag_bus <= "11110";
        end case;
    --BRANCH FORMAT?
    elsif BFormatCheck(op) = '1' then
        case (op) is
            when CALL =>
                stack_enable <= '1';
                DAT_ADR <= "11";
                Pntr_INC <= '1';
                DAT_PC <= '1';
                MEM_WRITE <= '1';
            when RET =>
                stack_enable <= '1';
                DAT_ADR <= "11";
                MEM_READ <= '1';
                PC_LDA <= '1';
            when JMP =>
                PC_LDA <= '0';
                PC_INC <= '0';
            --for branches we increment the PC if the relevant flag is cleared
            when BRZ =>
                if flag_bus(4) = '0' then
                    PC_INC <= '1';
                end if;
            when BRN =>
                if flag_bus(3) = '0' then
                    PC_INC <= '1';
                end if;
            when BRP =>
                if flag_bus(2) = '0' then
                    PC_INC <= '1';
                end if;
            when BRC =>
                if flag_bus(1) = '0' then
                    PC_INC <= '1';
                end if;
            when BRV =>
                if flag_bus(0) = '0' then
                    PC_INC <= '1';
                end if;
            when others => --NOP
                PC_INC <= '1';
        end case;
    --ADDRESSING FORMAT?
    else
        PC_INC <= '1';
        case (op) is
            when LDR =>
                MEM_READ <= '1';
                RF_CS <= '1';
                RF_WE <= '1';
            when LDW =>
                SRC_IMM <= '1';
                RF_CS <= '1';
                RF_WE <= '1';
            when LDI =>
                ALU_EN <= '1';
                ALU_OP <= "0000";
                ALU_ADR <= '1';
                DAT_ADR <= "10";
                ALU_IMM <= '1';
                MEM_READ <= '1';
                RF_CS <= '1';
                RF_WE <= '1';
            when STR =>
                RF_CS <= '1';
                MEM_WRITE <= '1';
            when STW =>
                SRC_IMM <= '1';
                DAT_ADR <= "01";
                MEM_WRITE <= '1';
            when others => --STI
                ALU_EN <= '1';
                ALU_OP <= "0000";
                ALU_ADR <= '1';
                DAT_ADR <= "10";
                ALU_IMM <= '1';
                RF_CS <= '1';
                MEM_READ <= '1';
        end case;
    end if;
end process c0;

end Behavioral;
