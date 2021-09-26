.code16

.include "8018x.S"

// This should land on 0xF000:0xF000
.section .text, "ax"

// Note: Most of this code comes directly from
// Wichit Sirichote's C188SBC https://www.kswichit.com/C188/c188sbc.htm

// prints the PCB block register values
.globl print_peripheral
print_peripheral:
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
