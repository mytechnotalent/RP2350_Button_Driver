# Chapter 6: Fetch-Decode-Execute Cycle in Detail

## Introduction

Chapter 1 introduced the fetch-decode-execute cycle as the heartbeat of every processor.  This chapter examines the cycle in detail for the ARM Cortex-M33, showing how each phase works, how the pipeline overlaps them, and how branch instructions disrupt the flow.

## The Three Phases

### Fetch

The processor reads the instruction at the address held in the Program Counter (PC).  On the Cortex-M33, instructions are either 16 bits (2 bytes) or 32 bits (4 bytes).  The fetch unit reads from the instruction bus connected to flash via the XIP cache.

### Decode

The fetched binary pattern is decoded to determine:
- The operation (add, load, branch, etc.)
- The source and destination registers
- Any immediate value embedded in the instruction

For example, the 32-bit encoding of `bic r5, r5, #(1<<7)` decodes to: "perform bitwise AND of r5 with the complement of 0x80, store result in r5."

### Execute

The operation runs on the ALU, memory interface, or branch unit.  The result is written to the destination register or memory.  Condition flags may be updated.

## The Cortex-M33 Pipeline

The Cortex-M33 has a multi-stage pipeline that overlaps these phases:

```
Cycle:     1      2      3      4      5
          +------+------+------+------+------+
Instr 1:  |Fetch |Decode|Exec  |      |      |
          +------+------+------+------+------+
Instr 2:  |      |Fetch |Decode|Exec  |      |
          +------+------+------+------+------+
Instr 3:  |      |      |Fetch |Decode|Exec  |
          +------+------+------+------+------+
```

While instruction 1 is executing, instruction 2 is being decoded and instruction 3 is being fetched.  This overlap means the processor can complete one instruction per cycle under ideal conditions.

## Sequential Execution Example

Consider this sequence from our Reset_Handler:

```asm
  bl    Init_Stack                               // call Init_Stack
  bl    Init_XOSC                                // call Init_XOSC
  bl    Enable_XOSC_Peri_Clock                   // call Enable_XOSC_Peri_Clock
```

Each `bl` is fetched, decoded, and executed in sequence.  The pipeline keeps all three stages busy simultaneously.

## Branch Penalty

When the processor encounters a branch, it may not know the target address until the execute stage.  Instructions that were already fetched after the branch are incorrect and must be discarded — this is called a **pipeline flush**.

```asm
  bne   .Delay_MS_Loop                           // branch if counter != 0
```

If the branch is taken, the pipeline flushes and restarts at `.Delay_MS_Loop`.  For our tight delay loop (3,600 × ms iterations), this flush happens on every iteration except the last.  The penalty is small (a few cycles) but multiplied across millions of iterations.

## Conditional Execution

The Cortex-M33 supports conditional branches based on the flags set by previous instructions:

```asm
  cmp   r0, #0                                   // set flags: Z=1 if r0==0
  beq   .Button_Pressed                          // branch if Z==1 (button pressed)
```

The `cmp` instruction subtracts the immediate from r0, discards the result, and updates the N, Z, C, V flags.  The `beq` instruction checks the Z flag and branches only if it is set.

## The Clock

Every pipeline stage advances on each clock tick.  The RP2350 runs the Cortex-M33 at approximately 14.5 MHz from the ring oscillator after reset (before we configure the PLL).  At 14.5 MHz:

- 1 clock cycle = ~69 ns
- A tight loop iteration (sub + branch) takes ~2–3 cycles = ~140–207 ns

This is why our delay loop uses 3,600 iterations per millisecond: 3,600 × ~278 ns ≈ 1 ms.

## Summary

- The fetch-decode-execute cycle has three phases that overlap in the pipeline.
- The Cortex-M33 pipeline can complete one instruction per cycle under ideal conditions.
- Branch instructions cause pipeline flushes, costing a few cycles.
- Conditional branches (`beq`, `bne`, `ble`) check flags set by `cmp`, `tst`, or `subs`.
- At 14.5 MHz, each clock cycle takes approximately 69 ns.
