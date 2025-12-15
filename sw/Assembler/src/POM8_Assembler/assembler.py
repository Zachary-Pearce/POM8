"""
pom8_assembler.py

This module provides the operations required to perform syntax analysis and
assemble any POM8 mnemonics.

Author: Zachary Pearce
Contributors: 
License: GPL-3.0

Classes:
    Line: A dataclass modelling the data related to each assembly line
    Program: A dataclass modelling the data related to a program
"""

from pom8_token import *
from parser import *
import re

import logging
from logger_conf import *

logger = logging.getLogger(__name__)

__all__ = ["read_file", "write_file", "tokenise", "second_pass"]

_OPCODE = {
    "NOP": "000001",
    "CALL": "000010",
    "RET": "000011",
    "JMP": "000100",
    "BRZ": "000101",
    "BRN": "000110",
    "BRP": "000111",
    "BRC": "001000",
    "BRV": "001001",
    "HLT": "001010",
    "ADDI": "001011",
    "SUBI": "001100",
    "ANDI": "001101",
    "ORI": "001110",
    "XORI": "001111",
    "LDI": "010000",
    "LDA": "010001",
    "LDO": "010010",
    "STA": "010011",
    "PUSH": "010100",
    "POP": "010101"
}

FUNCT = {
    "ADD": "000000",
    "SUB": "000001",
    "AND": "000010",
    "OR": "000011",
    "NOT": "000100",
    "XOR": "000101",
    "LSL": "000110",
    "LSR": "000111",
    "ADDC": "001000",
    "SUBC": "001001",
    "SETC": "001010",
    "CLRC": "001011",
    "SETV": "001100",
    "CLRV": "001101",
    "MOV": "001110",
    "IJMP": "001111",
    "INC": "010000"
}

def read_file(file_name: str) -> str:
    """
    Helper function to read an assembly text file and return the contents.

    Parameters:
        asm_file_name (str): the name of the text file to read from.

    Returns:
        asm (str): the assembly code read from the file
    """
    asm: str = ""
    with open(file_name, "r") as f:
        f.seek(0)
        asm = f.read()

    return asm

def write_file(file_name: str, machine_code: list[str]) -> None:
    """
    Helper function to write machine code to a file.

    Parameters:
        bin_file_name (str): The name of the file to write to.
        machine_code (list[str]): The machine code to write.
    """
    with open(file_name, "w") as f:
        f.seek(0)
        for line in machine_code:
            f.write(line + "\n")

def tokenise(file_name: str) -> list[Token]:
    """
    tokenise the lines of assembly and store them.

    Parameters:
        program (Program): The assembly program.
    """
    tokens: list[Token] = []
    asm = read_file(file_name)
    asm_lines = re.split("\n", asm)
    address = 0 #keep track of address separately to line number
    for line_index, line in enumerate(asm_lines):
        if not line.strip() or line.strip().startswith(";"):
            continue #skip empty lines or lines with only comments

        # split line into items based on commas and/or whitespace
        line_items = re.split(r"[,][ ]*|[ \t]+", line.strip())
        for item in line_items:
            token = Token(item, line_index+1)
            if token.type == TokenType.COMMENT:
                break #everything after a comment (;) is ignored
            elif token.type == TokenType.LABEL:
                label = token.text[:-1] #strip colon from label text
                if label in symbol_table:
                    raise SyntaxError(
                        f"line {line_index+1}: '{label}' label already exists!"
                    )
                symbol_table[label] = address
                logger.info(f"Line {line_index+1}: label ({label}) created for address {hex(address)}")
            else:
                tokens.append(token)
            
        address += 1
        tokens.append(Token("\n", line_index+1))
    
    return tokens

def second_pass(ast: Program) -> list[str]:
    """
    Assemble tokenised and syntax checked assembly code.
    """
    machine_code = []
    for instruction in ast.instructions:
        mnemonic = instruction.opcode_mnemonic
        machine_code_line = ""
        Rd = Rs = Rt = 0

        if instruction.inst_format == Format.REGISTER_FORMAT:
            Funct = FUNCT[mnemonic]

            if mnemonic == "IJMP":
                #IJMP is the only instruction that does not follow the Rd, Rs, Rt order
                Rs = instruction.operands[0].reigster_num
                Rt = instruction.operands[1].register_num
            else:
                registers = [0, 0, 0]
                for x, operand in enumerate(instruction.operands):
                    registers[x] = operand.register_num
                Rd, Rs, Rt = registers
            
            machine_code_line = ("000000"
                                    + f"{Rd:04b}"
                                    + f"{Rs:04b}"
                                    + f"{Rt:04b}"
                                    + Funct)
        elif instruction.inst_format == Format.BRANCH_FORMAT:
            opcode = _OPCODE[mnemonic]

            #is it a label or a hex input
            address = 0
            if len(instruction.operands) >= 1:
                operand = instruction.operands[0]
                if isinstance(operand, LabelOperand):
                    address = symbol_table[operand.name]
                else:
                    address = operand.value
            
            machine_code_line = (opcode
                                    + "00"
                                    + f"{address:016b}")
        elif instruction.inst_format == Format.IMMEDIATE_FORMAT:
            opcode = _OPCODE[mnemonic]
            immediate = "0000000000"

            registers = [0, 0]
            imm_op: ASTNode = ASTNode()
            for x, op in enumerate(instruction.operands):
                if isinstance(op, RegisterOperand):
                    registers[x] = op.register_num
                else: #immediate operand
                    imm_op = op

            #STA and PUSH do not follow the Rd, Rs, Rt order
            if (mnemonic == "STA"
                or mnemonic == "PUSH"):
                Rs = registers[0]
            else:
                Rd, Rs = registers
            
            if isinstance(imm_op, ImmediateOperand):
                decimal = imm_op.value
                if decimal < 0:
                    immediate = "00" + bin((1 << 8) + decimal)[2:]
                else:
                    immediate = f"{decimal:010b}"

            machine_code_line = (opcode
                                    + f"{Rd:04b}"
                                    + f"{Rs:04b}"
                                    + immediate)

        machine_code.append(machine_code_line)
    
    return machine_code