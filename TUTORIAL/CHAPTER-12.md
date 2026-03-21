# Chapter 12: Jumps, Calls, and Returns

## Introduction

Chapter 11 covered branches that redirect execution within a function.  This chapter focuses on the instructions that transfer control between functions: `bl` (call), `bx lr` (return), and `b` (tail call).  These three instructions form the backbone of the button driver's modular design.

## bl — Branch with Link (Function Call)

```asm
  bl    GPIO_Config                              // call GPIO_Config
```

`bl` does two things:

1. Saves the address of the next instruction in the **Link Register** (lr / r14)
2. Jumps to the target function

This is how every function call works in our driver.  The saved return address in lr enables the callee to return to the exact point after the call.

### Call Chain in main.s

```asm
  bl    GPIO_Config                              // call GPIO_Config
  bl    Button_Init                              // initialize button on GPIO15
  bl    Button_Read                              // read button state
  bl    GPIO_Set                                 // turn on LED
  bl    GPIO_Clear                               // turn off LED
  bl    Delay_MS                                 // call Delay_MS
```

Each `bl` stores a different return address in lr.  This is why functions must save lr on entry — if a function calls another function, the nested `bl` overwrites lr.

### Nested Calls

When Button_IsPressed calls Button_Read:

```asm
Button_IsPressed:
  push  {r4-r12, lr}                             // save lr (return to caller)
  bl    Button_Read                              // lr now points within Button_IsPressed
  eor   r0, r0, #1                               // invert result
  pop   {r4-r12, lr}                             // restore original lr
  bx    lr                                       // return to original caller
```

Without the push/pop of lr, the `bl Button_Read` would overwrite the return address and Button_IsPressed would never return to its own caller.

## bx lr — Branch to Link Register (Return)

```asm
  bx    lr                                       // return
```

`bx` branches to the address stored in a register.  Using `lr` makes it a function return.  The `x` in `bx` stands for "exchange" — it can switch between ARM and Thumb states based on bit 0 of the target address.  On the Cortex-M33 (Thumb-only), this bit is always 1.

Every function in our driver ends with `bx lr`:

| Function | File |
|----------|------|
| `Button_Init` | button.s |
| `Button_Read` | button.s |
| `Button_IsPressed` | button.s |
| `GPIO_Config` | gpio.s |
| `GPIO_Set` | gpio.s |
| `GPIO_Clear` | gpio.s |
| `Delay_MS` | delay.s |
| `Enable_Coprocessor` | coprocessor.s |
| `Init_XOSC` | xosc.s |
| `Enable_XOSC_Peri_Clock` | xosc.s |
| `Init_Subsystem` | reset.s |
| `Init_Stack` | stack.s |

## b — Tail Call (Branch Without Link)

```asm
  b     main                                     // branch to main loop
```

In reset_handler.s, the final instruction is `b main` rather than `bl main`.  This is a **tail call**: the Reset_Handler does not expect main to return, so there is no need to save a return address.  Using `b` instead of `bl` is more efficient — it does not modify lr.

## The Call Stack in Action

Consider this call sequence during normal operation:

```
Reset_Handler
  bl Init_Stack         --> Init_Stack --> bx lr
  bl Init_XOSC          --> Init_XOSC --> bx lr
  bl Enable_XOSC_Peri_Clock --> ... --> bx lr
  bl Init_Subsystem     --> Init_Subsystem --> bx lr
  bl Enable_Coprocessor --> Enable_Coprocessor --> bx lr
  b  main               --> main (never returns)
    bl GPIO_Config      --> GPIO_Config --> bx lr
    bl Button_Init      --> Button_Init --> bx lr
    .Loop:
      bl Button_Read    --> Button_Read --> bx lr
      bl GPIO_Set/Clear --> ... --> bx lr
      bl Delay_MS       --> Delay_MS --> bx lr
      b .Loop
```

The stack grows when a function pushes registers, and shrinks when it pops them.  At maximum depth (main → Button_Read), two frames are on the stack: main's saved registers and Button_Read's saved registers, totaling 80 bytes.

## Link Register vs. Stack

Functions that do not call other functions (leaf functions) can use lr directly without saving it:

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

Enable_Coprocessor never uses `bl`, so lr is never overwritten.  It does not need push/pop.

Similarly, Init_XOSC, Enable_XOSC_Peri_Clock, Init_Subsystem, and Init_Stack are all leaf functions — they do not push/pop because they never call other functions.

## The Thumb Bit

The vector table entry for Reset_Handler includes `+ 1`:

```asm
  .word Reset_Handler + 1                        // reset handler (Thumb bit set)
```

Bit 0 of the address tells the processor to execute in Thumb state.  The `bx` instruction checks this bit.  On the Cortex-M33, all code is Thumb, so this bit must always be set for valid function pointers.

## Summary

- `bl` saves the return address in lr and jumps to the target function.
- `bx lr` returns to the caller by branching to the address saved in lr.
- `b` performs a tail call when no return is expected (Reset_Handler → main).
- Functions that call other functions must save lr with `push` and restore it with `pop`.
- Leaf functions (no nested calls) skip push/pop since lr remains intact.
- The Thumb bit (bit 0) must be set in all function pointers on the Cortex-M33.
