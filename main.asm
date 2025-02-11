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
            bic.w   #LOCKLPM5,  &PM5CTL0    ; turn on I/O                

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

main:
            call    #i2c_init
loop        mov.w   #69h,           R14
            mov.w   #00h,           R9 
            call    #i2c_start        
            call    #i2c_tx_slave_address
            call    #i2c_rx_ack
            call    #i2c_stop
            jmp     loop

;-------------------------------------------------------------------------------------------------------------------------------------

;Expected behavior verified
i2c_init:
            bic.b   #BIT0 + BIT1,   &P2DIR    ;Set P2.0 and P2.1 as inputs to enable resistors
            bis.b   #BIT0 + BIT1,   &P2REN    ;Enable P2.0 resistor
            mov.b   #1,             &P2OUT    ;Set resistor as pull-up
            bis.b   #BIT0 + BIT1,   &P2DIR    ;Set P2.0 and P2.1 as outputs (SDA = P2.0, SCL = P2.1)
            bis.b   #BIT0 + BIT1,   &P2OUT    ;Start SDA and SCL in idle state (high)
                        
            ret

;-------------------------------------------------------------------------------------------------------------------------------------

;All timing requirements met
i2c_start:
            bic.b   #BIT0,          &P2OUT      ;Drive SDA low
            
            NOP                                 ;Delay ~5.712us (>4.7us) (start setup)

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            NOP                                 ;Delay ~5.712us (>4.0us) (start hold)

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

;All timing requirements met
i2c_stop:
            bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            NOP                                 ;Delay ~5.712us (>4.0us) (stop setup)

            bis.b   #BIT0,          &P2OUT      ;Drive SDA high

            NOP                                 ;Delay ~5.712us (>4.7us) (stop hold)

            ret

;-------------------------------------------------------------------------------------------------------------------------------------
