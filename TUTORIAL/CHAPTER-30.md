# Chapter 30: Full Integration — Build, Flash, Wire, and Test

## Introduction

This final chapter ties everything together.  We build the firmware from source, connect the hardware, flash the binary onto the RP2350, and verify that the LED responds to button presses.  Every step from source code to running silicon is covered.

## The Complete System

The button driver comprises 13 source files and 1 linker script:

| File             | Purpose                          |
|------------------|----------------------------------|
| image_def.s      | Boot metadata (.picobin_block)   |
| vector_table.s   | Stack pointer and reset vector   |
| stack.s          | Stack initialization             |
| reset_handler.s  | Boot sequence orchestrator       |
| xosc.s           | Crystal oscillator and clock     |
| reset.s          | Peripheral reset controller      |
| coprocessor.s    | Enable coprocessor CP0           |
| constants.s      | All address and offset constants |
| gpio.s           | GPIO output configuration        |
| delay.s          | Millisecond busy-wait delay      |
| button.s         | Button input driver (GPIO15)     |
| main.s           | Application entry point          |
| linker.ld        | Memory layout and section rules  |
| build.bat        | Build automation script          |

## Boot Order

```
Power On
    |
    v
RP2350 ROM Bootloader
    |
    v
Reads .picobin_block from flash
    |
    v
Loads vector table from .vectors
    |
    v
Sets MSP = STACK_TOP (0x20082000)
    |
    v
Jumps to Reset_Handler (with Thumb bit)
    |
    v
Reset_Handler:
    bl Init_Stack              // configure PSP, MSPLIM, PSPLIM, MSP
    bl Init_XOSC               // start 12 MHz crystal
    bl Enable_XOSC_Peri_Clock  // route crystal to peripherals
    bl Init_Subsystem          // bring IO_BANK0 out of reset
    bl Enable_Coprocessor      // enable GPIO coprocessor
    b  main                    // jump to application
    |
    v
main:
    GPIO_Config(GPIO16)        // LED output
    Button_Init()              // Button input (GPIO15)
    Loop forever:
        read button → drive LED → delay 10ms
```

## Building the Firmware

### The Build Script

```bat
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o image_def.o image_def.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o vector_table.o vector_table.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o stack.o stack.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o reset_handler.o reset_handler.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o xosc.o xosc.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o reset.o reset.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o coprocessor.o coprocessor.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o gpio.o gpio.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o delay.o delay.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o button.o button.s
arm-none-eabi-as -g -mcpu=cortex-m33 -mthumb -o main.o main.s
arm-none-eabi-ld -T linker.ld -o button.elf image_def.o vector_table.o stack.o reset_handler.o xosc.o reset.o coprocessor.o gpio.o delay.o button.o main.o
arm-none-eabi-objcopy -O binary button.elf button.bin
python uf2conv.py button.bin --base 0x10000000 --family 0xe48bff59 --output button.uf2
```

Four stages:

1. **Assemble**: Each `.s` file → `.o` object file.  The `-g` flag includes debug symbols.  `-mcpu=cortex-m33 -mthumb` targets the RP2350's ARM core.

2. **Link**: All `.o` files → `button.elf`.  The linker script places sections at their correct flash addresses.

3. **Extract**: `objcopy` strips ELF metadata → raw `button.bin` binary.

4. **Package**: `uf2conv.py` wraps the binary in UF2 format with family ID `0xe48bff59` (RP2350 ARM) and base address `0x10000000` (start of flash).

### Running the Build

Open a terminal in the project directory and run:

```
build.bat
```

Expected output shows each assembly and link command.  If successful, `button.uf2` appears in the project directory.

## Hardware Wiring

### Components Needed

- RP2350 development board (Raspberry Pi Pico 2 or equivalent)
- Tactile push button (normally open)
- LED (any color)
- 330 ohm resistor (for LED current limiting)
- Breadboard and jumper wires
- USB cable

### Wiring Diagram

```
                 RP2350
              +----------+
              |          |
              |  GPIO15  |----+---- Button ---- GND
              |          |    |
              |          |   (internal pull-up ~50kohm)
              |          |
              |  GPIO16  |---- 330ohm ---- LED ---- GND
              |          |
              |   GND    |---- GND rail
              +----------+
```

### Button Circuit (GPIO15)

Connect one terminal of the push button to GPIO15 and the other terminal to GND.  No external pull-up resistor is needed — the firmware enables the internal pull-up (~50 kohm) in Button_Init:

- **Button released**: Internal pull-up holds GPIO15 high (1)
- **Button pressed**: Button shorts GPIO15 to GND, pulling it low (0)

This is an active-low configuration.

### LED Circuit (GPIO16)

Connect GPIO16 to the anode (long leg) of the LED through a 330 ohm resistor.  Connect the cathode (short leg) to GND.

Current calculation at 3.3V:

$$I = \frac{V_{GPIO} - V_{LED}}{R} = \frac{3.3 - 2.0}{330} \approx 3.9 \text{ mA}$$

This is well within the RP2350's maximum drive strength of 12 mA per GPIO pin.

## Flashing the Firmware

### Method 1: UF2 Drag-and-Drop

1. Hold the BOOTSEL button on the RP2350 board
2. Connect the USB cable (or press RESET while holding BOOTSEL)
3. Release BOOTSEL — a USB drive named `RP2350` appears
4. Copy `button.uf2` to the drive
5. The board automatically reboots and runs the firmware

### Method 2: picotool

```
picotool load button.uf2 -f
```

The `-f` flag forces a reboot after loading.

### Method 3: OpenOCD (Debug Probe)

```
openocd -f interface/cmsis-dap.cfg -f target/rp2350.cfg -c "adapter speed 5000" -c "program button.elf verify reset exit"
```

This method uses a debug probe (such as a second Pico running the debugprobe firmware) connected via the SWD pins.  It programs the ELF file directly, verifies the flash contents, and resets the target.

## Testing

### Expected Behavior

After flashing:

1. The LED is **off** when the button is not pressed
2. Press the button — the LED turns **on** immediately
3. Release the button — the LED turns **off** immediately
4. The response feels instantaneous (10ms polling delay is imperceptible)

### Troubleshooting

| Symptom                  | Possible Cause                        |
|--------------------------|---------------------------------------|
| LED always off           | Check LED polarity and resistor value |
| LED always on            | Check button wiring (both terminals)  |
| LED flickers on press    | Contact bounce — verify 10ms delay    |
| No response at all       | Verify UF2 copied and board rebooted  |
| Board not in BOOTSEL     | Hold BOOTSEL before connecting USB    |

### Verifying with a Debugger

If using OpenOCD with a debug probe:

```
openocd -f interface/cmsis-dap.cfg -f target/rp2350.cfg -c "adapter speed 5000"
```

In another terminal:

```
arm-none-eabi-gdb button.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) break main
(gdb) continue
```

You can single-step through the initialization sequence and inspect registers to verify each peripheral is configured correctly.

## Memory Layout

The final binary occupies flash starting at 0x10000000:

```
0x10000000  +-------------------+
            | .embedded_block   |  Boot metadata (20 bytes)
            +-------------------+
            | .vectors          |  Stack pointer + reset vector (8 bytes)
            +-------------------+
            | .text             |  All executable code
            |   reset_handler   |
            |   stack           |
            |   xosc            |
            |   reset           |
            |   coprocessor     |
            |   gpio            |
            |   delay           |
            |   button          |
            |   main            |
            |   literal pools   |
            +-------------------+
            | .rodata           |  Read-only data (empty)
            +-------------------+

0x20000000  +-------------------+
            | RAM               |  .data + .bss (empty)
            |                   |
            | ...               |
            |                   |
0x2007A000  | PSPLIM            |  Stack limit
            | Stack (32K)       |
0x20082000  | STACK_TOP / MSP   |  Stack grows downward
            +-------------------+
```

## What We Built

Starting from nothing but the RP2350 datasheet and an assembler, we built a complete bare-metal button driver:

- **No C compiler** — every instruction was written by hand in ARM assembly
- **No SDK** — all peripheral registers accessed directly through MMIO and coprocessor instructions
- **No RTOS** — a single infinite polling loop with deterministic timing
- **13 source files** — each with a single clear responsibility
- **~250 lines of assembly** — enough to boot the chip, configure two GPIO pins, and respond to a button in real time

The firmware initializes the hardware from cold boot, configures GPIO15 as a pulled-up input, configures GPIO16 as a driven output, and enters a loop that mirrors the button state to the LED at 100 Hz.

## Summary

This tutorial covered the complete journey from silicon to software:

1. **Foundations** (Chapters 1-6): How computers work, number systems, and the fetch-decode-execute cycle
2. **Instruction Set** (Chapters 7-12): ARM Cortex-M33 instructions used in the driver
3. **Assembly Programming** (Chapters 13-17): Directives, calling conventions, and hardware bit manipulation
4. **Hardware** (Chapter 18): The RP2350 architecture and peripheral system
5. **Build System** (Chapters 19-20): Linker scripts and the assembly-to-UF2 pipeline
6. **Source Walkthroughs** (Chapters 21-29): Every source file explained line by line
7. **Integration** (Chapter 30): Building, wiring, flashing, and testing the complete system

Every concept was grounded in real code running on real hardware.  The button driver is minimal but complete — a foundation for understanding how software meets silicon.
