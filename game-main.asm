.cpu "65816"
.include "macros_inc.asm"
.include "bank_00_inc.asm"
.include "vicky_def.asm"
.include "interrupt_def.asm"
.include "keyboard_def.asm"
.include "io_def.asm"

* = HRESET
                CLC
                XCE   ; go into native mode
                SEI   ; ignore interrupts
                JML GAME_START
                
* = HIRQ       ; IRQ handler.
RHIRQ
                .as
                .xl
                PHB
                PHD
                PHA
                PHX
                PHY
                ;
                ; todo: look up IRQ triggered and do stuff
                ;
                JSL IRQ_HANDLER

                PLY
                PLX
                PLA
                PLD
                PLB
                RTI
                
; Interrupt Vectors
* = VECTORS_BEGIN
JUMP_READY      JML GAME_START ; Kernel READY routine. Rewrite this address to jump to a custom kernel.
RVECTOR_COP     .addr HCOP     ; FFE4
RVECTOR_BRK     .addr HBRK     ; FFE6
RVECTOR_ABORT   .addr HABORT   ; FFE8
RVECTOR_NMI     .addr HNMI     ; FFEA
                .word $0000    ; FFEC
RVECTOR_IRQ     .addr HIRQ     ; FFEE

RRETURN         JML GAME_START

RVECTOR_ECOP    .addr HCOP     ; FFF4
RVECTOR_EBRK    .addr HBRK     ; FFF6
RVECTOR_EABORT  .addr HABORT   ; FFF8
RVECTOR_ENMI    .addr HNMI     ; FFFA
RVECTOR_ERESET  .addr HRESET   ; FFFC
RVECTOR_EIRQ    .addr HIRQ     ; FFFE

* = $160000

PLAYER_X    .word 100
PLAYER_Y    .word 100

GAME_START
            setas
            setxl
            
            ; Setup the Interrupt Controller
            ; For Now all Interrupt are Falling Edge Detection (IRQ)
            LDA #$FF
            STA @lINT_EDGE_REG0
            STA @lINT_EDGE_REG1
            STA @lINT_EDGE_REG2
            
            ; Mask all Interrupt @ This Point
            LDA #$FF
            STA @lINT_MASK_REG0
            STA @lINT_MASK_REG1
            STA @lINT_MASK_REG2
                
            JSR INIT_DISPLAY
            
            ; Enable SOF
            LDA #~( FNX0_INT00_SOF )
            STA @lINT_MASK_REG0
            LDA #~( FNX1_INT00_KBD )
            STA @lINT_MASK_REG1
            CLI
            
    GAME_LOOP
            BRA GAME_LOOP

.include "interrupt_handler.asm"
.include "display.asm"
