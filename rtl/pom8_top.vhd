----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.07.2025 22:57:09
-- Design Name: 
-- Module Name: POM8_Top - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--pomegranate libraries
use WORK.pomegranate_inst_conf.ALL;
use WORK.pomegranate_memory_map_conf.ALL;

entity POM8_Top is
    Port (
        CLK, RST: in std_logic;
--        op1: out opcode;
--        funct1: out funct;
--        inst_bus: out std_logic_vector(instruction_w-1 downto 0);
--        inst_adr_bus: out std_logic_vector(Iaddr_w-1 downto 0);
--        dat_bus: out std_logic_vector(word_w-1 downto 0);
--        dat_adr_bus: out std_logic_vector(Maddr_w-1 downto 0);
--        flg_bus: out std_logic_vector(4 downto 0);
        --I/O pins
        pins: inout std_logic_vector(7 downto 0)
    );
end entity POM8_Top;

architecture Behavioral of POM8_Top is

--components

-- ALU
component ALU is
    generic (
        WORD_WIDTH: natural := 8; --data width
        FLAG_NUM: natural := 6    --num of status flags
    );
    Port (
        ALU_EN, ALU_IMM: in std_logic;
        ALU_OP: in std_logic_vector(3 downto 0);
        Rs, Rt, Immediate: in std_logic_vector(WORD_WIDTH-1 downto 0);
        result_out: out std_logic_vector(WORD_WIDTH-1 downto 0);
        C_flag_in: in std_logic;
        flag_bus: out std_logic_vector(FLAG_NUM-1 downto 0)
    );
end component ALU;

--GPIO controller
component GPIO_Controller is
    generic (
        --this design is made for a number of pins greater than or equal to the word width
        PIN_NUM: natural := 16;
        WORD_WIDTH: natural := 8;
        REGISTER_ADDRESS_WIDTH: natural := 3
    );
    port (
        CLK: in std_logic;
        ARST: in std_logic;
        CS: in std_logic;
        RnW: in std_logic;
        RS: in std_logic_vector(REGISTER_ADDRESS_WIDTH-1 downto 0);
        
        -- the size of each register in bits is given by the number of pins divided by the number of registers
        din: in std_logic_vector(WORD_WIDTH-1 downto 0);
        dout: out std_logic_vector(WORD_WIDTH-1 downto 0);
        pins: inout std_logic_vector(PIN_NUM-1 downto 0)
    );
end component GPIO_Controller;

--data memory
component Memory_ITF is
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
end component Memory_ITF;

--program counter
component PC is
    generic (
        a: natural := 8
    );
    Port (
        CLK, RST: in std_logic;
        PC_INC, DAT_PC, PC_LDA: in std_logic;
        data_bus: inout std_logic_vector(a-1 downto 0);
        instruction_bus: in std_logic_vector(a-1 downto 0);
        address_out: out std_logic_vector(a-1 downto 0)
    );
end component PC;

--stack pointer
component Stack_Pointer is
    generic (
        a: natural := 8 --memory address width
    );
    Port (
        CLK, RST: in std_logic;
        enable, Pntr_INC: in std_logic;
        address: out std_logic_vector(a-1 downto 0)
    );
end component Stack_Pointer;

--status register
component Status_Register is
    Generic (
        WORD_WIDTH: natural := 8;
        FLAG_NUM: natural := 6
    );
    Port (
        CLK: in std_logic;
        ARST: in std_logic;
        WE, DAT, FLG, CnS: in std_logic;
        C_out: out std_logic;
        flag_bus: inout std_logic_vector(FLAG_NUM-1 downto 0);
        data_bus: inout std_logic_vector(WORD_WIDTH-1 downto 0)
    );
end component Status_Register;

--program memory
component program_memory is
    generic (
        i: natural := 8; --instruction width
        k: natural := 8  --memory address width
    );
    Port (
        address: in std_logic_vector(k-1 downto 0);
        dout: out std_logic_vector(i-1 downto 0)
    );
end component program_memory;

--register file
component regFile is
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
end component regFile;

--control unit
component CU is
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
end component CU;

--signals
--buses
signal data_bus: std_logic_vector(word_w-1 downto 0);
signal data_address_bus: std_logic_vector(Maddr_w-1 downto 0);

signal instruction_bus: std_logic_vector(instruction_w-1 downto 0);
signal instruction_address_bus: std_logic_vector(Iaddr_w-1 downto 0);

signal flag_bus: std_logic_vector(4 downto 0);

signal Reg_s, Reg_t: std_logic_vector(word_w-1 downto 0);
signal calc_mux: std_logic_vector(word_w-1 downto 0);
signal C_flag: std_logic;
signal MEM_D_OUT: std_logic_vector(word_w-1 downto 0);

--control signals
--ALU
signal ALU_EN, ALU_IMM, ALU_ADR: std_logic;
signal ALU_OP: std_logic_vector(3 downto 0);
--GPIO controller
signal GPIO_CS: std_logic;
signal GPIO_RS: std_logic_vector(2 downto 0);
--data memory
signal MEM_CS: std_logic;
signal MEM_WRITE, MEM_READ: std_logic;
signal DAT_ADR: std_logic_vector(1 downto 0);
--program counter
signal PC_INC, DAT_PC, PC_LDA: std_logic;
--stack pointer
signal stack_enable, Pntr_INC: std_logic;
--status register
signal SR_WE, SR_DAT, SR_FLG, SR_CnS: std_logic;
--register file
signal RF_WE, RF_CS: std_logic;
signal SRC_IMM: std_logic;

begin

--control unit instantiation
CU_inst: CU port map (
    op => slv2op(instruction_bus(instruction_w-1 downto instruction_w-op_w)),
    fnct => slv2funct(instruction_bus(19 downto 15)),
    flag_bus => flag_bus,
    ALU_EN => ALU_EN, ALU_IMM => ALU_IMM,
    ALU_OP => ALU_OP,
    MEM_WRITE => MEM_WRITE, MEM_READ => MEM_READ,
    PC_INC => PC_INC, DAT_PC => DAT_PC, PC_LDA => PC_LDA,
    stack_enable => stack_enable, Pntr_INC => Pntr_INC,
    SR_WE => SR_WE, SR_DAT => SR_DAT, SR_FLG => SR_FLG, SR_CnS => SR_CnS,
    RF_WE => RF_WE, RF_CS => RF_CS,
    SRC_IMM => SRC_IMM,
    ALU_ADR => ALU_ADR,
    DAT_ADR => DAT_ADR
);
--op1 <= slv2op(instruction_bus(instruction_w-1 downto instruction_w-op_w));
--funct1 <= slv2funct(instruction_bus(19 downto 15));
--inst_bus <= instruction_bus;
--inst_adr_bus <= instruction_address_bus;
--dat_bus <= data_bus;
--dat_adr_bus <= data_address_bus;
--flg_bus <= flag_bus;

--immediate on the databus
with SRC_IMM select
    data_bus <= instruction_bus(AddressIndex(register_format, immediate2) downto AddressIndex(register_format, immediate2)-(word_w-1)) when '1',
                (others => 'Z') when others;

--ALU instantiation
--there are 5 flags in the status register
ALU_inst: ALU generic map (word_w, 5) port map (
    ALU_EN => ALU_EN, ALU_IMM => ALU_IMM,
    ALU_OP => ALU_OP,
    Rs => Reg_s, Rt => Reg_t, Immediate => instruction_bus(AddressIndex(register_format, immediate2) downto AddressIndex(register_format, immediate2)-(word_w-1)),
    result_out => calc_mux,
    C_flag_in => C_flag,
    flag_bus => flag_bus
);
--address calculation
data_bus <= calc_mux when ALU_ADR = '0' else (others => 'Z');

--program counter instantiation
PC_inst: PC generic map (Iaddr_w) port map (
    CLK => CLK, RST => RST,
    PC_INC => PC_INC, DAT_PC => DAT_PC, PC_LDA => PC_LDA,
    data_bus => data_bus,
    instruction_bus => instruction_bus(AddressIndex(branch_format, Immediate1) downto AddressIndex(branch_format, Immediate1)-(Iaddr_w-1)),
    address_out => instruction_address_bus
);

--stack pointer instantiation
STCK_PNTR_inst: Stack_Pointer generic map (Maddr_w) port map (
    CLK => CLK, RST => RST,
    enable => stack_enable, Pntr_INC => Pntr_INC,
    address => data_address_bus
);

--status register instnatiation
--there are 5 flags in the status register
SR_inst: Status_Register generic map (word_w, 5) port map (
    CLK => CLK, ARST => RST,
    WE => SR_WE, DAT => SR_DAT, FLG => SR_FLG, CnS => SR_CnS,
    C_out => C_flag,
    flag_bus => flag_bus,
    data_bus => data_bus
);

--MEMORIES

--data address selection
with DAT_ADR select
    data_address_bus <= instruction_bus(AddressIndex(addressing_format, Immediate1) downto AddressIndex(addressing_format, Immediate1)-(word_w-1)) & instruction_bus(AddressIndex(addressing_format, Immediate2) downto AddressIndex(addressing_format, Immediate2)-(word_w-1)) when "00",
                        instruction_bus(AddressIndex(addressing_format, Rs) downto AddressIndex(addressing_format, Rs)-(word_w-1)) & instruction_bus(AddressIndex(addressing_format, Immediate1) downto AddressIndex(addressing_format, Immediate1)-(word_w-1)) when "01",
                        "00000000" & calc_mux when "10",
                        (others => 'Z') when others;

--memory map logic
GPIO_CS <= '1' when to_integer(unsigned(data_address_bus)) >= find_device_address(GPIO) and (MEM_READ = '1' OR MEM_WRITE = '1') else '0';
MEM_CS <= '1' when to_integer(unsigned(data_address_bus)) >= find_device_address(RAM) and to_integer(unsigned(data_address_bus)) < find_device_address(GPIO) and (MEM_READ = '1' OR MEM_WRITE = '1') else '0';

--register file instantiation
RF_inst: regFile generic map (word_w, Raddr_w) port map (
    CLK => CLK, ARST => RST, WE => RF_WE, CS => RF_CS,
    source_register => instruction_bus(AddressIndex(register_format, Rs) downto AddressIndex(register_format, Rs)-(Raddr_w-1)),
    target_register => instruction_bus(AddressIndex(register_format, Rt) downto AddressIndex(register_format, Rt)-(Raddr_w-1)),
    destination_register => instruction_bus(AddressIndex(register_format, Rd) downto AddressIndex(register_format, Rd)-(Raddr_w-1)),
    data_bus => data_bus,
    source_out => Reg_s, target_out => Reg_t
);

--gpio controller instantiation
--8 I/O pins and a register address width of 2
GPIO_inst: GPIO_Controller generic map (8, word_w, 2) port map (
    CLK => CLK, ARST => RST, CS => GPIO_CS, RnW => MEM_READ, RS => data_address_bus(5 downto 4),
    din => data_bus,
    dout => data_bus,
    pins => pins
);

--data memory instantiation
DATA_MEM_inst: Memory_ITF generic map (word_w, Maddr_w) port map (
    CLK => CLK,
    WE => MEM_WRITE, CS => MEM_CS,
    din => data_bus,
    dout => MEM_D_OUT,
    address => data_address_bus
);
data_bus <= MEM_D_OUT when (MEM_CS = '1' and MEM_READ = '1') else (others => 'Z');

--program memory instantiation
PROG_MEM_inst: program_memory generic map (instruction_w, Iaddr_w) port map (
    address => instruction_address_bus,
    dout => instruction_bus
);

end Behavioral;
