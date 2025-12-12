from parser import *
from pom8_token import *

import pytest

def test_parser() -> None:
    """Test the parser by providing a token stream and comparing against a known good output"""
    #input token stream and symbol table
    symbol_table["start"] = 2
    token_stream: list[Token] = [
        Token("LDI", 1), Token("r15", 1), Token("0b11111111", 1), Token("\n", 1),
        Token("STA", 2), Token("r0", 2), Token("0x000", 2), Token("\n", 2),
        Token("ADD", 3), Token("r0", 3), Token("r6", 3), Token("r15", 3), Token("\n", 3),
        Token("JMP", 4), Token("start", 4), Token("\n", 4)
    ]
    expected_instructions: list[Instruction] = [
        Instruction("LDI", [ RegisterOperand(token_stream[1], "r15"), ImmediateOperand(token_stream[2], "0b11111111") ], Format.IMMEDIATE_FORMAT),
        Instruction("STA", [ RegisterOperand(token_stream[5], "r0"), ImmediateOperand(token_stream[6], "0x000") ], Format.IMMEDIATE_FORMAT),
        Instruction("ADD", [ RegisterOperand(token_stream[9], "r0"), RegisterOperand(token_stream[10], "r6"), RegisterOperand(token_stream[11], "r15") ], Format.REGISTER_FORMAT),
        Instruction("JMP", [ LabelOperand(token_stream[14], "start") ], Format.BRANCH_FORMAT)
    ]

    parser = Parser(token_stream)
    ast = parser.parse_program()

    for index, instruction in enumerate(ast.instructions):
        assert ( instruction.opcode_mnemonic == expected_instructions[index].opcode_mnemonic and
                instruction.operands.__repr__() == expected_instructions[index].operands.__repr__() and
                instruction.inst_format == expected_instructions[index].inst_format)

    #clear the symbol table
    symbol_table.clear()