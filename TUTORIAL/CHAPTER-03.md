# Chapter 3: Memory

## Introduction

Memory is where the processor stores both the instructions it executes and the data it operates on.  Our button driver lives in flash memory at address `0x10000000` and uses SRAM at `0x20000000` for the stack.  This chapter explains how memory is organized, how addresses work, and how the RP2350's memory map determines where every byte of our firmware resides.

## Addresses and Bytes

Memory is a linear array of bytes.  Each byte has a unique **address** — a 32-bit number that identifies its location.  The Cortex-M33 uses byte addressing: every address points to one 8-bit byte.

```
Address:  0x00000000  0x00000001  0x00000002  0x00000003
Content:  [  byte  ]  [  byte  ]  [  byte  ]  [  byte  ]
```

## Words

A **word** on the Cortex-M33 is 32 bits (4 bytes).  Most instructions operate on whole words.  When we load a word from memory:

```asm
  ldr   r1, [r0]                                 // load 4 bytes from address in r0
```

The processor reads 4 consecutive bytes starting at the address in r0 and assembles them into a 32-bit value in r1.

## Endianness

The RP2350 Cortex-M33 is **little-endian**: the least significant byte is stored at the lowest address.

```
Address:   0x100  0x101  0x102  0x103
Content:   0xA0   0xBA   0xFA   0x00
Word value: 0x00FABAA0
```

Our XOSC control word `0x00FABAA0` is stored with `0xA0` at the lowest address.  You rarely need to think about endianness in assembly because `ldr` and `str` handle byte ordering automatically.

## The RP2350 Memory Map

The Cortex-M33 has a 4 GB address space (2^32 bytes).  The RP2350 maps different hardware to specific address ranges:

| Address Range | Size | Contents |
|---------------|------|----------|
| `0x00000000` – `0x0FFFFFFF` | 256 MB | Boot ROM and system |
| `0x10000000` – `0x11FFFFFF` | 32 MB | External Flash (XIP) |
| `0x20000000` – `0x2007FFFF` | 512 KB | SRAM |
| `0x40000000` – `0x4FFFFFFF` | 256 MB | APB Peripherals |
| `0xD0000000` – `0xDFFFFFFF` | 256 MB | SIO |
| `0xE0000000` – `0xE00FFFFF` | 1 MB | Private Peripheral Bus (PPB) |

## Flash Memory — Where Our Code Lives

Our firmware is stored in external flash starting at `0x10000000`.  The RP2350 supports **execute-in-place (XIP)**: the processor fetches and executes instructions directly from flash through a cache, without copying them to RAM first.

The linker script places our code here:

```
FLASH (rx) : ORIGIN = 0x10000000, LENGTH = 32M
```

Every instruction in our firmware — from the PICOBIN block to the button loop in main.s — resides in flash.

## SRAM — Where the Stack Lives

SRAM occupies `0x20000000` to `0x2007FFFF` (512 KB).  Our firmware uses the top 32 KB as stack space:

```
0x20000000  +------------------+
            |                  |
            |  (unused SRAM)   |
            |                  |
0x2007A000  +------------------+ ← STACK_LIMIT
            |                  |
            |     Stack        |
            |  (grows down)    |
            |                  |
0x20082000  +------------------+ ← STACK_TOP
```

The stack grows downward: `push` decreases the stack pointer, `pop` increases it.

## Peripheral Registers — Memory-Mapped I/O

Hardware peripherals are controlled by reading and writing to specific memory addresses.  This is called **memory-mapped I/O**.  The same `ldr` and `str` instructions that access RAM also access peripheral registers:

```asm
  ldr   r0, =XOSC_STATUS                         // r0 = 0x40048004
  ldr   r1, [r0]                                 // read XOSC status register
```

This `ldr` does not read RAM — it reads the XOSC hardware register at address `0x40048004`.  The bus fabric routes the access to the correct peripheral based on the address.

## Addresses in Our Firmware

Every `.equ` constant in constants.s is a memory address:

| Constant | Address | What Lives There |
|----------|---------|-----------------|
| `STACK_TOP` | `0x20082000` | Top of SRAM (stack starts here) |
| `XOSC_BASE` | `0x40048000` | Crystal oscillator registers |
| `CLOCKS_BASE` | `0x40010000` | Clock controller registers |
| `RESETS_BASE` | `0x40020000` | Reset controller registers |
| `IO_BANK0_BASE` | `0x40028000` | GPIO function select registers |
| `PADS_BANK0_BASE` | `0x40038000` | GPIO pad control registers |
| `PPB_BASE` | `0xE0000000` | Private peripheral bus (CPACR) |

## Alignment

The Cortex-M33 requires word-aligned access for `ldr` and `str`: the address must be divisible by 4.  All peripheral registers are naturally word-aligned.  The assembler directive `.align 2` ensures code is aligned to a 4-byte boundary (2^2 = 4).

The vector table has a stricter requirement: it must be aligned to a 128-byte boundary within the first 4 KB of flash, which the linker script enforces with `ALIGN(128)`.

## Summary

- Memory is a byte-addressable array; the Cortex-M33 has a 4 GB address space.
- A word is 32 bits (4 bytes), stored little-endian on the RP2350.
- Flash at `0x10000000` holds our code; SRAM at `0x20000000` holds the stack.
- Peripheral registers are accessed through memory-mapped I/O at fixed addresses.
- Every address constant in our firmware maps to a real hardware register or memory region.
