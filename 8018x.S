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

.equ GCS0ST, 0xff80
.equ GSC0SP, 0xff82
.equ GCS1ST, 0xff84
.equ GSC1SP, 0xff86
.equ GCS2ST, 0xff88
.equ GSC2SP, 0xff8a
.equ GCS3ST, 0xff8c
.equ GSC3SP, 0xff8e
.equ GCS4ST, 0xff90
.equ GSC4SP, 0xff92
.equ GCS5ST, 0xff84
.equ GSC5SP, 0xff96
.equ GCS6ST, 0xff98
.equ GSC6SP, 0xff9a
.equ GCS7ST, 0xff9c
.equ GSC7SP, 0xff9e

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
