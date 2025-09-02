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
        clk, arst: in std_logic;
        op: in opcode;
        fnct: in funct;
        flag_bus: inout std_logic_vector(4 downto 0);
        --control signals
        --ALU
        ALU_EN, ALU_STAT: out std_logic;
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
signal data_address_bus: std_logic_vector(Maddr_w-1 downto 0);

signal instruction_bus: std_logic_vector(instruction_w-1 downto 0);
signal instruction_address_bus: std_logic_vector(Iaddr_w-1 downto 0);

signal flag_bus: std_logic_vector(4 downto 0);

--control signals
signal ALU_EN, ALU_STAT: std_logic;
signal ALU_OP: std_logic_vector(3 downto 0);
signal MEM_WRITE, MEM_READ: std_logic;
signal PC_UPDATE: std_logic;
signal IR_WRITE: std_logic;
signal SP_EN, SP_UPDATE: std_logic;
signal SR_WE, SR_FLG, SR_CnS: std_logic;
signal RF_WE, RF_CS: std_logic;

-- mux select signals/bus management
signal ADR_SEL: std_logic_vector(1 downto 0);
signal OUT_SEL: std_logic_vector(1 downto 0);
signal DAT_SEL: std_logic_vector(1 downto 0);
signal SRC_SEL: std_logic_vector(1 downto 0);
signal TAR_SEL: std_logic_vector(1 downto 0);

--MUX's
signal SRC_MUX_out: std_logic_vector(word_w-1 downto 0);
signal TAR_MUX_out: std_logic_vector(word_w-1 downto 0);

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

begin

--==========================================================--
--THE CONTROL SECTION                                       --
--==========================================================--

--control unit instance
CU_inst: CU port map (
    clk => CLK,
    arst => RST,
    op => slv2op(instruction_bus(instruction_w-1 downto instruction_w-op_w)),
    fnct => slv2funct(instruction_bus(19 downto 15)),
    flag_bus => flag_bus,
    ALU_EN => ALU_EN,
    ALU_STAT => ALU_STAT,
    ALU_OP => ALU_OP,
    MEM_WRITE => MEM_WRITE,
    MEM_READ => MEM_READ,
    PC_UPDATE => PC_UPDATE,
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
    TAR_SEL => TAR_SEL
);
--simulation outputs
op1 <= slv2op(instruction_bus(instruction_w-1 downto instruction_w-op_w));
fnct1 <= slv2funct(instruction_bus(19 downto 15));
data <= data_bus;
data_address <= data_address_bus;
instruction <= instruction_bus;
instruction_address <= instruction_address_bus;

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

--program counter instance
PC_inst: counter_reg_prim generic map (
    Iaddr_w,
    "00000000" --initialise at 0
) port map (
    CLK => CLK,
    ARST => RST,
    WE => PC_UPDATE,
    address_next => data_bus,
    address_out => instruction_address_bus
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
    Iaddr_w
) port map (
    address => instruction_address_bus,
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
    source_register => instruction_bus(AddressIndex(register_format, Rs) downto AddressIndex(register_format, Rs)-(Raddr_w-1)),
    target_register => instruction_bus(AddressIndex(register_format, Rt) downto AddressIndex(register_format, Rt)-(Raddr_w-1)),
    destination_register => instruction_bus(AddressIndex(register_format, Rd) downto AddressIndex(register_format, Rd)-(Raddr_w-1)),
    source_out => src_register,
    target_out => tar_register
);

--source MUX
with SRC_SEL select
    SRC_MUX_out <=  instruction_address_bus when "00",
                    PC_old when "01",
                    src_register when others;

--target MUX
with TAR_SEL select
    TAR_MUX_out <=  instruction_bus(AddressIndex(register_format, immediate2) downto AddressIndex(register_format, immediate2)-(word_w-1)) when "01",
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
                DMEM_out when "11",
                (others => 'Z') when others;

--==========================================================--
--THE DATA MEMORY SECTION                                   --
--==========================================================--

--data MUX
with DAT_SEL select
    data_bus <= src_register when "01",
                instruction_bus(AddressIndex(register_format, immediate2) downto AddressIndex(register_format, immediate2)-(word_w-1)) when "10",
                instruction_address_bus when "11",
                (others => 'Z') when others;

--stack pointer instance
SP_inst: Stack_Pointer generic map (
    Maddr_w
) port map (
    CLK => CLK,
    RST => RST,
    enable => SP_EN,
    Pntr_INC => SP_UPDATE,
    address => data_address_bus
);

--data address MUX
with ADR_SEL select
    data_address_bus <= instruction_bus(AddressIndex(addressing_format, Immediate1) downto AddressIndex(addressing_format, Immediate1)-(word_w-1)) & instruction_bus(AddressIndex(addressing_format, Immediate2) downto AddressIndex(addressing_format, Immediate2)-(word_w-1)) when "01",
                        instruction_bus(AddressIndex(addressing_format, Rs) downto AddressIndex(addressing_format, Rs)-(word_w-1)) & instruction_bus(AddressIndex(addressing_format, Immediate1) downto AddressIndex(addressing_format, Immediate1)-(word_w-1)) when "10",
                        "00000000" & ALU_out when "11",
                        (others => 'Z') when others;

--memory map logic
GPIO_CS <= '1' when to_integer(unsigned(data_address_bus)) >= find_device_address(GPIO) and (MEM_READ = '1' OR MEM_WRITE = '1') else '0';
DMEM_CS <= '1' when to_integer(unsigned(data_address_bus)) >= find_device_address(RAM) and to_integer(unsigned(data_address_bus)) < find_device_address(GPIO) and (MEM_READ = '1' OR MEM_WRITE = '1') else '0';

--data memory instance
DM_inst: Memory_ITF generic map (
    word_w,
    Maddr_w
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
    RS => data_address_bus(5 downto 4),
    din => data_bus,
    dout => data_bus,
    pins => pins
);

end Behavioral;
