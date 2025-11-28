/**
 * FILE: button.s
 *
 * DESCRIPTION:
 * RP2350 Button Driver Functions.
 * 
 * BRIEF:
 * Provides button initialization and reading functions for GPIO15.
 * Configures the button pin as input with pull-up resistor enabled.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 28, 2025
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
 * @brief   Initialize button on GPIO15.
 *
 * @details Configures GPIO15 as input with pull-up resistor enabled.
 *          Button is active-low (pressed = 0, released = 1).
 *
 * @param   None
 * @retval  None
 */
.global Button_Init
.type Button_Init, %function
Button_Init:
.Button_Init_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.Button_Init_Modify_Pad:
  ldr   r4, =PADS_BANK0_BASE                     // load PADS_BANK0_BASE address
  ldr   r5, =PADS_BANK0_GPIO15_OFFSET            // load GPIO15 pad offset
  add   r4, r4, r5                               // PADS_BANK0_BASE + PAD_OFFSET
  ldr   r5, [r4]                                 // read PAD_OFFSET value
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
  orr   r5, r5, #(1<<3)                          // set PUE bit (pull-up enable)
  bic   r5, r5, #(1<<2)                          // clear PDE bit (pull-down disable)
  bic   r5, r5, #(1<<8)                          // clear ISO bit
  str   r5, [r4]                                 // store value into PAD_OFFSET
.Button_Init_Modify_CTRL:
  ldr   r4, =IO_BANK0_BASE                       // load IO_BANK0 base
  ldr   r5, =IO_BANK0_GPIO15_CTRL_OFFSET         // load GPIO15 ctrl offset
  add   r4, r4, r5                               // IO_BANK0_BASE + CTRL_OFFSET
  ldr   r5, [r4]                                 // read CTRL_OFFSET value
  bic   r5, r5, #0x1f                            // clear FUNCSEL
  orr   r5, r5, #0x05                            // set FUNCSEL 0x05->SIO_0
  str   r5, [r4]                                 // store value into CTRL_OFFSET
.Button_Init_Disable_OE:
  ldr   r4, =0                                   // disable output
  ldr   r5, =15                                  // GPIO15
  mcrr  p0, #4, r5, r4, c4                       // gpioc_bit_oe_put(GPIO15, 0)
.Button_Init_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return

/**
 * @brief   Read button state.
 *
 * @details Reads the current state of the button on GPIO15.
 *          Returns 0 if button is pressed, 1 if released.
 *
 * @param   None
 * @retval  r0 - Button state (0 = pressed, 1 = released)
 */
.global Button_Read
.type Button_Read, %function
Button_Read:
.Button_Read_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.Button_Read_Execute:
  mrc   p0, #0, r4, c0, c8                       // gpioc_lo_in_get - read all lower 32 GPIO inputs
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
  and   r0, r4, #1                               // mask to get just bit 0
.Button_Read_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return

/**
 * @brief   Check if button is pressed.
 *
 * @details Returns 1 if button is currently pressed, 0 otherwise.
 *
 * @param   None
 * @retval  r0 - 1 if pressed, 0 if not pressed
 */
.global Button_IsPressed
.type Button_IsPressed, %function
Button_IsPressed:
.Button_IsPressed_Push_Registers:
  push  {r4-r12, lr}                             // push registers r4-r12, lr to the stack
.Button_IsPressed_Read:
  bl    Button_Read                              // read button state
  eor   r0, r0, #1                               // invert (pressed=1, released=0)
.Button_IsPressed_Pop_Registers:
  pop   {r4-r12, lr}                             // pop registers r4-r12, lr from the stack
  bx    lr                                       // return
