library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--pomegranate libraries
use WORK.pomegranate_inst_conf.ALL;

entity CU is
    Port (
        CLK, ARST: in std_logic;
        op: in opcodes;
        fnct: in funct;
        flag_bus: inout std_logic_vector(4 downto 0);
        --control signals
        --ALU
        ALU_EN, ALU_STAT: out std_logic;
        ALU_OP: out std_logic_vector(3 downto 0);
        --data memory
        MEM_WRITE, MEM_READ: out std_logic;
        --program counter
        PCL_UPDATE: out std_logic;
        PCH_UPDATE: out std_logic;
        --instruction register
        IR_WRITE: out std_logic;
        --stack pointer
        SP_EN, SP_UPDATE: out std_logic;
        --status register
        SR_WE, SR_FLG, SR_CnS: out std_logic;
        --register file
        RF_WE, RF_CS: out std_logic;
        --bus management
        ADR_SEL: out std_logic_vector(1 downto 0);
        OUT_SEL: out std_logic_vector(1 downto 0);
        DAT_SEL: out std_logic_vector(2 downto 0);
        --ALU input selection
        SRC_SEL: out std_logic_vector(1 downto 0);
        TAR_SEL: out std_logic_vector(1 downto 0);
        --PC input selection
        PCL_SEL: out std_logic_vector(1 downto 0);
        PCH_SEL: out std_logic_vector(1 downto 0)
    );
end entity CU;

architecture Behavioral of CU is

    type state_t is (HALT, BOOT, PCL_INC, PCL_LOAD8, PCH_INC, PCH_SAVE, PCH_LOAD8, PC_LOAD16, DECODE, REGISTER_EXE, BRANCH_EXE, IMMEDIATE_EXE, MEM_WRITEBACK);
    signal state, state_next: state_t;

begin

    --SEQUENTIAL PART
    fsm_sync: process(CLK, ARST) is
    begin
        if ARST = '1' then
            state <= BOOT;
        elsif rising_edge(CLK) then
            state <= state_next;
        end if;
    end process fsm_sync;

    --COMBINATIONAL PART
    --finite state machine, output and next state logic
    main_fsm: process(state, op, fnct, flag_bus) is
    begin
        --reset all control signals
        ALU_EN <= '0';
        ALU_STAT <= '0';
        MEM_WRITE <= '0';
        MEM_READ <= '0';
        PCL_UPDATE <= '0';
        PCH_UPDATE <= '0';
        IR_WRITE <= '0';
        SP_EN <= '0';
        SP_UPDATE <= '0';
        SR_WE <= '0';
        SR_FLG <= '0';
        SR_CnS <= '0';
        RF_WE <= '0';
        RF_CS <= '0';
        PCL_SEL <= "00";  -- data_bus, Rt, Imm16(8), data_bus
        PCH_SEL <= "00";  -- data_bus, Rs, Imm16(15), data_bus
        ADR_SEL <= "00";  -- Z, ALU_out, SP_out, Imm10
        OUT_SEL <= "00";  -- Z, ALU_out_reg, ALU_out, DM_out
        DAT_SEL <= "000"; -- Z, Rs, Rt, Imm8, PCL_out, PCH_out, Z, Z
        SRC_SEL <= "00";  -- PCL_out, PCH_out, PC_old, Rs
        TAR_SEL <= "00";  -- Rt, Imm8, 1, Rt
        state_next <= PCL_INC;
        --free up flag bus
        flag_bus <= "ZZZZZ";

        case state is
            when HALT =>
                --only way to exit a halt is through interrupt
                state_next <= HALT;
            when BOOT =>
                --only here until synchronous asynchronous reset is implemented
                --prevents timing issues when reset is asserted immediately before a clock
                --does not prevent all instances of incorrect logic, but prevents most
                state_next <= PCL_INC;
            --=======================================================--
            -- PCL_INC
            -- Increment the low byte of the program counter,
            -- if a carry is generated then goto PCH_INC state,
            -- otherwise write to IR and goto decode state
            when PCL_INC =>
                --increment low byte
                PCL_UPDATE <= '1';
                SRC_SEL <= "00";
                TAR_SEL <= "10";
                ALU_EN <= '1';
                OUT_SEL <= "10";

                --check for carry
                if flag_bus(1) = '1' then
                    --goto PCH_INC state
                    state_next <= PCH_INC;
                else
                    --write to IR and decode
                    IR_WRITE <= '1';
                    state_next <= DECODE;
                end if;
            --=======================================================--
            -- PCL_LOAD8
            -- Load a byte into PCL that was popped from the stack,
            -- also pop PC high byte from the stack
            when PCL_LOAD8 =>
                --update PCL with low byte over the data bus
                OUT_SEL <= "11";
                PCL_SEL <= "00";
                PCL_UPDATE <= '1';

                --pop program counter high byte from the stack
                SP_EN <= '1';
                ADR_SEL <= "10";
                MEM_READ <= '1';

                --goto PCH_LOAD8 to load high byte in PCH
                state_next <= PCH_LOAD8;
            --=======================================================--
            -- PCH_INC
            -- Increment the high byte of the program counter,
            -- then write to IR and goto decode state
            when PCH_INC =>
                --increment high byte
                PCH_UPDATE <= '1';
                SRC_SEL <= "01";
                TAR_SEL <= "10";
                ALU_EN <= '1';
                OUT_SEL <= "10";

                --write to IR and decode
                IR_WRITE <= '1';
                state_next <= DECODE;
            --=======================================================--
            -- PCH_SAVE
            -- Push the high byte of the program counter onto the stack
            when PCH_SAVE =>
                --save PC high byte
                SP_EN <= '1';
                SP_UPDATE <= '1';
                ADR_SEL <= "10";
                DAT_SEL <= "101";
                MEM_WRITE <= '1';
                --goto PC_LOAD16 to switch to target address
                state_next <= PC_LOAD16;
            --=======================================================--
            -- PCH_LOAD8
            -- Load a byte into PCH that was popped from the stack
            when PCH_LOAD8 =>
                --update PCH with high byte over the data bus
                OUT_SEL <= "11";
                PCH_SEL <= "00";
                PCH_UPDATE <= '1';
                --fetch the next instruction
                state_next <= PCL_INC;
            --=======================================================--
            -- PC_LOAD16
            -- Load a 16-bit immediate into the program counter,
            -- from the instruction bus
            when PC_LOAD16 =>
                --update PCL with low byte from instruction bus
                PCL_SEL <= "10";
                PCL_UPDATE <= '1';
                --update PCH with high byte from instruction bus
                PCH_SEL <= "10";
                PCH_UPDATE <= '1';
                --fetch the next instruction
                state_next <= PCL_INC;
            --=======================================================--
            -- DECODE
            -- Determine format of instruction,
            -- then goto relevant execute state
            when DECODE =>
                if RFormatCheck(op) = '1' then
                    state_next <= REGISTER_EXE;
                elsif BFormatCheck(op) = '1' then
                    state_next <= BRANCH_EXE;
                else
                    state_next <= IMMEDIATE_EXE;
                end if;
            --=======================================================--
            -- REGISTER_EXE
            -- Execute state for register format instructions
            when REGISTER_EXE =>
                case fnct is
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
                    when CLRV =>
                        SR_WE <= '1';
                        SR_CnS <= '1';
                        flag_bus <= "11110";
                    when IJMP =>
                        RF_CS <= '1';
                        --update PCL with Rs
                        PCL_SEL <= "01";
                        PCL_UPDATE <= '1';
                        --update PCH with Rt
                        PCH_SEL <= "01";
                        PCH_UPDATE <= '1';
                    when MOV =>
                        RF_CS <= '1';
                        RF_WE <= '1';
                        DAT_SEL <= "001";
                    when INC =>
                        -- ALU_OP is determined by the ALU decoder
                        SRC_SEL <= "11";
                        TAR_SEL <= "10";
                        ALU_EN <= '1';
                        
                        --update flags
                        ALU_STAT <= '1';
                        SR_WE <= '1';
                        SR_FLG <= '1';
                        
                        --write back
                        OUT_SEL <= "10";
                        RF_CS <= '1';
                        RF_WE <= '1';
                    when others => --ALU operations
                        -- ALU_OP is determined by the ALU decoder
                        SRC_SEL <= "11";
                        TAR_SEL <= "00";
                        ALU_EN <= '1';

                        --update flags
                        ALU_STAT <= '1';
                        SR_WE <= '1';
                        SR_FLG <= '1';

                        --write back
                        OUT_SEL <= "10";
                        RF_CS <= '1';
                        RF_WE <= '1';
                end case;
                --fetch the next instruction
                state_next <= PCL_INC;
            --=======================================================--
            -- BRANCH_EXE
            -- Execute state for branch format instructions.
            when BRANCH_EXE =>
                case op is
                    when CALL => --takes three clock cycles
                        --save PC low byte 
                        SP_EN <= '1';
                        SP_UPDATE <= '1';
                        ADR_SEL <= "10";
                        DAT_SEL <= "100";
                        MEM_WRITE <= '1';
                        --then goto PCH_SAVE
                        state_next <= PCH_SAVE;
                    when RET => --takes three clock cycles
                        --pop PC low byte
                        SP_EN <= '1';
                        ADR_SEL <= "10";
                        MEM_READ <= '1';
                        --goto PCL_LOAD8 to load low byte into PCL
                        state_next <= PCL_LOAD8;
                    when JMP =>
                        --update PCL with low byte from instruction bus
                        PCL_SEL <= "10";
                        PCL_UPDATE <= '1';
                        --update PCH with high byte from instruction bus
                        PCH_SEL <= "10";
                        PCH_UPDATE <= '1';
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when BRZ =>
                        if flag_bus(4) = '1' then
                            --update PCL with low byte from instruction bus
                            PCL_SEL <= "10";
                            PCL_UPDATE <= '1';
                            --update PCH with high byte from instruction bus
                            PCH_SEL <= "10";
                            PCH_UPDATE <= '1';
                        end if;
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when BRN =>
                        if flag_bus(3) = '1' then
                            --update PCL with low byte from instruction bus
                            PCL_SEL <= "10";
                            PCL_UPDATE <= '1';
                            --update PCH with high byte from instruction bus
                            PCH_SEL <= "10";
                            PCH_UPDATE <= '1';
                        end if;
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when BRP =>
                        if flag_bus(2) = '1' then
                            --update PCL with low byte from instruction bus
                            PCL_SEL <= "10";
                            PCL_UPDATE <= '1';
                            --update PCH with high byte from instruction bus
                            PCH_SEL <= "10";
                            PCH_UPDATE <= '1';
                        end if;
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when BRC =>
                        if flag_bus(1) = '1' then
                            --update PCL with low byte from instruction bus
                            PCL_SEL <= "10";
                            PCL_UPDATE <= '1';
                            --update PCH with high byte from instruction bus
                            PCH_SEL <= "10";
                            PCH_UPDATE <= '1';
                        end if;
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when BRV =>
                        if flag_bus(0) = '1' then
                            --update PCL with low byte from instruction bus
                            PCL_SEL <= "10";
                            PCL_UPDATE <= '1';
                            --update PCH with high byte from instruction bus
                            PCH_SEL <= "10";
                            PCH_UPDATE <= '1';
                        end if;
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when HLT =>
                        state_next <= HALT;
                    when others => --NOP
                        state_next <= PCL_INC;
                end case;
            --=======================================================--
            -- IMMEDIATE_EXE
            -- Execute state for immediate format instructions.
            when IMMEDIATE_EXE =>
                case op is
                    when PUSH =>
                        --push source register onto stack
                        RF_CS <= '1';
                        SP_EN <= '1';
                        SP_UPDATE <= '1';
                        ADR_SEL <= "10";
                        DAT_SEL <= "001";
                        MEM_WRITE <= '1';
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when POP => --takes two clock cycles
                        --pop byte from the stack
                        SP_EN <= '1';
                        ADR_SEL <= "10";
                        MEM_READ <= '1';
                        --write back to destination register
                        state_next <= MEM_WRITEBACK;
                    when LDI =>
                        --write immediate byte to destination register
                        DAT_SEL <= "011";
                        RF_CS <= '1';
                        RF_WE <= '1';
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when LDA =>
                        --read byte from data memory
                        ADR_SEL <= "11";
                        MEM_READ <= '1';
                        --write back to destination register
                        state_next <= MEM_WRITEBACK;
                    when LDO =>
                        --calculate address
                        -- ALU_OP is determined by the ALU decoder
                        ALU_EN <= '1';
                        SRC_SEL <= "11";
                        TAR_SEL <= "01";

                        --update flags
                        ALU_STAT <= '1';
                        SR_WE <= '1';
                        SR_FLG <= '1';

                        --read from memory
                        ADR_SEL <= "01";
                        MEM_READ <= '1';

                        --write back to destination register
                        state_next <= MEM_WRITEBACK;
                    when STA =>
                        --write source register to memory
                        RF_CS <= '1';
                        DAT_SEL <= "001";
                        ADR_SEL <= "11";
                        MEM_WRITE <= '1';
                        --fetch the next instruction
                        state_next <= PCL_INC;
                    when others => --ALU operations
                        -- ALU_OP is determined by the ALU decoder
                        SRC_SEL <= "11";
                        TAR_SEL <= "01";
                        ALU_EN <= '1';

                        --update flags
                        ALU_STAT <= '1';
                        SR_WE <= '1';
                        SR_FLG <= '1';

                        --write back
                        OUT_SEL <= "10";
                        RF_CS <= '1';
                        RF_WE <= '1';

                        --fetch the next instruction
                        state_next <= PCL_INC;
                end case;
            --=======================================================--
            -- MEM_WRITEBACK
            -- write read memory address into destination register
            when MEM_WRITEBACK =>
                case op is
                    when LDO =>
                        ADR_SEL <= "01";
                    when POP =>
                        ADR_SEL <= "10";
                    when others => --LDA and unknowns
                        ADR_SEL <= "11";
                end case;

                OUT_SEL <= "11";
                RF_CS <= '1';
                RF_WE <= '1';
                --fetch the next instruction
                state_next <= PCL_INC;
        end case;
    end process main_fsm;

    --OUTPUT PART
    --ALU decoder
    alu_decode: process(state, op, fnct) is
    begin
        case state is
            when PCL_INC | PCH_INC =>
                ALU_OP <= "0000";
            when others =>
                if RFormatCheck(op) = '1' then
                    case fnct is
                        when SUB =>
                            ALU_OP <= "0001";
                        when ANDG =>
                            ALU_OP <= "0010";
                        when ORG =>
                            ALU_OP <= "0011";
                        when XORG =>
                            ALU_OP <= "0100";
                        when NOTG =>
                            ALU_OP <= "0101";
                        when LSL =>
                            ALU_OP <= "0110";
                        when LSR =>
                            ALU_OP <= "0111";
                        when ADDC =>
                            ALU_OP <= "1000";
                        when SUBC =>
                            ALU_OP <= "1001";
                        when others => --ADD and unknowns
                            ALU_OP <= "0000";
                    end case;
                else
                    case op is
                        when SUBI =>
                            ALU_OP <= "0001";
                        when ANDI =>
                            ALU_OP <= "0010";
                        when ORI =>
                            ALU_OP <= "0011";
                        when XORI =>
                            ALU_OP <= "0100";
                        when others => --ADDI and unknowns
                            ALU_OP <= "0000";
                    end case;
                end if;
        end case;
    end process alu_decode;

end Behavioral;