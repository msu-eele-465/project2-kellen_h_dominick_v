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

Setup_P1    bic.b   #BIT0,&P1OUT            
            bis.b   #BIT0,&P1DIR            
            bic.w   #LOCKLPM5,&PM5CTL0      

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

Mainloop    xor.b   #BIT0,&P1OUT            
            jmp     FlashRed

FlashRed:

WaitOuter   mov.w   #4,R14                  
WaitInner   mov.w   #43750,R15              
L1          dec.w   R15                     
            jnz     L1                      
            dec.w   R14                     
            jnz     WaitInner               
            jmp     Mainloop                
            NOP

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