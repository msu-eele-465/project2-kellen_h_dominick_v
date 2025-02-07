;******************************************************************************
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT  

Setup_P6    
            bis.b   #BIT6,&P6DIR            
            bic.b   #BIT6,&P6OUT            
            bic.w   #LOCKLPM5,&PM5CTL0      

Setup_Timer_B0
            bis.w   #TBCLR, &TB0CTL         
            bis.w   #TBSSEL__ACLK, &TB0CTL  
            bis.w   #MC__UP, &TB0CTL        

Setup_Compare
            mov.w   #16384, &TB0CCR0
            bis.w   #CCIE,  &TB0CCTL0
            NOP
            eint                            
            NOP
            bic.w   #CCIFG, &TB0CCTL0

;-------------------------------------------------------------------------------------------------------------------------------------

; bis.w     UCASTP_2    UCB0CTLW0 ; auto STOP mode

i2c_init:
            bis.w   UCSWRST     UCB0CTLW0   ; put in SW RST

            bic.w   BIT3        P1SEL1      ; P1.3 = SCL
            bis.w   BIT3        P1SEL0
            bic.w   BIT2        P1SEL1      ; P1.2 = SDA
            bis.w   BIT2        P1SEL0

            bic.w   LOCKLPM5    PM5CTL0     ; turn on I/O
            
            bis.w   UCSSEL_3    UCB0CTLW0   ; choose SMCLK
            mov.w   #10         UCB0BRW     ; set prescalar to 10

            bis.w   UCMODE_3    UCB0CTLW0   ; put into I2C mode
            bis.w   UCMST       UCB0CTLW0   ; set as master

            mov.w   #68h        UCB0I2CSA   ; set slave address

            bic.w   UCSWRST     UCB0CTLW0   ; take B0 out of SW RST

            bis.w   UCTXIE0     UCB0IE      ; local enable for TX0

i2c_start:

i2c_stop:

i2c_tx_ack:
            bis.w   UCTR        UCB0CTLW0   ; put into TX mode (write)

i2c_rx_ack:

i2c_tx_byte:
            bis.w   UCTR        UCB0CTLW0   ; put into TX mode (write)

i2c_rx_byte:

i2c_sda_delay:

i2c_scl_delay:

i2c_send_address:

i2c_write:

i2c_read:

;------------------------------------------------------------------------------
;  ISRs
;------------------------------------------------------------------------------
ISR_TB0_CCR0:
            xor.b   #BIT6,  &P6OUT          ; Toggle LED 2
            bic.w   #CCIFG, &TB0CCTL0       ; Clear interrupt flag
            reti

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;

            .sect   TIMER0_B0_VECTOR        ; Timer B0 CCR0 Vector
            .short  ISR_TB0_CCR0
            .end