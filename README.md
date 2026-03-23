## FREE Reverse Engineering Self-Study Course [HERE](https://github.com/mytechnotalent/Reverse-Engineering-Tutorial)
### VIDEO PROMO [HERE](https://www.youtube.com/watch?v=aD7X9sXirF8)

<br>

# RP2350 Button Driver
An RP2350 Button driver written entirely in ARM Assembler.

<br>

# Install ARM Toolchain (Windows / RP2350 Cortex-M33)
Official Raspberry Pi guidance for RP2350 ARM recommends the Arm GNU Toolchain from developer.arm.com.

## Official References
- Raspberry Pi Pico SDK quick start: [HERE](https://github.com/raspberrypi/pico-sdk#quick-start-your-own-project)
- Tool downloads (official): [HERE](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)

## Install (PowerShell)
```powershell
$url = "https://developer.arm.com/-/media/Files/downloads/gnu/15.2.rel1/binrel/arm-gnu-toolchain-15.2.rel1-mingw-w64-x86_64-arm-none-eabi.zip"
$zipPath = "$env:TEMP\arm-toolchain-15-x64-win.zip"
$extractPath = "$env:TEMP\arm-extract"
$dest = "$HOME\arm-toolchain-15"

Invoke-WebRequest -Uri $url -OutFile $zipPath
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force
Move-Item "$extractPath\arm-gnu-toolchain-*" $dest -Force
Get-ChildItem -Path $dest | Select-Object Name
```

## Add Toolchain To User PATH (PowerShell)
```powershell
$toolBin = "$HOME\arm-toolchain-15\bin"
$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentUserPath -notlike "*$toolBin*") {
  [Environment]::SetEnvironmentVariable("Path", "$currentUserPath;$toolBin", "User")
}
```

Close and reopen your terminal after updating PATH.

## Verify Toolchain
```powershell
arm-none-eabi-as --version
arm-none-eabi-ld --version
arm-none-eabi-objcopy --version
```

## Build This Project
```powershell
.\build.bat
```

## Button + LED Wiring (Pico 2 Target)
- GP15 (Pin 20) → tactile button → GND (internal pull-up enabled)
- GP16 (Pin 21) → 330 ohm resistor → LED anode
- LED cathode → GND (Pin 23)

<br>

# Hardware
## Raspberry Pi Pico 2 w/ Header [BUY](https://www.pishop.us/product/raspberry-pi-pico-2-with-header)
## USB A-Male to USB Micro-B Cable [BUY](https://www.pishop.us/product/usb-a-male-to-usb-micro-b-cable-6-inches)
## Raspberry Pi Pico Debug Probe [BUY](https://www.pishop.us/product/raspberry-pi-debug-probe)
## Complete Component Kit for Raspberry Pi [BUY](https://www.pishop.us/product/complete-component-kit-for-raspberry-pi)
## 10pc 25v 1000uF Capacitor [BUY](https://www.amazon.com/Cionyce-Capacitor-Electrolytic-CapacitorsMicrowave/dp/B0B63CCQ2N?th=1)
### 10% PiShop DISCOUNT CODE - KVPE_HS320548_10PC

<br>

# Build
```
.\build.bat
```

<br>

# Clean
```
.\clean.bat
```

# Tutorial

## Part I — Foundations (Chapters 1–6)

### [Chapter 1: What Is a Computer?](TUTORIAL/CHAPTER-01.md)
- [Introduction](TUTORIAL/CHAPTER-01.md#introduction)
- [The Fetch-Decode-Execute Cycle](TUTORIAL/CHAPTER-01.md#the-fetch-decode-execute-cycle)
- [The Three Core Components](TUTORIAL/CHAPTER-01.md#the-three-core-components)
- [Microcontroller vs Desktop Computer](TUTORIAL/CHAPTER-01.md#microcontroller-vs-desktop-computer)
- [What Is RP2350?](TUTORIAL/CHAPTER-01.md#what-is-rp2350)
- [What Is ARM Cortex-M33?](TUTORIAL/CHAPTER-01.md#what-is-arm-cortex-m33)
- [What Is Assembly Language?](TUTORIAL/CHAPTER-01.md#what-is-assembly-language)
- [Why Learn Assembly?](TUTORIAL/CHAPTER-01.md#why-learn-assembly)
- [What We Will Build](TUTORIAL/CHAPTER-01.md#what-we-will-build)
- [Summary](TUTORIAL/CHAPTER-01.md#summary)

### [Chapter 2: Number Systems](TUTORIAL/CHAPTER-02.md)
- [Introduction](TUTORIAL/CHAPTER-02.md#introduction)
- [Decimal (Base 10)](TUTORIAL/CHAPTER-02.md#decimal-base-10)
- [Binary (Base 2)](TUTORIAL/CHAPTER-02.md#binary-base-2)
- [Hexadecimal (Base 16)](TUTORIAL/CHAPTER-02.md#hexadecimal-base-16)
- [Number Prefixes in ARM Assembly](TUTORIAL/CHAPTER-02.md#number-prefixes-in-arm-assembly)
- [Bit Masks](TUTORIAL/CHAPTER-02.md#bit-masks)
- [Register Values as Hex](TUTORIAL/CHAPTER-02.md#register-values-as-hex)
- [Summary](TUTORIAL/CHAPTER-02.md#summary)

### [Chapter 3: Memory](TUTORIAL/CHAPTER-03.md)
- [Introduction](TUTORIAL/CHAPTER-03.md#introduction)
- [Addresses and Bytes](TUTORIAL/CHAPTER-03.md#addresses-and-bytes)
- [Words](TUTORIAL/CHAPTER-03.md#words)
- [Endianness](TUTORIAL/CHAPTER-03.md#endianness)
- [The RP2350 Memory Map](TUTORIAL/CHAPTER-03.md#the-rp2350-memory-map)
- [Flash Memory — Where Our Code Lives](TUTORIAL/CHAPTER-03.md#flash-memory--where-our-code-lives)
- [SRAM — Where the Stack Lives](TUTORIAL/CHAPTER-03.md#sram--where-the-stack-lives)
- [Peripheral Registers — Memory-Mapped I/O](TUTORIAL/CHAPTER-03.md#peripheral-registers--memory-mapped-io)
- [Addresses in Our Firmware](TUTORIAL/CHAPTER-03.md#addresses-in-our-firmware)
- [Alignment](TUTORIAL/CHAPTER-03.md#alignment)
- [Summary](TUTORIAL/CHAPTER-03.md#summary)

### [Chapter 4: What Is a Register?](TUTORIAL/CHAPTER-04.md)
- [Introduction](TUTORIAL/CHAPTER-04.md#introduction)
- [General-Purpose Registers](TUTORIAL/CHAPTER-04.md#general-purpose-registers)
- [Special-Purpose Registers](TUTORIAL/CHAPTER-04.md#special-purpose-registers)
- [Stack Limit Registers](TUTORIAL/CHAPTER-04.md#stack-limit-registers)
- [The Program Status Register (xPSR)](TUTORIAL/CHAPTER-04.md#the-program-status-register-xpsr)
- [CPACR — Coprocessor Access Control](TUTORIAL/CHAPTER-04.md#cpacr--coprocessor-access-control)
- [Register Usage in Our Button Driver](TUTORIAL/CHAPTER-04.md#register-usage-in-our-button-driver)
- [Summary](TUTORIAL/CHAPTER-04.md#summary)

### [Chapter 5: Load-Store Architecture](TUTORIAL/CHAPTER-05.md)
- [Introduction](TUTORIAL/CHAPTER-05.md#introduction)
- [The Load-Store Rule](TUTORIAL/CHAPTER-05.md#the-load-store-rule)
- [Load Instructions in Our Firmware](TUTORIAL/CHAPTER-05.md#load-instructions-in-our-firmware)
- [Store Instructions in Our Firmware](TUTORIAL/CHAPTER-05.md#store-instructions-in-our-firmware)
- [The Read-Modify-Write Pattern](TUTORIAL/CHAPTER-05.md#the-read-modify-write-pattern)
- [Push and Pop — Stack Access](TUTORIAL/CHAPTER-05.md#push-and-pop--stack-access)
- [Why Load-Store?](TUTORIAL/CHAPTER-05.md#why-load-store)
- [Summary](TUTORIAL/CHAPTER-05.md#summary)

### [Chapter 6: Fetch-Decode-Execute Cycle in Detail](TUTORIAL/CHAPTER-06.md)
- [Introduction](TUTORIAL/CHAPTER-06.md#introduction)
- [The Three Phases](TUTORIAL/CHAPTER-06.md#the-three-phases)
- [The Cortex-M33 Pipeline](TUTORIAL/CHAPTER-06.md#the-cortex-m33-pipeline)
- [Sequential Execution Example](TUTORIAL/CHAPTER-06.md#sequential-execution-example)
- [Branch Penalty](TUTORIAL/CHAPTER-06.md#branch-penalty)
- [Conditional Execution](TUTORIAL/CHAPTER-06.md#conditional-execution)
- [The Clock](TUTORIAL/CHAPTER-06.md#the-clock)
- [Summary](TUTORIAL/CHAPTER-06.md#summary)

## Part II — The ARM Instruction Set (Chapters 7–12)

### [Chapter 7: ARM Cortex-M33 ISA Overview](TUTORIAL/CHAPTER-07.md)
- [Introduction](TUTORIAL/CHAPTER-07.md#introduction)
- [What Is an ISA?](TUTORIAL/CHAPTER-07.md#what-is-an-isa)
- [Thumb-2: Mixed 16-bit and 32-bit Instructions](TUTORIAL/CHAPTER-07.md#thumb-2-mixed-16-bit-and-32-bit-instructions)
- [Instruction Categories](TUTORIAL/CHAPTER-07.md#instruction-categories)
- [Condition Flags](TUTORIAL/CHAPTER-07.md#condition-flags)
- [Unified Assembly Syntax](TUTORIAL/CHAPTER-07.md#unified-assembly-syntax)
- [Instruction Encoding Example](TUTORIAL/CHAPTER-07.md#instruction-encoding-example)
- [Complete Instruction Map for This Driver](TUTORIAL/CHAPTER-07.md#complete-instruction-map-for-this-driver)
- [Summary](TUTORIAL/CHAPTER-07.md#summary)

### [Chapter 8: Immediate and Upper-Immediate Instructions](TUTORIAL/CHAPTER-08.md)
- [Introduction](TUTORIAL/CHAPTER-08.md#introduction)
- [What Is an Immediate Value?](TUTORIAL/CHAPTER-08.md#what-is-an-immediate-value)
- [Thumb-2 Modified Immediate Encoding](TUTORIAL/CHAPTER-08.md#thumb-2-modified-immediate-encoding)
- [The Barrel Shifter](TUTORIAL/CHAPTER-08.md#the-barrel-shifter)
- [Constants That Don't Fit: The ldr Pseudo-Instruction](TUTORIAL/CHAPTER-08.md#constants-that-dont-fit-the-ldr-pseudo-instruction)
- [Immediate vs. Pseudo-Instruction Usage in Our Driver](TUTORIAL/CHAPTER-08.md#immediate-vs-pseudo-instruction-usage-in-our-driver)
- [The movw/movt Pair](TUTORIAL/CHAPTER-08.md#the-movwmovt-pair)
- [Summary](TUTORIAL/CHAPTER-08.md#summary)

### [Chapter 9: Arithmetic and Logic Instructions](TUTORIAL/CHAPTER-09.md)
- [Introduction](TUTORIAL/CHAPTER-09.md#introduction)
- [Arithmetic Instructions](TUTORIAL/CHAPTER-09.md#arithmetic-instructions)
- [Logic Instructions](TUTORIAL/CHAPTER-09.md#logic-instructions)
- [Shift Instructions](TUTORIAL/CHAPTER-09.md#shift-instructions)
- [Instruction Summary Table](TUTORIAL/CHAPTER-09.md#instruction-summary-table)
- [Summary](TUTORIAL/CHAPTER-09.md#summary)

### [Chapter 10: Memory Access — Load and Store Deep Dive](TUTORIAL/CHAPTER-10.md)
- [Introduction](TUTORIAL/CHAPTER-10.md#introduction)
- [Register-Indirect Addressing](TUTORIAL/CHAPTER-10.md#register-indirect-addressing)
- [Register-Indirect with Offset](TUTORIAL/CHAPTER-10.md#register-indirect-with-offset)
- [PC-Relative Loads (Literal Pools)](TUTORIAL/CHAPTER-10.md#pc-relative-loads-literal-pools)
- [Stack Operations: push and pop](TUTORIAL/CHAPTER-10.md#stack-operations-push-and-pop)
- [System Register Transfers: msr](TUTORIAL/CHAPTER-10.md#system-register-transfers-msr)
- [Coprocessor Memory Access](TUTORIAL/CHAPTER-10.md#coprocessor-memory-access)
- [Memory Access Timing](TUTORIAL/CHAPTER-10.md#memory-access-timing)
- [Summary](TUTORIAL/CHAPTER-10.md#summary)

### [Chapter 11: Branch Instructions](TUTORIAL/CHAPTER-11.md)
- [Introduction](TUTORIAL/CHAPTER-11.md#introduction)
- [Unconditional Branch: b](TUTORIAL/CHAPTER-11.md#unconditional-branch-b)
- [Conditional Branches](TUTORIAL/CHAPTER-11.md#conditional-branches)
- [Condition Code Summary](TUTORIAL/CHAPTER-11.md#condition-code-summary)
- [How the Processor Evaluates Conditions](TUTORIAL/CHAPTER-11.md#how-the-processor-evaluates-conditions)
- [Branch Encoding](TUTORIAL/CHAPTER-11.md#branch-encoding)
- [Control Flow in main.s](TUTORIAL/CHAPTER-11.md#control-flow-in-mains)
- [Summary](TUTORIAL/CHAPTER-11.md#summary)

### [Chapter 12: Jumps, Calls, and Returns](TUTORIAL/CHAPTER-12.md)
- [Introduction](TUTORIAL/CHAPTER-12.md#introduction)
- [bl — Branch with Link (Function Call)](TUTORIAL/CHAPTER-12.md#bl--branch-with-link-function-call)
- [bx lr — Branch to Link Register (Return)](TUTORIAL/CHAPTER-12.md#bx-lr--branch-to-link-register-return)
- [b — Tail Call (Branch Without Link)](TUTORIAL/CHAPTER-12.md#b--tail-call-branch-without-link)
- [The Call Stack in Action](TUTORIAL/CHAPTER-12.md#the-call-stack-in-action)
- [Link Register vs. Stack](TUTORIAL/CHAPTER-12.md#link-register-vs-stack)
- [The Thumb Bit](TUTORIAL/CHAPTER-12.md#the-thumb-bit)
- [Summary](TUTORIAL/CHAPTER-12.md#summary)

## Part III — Assembly Programming (Chapters 13–17)

### [Chapter 13: Pseudo-Instructions](TUTORIAL/CHAPTER-13.md)
- [Introduction](TUTORIAL/CHAPTER-13.md#introduction)
- [ldr Rd, =value — Load Constant](TUTORIAL/CHAPTER-13.md#ldr-rd-value--load-constant)
- [.type — Symbol Type Declaration](TUTORIAL/CHAPTER-13.md#type--symbol-type-declaration)
- [.global — Export Symbol](TUTORIAL/CHAPTER-13.md#global--export-symbol)
- [.size — Function Size](TUTORIAL/CHAPTER-13.md#size--function-size)
- [.equ — Define Constant](TUTORIAL/CHAPTER-13.md#equ--define-constant)
- [.include — Include File](TUTORIAL/CHAPTER-13.md#include--include-file)
- [Pseudo-Instructions vs. Directives](TUTORIAL/CHAPTER-13.md#pseudo-instructions-vs-directives)
- [Summary](TUTORIAL/CHAPTER-13.md#summary)

### [Chapter 14: Assembler Directives](TUTORIAL/CHAPTER-14.md)
- [Introduction](TUTORIAL/CHAPTER-14.md#introduction)
- [Processor Configuration Directives](TUTORIAL/CHAPTER-14.md#processor-configuration-directives)
- [Section Directives](TUTORIAL/CHAPTER-14.md#section-directives)
- [Alignment Directives](TUTORIAL/CHAPTER-14.md#alignment-directives)
- [Symbol Directives](TUTORIAL/CHAPTER-14.md#symbol-directives)
- [Data Directives](TUTORIAL/CHAPTER-14.md#data-directives)
- [Constant Directives](TUTORIAL/CHAPTER-14.md#constant-directives)
- [Label Directives](TUTORIAL/CHAPTER-14.md#label-directives)
- [KEEP Directive (Linker)](TUTORIAL/CHAPTER-14.md#keep-directive-linker)
- [Summary](TUTORIAL/CHAPTER-14.md#summary)

### [Chapter 15: Calling Convention and Stack Frames](TUTORIAL/CHAPTER-15.md)
- [Introduction](TUTORIAL/CHAPTER-15.md#introduction)
- [The AAPCS Register Convention](TUTORIAL/CHAPTER-15.md#the-aapcs-register-convention)
- [Arguments and Return Values](TUTORIAL/CHAPTER-15.md#arguments-and-return-values)
- [Saving and Restoring Registers](TUTORIAL/CHAPTER-15.md#saving-and-restoring-registers)
- [Stack Frame Layout](TUTORIAL/CHAPTER-15.md#stack-frame-layout)
- [Leaf Functions](TUTORIAL/CHAPTER-15.md#leaf-functions)
- [The Full Call Chain](TUTORIAL/CHAPTER-15.md#the-full-call-chain)
- [Summary](TUTORIAL/CHAPTER-15.md#summary)

### [Chapter 16: Bitwise Operations for Hardware Programming](TUTORIAL/CHAPTER-16.md)
- [Introduction](TUTORIAL/CHAPTER-16.md#introduction)
- [The Problem: Modifying Individual Bits](TUTORIAL/CHAPTER-16.md#the-problem-modifying-individual-bits)
- [Setting a Bit: orr](TUTORIAL/CHAPTER-16.md#setting-a-bit-orr)
- [Clearing a Bit: bic](TUTORIAL/CHAPTER-16.md#clearing-a-bit-bic)
- [Clear-Then-Set Pattern](TUTORIAL/CHAPTER-16.md#clear-then-set-pattern)
- [Testing a Bit: tst](TUTORIAL/CHAPTER-16.md#testing-a-bit-tst)
- [Bitwise AND for Masking: and](TUTORIAL/CHAPTER-16.md#bitwise-and-for-masking-and)
- [Bitwise XOR for Inversion: eor](TUTORIAL/CHAPTER-16.md#bitwise-xor-for-inversion-eor)
- [Shift for Bit Extraction: lsr](TUTORIAL/CHAPTER-16.md#shift-for-bit-extraction-lsr)
- [Complete Button Read Sequence](TUTORIAL/CHAPTER-16.md#complete-button-read-sequence)
- [The Complete Pad Configuration Sequence](TUTORIAL/CHAPTER-16.md#the-complete-pad-configuration-sequence)
- [Summary](TUTORIAL/CHAPTER-16.md#summary)

### [Chapter 17: Memory-Mapped I/O](TUTORIAL/CHAPTER-17.md)
- [Introduction](TUTORIAL/CHAPTER-17.md#introduction)
- [The RP2350 Address Space](TUTORIAL/CHAPTER-17.md#the-rp2350-address-space)
- [How Peripherals Respond to Writes](TUTORIAL/CHAPTER-17.md#how-peripherals-respond-to-writes)
- [How Peripherals Respond to Reads](TUTORIAL/CHAPTER-17.md#how-peripherals-respond-to-reads)
- [Constants as Address Guides](TUTORIAL/CHAPTER-17.md#constants-as-address-guides)
- [The MMIO Access Pattern](TUTORIAL/CHAPTER-17.md#the-mmio-access-pattern)
- [The Coprocessor Exception](TUTORIAL/CHAPTER-17.md#the-coprocessor-exception)
- [Volatile Access](TUTORIAL/CHAPTER-17.md#volatile-access)
- [Summary](TUTORIAL/CHAPTER-17.md#summary)

## Part IV — RP2350 Hardware (Chapter 18)

### [Chapter 18: The RP2350 — Architecture and Hardware](TUTORIAL/CHAPTER-18.md)
- [Introduction](TUTORIAL/CHAPTER-18.md#introduction)
- [RP2350 Overview](TUTORIAL/CHAPTER-18.md#rp2350-overview)
- [Block Diagram](TUTORIAL/CHAPTER-18.md#block-diagram)
- [Peripherals Used by Our Driver](TUTORIAL/CHAPTER-18.md#peripherals-used-by-our-driver)
- [The GPIO System](TUTORIAL/CHAPTER-18.md#the-gpio-system)
- [Boot Process](TUTORIAL/CHAPTER-18.md#boot-process)
- [Dual-Core and Security](TUTORIAL/CHAPTER-18.md#dual-core-and-security)
- [Summary](TUTORIAL/CHAPTER-18.md#summary)

## Part V — Build System (Chapters 19–20)

### [Chapter 19: The Linker Script — Placing Code in Memory](TUTORIAL/CHAPTER-19.md)
- [Introduction](TUTORIAL/CHAPTER-19.md#introduction)
- [The Complete Linker Script](TUTORIAL/CHAPTER-19.md#the-complete-linker-script)
- [Line-by-Line Walkthrough](TUTORIAL/CHAPTER-19.md#line-by-line-walkthrough)
- [Section Layout in Flash](TUTORIAL/CHAPTER-19.md#section-layout-in-flash)
- [Summary](TUTORIAL/CHAPTER-19.md#summary)

### [Chapter 20: The Build Pipeline — From Assembly to Flashable Binary](TUTORIAL/CHAPTER-20.md)
- [Introduction](TUTORIAL/CHAPTER-20.md#introduction)
- [The Build Script](TUTORIAL/CHAPTER-20.md#the-build-script)
- [Step 1: Assembly (Source to Object Files)](TUTORIAL/CHAPTER-20.md#step-1-assembly-source-to-object-files)
- [Step 2: Linking (Object Files to ELF)](TUTORIAL/CHAPTER-20.md#step-2-linking-object-files-to-elf)
- [Step 3: Binary Extraction (ELF to Raw Binary)](TUTORIAL/CHAPTER-20.md#step-3-binary-extraction-elf-to-raw-binary)
- [Step 4: UF2 Conversion (Binary to UF2)](TUTORIAL/CHAPTER-20.md#step-4-uf2-conversion-binary-to-uf2)
- [Flashing](TUTORIAL/CHAPTER-20.md#flashing)
- [The Complete Pipeline](TUTORIAL/CHAPTER-20.md#the-complete-pipeline)
- [Summary](TUTORIAL/CHAPTER-20.md#summary)

## Part VI — Source Code Walkthroughs (Chapters 21–29)

### [Chapter 21: Boot Metadata — image_def.s](TUTORIAL/CHAPTER-21.md)
- [Introduction](TUTORIAL/CHAPTER-21.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-21.md#the-complete-source)
- [Line-by-Line Walkthrough](TUTORIAL/CHAPTER-21.md#line-by-line-walkthrough)
- [Binary Layout](TUTORIAL/CHAPTER-21.md#binary-layout)
- [Why This File Exists](TUTORIAL/CHAPTER-21.md#why-this-file-exists)
- [Summary](TUTORIAL/CHAPTER-21.md#summary)

### [Chapter 22: Constants File — constants.s](TUTORIAL/CHAPTER-22.md)
- [Introduction](TUTORIAL/CHAPTER-22.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-22.md#the-complete-source)
- [Line-by-Line Walkthrough](TUTORIAL/CHAPTER-22.md#line-by-line-walkthrough)
- [Cross-Reference Table](TUTORIAL/CHAPTER-22.md#cross-reference-table)
- [Summary](TUTORIAL/CHAPTER-22.md#summary)

### [Chapter 23: Stack and Vector Table — stack.s and vector_table.s](TUTORIAL/CHAPTER-23.md)
- [Introduction](TUTORIAL/CHAPTER-23.md#introduction)
- [vector_table.s — The Complete Source](TUTORIAL/CHAPTER-23.md#vector_tables--the-complete-source)
- [stack.s — The Complete Source](TUTORIAL/CHAPTER-23.md#stacks--the-complete-source)
- [Initialization Order](TUTORIAL/CHAPTER-23.md#initialization-order)
- [Summary](TUTORIAL/CHAPTER-23.md#summary)

### [Chapter 24: Boot Sequence — reset_handler.s](TUTORIAL/CHAPTER-24.md)
- [Introduction](TUTORIAL/CHAPTER-24.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-24.md#the-complete-source)
- [Line-by-Line Walkthrough](TUTORIAL/CHAPTER-24.md#line-by-line-walkthrough)
- [Initialization Order Dependencies](TUTORIAL/CHAPTER-24.md#initialization-order-dependencies)
- [Why Reset_Handler Has No push/pop](TUTORIAL/CHAPTER-24.md#why-reset_handler-has-no-pushpop)
- [The Complete Boot Timeline](TUTORIAL/CHAPTER-24.md#the-complete-boot-timeline)
- [Summary](TUTORIAL/CHAPTER-24.md#summary)

### [Chapter 25: Oscillator Init — xosc.s](TUTORIAL/CHAPTER-25.md)
- [Introduction](TUTORIAL/CHAPTER-25.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-25.md#the-complete-source)
- [Init_XOSC — Line-by-Line](TUTORIAL/CHAPTER-25.md#init_xosc--line-by-line)
- [Enable_XOSC_Peri_Clock — Line-by-Line](TUTORIAL/CHAPTER-25.md#enable_xosc_peri_clock--line-by-line)
- [Both Functions Are Leaf Functions](TUTORIAL/CHAPTER-25.md#both-functions-are-leaf-functions)
- [Timing](TUTORIAL/CHAPTER-25.md#timing)
- [Summary](TUTORIAL/CHAPTER-25.md#summary)

### [Chapter 26: Reset Controller — reset.s](TUTORIAL/CHAPTER-26.md)
- [Introduction](TUTORIAL/CHAPTER-26.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-26.md#the-complete-source)
- [Line-by-Line Walkthrough](TUTORIAL/CHAPTER-26.md#line-by-line-walkthrough)
- [Why This Is Necessary](TUTORIAL/CHAPTER-26.md#why-this-is-necessary)
- [The Read-Modify-Write vs. Atomic Clear](TUTORIAL/CHAPTER-26.md#the-read-modify-write-vs-atomic-clear)
- [Leaf Function](TUTORIAL/CHAPTER-26.md#leaf-function)
- [Summary](TUTORIAL/CHAPTER-26.md#summary)

### [Chapter 27: GPIO Configuration — gpio.s](TUTORIAL/CHAPTER-27.md)
- [Introduction](TUTORIAL/CHAPTER-27.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-27.md#the-complete-source)
- [GPIO_Config — Line-by-Line](TUTORIAL/CHAPTER-27.md#gpio_config--line-by-line)
- [GPIO_Set — Line-by-Line](TUTORIAL/CHAPTER-27.md#gpio_set--line-by-line)
- [GPIO_Clear — Line-by-Line](TUTORIAL/CHAPTER-27.md#gpio_clear--line-by-line)
- [GPIO_Config vs. Button_Init](TUTORIAL/CHAPTER-27.md#gpio_config-vs-button_init)
- [Summary](TUTORIAL/CHAPTER-27.md#summary)

### [Chapter 28: Button Driver — button.s](TUTORIAL/CHAPTER-28.md)
- [Introduction](TUTORIAL/CHAPTER-28.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-28.md#the-complete-source)
- [Button_Init — Line-by-Line](TUTORIAL/CHAPTER-28.md#button_init--line-by-line)
- [Button_Read — Line-by-Line](TUTORIAL/CHAPTER-28.md#button_read--line-by-line)
- [Button_IsPressed — Line-by-Line](TUTORIAL/CHAPTER-28.md#button_ispressed--line-by-line)
- [The Three Functions Compared](TUTORIAL/CHAPTER-28.md#the-three-functions-compared)
- [Hardware Circuit](TUTORIAL/CHAPTER-28.md#hardware-circuit)
- [mrc vs. mcrr](TUTORIAL/CHAPTER-28.md#mrc-vs-mcrr)
- [Summary](TUTORIAL/CHAPTER-28.md#summary)

### [Chapter 29: Application Entry Point — main.s](TUTORIAL/CHAPTER-29.md)
- [Introduction](TUTORIAL/CHAPTER-29.md#introduction)
- [The Complete Source](TUTORIAL/CHAPTER-29.md#the-complete-source)
- [Line-by-Line Walkthrough](TUTORIAL/CHAPTER-29.md#line-by-line-walkthrough)
- [Control Flow Diagram](TUTORIAL/CHAPTER-29.md#control-flow-diagram)
- [Timing Analysis](TUTORIAL/CHAPTER-29.md#timing-analysis)
- [Why Button_Read Instead of Button_IsPressed?](TUTORIAL/CHAPTER-29.md#why-button_read-instead-of-button_ispressed)
- [Summary](TUTORIAL/CHAPTER-29.md#summary)

## Part VII — Full Integration (Chapter 30)

### [Chapter 30: Full Integration — Build, Flash, Wire, and Test](TUTORIAL/CHAPTER-30.md)
- [Introduction](TUTORIAL/CHAPTER-30.md#introduction)
- [The Complete System](TUTORIAL/CHAPTER-30.md#the-complete-system)
- [Boot Order](TUTORIAL/CHAPTER-30.md#boot-order)
- [Building the Firmware](TUTORIAL/CHAPTER-30.md#building-the-firmware)
- [Hardware Wiring](TUTORIAL/CHAPTER-30.md#hardware-wiring)
- [Flashing the Firmware](TUTORIAL/CHAPTER-30.md#flashing-the-firmware)
- [Testing](TUTORIAL/CHAPTER-30.md#testing)
- [Memory Layout](TUTORIAL/CHAPTER-30.md#memory-layout)
- [What We Built](TUTORIAL/CHAPTER-30.md#what-we-built)
- [Summary](TUTORIAL/CHAPTER-30.md#summary)

<br>

# main.s Code
```
/**
 * FILE: main.s
 *
 * DESCRIPTION:
 * RP2350 Button Driver Main Application.
 * 
 * BRIEF:
 * Main application entry point for RP2350 button driver. Monitors button
 * on GPIO15 and controls LED on GPIO16 based on button state.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 2, 2025
 * UPDATE DATE: November 28, 2025
 */

.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

/**
 * Initialize the .text section. 
 * The .text section contains executable code.
 */
.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

/**
 * @brief   Main application entry point.
 *
 * @details Implements button monitoring loop. LED on GPIO16 lights up
 *          when button on GPIO15 is pressed.
 *
 * @param   None
 * @retval  None
 */
.global main                                     // export main
.type main, %function                            // mark as function
main:
.Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.GPIO16_Config:
  ldr   r0, =PADS_BANK0_GPIO16_OFFSET            // load PADS_BANK0_GPIO16_OFFSET
  ldr   r1, =IO_BANK0_GPIO16_CTRL_OFFSET         // load IO_BANK0_GPIO16_CTRL_OFFSET
  ldr   r2, =16                                  // load GPIO number
  bl    GPIO_Config                              // call GPIO_Config
.Button_Init:
  bl    Button_Init                              // initialize button on GPIO15
.Loop:
  bl    Button_Read                              // read button state (0=pressed, 1=released)
  cmp   r0, #0                                   // compare with 0 (pressed)
  beq   .Button_Pressed                          // branch if button pressed (r0==0)
.Button_Released:
  ldr   r0, =16                                  // load GPIO number
  bl    GPIO_Clear                               // turn off LED
  b     .Loop_Delay                              // continue to delay
.Button_Pressed:
  ldr   r0, =16                                  // load GPIO number
  bl    GPIO_Set                                 // turn on LED
.Loop_Delay:
  ldr   r0, =10                                  // 10ms debounce delay
  bl    Delay_MS                                 // call Delay_MS
  b     .Loop                                    // loop forever
.Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return to caller

/**
 * Test data and constants.
 * The .rodata section is used for constants and static data.
 */
.section .rodata                                 // read-only data section

/**
 * Initialized global data.
 * The .data section is used for initialized global or static variables.
 */
.section .data                                   // data section

/**
 * Uninitialized global data.
 * The .bss section is used for uninitialized global or static variables.
 */
.section .bss                                    // BSS section
```

<br>

# License
[Apache License 2.0](https://github.com/mytechnotalent/RP2350_Blink_Driver/blob/main/LICENSE)
