# Chapter 20: The Build Pipeline — From Assembly to Flashable Binary

## Introduction

This chapter traces every step of the build process: from assembly source files through object files, an ELF binary, a raw binary, and finally a UF2 image that the RP2350 can boot from.

## The Build Script

The complete build pipeline is automated by build.bat:

```
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb <source>.s -o <source>.o
arm-none-eabi-ld -g -T linker.ld <objects> -o button.elf
arm-none-eabi-objcopy -O binary button.elf button.bin
python uf2conv.py -b 0x10000000 -f 0xe48bff59 -o button.uf2 button.bin
```

## Step 1: Assembly (Source to Object Files)

```
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb vector_table.s -o vector_table.o
```

The assembler translates each `.s` file into an `.o` object file containing:
- Machine code for each instruction
- Symbol table (function names, labels, constants)
- Relocation entries (addresses that need fixing at link time)
- Debug information (line numbers, from the `-g` flag)

### Flags

| Flag | Purpose |
|------|---------|
| `-g` | Include debug information in the output |
| `-mcpu=cortex-m33` | Target the Cortex-M33 instruction set |
| `-mthumb` | Generate Thumb-2 instructions |

### Assembly Order

The build script assembles 11 source files:

1. vector_table.s → vector_table.o
2. reset_handler.s → reset_handler.o
3. stack.s → stack.o
4. xosc.s → xosc.o
5. reset.s → reset.o
6. coprocessor.s → coprocessor.o
7. gpio.s → gpio.o
8. button.s → button.o
9. delay.s → delay.o
10. main.s → main.o
11. image_def.s → image_def.o

Each `.include "constants.s"` is resolved during assembly — constants.s is not assembled separately.

## Step 2: Linking (Object Files to ELF)

```
arm-none-eabi-ld -g -T linker.ld vector_table.o reset_handler.o stack.o xosc.o reset.o coprocessor.o gpio.o button.o delay.o main.o image_def.o -o button.elf
```

The linker:

1. **Reads** all 11 object files
2. **Resolves symbols**: `bl GPIO_Config` in main.o finds `GPIO_Config` in gpio.o
3. **Places sections** according to linker.ld:
   - `.embedded_block` at 0x10000000
   - `.vectors` at 0x10000080
   - `.text` after the vectors
4. **Fixes relocations**: replaces placeholder addresses with final values
5. **Produces** button.elf — an ELF (Executable and Linkable Format) file

### The ELF File

The ELF file contains:
- All machine code at its final addresses
- Section headers describing each segment
- Symbol table for debugging
- Debug information (DWARF format)

The ELF file is used by debuggers (GDB, OpenOCD) but cannot be flashed directly to the RP2350 via UF2.

## Step 3: Binary Extraction (ELF to Raw Binary)

```
arm-none-eabi-objcopy -O binary button.elf button.bin
```

`objcopy` strips all ELF metadata and produces a raw binary image — just the bytes that should appear in flash, starting at address 0x10000000.

| Offset in .bin | Content |
|----------------|---------|
| 0x00000000 | IMAGE_DEF block (32 bytes) |
| 0x00000080 | Vector table (8 bytes) |
| 0x00000088+ | All code and literal pools |

The raw binary is what the flash chip will contain.

## Step 4: UF2 Conversion (Binary to UF2)

```
python uf2conv.py -b 0x10000000 -f 0xe48bff59 -o button.uf2 button.bin
```

The UF2 (USB Flashing Format) file wraps the raw binary in a format the RP2350's USB mass storage bootloader understands.

### UF2 Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `-b 0x10000000` | Base address | Where in flash this data starts |
| `-f 0xe48bff59` | Family ID | Identifies the target as RP2350 (ARM) |
| `-o button.uf2` | Output file | The flashable UF2 image |

### UF2 File Format

A UF2 file is a sequence of 512-byte blocks, each containing:

| Offset | Size | Content |
|--------|------|---------|
| 0 | 4 | Magic number 1: 0x0A324655 |
| 4 | 4 | Magic number 2: 0x9E5D5157 |
| 8 | 4 | Flags |
| 12 | 4 | Target address for this block |
| 16 | 4 | Data size (up to 256 bytes) |
| 20 | 4 | Block sequence number |
| 24 | 4 | Total number of blocks |
| 28 | 4 | Family ID (0xe48bff59) |
| 32 | 476 | Data payload (256 bytes + padding) |
| 508 | 4 | Final magic: 0x0AB16F30 |

Each 512-byte block carries up to 256 bytes of firmware data.

## Flashing

### Method 1: UF2 Drag-and-Drop

1. Hold the BOOTSEL button on the Pico 2 board
2. Connect USB
3. Copy button.uf2 to the RP2350 USB mass storage drive
4. The board reboots and runs the firmware

### Method 2: OpenOCD (Debug Probe)

```
openocd -f interface/cmsis-dap.cfg -f target/rp2350.cfg -c "adapter speed 5000" -c "program button.elf verify reset exit"
```

OpenOCD programs the ELF file directly via the SWD debug interface.  This method uses the ELF file (not UF2) and can also verify the flash contents.

## The Complete Pipeline

```
  constants.s (included by all .s files)
       |
  +----+----+----+----+----+----+----+----+----+----+
  |    |    |    |    |    |    |    |    |    |    |
 v_t  r_h  stk  xo   rst  cop  gpio btn  dly  main img
 .s   .s   .s   .s   .s   .s   .s   .s   .s   .s   .s
  |    |    |    |    |    |    |    |    |    |    |
  v    v    v    v    v    v    v    v    v    v    v
 .o   .o   .o   .o   .o   .o   .o   .o   .o   .o   .o
  |    |    |    |    |    |    |    |    |    |    |
  +----+----+----+----+----+----+----+----+----+----+
                          |
                    linker.ld + ld
                          |
                     button.elf
                          |
                      objcopy
                          |
                     button.bin
                          |
                      uf2conv
                          |
                     button.uf2
                          |
                    Flash / Run
```

## Summary

- Assembly converts `.s` source files to `.o` object files with `-mcpu=cortex-m33 -mthumb`.
- Linking combines all object files using the linker script to produce button.elf.
- `objcopy` strips ELF metadata to produce the raw binary button.bin.
- `uf2conv.py` wraps the binary in UF2 format with the RP2350 ARM family ID `0xe48bff59`.
- The build pipeline transforms human-readable assembly into a flashable firmware image in four steps.
