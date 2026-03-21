# Chapter 15: Calling Convention and Stack Frames

## Introduction

When one function calls another, both must agree on where arguments go, which registers are preserved, and how the return value is passed back.  These rules form the **calling convention**.  This chapter explains the ARM Architecture Procedure Call Standard (AAPCS) as it applies to our button driver.

## The AAPCS Register Convention

| Register | Alias | Role | Caller/Callee Saved |
|----------|-------|------|-------------------|
| r0–r3 | a1–a4 | Arguments and return values | Caller-saved |
| r4–r11 | v1–v8 | General-purpose | Callee-saved |
| r12 | ip | Intra-procedure scratch | Caller-saved |
| r13 | sp | Stack Pointer | — |
| r14 | lr | Link Register (return address) | Callee-saved |
| r15 | pc | Program Counter | — |

**Caller-saved** means the calling function must assume these registers are destroyed after a `bl`.  **Callee-saved** means the called function must preserve and restore these registers before returning.

## Arguments and Return Values

### Arguments in r0–r3

Functions receive their first four arguments in r0–r3:

```asm
.GPIO16_Config:
  ldr   r0, =PADS_BANK0_GPIO16_OFFSET            // arg 1: PAD_OFFSET
  ldr   r1, =IO_BANK0_GPIO16_CTRL_OFFSET         // arg 2: CTRL_OFFSET
  ldr   r2, =16                                  // arg 3: GPIO number
  bl    GPIO_Config                              // call GPIO_Config(r0, r1, r2)
```

GPIO_Config receives three arguments:
- r0 = pad offset (0x44)
- r1 = control register offset (0x84)
- r2 = GPIO number (16)

### Return Values in r0

Functions return values in r0:

```asm
  bl    Button_Read                              // r0 = button state (0 or 1)
  cmp   r0, #0                                   // check return value
```

Button_Read places its result in r0, and the caller immediately uses r0 to decide which branch to take.

## Saving and Restoring Registers

Every function that uses r4–r12 must save them on entry and restore them on exit:

```asm
Button_Init:
  push  {r4-r12, lr}                             // save callee-saved registers
                                                 // ... function body ...
  pop   {r4-r12, lr}                             // restore callee-saved registers
  bx    lr                                       // return
```

The push/pop pair saves 10 registers (r4–r12 plus lr), consuming 40 bytes of stack space.

### Why Save lr?

If a function calls another function with `bl`, the new `bl` overwrites lr.  Pushing lr on entry and popping it before `bx lr` ensures the original return address is restored.

Button_IsPressed demonstrates this clearly:

```asm
Button_IsPressed:
  push  {r4-r12, lr}                             // save lr (caller's return address)
  bl    Button_Read                              // overwrites lr with address in IsPressed
  eor   r0, r0, #1                               // invert result
  pop   {r4-r12, lr}                             // restore caller's return address
  bx    lr                                       // return to caller
```

## Stack Frame Layout

When Button_Read is called from within main's loop, the stack looks like this:

```
     High Address (0x20082000 = STACK_TOP)
  +--------------+
  | main's lr    |  main's frame
  | main's r12   |
  | ...          |
  | main's r4    |
  +--------------+
  | BRead's lr   |  Button_Read's frame
  | BRead's r12  |
  | ...          |
  | BRead's r4   |  <-- SP
  +--------------+
     Low Address
```

Each frame is 40 bytes.  The stack grows downward (from high to low addresses).

## Leaf Functions

Functions that never call other functions are **leaf functions**.  They do not need to save lr because no `bl` will overwrite it.

```asm
Enable_Coprocessor:
  ldr   r0, =CPACR                               // load CPACR address
  ldr   r1, [r0]                                 // read CPACR value
  orr   r1, r1, #(1<<1)                          // set CP0 bit
  orr   r1, r1, #(1<<0)                          // set CP0 bit
  str   r1, [r0]                                 // store value into CPACR
  dsb                                            // data sync barrier
  isb                                            // instruction sync barrier
  bx    lr                                       // return
```

Enable_Coprocessor uses only r0 and r1 (caller-saved), never calls `bl`, and returns directly.  No push/pop needed.

Leaf functions in our driver:
- `Enable_Coprocessor` (coprocessor.s)
- `Init_XOSC` (xosc.s)
- `Enable_XOSC_Peri_Clock` (xosc.s)
- `Init_Subsystem` (reset.s)
- `Init_Stack` (stack.s)

Non-leaf functions (they call other functions via `bl`):
- `Button_Init` (button.s) — no nested bl, but uses r4-r5
- `Button_Read` (button.s) — no nested bl, but uses r4
- `Button_IsPressed` (button.s) — calls Button_Read
- `GPIO_Config` (gpio.s) — no nested bl, but uses r4-r5
- `GPIO_Set` (gpio.s) — no nested bl, but uses r4
- `GPIO_Clear` (gpio.s) — no nested bl, but uses r4
- `Delay_MS` (delay.s) — no nested bl, but uses r4-r5
- `main` (main.s) — calls multiple functions
- `Reset_Handler` (reset_handler.s) — calls multiple functions

Note: Button_Init, Button_Read, GPIO_Config, GPIO_Set, GPIO_Clear, and Delay_MS push/pop r4-r12 and lr because they use callee-saved registers (r4, r5), even if they do not make nested calls.

## The Full Call Chain

```
Reset_Handler (no frame - uses b, not bl, to reach main)
  bl Init_Stack            0 bytes (leaf, no push)
  bl Init_XOSC             0 bytes (leaf, no push)
  bl Enable_XOSC_Peri_Clock 0 bytes (leaf, no push)
  bl Init_Subsystem        0 bytes (leaf, no push)
  bl Enable_Coprocessor    0 bytes (leaf, no push)
  b  main                 40 bytes (push {r4-r12, lr})
    bl GPIO_Config        40 bytes (push {r4-r12, lr})
    bl Button_Init        40 bytes (push {r4-r12, lr})
    bl Button_Read        40 bytes (push {r4-r12, lr})
    bl GPIO_Set           40 bytes (push {r4-r12, lr})
    bl Delay_MS           40 bytes (push {r4-r12, lr})
```

Maximum stack depth: main's frame (40) + one callee frame (40) = **80 bytes**.  With 32 KB of stack space, this is well within bounds.

## Summary

- Arguments pass in r0–r3; return values come back in r0.
- Callee-saved registers (r4–r12, lr) must be preserved by the called function.
- `push {r4-r12, lr}` / `pop {r4-r12, lr}` creates a 40-byte stack frame.
- Leaf functions skip push/pop when they only use caller-saved registers.
- Maximum stack depth in our driver is 80 bytes (two nested frames).
- The calling convention ensures functions can be composed freely without corrupting each other's state.
