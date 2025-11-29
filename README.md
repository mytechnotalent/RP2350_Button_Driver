<img src="https://github.com/mytechnotalent/RP2350_Button_Driver/blob/main/RP2350_Button_Driver.png?raw=true">

## FREE Reverse Engineering Self-Study Course [HERE](https://github.com/mytechnotalent/Reverse-Engineering-Tutorial)
### VIDEO PROMO [HERE](https://www.youtube.com/watch?v=aD7X9sXirF8)

<br>

# RP2350 Button Driver
An RP2350 Button driver written entirely in Assembler.

<br>

# Install ARM Toolchain
## NOTE: Be SURE to select `Add path to environment variable` on setup.
[HERE](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)

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

<br>

main.s Code
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
