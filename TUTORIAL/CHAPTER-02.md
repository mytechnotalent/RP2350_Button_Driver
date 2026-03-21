# Chapter 2: Number Systems

## Introduction

Every value our button driver manipulates — register addresses, bit masks, GPIO numbers, delay counts — is a number stored in binary.  This chapter teaches the three number systems you will encounter in ARM assembly: binary, hexadecimal, and decimal.  By the end you will be able to convert between them and recognise each form in our firmware source code.

## Decimal (Base 10)

Decimal is the system humans use daily.  Each digit position represents a power of 10:

```
  3600 = 3×1000 + 6×100 + 0×10 + 0×1
```

In our firmware, decimal appears in delay calculations and GPIO numbers:

```asm
  ldr   r4, =3600                                // loops per ms at 14.5 MHz
  ldr   r2, =16                                  // GPIO16 pin number
```

## Binary (Base 2)

Binary uses only two digits: 0 and 1.  Each digit is one **bit**.  The processor stores and operates on everything in binary.

```
  0b0001000000100001 = IMAGE_DEF type field
```

Eight bits make one byte.  Thirty-two bits make one word — the native data size of the Cortex-M33.

### Bit Numbering

Bits in a 32-bit register are numbered 0 (least significant, rightmost) to 31 (most significant, leftmost):

```
Bit:  31 30 29 ... 8  7  6  5  4  3  2  1  0
      MSB                                  LSB
```

Our firmware tests and sets individual bits by position:

```asm
  tst   r1, #(1<<31)                             // test XOSC STABLE bit
  bic   r5, r5, #(1<<7)                          // clear OD (Output Disable)
  orr   r5, r5, #(1<<6)                          // set IE (Input Enable)
  orr   r5, r5, #(1<<3)                          // set PUE (Pull-Up Enable)
```

The expression `(1<<6)` means "1 shifted left 6 positions" = bit 6 = `0b01000000` = `0x40`.

## Hexadecimal (Base 16)

Hexadecimal (hex) uses digits 0–9 and letters A–F.  Each hex digit represents exactly 4 bits:

| Hex | Binary | Decimal |
|-----|--------|---------|
| 0 | 0000 | 0 |
| 1 | 0001 | 1 |
| 4 | 0100 | 4 |
| 5 | 0101 | 5 |
| 8 | 1000 | 8 |
| A | 1010 | 10 |
| F | 1111 | 15 |

Every memory-mapped address in our firmware is written in hex:

```asm
  .equ XOSC_BASE,  0x40048000                    // crystal oscillator base
  .equ RESETS_BASE, 0x40020000                   // reset controller base
```

### Converting Hex to Binary

Split each hex digit into 4 bits:

```
0x40028000 = 0100 0000 0000 0010 1000 0000 0000 0000 (binary)
```

### Why Hex?

Hex is compact.  A 32-bit address like `0x40038044` is 8 hex digits instead of 32 binary digits.  It is the standard notation for memory addresses and register values in embedded programming.

## Number Prefixes in ARM Assembly

| Prefix | Base | Example |
|--------|------|---------|
| `0x` | Hexadecimal | `0x40048000` |
| `0b` | Binary | `0b0001000000100001` |
| `#` | Immediate decimal | `#(1<<6)` |
| (none) | Decimal | `3600` |

## Bit Masks

A bit mask isolates specific bits in a register.  Our button driver uses masks throughout:

| Mask | Binary | Purpose |
|------|--------|---------|
| `#(1<<31)` | Bit 31 only | Test XOSC STABLE |
| `#(1<<7)` | Bit 7 only | Clear OD bit |
| `#(1<<6)` | Bit 6 only | Set IE / test IO_BANK0 |
| `#(1<<3)` | Bit 3 only | Set PUE (pull-up enable) |
| `#0x1f` | Bits 4:0 | Clear FUNCSEL field |
| `#1` | Bit 0 only | Mask single bit in button read |

Understanding these masks requires fluency in binary.  By the time you reach the source code walkthroughs, every `bic`, `orr`, `tst`, and `and` will be transparent.

## Register Values as Hex

When our firmware loads a large constant, it appears in hex:

```asm
  ldr   r1, =0x00FABAA0                          // XOSC control word
```

Breaking this down:

```
0x00FABAA0 = 0000 0000 1111 1010 1011 1010 1010 0000
```

The upper bits encode the ENABLE field, the lower bits encode the frequency range.  We will decode this fully in Chapter 25.

## Summary

- Decimal is for human-readable values: delay counts, GPIO numbers.
- Binary is how the processor stores everything: each bit has a specific meaning in a register.
- Hexadecimal compactly represents binary: one hex digit = 4 bits.
- Bit masks like `(1<<6)` isolate individual bits for testing and modification.
- All three number systems appear throughout our button driver source code.
