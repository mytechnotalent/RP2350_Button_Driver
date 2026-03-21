# Chapter 22: Constants File — constants.s

## Introduction

Every source file in the project includes constants.s via `.include "constants.s"`.  This file defines all memory-mapped peripheral addresses and hardware constants as symbolic names.  This chapter explains every constant and shows where it is used.

## The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.equ STACK_TOP,                   0x20082000
.equ STACK_LIMIT,                 0x2007a000
.equ XOSC_BASE,                   0x40048000
.equ XOSC_CTRL,                   XOSC_BASE + 0x00
.equ XOSC_STATUS,                 XOSC_BASE + 0x04
.equ XOSC_STARTUP,                XOSC_BASE + 0x0c
.equ PPB_BASE,                    0xe0000000
.equ CPACR,                       PPB_BASE + 0x0ed88
.equ CLOCKS_BASE,                 0x40010000
.equ CLK_PERI_CTRL,               CLOCKS_BASE + 0x48
.equ RESETS_BASE,                 0x40020000
.equ RESETS_RESET,                RESETS_BASE + 0x0
.equ RESETS_RESET_CLEAR,          RESETS_BASE + 0x3000
.equ RESETS_RESET_DONE,           RESETS_BASE + 0x8
.equ IO_BANK0_BASE,               0x40028000
.equ IO_BANK0_GPIO15_CTRL_OFFSET, 0x7c
.equ IO_BANK0_GPIO16_CTRL_OFFSET, 0x84
.equ PADS_BANK0_BASE,             0x40038000
.equ PADS_BANK0_GPIO15_OFFSET,    0x40
.equ PADS_BANK0_GPIO16_OFFSET,    0x44
```

## Line-by-Line Walkthrough

### Assembler Configuration

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set
```

These three directives are included because constants.s is textually inserted into every source file.  They ensure the assembler is configured correctly regardless of which file includes them.

### Stack Constants

```asm
.equ STACK_TOP,                   0x20082000
```

The stack grows downward from this address.  This is the top of a 32 KB region at the end of SRAM.

**Used in:** stack.s (`ldr r0, =STACK_TOP`), vector_table.s (`.word STACK_TOP`)

**Value derivation:** SRAM ends at 0x20000000 + 512K = 0x20080000.  Adding 8K (0x2000) as a safety margin gives 0x20082000.

```asm
.equ STACK_LIMIT,                 0x2007a000
```

The lowest address the stack should reach.  If the stack grows past this, a stack overflow has occurred.

**Used in:** stack.s (`ldr r0, =STACK_LIMIT`)

**Value derivation:** 0x20082000 - 32K = 0x20082000 - 0x8000 = 0x2007A000.

### XOSC Constants

```asm
.equ XOSC_BASE,                   0x40048000
```

Base address of the External Crystal Oscillator peripheral.

```asm
.equ XOSC_CTRL,                   XOSC_BASE + 0x00
```

XOSC control register.  Offset 0x00 from base.

**Used in:** xosc.s — writes frequency range and enable bits.

```asm
.equ XOSC_STATUS,                 XOSC_BASE + 0x04
```

XOSC status register.  Offset 0x04 from base.

**Used in:** xosc.s — polls bit 31 (STABLE) in the wait loop.

```asm
.equ XOSC_STARTUP,                XOSC_BASE + 0x0c
```

XOSC startup delay register.  Offset 0x0c from base.

**Used in:** xosc.s — writes the startup delay count (0x00c4 = 196 cycles).

### Coprocessor Access Control

```asm
.equ PPB_BASE,                    0xe0000000
```

Private Peripheral Bus base.  This region contains Cortex-M33 system registers.

```asm
.equ CPACR,                       PPB_BASE + 0x0ed88
```

Coprocessor Access Control Register at 0xE000ED88.

**Used in:** coprocessor.s — enables CP0 (GPIO coprocessor) access.

### Clock Constants

```asm
.equ CLOCKS_BASE,                 0x40010000
```

Base address of the Clocks peripheral.

```asm
.equ CLK_PERI_CTRL,               CLOCKS_BASE + 0x48
```

Peripheral clock control register at 0x40010048.

**Used in:** xosc.s — sets XOSC as the peripheral clock source.

### Reset Constants

```asm
.equ RESETS_BASE,                 0x40020000
```

Base address of the Reset controller.

```asm
.equ RESETS_RESET,                RESETS_BASE + 0x0
```

Reset register at 0x40020000.  Each bit controls one subsystem's reset state.

**Used in:** reset.s — clears the IO_BANK0 reset bit (bit 6).

```asm
.equ RESETS_RESET_CLEAR,          RESETS_BASE + 0x3000
```

Atomic clear alias for the reset register at 0x40023000.  Writing a 1 to a bit clears it without affecting other bits.

**Note:** This constant is defined but not currently used in our driver.  The current code uses a read-modify-write pattern with `bic` instead.

```asm
.equ RESETS_RESET_DONE,           RESETS_BASE + 0x8
```

Reset done register at 0x40020008.  Each bit indicates whether the corresponding subsystem has finished its reset sequence.

**Used in:** reset.s — polls bit 6 (IO_BANK0 reset done).

### GPIO Control Constants

```asm
.equ IO_BANK0_BASE,               0x40028000
```

Base address of the IO_BANK0 peripheral (GPIO function select registers).

```asm
.equ IO_BANK0_GPIO15_CTRL_OFFSET, 0x7c
```

GPIO15 control register offset.  The absolute address is 0x40028000 + 0x7c = 0x4002807C.

**Used in:** button.s — sets FUNCSEL=5 for GPIO15 (SIO function).

```asm
.equ IO_BANK0_GPIO16_CTRL_OFFSET, 0x84
```

GPIO16 control register offset.  The absolute address is 0x40028000 + 0x84 = 0x40028084.

**Used in:** main.s — passed to GPIO_Config as argument r1.

### GPIO Pad Constants

```asm
.equ PADS_BANK0_BASE,             0x40038000
```

Base address of the PADS_BANK0 peripheral (GPIO electrical configuration).

```asm
.equ PADS_BANK0_GPIO15_OFFSET,    0x40
```

GPIO15 pad register offset.  Absolute address: 0x40038000 + 0x40 = 0x40038040.

**Used in:** button.s — configures GPIO15 as input with pull-up.

```asm
.equ PADS_BANK0_GPIO16_OFFSET,    0x44
```

GPIO16 pad register offset.  Absolute address: 0x40038000 + 0x44 = 0x40038044.

**Used in:** main.s — passed to GPIO_Config as argument r0.

## Cross-Reference Table

| Constant | Address | Used By |
|----------|---------|---------|
| `STACK_TOP` | 0x20082000 | stack.s, vector_table.s |
| `STACK_LIMIT` | 0x2007A000 | stack.s |
| `XOSC_CTRL` | 0x40048000 | xosc.s |
| `XOSC_STATUS` | 0x40048004 | xosc.s |
| `XOSC_STARTUP` | 0x4004800C | xosc.s |
| `CPACR` | 0xE000ED88 | coprocessor.s |
| `CLK_PERI_CTRL` | 0x40010048 | xosc.s |
| `RESETS_RESET` | 0x40020000 | reset.s |
| `RESETS_RESET_DONE` | 0x40020008 | reset.s |
| `IO_BANK0_BASE` | 0x40028000 | gpio.s, button.s |
| `IO_BANK0_GPIO15_CTRL_OFFSET` | 0x7C | button.s |
| `IO_BANK0_GPIO16_CTRL_OFFSET` | 0x84 | main.s |
| `PADS_BANK0_BASE` | 0x40038000 | gpio.s, button.s |
| `PADS_BANK0_GPIO15_OFFSET` | 0x40 | button.s |
| `PADS_BANK0_GPIO16_OFFSET` | 0x44 | main.s |

## Summary

- constants.s is a shared header file included by every source file.
- Every hardware address comes from the RP2350 datasheet, expressed as base + offset.
- The `.equ` directive creates assembler-time constants — they generate no machine code.
- GPIO15 (button) and GPIO16 (LED) each have two constants: one for pad control, one for function select.
- Centralizing all addresses in one file makes it easy to port the driver to a different pin assignment.
