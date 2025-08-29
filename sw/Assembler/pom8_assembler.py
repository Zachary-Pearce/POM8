"""pom8_assembler.py

This module provides the operations required to perform syntax analysis and
assemble any POM8 mnemonics.

Author: Zachary Pearce
Contributors: 
License: GPL-3.0

Classes:
    Assembler: A wrapper class for the POM8 assembler

TODO:
    Might want to further modularise this and move all syntax analysis to another file.
    Add support for negative decimals.
    Clean up assemble logic.
"""

from pom8_tokeniser import *
import sys
import argparse

class Assembler():
    """
    Wrapper class for the POM8 assembler
    
    Attributes:
        opcode (dict): A dictionary of opcodes and their respective binary.
        funct (dict): A dictionary of opcodes and their respective binary.
        formats (dict): A dictionary of instruction formats and expected token order.
        _asm_file_name (str): The name of the assembly code file.
        _token_lines (list[list[Token]]): The tokenised lines of code.
        _format_lines (list[str]): The format of each line.
        _machine_code (list[str]): The final machine code.
        _labels (dict): A dictionary of labels and their repsective address.
    """

    opcode = {
	    "NOP": "0001",
	    "CALL": "0010",
	    "RET": "0011",
	    "JMP": "0100",
	    "BRZ": "0101",
	    "BRN": "0110",
	    "BRP": "0111",
	    "BRC": "1000",
	    "BRV": "1001",
	    "LDR": "1010",
	    "LDW": "1011",
	    "LDI": "1100",
	    "STR": "1101",
	    "STW": "1110",
	    "STI": "1111"
    }

    funct = {
	    "ADD": "00000",
	    "SUB": "00001",
	    "AND": "00010",
	    "OR": "00011",
	    "NOT": "00100",
	    "XOR": "00101",
	    "ADDI": "00110",
	    "SUBI": "00111",
	    "ANDI": "01000",
	    "ORI": "01001",
	    "XORI": "01010",
	    "LSL": "01011",
	    "LSR": "01100",
	    "ADDC": "01101",
	    "SUBC": "01110",
	    "PUSH": "01111",
	    "POP": "10000",
	    "SETC": "10001",
	    "CLRC": "10010",
	    "SETV": "10011",
	    "CLRV": "10100"
    }

    formats = {
        "REGISTER": ["MNEMONIC", "REGISTER", "REGISTER", "REGISTER/DECIMAL"],
        "BRANCH": ["MNEMONIC", "HEXADECIMAL/MNEMONIC"],
        "ADDRESSING_LOAD": ["MNEMONIC", "REGISTER", "HEXADECIMAL"],
        "ADDRESSING_LOAD_IMMEDIATE": ["MNEMONIC", "REGISTER", "DECIMAL"],
        "ADDRESSING_LOAD_INDEXED": ["MNEMONIC", "REGISTER", "REGISTER", "DECIMAL"],
        "ADDRESSING_STORE": ["MNEMONIC", "REGISTER", "HEXADECIMAL"],
        "ADDRESSING_STORE_IMMEDIATE": ["MNEMONIC", "HEXADECIMAL", "DECIMAL"],
        "ADDRESSING_STORE_INDEXED": ["MNEMONIC", "REGISTER", "REGISTER", "DECIMAL"]
    }

    def __init__(self, asm_file_name: str):
        """
        Assembler class constructor.
        
        Parameters:
            asm_file_name (str): The name of the assembly code file.
        """
        self._asm_file_name = asm_file_name

        self._token_lines = []
        self._format_lines = []
        self._machine_code = []
        self._labels = {}

    def _get_labels(self):
        """
        Get labels from the tokenised code, store them in a dictionary
        and remove them.
        
        Raises:
            SyntaxError: If there is a duplicate label or labels contain
                non-letter charaters.
        """
        try:
            for line in self._token_lines:
                current_line = self._token_lines.index(line)
                for token in line:
                    if token.get_type() == "LABEL":
                        #don't want the colon in the dictionary entry
                        label = token.get_text()[:-1]
                        if label in self._labels:
                            raise SyntaxError(
                                f"line {current_line + 1}: '{label}' label already exists!"
                            )

                        for char in label:
                            if ord(char.upper()) not in range(65,91):
                                raise SyntaxError(
                                    f"Line {current_line + 1}: Unexpected '{char}' in '{label}'.\n \
                                        Labels must only contain letters"
                                )
                        #remove the label from the line
                        line.remove(token)
                        self._labels[label] = current_line
        except Exception as ex:
            print(ex)
            print("An error has occurred! Aborting...")
            sys.exit()
    
    def _address_format_check(self, token_mnemonic: str) -> bool:
        """
        Checks if a given mnemonic is in the address format.

        Parameters:
            token_mnemonic (str): The mnemonic to check
        
        Returns:
            match (bool): returns True if the mnemonic is in the format.
        """
        if (token_mnemonic == "LDR"
            or token_mnemonic == "LDW"
            or token_mnemonic == "LDI"
            or token_mnemonic == "STR"
            or token_mnemonic == "STW"
            or token_mnemonic == "STI"):
            return True
        else:
            return False

    def _branch_format_check(self, token_mnemonic: str) -> bool:
        """
        Checks if a given mnemonic is in the branch format.

        Parameters:
            token_mnemonic (str): The mnemonic to check
        
        Returns:
            match (bool): returns True if the mnemonic is in the format.
        """
        if (token_mnemonic == "NOP"
            or token_mnemonic == "CALL"
            or token_mnemonic == "RET"
            or token_mnemonic == "JMP"
            or token_mnemonic == "BRZ"
            or token_mnemonic == "BRN"
            or token_mnemonic == "BRP"
            or token_mnemonic == "BRC"
            or token_mnemonic == "BRV"):
            return True
        else:
            return False

    def _get_line_format(self, line: list[Token]) -> str:
        """
        Gets the instruction format relating to a line of assembly.

        Parameters:
            line (list[Token]): The token line to identify.
        
        Returns:
            format (str): The identified format of the line, can be:
                REGISTER,
                BRANCH,
                ADDRESSING_LOAD,
                ADDRESSING_LOAD_IMMEDIATE,
                ADDRESSING_LOAD_INDEXED,
                ADDRESSING_STORE,
                ADDRESSING_STORE_IMMEDIATE,
                ADDRESSING_STORE_INDEXED
        """
        _format = ""
        mnemonic = line[0].get_text().upper()

        if mnemonic not in self.opcode:
            _format = "REGISTER"
        elif self._branch_format_check(mnemonic):
            _format = "BRANCH"
        elif self._address_format_check(mnemonic):
            if mnemonic.startswith("L"):
                if mnemonic.endswith("W"):
                    _format = "ADDRESSING_LOAD_IMMEDIATE"
                elif mnemonic.endswith("I"):
                    _format = "ADDRESSING_LOAD_INDEXED"
                else:
                    _format = "ADDRESSING_LOAD"
            else:
                if mnemonic.endswith("W"):
                    _format = "ADDRESSING_STORE_IMMEDIATE"
                elif mnemonic.endswith("I"):
                    _format = "ADDRESSING_STORE_INDEXED"
                else:
                    _format = "ADDRESSING_STORE"
        
        return _format
    
    def _check_symbols(self, token: Token, line_num: int):
        """
        Check for unexpected symbols in operands.

        Parameters:
            token (Token): The token to check.
            line_num (int): The token's line number.

        Raises:
            SyntaxError: If there are unexpected symbols.
        """
        token_type = token.get_type()

        match token_type:
            case "HEXADECIMAL":
                _hex = token.get_text()[2:]
                for char in _hex:
                    if char.upper() not in "ABCDEF" and not char.isdigit():
                        raise SyntaxError(
                            f"Line {line_num}: '{_hex}' is not a valid {token_type}, Unexpected '{char}'."
                        )
            case "MNEMONIC":
                mnemonic = token.get_text()
                if (mnemonic not in self.opcode
                and mnemonic not in self.funct
                and mnemonic not in self._labels):
                    raise SyntaxError (
                        f"Line {line_num}: '{mnemonic}' is not a valid {token_type}!"
                    )
    
    def _check_overflow(self, token: Token, line_num: int):
        """
        Check that all inputs are within range.

        Parameters:
            token (Token): The token to check.
            line_num (int): The token's line number.
        
        Raises:
            OverflowError: If any input is out of range.
        """
        token_type = token.get_type()

        match token_type:
            case "REGISTER":
                reg_num = token.get_text()[1:]
                if int(reg_num, 10) > 15:
                    raise OverflowError(
                        f"Line {line_num}: {token_type} index '{reg_num}' out of range, \
                            expected range 0-15"
                    )
            case "HEXADECIMAL":
                _hex = token.get_text()[2:]
                if len(_hex) > 4:
                    raise OverflowError(
                        f"Line {line_num}: {token_type} '{_hex}' out of range, \
                            expected range 0x0000-0xFFFF"
                    )
            case "DECIMAL":
                dec_num = token.get_text()
                if int(dec_num, 10) > 255:
                    raise OverflowError(
                        f"Line {line_num}: {token_type} word '{dec_num}' out of range, \
                            expected range 0-255"
                    )

    # TODO: Add support for negative decimals.
    def syntax_analysis(self):
        """
        Tokenise and perform syntax analysis on assembly code
        
        Raises:
            SyntaxError: If a line is not in the correct format.
        """
        self._token_lines = tokenise_asm(self._asm_file_name)
        self._get_labels()

        try:
            for line in self._token_lines:
                current_line = self._token_lines.index(line)

                #check the tokens
                for token in line:
                    self._check_symbols(token, current_line + 1)
                    
                    self._check_overflow(token, current_line + 1)

                #then check the line is in the correct format
                _format = self._get_line_format(line)
                self._format_lines.append(_format) #save the format for assembly later
                expected_tokens = self.formats[_format]
                i = 0
                while i < len(line):
                    if line[i].get_type() not in expected_tokens[i]:
                        raise SyntaxError(
                            f"Line {current_line + 1}: Unexpected token '{line[i].get_type()}', \
                                expected '{expected_tokens[i]}'"
                        )
                    i += 1
        except Exception as ex:
            print(ex)
            print("An error has occurred! Aborting...")
            sys.exit()

    def _convert_register(self, token: Token) -> str:
        """
        Converts a register token into machine code.

        Parameters:
            token (Token): The register token to convert.

        Returns:
            machine_code (str): The converted binary string.
        """
        machine_code = ""

        reg_index = int(token.get_text()[1:], 10)
        machine_code = f"{reg_index:04b}"

        return machine_code

    # TODO: clean up assemble logic, very messy.
    def assemble(self):
        """Assemble tokenised and syntax checked assembly code."""
        i = 0
        while i < len(self._token_lines):
            machine_code_line = ""
            line = self._token_lines[i]
            mnemonic = line[0].get_text().upper()

            if self._format_lines[i] == "REGISTER":
                immediate = 0
                Rs = 0
                Rt = 0
                Rd = 0
                funct = self.funct[mnemonic]

                #convert the registers
                reg_num = 0
                if mnemonic.endswith("I"):
                    reg_num = 2
                    immediate = int(line[3].get_text(), 10)
                else:
                    reg_num = len(line) - 1
                
                match reg_num:
                    case 1:
                        if mnemonic == "PUSH":
                            Rs = int(line[1].get_text()[1:], 10)
                        else:
                            Rd = int(line[1].get_text()[1:], 10)
                    case 2:
                        Rs = int(line[1].get_text()[1:], 10)
                        Rd = int(line[2].get_text()[1:], 10)
                    case 3:
                        Rs = int(line[1].get_text()[1:], 10)
                        Rt = int(line[2].get_text()[1:], 10)
                        Rd = int(line[3].get_text()[1:], 10)

                machine_code_line = ("0000"
                                     + f"{Rs:04b}"
                                     + f"{Rt:04b}"
                                     + funct
                                     + "000"
                                     + f"{Rd:04b}"
                                     + f"{immediate:08b}")
            elif self._format_lines[i] == "BRANCH":
                opcode = self.opcode[line[0].get_text()]
                
                #is it a label or a hex input
                immediate = "00000000"
                if len(line) > 1:
                    if line[1].get_text() in self._labels:
                        immediate = f"{self._labels[line[1].get_text()]:08b}"
                    else:
                        _hex = line[1].get_text()[2:]
                        decimal = int(_hex, 16)
                        immediate = f"{decimal:08b}"
                
                machine_code_line = (opcode
                                     + "00000000"
                                     + immediate
                                     + "000000000000")
            elif self._format_lines[i] == "ADDRESSING_LOAD":
                opcode = self.opcode[line[0].get_text()]
                register_num = int(line[1].get_text()[1:], 10)
                _hex = line[2].get_text()[2:]
                decimal = int(_hex, 16)
                address = f"{decimal:016b}"
                immediate_higher = address[:8]
                immediate_lower = address[-8:]
                machine_code_line = (opcode
                                     + "00000000"
                                     + immediate_higher
                                     + f"{register_num:04b}"
                                     + immediate_lower)
            elif self._format_lines[i] == "ADDRESSING_LOAD_IMMEDIATE":
                opcode = self.opcode[line[0].get_text()]
                register_num = int(line[1].get_text()[1:], 10)
                immediate = int(line[2].get_text(), 10)
                machine_code_line = (opcode
                                     + "00000000"
                                     + "00000000"
                                     + f"{register_num:04b}"
                                     + f"{immediate:08b}")
            elif self._format_lines[i] == "ADDRESSING_LOAD_INDEXED":
                opcode = self.opcode[line[0].get_text()]
                registers = []
                for n in range(2):
                    register_num = int(line[1+n].get_text()[1:], 10)
                    registers.append(f"{register_num:04b}")
                immediate = int(line[3].get_text(), 10)
                machine_code_line = (opcode
                                     + registers[0]
                                     + "0000"
                                     + "00000000"
                                     + registers[1]
                                     + f"{immediate:08b}")
            elif self._format_lines[i] == "ADDRESSING_STORE":
                opcode = self.opcode[line[0].get_text()]
                register_num = int(line[1].get_text()[1:], 10)
                _hex = line[2].get_text()[2:]
                decimal = int(_hex, 16)
                address = f"{decimal:016b}"
                immediate_higher = address[:8]
                immediate_lower = address[-8:]
                machine_code_line = (opcode
                                     + f"{register_num:04b}"
                                     + "0000"
                                     + immediate_higher
                                     + "0000"
                                     + immediate_lower)
            elif self._format_lines[i] == "ADDRESSING_STORE_IMMEDIATE":
                opcode = self.opcode[line[0].get_text()]
                _hex = line[1].get_text()[2:]
                decimal = int(_hex, 16)
                address = f"{decimal:016b}"
                address_higher = address[:8]
                address_lower = address[-8:]
                immediate = int(line[2].get_text(), 10)
                machine_code_line = (opcode
                                     + address_higher
                                     + address_lower
                                     + "0000"
                                     + f"{immediate:08b}")
            elif self._format_lines[i] == "ADDRESSING_STORE_INDEXED":
                opcode = self.opcode[line[0].get_text()]
                registers = []
                for n in range(2):
                    register_num = int(line[1+n].get_text()[1:], 10)
                    registers.append(f"{register_num:04b}")
                immediate = int(line[3].get_text(), 10)
                machine_code_line = (opcode
                                     + registers[0]
                                     + registers[1]
                                     + "00000000"
                                     + "0000"
                                     + f"{immediate:08b}")

            self._machine_code.append(machine_code_line)
            i += 1
    
    def get_machine_code(self) -> list[str]:
        """
        Get the machine code

        Returns:
            machine_code (str): The converted machine code
        """
        return self._machine_code

def write_file(bin_file_name: str, machine_code: list[str]):
    """
    A function to write machine code to a file.

    Parameters:
        bin_file_name (str): The name of the file to write to.
        machine_code (list[str]): The machine code to write.
    """
    bin_file = open(bin_file_name, "w")
    bin_file.seek(0)

    for line in machine_code:
        bin_file.write(line + "\n")

    bin_file.close()

if __name__ == "__main__":
    help_msg = "Convert a POM8 assembly file into machine code."
    parser = argparse.ArgumentParser(description=help_msg)

    parser.add_argument("Input", type=str, help="the input assembly (.asm) file name")
    parser.add_argument("-o", "--Output", help="optional output binary file name")

    #read input argumnets
    args = parser.parse_args()

    #convert the input file
    asm_file_name = args.Input
    assembler = Assembler(asm_file_name)
    assembler.syntax_analysis()
    assembler.assemble()

    machine_code = assembler.get_machine_code()
    if args.Output:
        #if an output was provided
        bin_file_name = args.Output
        write_file(bin_file_name, machine_code)
    else:
        for line in machine_code:
            print(line)