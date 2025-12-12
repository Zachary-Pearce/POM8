from assembler import *
from parser import *
import sys
import argparse

import logging
from logger_conf import *

logger = logging.getLogger(__name__)

def main() -> None:
    help_msg = "Convert a POM8 assembly file into machine code."
    parser = argparse.ArgumentParser(description=help_msg)

    parser.add_argument("Input", type=str, help="the input assembly (.asm) file name")
    parser.add_argument("-o", "--Output", help="optional output binary file name")

    #read input argumnets
    args = parser.parse_args()

    asm_file_name = args.Input
    machine_code = []
    try:
        tokens = tokenise(asm_file_name)
        parser = Parser(tokens)
        ast = parser.parse_program()
        machine_code = second_pass(ast)
    except Exception as ex:
        logger.error(ex)
        sys.exit()

    if args.Output:
        #if an output was provided
        bin_file_name = args.Output
        write_file(bin_file_name, machine_code)
    else:
        for line in machine_code:
            print(line)

if __name__ == "__main__":
    main()