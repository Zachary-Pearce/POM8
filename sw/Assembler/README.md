# The POM8 Assembler
This assembler is a completely custom Python package featuring lexical, semantic, and syntax analysis. It assembles given POM8 assembly using multiple passes, the generated binary can then be copied into POM8's instruction memory.

## :mag_right: Breakdown
The package is made up of several python files:

* `pom8_token.py` - Implements the `Token` class, tokens are classified on instantiation.
* `parser.py` - Implements a recursive descent parser to build an abstract syntax tree (ast) from a token stream, this makes up the first pass of the assembler.
* `assembler.py` - Implements the second pass, converting a given ast into machine code.
* `logger_conf.py` - This package holds the dictionary config for the logger.

Being for the POM8 Microcontroller, this packages focuses on readability and maintainability over performance, allowing a relatively inexperienced user to understand how the assembler works.

## :rocket: Installation
Install the package using pip.

```bash
python3 -m pip install POM8_Assembler
```

While installing, you may receive an `error: externally-managed-environment`, this means your python install is managed by your OS or another package manager. You will need to install the package in a virtual environment.

1. Create the virtual environment in your current folder, where the second argument is the location of the virtual environment.

```bash
# Create a virtual environment called ".venv" in the working directory
python3 -m venv .venv
```

2. Activate the virtual environment, where `<DIR>` is the location of the virtual environment.

```bash
source <DIR>/bin/activate
```

3. Now you can install using pip as before, once you have finished using your virtual environment, deactivate it.

```bash
deactivate
```

## :zap: Usage
The assembler can be run as a CLI application

```bash
python3 -m POM8_Assembler YourProgram.asm
```

By default this will output the resulting binary to the terminal, or you can write the result to a file by providing an output file.

```bash
python3 -m POM8_Assembler YourProgram.asm -o output.txt
```

Alternatively, you can import the individual components of the package, `import *` is satisfactory as the `__all__` attribute is configured for each component.

## :seedling: Contribution
We welcome contributions to any part of this package, please ensure that you run the unit tests after any change, you can do this by going to `<REPO DIR>/sw/Assembler/` and running pytest.

```bash
python3 -m pytest
```