# Chapter 21: Boot Metadata — image_def.s

## Introduction

The RP2350 boot ROM scans the first 4 KB of flash for a valid IMAGE_DEF block.  Without it, the boot ROM rejects the binary and the chip does not boot.  This chapter walks through every byte of image_def.s.

## The Complete Source

```asm
.section .picobin_block, "a"                     // place IMAGE_DEF block in flash

.word  0xffffded3                                // PICOBIN_BLOCK_MARKER_START
.byte  0x42                                      // PICOBIN_BLOCK_ITEM_1BS_IMAGE_TYPE
.byte  0x1                                       // item is 1 word in size
.hword 0b0001000000100001                        // SECURE mode (0x1021)
.byte  0xff                                      // PICOBIN_BLOCK_ITEM_2BS_LAST
.hword 0x0001                                    // item is 1 word in size
.byte  0x0                                       // pad
.word  0x0                                       // relative pointer to next block (0 = loop to self)
.word  0xab123579                                // PICOBIN_BLOCK_MARKER_END
```

## Line-by-Line Walkthrough

### Section Declaration

```asm
.section .picobin_block, "a"                     // place IMAGE_DEF block in flash
```

Creates a section named `.picobin_block` with the `"a"` (allocatable) attribute.  The linker script maps this to `.embedded_block`, which is placed at the very start of flash (0x10000000).  The boot ROM reads this address first.

### Start Marker

```asm
.word  0xffffded3                                // PICOBIN_BLOCK_MARKER_START
```

A 32-bit magic number that tells the boot ROM "an IMAGE_DEF block starts here."  The boot ROM scans flash looking for this exact value.  If it does not find it in the first 4 KB, the binary is rejected.

### Image Type Item

```asm
.byte  0x42                                      // PICOBIN_BLOCK_ITEM_1BS_IMAGE_TYPE
```

Item type byte.  `0x42` identifies this as an image type declaration.  The boot ROM uses this to determine the security mode, architecture, and chip compatibility.

```asm
.byte  0x1                                       // item is 1 word in size
```

The payload of this item is 1 word (4 bytes) long, but the actual data is packed in the following halfword.

```asm
.hword 0b0001000000100001                        // SECURE mode (0x1021)
```

This 16-bit value encodes the image properties:

| Bits | Value | Meaning |
|------|-------|---------|
| [2:0] | 001 | EXE (executable image) |
| [5] | 1 | Security: Secure mode |
| [12] | 1 | Architecture: ARM |

In hexadecimal: `0x1021`.  This tells the boot ROM to:
- Execute this image as a program (not a data partition)
- Run in Secure mode (TrustZone)
- Use the ARM Cortex-M33 core (not the RISC-V Hazard3)

### Last Item Marker

```asm
.byte  0xff                                      // PICOBIN_BLOCK_ITEM_2BS_LAST
```

Marks the end of the item list.  `0xff` is a sentinel value that tells the boot ROM there are no more items in this block.

```asm
.hword 0x0001                                    // item is 1 word in size
```

Size of the terminator item.

```asm
.byte  0x0                                       // pad
```

Padding byte to maintain 4-byte alignment for the following words.

### Block Linkage

```asm
.word  0x0                                       // relative pointer to next block (0 = loop to self)
```

A relative pointer to the next IMAGE_DEF block.  `0x0` means this block points to itself — there is only one block.  In more complex binaries, multiple blocks can form a linked list.

### End Marker

```asm
.word  0xab123579                                // PICOBIN_BLOCK_MARKER_END
```

A 32-bit magic number that marks the end of the block.  The boot ROM verifies both the start and end markers to confirm the block is valid.

## Binary Layout

The IMAGE_DEF block occupies 24 bytes starting at address 0x10000000:

```
  0x10000000: D3 DE FF FF   (start marker, little-endian)
  0x10000004: 42 01 21 10   (image type item)
  0x10000008: FF 01 00 00   (last item + pad)
  0x1000000C: 00 00 00 00   (next block pointer)
  0x10000010: 79 35 12 AB   (end marker, little-endian)
```

Note: all multi-byte values are stored in little-endian byte order, as required by the Cortex-M33.

## Why This File Exists

The RP2350 is a significant departure from the RP2040.  The RP2040 required a checksummed "boot2" flash setup function at address 0.  The RP2350 instead requires this metadata block, which:

1. Identifies the binary as a valid program
2. Specifies the security mode (Secure, Non-secure, or unspecified)
3. Specifies the architecture (ARM or RISC-V)
4. Is simpler than the RP2040's boot2 requirement

Without a valid IMAGE_DEF block, the boot ROM assumes flash is blank or contains no valid program.

## Summary

- image_def.s creates a 24-byte metadata block at the start of flash.
- The block contains start/end markers, an image type item, and a block linkage pointer.
- The image type encodes: ARM architecture, Secure mode, executable.
- The linker script places this section first in flash so the boot ROM finds it immediately.
- This file is mandatory — removing it prevents the RP2350 from booting.
