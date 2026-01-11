# The POM8 Microcontroller
<img src="https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg" alt="Contributor Covenant Badge">

POM8 is an 8-bit microcontroller architecture that is designed to serve as an understandable and accessible example of architectural design and implementation. Designed through the [Pomegranate](https://github.com/Zachary-Pearce/Pomegranate) framework, it is a reconfigurable architecture with a small footprint and comparable performance to some modern architectures.

![POM8 Block Diagram](/documentation/images/POM8-High-Level-Block-Diagram.png)

## :bulb: Key Features
* RISC-Harvard 8-bit multi-cycle architecture.
* Custom Instruction Set Architecture (ISA) with 36 instructions.
* Can run at a clock frequency of up to $100\text{MHz}$.
* Minimal resource utilisation, less than 500 LUTs.
* Toolchain provided via a Python-based assembler.
* An out-of-the-box solution suitable for FPGA and Computer Engineering beginners.

## Installation & Usage

### :toolbox: Software and Hardware Tools
Feel free to bring your own software and/or FPGA platform, however for the most seamless and beginner friendly experience, we recommend:

* You use the [Standard Edition of the Vivado Design Suite](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html) as your development environment.
* And use the [Basys 3](https://digilent.com/shop/basys-3-amd-artix-7-fpga-trainer-board-recommended-for-introductory-users/) FPGA development board by Digilent for a fairly capable but relatively inexpensive platform that is designed for use with Vivado.

### :rocket: Setting Up
1. Clone this repository.

```bash
git clone https://github.com/Zachary-Pearce/POM8.git
```

2. Create a new project and import the rtl files.
3. Write and assemble your first program.

> [!TIP]
> The handbook has more details for getting started with POM8.