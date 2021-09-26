.code16

.include "8018x.S"

// This should land on 0xF000:0xF000
.section .text, "ax"

// Note: Most of this code comes directly from
// Wichit Sirichote's C188SBC https://www.kswichit.com/C188/c188sbc.htm 

// send string to terminal
// entry: si (uses cs)
.globl pstr
pstr:
    push %ax
    lodsb %cs:(%si)     // AL = CS:[SI]// SI++
    test %al, %al       // last element on the string is a null byte
    jnz pstr1
    pop %ax
    ret

pstr1:
    call cout
    jmp pstr

// send 8-bit character in al to terminal
// entry: al
.globl cout
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
