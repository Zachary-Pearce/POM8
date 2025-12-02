"""
pom8_token.py

This module provides the tools necessary to generate tokens,
from POM8 assembly code.

Author: Zachary Pearce
Contributors: 
License: GPL-3.0

Classes:
    TokenType: An enumeration of possible token types.
    Token: A class representing a token.
"""

import re
from enum import Enum

__all__ = ["TokenType", "Token"]

class TokenType(Enum):
    """
    An enumeration of possible token types.
    
    Members:
        LABEL: A label token.
        MNEMONIC: A mnemonic token.
        REGISTER: A register token.
        COMMENT: A comment token.
        HEXADECIMAL: A hexadecimal number token.
        DECIMAL: A decimal number token.
    """
    LABEL = 1
    MNEMONIC = 2
    REGISTER = 3
    COMMENT = 4
    HEXADECIMAL = 5
    DECIMAL = 6

#Precompiled regex patterns for performance
# .upper() or .lower() can be slower, so we use re.IGNORECASE
_REGISTER_RE = re.compile(r"^r\d+$", re.IGNORECASE)
_HEX_RE = re.compile(r"^0x[0-9A-F]+$", re.IGNORECASE)
_DECIMAL_RE = re.compile(r"^[-]?\d+$")
_LABEL_RE = re.compile(r"^[a-z][a-z0-9]*:$", re.IGNORECASE)
_MNEMONIC_RE = re.compile(r"^[a-z][a-z0-9]+$", re.IGNORECASE)

class Token():
    """
    A class representing a token of POM8 assembly code.

    Properties:
        text (str): The portion of code associated with the token.
        type (TokenType): The tokens type as a TokenType member.
    """

    def __init__(self, text: str, line_num: int):
        """
        Token class constructor.
        
        Parameters:
            text (str): The portion of code associated with the token.
            line_num (int): The line number of the token, for error tracking.
        """
        self._text: str = text
        self._line_num: int = line_num
        self._type: TokenType = self._classify_token()

    def _classify_token(self) -> TokenType:
        """
        Assigns a TokenType based on the token's raw text.

        Returns:
            type (TokenType): The assigned token type.

        Raises:
            ValueError: If the token type cannot be determined.
        """
        #anything can be in a comment so we check for it first
        if self._text.startswith(";"):
            return TokenType.COMMENT
        #registers start with an r followed by a number
        elif _REGISTER_RE.fullmatch(self._text):
            return TokenType.REGISTER
        #hexadecimal numbers start with 0x followed by hex digits
        elif _HEX_RE.fullmatch(self._text):
            return TokenType.HEXADECIMAL
        #decimal numbers
        elif _DECIMAL_RE.fullmatch(self._text):
            return TokenType.DECIMAL
        #labels end with a colon,
        # and start with a letter followed by letters/numbers
        elif _LABEL_RE.fullmatch(self._text):
            return TokenType.LABEL
        elif _MNEMONIC_RE.fullmatch(self._text):
            return TokenType.MNEMONIC
        else:
            raise ValueError(f"Line {self._line_num}: '{self._text}' could not be tokenised, not recognised!")

    @property
    def text(self) -> str:
        """The portion of code associated with the token."""
        return self._text

    @property
    def type(self) -> TokenType:
        """The tokens type as a TokenType enum member."""
        return self._type
    
    def __repr__(self) -> str:
        """String representation of the Token object."""
        return f"Token(text='{self._text}', type={self._type})"