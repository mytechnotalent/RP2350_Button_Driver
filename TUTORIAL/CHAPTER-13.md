# Chapter 13: Pseudo-Instructions

## Introduction

Some instructions in our source code do not correspond to a single machine instruction.  Instead, the assembler translates them into one or more real instructions.  These are **pseudo-instructions** — programmer conveniences that the assembler expands for us.

## ldr Rd, =value — Load Constant

The most common pseudo-instruction in our driver:

```asm
  ldr   r4, =PADS_BANK0_BASE                     // load PADS_BANK0_BASE address
```

This is not a real ARM instruction.  The assembler converts it based on the constant's value:

### Case 1: Small Constant

If the value fits in a `movs` or `mov` immediate:

```asm
  ldr   r0, =10                                  // 10ms debounce delay
```

The assembler may emit:

```asm
  movs  r0, #10                                  // single instruction, no pool
```

### Case 2: Modified Immediate

If the value can be expressed as a rotated 8-bit immediate:

```asm
  ldr   r5, =15                                  // GPIO15
```

The assembler may emit:

```asm
  movs  r5, #15                                  // fits in immediate
```

### Case 3: Large Constant

If the value does not fit any immediate encoding:

```asm
  ldr   r4, =PADS_BANK0_BASE                     // 0x40038000
```

The assembler emits:

```asm
  ldr   r4, [pc, #offset]                        // PC-relative load from literal pool
```

And places `0x40038000` in the literal pool.

### Usage in Our Driver

| Pseudo-Instruction | Value | Likely Expansion |
|-------------------|-------|-----------------|
| `ldr r4, =PADS_BANK0_BASE` | 0x40038000 | Literal pool |
| `ldr r4, =IO_BANK0_BASE` | 0x40028000 | Literal pool |
| `ldr r0, =XOSC_STARTUP` | 0x4004800c | Literal pool |
| `ldr r0, =CPACR` | 0xe000ed88 | Literal pool |
| `ldr r0, =RESETS_RESET` | 0x40020000 | Literal pool |
| `ldr r4, =3600` | 0xE10 | Literal pool |
| `ldr r0, =10` | 0x0A | `movs r0, #10` |
| `ldr r0, =16` | 0x10 | `movs r0, #16` |
| `ldr r4, =0` | 0x00 | `movs r4, #0` |
| `ldr r4, =1` | 0x01 | `movs r4, #1` |
| `ldr r5, =15` | 0x0F | `movs r5, #15` |

## .type — Symbol Type Declaration

```asm
.type Button_Init, %function                     // mark as function
```

This tells the assembler that `Button_Init` is a function symbol.  It is not an instruction — it produces no machine code.  The linker uses this metadata to set the Thumb bit (bit 0) in function addresses.

## .global — Export Symbol

```asm
.global Button_Init                              // export Button_Init symbol
```

Makes the symbol visible to the linker so other files can reference it.  Without `.global`, the symbol is file-local and `bl Button_Init` from another file would fail at link time.

## .size — Function Size

```asm
.size Reset_Handler, . - Reset_Handler
```

Records the size of the function in the symbol table.  The `.` represents the current address, so `. - Reset_Handler` computes the number of bytes from the start of the function to this point.  Debuggers use this information.

## .equ — Define Constant

```asm
.equ STACK_TOP,                   0x20082000
```

Associates a name with a numeric value.  This is not an instruction — it creates an assembler symbol that can be used anywhere a numeric value is expected.  Every `.equ` in constants.s becomes a named constant available through `.include "constants.s"`.

## .include — Include File

```asm
.include "constants.s"
```

Textually inserts the contents of constants.s at the point of the directive.  This is how every source file gains access to the memory addresses defined in constants.s.

## Pseudo-Instructions vs. Directives

| Feature | Pseudo-Instruction | Directive |
|---------|-------------------|-----------|
| Produces machine code? | Yes (1+ instructions) | No |
| Example | `ldr r0, =10` → `movs r0, #10` | `.global`, `.equ`, `.type` |
| Purpose | Simplify instruction writing | Control assembler behavior |

Both are written in the source file, but only pseudo-instructions generate executable bytes.

## Summary

- `ldr Rd, =value` is the primary pseudo-instruction, expanded to `movs`, `mov`, or a literal pool load depending on the constant's size.
- `.type`, `.global`, and `.size` provide symbol metadata for the linker and debugger.
- `.equ` creates named constants used throughout the driver.
- `.include` inserts file contents — shared constants.s is included by every source file.
- Pseudo-instructions generate machine code; directives do not.
