# Chapter 11: Branch Instructions

## Introduction

Branch instructions alter the sequential flow of execution.  Without them, every program would execute from start to finish in a straight line.  This chapter covers every branch instruction used in our button driver: unconditional branches, conditional branches, and the flags that control them.

## Unconditional Branch: b

```asm
  b     .Loop                                    // loop forever
```

The `b` instruction jumps to the target label regardless of any condition.  The PC is loaded with the address of `.Loop` and execution continues there.

In main.s, this creates the infinite monitoring loop:

```asm
.Loop_Delay:
  ldr   r0, =10                                  // 10ms debounce delay
  bl    Delay_MS                                 // call Delay_MS
  b     .Loop                                    // loop forever
```

After each delay, execution jumps back to `.Loop` to read the button again.

Also used to skip over the pressed handler when the button is released:

```asm
  b     .Loop_Delay                              // continue to delay
```

## Conditional Branches

Conditional branches check the condition flags (N, Z, C, V) set by a previous instruction and branch only if the condition is true.

### beq — Branch if Equal (Z=1)

```asm
  cmp   r0, #0                                   // set flags: Z=1 if r0==0
  beq   .Button_Pressed                          // branch if button pressed (r0==0)
```

After `cmp r0, #0`, if r0 is 0 (button pressed), the Z flag is set and `beq` takes the branch.  If r0 is 1 (button released), Z is clear and execution falls through to `.Button_Released`.

Also used in xosc.s and reset.s for polling loops:

```asm
  tst   r1, #(1<<31)                             // test STABLE bit
  beq   .Init_XOSC_Wait                          // wait until stable bit is set
```

Here `beq` branches back to keep polling when the tested bit is 0 (Z=1 means the AND result was zero).

### bne — Branch if Not Equal (Z=0)

```asm
  subs  r5, r5, #1                               // decrement counter
  bne   .Delay_MS_Loop                           // branch until zero
```

The tight delay loop in delay.s uses `bne` to repeat until the counter reaches zero.  When `subs` sets Z=1 (result is zero), `bne` falls through and the loop ends.

### ble — Branch if Less or Equal (Z=1 or N!=V)

```asm
  cmp   r0, #0                                   // if MS is not valid, return
  ble   .Delay_MS_Done                           // branch if less or equal to 0
```

This guards delay.s against invalid inputs.  If the caller passes 0 or a negative value, `ble` skips the loop entirely.

## Condition Code Summary

| Suffix | Condition | Flags | Used In |
|--------|-----------|-------|---------|
| `eq` | Equal / Zero | Z=1 | main.s, xosc.s, reset.s |
| `ne` | Not equal / Non-zero | Z=0 | delay.s |
| `le` | Less than or equal (signed) | Z=1 or N≠V | delay.s |

## How the Processor Evaluates Conditions

The condition evaluation happens in the decode/execute stage.  The processor:

1. Reads the condition field from the instruction encoding
2. Compares the condition against the current APSR flags
3. If the condition is true: updates the PC to the branch target
4. If the condition is false: increments the PC to the next instruction (falls through)

## Branch Encoding

Branch instructions encode the target as a **PC-relative offset** — a signed displacement added to the current PC value.

For Thumb-2:
- 16-bit conditional branch: ±256 bytes range
- 32-bit conditional branch: ±1 MB range
- 32-bit unconditional branch: ±16 MB range

The assembler and linker compute the offset from the label.  As the programmer, you write:

```asm
  beq   .Button_Pressed                          // branch if button pressed (r0==0)
```

The assembler calculates the byte distance between this instruction and `.Button_Pressed` and encodes it in the instruction.

## Control Flow in main.s

The complete control flow of the button monitoring loop:

```
         .Loop
           |
     Button_Read()
           |
     cmp r0, #0
           |
      +----+----+
      |         |
  Z=1 (beq)  Z=0 (fall through)
      |         |
 .Button_     .Button_
  Pressed      Released
      |         |
  GPIO_Set   GPIO_Clear
      |         |
      +----+----+
           |
     .Loop_Delay
           |
     Delay_MS(10)
           |
       b .Loop
```

Every iteration reads the button, branches based on its state, drives the LED accordingly, waits 10ms for debouncing, and repeats.

## Summary

- `b` is an unconditional jump — used for infinite loops and skipping code blocks.
- `beq` branches when Z=1 — used to detect button press (r0==0) and to poll hardware status bits.
- `bne` branches when Z=0 — used for countdown loops in delay.s.
- `ble` branches when Z=1 or N≠V — used to guard against invalid inputs.
- Branch targets are encoded as PC-relative offsets computed by the assembler.
- The main.s control flow uses `cmp` + `beq` to implement a button-state conditional.
