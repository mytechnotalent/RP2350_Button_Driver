# Chapter 29: Application Entry Point — main.s

## Introduction

After the boot sequence completes, `Reset_Handler` branches to `main`.  This is where the application logic lives: configure GPIO16 as an LED output, initialize the button on GPIO15, and enter an infinite loop that reads the button and drives the LED accordingly.  This chapter walks through every line of main.s.

## The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

.global main                                     // export main
.type main, %function                            // mark as function
main:
.Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.GPIO16_Config:
  ldr   r0, =PADS_BANK0_GPIO16_OFFSET            // load PADS_BANK0_GPIO16_OFFSET
  ldr   r1, =IO_BANK0_GPIO16_CTRL_OFFSET         // load IO_BANK0_GPIO16_CTRL_OFFSET
  ldr   r2, =16                                  // load GPIO number
  bl    GPIO_Config                              // call GPIO_Config
.Button_Init:
  bl    Button_Init                              // initialize button on GPIO15
.Loop:
  bl    Button_Read                              // read button state (0=pressed, 1=released)
  cmp   r0, #0                                   // compare with 0 (pressed)
  beq   .Button_Pressed                          // branch if button pressed (r0==0)
.Button_Released:
  ldr   r0, =16                                  // load GPIO number
  bl    GPIO_Clear                               // turn off LED
  b     .Loop_Delay                              // continue to delay
.Button_Pressed:
  ldr   r0, =16                                  // load GPIO number
  bl    GPIO_Set                                 // turn on LED
.Loop_Delay:
  ldr   r0, =10                                  // 10ms debounce delay
  bl    Delay_MS                                 // call Delay_MS
  b     .Loop                                    // loop forever
.Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return to caller

.section .rodata                                 // read-only data section

.section .data                                   // data section

.section .bss                                    // BSS section
```

## Line-by-Line Walkthrough

### Function Declaration

```asm
.global main                                     // export main
.type main, %function                            // mark as function
```

Exports `main` so the linker resolves the `b main` in reset_handler.s.

### Save Registers

```asm
.Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

Saves all callee-saved registers plus lr.  Although main never returns in practice (the loop is infinite), the push/pop pair maintains correctness.

### Configure LED Output (GPIO16)

```asm
.GPIO16_Config:
  ldr   r0, =PADS_BANK0_GPIO16_OFFSET            // load PADS_BANK0_GPIO16_OFFSET
  ldr   r1, =IO_BANK0_GPIO16_CTRL_OFFSET         // load IO_BANK0_GPIO16_CTRL_OFFSET
  ldr   r2, =16                                  // load GPIO number
  bl    GPIO_Config                              // call GPIO_Config
```

Sets up the three arguments for GPIO_Config:
- r0 = 0x44 (GPIO16 pad register offset)
- r1 = 0x84 (GPIO16 control register offset)
- r2 = 16 (GPIO pin number)

GPIO_Config (Chapter 27) configures the pad, sets FUNCSEL=5, and enables the output driver.  After this call, GPIO16 can drive the LED.

### Initialize Button (GPIO15)

```asm
.Button_Init:
  bl    Button_Init                              // initialize button on GPIO15
```

Calls Button_Init (Chapter 28) which configures GPIO15 as an input with pull-up and disables its output driver.  After this call, GPIO15 can sense the button state.

### The Main Loop

```asm
.Loop:
  bl    Button_Read                              // read button state (0=pressed, 1=released)
```

Calls Button_Read, which returns:
- r0 = 0: button pressed (GPIO15 connected to GND)
- r0 = 1: button released (GPIO15 pulled high)

```asm
  cmp   r0, #0                                   // compare with 0 (pressed)
```

Subtracts 0 from r0 and updates the flags.  If r0 = 0, the Z flag is set.

```asm
  beq   .Button_Pressed                          // branch if button pressed (r0==0)
```

If Z=1 (r0 was 0, button pressed), jumps to `.Button_Pressed`.  Otherwise, falls through to `.Button_Released`.

### Button Released Path

```asm
.Button_Released:
  ldr   r0, =16                                  // load GPIO number
  bl    GPIO_Clear                               // turn off LED
  b     .Loop_Delay                              // continue to delay
```

When the button is released, GPIO_Clear drives GPIO16 low, turning off the LED.  The `b .Loop_Delay` skips over the pressed path.

### Button Pressed Path

```asm
.Button_Pressed:
  ldr   r0, =16                                  // load GPIO number
  bl    GPIO_Set                                 // turn on LED
```

When the button is pressed, GPIO_Set drives GPIO16 high, turning on the LED.  Execution falls through to `.Loop_Delay`.

### Debounce Delay

```asm
.Loop_Delay:
  ldr   r0, =10                                  // 10ms debounce delay
  bl    Delay_MS                                 // call Delay_MS
  b     .Loop                                    // loop forever
```

Both paths converge here.  A 10-millisecond delay serves two purposes:

1. **Debouncing**: Mechanical buttons produce electrical noise (bouncing) when pressed or released.  The contacts may open and close rapidly for several milliseconds.  The 10ms delay ensures we do not read the button during this unstable period.

2. **CPU efficiency**: Without a delay, the loop would spin as fast as possible (~14.5 million iterations per second), wasting power.  The delay reduces the polling rate to ~100 Hz, which is more than sufficient for human button interaction.

After the delay, `b .Loop` returns to the top of the loop to read the button again.

### Unreachable Exit

```asm
.Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return to caller
```

These instructions are never reached because the loop is infinite.  They exist for structural completeness — if the loop were changed to have an exit condition, the function would return correctly.

### Data Sections

```asm
.section .rodata                                 // read-only data section
.section .data                                   // data section
.section .bss                                    // BSS section
```

Three empty data sections.  They serve as placeholders for future expansion.  If the application needed read-only constants, initialized variables, or uninitialized variables, they would go here.

## Control Flow Diagram

```
        main()
          |
    GPIO_Config(GPIO16)
          |
    Button_Init(GPIO15)
          |
          v
    +-->.Loop
    |     |
    |   Button_Read()
    |     |
    |   cmp r0, #0
    |     |
    |  +--+--+
    |  |     |
    | beq   fall
    |  |     |
    |  v     v
    | .Pressed  .Released
    |  |         |
    | GPIO_Set  GPIO_Clear
    | (LED on)  (LED off)
    |  |         |
    |  +--+--+---+
    |     |
    |   .Loop_Delay
    |     |
    |   Delay_MS(10)
    |     |
    +-----+
```

## Timing Analysis

Each loop iteration takes approximately:
- Button_Read: ~5 instructions + coprocessor read ≈ 6 cycles
- cmp + beq: 2 cycles
- GPIO_Set or GPIO_Clear: ~5 instructions + coprocessor write ≈ 6 cycles
- Delay_MS(10): 36,000 loop iterations ≈ 108,000 cycles

Total per iteration: ~108,014 cycles at 14.5 MHz ≈ **7.4 ms**

The 10ms delay dominates the loop timing.  The button is checked approximately every 10ms.

## Why Button_Read Instead of Button_IsPressed?

The main loop uses `Button_Read` (raw, active-low) instead of `Button_IsPressed` (inverted, active-high).  This is a design choice — the comparison `cmp r0, #0` / `beq .Button_Pressed` reads naturally: "if the button reads 0, it is pressed."

Using `Button_IsPressed` would change the comparison to `cmp r0, #1` / `beq .Button_Pressed`, which is equally valid but uses one more function call (the `bl Button_Read` inside Button_IsPressed).

## Summary

- main configures GPIO16 as an LED output and GPIO15 as a button input.
- The infinite loop reads the button, branches based on its state, drives the LED, and delays 10ms.
- The 10ms delay provides debouncing and reduces CPU power consumption.
- Both the pressed and released paths converge at the delay before looping.
- Empty `.rodata`, `.data`, `.bss` sections are placeholders for future use.
- The pop/bx instructions are structurally present but never reached.
