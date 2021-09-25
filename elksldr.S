.code16

#define VECT_TIMER0 0x08
#define VECT_TIMER1 18

.equ EOI, 0xff02
.equ IMASK, 0xff08
.equ TCUCON, 0xff12

.equ B0CMP, 0xff60
.equ B0CNT, 0xff62
.equ S0CON, 0xff64
.equ S0STS, 0xff66
.equ R0BUF, 0xff68
.equ T0BUF, 0xff6A

.equ LCSST, 0xffA0
.equ LCSSP, 0xffA2
.equ UCSST, 0xffA4
.equ UCSSP, 0xffA6

.equ T0CNT, 0xff30
.equ T0CMPA, 0xff32
.equ T0CMPB, 0xff34
.equ T0CON, 0xff36
.equ T1CNT, 0xff38
.equ T1CMPA, 0xff3A
.equ T1CMPB, 0xff3C
.equ T1CON, 0xff3E
.equ T2CNT, 0xff40
.equ T2CMPA, 0xff42
.equ T2CON, 0xff46


// This should land on 0xF000:0xFFF0
.section .reset.text, "ax"
.globl _cpu_reset_entrypoint
_cpu_reset_entrypoint:
    // Setup UCS and LCS
    mov $UCSST, %dx
    mov $0x8000, %ax
    out %ax, %dx

    ljmp $0xf000, $_init8018x_and_start

// This should land on 0xF000:0xF000
.section .text, "ax"
.globl _init8018x_and_start
_init8018x_and_start:
    cli

    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss        // DS = ES = SS = 0x0000
    
    mov $0x600, %ax
    mov %ax, %sp        // Set a stack pointer starting at 0x0000:0x0600

    mov $UCSSP, %dx    // FINISH SETTING UP UCS#
    mov $0x000e, %ax    // set ISTOP for 0FFFFF ending loaction
    out %al, %dx        // REMEMBER, BYTE WRITE WORK OK

    mov $LCSST, %dx    // SET UP LCS START REGISTER
    mov $0x0000, %ax    // LCS STARTS AT 0H, ZERO WAIT STATES!
    out %al, %dx        // REMEMBER, BYTE WRITES WORK OK

    mov $LCSSP, %dx    // SET UP LCS STOP REGISTER
    mov $0x200A, %ax    // 128kB Installed
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
    mov $0x00aa, %ax
    out %ax, %dx


    // Setup internal serial port

    mov $B0CMP, %dx    // B0CMP
    mov $0x8033, %ax    // 38400 @ 16MHz
    out %ax, %dx

    mov $S0CON, %dx    // S0CON
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

    // print PCB registers on startup (after setting up the serial port)
    call print_peripheral

    // Timer vector
    mov $4*VECT_TIMER0, %bx
    movw $int_timer0, %es:(%bx)
    mov %cs, %es:2(%bx)

    // Timer1 vector
    mov $4*VECT_TIMER1, %bx
    movw $int_timer0, %es:(%bx)
    mov %cs, %es:2(%bx)


    // Reset Timer2
    mov $T2CON, %dx
    mov $0x4000, %ax
    out %ax, %dx

    // Reset Timer1
    mov $T1CON, %dx
    mov $0x4000, %ax
    out %ax, %dx

    // Reset Timer0
    mov $T0CON, %dx
    mov $0x4000, %ax
    out %ax, %dx

    // Clear the Timer0 count register before programming it
    //outw(0x0000, 0xff00 + 0x30)// // T0CNT
    mov $T0CNT, %dx
    mov $0x0000, %ax
    out %ax, %dx

    // Clear the Timer1 count register before programming it
    mov $T1CNT, %dx
    mov $0x0000, %ax
    out %ax, %dx

    // Clear the Timer2 count register before programming it
    //outw(0x0000, 0xff00 + 0x40)// // T2CNT
    mov $T2CNT, %dx
    mov $0x0000, %ax
    out %ax, %dx

    // Set Timer0 Maxcount register
    //outw(TIMER0_INTERVAL, 0xff00 + 0x32)// // T0CMPA
    mov $T0CMPA, %dx
    mov $0x100a, %ax
    out %ax, %dx

    // Set Timer1 Maxcount register
    mov $T1CMPA, %dx
    mov $0x100a, %ax
    out %ax, %dx

    // Set Timer2 Maxcount register
    //outw(TIMER2_INTERVAL, 0xff00 + 0x42)// // T2CMPA
    mov $T2CMPA, %dx
    mov $0x0fa0, %ax
    out %ax, %dx

    // Enable Timer0, release inhibit to change EN bit, INT enabled, use Timer2 as source, continuous mode
    //outw(0xe009, 0xff00 + 0x36)// // T0CON
    mov $T0CON, %dx
    mov $0xc009, %ax
    out %ax, %dx

    // Enable Timer1, release inhibit to change EN bit, INT disabled, use Timer2 as source, continuous mode
    mov $T1CON, %dx
    mov $0xe009, %ax
    out %ax, %dx

    // When using Timer 2 to prescale another timer, enable Timer 2 last. If Timer 2 is enabled first, it will be at an unknown point in its timing cycle when the timer to be prescaled is enabled. This results in an unpredictable duration of the first timing cycle for the prescaled timer.
    // Enable Timer2, release inhibit to change EN bit, continuous mode
    //outw(0xc001, 0xff00 + 0x46)// // T2CON
    mov $T2CON, %dx
    mov $0xc001, %ax
    out %ax, %dx

    // Enable ints for timer0
    mov $0x00fc, %ax // unmask tmr int
    mov $IMASK, %dx // IMASK
    out %ax, %dx

    mov $TCUCON, %dx // TCUCON
    xor %ax, %ax
    out %ax, %dx

    sti

sss:
    call cins
    call print_peripheral
    jmp sss
    // Should never happen
    hlt

print_peripheral:
    call newline
    push %bx
    push %cx
    push %ax
    push %dx
    mov $0x0ff00, %bx
    mov $16, %cx

print1:
    call newline
    mov %bx, %ax

    push %cx
    call out4x
    call space  // one more space

    mov $8, %cx

print2:
    push %cx
    call space

    mov %bx, %dx
    in %dx, %ax
    call out4x

    inc %bx
    inc %bx
    pop %cx
    loop print2


    pop %cx

    loop print1
    pop %dx
    pop %ax
    pop %cx
    pop %bx
    ret


// send string to terminal
// entry: si

pstr:
    lodsb %cs:(%si)     // AL = CS:[SI]// SI++
    test %al, %al       // last element on the string is a null byte
    jnz pstr1
    ret

pstr1:
    call cout
    jmp pstr

// receive character from terminal
// exit: al = data received
//       al = -1 no data received

cin:
    mov $S0STS,%dx
    in %dx,%al
    test $0x40, %al
    jnz cin1
    mov $-1,%al
    ret
cin1:
    mov $R0BUF,%dx
    in %dx,%al
    ret

// cins wait until get character

cins:
    call cin
    cmp $-1,%al
    je  cins
    ret

// send 8-bit character in al to terminal
// entry: al

cout:
    push %ax
    mov $S0STS, %dx
cout1:
    in  %dx, %al
    test $8, %al    // test TXE
    jz cout1    // wait until TXE = 1
    
    pop %ax
    mov $T0BUF, %dx
    out %al, %dx
    ret

// print hex
// entry: al

out1x:
    push %ax
    and $0x0f, %al
    add $'0', %al
    cmp $'9', %al
    jle out1x1     // if al less than or equal 39h then print it
    add $7, %al       // else add with 7

out1x1:
    call cout
    pop %ax
    ret
         
out2x:
    push %cx
    mov $4, %cl
    ror %cl,%al     // rotate right four bits
    call out1x
    rol %cl,%al     // rotate left four bits
    call out1x
    pop %cx
    ret

out4x:
    push %ax
    xchg %al,%ah
    call out2x
    pop %ax
    call out2x
    ret
           
space:
    mov $' ',%al
    call cout
    ret

newline:
    mov $'\r',%al
    call cout
    mov $'\n',%al
    call cout
    ret

int_timer0:
    push %ax
    push %dx

    mov $'t', %al
    call cout

    mov $0x8000, %ax // set the NSPEC bit on the
    mov $EOI, %dx // EOI register so the ICU
    out %ax, %dx // acks the highest priority interrupt

    pop %dx
    pop %ax
    iret

message:
    .ascii "Welcome! Built at " BUILD_TIMESTAMP
    .asciz "\r\n"