# Chapter 18: The RP2350 — Architecture and Hardware

## Introduction

The previous chapters covered generic ARM Cortex-M33 concepts.  This chapter focuses on the RP2350 itself: the chip we target, its block diagram, the peripherals we use, and how the boot process works.

## RP2350 Overview

The RP2350 is Raspberry Pi's second-generation microcontroller.  Key specifications:

| Feature | Value |
|---------|-------|
| Cores | Dual ARM Cortex-M33 (or dual Hazard3 RISC-V) |
| Default Clock | ~150 MHz (after PLL configuration) |
| Ring Oscillator | ~14.5 MHz (boot default, used by our driver) |
| Flash | External QSPI (via XIP at 0x10000000) |
| SRAM | 520 KB (at 0x20000000) |
| GPIO Pins | 48 total (30 user-accessible on typical boards) |
| Package | QFN-60 or QFN-80 |

Our button driver uses a single Cortex-M33 core running at the ring oscillator's ~14.5 MHz, which is sufficient for button monitoring without PLL setup.

## Block Diagram

```
+--------------------------------------------------+
|                    RP2350                         |
|                                                  |
|  +----------+  +----------+                      |
|  | Cortex-  |  | Cortex-  |                      |
|  | M33      |  | M33      |                      |
|  | Core 0   |  | Core 1   |                      |
|  +----+-----+  +----------+                      |
|       |                                          |
|       | AHB-Lite Bus                             |
|  +----+------------------------------------------+
|  |    |                                          |
|  |  +-+--------+  +---------+  +----------+     |
|  |  | XIP      |  | SRAM    |  | Boot ROM |     |
|  |  | (Flash)  |  | 520KB   |  |          |     |
|  |  +----------+  +---------+  +----------+     |
|  |                                               |
|  |  APB Bus                                      |
|  |  +---------+  +---------+  +----------+      |
|  |  | XOSC    |  | CLOCKS  |  | RESETS   |      |
|  |  +---------+  +---------+  +----------+      |
|  |                                               |
|  |  +---------+  +---------+  +----------+      |
|  |  | IO_BANK |  | PADS    |  | SIO/GPIO |      |
|  |  | (CTRL)  |  | BANK0   |  | (CP0)    |      |
|  |  +---------+  +---------+  +----------+      |
|  |                                               |
+--+-----------------------------------------------+
        |           |
      GPIO15      GPIO16
      (Button)    (LED)
```

Our driver only uses Core 0.  Core 1 remains in its default reset state.

## Peripherals Used by Our Driver

### XOSC (External Crystal Oscillator)

- Base: 0x40048000
- Provides a stable 14.5 MHz clock from an external crystal
- Must be configured before GPIO timing is reliable
- Registers: CTRL (configuration), STATUS (ready polling), STARTUP (delay count)

### CLOCKS

- Base: 0x40010000
- Routes clock sources to peripherals
- We configure CLK_PERI_CTRL to use XOSC as the peripheral clock source

### RESETS

- Base: 0x40020000
- Controls reset state of all peripherals
- We clear the IO_BANK0 reset bit to enable GPIO
- Must poll RESET_DONE to confirm the reset is complete

### PADS_BANK0

- Base: 0x40038000
- Controls the electrical properties of each GPIO pad
- For GPIO15 (button): enable input, enable pull-up, disable output driver
- For GPIO16 (LED): enable input, disable output driver (OE controlled via SIO)

### IO_BANK0

- Base: 0x40028000
- Controls the function multiplexer for each GPIO pin
- FUNCSEL=5 routes the pin to SIO (Single-cycle I/O)

### SIO (Single-cycle I/O) / Coprocessor 0

- Accessed via coprocessor instructions, not memory-mapped
- Provides fast GPIO output set/clear and input read
- Must enable CP0 in CPACR before use

## The GPIO System

GPIO pins on the RP2350 have three layers of configuration:

```
+--------+     +--------+     +--------+
|  PAD   | --> | IO_BANK| --> |  SIO   |
| (elec) |     | (func) |     | (I/O)  |
+--------+     +--------+     +--------+
```

1. **PAD** (PADS_BANK0): Electrical characteristics — input enable, pull-up/down, drive strength, slew rate
2. **IO_BANK** (IO_BANK0): Function select — which internal peripheral drives the pin
3. **SIO** (Coprocessor 0): Actual I/O — read input state, drive output high/low

For our button on GPIO15:
- PAD: IE=1, PUE=1, PDE=0, OD=1 (input with pull-up)
- IO_BANK: FUNCSEL=5 (SIO)
- SIO: Output enable=0 (input only), read via `mrc p0`

For our LED on GPIO16:
- PAD: IE=1, OD=0, ISO=0
- IO_BANK: FUNCSEL=5 (SIO)
- SIO: Output enable=1, set/clear via `mcrr p0`

## Boot Process

When power is applied, the RP2350 executes the following sequence:

1. **Boot ROM** runs from internal mask ROM
2. Boot ROM scans flash for a valid IMAGE_DEF block (our image_def.s)
3. Boot ROM performs XIP (Execute-in-Place) setup for the flash
4. Boot ROM reads the vector table from flash
5. **MSP** is loaded from the first word of the vector table (STACK_TOP)
6. **PC** is loaded from the second word (Reset_Handler + 1)
7. Execution begins at Reset_Handler in Thumb state

Our Reset_Handler then:
- Initializes MSP/PSP and stack limits (stack.s)
- Configures the XOSC (xosc.s)
- Enables the peripheral clock (xosc.s)
- Releases IO_BANK0 from reset (reset.s)
- Enables coprocessor 0 (coprocessor.s)
- Branches to main (main.s)

## Dual-Core and Security

The RP2350 supports dual-core operation and TrustZone security.  Our application:
- Runs on Core 0 only (Core 1 stays in reset)
- Runs in Secure mode (set by IMAGE_DEF: `0b0001000000100001`)
- Does not use interrupts (polling loop instead)

This is the simplest possible configuration — no RTOS, no interrupts, no Core 1, single security domain.

## Summary

- The RP2350 has dual Cortex-M33 cores; we use Core 0 at ~14.5 MHz from the ring oscillator.
- Six peripherals are involved: XOSC, CLOCKS, RESETS, PADS_BANK0, IO_BANK0, and SIO (CP0).
- GPIO configuration has three layers: pad electrical, function select, and SIO I/O.
- GPIO15 is configured as an input with pull-up (button), GPIO16 as an output (LED).
- The boot ROM reads our IMAGE_DEF block and vector table from flash to start execution.
- We run in the simplest mode: single-core, Secure, no interrupts, no PLL.
