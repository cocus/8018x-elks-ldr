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
