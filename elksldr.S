.code16

.include "8018x.S"

// This should land on 0xF000:0xFFF0
.section .reset.text, "ax"

// Note: Most of this code comes directly from
// Wichit Sirichote's C188SBC https://www.kswichit.com/C188/c188sbc.htm
// and Intel's datasheet for the 80C188

.globl _cpu_reset_entrypoint
_cpu_reset_entrypoint:
    // Setup UCS now so it's possible to address the lower part of the 512kB FLASH
    mov $UCSST, %dx
    mov $0x8000, %ax
    out %ax, %dx
    ljmp $0xf000, $_init8018x_and_start

// This should land on 0xF000:0xF000
.section .text, "ax"
.globl _init8018x_and_start
_init8018x_and_start:
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss        // DS = ES = SS = 0x0000
    
    mov $0x600, %ax
    mov %ax, %sp        // Set a stack pointer starting at 0x0000:0x0600 (elks doesn't use this addresses)

    // Setup UCS and LCS
    mov $UCSSP, %dx     // FINISH SETTING UP UCS#
    mov $0x000e, %ax    // set ISTOP for 0FFFFF ending loaction
    out %al, %dx        // REMEMBER, BYTE WRITE WORK OK

    mov $LCSST, %dx     // SET UP LCS START REGISTER
    mov $0x0000, %ax    // LCS STARTS AT 0H, ZERO WAIT STATES!
    out %al, %dx        // REMEMBER, BYTE WRITES WORK OK

    mov $LCSSP, %dx     // SET UP LCS STOP REGISTER
    mov $0x800A, %ax    // 512kB Installed
    out %al, %dx        // REMEMBER, BYTE WRITES WORK OK
    // Now full FLASH and RAM should be properly mapped

    // Setup GCS6 so status leds are available at 0x2002
    mov $0x200f, %ax
    mov $0xff98, %dx
    out %ax, %dx
    mov $0x2048, %ax
    mov $0xff9a, %dx
    out %ax, %dx

    // turn some LEDs on :)
    mov $0x2002, %dx
    mov $0x00fe, %ax
    out %ax, %dx

    // Setup GCS4 for NE2K
    mov $0x030f, %ax
    mov $0xff90, %dx
    out %ax, %dx
    mov $0x03f8, %ax
    mov $0xff92, %dx
    out %ax, %dx

    // Setup internal serial port
    mov $B0CMP, %dx     // B0CMP
    //mov $0x8033, %ax    // 38400 @ 16MHz
    mov $0x80cf, %ax    // 9600 @ 16MHz
    out %ax, %dx

    mov $S0CON, %dx     // S0CON
    mov $0x0001, %ax    // mode 1 asynchronous 10-bit
    out %ax, %dx

    // Clear any pending RI or TI, just for safety
    mov $S0STS, %dx    // S0STS
    in %dx, %ax

    mov $S0CON, %dx    // S0CON
    in %dx, %ax
    or $0x0020, %ax    // REN = 1
    out %ax, %dx

    // print startup message
    mov $message, %si
    call pstr

#ifdef USING_PCBDUMP
    // print PCB registers on startup (after setting up the serial port)
    call print_peripheral
#endif

    // print startup message
    mov $message_loading, %si
    call pstr

    // Call to ELKS init code that sets up INT19 handler
    lcall $0xe000, $0x0003
    // Now call that INT19
    int $0x19
    // should never reach this point
    hlt

message:
    .ascii "\r\n8018x ELKS loader built at " BUILD_TIMESTAMP
    .asciz "\r\n"

message_loading:
    .asciz "Now jumping into ELKS...\r\n"
