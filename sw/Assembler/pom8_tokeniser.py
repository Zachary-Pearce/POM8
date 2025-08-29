"""
pom8_tokeniser.py

This module provides the tools necessary to tokenise POM8 assembly code.

Author: Zachary Pearce
Contributors: 
License: GPL-3.0

Classes:
    Token: A class representing a token.

Functions:
    read_file: A function to read an assembly text file and save the contents.
    tokenise_asm: A function that tokenises each assembly line,
        creating a list of tokens for each line.

TODO:
    Add support for negative decimals.
"""

import re
import sys

class Token():
    """
    A class representing a token.

    Attributes:
        _text (str): The portion of code associated with the token
        _type (str): The tokens type, can be:
            LABEL,
            MNEMONIC,
            REGISTER,
            COMMENT,
            HEXADECIMAL,
            DECIMAL
    """

    def __init__(self, text: str):
        """
        Token class constructor.
        
        Parameters:
            text (str): The portion of code associated with the token.
        """
        self._text = text
        self._type = ""

        self._set_type()

    # TODO: Add support for negative decimals.
    def _set_type(self):
        """
        Private method to set the token type

        Raises:
            ValueError: If a token type could not be assigned.
        """
        try:
            #anything can be in a comment so we check for it first
            if self._text.startswith(";"):
                self._type = "COMMENT"
            #registers start with an r followed by a number
            elif (self._text.upper().startswith("R")
                 and self._text[1:].isdigit()):
                self._type = "REGISTER"
            elif self._text.startswith("0x"):
                self._type = "HEXADECIMAL"
            elif self._text.isdigit():
                #if not hex prefix and all letters are digits...
                self._type = "DECIMAL"
            elif self._text.endswith(":"):
                self._type = "LABEL"
            else:
                self._type = "MNEMONIC"
                #mnemonics are just alphabet characters
                for c in self._text:
                    #not case sensitive, convert to upper case
                    #if not a mnemonic throw an exception
                    if ord(c.upper()) not in range(65,91):
                        raise ValueError(f"'{self._text}' could not be tokenised, not recognised!")
        except Exception as ex:
            print(ex)
            print("An error has occurred! Aborting...")
            sys.exit()

    def get_text(self) -> str:
        """
        Public method to get the token text.
        
        Returns:
            text (str): The portion of code associated with the token.
        """
        return self._text

    def get_type(self) -> str:
        """
        Public method to get the token type.

        Returns:
            type (str): The tokens type, can be:
                LABEL,
                MNEMONIC,
                REGISTER,
                COMMENT,
                HEXADECIMAL,
                DECIMAL
        """
        return self._type

def read_file(asm_file_name: str) -> str:
    """
    A function to read an assembly text file and save the contents.

    Parameters:
        asm_file_name (str): the name of the text file to read from.
    
    Returns:
        asm (str): The assembly code as a string
    """
    asm_file = open(asm_file_name, "r")
    asm_file.seek(0)
    asm = asm_file.read()
    asm_file.close()
    
    return asm

def tokenise_asm(asm_file_name: str) -> list[list[Token]]:
    """
    A function that tokenises each assembly line,
    creating a list of tokens for each line.

    Parameters:
        asm_file_name (str): the name of the text file to read from.

    Returns:
        token_lines (list[list[Token]]): A list of tokens for each line of assembly code.
    """
    token_lines = []

    asm = read_file(asm_file_name)
    asm_lines = re.split("\n", asm)
    for line in asm_lines:
        tokens = []
        if line != "": #ignore empty lines
            line_split = re.split(" |\t|, ", line)
            for item in line_split:
                #prevent spaces from causing trouble
                if item != "":
                    token = Token(item)
                    if token.get_type() != "COMMENT":
                        tokens.append(token)
                    else:
                        break #everything after a ; is ignored
            token_lines.append(tokens)
    
    return token_lines