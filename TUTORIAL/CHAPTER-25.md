# Chapter 25: Oscillator Init — xosc.s

## Introduction

Before any peripheral can operate reliably, the system needs a stable clock.  The RP2350 starts on an internal ring oscillator (~6.5 MHz, imprecise) and our code switches to the external crystal oscillator (XOSC, ~14.5 MHz, precise).  This chapter walks through every line of xosc.s.

## The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

.global Init_XOSC
.type Init_XOSC, %function
Init_XOSC:
  ldr   r0, =XOSC_STARTUP                        // load XOSC_STARTUP address
  ldr   r1, =0x00c4                              // set delay 50,000 cycles
  str   r1, [r0]                                 // store value into XOSC_STARTUP
  ldr   r0, =XOSC_CTRL                           // load XOSC_CTRL address
  ldr   r1, =0x00FABAA0                          // set 1_15MHz, freq range, actual 14.5MHz
  str   r1, [r0]                                 // store value into XOSC_CTRL
.Init_XOSC_Wait:
  ldr   r0, =XOSC_STATUS                         // load XOSC_STATUS address
  ldr   r1, [r0]                                 // read XOSC_STATUS value
  tst   r1, #(1<<31)                             // test STABLE bit
  beq   .Init_XOSC_Wait                          // wait until stable bit is set
  bx    lr                                       // return

.global Enable_XOSC_Peri_Clock
.type Enable_XOSC_Peri_Clock, %function
Enable_XOSC_Peri_Clock:
  ldr   r0, =CLK_PERI_CTRL                       // load CLK_PERI_CTRL address
  ldr   r1, [r0]                                 // read CLK_PERI_CTRL value
  orr   r1, r1, #(1<<11)                         // set ENABLE bit
  orr   r1, r1, #(4<<5)                          // set AUXSRC: XOSC_CLKSRC bit
  str   r1, [r0]                                 // store value into CLK_PERI_CTRL
  bx    lr                                       // return
```

## Init_XOSC — Line-by-Line

### Configure Startup Delay

```asm
  ldr   r0, =XOSC_STARTUP                        // load XOSC_STARTUP address
```

Loads the address of XOSC_STARTUP (0x4004800C) into r0.  This register controls how many clock cycles the oscillator waits before declaring itself stable.

```asm
  ldr   r1, =0x00c4                              // set delay 50,000 cycles
```

Loads the startup delay value 0xC4 (196 decimal) into r1.  The XOSC_STARTUP register multiplies this by 256, giving ~50,000 reference clock cycles — enough time for the crystal to stabilize.

```asm
  str   r1, [r0]                                 // store value into XOSC_STARTUP
```

Writes the delay value to the XOSC_STARTUP register.

### Configure and Enable

```asm
  ldr   r0, =XOSC_CTRL                           // load XOSC_CTRL address
```

Loads the address of XOSC_CTRL (0x40048000) into r0.

```asm
  ldr   r1, =0x00FABAA0                          // set 1_15MHz, freq range, actual 14.5MHz
```

Loads the control value into r1.  This 32-bit value encodes two fields:

| Field | Bits | Value | Meaning |
|-------|------|-------|---------|
| FREQ_RANGE | [11:0] | 0xAA0 | 1–15 MHz crystal range |
| ENABLE | [23:12] | 0xFAB | Magic enable value |

The RP2350 datasheet specifies `0xFAB` as the enable key — writing any other value disables the oscillator.

```asm
  str   r1, [r0]                                 // store value into XOSC_CTRL
```

Writes to XOSC_CTRL.  The crystal oscillator begins its startup sequence.

### Wait for Stability

```asm
.Init_XOSC_Wait:
  ldr   r0, =XOSC_STATUS                         // load XOSC_STATUS address
```

Loads the address of XOSC_STATUS (0x40048004) into r0.

```asm
  ldr   r1, [r0]                                 // read XOSC_STATUS value
```

Reads the current status of the crystal oscillator.

```asm
  tst   r1, #(1<<31)                             // test STABLE bit
```

Tests bit 31 of the status register.  `tst` performs AND and updates the Z flag:
- Bit 31 = 0: Z=1, oscillator not yet stable
- Bit 31 = 1: Z=0, oscillator stable

```asm
  beq   .Init_XOSC_Wait                          // wait until stable bit is set
```

If Z=1 (not stable), branch back to read the status again.  This busy-wait loop typically executes for a few hundred iterations while the crystal stabilizes.

```asm
  bx    lr                                       // return
```

The oscillator is stable.  Returns to Reset_Handler.

## Enable_XOSC_Peri_Clock — Line-by-Line

```asm
  ldr   r0, =CLK_PERI_CTRL                       // load CLK_PERI_CTRL address
```

Loads the address of CLK_PERI_CTRL (0x40010048).

```asm
  ldr   r1, [r0]                                 // read CLK_PERI_CTRL value
```

Reads the current peripheral clock configuration.

```asm
  orr   r1, r1, #(1<<11)                         // set ENABLE bit
```

Sets bit 11, which enables the peripheral clock.  Without this, GPIO and other peripherals have no clock and cannot operate.

```asm
  orr   r1, r1, #(4<<5)                          // set AUXSRC: XOSC_CLKSRC bit
```

Sets bits [7:5] to 4 (binary 100), selecting XOSC as the auxiliary clock source.  The `(4<<5)` expression shifts the value 4 left by 5 positions, producing 0x80.

The AUXSRC field options:
| Value | Source |
|-------|--------|
| 0 | CLK_SYS |
| 1 | PLL_SYS |
| 2 | PLL_USB |
| 3 | ROSC_CLKSRC_PH |
| 4 | XOSC_CLKSRC |

We select XOSC (4) for a stable, precise peripheral clock.

```asm
  str   r1, [r0]                                 // store value into CLK_PERI_CTRL
```

Writes the updated configuration.  The peripheral clock is now running from XOSC.

```asm
  bx    lr                                       // return
```

Returns to Reset_Handler.

## Both Functions Are Leaf Functions

Neither Init_XOSC nor Enable_XOSC_Peri_Clock calls any other function (no `bl` instructions).  They use only r0 and r1, which are caller-saved registers.  Therefore, neither function needs push/pop.

## Timing

The Init_XOSC wait loop is the longest operation in the boot sequence.  At the ring oscillator speed (~6.5 MHz), the 50,000-cycle startup delay takes approximately:

$$\frac{50{,}000}{6{,}500{,}000} \approx 7.7 \text{ ms}$$

After the XOSC is stable, the system runs at ~14.5 MHz, making all subsequent operations faster.

## Summary

- Init_XOSC configures the crystal oscillator startup delay and frequency range, then polls until stable.
- Enable_XOSC_Peri_Clock routes the XOSC to the peripheral clock and enables it.
- The startup delay of ~7.7 ms is the longest wait in the boot sequence.
- XOSC_CTRL uses a magic enable key (0xFAB) — the datasheet specifies this exact value.
- Both functions are leaf functions using only caller-saved registers (r0, r1).
