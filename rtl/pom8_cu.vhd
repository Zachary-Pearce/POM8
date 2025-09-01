library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--pomegranate libraries
use WORK.pomegranate_inst_conf.ALL;

entity CU is
    Port (
        clk, arst: in std_logic;
        op: in opcode;
        fnct: in funct;
        flag_bus: inout std_logic_vector(4 downto 0);
        --control signals
        --ALU
        ALU_EN: out std_logic;
        ALU_OP: out std_logic_vector(3 downto 0);
        --Data memory
        MEM_WRITE, MEM_READ: out std_logic;
        --program counter
        PC_UPDATE: out std_logic;
        --instruction register
        IR_WRITE: out std_logic;
        --stack pointer
        SP_EN, SP_UPDATE: out std_logic;
        --status register
        SR_WE, SR_FLG, SR_CnS: out std_logic;
        --register file
        RF_WE, RF_CS: out std_logic;
        --data bus management
        ADR_SEL: out std_logic_vector(1 downto 0);
        OUT_SEL: out std_logic_vector(1 downto 0);
        DAT_SEL: out std_logic_vector(1 downto 0);
        --ALU input selection
        SRC_SEL: out std_logic_vector(1 downto 0);
        TAR_SEL: out std_logic_vector(1 downto 0)
    );
end entity CU;

architecture Behavioral of CU is
    type state_t is (FETCH, DECODE, REGISTER_EXECUTE, BRANCH_EXECUTE, ADDRESSING_EXECUTE, MEM_WRITE_BACK, PC_SUBROUTINE_UPDATE);
    signal state, state_next: state_t;
begin
    --SEQUENTIAL PART
    --fsm sync
    fsm_sync: process(clk, arst) is
    begin
        if arst = '1' then
            state <= FETCH;
        elsif rising_edge(clk) then
            state <= state_next;
        end if;
    end process fsm_sync;

    --COMBINATIONAL PART
    --main fsm
    main_fsm: process(state) is
    begin
        --control signal defaults
        ALU_EN <= '0';
        MEM_WRITE <= '0';
        MEM_READ <= '0';
        PC_UPDATE <= '0';
        IR_WRITE <= '0';
        SP_EN <= '0';
        SP_UPDATE <= '0';
        SR_WE <= '0';
        SR_FLG <= '0';
        SR_CnS <= '0';
        RF_WE <= '0';
        RF_CS <= '0';
        ADR_SEL <= "00"; -- Z, Imm, Imm (Rs & Rt), ALU_out
        OUT_SEL <= "00"; -- Z, ALU_out_reg, ALU_out, DM_out
        DAT_SEL <= "00"; -- Z, Rs, Imm, PC
        SRC_SEL <= "00"; -- PC, PC_OLD, Rs, Rs
        TAR_SEL <= "00"; -- Rt, Imm, 1, Rt
        flag_bus <= "ZZZZZ";

        --state machine
        case state is
            when FETCH =>
                PC_UPDATE <= '1';
                SRC_SEL <= "00";
                TAR_SEL <= "10";
                ALU_EN <= '1';
                OUT_SEL <= "10";
                IR_WRITE <= '1';
                state_next <= DECODE;
            when DECODE =>
                if RFormatCheck(op) = '1' then
                    state_next <= REGISTER_EXECUTE;
                elsif BFormatCheck(op) = '1' then
                    state_next <= BRANCH_EXECUTE;
                else
                    state_next <= ADDRESSING_EXECUTE;
                end if;
            when REGISTER_EXECUTE =>
                case fnct is
                    when PUSH =>
                        RF_CS <= '1';
                        DAT_SEL <= "01";
                        SP_EN <= '1';
                        SP_UPDATE <= '1';
                        MEM_WRITE <= '1';
                        state_next <= FETCH;
                    when POP =>
                        SP_EN <= '1';
                        MEM_READ <= '1';
                        state_next <= MEM_WRITE_BACK;
                    when SETC =>
                        SR_WE <= '1';
                        SR_CnS <= '0';
                        flag_bus <= "00010";
                        state_next <= FETCH;
                    when CLRC =>
                        SR_WE <= '1';
                        SR_CnS <= '1';
                        flag_bus <= "11101";
                        state_next <= FETCH;
                    when SETV =>
                        SR_WE <= '1';
                        SR_CnS <= '0';
                        flag_bus <= "00001";
                        state_next <= FETCH;
                    when CLRV =>
                        SR_WE <= '1';
                        SR_CnS <= '1';
                        flag_bus <= "11110";
                        state_next <= FETCH;
                    when others => --ALU operations
                        SRC_SEL <= "10";
                        if fnct = ADDI or funct = SUBI or funct = ANDI or funct = ORI or funct = XORI then
                            TAR_SEL <= "01";
                        else
                            TAR_SEL <= "00";
                        end if;

                        ALU_EN <= '1';
                        --update flags
                        SR_WE <= '1';
                        SR_FLG <= '1';

                        OUT_SEL <= "10";
                        RF_CS <= '1';
                        RF_WE <= '1';
                        state_next <= FETCH;
                end case;
            when BRANCH_EXECUTE =>
                case op is
                    when CALL =>
                        SP_EN <= '1';
                        SP_UPDATE <= '1';
                        DAT_SEL <= "11";
                        MEM_WRITE <= '1';
                        state_next <= PC_SUBROUTINE_UPDATE;
                    when RET =>
                        SP_EN <= '1';
                        MEM_READ <= '1';
                        state_next <= PC_SUBROUTINE_UPDATE;
                    when JMP =>
                        DAT_SEL <= "10";
                        PC_UPDATE <= '1';
                        state_next <= FETCH
                    --for branches we jump if the relevant flag is set
                    when BRZ =>
                        if flag_bus(4) = '1' then
                            DAT_SEL <= "10";
                            PC_UPDATE <= '1';
                        end if;
                        state_next <= FETCH
                    when BRN =>
                        if flag_bus(3) = '1' then
                            DAT_SEL <= "10";
                            PC_UPDATE <= '1';
                        end if;
                        state_next <= FETCH
                    when BRP =>
                        if flag_bus(2) = '1' then
                            DAT_SEL <= "10";
                            PC_UPDATE <= '1';
                        end if;
                        state_next <= FETCH
                    when BRC =>
                        if flag_bus(1) = '1' then
                            DAT_SEL <= "10";
                            PC_UPDATE <= '1';
                        end if;
                        state_next <= FETCH
                    when BRV =>
                        if flag_bus(0) = '1' then
                            DAT_SEL <= "10";
                            PC_UPDATE <= '1';
                        end if;
                        state_next <= FETCH
                    when others => --NOP
                        state_next <= FETCH --these do nothing
                end case;
            when ADDRESSING_EXECUTE =>
                case (op) is
                    when LDR =>
                        ADR_SEL <= "01";
                        MEM_READ <= '1';
                        state_next <= MEM_WRITE_BACK;
                    when LDW =>
                        DAT_SEL <= "10";
                        RF_CS <= '1';
                        RF_WE <= '1';
                        state_next <= FETCH;
                    when LDI =>
                        SRC_SEL <= "10";
                        TAR_SEL <= "01";
                        ALU_EN <= '1';

                        ADR_SEL <= "11";
                        MEM_READ <= '1';
                        state_next <= MEM_WRITE_BACK;
                    when STR =>
                        DAT_SEL <= "01";
                        MEM_WRITE <= '1';
                        state_next <= FETCH;
                    when STW =>
                        ADR_SEL <= "10";
                        DAT_SEL <= "10";
                        MEM_WRITE <= '1';
                        state_next <= FETCH;
                    when others => --STI
                        SRC_SEL <= "10";
                        TAR_SEL <= "01";
                        ALU_EN <= '1';

                        DAT_SEL <= "01";
                        ADR_SEL <= "11";
                        MEM_WRITE <= '1';
                        state_next <= FETCH;
                end case;
            when MEM_WRITE_BACK =>
                OUT_SEL <= "11";
                RF_CS <= '1';
                RF_WE <= '1';
                state_next <= FETCH;
            when PC_SUBROUTINE_UPDATE =>
                if op = CALL
                    DAT_SEL <= "10";
                else --if RET
                    OUT_SEL <= "11";
                end if;
                PC_UPDATE <= '1';

                state_next <= DECODE;
        end case;
    end process main_fsm;

    --alu decoder
    alu_decoder: process(fnct) is
    begin
        ALU_OP <= "0000"; --default value
        case fnct is
            when SUB | SUBI =>
                ALU_OP <= "0001";
            when ANDG | ANDI =>
                ALU_OP <= "0010";
            when ORG | ORI =>
                ALU_OP <= "0011";
            when XORG | XORI =>
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
            when others => --ADD, ADDI, and unknowns
                ALU_OP <= "0000";
        end case;
    end process alu_decoder;
end Behavioral;
