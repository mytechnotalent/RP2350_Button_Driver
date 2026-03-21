# Chapter 24: Boot Sequence — reset_handler.s

## Introduction

After the hardware loads the stack pointer and jumps to the reset vector, our code takes over.  The Reset_Handler in reset_handler.s is the first function that runs.  It calls a chain of initialization routines and then hands control to main.  This chapter walks through every line.

## The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

.global Reset_Handler                            // export Reset_Handler symbol
.type Reset_Handler, %function
Reset_Handler:
  bl    Init_Stack                               // initialize MSP/PSP and limits
  bl    Init_XOSC                                // initialize external crystal oscillator
  bl    Enable_XOSC_Peri_Clock                   // enable XOSC peripheral clock
  bl    Init_Subsystem                           // initialize subsystems
  bl    Enable_Coprocessor                       // enable CP0 coprocessor
  b     main                                     // branch to main loop
.size Reset_Handler, . - Reset_Handler
```

## Line-by-Line Walkthrough

### Directives

```asm
.section .text                                   // code section
.align 2                                         // align to 4-byte boundary
```

Places Reset_Handler in the `.text` section (executable code in flash) at a 4-byte aligned address.

```asm
.global Reset_Handler                            // export Reset_Handler symbol
.type Reset_Handler, %function
```

Exports `Reset_Handler` so the linker can:
1. Resolve the reference in vector_table.s (`.word Reset_Handler + 1`)
2. Set the Thumb bit in the vector table entry (because `.type %function` is set)

### Step 1: Stack Initialization

```asm
  bl    Init_Stack                               // initialize MSP/PSP and limits
```

Calls Init_Stack (stack.s), which:
- Sets PSP = 0x20082000
- Sets MSPLIM and PSPLIM = 0x2007A000
- Sets MSP = 0x20082000

This must happen first because every subsequent function call uses the stack.

### Step 2: Oscillator Configuration

```asm
  bl    Init_XOSC                                // initialize external crystal oscillator
```

Calls Init_XOSC (xosc.s), which:
- Sets the startup delay to 196 cycles
- Configures the crystal for 1–15 MHz range (actual ~14.5 MHz)
- Polls XOSC_STATUS until the oscillator stabilizes

After this call, the system has a stable clock source.

### Step 3: Peripheral Clock

```asm
  bl    Enable_XOSC_Peri_Clock                   // enable XOSC peripheral clock
```

Calls Enable_XOSC_Peri_Clock (xosc.s), which:
- Sets the peripheral clock source to XOSC
- Enables the peripheral clock

GPIO and other peripherals now have a clock supply derived from the stable XOSC.

### Step 4: Subsystem Reset

```asm
  bl    Init_Subsystem                           // initialize subsystems
```

Calls Init_Subsystem (reset.s), which:
- Clears the IO_BANK0 reset bit in the RESETS register
- Polls RESETS_RESET_DONE until IO_BANK0 is ready

After this call, the GPIO function-select registers in IO_BANK0 are accessible.

### Step 5: Coprocessor Enable

```asm
  bl    Enable_Coprocessor                       // enable CP0 coprocessor
```

Calls Enable_Coprocessor (coprocessor.s), which:
- Sets bits [1:0] of CPACR to enable CP0 access in privileged mode
- Executes `dsb` + `isb` to ensure the change takes effect

After this call, the `mcrr` and `mrc` coprocessor instructions for GPIO control are functional.

### Step 6: Branch to Main

```asm
  b     main                                     // branch to main loop
```

Uses `b` (not `bl`) because main never returns.  This is a tail call — the Reset_Handler's stack frame is not preserved.  The `b` instruction is more efficient than `bl` because it does not modify lr.

### Function Size

```asm
.size Reset_Handler, . - Reset_Handler
```

Records the function's size in the symbol table for debugger use.

## Initialization Order Dependencies

The order of initialization calls is not arbitrary:

```
Init_Stack         Must be first (everything uses the stack)
     |
Init_XOSC          Provides stable clock
     |
Enable_XOSC_Peri_Clock  GPIO needs a clock source
     |
Init_Subsystem     GPIO peripheral must be taken out of reset
     |
Enable_Coprocessor GPIO I/O via mcrr/mrc needs CP0 enabled
     |
main               All hardware is ready
```

Reordering these calls would cause failures:
- Calling Init_Subsystem before Init_XOSC: the peripheral clock is not running
- Calling Enable_Coprocessor before Init_Stack: `bl` pushes lr, but the stack is not set up
- Calling main before Enable_Coprocessor: `mcrr`/`mrc` instructions would fault

## Why Reset_Handler Has No push/pop

Reset_Handler does not save any registers because:
1. There is no caller to return to — this is the entry point after hardware reset
2. The `b main` at the end is a one-way transfer, not a call
3. All initialization functions are leaf functions that preserve their own registers

## The Complete Boot Timeline

```
Power On
  |
Boot ROM scans flash
  |
Finds IMAGE_DEF at 0x10000000
  |
Reads vector table at 0x10000080
  |
MSP = 0x20082000, PC = Reset_Handler
  |
bl Init_Stack          ~10 instructions
  |
bl Init_XOSC           ~8 instructions + wait loop
  |
bl Enable_XOSC_Peri_Clock  ~5 instructions
  |
bl Init_Subsystem      ~6 instructions + wait loop
  |
bl Enable_Coprocessor  ~7 instructions
  |
b  main                Button monitoring begins
```

## Summary

- Reset_Handler is the first user code to run after hardware reset.
- It calls five initialization functions in a strict dependency order.
- Each call sets up one layer of hardware: stack → clock → peripheral clock → GPIO subsystem → coprocessor.
- The final `b main` is a tail call — main's infinite loop never returns.
- Reset_Handler uses no push/pop because it is the entry point and never returns.
