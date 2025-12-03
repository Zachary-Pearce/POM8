"""pom8_assembler.py

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
from dataclasses import dataclass, field
from typing import Dict
from enum import Enum
import re
import sys
import argparse

class Format(Enum):
    """
    An enumeration of possible instruction formats.
    
    Members:
        REGISTER_FORMAT
        BRANCH_FORMAT
        IMMEDIATE_FORMAT
    """
    REGISTER_FORMAT = 1
    BRANCH_FORMAT = 2
    IMMEDIATE_FORMAT = 3

OPCODE = {
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

FORMATS = {
    Format.REGISTER_FORMAT: ["MNEMONIC", "REGISTER", "REGISTER", "REGISTER"],
    Format.BRANCH_FORMAT: ["MNEMONIC", "HEXADECIMAL/MNEMONIC"],
    Format.IMMEDIATE_FORMAT: ["MNEMONIC", "REGISTER", "REGISTER/DECIMAL/HEXADECIMAL/BINARY", "DECIMAL/HEXADECIMAL/BINARY"]
}

@dataclass
class Line:
    index: int
    tokens: list[Token] = field(default_factory=list)
    format: Format = Format.REGISTER_FORMAT

    def __repr__(self) -> str:
        """String representation of the Line object."""
        return f"Line(index={self.index}, tokens='{self.tokens}', format='{Format.REGISTER_FORMAT.name}')"

@dataclass
class Program:
    file_name: str
    labels: Dict[str, int] = field(default_factory=lambda: dict())
    lines: list[Line] = field(default_factory=list)
    machine_code: list[str] = field(default_factory=list)

def read_file(file_name: str) -> str:
    """
    Helper function to read an assembly text file and return the contents.

    Parameters:
        asm_file_name (str): the name of the text file to read from.

    Returns:
        asm (str): the assembly code read from the file
    """
    asm: str = []
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

def tokenise(program: Program) -> None:
    """
    tokenise the lines of assembly and store them.

    Parameters:
        program (Program): The assembly program.
    """
    asm = read_file(program.file_name)
    asm_lines = re.split("\n", asm)
    try:
        for line in asm_lines:
            line_index = asm_lines.index(line)
            program.lines.append(Line(line_index))
            if line != "": #ignore empty lines
                line_items = re.split(" |\t|, ", line)
                for item in line_items:
                    if item != "": #prevent spaces from causing trouble
                        token = Token(item, line_index+1)
                        if token.type != TokenType.COMMENT:
                            if token.type == TokenType.LABEL:
                                label = token.text[:-1] #don't include the colon in label text
                                _label_semantics(program, label, line_index)
                            else: #we add labels to the symbol table rather than adding them to the token list
                                program.lines[line_index].tokens.append(token)
                        else:
                            break #everything after a comment (;) is ignored
    except Exception as ex:
        print(ex)
        print("An error has occurred! Aborting...")
        sys.exit()

def _label_semantics(program: Program, label: str, line_index: int) -> None:
    """
    Semantically analyse found labels, store them in a dictionary if valid.

    Parameters:
        program (Program): The assembly program.
        label (str): The label to analyse.
        line_index (int): The index of the current line.

    Raises:
        SyntaxError: If there is a duplicate label.
    """
    if label in program.labels:
        raise SyntaxError(
            f"line {line_index+1}: '{label}' label already exists!"
        )

    program.labels[label] = line_index

def _get_line_format(program: Program, line_index: int) -> None:
    """
    Gets the instruction format relating to a line of assembly.

    Parameters:
        program (Program): The assembly program.
        line_index (int): The index of the line.
    
    Returns:
        format (Format): The lines format as a Format member.

    Raises:
        SyntaxError: If the given mnemonic is not valid.
    """
    line = program.lines[line_index]
    #the first element will be an opcode mnemonic
    opcode_mnemonic = line.tokens[0].text.upper()
    if opcode_mnemonic not in OPCODE:
        line.format = Format.REGISTER_FORMAT
    elif (opcode_mnemonic == "NOP"
            or opcode_mnemonic == "CALL"
            or opcode_mnemonic == "RET"
            or opcode_mnemonic == "JMP"
            or opcode_mnemonic == "BRZ"
            or opcode_mnemonic == "BRN"
            or opcode_mnemonic == "BRP"
            or opcode_mnemonic == "BRC"
            or opcode_mnemonic == "BRV"):
        line.format = Format.BRANCH_FORMAT
    elif (opcode_mnemonic == "ADDI"
            or opcode_mnemonic == "SUBI"
            or opcode_mnemonic == "ANDI"
            or opcode_mnemonic == "ORI"
            or opcode_mnemonic == "XORI"
            or opcode_mnemonic == "LDI"
            or opcode_mnemonic == "LDA"
            or opcode_mnemonic == "LDO"
            or opcode_mnemonic == "STA"
            or opcode_mnemonic == "PUSH"
            or opcode_mnemonic == "POP"):
        line.format = Format.IMMEDIATE_FORMAT
    else:
        raise SyntaxError (
            f"Line {line_index+1}: '{opcode_mnemonic}' is not a valid MNEMONIC!"
        )

def _check_symbols(program: Program, token: Token, line_num: int) -> None:
    """
    Check for unexpected symbols in operands.

    Parameters:
        token (Token): The token to check.
        line_num (int): The token's line number.

    Raises:
        SyntaxError: If there are unexpected symbols.
    """
    token_type = token.type

    match token_type:
        case TokenType.MNEMONIC:
            mnemonic = token.text
            if mnemonic not in program.labels:
                raise SyntaxError (
                    f"Line {line_num}: '{mnemonic}' is not a valid {token_type.name}!"
                )

def _check_overflow(token: Token, line_num: int) -> None:
    """
    Check that all inputs are within range.

    Parameters:
        token (Token): The token to check.
        line_num (int): The token's line number.
    
    Raises:
        OverflowError: If any input is out of range.
    """
    token_type = token.type

    match token_type:
        case TokenType.REGISTER:
            reg_num = token.text[1:]
            if int(reg_num, 10) > 15:
                raise OverflowError(
                    f"Line {line_num}: {token_type.name} index '{reg_num}' out of range, expected range 0-15"
                )
        case TokenType.HEXADECIMAL:
            _hex = token.text[2:]
            if len(_hex) > 3 or not _hex[0].isdigit() or int(_hex[0], 10) > 3:
                raise OverflowError(
                    f"Line {line_num}: {token_type.name} '{_hex}' out of range, expected range 0x000-0x3FF"
                )
        case TokenType.DECIMAL:
            dec_num = token.text
            if dec_num.startswith("-"):
                if int(dec_num, 10) < -128:
                    raise OverflowError(
                        f"Line {line_num}: {token_type.name} word '{dec_num}' out of range, expected range -128-127"
                    )
            elif int(dec_num, 10) > 255:
                raise OverflowError(
                    f"Line {line_num}: {token_type.name} word '{dec_num}' out of range, expected range 0-255"
                )
        case TokenType.BINARY:
            _bin = token.text[2:]
            if len(_bin) > 8:
                raise OverflowError(
                    f"Line {line_num}: {token_type.name} word '{_bin}' out of range, expected 8-bit number"
                )

def first_pass(program: Program) -> None:
    """
    The first pass over the tokenised stream, performing the following:
        Symbol table creation
        Syntax analysis
        Semantic analysis

    Raises:
        SyntaxError: If there is an unexpected token.
    """
    try:
        for line in program.lines:
            line_index = program.lines.index(line)
            #get the format of the line
            _get_line_format(program, line_index)
        
            #now we can loop through the remaining tokens on the line
            # we don't need to worry about opcodes that require no arguments
            tokens = line.tokens
            if len(tokens) > 1:
                expected_tokens = FORMATS[line.format]
                for i in range(1, len(tokens)): #skip first token as we have already checked this
                    if tokens[i].type.name in expected_tokens[i]:
                        _check_symbols(program, tokens[i], line_index+1)
                        _check_overflow(tokens[i], line_index+1)
                    else:
                        raise SyntaxError(
                            f"Line {line_index+1}: Unexpected token '{tokens[i].type}', expected '{expected_tokens[i]}'"
                        )
    except Exception as ex:
       print(ex)
       print("An error has occurred! Aborting...")
       sys.exit()

def second_pass(program: Program) -> None:
    """
    Assemble tokenised and syntax checked assembly code.
    """
    for line in program.lines:
        machine_code_line = ""
        tokens = line.tokens
        mnemonic = tokens[0].text.upper()

        if line.format == Format.REGISTER_FORMAT:
            Rd = 0
            Rs = 0
            Rt = 0
            Funct = FUNCT[mnemonic]
            
            # convert registers
            if mnemonic == "IJMP":
                #IJMP is the only instruction that does not follow the Rd, Rs, Rt order
                Rs = int(line[1].text[1:], 10)
                Rt = int(line[2].text[1:], 10)
            elif (mnemonic != "SETC"
                    or mnemonic != "CLRC"
                    or mnemonic != "SETV"
                    or mnemonic != "CLRV"):
                #all other instructions with inputs follow the order
                registers = [0, 0, 0]
                for x in range(1,len(tokens)):
                    registers[x-1] = int(tokens[x].text[1:], 10)
                
                Rd = registers[0]
                Rs = registers[1]
                Rt = registers[2]

            machine_code_line = ("000000"
                                    + f"{Rd:04b}"
                                    + f"{Rs:04b}"
                                    + f"{Rt:04b}"
                                    + Funct)
        elif line.format == Format.BRANCH_FORMAT:
            opcode = OPCODE[mnemonic]
            
            #is it a label or a hex input
            immediate = "0000000000000000"
            if len(tokens) > 1:
                if tokens[1].text in program.labels:
                    immediate = f"{program.labels[tokens[1].text]:016b}"
                else:
                    _hex = tokens[1].text[2:]
                    decimal = int(_hex, 16)
                    immediate = f"{decimal:016b}"
            
            machine_code_line = (opcode
                                    + "00"
                                    + immediate)
        elif line.format == Format.IMMEDIATE_FORMAT:
            opcode = OPCODE[mnemonic]
            immediate = "0000000000"
            Rd = 0
            Rs = 0

            #STA and PUSH do not follow the Rd, Rs, Rt order
            if (mnemonic == "STA"
                or mnemonic == "PUSH"):
                Rs = int(tokens[1].text[1:], 10)
            else:
                #all other instructions follow the order
                registers = [0, 0]
                for x in range(1,len(tokens)-1):
                    registers[x-1] = int(tokens[x].text[1:], 10)
                
                Rd = registers[0]
                Rs = registers[0]

            #immediate comes after the registers
            #so use x+1 to index where x is the index of the last register
            if x+1 < len(tokens): #some instructions do not contain immediates
                if tokens[x+1].type == TokenType.HEXADECIMAL:
                    _hex = tokens[x+1].text[2:]
                    decimal = int(_hex, 16)
                elif tokens[x+1].type == TokenType.BINARY:
                    _bin = tokens[x+1].text[2:]
                    decimal = int(_bin, 2)
                else: #if the input is a decimal
                    decimal = int(tokens[x+1].text, 10)
                
                if tokens[x+1].text.startswith("-"):
                    immediate = "00" + bin((1 << 8) + decimal)[2:]
                else:
                    immediate = f"{decimal:010b}"

            machine_code_line = (opcode
                                    + f"{Rd:04b}"
                                    + f"{Rs:04b}"
                                    + immediate)

        program.machine_code.append(machine_code_line)

def main() -> None:
    help_msg = "Convert a POM8 assembly file into machine code."
    parser = argparse.ArgumentParser(description=help_msg)

    parser.add_argument("Input", type=str, help="the input assembly (.asm) file name")
    parser.add_argument("-o", "--Output", help="optional output binary file name")

    #read input argumnets
    args = parser.parse_args()

    #convert the input file
    asm_file_name = args.Input
    program = Program(asm_file_name)
    tokenise(program)
    first_pass(program)
    second_pass(program)

    machine_code = program.machine_code
    if args.Output:
        #if an output was provided
        bin_file_name = args.Output
        write_file(bin_file_name, machine_code)
    else:
        for line in machine_code:
            print(line)

if __name__ == "__main__":
    main()