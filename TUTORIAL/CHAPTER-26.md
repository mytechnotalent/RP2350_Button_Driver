# Chapter 26: Reset Controller — reset.s

## Introduction

Peripherals on the RP2350 start in a reset state after power-on.  Before we can configure GPIO pins, the IO_BANK0 subsystem must be brought out of reset.  This chapter walks through every line of reset.s.

## The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

.global Init_Subsystem
.type Init_Subsystem, %function
Init_Subsystem:
.GPIO_Subsystem_Reset:
  ldr   r0, =RESETS_RESET                        // load RESETS->RESET address
  ldr   r1, [r0]                                 // read RESETS->RESET value
  bic   r1, r1, #(1<<6)                          // clear IO_BANK0 bit
  str   r1, [r0]                                 // store value into RESETS->RESET address
.GPIO_Subsystem_Reset_Wait:
  ldr   r0, =RESETS_RESET_DONE                   // load RESETS->RESET_DONE address
  ldr   r1, [r0]                                 // read RESETS->RESET_DONE value
  tst   r1, #(1<<6)                              // test IO_BANK0 reset done
  beq   .GPIO_Subsystem_Reset_Wait               // wait until done
  bx    lr                                       // return
```

## Line-by-Line Walkthrough

### Function Declaration

```asm
.global Init_Subsystem
.type Init_Subsystem, %function
```

Exports `Init_Subsystem` as a function.  Called from reset_handler.s after the clocks are configured.

### Clear the Reset Bit

```asm
.GPIO_Subsystem_Reset:
  ldr   r0, =RESETS_RESET                        // load RESETS->RESET address
```

Loads the address of the RESETS_RESET register (0x40020000).  This register has one bit per peripheral subsystem.  When a bit is 1, that subsystem is held in reset.

```asm
  ldr   r1, [r0]                                 // read RESETS->RESET value
```

Reads the current reset state.  After power-on, most bits are 1 (peripherals in reset).

```asm
  bic   r1, r1, #(1<<6)                          // clear IO_BANK0 bit
```

Clears bit 6, which controls the IO_BANK0 subsystem.  Clearing a reset bit tells the hardware to bring that subsystem out of reset.

The RESETS register bit assignments (relevant bits):

| Bit | Subsystem |
|-----|-----------|
| 0 | ADC |
| 5 | IO_BANK0 (on some revisions) |
| 6 | IO_BANK0 |
| 8 | PADS_BANK0 |
| 11 | PIO0 |
| 22 | UART0 |

Only bit 6 is cleared — all other subsystems remain in reset.  This is the minimum required for GPIO operation.

```asm
  str   r1, [r0]                                 // store value into RESETS->RESET address
```

Writes the modified value back.  The hardware begins the IO_BANK0 de-reset sequence.

### Wait for Reset Complete

```asm
.GPIO_Subsystem_Reset_Wait:
  ldr   r0, =RESETS_RESET_DONE                   // load RESETS->RESET_DONE address
```

Loads the address of RESETS_RESET_DONE (0x40020008).  This read-only register mirrors the reset state: a bit is 1 when the corresponding subsystem has completed its reset release sequence.

```asm
  ldr   r1, [r0]                                 // read RESETS->RESET_DONE value
```

Reads the current reset-done status.

```asm
  tst   r1, #(1<<6)                              // test IO_BANK0 reset done
```

Tests bit 6 of RESET_DONE:
- Bit 6 = 0: IO_BANK0 is still resetting, Z=1
- Bit 6 = 1: IO_BANK0 is ready, Z=0

```asm
  beq   .GPIO_Subsystem_Reset_Wait               // wait until done
```

If Z=1 (not done), loop back and check again.  The de-reset process takes a few clock cycles.

```asm
  bx    lr                                       // return
```

IO_BANK0 is now operational.  Returns to Reset_Handler.

## Why This Is Necessary

Without releasing IO_BANK0 from reset:
- The GPIO function select registers (IO_BANK0_GPIO15_CTRL, IO_BANK0_GPIO16_CTRL) would be inaccessible
- Writes to these registers would be silently ignored
- GPIO15 and GPIO16 would remain in their default (non-functional) state

## The Read-Modify-Write vs. Atomic Clear

The code uses a read-modify-write pattern (ldr → bic → str).  The RP2350 also provides an atomic clear register at offset 0x3000:

```asm
.equ RESETS_RESET_CLEAR,          RESETS_BASE + 0x3000
```

Writing `(1<<6)` to RESETS_RESET_CLEAR would clear bit 6 without reading first.  Our driver defines this constant but uses the read-modify-write approach, which is equally correct in a single-core, interrupt-free environment.

## Leaf Function

Init_Subsystem uses only r0 and r1 (caller-saved), never calls `bl`, and returns with `bx lr`.  No push/pop is needed.

## Summary

- The RESETS peripheral controls which subsystems are active.
- Clearing bit 6 in RESETS_RESET releases IO_BANK0 from reset.
- The wait loop polls RESETS_RESET_DONE until the subsystem is ready.
- This step must complete before any GPIO configuration can occur.
- Init_Subsystem is a leaf function requiring no stack frame.
