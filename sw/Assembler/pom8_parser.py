"""
pom8_parser.py

This module defines the POM8 assembly language parser which converts
tokens into an abstract syntax tree (AST).

Author: Zachary Pearce
Contributors: 
License: GPL-3.0
"""

from pom8_token import *
from dataclasses import dataclass
from typing import Callable, Dict
from enum import Enum

import logging
import logger_conf

logger = logging.getLogger(__name__)

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

FORMATS = {
    Format.REGISTER_FORMAT: ["ADD", "SUB", "AND", "OR", "NOT", "XOR",
                             "LSL", "LSR", "ADDC", "SUBC", "SETC", "CLRC",
                             "SETV", "CLRV", "MOV", "IJMP", "INC"],

    Format.BRANCH_FORMAT: ["NOP", "CALL", "RET", "JMP", "BRZ", "BRN",
                           "BRP", "BRC", "BRV", "HLT"],

    Format.IMMEDIATE_FORMAT: ["ADDI", "SUBI", "ANDI", "ORI", "XORI",
                              "LDI", "LDA", "LDO", "STA", "PUSH", "POP"]
}

symbol_table: Dict[str, int] = dict()

class ASTNode:
    """Base class for all AST nodes."""
    pass

    def validate(self) -> bool:
        """Validate the AST node."""
        ...

#operand classes
class RegisterOperand(ASTNode):
    """
    register operand node.

    Attributes:
        token (Token): The token representing the register.
        register_num (int): The integer value of the register number.
    """
    def __init__(self, token: Token, value: str) -> None:
        self.token = token
        self.register_num = int(value[1:], 10)

    def validate(self) -> bool:
        """
        Validate the RegisterOperand node.

        Returns:
            valid (bool): is the register number within range (0-15).
        """
        return self.register_num <= 15

    def __repr__(self) -> str:
        """String representation of the RegisterOperand object."""
        return f"RegisterOperand(token={self.token}, register_num={self.register_num})"

class ImmediateOperand(ASTNode):
    """
    Immediate operand node.

    Attributes:
        token (Token): The token representing the immediate value.
        value (int): The integer value of the immediate operand.
    """
    def __init__(self, token: Token, value: str) -> None:
        self.token = token
        self.value = int(value, 0)

    def validate(self) -> bool:
        """
        Validate the ImmediateOperand node.

        Returns:
            valid (bool): is the immediate value valid for its type.
        """
        match self.token.type:
            case TokenType.HEXADECIMAL:
                return self.value <= 0x3FF
            case TokenType.DECIMAL:
                if self.value < 0:
                    return self.value >= -128
                else:
                    return self.value <= 255
            case TokenType.BINARY:
                return self.value <= 255

    def __repr__(self) -> str:
        """String representation of the ImmediateOperand object."""
        return f"ImmediateOperand(token={self.token}, value={self.value})"

class LabelOperand(ASTNode):
    """
    Label operand node.

    Attributes:
        token (Token): The token representing the label.
        name (str): The name of the label.
    """
    def __init__(self, token: Token, name: str) -> None:
        self.token = token
        self.name = name
    
    def validate(self) -> bool:
        """
        Validate the LabelOperand node.
        
        Returns:
            valid (bool): true if the label exists in the symbol table.
        """
        return self.name in symbol_table
    
    def __repr__(self) -> str:
        """String representation of the LabelOperand object."""
        return f"LabelOperand(token={self.token}, name='{self.name}')"

OperandFactory = Callable[[Token, str], 'ASTNode']

OPERANDS: Dict[TokenType, OperandFactory] = {
    TokenType.REGISTER: RegisterOperand,
    TokenType.HEXADECIMAL: ImmediateOperand,
    TokenType.DECIMAL: ImmediateOperand,
    TokenType.BINARY: ImmediateOperand,
    TokenType.MNEMONIC: LabelOperand
}

@dataclass
class Instruction(ASTNode):
    """Instruction node with mnemonic and operands."""
    opcode_mnemonic: str
    operands: list[ASTNode]
    inst_format: Format

@dataclass
class Program(ASTNode):
    """The root program node containing all instructions."""
    instructions: list[Instruction]

class Parser:
    """Recursive descent parser for POM8 assembly language."""
    def __init__(self, tokens: list[Token]) -> None:
        self._tokens = tokens
        self._pos = 0
    
    @property
    def current_token(self) -> Token | None:
        """Get the current token without advancing."""
        if self._pos < len(self._tokens):
            return self._tokens[self._pos]
        return None
    
    def peek_ahead(self, offset: int = 1) -> Token | None:
        """Peak ahead at the next token without advancing."""
        pos = self._pos + offset
        if pos < len(self._tokens):
            return self._tokens[pos]
        return None
    
    def advance(self) -> Token | None:
        """Return the current token and advance."""
        token = self.current_token
        self._pos += 1
        return token
    
    def parse_operands(self, mnemonic: str, inst_format: Format) -> list[ASTNode]:
        """Parse operands based on instruction format."""
        operands = []
        expected_types : list[str] = []
        if mnemonic in ["NOP", "HLT", "RET", "SETC", "CLRC", "SETV", "CLRV"]:
            token = self.advance() #consume newline
            return operands #no operands
        elif inst_format == Format.BRANCH_FORMAT:
            expected_types = [ f"{TokenType.MNEMONIC.name}/"+
                              f"{TokenType.HEXADECIMAL.name}" ]
        elif inst_format == Format.IMMEDIATE_FORMAT:
            if (self.peek_ahead(1).type in [TokenType.DECIMAL,
                                            TokenType.HEXADECIMAL,
                                            TokenType.BINARY]):
                expected_types = [ f"{TokenType.REGISTER.name}",
                                  f"{TokenType.DECIMAL.name}/"+
                                  f"{TokenType.HEXADECIMAL.name}/"+
                                  f"{TokenType.BINARY.name}" ]
            else:
                expected_types = [ f"{TokenType.REGISTER.name}",
                                  f"{TokenType.REGISTER.name}",
                                  f"{TokenType.DECIMAL.name}/"+
                                  f"{TokenType.HEXADECIMAL.name}/"+
                                  f"{TokenType.BINARY.name}" ]
        elif inst_format == Format.REGISTER_FORMAT:
            if mnemonic in ["LSL", "LSR", "MOV", "IJMP"]:
                expected_types = [ f"{TokenType.REGISTER.name}",
                                  f"{TokenType.REGISTER.name}" ]
            else:
                expected_types = [ f"{TokenType.REGISTER.name}",
                                  f"{TokenType.REGISTER.name}",
                                  f"{TokenType.REGISTER.name}" ]
        
        token = self.current_token
        for expected in expected_types:
            token = self.advance()
            if token.type.name not in expected:
                raise SyntaxError(
                    f"line {token.line_num}: Expected operand of type {expected}, got {token.type.name}"
                )
            
            operand_class = OPERANDS[token.type]
            new_operand = operand_class(token, token.text)
            if new_operand.validate() is False:
                raise SyntaxError(
                    f"line {token.line_num}: Invalid value {token.text} for operand of type {token.type.name}"
                )
            logger.info(f"Line {self.current_token.line_num}: Created {new_operand.__repr__()}")
            operands.append(new_operand)
        token = self.advance() #consume newline

        return operands

    def parse_intruction(self) -> Instruction:
        """Parse a single instruction and return the AST node."""
        token = self.advance()
        if token.type != TokenType.MNEMONIC:
            raise SyntaxError(
                f"line {token.line_num}: Expected mnemonic, got {token.type}"
            )
        mnemonic = token.text.upper()
        inst_format = None
        for fmt, mnemonics in FORMATS.items():
            if mnemonic in mnemonics:
                inst_format = fmt
                break
        if inst_format is None:
            raise SyntaxError(
                f"line {token.line_num}: Unknown opcode '{mnemonic}'"
            )

        operands = self.parse_operands(mnemonic, inst_format)

        return Instruction(
            opcode_mnemonic=mnemonic,
            operands=operands,
            inst_format=inst_format
        )
    
    def parse_program(self) -> Program:
        """Parse the entire program and return the AST."""
        instructions = []
        while self.current_token is not None:
            instruction = self.parse_intruction()
            instructions.append(instruction)
            logger.debug(f"Parsed {instruction.inst_format.name} instruction.\n")
        return Program(instructions)