;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
; Interrupt Handler
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////

check_irq_bit  .macro
                LDA \1
                AND #\2
                CMP #\2
                BNE END_CHECK
                STA \1
                JSR \3
                
END_CHECK
                .endm
                
IRQ_HANDLER
; First Block of 8 Interrupts
                .as
                setdp 0
                
                .as
                LDA #0  ; set the data bank register to 0
                PHA
                PLB
                
                LDA INT_PENDING_REG0
                BEQ CHECK_PENDING_REG1
; Start of Frame
                check_irq_bit INT_PENDING_REG0, FNX0_INT00_SOF, SOF_INTERRUPT
; Timer 0
                check_irq_bit INT_PENDING_REG0, FNX0_INT02_TMR0, TIMER0_INTERRUPT
; FDC Interrupt
                ;check_irq_bit INT_PENDING_REG0, FNX0_INT06_FDC, FDC_INTERRUPT
; Mouse IRQ
                ;check_irq_bit INT_PENDING_REG0, FNX0_INT07_MOUSE, MOUSE_INTERRUPT

; Second Block of 8 Interrupts
CHECK_PENDING_REG1
                setas
                LDA INT_PENDING_REG1
                BEQ CHECK_PENDING_REG2   ; BEQ EXIT_IRQ_HANDLE
; Keyboard Interrupt
                check_irq_bit INT_PENDING_REG1, FNX1_INT00_KBD, KEYBOARD_INTERRUPT
; COM2 Interrupt
                ;check_irq_bit INT_PENDING_REG1, FNX1_INT03_COM2, COM2_INTERRUPT
; COM1 Interrupt
                ;check_irq_bit INT_PENDING_REG1, FNX1_INT04_COM1, COM1_INTERRUPT
; MPU401 - MIDI Interrupt
                ;check_irq_bit INT_PENDING_REG1, FNX1_INT05_MPU401, MPU401_INTERRUPT
; LPT Interrupt
                ;check_irq_bit INT_PENDING_REG1, FNX1_INT06_LPT, LPT1_INTERRUPT

; Third Block of 8 Interrupts
CHECK_PENDING_REG2
                setas
                LDA INT_PENDING_REG2
                BEQ EXIT_IRQ_HANDLE
                
; OPL2 Right Interrupt
                ;check_irq_bit INT_PENDING_REG2, FNX2_INT00_OPL2R, OPL2R_INTERRUPT
; OPL2 Left Interrupt
                ;check_irq_bit INT_PENDING_REG2, FNX2_INT01_OPL2L, OPL2L_INTERRUPT
                
EXIT_IRQ_HANDLE
                ; Exit Interrupt Handler

                RTL

; ****************************************************************
; ****************************************************************
;
;  KEYBOARD_INTERRUPT
;
; ****************************************************************
; ****************************************************************
; * Todo: rewrite this to use indirect or indexed jumps
KEYBOARD_INTERRUPT
                .as
                LDA KBD_INPT_BUF        ; Get Scan Code from KeyBoard
                EOR KEYBOARD_SC_TMP     ; if the scan code hasn't changed, skip
                BEQ KBD_SKIP
                
                LDA KBD_INPT_BUF
                STA KEYBOARD_SC_TMP
                CMP #$11 ; W key
                BNE CHECK_A
                LDA #$9E
                BRA KBD_DONE
                
        CHECK_A CMP #$1E
                BNE CHECK_S
                LDA #$9B
                BRA KBD_DONE
                
        CHECK_S CMP #$1F
                BNE CHECK_D
                LDA #$9D
                BRA KBD_DONE
                
        CHECK_D CMP #$20
                BNE CHECK_SPACE
                LDA #$97
                BRA KBD_DONE
                
        CHECK_SPACE
                CMP #$39
                BNE SKIP_KEY
                LDA #$8F
                BRA KBD_DONE
                
        SKIP_KEY
                LDA #$9F
                JMP KBD_SKIP
                
        KBD_DONE
                JSR UPDATE_DISPLAY
        KBD_SKIP        
                RTS


; ///////////////////////////////////////////////////////////////////
; ///
; /// Start of Frame Interrupt
; /// 60Hz, 16ms Cyclical Interrupt
; ///
; ///////////////////////////////////////////////////////////////////
SOF_INTERRUPT

                .as
                LDA JOYSTICK0
                AND #$DF
                EOR JOYSTICK_SC_TMP
                BEQ SOF_CONTINUE
                
                LDA JOYSTICK0
                STA JOYSTICK_SC_TMP
                BRA SOF_DISPLAY
                
        SOF_CONTINUE
                LDA #$DF
        SOF_DISPLAY
                JSR UPDATE_DISPLAY
                
                RTS


; ///////////////////////////////////////////////////////////////////
; ///
; /// Timer0 interrupt
; /// Desc: Interrupt for playing VGM data
; ///
; ///////////////////////////////////////////////////////////////////
TIMER0_INTERRUPT  .as
                JSL VGM_WRITE_REGISTER
                RTS

NMI_HANDLER
                RTL
                
