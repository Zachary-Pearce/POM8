library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--pomegranate libraries
use WORK.pomegranate_inst_conf.ALL;
use WORK.pomegranate_memory_map_conf.ALL;

entity POM8_Top is
    Port (
        CLK, RST: in std_logic;
        --I/O pins
        pins: inout std_logic_vector(7 downto 0)
        --simulation
--        op1: out opcodes;
--        fnct1: out funct;
--        data: out std_logic_vector(word_w-1 downto 0);
--        data_address: out std_logic_vector(Daddr_w-1 downto 0);
--        instruction: out std_logic_vector(instruction_w-1 downto 0);
--        instruction_address: out std_logic_vector(Iaddr_w-1 downto 0);
--        flag: out std_logic_vector(4 downto 0)
    );
end entity POM8_Top;
architecture Behavioral of POM8_Top is

--components

--counter register primitive
component counter_reg_prim is
    generic (
        ADDRESS_WIDTH: natural := 8;
        INIT: std_logic_vector(7 downto 0) := "00000000"
    );
    port (
        CLK, ARST: in std_logic;
        WE: in std_logic;
        address_next: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        address_out: out std_logic_vector(ADDRESS_WIDTH-1 downto 0)
    );
end component counter_reg_prim;

--register primitive
component reg_prim is
    generic (
        REGISTER_WIDTH: natural := 8
    );
    port (
        CLK, ARST: in std_logic;
        WE: in std_logic;
        din: in std_logic_vector(REGISTER_WIDTH-1 downto 0);
        dout: out std_logic_vector(REGISTER_WIDTH-1 downto 0)
    );
end component reg_prim;

--control unit
component CU is
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
end component CU;

--status register
component Status_Register is
    Generic (
        FLAG_NUM: natural := 6
    );
    Port (
        CLK: in std_logic;
        ARST: in std_logic;
        WE, FLG, CnS: in std_logic;
        C_out: out std_logic;
        flag_bus: inout std_logic_vector(FLAG_NUM-1 downto 0)
    );
end component Status_Register;

--instruction memory
component program_memory is
    generic (
        i: natural := 32; --instruction width
        k: natural := 16  --memory address width
    );
    Port (
        address: in std_logic_vector(k-1 downto 0);
        dout: out std_logic_vector(i-1 downto 0)
    );
end component program_memory;

--register file
component reg_file is
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
end component reg_file;

--ALU
component ALU is
    generic (
        WORD_WIDTH: natural := 8; --data width
        FLAG_NUM: natural := 6    --num of status flags
    );
    Port (
        EN, STAT: in std_logic;
        OP: in std_logic_vector(3 downto 0);
        Rs, Rt: in std_logic_vector(WORD_WIDTH-1 downto 0);
        result_out: out std_logic_vector(WORD_WIDTH-1 downto 0);
        C_flag_in: in std_logic;
        flag_bus: out std_logic_vector(FLAG_NUM-1 downto 0)
    );
end component ALU;

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

--signals
--buses
signal data_bus: std_logic_vector(word_w-1 downto 0);
signal data_address_bus: std_logic_vector(Daddr_w-1 downto 0);

signal instruction_bus: std_logic_vector(instruction_w-1 downto 0);
signal instruction_address_bus: std_logic_vector(Iaddr_w-1 downto 0);

signal flag_bus: std_logic_vector(4 downto 0);

--control signals
signal ALU_EN, ALU_STAT: std_logic;
signal ALU_OP: std_logic_vector(3 downto 0);
signal MEM_WRITE, MEM_READ: std_logic;
signal PCL_UPDATE: std_logic;
signal PCH_UPDATE: std_logic;
signal IR_WRITE: std_logic;
signal SP_EN, SP_UPDATE: std_logic;
signal SR_WE, SR_FLG, SR_CnS: std_logic;
signal RF_WE, RF_CS: std_logic;

-- mux select signals/bus management
signal ADR_SEL: std_logic_vector(1 downto 0); -- Z, ALU_out, SP_out, Imm10
signal OUT_SEL: std_logic_vector(1 downto 0); -- Z, ALU_out_reg, ALU_out, DM_out
signal DAT_SEL: std_logic_vector(2 downto 0); -- Z, Rs, Rt, Imm8, PCL_out, PCH_out, Z, Z
signal SRC_SEL: std_logic_vector(1 downto 0); -- PCL_out, PCH_out, PC_old, Rs
signal TAR_SEL: std_logic_vector(1 downto 0); -- Rt, Imm8, 1, Rt
signal PCL_SEL: std_logic_vector(1 downto 0); -- data_bus, Rt, Imm16(8), data_bus
signal PCH_SEL: std_logic_vector(1 downto 0); -- data_bus, Rs, Imm16(15), data_bus

--MUX's
signal SRC_MUX_out: std_logic_vector(word_w-1 downto 0);
signal TAR_MUX_out: std_logic_vector(word_w-1 downto 0);
signal PCL_MUX_out: std_logic_vector(word_w-1 downto 0);
signal PCH_MUX_out: std_logic_vector(word_w-1 downto 0);

-- wires
signal C_flag: std_logic;
signal PC_old: std_logic_vector(Iaddr_w-1 downto 0);
signal ROM_instruction: std_logic_vector(instruction_w-1 downto 0);
signal src_register: std_logic_vector(word_w-1 downto 0);
signal tar_register: std_logic_vector(word_w-1 downto 0);
signal ALU_out: std_logic_vector(word_w-1 downto 0);
signal ALU_reg_out: std_logic_vector(word_w-1 downto 0);
signal DMEM_out: std_logic_vector(word_w-1 downto 0);
signal GPIO_CS: std_logic;
signal DMEM_CS: std_logic;
signal GPIO_out: std_logic_vector(word_w-1 downto 0);
signal GPIO_reg_out: std_logic_vector(word_w-1 downto 0);
signal GPIO_reg_WE: std_logic;
signal MEM_out: std_logic_vector(word_w-1 downto 0);
signal SP_out: std_logic_vector(Daddr_w-1 downto 0);
signal s,t,d: std_logic_vector(Raddr_w-1 downto 0);

begin

--==========================================================--
--THE CONTROL SECTION                                       --
--==========================================================--

--control unit instance
CU_inst: CU port map (
    clk => CLK,
    arst => RST,
    op => slv2op(instruction_bus(instruction_w-1 downto instruction_w-op_w)),
    fnct => slv2funct(instruction_bus(5 downto 0)),
    flag_bus => flag_bus,
    ALU_EN => ALU_EN,
    ALU_STAT => ALU_STAT,
    ALU_OP => ALU_OP,
    MEM_WRITE => MEM_WRITE,
    MEM_READ => MEM_READ,
    PCL_UPDATE => PCL_UPDATE,
    PCH_UPDATE => PCH_UPDATE,
    IR_WRITE => IR_WRITE,
    SP_EN => SP_EN,
    SP_UPDATE => SP_UPDATE,
    SR_WE => SR_WE,
    SR_FLG => SR_FLG,
    SR_CnS => SR_CnS,
    RF_WE => RF_WE,
    RF_CS => RF_CS,
    ADR_SEL => ADR_SEL,
    OUT_SEL => OUT_SEL,
    DAT_SEL => DAT_SEL,
    SRC_SEL => SRC_SEL,
    TAR_SEL => TAR_SEL,
    PCL_SEL => PCL_SEL,
    PCH_SEL => PCH_SEL
);
--simulation outputs
--op1 <= slv2op(instruction_bus(instruction_w-1 downto instruction_w-op_w));
--fnct1 <= slv2funct(instruction_bus(5 downto 0));
--data <= data_bus;
--data_address <= data_address_bus;
--instruction <= instruction_bus;
--instruction_address <= instruction_address_bus;
--flag <= flag_bus;

--status register instance
SR_inst: Status_Register generic map (
    5 --the number of status flags
) port map (
    CLK => CLK,
    ARST => RST,
    WE => SR_WE,
    FLG => SR_FLG,
    CnS => SR_CnS,
    C_out => C_flag,
    flag_bus => flag_bus
);

--==========================================================--
--THE INSTRUCTION MEMORY SECTION                            --
--==========================================================--

--PCL MUX
with PCL_SEL select
    PCL_MUX_out <=  tar_register when "01",
                    GetOperand(instruction_bus, branch_format, Immediate16)(7 downto 0) when "10",
                    data_bus when others;

--program counter low instance
PCL_inst: counter_reg_prim generic map (
    Iaddr_w/2,
    "00000000" --initialise at 0
) port map (
    CLK => CLK,
    ARST => RST,
    WE => PCL_UPDATE,
    address_next => PCL_MUX_out,
    address_out => instruction_address_bus(7 downto 0)
);

--PCH MUX
with PCH_SEL select
    PCH_MUX_out <=  src_register when "01",
                    GetOperand(instruction_bus, branch_format, Immediate16)(15 downto 8) when "10",
                    data_bus when others;

--program counter high instance
PCH_inst: counter_reg_prim generic map (
    Iaddr_w/2,
    "00000000" --initialise at 0
) port map (
    CLK => CLK,
    ARST => RST,
    WE => PCH_UPDATE,
    address_next => PCH_MUX_out,
    address_out => instruction_address_bus(15 downto 8)
);

-- old program counter register
PC_old_reg: reg_prim generic map (
    Iaddr_w
) port map (
    CLK => CLK,
    ARST => RST,
    WE => IR_WRITE,
    din => instruction_address_bus,
    dout => PC_old
);

--instruction memory instance
PM_inst: program_memory generic map (
    instruction_w,
    8
) port map (
    address => instruction_address_bus(7 downto 0),
    dout => ROM_instruction
);

--instruction register instance
IR_inst: reg_prim generic map (
    instruction_w
) port map (
    CLK => CLK,
    ARST => RST,
    WE => IR_WRITE,
    din => ROM_instruction,
    dout => instruction_bus
);

--==========================================================--
--THE REGISTER SECTION                                      --
--==========================================================--

s <= GetOperand(instruction_bus, register_format, Rs);
t <= GetOperand(instruction_bus, register_format, Rt);
d <= GetOperand(instruction_bus, register_format, Rd);
--register file instance
RF_inst: reg_file generic map (
    word_w,
    Raddr_w
) port map (
    CLK => CLK,
    ARST => RST,
    WE => RF_WE,
    CS => RF_CS,
    din => data_bus,
    source_register => s,
    target_register => t,
    destination_register => d,
    source_out => src_register,
    target_out => tar_register
);

--source MUX
with SRC_SEL select
    SRC_MUX_out <=  instruction_address_bus(7 downto 0) when "00",
                    instruction_address_bus(15 downto 8) when "01",
                    PC_old(7 downto 0) when "10",
                    src_register when others;

--target MUX
with TAR_SEL select
    TAR_MUX_out <=  GetOperand(instruction_bus, immediate_format, immediate8) when "01",
                    "00000001" when "10",
                    tar_register when others;

--ALU instance
ALU_inst: ALU generic map (
    word_w,
    5 --the number of status flags
) port map (
    EN => ALU_EN,
    STAT => ALU_STAT,
    OP => ALU_OP,
    Rs => SRC_MUX_out,
    Rt => TAR_MUX_out,
    result_out => ALU_out,
    C_flag_in => C_flag,
    flag_bus => flag_bus
);

--ALU output register
ALU_out_reg: reg_prim generic map (
    word_w
) port map (
    CLK => CLK,
    ARST => RST,
    WE => ALU_EN,
    din => ALU_out,
    dout => ALU_reg_out
);

--ALU output MUX
with OUT_SEL select
    data_bus <= ALU_reg_out when "01",
                ALU_out when "10",
                MEM_out when "11",
                (others => 'Z') when others;

--==========================================================--
--THE DATA MEMORY SECTION                                   --
--==========================================================--

--data MUX
with DAT_SEL select
    data_bus <= src_register when "001",
                tar_register when "010",
                GetOperand(instruction_bus, immediate_format, immediate8) when "011",
                instruction_address_bus(7 downto 0) when "100",
                instruction_address_bus(15 downto 8) when "101",
                (others => 'Z') when others;

--stack pointer instance
SP_inst: Stack_Pointer generic map (
    Daddr_w
) port map (
    CLK => CLK,
    RST => RST,
    enable => SP_EN,
    Pntr_INC => SP_UPDATE,
    address => SP_out
);

--data address MUX
with ADR_SEL select
    data_address_bus <= "ZZZZZZZZZZ" when "00",
                        "00" & ALU_out when "01",
                        SP_out when "10",
                        GetOperand(instruction_bus, immediate_format, immediate2) & GetOperand(instruction_bus, immediate_format, immediate8) when others;

--memory map logic
GPIO_CS <= '1' when to_integer(unsigned(data_address_bus)) >= find_device_address(GPIO) else '0';
DMEM_CS <= '1' when to_integer(unsigned(data_address_bus)) >= find_device_address(RAM) and to_integer(unsigned(data_address_bus)) < find_device_address(GPIO) else '0';

--data memory instance
DM_inst: Memory_ITF generic map (
    word_w,
    Daddr_w
) port map (
    CLK => CLK,
    WE => MEM_WRITE,
    CS => DMEM_CS,
    din => data_bus,
    dout => DMEM_out,
    address => data_address_bus
);

--GPIO controller instance
--8 I/O pins and a register address width of 2
GPIO_inst: GPIO_Controller generic map (
    8,
    word_w,
    2
) port map (
    CLK => CLK,
    ARST => RST,
    CS => GPIO_CS,
    RnW => MEM_READ,
    RS => data_address_bus(1 downto 0),
    din => data_bus,
    dout => GPIO_out,
    pins => pins
);

GPIO_reg_WE <= GPIO_CS and MEM_READ;
--GPIO output register
GPIO_out_reg: reg_prim generic map (
    word_w
) port map (
    CLK => CLK,
    ARST => RST,
    WE => GPIO_reg_WE,
    din => GPIO_out,
    dout => GPIO_reg_out
);

MEM_out <= GPIO_reg_out when GPIO_CS = '1' and DMEM_CS = '0' else DMEM_out;

end Behavioral;
