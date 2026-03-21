# Chapter 27: GPIO Configuration — gpio.s

## Introduction

The GPIO driver provides three functions: `GPIO_Config` to set up a pin as a SIO-controlled output, `GPIO_Set` to drive a pin high, and `GPIO_Clear` to drive a pin low.  In our button driver, these functions control GPIO16 (the LED).  This chapter walks through every line of gpio.s.

## The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

.global GPIO_Config
.type GPIO_Config, %function
GPIO_Config:
.GPIO_Config_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.GPIO_Config_Modify_Pad:
  ldr   r4, =PADS_BANK0_BASE                     // load PADS_BANK0_BASE address
  add   r4, r4, r0                               // PADS_BANK0_BASE + PAD_OFFSET
  ldr   r5, [r4]                                 // read PAD_OFFSET value
  bic   r5, r5, #(1<<7)                          // clear OD bit
  orr   r5, r5, #(1<<6)                          // set IE bit
  bic   r5, r5, #(1<<8)                          // clear ISO bit
  str   r5, [r4]                                 // store value into PAD_OFFSET
.GPIO_Config_Modify_CTRL:
  ldr   r4, =IO_BANK0_BASE                       // load IO_BANK0 base
  add   r4, r4, r1                               // IO_BANK0_BASE + CTRL_OFFSET
  ldr   r5, [r4]                                 // read CTRL_OFFSET value
  bic   r5, r5, #0x1f                            // clear FUNCSEL
  orr   r5, r5, #0x05                            // set FUNCSEL 0x05->SIO_0
  str   r5, [r4]                                 // store value into CTRL_OFFSET
.GPIO_Config_Enable_OE:
  ldr   r4, =1                                   // enable output
  mcrr  p0, #4, r2, r4, c4                       // gpioc_bit_oe_put(GPIO, 1)
.GPIO_Config_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr to the stack
  bx    lr                                       // return

.global GPIO_Set
.type GPIO_Set, %function
GPIO_Set:
.GPIO_Set_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.GPIO_Set_Execute:
  ldr   r4, =1                                   // enable output
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(GPIO, 1)
.GPIO_Set_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return

.global GPIO_Clear
.type GPIO_Clear, %function
GPIO_Clear:
.GPIO_Clear_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.GPIO_Clear_Execute:
  ldr   r4, =0                                   // disable output
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(GPIO, 1)
.GPIO_Clear_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
```

## GPIO_Config — Line-by-Line

### Parameters

| Register | Parameter | Example Value |
|----------|-----------|--------------|
| r0 | PAD_OFFSET | 0x44 (PADS_BANK0_GPIO16_OFFSET) |
| r1 | CTRL_OFFSET | 0x84 (IO_BANK0_GPIO16_CTRL_OFFSET) |
| r2 | GPIO number | 16 |

### Save Registers

```asm
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

Saves 10 registers (40 bytes) because the function uses r4 and r5 (callee-saved).

### Configure Pad

```asm
  ldr   r4, =PADS_BANK0_BASE                     // load PADS_BANK0_BASE address
  add   r4, r4, r0                               // PADS_BANK0_BASE + PAD_OFFSET
```

Computes the pad register address: 0x40038000 + 0x44 = 0x40038044 for GPIO16.

```asm
  ldr   r5, [r4]                                 // read PAD_OFFSET value
  bic   r5, r5, #(1<<7)                          // clear OD bit
  orr   r5, r5, #(1<<6)                          // set IE bit
  bic   r5, r5, #(1<<8)                          // clear ISO bit
  str   r5, [r4]                                 // store value into PAD_OFFSET
```

Read-modify-write to configure the pad:
- **OD** (bit 7) = 0: Output driver enabled
- **IE** (bit 6) = 1: Input receiver enabled (needed even for outputs — feedback path)
- **ISO** (bit 8) = 0: Pad not isolated

Note: Unlike Button_Init, GPIO_Config does not set PUE or clear PDE — the LED output does not need pull-up/pull-down resistors.

### Configure Function Select

```asm
  ldr   r4, =IO_BANK0_BASE                       // load IO_BANK0 base
  add   r4, r4, r1                               // IO_BANK0_BASE + CTRL_OFFSET
```

Computes the CTRL register address: 0x40028000 + 0x84 = 0x40028084 for GPIO16.

```asm
  ldr   r5, [r4]                                 // read CTRL_OFFSET value
  bic   r5, r5, #0x1f                            // clear FUNCSEL
  orr   r5, r5, #0x05                            // set FUNCSEL 0x05->SIO_0
  str   r5, [r4]                                 // store value into CTRL_OFFSET
```

Sets FUNCSEL to 5 (SIO).  This routes the pin to the Single-cycle I/O block, which is controlled via coprocessor instructions.

### Enable Output

```asm
  ldr   r4, =1                                   // enable output
  mcrr  p0, #4, r2, r4, c4                       // gpioc_bit_oe_put(GPIO, 1)
```

The `mcrr` (Move to Coprocessor from two Registers) instruction sends two values to coprocessor 0:

| Operand | Register | Value | Meaning |
|---------|----------|-------|---------|
| CRm | c4 | — | Output enable function |
| opc1 | #4 | — | Bit operation |
| Rt | r2 | 16 | GPIO pin number |
| Rt2 | r4 | 1 | Enable (1) or disable (0) |

This enables the output driver for GPIO16.

### Restore and Return

```asm
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr to the stack
  bx    lr                                       // return
```

Restores all callee-saved registers and returns.

## GPIO_Set — Line-by-Line

```asm
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

Saves registers.

```asm
  ldr   r4, =1                                   // enable output
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(GPIO, 1)
```

Sets the GPIO output high:

| Operand | Register | Value | Meaning |
|---------|----------|-------|---------|
| CRm | c0 | — | Output value function |
| opc1 | #4 | — | Bit operation |
| Rt | r0 | 16 | GPIO pin number |
| Rt2 | r4 | 1 | Output high |

```asm
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
```

### Parameter

| Register | Parameter |
|----------|-----------|
| r0 | GPIO number (16) |

## GPIO_Clear — Line-by-Line

```asm
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

```asm
  ldr   r4, =0                                   // disable output
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(GPIO, 1)
```

Sets the GPIO output low — same instruction as GPIO_Set but with r4 = 0 instead of 1.

```asm
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
```

## GPIO_Config vs. Button_Init

Both functions configure a GPIO pin, but for different purposes:

| Aspect | GPIO_Config (LED) | Button_Init (Button) |
|--------|-------------------|---------------------|
| Target | GPIO16 | GPIO15 |
| Direction | Output | Input |
| OE (Output Enable) | Enabled (1) | Disabled (0) |
| PUE (Pull-up) | Not set | Set |
| PDE (Pull-down) | Not changed | Cleared |
| Parameterized | Yes (r0, r1, r2) | No (hardcoded GPIO15) |

GPIO_Config is generic — it accepts pin parameters and can configure any GPIO as an output.  Button_Init is specialized for GPIO15 as an input with pull-up.

## Summary

- GPIO_Config configures a pin as a SIO-controlled output: pad settings, function select, output enable.
- GPIO_Set drives a pin high via the coprocessor interface.
- GPIO_Clear drives a pin low via the same interface.
- The `mcrr p0` instruction communicates with the GPIO coprocessor for single-cycle I/O operations.
- CRm distinguishes the function: c0 = output value, c4 = output enable.
- All three functions save and restore r4-r12 and lr.
