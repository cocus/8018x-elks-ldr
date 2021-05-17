.code16

// This should land on 0xF000:0xFFF0
.section .reset.text, "ax"
.globl _cpu_reset_entrypoint
_cpu_reset_entrypoint:
    ljmp $0xf000, $_init8018x_and_start

// This should land on 0xF000:0xFF00
.section .text, "ax"
.globl _init8018x_and_start
_init8018x_and_start:
    xor %ax, %ax
    mov %ax, %cs
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss        // DS = ES = SS = CS = 0x0000

    // Setup UCS and LCS

    mov $0xffa4, %dx
    mov $0x8000, %ax
    out %ax, %dx

    mov $0xffa6, %dx    // FINISH SETTING UP UCS#
    mov $0x000e, %ax    // set ISTOP for 0FFFFF ending loaction
    out %al, %dx        // REMEMBER, BYTE WRITE WORK OK

    mov $0xffa0, %dx    // SET UP LCS START REGISTER
    mov $0x0000, %ax    // LCS STARTS AT 0H, ZERO WAIT STATES!
    out %al, %dx        // REMEMBER, BYTE WRITES WORK OK

    mov $0xffa2, %dx    // SET UP LCS STOP REGISTER
    mov $0x200A, %ax    // 128kB Installed
    out %al, %dx        // REMEMBER, BYTE WRITES WORK OK

    // Setup internal serial port

    mov $0xff60, %dx    // B0CMP
    mov $0x8033, %ax    // 38400 @ 16MHz
    out %ax, %dx

    mov $0xff64, %dx    // S0CON
    mov $0x0021, %ax    // mode 1 asynchronous 10-bit
    out %ax, %dx

    // Now full FLASH and RAM should be properly mapped

    mov $0x100, %ax
    mov %ax, %sp        // Set a stack pointer starting at 0x0000:0x0100

    // Call to ELKS init code that sets up INT19 handler
    lcall $0xe000, $0x0003
    // Now call that INT19
    int $0x19
    // Should never happen
    hlt