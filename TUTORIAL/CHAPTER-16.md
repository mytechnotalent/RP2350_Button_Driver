# Chapter 16: Bitwise Operations for Hardware Programming

## Introduction

Configuring hardware registers means setting, clearing, and testing individual bits.  This chapter shows how every bitwise operation in our button driver maps to a specific hardware configuration task, using real binary values from the RP2350 datasheet.

## The Problem: Modifying Individual Bits

Hardware peripheral registers pack multiple configuration fields into a single 32-bit word.  For example, the GPIO15 pad control register contains:

| Bit | Field | Meaning |
|-----|-------|---------|
| 8 | ISO | Pad isolation |
| 7 | OD | Output disable |
| 6 | IE | Input enable |
| 5:4 | DRIVE | Drive strength |
| 3 | PUE | Pull-up enable |
| 2 | PDE | Pull-down enable |
| 1 | SCHMITT | Schmitt trigger |
| 0 | SLEWFAST | Slew rate |

To configure GPIO15 as a button input with pull-up, we need to modify bits 2, 3, 6, 7, and 8 without changing the others.

## Setting a Bit: orr

To force a bit to 1, OR the register with a mask that has a 1 at the target position:

```asm
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
```

**Before:** `r5 = 0b_xxxx_xxxx_xxxx_xxxx_xxxx_xxx0_xxxx_xxxx`
**Mask:**        `0b_0000_0000_0000_0000_0000_0001_0000_0000` = `(1<<6)` = `0x40`
**After:**  `r5 = 0b_xxxx_xxxx_xxxx_xxxx_xxxx_xxx1_xxxx_xxxx`

Only bit 6 changes; all other bits remain exactly as they were.

### Setting Multiple Bits

In button.s, two consecutive `orr` instructions set IE and PUE:

```asm
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
  orr   r5, r5, #(1<<3)                          // set PUE bit (pull-up enable)
```

After both: bits 6 and 3 are set, everything else unchanged.

## Clearing a Bit: bic

To force a bit to 0, use BIC (Bit Clear), which ANDs with the complement of the mask:

```asm
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
```

**Before:** `r5 = 0b_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx`
**Mask:**        `(1<<7)` = `0x80`
**NOT mask:**    `0b_1111_1111_1111_1111_1111_1111_0111_1111`
**After:**  `r5 = 0b_xxxx_xxxx_xxxx_xxxx_xxxx_xxx0_xxxx_xxxx` (bit 7 = 0)

### Clearing a Multi-Bit Field

The FUNCSEL field is 5 bits wide (bits [4:0]).  To clear it before writing a new value:

```asm
  bic   r5, r5, #0x1f                            // clear FUNCSEL
```

**Mask:** `0x1f` = `0b_0001_1111` — bits [4:0]
**NOT mask:** `0b_1111_1111_1111_1111_1111_1111_1110_0000`

This clears all 5 bits of FUNCSEL, preparing them for the new value.

## Clear-Then-Set Pattern

To write a specific value into a multi-bit field:

```asm
  bic   r5, r5, #0x1f                            // clear FUNCSEL
  orr   r5, r5, #0x05                            // set FUNCSEL 0x05->SIO_0
```

Step 1: BIC clears bits [4:0] to `00000`.
Step 2: ORR sets bits [4:0] to `00101` (SIO function select = 5).

This two-instruction sequence safely updates the field regardless of its previous value.

## Testing a Bit: tst

To check if a specific bit is set without modifying the register:

```asm
  tst   r1, #(1<<31)                             // test STABLE bit
  beq   .Init_XOSC_Wait                          // wait until stable bit is set
```

`tst` computes `r1 AND 0x80000000` and sets the Z flag:
- If bit 31 = 0: result is 0, Z=1, `beq` branches (keep waiting)
- If bit 31 = 1: result is non-zero, Z=0, `beq` falls through (oscillator stable)

Also used in reset.s:

```asm
  tst   r1, #(1<<6)                              // test IO_BANK0 reset done
  beq   .GPIO_Subsystem_Reset_Wait               // wait until done
```

## Bitwise AND for Masking: and

To extract a single bit from a multi-bit value:

```asm
  and   r0, r4, #1                               // mask to get just bit 0
```

After shifting GPIO15's bit to position 0 with `lsr`, this discards all other bits:

**Before:** `r4 = 0b_0000_0000_0000_0000_xxxx_xxxx_xxxx_xxxB`
**Mask:**        `0b_0000_0000_0000_0000_0000_0000_0000_0001`
**After:**  `r0 = 0b_0000_0000_0000_0000_0000_0000_0000_000B`

The result is exactly 0 or 1.

## Bitwise XOR for Inversion: eor

To flip a bit:

```asm
  eor   r0, r0, #1                               // invert (pressed=1, released=0)
```

XOR with 1 inverts bit 0:
- `0 XOR 1 = 1` (pressed GPIO → active-high pressed)
- `1 XOR 1 = 0` (released GPIO → active-high released)

This is the key to converting the button's active-low hardware signal (0 when pressed, 1 when released) to an active-high software representation (1 when pressed, 0 when released).

## Shift for Bit Extraction: lsr

To move a bit from an arbitrary position to bit 0:

```asm
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
```

The `mrc` instruction reads all 32 GPIO input pins.  GPIO15's state is in bit 15.  The shift moves it to bit 0 where `and r0, r4, #1` can extract it.

**Before:** `r4 = 0b_xxxx_xxxx_xxxx_xxxB_xxxx_xxxx_xxxx_xxxx` (B at bit 15)
**After:**  `r4 = 0b_0000_0000_0000_0000_xxxx_xxxx_xxxx_xxxB` (B at bit 0)

## Complete Button Read Sequence

The full bit extraction in Button_Read combines three operations:

```asm
  mrc   p0, #0, r4, c0, c8                       // read all 32 GPIO input pins
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
  and   r0, r4, #1                               // mask to get just bit 0
```

1. **Read** all 32 GPIO inputs into r4
2. **Shift** GPIO15's bit from position 15 to position 0
3. **Mask** to isolate the single bit

Result: r0 = 0 (pressed) or r0 = 1 (released).

## The Complete Pad Configuration Sequence

Button_Init configures five bits in the GPIO15 pad register:

```asm
  ldr   r5, [r4]                                 // read PAD_OFFSET value
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
  orr   r5, r5, #(1<<3)                          // set PUE bit (pull-up enable)
  bic   r5, r5, #(1<<2)                          // clear PDE bit (pull-down disable)
  bic   r5, r5, #(1<<8)                          // clear ISO bit
  str   r5, [r4]                                 // store value into PAD_OFFSET
```

| Operation | Bit | Before | After | Purpose |
|-----------|-----|--------|-------|---------|
| `bic #(1<<7)` | 7 | x | 0 | Disable output driver |
| `orr #(1<<6)` | 6 | x | 1 | Enable input receiver |
| `orr #(1<<3)` | 3 | x | 1 | Enable pull-up resistor |
| `bic #(1<<2)` | 2 | x | 0 | Disable pull-down resistor |
| `bic #(1<<8)` | 8 | x | 0 | Disable pad isolation |

## Summary

- `orr` sets individual bits — used to enable input, pull-up, and function select.
- `bic` clears individual bits — used to disable output, pull-down, and isolation.
- `tst` tests bits without modification — used to poll hardware status.
- `and` masks bits to extract values — used to isolate the GPIO15 state.
- `eor` inverts bits — used to convert active-low to active-high.
- `lsr` shifts bits into position — used to move GPIO15 from bit 15 to bit 0.
- The clear-then-set pattern (`bic` + `orr`) safely updates multi-bit fields.
