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
                ;check_irq_bit INT_PENDING_REG0, FNX0_INT02_TMR0, TIMER0_INTERRUPT
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
                STA KEYBOARD_SC_TMP     ; Save Code Immediately
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
                LDA #$1F
                BRA KBD_DONE
                
        SKIP_KEY
                LDA #$9F
        KBD_DONE
                JSR UPDATE_DISPLAY
                RTS
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Start of Frame Interrupt
; /// 60Hz, 16ms Cyclical Interrupt
; ///
; ///////////////////////////////////////////////////////////////////
SOF_INTERRUPT

                .as
                LDA JOYSTICK0
                JSR UPDATE_DISPLAY
                
                RTS

;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Mouse Interrupt
; /// Desc: Basically Assigning the 3Bytes Packet to Vicky's Registers
; ///       Vicky does the rest
; ///////////////////////////////////////////////////////////////////
MOUSE_INTERRUPT
                .as
                LDA KBD_INPT_BUF
                PHA
                LDX #$0000
                setxs
                LDX MOUSE_PTR
                BNE MOUSE_BYTE_GT1
                
                ; copy the buttons to another address
                AND #%0111
                STA MOUSE_BUTTONS_REG
                
    MOUSE_BYTE_GT1
                PLA
                STA @lMOUSE_PTR_BYTE0, X
                INX
                CPX #$03
                BNE EXIT_FOR_NEXT_VALUE
                
                ; Create Absolute Count from Relative Input
                LDA @lMOUSE_PTR_X_POS_L
                STA MOUSE_POS_X_LO
                LDA @lMOUSE_PTR_X_POS_H
                STA MOUSE_POS_X_HI

                LDA @lMOUSE_PTR_Y_POS_L
                STA MOUSE_POS_Y_LO
                LDA @lMOUSE_PTR_Y_POS_H
                STA MOUSE_POS_Y_HI
                
                
                ; print the character on the upper-right of the screen
                ; this is temporary
                CLC
                LDA MOUSE_BUTTONS_REG
                
                JSR MOUSE_BUTTON_HANDLER
                
                LDX #$00
EXIT_FOR_NEXT_VALUE
                STX MOUSE_PTR

                setxl
                RTS
                
MOUSE_BUTTON_HANDLER
                setas
                
                LDA @lMOUSE_BUTTONS_REG
                BEQ MOUSE_CLICK_DONE
                
                ; set the cursor position ( X/8 and Y/8 ) and enable blinking
                setal
                CLC
                LDA @lMOUSE_PTR_X_POS_L
                LSR
                LSR
                LSR
                STA CURSORX
                STA @lVKY_TXT_CURSOR_X_REG_L
                
                CLC
                LDA @lMOUSE_PTR_Y_POS_L
                LSR
                LSR
                LSR
                STA CURSORY
                STA @lVKY_TXT_CURSOR_Y_REG_L
                
                setas
                LDA #$03      ;Set Cursor Enabled And Flash Rate @1Hz
                STA @lVKY_TXT_CURSOR_CTRL_REG
                
MOUSE_CLICK_DONE
                RTS
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Floppy Controller
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
FDC_INTERRUPT   .as

;; PUT YOUR CODE HERE
                RTS
;
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Serial Port COM2
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
COM2_INTERRUPT  .as

;; PUT YOUR CODE HERE
                RTS
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Serial Port COM1
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
COM1_INTERRUPT  .as

;; PUT YOUR CODE HERE
                RTS
;
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Parallel Port LPT1
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
LPT1_INTERRUPT  .as

;; PUT YOUR CODE HERE
                RTS

NMI_HANDLER
                RTL
                
