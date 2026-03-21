# Chapter 19: The Linker Script — Placing Code in Memory

## Introduction

The assembler produces object files containing machine code and data, but does not decide where they go in memory.  The **linker script** (linker.ld) tells the linker exactly where to place each section so the RP2350 boot ROM and the Cortex-M33 can find them at the correct addresses.

## The Complete Linker Script

```
ENTRY(Reset_Handler)

__XIP_BASE   = 0x10000000;
__XIP_SIZE   = 32M;

__SRAM_BASE  = 0x20000000;
__SRAM_SIZE  = 512K;                             /* non-secure window */
__STACK_SIZE = 32K;

MEMORY
{
  RAM   (rwx) : ORIGIN = __SRAM_BASE, LENGTH = __SRAM_SIZE
  FLASH (rx)  : ORIGIN = __XIP_BASE,  LENGTH = __XIP_SIZE
}

PHDRS
{
  text PT_LOAD FLAGS(5);                         /* RX */
}

SECTIONS
{
  . = ORIGIN(FLASH);

  .embedded_block :
  {
    KEEP(*(.embedded_block))
  } > FLASH :text

  .vectors ALIGN(128) :
  {
    KEEP(*(.vectors))
  } > FLASH :text

  ASSERT(((ADDR(.vectors) - ORIGIN(FLASH)) < 0x1000),
         "Vector table must be in first 4KB of flash")

  .text :
  {
    . = ALIGN(4);
    *(.text*)
    *(.rodata*)
    KEEP(*(.ARM.attributes))
  } > FLASH :text

  __StackTop   = ORIGIN(RAM) + LENGTH(RAM);      /* 0x20080000 */
  __StackLimit = __StackTop - __STACK_SIZE;
  __stack      = __StackTop;

  .stack (NOLOAD) : { . = ALIGN(8); } > RAM

  PROVIDE(__Vectors = ADDR(.vectors));
}
```

## Line-by-Line Walkthrough

### Entry Point

```
ENTRY(Reset_Handler)
```

Declares `Reset_Handler` as the entry point for the debugger and linker.  This symbol is defined in reset_handler.s.  It does not affect the hardware boot — that is controlled by the vector table.

### Memory Constants

```
__XIP_BASE   = 0x10000000;
__XIP_SIZE   = 32M;
```

Defines the flash base address and maximum size.  XIP (Execute-in-Place) means the Cortex-M33 executes code directly from flash through a cache, without copying it to RAM first.

```
__SRAM_BASE  = 0x20000000;
__SRAM_SIZE  = 512K;                             /* non-secure window */
__STACK_SIZE = 32K;
```

Defines the SRAM base, total size, and the amount reserved for the stack.

### Memory Regions

```
MEMORY
{
  RAM   (rwx) : ORIGIN = __SRAM_BASE, LENGTH = __SRAM_SIZE
  FLASH (rx)  : ORIGIN = __XIP_BASE,  LENGTH = __XIP_SIZE
}
```

Declares two memory regions:
- **RAM**: read-write-execute, starting at 0x20000000, 512 KB
- **FLASH**: read-execute, starting at 0x10000000, 32 MB

The flags `(rwx)` and `(rx)` specify the access permissions.

### Program Headers

```
PHDRS
{
  text PT_LOAD FLAGS(5);                         /* RX */
}
```

Defines a single program header for the ELF output.  `PT_LOAD` means this segment is loaded into memory.  `FLAGS(5)` = read(4) + execute(1) = RX.  This is used by tools that process the ELF file.

### Section Placement

#### IMAGE_DEF Block

```
  . = ORIGIN(FLASH);

  .embedded_block :
  {
    KEEP(*(.embedded_block))
  } > FLASH :text
```

Places the IMAGE_DEF metadata (from image_def.s) at the very start of flash (0x10000000).  `KEEP()` prevents the linker from discarding it during garbage collection — no code references it, but the boot ROM needs it.

The `.` is the **location counter**.  Setting it to `ORIGIN(FLASH)` starts placement at 0x10000000.

#### Vector Table

```
  .vectors ALIGN(128) :
  {
    KEEP(*(.vectors))
  } > FLASH :text
```

Places the vector table (from vector_table.s) at the next 128-byte boundary.  The Cortex-M33 requires the vector table to be aligned to its size or 128 bytes, whichever is larger.  Our table has only 2 entries (8 bytes), so 128-byte alignment is required.

The ASSERT that follows:

```
  ASSERT(((ADDR(.vectors) - ORIGIN(FLASH)) < 0x1000),
         "Vector table must be in first 4KB of flash")
```

Ensures the vector table falls within the first 4 KB of flash.  The boot ROM only searches this region.

#### Code and Read-Only Data

```
  .text :
  {
    . = ALIGN(4);
    *(.text*)
    *(.rodata*)
    KEEP(*(.ARM.attributes))
  } > FLASH :text
```

Places all executable code (`.text` sections from all object files) and read-only data (`.rodata`) into flash.  The wildcard `*(.text*)` matches `.text`, `.text.Button_Init`, etc.

`.ARM.attributes` contains the build attributes (CPU type, floating-point ABI) used by debuggers and analysis tools.

#### Stack Symbols

```
  __StackTop   = ORIGIN(RAM) + LENGTH(RAM);      /* 0x20080000 */
  __StackLimit = __StackTop - __STACK_SIZE;
  __stack      = __StackTop;
```

Defines symbols for the stack boundaries.  These are not used by our code directly — our constants.s defines `STACK_TOP` and `STACK_LIMIT` separately.  These linker symbols provide a standard interface for debuggers and runtime libraries.

#### Stack Section

```
  .stack (NOLOAD) : { . = ALIGN(8); } > RAM
```

Reserves space in RAM for the stack.  `NOLOAD` means this section is not initialized from flash — the stack starts as whatever random values are in SRAM at power-on.

#### Vector Table Symbol

```
  PROVIDE(__Vectors = ADDR(.vectors));
```

Creates a global symbol pointing to the vector table.  `PROVIDE` means the symbol is only created if no other file defines it.

## Section Layout in Flash

```
  0x10000000  +------------------+
              | .embedded_block  |  IMAGE_DEF (image_def.s)
              | (32 bytes)       |
              +------------------+
  0x10000080  | .vectors         |  Vector table (vector_table.s)
              | (8 bytes)        |  STACK_TOP + Reset_Handler+1
              +------------------+
  0x10000088  | .text            |  All code + rodata
              |                  |  reset_handler.s
              |                  |  stack.s
              |                  |  xosc.s
              |                  |  reset.s
              |                  |  coprocessor.s
              |                  |  gpio.s
              |                  |  button.s
              |                  |  delay.s
              |                  |  main.s
              |                  |  literal pools
              +------------------+
```

## Summary

- The linker script maps sections to physical memory addresses.
- IMAGE_DEF goes first at 0x10000000 so the boot ROM finds it.
- The vector table is 128-byte aligned and must be in the first 4 KB of flash.
- All code lives in flash (XIP) — the processor executes directly from there.
- The stack is in SRAM, growing downward from 0x20080000.
- `KEEP()` prevents the linker from removing sections that no code references but hardware requires.
