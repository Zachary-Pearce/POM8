from assembler import *
from pom8_token import *
import pytest

def test_token_classification() -> None:
    """Test the token classifier, ensuring each token type is correctly classified"""
    tokens = [
        Token("r0", 1), Token("R0", 1),
        Token(";some comment", 1),
        Token("\n", 1),
        Token("0x000", 1),
        Token("0", 1),
        Token("0b00000000", 1),
        Token("start:", 1),
        Token("HLT", 1),
        Token("hlt", 1)
    ]
    expected_types = [
        TokenType.REGISTER, TokenType.REGISTER,
        TokenType.COMMENT,
        TokenType.NEWLINE,
        TokenType.HEXADECIMAL,
        TokenType.DECIMAL,
        TokenType.BINARY,
        TokenType.LABEL,
        TokenType.MNEMONIC,
        TokenType.MNEMONIC
    ]

    for index, token in enumerate(tokens):
        assert token.type == expected_types[index]

    #check if an error is raised for an invalid token
    with pytest.raises(Exception):
        Token("1m", 1)
    
    with pytest.raises(Exception):
        Token("1m:", 1)

    #clear the symbol table
    symbol_table.clear()

def test_tokenisation() -> None:
    """Test the tokenisation function in the assembler component, input valid asm is properly sanitised"""
    #split across lines for readability, but is a flat list
    good_token_stream = [
        Token("LDA", 6), Token("r0", 6), Token("0x000", 6), Token("\n", 6),
        Token("STA", 7), Token("r15", 7), Token("0x000", 7), Token("\n", 7),
        Token("ADDI", 8), Token("r0", 8), Token("r0", 8), Token("255", 8), Token("\n", 8),
        Token("LDI", 9), Token("r0", 9), Token("0b11111111", 9), Token("\n", 9)
    ]

    # tokenise the no errors files in samples/
    token_stream = tokenise("./samples/test_asm_no_errors.asm")
    # compare the generated token stream with the ideal token stream
    assert len(token_stream) == len(good_token_stream)
    for index, token in enumerate(token_stream):
        assert (token.text == good_token_stream[index].text and
                token.type == good_token_stream[index].type and
                token.line_num == good_token_stream[index].line_num)