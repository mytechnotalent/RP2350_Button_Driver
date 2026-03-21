# Chapter 10: Memory Access — Load and Store Deep Dive

## Introduction

Chapter 5 introduced the load-store model.  This chapter examines every memory access pattern used in our button driver: register-indirect loads and stores, PC-relative literal pools, the push/pop stack operations, and the special system register transfers via `msr`.

## Register-Indirect Addressing

The most common memory access pattern in our driver uses a register as a pointer:

```asm
  ldr   r5, [r4]                                 // read PAD_OFFSET value
```

The square brackets mean "use the value in r4 as a memory address, and load the 32-bit word at that address into r5."

```asm
  str   r5, [r4]                                 // store value into PAD_OFFSET
```

The same syntax with `str` writes the value in r5 to the memory address in r4.

### The Read-Modify-Write Pattern

Peripheral registers often require updating individual bits without disturbing others.  This produces a three-instruction sequence that appears throughout our driver:

```asm
  ldr   r5, [r4]                                 // 1. READ: load current register value
  orr   r5, r5, #(1<<6)                          // 2. MODIFY: set IE bit
  str   r5, [r4]                                 // 3. WRITE: store modified value back
```

In button.s, the pad configuration uses five modify operations between the load and store:

```asm
  ldr   r5, [r4]                                 // read PAD_OFFSET value
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
  orr   r5, r5, #(1<<3)                          // set PUE bit (pull-up enable)
  bic   r5, r5, #(1<<2)                          // clear PDE bit (pull-down disable)
  bic   r5, r5, #(1<<8)                          // clear ISO bit
  str   r5, [r4]                                 // store value into PAD_OFFSET
```

This single read-modify-write updates five bits in one peripheral register access.

## Register-Indirect with Offset

Some memory accesses add an offset to the base register:

```asm
  ldr   r4, =PADS_BANK0_BASE                     // load base address
  ldr   r5, =PADS_BANK0_GPIO15_OFFSET            // load offset
  add   r4, r4, r5                               // base + offset = final address
  ldr   r5, [r4]                                 // read from computed address
```

This computes the address in two steps because the offset is loaded from a constant rather than being a small immediate value.

## PC-Relative Loads (Literal Pools)

When a constant is too large for a modified immediate, the assembler uses a PC-relative load:

```asm
  ldr   r4, =PADS_BANK0_BASE                     // load 0x40038000
```

The assembler converts this to:

```asm
  ldr   r4, [pc, #offset]                        // load from literal pool
```

The 32-bit value `0x40038000` is stored in a **literal pool** — a data table embedded near the instruction.  The processor reads it from flash using a PC-relative address.

### Literal Pool Layout

```
+---------------------------+
| Function instructions     |
| ...                       |
| bx lr                     |
+---------------------------+
| Literal pool:             |
| 0x40038000  (PADS_BANK0)  |
| 0x40028000  (IO_BANK0)    |
| 0x00000E10  (3600)        |
+---------------------------+
```

The literal pool is read-only data co-located with code in the `.text` section.

## Stack Operations: push and pop

The `push` and `pop` instructions are shorthand for multiple stores and loads to the stack:

```asm
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
```

This is equivalent to:

```
  stmdb sp!, {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
```

It decrements the Stack Pointer (SP) by 40 bytes (10 registers × 4 bytes) and writes each register to memory in order.

```asm
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
```

This loads the same registers back from the stack and increments SP by 40 bytes.

### Stack Layout After push

```
     High Address
  +--------------+
  |     lr       |  SP + 36
  +--------------+
  |     r12      |  SP + 32
  +--------------+
  |     r11      |  SP + 28
  +--------------+
  |     r10      |  SP + 24
  +--------------+
  |     r9       |  SP + 20
  +--------------+
  |     r8       |  SP + 16
  +--------------+
  |     r7       |  SP + 12
  +--------------+
  |     r6       |  SP + 8
  +--------------+
  |     r5       |  SP + 4
  +--------------+
  |     r4       |  SP + 0  <-- SP after push
  +--------------+
     Low Address
```

Every function in our driver that uses registers r4-r12 begins with push and ends with pop, preserving the caller's state.

## System Register Transfers: msr

The `msr` instruction writes a general-purpose register to a special system register:

```asm
  ldr   r0, =STACK_TOP                           // load stack top address
  msr   MSP, r0                                  // set Main Stack Pointer
```

Unlike `str` which writes to a memory address, `msr` writes to a processor-internal register that is not memory-mapped.  The system registers accessed in stack.s:

| Instruction | Target | Purpose |
|-------------|--------|---------|
| `msr PSP, r0` | Process Stack Pointer | Set PSP to STACK_TOP |
| `msr MSPLIM, r0` | MSP Limit | Set stack overflow guard |
| `msr PSPLIM, r0` | PSP Limit | Set stack overflow guard |
| `msr MSP, r0` | Main Stack Pointer | Set MSP to STACK_TOP |

## Coprocessor Memory Access

The coprocessor instructions bypass the normal memory bus entirely:

```asm
  mrc   p0, #0, r4, c0, c8                       // read all lower 32 GPIO inputs
```

`mrc` (Move to Register from Coprocessor) transfers data from coprocessor 0 to a general-purpose register.  This is how button.s reads the GPIO input state — the GPIO hardware provides the data through the coprocessor interface, not through a memory-mapped register.

```asm
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(GPIO, 1)
```

`mcrr` (Move to Coprocessor from two Registers) sends two register values to the coprocessor.  This is how gpio.s sets a GPIO pin high or low.

## Memory Access Timing

Different memory access types have different latencies:

| Access Type | Source | Typical Latency |
|-------------|--------|-----------------|
| Register immediate | Instruction encoding | 0 extra cycles |
| Literal pool load | Flash (cached) | 1 cycle |
| Peripheral register | AHB/APB bus | 2+ cycles |
| Coprocessor transfer | CP0 interface | 1 cycle |

The read-modify-write pattern (ldr + modify + str) accessing a peripheral register is the most expensive, taking at least 4 cycles (2 for ldr, 1 for modify, 2+ for str).

## Summary

- Register-indirect addressing (`ldr Rd, [Rn]` / `str Rd, [Rn]`) is the primary way to access hardware registers.
- The read-modify-write pattern updates individual bits in peripheral registers.
- PC-relative literal pools store constants too large for modified immediates.
- Push/pop save and restore registers across function calls, using 40 bytes per frame in our driver.
- `msr` writes to system registers (stack pointers, limits) that are not memory-mapped.
- Coprocessor instructions (`mrc`, `mcrr`) provide a fast path to the GPIO hardware.
