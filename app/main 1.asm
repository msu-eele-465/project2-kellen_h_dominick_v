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

            mov.w   #69h,           R4
            mov.w   #01h,           R5
            mov.w   #05h,           R6 
            mov.w   #07h,           R7
            mov.w   #25h,           R8
            mov.w   #23h,           R9

            call    #i2c_start

            call    #i2c_tx_slave_address
            call    #i2c_rx_ack

loop        call    #i2c_start

            call    #seconds
            call    #i2c_rx_ack
            call    #store_seconds
            call    #minutes
            call    #i2c_rx_ack
            call    #store_minutes
            call    #hours
            call    #i2c_rx_ack
            call    #store_hours
            call    #temp1
            call    #i2c_rx_ack
            call    #store_temp
            call    #temp2
            call    #i2c_rx_ack
            call    #store_temp2

            call    #i2c_stop
            jmp loop

;-------------------------------------------------------------------------------------------------------------------------------------

;Expected behavior verified
i2c_init:
            bic.b   #BIT0 + BIT1,   &P2DIR    ;Set P2.0 and P2.1 as inputs to enable resistors
            bis.b   #BIT0 + BIT1,   &P2REN    ;Enable P2.0 resistor
            bis.b   #BIT0,          &P2OUT    ;Set resistor as pull-up
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

;Working
i2c_tx_slave_address:
            mov.w   #8,             R10         ;Repeat shift_byte 8 times...
                  
shift_byte  bit.b   #10000000b,     R4         ;Test MSB of tx_byte
            jz      ifzero                      ;If MSB of tx_byte is 0, leave SDA low

            bis.b   #BIT0,          &P2OUT      ;If MSB of tx_byte is 1, drive SDA high
            jmp     clock

ifzero      bic.b   #BIT0,          &P2OUT
            NOP
            NOP
            NOP

clock       bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            rla.b   R4                         ;Shift bits to the left arithmetically    
            dec.w   R10
            jnz     shift_byte                  ;If there are more bits to transmit, continue 

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

seconds:
            mov.w   #8,             R10         ;Repeat shift_byte 8 times...   

shift_byte2 bit.b   #10000000b,     R5          ;Test MSB of tx_byte
            jz      ifzero2                     ;If MSB of tx_byte is 0, leave SDA low

            bis.b   #BIT0,          &P2OUT      ;If MSB of tx_byte is 1, drive SDA high
            jmp     clock2

ifzero2     bic.b   #BIT0,          &P2OUT

clock2      bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            rla.b   R5                          ;Shift bits to the left arithmetically    
            dec.w   R10
            jnz     shift_byte2                  ;If there are more bits to transmit, continue 

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

minutes:
            mov.w   #8,             R10         ;Repeat shift_byte 8 times...   

shift_byte3 bit.b   #10000000b,     R6          ;Test MSB of tx_byte
            jz      ifzero3                     ;If MSB of tx_byte is 0, leave SDA low

            bis.b   #BIT0,          &P2OUT      ;If MSB of tx_byte is 1, drive SDA high
            jmp     clock3

ifzero3     bic.b   #BIT0,          &P2OUT

clock3      bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            rla.b   R6                          ;Shift bits to the left arithmetically    
            dec.w   R10
            jnz     shift_byte3                 ;If there are more bits to transmit, continue 

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

hours:
            mov.w   #8,             R10         ;Repeat shift_byte 8 times...   

shift_byte4 bit.b   #10000000b,     R7          ;Test MSB of tx_byte
            jz      ifzero4                     ;If MSB of tx_byte is 0, leave SDA low

            bis.b   #BIT0,          &P2OUT      ;If MSB of tx_byte is 1, drive SDA high
            jmp     clock3

ifzero4     bic.b   #BIT0,          &P2OUT

clock4      bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            rla.b   R7                           ;Shift bits to the left arithmetically    
            dec.w   R10
            jnz     shift_byte4                  ;If there are more bits to transmit, continue 

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

temp1:
            mov.w   #8,             R10         ;Repeat shift_byte 8 times...   

shift_byte5 bit.b   #10000000b,     R8          ;Test MSB of tx_byte
            jz      ifzero5                     ;If MSB of tx_byte is 0, leave SDA low

            bis.b   #BIT0,          &P2OUT      ;If MSB of tx_byte is 1, drive SDA high
            jmp     clock5

ifzero5     bic.b   #BIT0,          &P2OUT

clock5      bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            rla.b   R8                           ;Shift bits to the left arithmetically    
            dec.w   R10
            jnz     shift_byte5                  ;If there are more bits to transmit, continue 

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

temp2:
            mov.w   #8,             R10         ;Repeat shift_byte 8 times...   

shift_byte6 bit.b   #10000000b,     R9          ;Test MSB of tx_byte
            jz      ifzero6                     ;If MSB of tx_byte is 0, leave SDA low

            bis.b   #BIT0,          &P2OUT      ;If MSB of tx_byte is 1, drive SDA high
            jmp     clock6

ifzero6     bic.b   #BIT0,          &P2OUT

clock6      bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            rla.b   R9                           ;Shift bits to the left arithmetically    
            dec.w   R10
            jnz     shift_byte6                  ;If there are more bits to transmit, continue 

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

i2c_tx_ack:
            bic.b   #BIT0,          &P2OUT      ;Drive SDA low
            bis.b   #BIT1,          &P2OUT      ;Drive SCL high   

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            ret

;-------------------------------------------------------------------------------------------------------------------------------------



i2c_rx_ack:
            bic.b   #BIT0,          &P2OUT
            bic.b   #BIT0,          &P2DIR      ;Set SDA as input

            NOP
            NOP
            NOP
            NOP

            bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            bit.b   #10000000b,     &P2IN
            jz      ACK

            call    #i2c_stop
ACK     
            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low

            bis.b   #BIT0,          &P2DIR      ;Set SDA as output

            ret

;-------------------------------------------------------------------------------------------------------------------------------------

store_seconds:
            bic.b   #BIT0,          &P2DIR      ;Set SDA as input

            mov.w   #8,             R10
            mov.w   #0,             R15

shift_loop2 bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            rrc.b   R15                         ;Logical shift right
            bit.b   #10000000b,     &P2IN       ;Check if received bit is 1
            jz      P2_02                       ;If not, don't set new MSB to 1
            bis.b   #10000000b,     R15         ;If so, set new MSB to 1

P2_02        

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low
            dec.w   R10
            jnz     shift_loop2

            ret

;-------------------------------------------------------------------------------------------------------------------------------------
store_minutes:
            bic.b   #BIT0,          &P2DIR      ;Set SDA as input

            mov.w   #8,             R10
            mov.w   #0,             R14

shift_loop  bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            rrc.b   R14                         ;Logical shift right
            bit.b   #10000000b,     &P2IN       ;Check if received bit is 1
            jz      P2_0                        ;If not, don't set new MSB to 1
            bis.b   #10000000b,     R14         ;If so, set new MSB to 1

P2_0        

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low
            dec.w   R10
            jnz     shift_loop

            ret

;-------------------------------------------------------------------------------------------------------------------------------------
store_hours:
            bic.b   #BIT0,          &P2DIR      ;Set SDA as input

            mov.w   #8,             R10
            mov.w   #0,             R13

shift_loop3 bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            rrc.b   R13                         ;Logical shift right
            bit.b   #10000000b,     &P2IN       ;Check if received bit is 1
            jz      P2_03                       ;If not, don't set new MSB to 1
            bis.b   #10000000b,     R13         ;If so, set new MSB to 1

P2_03        

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low
            dec.w   R10
            jnz     shift_loop3

            ret

;-------------------------------------------------------------------------------------------------------------------------------------
store_temp:
            bic.b   #BIT0,          &P2DIR      ;Set SDA as input

            mov.w   #8,             R10
            mov.w   #0,             R12

shift_loop4 bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            rrc.b   R12                         ;Logical shift right
            bit.b   #10000000b,     &P2IN       ;Check if received bit is 1
            jz      P2_04                       ;If not, don't set new MSB to 1
            bis.b   #10000000b,     R12         ;If so, set new MSB to 1

P2_04        

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low
            dec.w   R10
            jnz     shift_loop4

            ret

;-------------------------------------------------------------------------------------------------------------------------------------
store_temp2:
            bic.b   #BIT0,          &P2DIR      ;Set SDA as input

            mov.w   #8,             R10
            mov.w   #0,             R12

shift_loop9 bis.b   #BIT1,          &P2OUT      ;Drive SCL high

            rrc.b   R12                         ;Logical shift right
            bit.b   #10000000b,     &P2IN       ;Check if received bit is 1
            jz      P2_09                       ;If not, don't set new MSB to 1
            bis.b   #10000000b,     R12         ;If so, set new MSB to 1

P2_09        

            NOP                                 ;Delay for SCL high time
            NOP
            NOP
            NOP

            bic.b   #BIT1,          &P2OUT      ;Drive SCL low
            dec.w   R10
            jnz     shift_loop9

            ret

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

start2: