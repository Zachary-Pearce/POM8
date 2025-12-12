----------------------------------------------------------------------------------
-- Engineer: Zachary Pearce
-- 
-- Create Date: 23/02/2025
-- Module Name: pomegranate_inst_conf
-- Project Name: Pomegranate
-- Description: Define parameters that are used to modify the instruction set architecture of Pomegranate configured architectures
-- 
-- Dependencies: NA
-- 
-- Revision: 1.0
-- Revision Date: 23/02/2025
-- Notes: File Created
----------------------------------------------------------------------------------

library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

--package declarations
package pomegranate_inst_conf is
--==========================================================--
--VARIABLES                                                 --
--==========================================================--

    constant word_w: NATURAL := 8; --the width of a word
    constant instruction_w: NATURAL := 24; --the width of instructions
    constant op_w: NATURAL := 6;    --the number of bits reserved for the opcode in instructions
    constant Raddr_w: NATURAL := 4; --the number of bits reserved for register addresses
    constant Daddr_w: NATURAL := 10; --the number of bits reserved for data addresses
    constant Iaddr_w: NATURAL := 16; --the number of bits reserved for instruction addresses
    
    type opcodes is
    (
        --your opcodes go here...
        NA,
        NOP,
        CALL,
        RET,
        JMP,
        BRZ,
        BRN,
        BRP,
        BRC,
        BRV,
        HLT,
        ADDI,
        SUBI,
        ANDI,
        ORI,
        XORI,
        LDI,
        LDA,
        LDO,
        STA,
        PUSH,
        POP
    );

    type funct is
    (
        ADD,
        SUB,
        ANDG,
        ORG,
        NOTG,
        XORG,
        LSL,
        LSR,
        ADDC,
        SUBC,
        SETC,
        CLRC,
        SETV,
        CLRV,
        MOV,
        IJMP,
        INC
    );
    
    type operands is
    (
        --your operands go here...
        Rd,
        Rs,
        Rt,
        Immediate16,
        Immediate2,
        Immediate8
    );

    type formats is
    (
        --your instruction formats go here...
        register_format,
        branch_format,
        immediate_format
    );

--==========================================================--
--FUNCTIONS                                                 --
--==========================================================--

    ---- FORMAT CHECK FUNCTIONS ----
    -- these functions determine which instructions are in which format
    -- these functions must be synthesisable as they will be used in control unit logic

    --register format check
    function RFormatCheck (op: in opcodes) return std_logic;

    --branch format check
    function BFormatCheck (op: in opcodes) return std_logic;

    --addressing format check
    function IFormatCheck (op: in opcodes) return std_logic;
    
    ---- HELPER FUNCTIONS, DO NOT EDIT THESE ----
    --get operand function
    -- gets just the operand from a given standard logic vector
    -- as this forms connections between modules, there should be no decision logic here
    function GetOperand (slv: in std_logic_vector; instruction_format: in formats; operand: in operands) return std_logic_vector;
    
    --convert from binary (std_logic_vector) to opcode
    -- convert binary to integer and use it to index opcodes table
    function slv2op (slv: in std_logic_vector) return opcodes;
    
    --convert from opcode to binary (std_logic_vector)
    -- get the index of the given opcode and convert to binary
    function op2slv (op: in opcodes) return std_logic_vector;

    --convert from funct to binary
    function funct2slv (fnct: in funct) return std_logic_vector;

    --convert from binary to funct
    function slv2funct (slv: in std_logic_vector) return funct;
end package pomegranate_inst_conf;


--definition of package declarations
package body pomegranate_inst_conf is
--==========================================================--
--VARIABLES                                                 --
--==========================================================--

    --operand width table
    type t_operand_width is array (operands) of NATURAL;
    constant operand_width: t_operand_width := (
        Raddr_w, Raddr_w, Raddr_w, 16, 2, 8
    );

    --operand MSB index table
    -- a 2D array with a row for each instruction format
    -- each row contains the index of the MSB of the operands in the corresponding format
    type t_operand_table is array (formats, operands) of NATURAL;
    constant operand_table: t_operand_table := (
        (17, 13, 9, 0, 0, 0), --register format
        (0, 0, 0, 15, 0, 0),  --branch format
        (17, 13, 0, 0, 9, 7)  --immediate format
    );

--==========================================================--
--FUNCTIONS                                                 --
--==========================================================--

    ---- FORMAT CHECK FUNCTIONS ----
    -- these functions determine which instructions are in which format
    -- these functions must be synthesisable as they will be used in control unit logic

    --register format check
    function RFormatCheck (op: in opcodes) return std_logic is
    begin
        case op2slv(op) is
            --this format contains just instructions with an opcode of "0000"
            when "000000" => --replace the binary here
                return '1';
            when others =>
                return '0';
        end case;
    end function RFormatCheck;

    --branch format check
    function BFormatCheck (op: in opcodes) return std_logic is
    begin
        case op2slv(op) is
            --opcodes in this format are as follows: NOP, CALL, RET, JMP, BRZ, BRN, BRP, BRC, BRV, HLT
            when "000001" | "000010" | "000011" | "000100" | "000101" | "000110" | "000111" | "001000" | "001001" | "001010" =>
                return '1';
            when others =>
                return '0';
        end case;
    end function BFormatCheck;

    --addressing format check
    function IFormatCheck (op: in opcodes) return std_logic is
    begin
        case op2slv(op) is
            --opcodes in this format are as follows: ADDI, SUBI, ANDI, ORI, XORI, LDI, LDA, LDO, LDN, STA, STO, STN, PUSH, POP
            when "001011" | "001100" | "001101" | "001110" | "001111" | "010000" | "010001" | "010010" | "010011" | "010100" | "010101" | "010110" | "010111" | "011000" =>
                return '1';
            when others =>
                return '0';
        end case;
    end function IFormatCheck;
    
    ---- HELPER FUNCTIONS, DO NOT EDIT THESE ----
    --get operand function
    -- gets just the operand from a given standard logic vector
    -- as this forms connections between modules, there should be no decision logic here
    function GetOperand (slv: in std_logic_vector; instruction_format: in formats; operand: in operands) return std_logic_vector is
        variable operand_index: natural;
    begin
        operand_index := operand_table(instruction_format, operand);
        return slv(operand_table(instruction_format, operand) downto operand_table(instruction_format, operand)-(operand_width(operand)-1));
    end function GetOperand;

    --convert from binary (std_logic_vector) to opcode
    -- convert binary to integer and use it to index opcodes table
    function slv2op (slv: in std_logic_vector) return opcodes is
    begin
        return opcodes'val(to_integer(unsigned(slv)));
    end function slv2op;

    --convert from opcode to binary (std_logic_vector)
    -- get the index of the given opcode and convert to binary
    function op2slv (op : in opcodes) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(opcodes'pos(op), op_w));
    end function op2slv;

    --convert from funct to binary
    function funct2slv (fnct: in funct) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(funct'pos(fnct), 5));
    end function funct2slv;

    --convert from binary to funct
    function slv2funct (slv: in std_logic_vector) return funct is
    begin
        return funct'val(to_integer(unsigned(slv)));
    end function slv2funct;
end package body pomegranate_inst_conf;