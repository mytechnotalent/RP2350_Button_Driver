# Chapter 14: Assembler Directives

## Introduction

Assembler directives are instructions to the assembler itself — they control how the assembler organizes, aligns, and labels the machine code it produces.  They do not generate instructions but determine where code and data are placed.  This chapter covers every directive used in our button driver.

## Processor Configuration Directives

Every source file begins with three directives that configure the assembler:

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set
```

### .syntax unified

Selects the Unified Assembly Language (UAL) syntax.  UAL provides a single syntax that works for both ARM and Thumb instruction sets.  Without this directive, the assembler defaults to a legacy syntax with different mnemonics for Thumb.

### .cpu cortex-m33

Tells the assembler which CPU to target.  This enables Cortex-M33-specific instructions and disables instructions not available on this core.  If you wrote an instruction the Cortex-M33 does not support, the assembler would reject it.

### .thumb

Forces all following code to be assembled as Thumb instructions.  The Cortex-M33 only executes Thumb code, so this directive is mandatory.

## Section Directives

### .section

```asm
.section .text                                   // code section
```

Places all following code or data into the named section.  The linker script determines where each section ends up in memory.

Sections used in our driver:

| Directive | Section | Purpose | Memory Region |
|-----------|---------|---------|---------------|
| `.section .text` | .text | Executable code | FLASH |
| `.section .rodata` | .rodata | Read-only constants | FLASH |
| `.section .data` | .data | Initialized variables | RAM |
| `.section .bss` | .bss | Uninitialized variables | RAM |
| `.section .vectors, "ax"` | .vectors | Vector table | FLASH |
| `.section .picobin_block, "a"` | .picobin_block | Boot metadata | FLASH |

The flags after the section name specify attributes:
- `"a"` — allocatable (occupies memory)
- `"ax"` — allocatable and executable

### .section in main.s

main.s declares three data sections even though they are currently empty:

```asm
.section .rodata                                 // read-only data section
.section .data                                   // data section
.section .bss                                    // BSS section
```

These exist as placeholders for future expansion.

## Alignment Directives

### .align

```asm
.align 2                                         // align to 4-byte boundary
```

The argument to `.align` is a power of 2.  `.align 2` means align to $2^2 = 4$ bytes.  The assembler inserts padding bytes (typically NOP instructions in code sections) to reach the required boundary.

4-byte alignment is required for:
- ARM instructions (some 32-bit instructions must be word-aligned)
- Data accessed with `ldr` (unaligned access may fault or be slow)

## Symbol Directives

### .global

```asm
.global Button_Init
```

Exports the symbol so the linker can resolve references from other object files.  Every function called from outside its source file needs `.global`.

Symbols exported in our driver:

| Symbol | File |
|--------|------|
| `Button_Init` | button.s |
| `Button_Read` | button.s |
| `Button_IsPressed` | button.s |
| `GPIO_Config` | gpio.s |
| `GPIO_Set` | gpio.s |
| `GPIO_Clear` | gpio.s |
| `Delay_MS` | delay.s |
| `Enable_Coprocessor` | coprocessor.s |
| `Init_XOSC` | xosc.s |
| `Enable_XOSC_Peri_Clock` | xosc.s |
| `Init_Subsystem` | reset.s |
| `Init_Stack` | stack.s |
| `Reset_Handler` | reset_handler.s |
| `main` | main.s |
| `_vectors` | vector_table.s |

### .type

```asm
.type Button_Init, %function
```

Marks the symbol as a function.  This is critical on ARM because the linker uses this information to set bit 0 (the Thumb bit) when computing branch targets.

### .size

```asm
.size Reset_Handler, . - Reset_Handler
```

Records the function's size in bytes.  The `.` symbol represents the current address.

## Data Directives

### .word

```asm
  .word STACK_TOP                                // initial stack pointer
  .word Reset_Handler + 1                        // reset handler (Thumb bit set)
```

Emits a 32-bit (4-byte) value into the output.  In vector_table.s, these create the two entries of the vector table.

### .byte

```asm
  .byte  0x42                                    // PICOBIN_BLOCK_ITEM_1BS_IMAGE_TYPE
```

Emits a single byte.  Used in image_def.s for the IMAGE_DEF metadata block.

### .hword

```asm
  .hword 0b0001000000100001                      // SECURE mode (0x1021)
```

Emits a 16-bit (2-byte) halfword.  Also used in image_def.s.

## Constant Directives

### .equ

```asm
.equ STACK_TOP,                   0x20082000
```

Defines a symbolic constant.  The assembler substitutes the value wherever the symbol appears.  All hardware addresses in our driver are defined this way in constants.s.

### .include

```asm
.include "constants.s"
```

Inserts the contents of the named file.  This is a textual inclusion — the assembler processes the included file as if its contents were written at the inclusion point.

## Label Directives

Labels are not technically directives, but they are assembler syntax that creates symbols:

```asm
Button_Init:                                     // global function label
.Button_Init_Push_Registers:                     // local label
```

Labels starting with `.` are local to the current file and do not pollute the global symbol table.  They are used for internal branch targets within a function.

## KEEP Directive (Linker)

In the linker script (covered in Chapter 19), `KEEP()` prevents the linker from discarding sections during garbage collection:

```
KEEP(*(.vectors))
```

This ensures the vector table is always included even though no code references it directly — the hardware reads it on reset.

## Summary

- `.syntax unified`, `.cpu`, `.thumb` configure the assembler for the Cortex-M33.
- `.section` directs code and data into named sections that the linker places in memory.
- `.align 2` ensures 4-byte alignment required by ARM instructions.
- `.global` and `.type` make functions visible to the linker with correct Thumb metadata.
- `.word`, `.byte`, `.hword` emit raw data for the vector table and boot metadata.
- `.equ` defines named constants; `.include` shares them across files.
