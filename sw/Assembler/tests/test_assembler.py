from assembler import *
from parser import *
import pytest
from typing import Iterator

def test_assembler_and_compare_good_binaries(monkeypatch: pytest.MonkeyPatch) -> None:
    """Test the assembler and compare it against known good binaries"""
    def file_patch(file_name: str) -> str:
        asm: str = ""
        with open(f"../Examples/{file_name}.asm") as f:
            f.seek(0)
            asm = f.read()
        return asm
    
    def read_good_sample(file_name: str) -> Iterator[str]:
        with open(f"./samples/{file_name}_bin.txt") as f:
            for line in f:
                yield line.strip("\n")
    
    #covert assembly into binary
    monkeypatch.setattr("assembler.read_file", file_patch)
    file_names = ["add5", "fibonacci", "pwm_led_breathe"]
    for file_name in file_names:
        tokens = tokenise(file_name)
        parser = Parser(tokens)
        ast = parser.parse_program()
        machine_code = second_pass(ast)

        # check the machine code
        good_machine_code = read_good_sample(file_name)
        for index, inst in enumerate(good_machine_code):
            assert machine_code[index] == inst

        # clear symbol table
        symbol_table.clear()