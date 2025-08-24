# The POM8 Microcontroller
<img src="https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg" alt="Contributor Covenant Badge">

POM8 is an 8-bit microcontroller architecture that is designed to serve as an understandable and accessible example of architectural design and implementation. Designed through the [Pomegranate](https://github.com/Zachary-Pearce/Pomegranate) framework, it is a reconfigurable architecture with a small footprint and comparable performance to some modern architectures.

![POM8 Block Diagram](/documentation/images/POM8%20Block%20Diagram.png)

### Key Features
* RISC-Harvard 8-bit single-cycle architecture.
* Custom Instruction Set Architecture (ISA) with 36 instructions.
* Can run at a clock frequency of up to $100\text{MHz}$.
* Minimal resource utilisation, less than 500 LUTs.
* Toolchain provided via a Python-based assembler.
* An out-of-the-box solution suitable for FPGA and Computer Engineering beginners.

## Installation & Usage
1. Clone this repository.

```bash
git clone https://github.com/Zachary-Pearce/POM8.git
```

2. Import the rtl files into your project.
3. Visit the wiki for a full guide on writing your "Hello World!" program.