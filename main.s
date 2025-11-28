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
