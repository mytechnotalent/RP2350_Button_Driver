# Chapter 17: Memory-Mapped I/O

## Introduction

The RP2350 does not have special I/O instructions.  Instead, hardware peripherals are controlled by reading and writing ordinary memory addresses.  This is **memory-mapped I/O** (MMIO): the processor uses the same `ldr` and `str` instructions for both RAM and peripheral registers.  This chapter explains how MMIO works and connects it to every peripheral access in our button driver.

## The RP2350 Address Space

The Cortex-M33 has a 32-bit address space (4 GB).  The RP2350 maps different hardware to different address ranges:

| Base Address | Range | Peripheral |
|-------------|-------|------------|
| 0x10000000 | 32 MB | XIP (Flash via cache) |
| 0x20000000 | 512 KB | SRAM |
| 0x40010000 | — | CLOCKS |
| 0x40020000 | — | RESETS |
| 0x40028000 | — | IO_BANK0 (GPIO function select) |
| 0x40038000 | — | PADS_BANK0 (GPIO pad control) |
| 0x40048000 | — | XOSC |
| 0xE0000000 | — | PPB (Private Peripheral Bus: CPACR, NVIC) |

When our code executes `str r5, [r4]` with r4 = `0x40038040`, the processor does not write to RAM — it writes to the GPIO15 pad control register in the PADS_BANK0 peripheral.

## How Peripherals Respond to Writes

When the bus delivers a write to a peripheral address, the hardware:

1. Latches the data value from the bus
2. Decodes which internal register is being written (based on the offset within the peripheral)
3. Acts on the new value — changes GPIO configuration, sets a clock source, clears a reset, etc.

For example, writing to `PADS_BANK0_BASE + 0x40` with bit 6 set enables the GPIO15 input receiver.  The pad hardware immediately begins routing the external pin voltage to the GPIO input logic.

## How Peripherals Respond to Reads

When the bus delivers a read from a peripheral address, the hardware:

1. Decodes which internal register is being read
2. Returns the register's current value
3. Some registers are **read-clear** (reading them has a side effect)

```asm
  ldr   r1, [r0]                                 // read RESETS->RESET_DONE value
  tst   r1, #(1<<6)                              // test IO_BANK0 reset done
```

The RESETS_RESET_DONE register returns a bitmap showing which subsystems have completed their reset.  Reading it does not modify it — this is a status register.

## Constants as Address Guides

Our constants.s file provides symbolic names for every peripheral address:

```asm
.equ XOSC_BASE,                   0x40048000
.equ XOSC_CTRL,                   XOSC_BASE + 0x00
.equ XOSC_STATUS,                 XOSC_BASE + 0x04
.equ XOSC_STARTUP,                XOSC_BASE + 0x0c
```

Each peripheral has a base address, and each register within the peripheral is at a fixed offset from that base.  The offsets come from the RP2350 datasheet.

For GPIO configuration, we use a base-plus-offset pattern:

```asm
.equ PADS_BANK0_BASE,             0x40038000
.equ PADS_BANK0_GPIO15_OFFSET,    0x40
.equ PADS_BANK0_GPIO16_OFFSET,    0x44
```

GPIO15's pad register is at `0x40038000 + 0x40 = 0x40038040`.
GPIO16's pad register is at `0x40038000 + 0x44 = 0x40038044`.

## The MMIO Access Pattern

Every peripheral interaction in our driver follows this pattern:

### Direct Write (No Read-Modify-Write)

When we know the entire register value:

```asm
  ldr   r0, =XOSC_STARTUP                        // load peripheral address
  ldr   r1, =0x00c4                              // value to write
  str   r1, [r0]                                 // write to peripheral
```

### Read-Modify-Write

When we need to change specific bits:

```asm
  ldr   r0, =RESETS_RESET                        // load peripheral address
  ldr   r1, [r0]                                 // READ current value
  bic   r1, r1, #(1<<6)                          // MODIFY: clear IO_BANK0 bit
  str   r1, [r0]                                 // WRITE modified value back
```

### Poll Loop

When we need to wait for hardware to be ready:

```asm
.Init_XOSC_Wait:
  ldr   r0, =XOSC_STATUS                         // load status register address
  ldr   r1, [r0]                                 // read status
  tst   r1, #(1<<31)                             // test ready bit
  beq   .Init_XOSC_Wait                          // loop until ready
```

## The Coprocessor Exception

The GPIO SIO (Single-cycle I/O) block on the RP2350 is not accessed through normal MMIO.  Instead, it uses the ARM coprocessor interface:

```asm
  mcrr  p0, #4, r0, r4, c0                       // set GPIO output via coprocessor
  mrc   p0, #0, r4, c0, c8                       // read GPIO inputs via coprocessor
```

These instructions bypass the AHB/APB bus and communicate directly with the GPIO hardware through the coprocessor port.  This provides single-cycle access — faster than the 2+ cycles required for a bus transaction.

However, to use the coprocessor interface, we must first enable it through a normal MMIO write to the CPACR:

```asm
  ldr   r0, =CPACR                               // 0xE000ED88
  ldr   r1, [r0]                                 // read CPACR
  orr   r1, r1, #(1<<1)                          // enable CP0
  orr   r1, r1, #(1<<0)                          // enable CP0
  str   r1, [r0]                                 // write CPACR
```

The CPACR itself is a memory-mapped register in the PPB (Private Peripheral Bus) at 0xE000ED88.

## Volatile Access

In C, peripheral registers would be declared `volatile` to prevent the compiler from optimizing away reads or reordering accesses.  In assembly, every `ldr` and `str` executes exactly as written — there is no optimizer to worry about.  This is one advantage of writing drivers in assembly.

The `dsb` (Data Synchronization Barrier) and `isb` (Instruction Synchronization Barrier) in coprocessor.s ensure that the CPACR write takes effect before any coprocessor instruction executes:

```asm
  str   r1, [r0]                                 // store value into CPACR
  dsb                                            // ensure write completes
  isb                                            // flush pipeline
```

## Summary

- Memory-mapped I/O means reading and writing peripheral registers with the same `ldr`/`str` instructions used for RAM.
- The RP2350 maps peripherals into the 0x40000000–0x5FFFFFFF range (and PPB at 0xE0000000).
- Every peripheral register has a base address plus an offset defined in constants.s.
- Three access patterns: direct write, read-modify-write, and poll loop.
- The GPIO SIO block uses coprocessor instructions (`mcrr`/`mrc`) for single-cycle access, but enabling the coprocessor itself requires an MMIO write to CPACR.
- Assembly provides naturally volatile access — no compiler reordering to worry about.
