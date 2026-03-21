# Chapter 28: Button Driver — button.s

## Introduction

This is the chapter that distinguishes this project from a simple blink driver.  button.s provides three functions: `Button_Init` configures GPIO15 as an input with an internal pull-up resistor, `Button_Read` reads the raw button state, and `Button_IsPressed` wraps the read with active-low inversion.  This chapter walks through every line.

## The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

.global Button_Init
.type Button_Init, %function
Button_Init:
.Button_Init_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.Button_Init_Modify_Pad:
  ldr   r4, =PADS_BANK0_BASE                     // load PADS_BANK0_BASE address
  ldr   r5, =PADS_BANK0_GPIO15_OFFSET            // load GPIO15 pad offset
  add   r4, r4, r5                               // PADS_BANK0_BASE + PAD_OFFSET
  ldr   r5, [r4]                                 // read PAD_OFFSET value
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
  orr   r5, r5, #(1<<3)                          // set PUE bit (pull-up enable)
  bic   r5, r5, #(1<<2)                          // clear PDE bit (pull-down disable)
  bic   r5, r5, #(1<<8)                          // clear ISO bit
  str   r5, [r4]                                 // store value into PAD_OFFSET
.Button_Init_Modify_CTRL:
  ldr   r4, =IO_BANK0_BASE                       // load IO_BANK0 base
  ldr   r5, =IO_BANK0_GPIO15_CTRL_OFFSET         // load GPIO15 ctrl offset
  add   r4, r4, r5                               // IO_BANK0_BASE + CTRL_OFFSET
  ldr   r5, [r4]                                 // read CTRL_OFFSET value
  bic   r5, r5, #0x1f                            // clear FUNCSEL
  orr   r5, r5, #0x05                            // set FUNCSEL 0x05->SIO_0
  str   r5, [r4]                                 // store value into CTRL_OFFSET
.Button_Init_Disable_OE:
  ldr   r4, =0                                   // disable output
  ldr   r5, =15                                  // GPIO15
  mcrr  p0, #4, r5, r4, c4                       // gpioc_bit_oe_put(GPIO15, 0)
.Button_Init_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return

.global Button_Read
.type Button_Read, %function
Button_Read:
.Button_Read_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.Button_Read_Execute:
  mrc   p0, #0, r4, c0, c8                       // gpioc_lo_in_get - read all lower 32 GPIO inputs
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
  and   r0, r4, #1                               // mask to get just bit 0
.Button_Read_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return

.global Button_IsPressed
.type Button_IsPressed, %function
Button_IsPressed:
.Button_IsPressed_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.Button_IsPressed_Read:
  bl    Button_Read                              // read button state
  eor   r0, r0, #1                               // invert (pressed=1, released=0)
.Button_IsPressed_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
```

## Button_Init — Line-by-Line

### Save Registers

```asm
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

Saves all callee-saved registers.  Button_Init uses r4 and r5.

### Configure the Pad Register

```asm
  ldr   r4, =PADS_BANK0_BASE                     // load PADS_BANK0_BASE address
  ldr   r5, =PADS_BANK0_GPIO15_OFFSET            // load GPIO15 pad offset
  add   r4, r4, r5                               // PADS_BANK0_BASE + PAD_OFFSET
```

Computes the GPIO15 pad register address: 0x40038000 + 0x40 = 0x40038040.

```asm
  ldr   r5, [r4]                                 // read PAD_OFFSET value
```

Reads the current pad configuration for GPIO15.

```asm
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
```

**OD (Output Disable), bit 7 → 0**: Clears the output disable bit.  Despite the name, this does not enable the output driver — the output enable is controlled separately via the SIO coprocessor.  Clearing OD ensures the pad driver is available.

```asm
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
```

**IE (Input Enable), bit 6 → 1**: Enables the input receiver.  This is the critical bit for a button — without it, the pad cannot sense the external voltage level.

```asm
  orr   r5, r5, #(1<<3)                          // set PUE bit (pull-up enable)
```

**PUE (Pull-Up Enable), bit 3 → 1**: Activates the internal pull-up resistor (~50 kΩ).  This pulls GPIO15 to 3.3V when the button is not pressed.  When the button is pressed, it connects GPIO15 to GND through a low-impedance path, overriding the pull-up.

This is why the button is **active-low**: unpressed = high (1), pressed = low (0).

```asm
  bic   r5, r5, #(1<<2)                          // clear PDE bit (pull-down disable)
```

**PDE (Pull-Down Enable), bit 2 → 0**: Disables the pull-down resistor.  Having both pull-up and pull-down enabled simultaneously would create a voltage divider — an undefined state.

```asm
  bic   r5, r5, #(1<<8)                          // clear ISO bit
```

**ISO (Isolation), bit 8 → 0**: Connects the pad to the internal logic.  After reset, some pads may be isolated for power savings.

```asm
  str   r5, [r4]                                 // store value into PAD_OFFSET
```

Writes the modified pad configuration back.  GPIO15's pad is now configured for input with pull-up.

### Configure Function Select

```asm
  ldr   r4, =IO_BANK0_BASE                       // load IO_BANK0 base
  ldr   r5, =IO_BANK0_GPIO15_CTRL_OFFSET         // load GPIO15 ctrl offset
  add   r4, r4, r5                               // IO_BANK0_BASE + CTRL_OFFSET
```

Computes the GPIO15 CTRL register address: 0x40028000 + 0x7C = 0x4002807C.

```asm
  ldr   r5, [r4]                                 // read CTRL_OFFSET value
  bic   r5, r5, #0x1f                            // clear FUNCSEL
  orr   r5, r5, #0x05                            // set FUNCSEL 0x05->SIO_0
  str   r5, [r4]                                 // store value into CTRL_OFFSET
```

Sets FUNCSEL to 5 (SIO), the same function used for all GPIO I/O in this driver.  This routes GPIO15 to the SIO block where the coprocessor can read its input state.

### Disable Output Enable

```asm
  ldr   r4, =0                                   // disable output
  ldr   r5, =15                                  // GPIO15
  mcrr  p0, #4, r5, r4, c4                       // gpioc_bit_oe_put(GPIO15, 0)
```

Explicitly disables the output driver for GPIO15 via the coprocessor:

| Operand | Register | Value | Meaning |
|---------|----------|-------|---------|
| CRm | c4 | — | Output enable function |
| opc1 | #4 | — | Bit operation |
| Rt | r5 | 15 | GPIO15 |
| Rt2 | r4 | 0 | Disable output |

This ensures GPIO15 is input-only — the SIO block will not drive this pin.

### Restore and Return

```asm
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
```

## Button_Read — Line-by-Line

### Save Registers

```asm
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

Saves callee-saved registers.  Button_Read uses r4.

### Read GPIO Inputs

```asm
  mrc   p0, #0, r4, c0, c8                       // gpioc_lo_in_get - read all lower 32 GPIO inputs
```

The `mrc` (Move to Register from Coprocessor) instruction reads from coprocessor 0:

| Operand | Value | Meaning |
|---------|-------|---------|
| coproc | p0 | GPIO coprocessor |
| opc1 | #0 | Read operation |
| Rt | r4 | Destination register |
| CRn | c0 | GPIO function group |
| CRm | c8 | Input read function |

This returns a 32-bit value where each bit represents the current input level of one GPIO pin.  Bit 0 = GPIO0, bit 1 = GPIO1, ..., bit 15 = GPIO15, ..., bit 31 = GPIO31.

### Extract GPIO15's Bit

```asm
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
```

Shifts all bits right by 15 positions.  GPIO15's state moves from bit 15 to bit 0.  All bits above GPIO15 shift down correspondingly.

```asm
  and   r0, r4, #1                               // mask to get just bit 0
```

Masks off all bits except bit 0, giving a clean 0 or 1 result.

**Result:**
- r0 = 0: GPIO15 is low (button pressed — connected to GND)
- r0 = 1: GPIO15 is high (button released — pulled up to 3.3V)

### Restore and Return

```asm
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
```

The return value is in r0, following the AAPCS calling convention.

## Button_IsPressed — Line-by-Line

### Save Registers

```asm
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

Must save lr because this function calls Button_Read with `bl`.

### Read and Invert

```asm
  bl    Button_Read                              // read button state
```

Calls Button_Read, which returns:
- r0 = 0: pressed (active-low)
- r0 = 1: released

```asm
  eor   r0, r0, #1                               // invert (pressed=1, released=0)
```

XOR with 1 inverts bit 0:
- 0 → 1: pressed becomes 1 (active-high)
- 1 → 0: released becomes 0

This provides a more intuitive API: `Button_IsPressed` returns 1 when the button is pressed.

### Restore and Return

```asm
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
```

## The Three Functions Compared

| Function | Input | Output | Calls | Purpose |
|----------|-------|--------|-------|---------|
| Button_Init | None | None | None | Configure GPIO15 as input with pull-up |
| Button_Read | None | r0 = raw state (0=pressed) | None | Read physical pin state |
| Button_IsPressed | None | r0 = logical state (1=pressed) | Button_Read | User-friendly pressed check |

## Hardware Circuit

```
     3.3V
      |
     [~50K]  <-- Internal pull-up (PUE bit)
      |
 GPIO15 ----+---- Button ---- GND
             |
        Input receiver
          (IE bit)
```

When the button is open: GPIO15 = 3.3V (high, read as 1)
When the button is pressed: GPIO15 = GND (low, read as 0)

The internal pull-up eliminates the need for an external resistor.

## mrc vs. mcrr

| Instruction | Direction | Registers | Used For |
|-------------|-----------|-----------|----------|
| `mcrr` | CPU → Coprocessor | Two registers (Rt, Rt2) | Set output, set output enable |
| `mrc` | Coprocessor → CPU | One register (Rt) | Read input state |

`mrc` reads a single 32-bit value (all GPIO inputs).  `mcrr` writes two register values (pin number and value) to the coprocessor.

## Summary

- Button_Init configures GPIO15 as an input: IE=1, PUE=1, PDE=0, OE=0, FUNCSEL=5 (SIO).
- Button_Read uses `mrc p0` to read all 32 GPIO inputs, then shifts and masks to extract GPIO15.
- Button_IsPressed wraps Button_Read with an XOR to convert active-low to active-high.
- The internal pull-up resistor eliminates the need for external hardware beyond the button and a wire to GND.
- `mrc` (read from coprocessor) is the counterpart to `mcrr` (write to coprocessor).
