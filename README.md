# ARM32-Pipelined-CPU

A complete ARM32 CPU implementation in SystemVerilog, featuring a pipelined architecture with instruction decoder, datapath, ALU, register file, and controller.

## 🏗️ Architecture Overview

This project implements a simplified ARM32 processor with the following components:

- **Instruction Decoder**: Decodes 32-bit ARM instructions into control signals
- **Datapath**: Contains ALU, register file, shifter, and data processing logic
- **Controller**: State machine controlling the instruction execution pipeline
- **ALU**: Arithmetic and logic operations with condition flags
- **Register File**: 16 ARM registers (R0-R15) with R0 hardwired to zero
- **Shifter**: Barrel shifter for shift/rotate operations
- **Status Register**: Condition flags (N, Z, C, V) management

## 📋 Supported Instructions

### Data Processing Instructions (21 instructions)
- **ADD, SUB, AND, ORR, EOR, MOV, CMP**
- **3 Addressing Modes**: Immediate, Register, Register Shifted

### Memory Access Instructions (5 instructions)
- **LDR**: Load Register (immediate, register, literal)
- **STR**: Store Register (immediate, register)

### Branch Instructions (4 instructions)
- **B**: Branch
- **BL**: Branch with Link
- **BX**: Branch Exchange
- **BLX**: Branch with Link Exchange

### Control Instructions (2 instructions)
- **NOP**: No Operation
- **HALT**: Halt Execution

**Total: 32 distinct instructions**

## 🔧 Pipeline Architecture

The CPU implements a 5-stage pipeline:

1. **Fetch**: Fetch instruction from memory
2. **Decode**: Decode instruction and generate control signals
3. **Execute**: Perform ALU operations and data processing
4. **Memory**: Memory access and PC increment
5. **Write Back**: Write results back to register file

## 🔍 Key Features

### ARM32 Compliance
- **16 Registers**: R0-R15 with R0 hardwired to zero
- **Condition Codes**: Full ARM condition code support
- **Status Flags**: N (Negative), Z (Zero), C (Carry), V (Overflow)
- **Addressing Modes**: Immediate, register, and register-shifted

### Pipeline Features
- **Forwarding**: Data forwarding for pipeline efficiency
- **Multiple Write Ports**: Support for normal writes, LDR writes, and LR writes
- **PC Management**: Proper PC handling with multiple sources
- **Memory Interface**: Clean interface for memory operations

### Code Quality
- **Well Documented**: Comprehensive comments and documentation
- **Modular Design**: Clean separation of concerns
- **Synthesis Ready**: Proper coding style for synthesis
- **Tested**: Comprehensive testbenches for all components

## 📊 Performance Characteristics

- **Clock Frequency**: Depends on target FPGA/ASIC technology
- **Pipeline Depth**: 5 stages
- **Register File**: 16 × 32-bit registers
- **ALU Operations**: 5 operations (ADD, SUB, AND, ORR, XOR)
- **Shift Operations**: 4 operations (LSL, LSR, ASR, ROR)

## 🧪 Testing

The project includes comprehensive testbenches for all components:

- **ALU Tests**: All arithmetic and logic operations
- **Register File Tests**: Read/write operations, R0 zero behavior
- **Shifter Tests**: All shift operations with edge cases
- **Instruction Decoder Tests**: All instruction types and addressing modes
- **Controller Tests**: Pipeline state machine and control signals
- **Datapath Tests**: Data flow and forwarding
- **CPU Tests**: End-to-end instruction execution

## 🔧 Configuration

### ALU Operations
```systemverilog
localparam [2:0] ALU_ADD = 3'b000;
localparam [2:0] ALU_SUB = 3'b001;
localparam [2:0] ALU_AND = 3'b010;
localparam [2:0] ALU_ORR = 3'b011;
localparam [2:0] ALU_XOR = 3'b100;
```

### Shift Operations
```systemverilog
2'b00: Logical Left Shift (LSL)
2'b01: Logical Right Shift (LSR)
2'b10: Arithmetic Right Shift (ASR)
2'b11: Rotate Right (ROR)
```

## 📚 Instruction Examples

### Data Processing
```assembly
ADD R1, R2, R3        ; R1 = R2 + R3
SUB R1, R2, #10       ; R1 = R2 - 10
MOV R1, #0x100        ; R1 = 0x100
CMP R1, R2            ; Compare R1 and R2
```

### Memory Access
```assembly
LDR R1, [R2, #4]      ; R1 = memory[R2 + 4]
STR R1, [R2, R3]      ; memory[R2 + R3] = R1
LDR R1, =0x12345678   ; R1 = 0x12345678 (literal)
```

### Branching
```assembly
B label               ; Branch to label
BL function           ; Branch with link
BX R1                 ; Branch exchange to R1
```

