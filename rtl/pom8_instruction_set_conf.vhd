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
    ------ VARIABLES ------
    
    constant word_w: NATURAL := 8; --the width of the data bus
    constant instruction_w: NATURAL := 32; --the width of instructions
    constant op_w: NATURAL := 4;    --the number of bits reserved for the opcode in instructions
    constant Raddr_w: NATURAL := 4; --the number of bits reserved for register addresses
    constant Maddr_w: NATURAL := 16; --the number of bits reserved for memory addresses
    constant Iaddr_w: NATURAL := 8; --the number of bits reserved for instruction addresses
    
    --opcode mnemonics
    type opcode is
    (
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
        LDR,
        LDW,
        LDI,
        STR,
        STW,
        STI
    );
    
    --funct mnemonics
    type funct is
    (
        ADD,
        SUB,
        ANDG,
        ORG,
        NOTG,
        XORG,
        ADDI,
        SUBI,
        ANDI,
        ORI,
        XORI,
        LSL,
        LSR,
        ADDC,
        SUBC,
        PUSH,
        POP,
        SETC,
        CLRC,
        SETV,
        CLRV
    );
    
    --operands
    type operands is
    (
        Rd,
        Rs,
        Rt,
        Immediate1,
        Immediate2,
        Mode
    );
    
    --instruction formats
    type formats is
    (
        register_format,
        branch_format,
        addressing_format
    );

    --INSTRUCTION FORMAT CHECK FUNCTIONS

    -- register format check
    function RFormatCheck (op: in opcode) return std_logic;

    -- branch format check
    function BFormatCheck (op: in opcode) return std_logic;

    -- address format check
    function AFormatCheck (op: in opcode) return std_logic;

    --OPCODE FUNCTIONS
    
    -- address index function
    function AddressIndex (instruction_format: in formats := branch_format; operand: in operands := Rs) return NATURAL;
    
    -- convert from standard logic vector to opcode mnemonic
    function slv2op (slv: in std_logic_vector) return opcode;
    
    -- convert from opcode mnemonic to standard logic vector
    function op2slv (op: in opcode) return std_logic_vector;
    
    -- convert from funct mnemonic to standard logic vector
    function funct2slv (fnct: in funct) return std_logic_vector;
    
    -- convert from standard logic vector to funct mnemonic
    function slv2funct (slv: in std_logic_vector) return funct;
end package pomegranate_inst_conf;


--definition of package declarations
package body pomegranate_inst_conf is
    ------ VARIABLES ------
    
    --the array used to translate a standard logic vector to it's respective opcode mnemonic
    type opcode_table is array (opcode) of std_logic_vector(op_w-1 downto 0);
    constant trans_table: opcode_table := (
        "0000",
        "0001",
        "0010",
        "0011",
        "0100",
        "0101",
        "0110",
        "0111",
        "1000",
        "1001",
        "1010",
        "1011",
        "1100",
        "1101",
        "1110",
        "1111"
    );
    
    type funct_table is array (funct) of std_logic_vector(4 downto 0);
    constant functrans_table: funct_table := (
        "00000",
        "00001",
        "00010",
        "00011",
        "00100",
        "00101",
        "00110",
        "00111",
        "01000",
        "01001",
        "01010",
        "01011",
        "01100",
        "01101",
        "01110",
        "01111",
        "10000",
        "10001",
        "10010",
        "10011",
        "10100"
    );
    
    --operand MSB index table
    type operand_table is array (operands) of natural;
    -- register format
    constant register_table: operand_table := (
        11, 27, 23, 0, 7, 0
    );
    -- branch format
    constant branch_table: operand_table := (
        0, 27, 0, 19, 7, 11
    );
    -- load format
    constant address_table: operand_table := (
        11, 27, 23, 19, 7, 0
    );

    -- register format check
    function RFormatCheck (op: in opcode) return std_logic is
    begin
        case op2slv(op) is
            --this format contains just instructions with an opcode of "0000"
            when "0000" =>
                --return '1' to specify we are in the register format
                return '1';
            when others =>
                --otherwise we return '0'
                return '0';
        end case;
    end function RFormatCheck;
    -- branch format check
    function BFormatCheck (op: in opcode) return std_logic is
    begin
        case op2slv(op) is
            --opcodes in this format are as follows: NOP, CALL, RET, JMP, BRZ, BRN, BRP, BRC, BRV
            when "0001" | "0010" | "0011" | "0100" | "0101" | "0110" | "0111" | "1000" | "1001" =>
                --return '1' to indicate we are in the branch format
                return '1';
            when others =>
                --otherwise return '0'
                return '0';
        end case;
    end function BFormatCheck;
    -- addressing format check
    function AFormatCheck (op: in opcode) return std_logic is
    begin
        case op2slv(op) is
            --opcodes in this format are as follows: LDR, LDW, LDI, STR, STW, STI
            when "1010" | "1011" | "1100" | "1101" | "1110" | "1111" =>
                --return '1' to indicate we are in the load format
                return '1';
            when others =>
                --otherwise return '0'
                return '0';
        end case;
    end function AFormatCheck;
        
        
    ---- OPCODE FUNCTIONS ----
     
    -- address index return function
    function AddressIndex (instruction_format: in formats := branch_format; operand: in operands := Rs) return NATURAL is
    begin
        --check which instruction format the opcode is in
        -- then return the index of the MSB of the target operand
        case instruction_format is
            when register_format =>
                return register_table(operand);
            when branch_format =>
                return branch_table(operand);
            when addressing_format =>
                return address_table(operand);
        end case;
        report "format not found!" severity error;
        return word_w; --on a fail to fulfill conditions return the word width
    end function AddressIndex;
    
    -- convert from binary (std_logic_vector) to opcode
    function slv2op (slv: in std_logic_vector) return opcode is
        variable transop: opcode;
    begin
        --this is the way that makes the most sense, however some synthesis tools don't support it.
        --  the other method would be to use a case statement but it is harder to edit the instruction set.
        for i in opcode loop
            if slv = trans_table(i) then
                transop := i;
            end if;
        end loop;
        return transop;
    end function slv2op;

    -- convert from opcode to binary (std_logic_vector)
    function op2slv (op : in opcode) return std_logic_vector is
    begin
        return trans_table(op);
    end function op2slv;
    
    --convert from funct to binary (std_logic_vector)
    function funct2slv (fnct: in funct) return std_logic_vector is
    begin
        return functrans_table(fnct);
    end function funct2slv;
    
    --convert from binary (std_logic_vector) to funct
    function slv2funct (slv: in std_logic_vector) return funct is
        variable transfnct: funct;
    begin
        for i in funct loop
            if slv = functrans_table(i) then
                transfnct := i;
            end if;
        end loop;
        return transfnct;
    end function slv2funct;
end package body pomegranate_inst_conf;
