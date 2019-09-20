; *************************************************************************
; * Lame attempt at a copy-cat game like Frogger
; * Work under progress!
; *************************************************************************
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

game_array  ; the array treats each sprite in order
            ;     speed  X       Y        sprite
            .word $FFFC, 640-96, 480-128, 0 ; sprite  0 - car front
            .word $FFFC, 640-64, 480-128, 1 ; sprite  1 - car back
            .word     2, 32    , 480-160, 2 ; sprite  2 - bus back
            .word     2, 64    , 480-160, 3 ; sprite  3 - bus middle
            .word     2, 96    , 480-160, 4 ; sprite  4 - bus front
            .word $FFFA, 96    , 480-192, 0 ; sprite  5 - car front
            .word $FFFA, 128   , 480-192, 1 ; sprite  6 - car back
            .word     1, 192   , 256    , 8 ; sprite  7 - oldie front
            .word     1, 224   , 256    , 9 ; sprite  8 - oldie back
            .word $FFFB, 320   , 128    , 5 ; sprite  9 - log 1
            .word $FFFB, 352   , 128    , 6 ; sprite 10 - log 2
            .word $FFFB, 384   , 128    , 7 ; sprite 11 - log 3
            .word     2, 416   , 160    , 5 ; sprite 12 - log 1
            .word     2, 448   , 160    , 7 ; sprite 13 - log 3
            .word $FFFE, 512   , 192    ,10 ; sprite 15 - lilypad
            .word     0, 0     , 0      ,15 ; - not used


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
