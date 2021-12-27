; *************************************************************************
; * Lame attempt at a copy-cat game like Frogger
; * Work under progress!
; *************************************************************************
.cpu "65816"
.include "macros_inc.asm"
.include "bank_00_inc.asm"
.include "vicky_ii_def.asm"
.include "interrupt_def.asm"
.include "keyboard_def.asm"
.include "io_def.asm"
.include "math_def.asm"
.include "timer_def.asm"
.include "base.asm"

TOTAL_SPRITES   = 26
TILE_MAP0       = $B02000

; sprite names
PLAYER_UP       = 10
PLAYER_LEFT     = 11
PLAYER_RIGHT    = 13
PLAYER_DOWN     = 12
SPLASH_SPRITE   = 14
SPLATT_SPRITE   = 15
THREE_SECS      = 180

* = $160000

PLAYER_X    .word 100
PLAYER_Y    .word 100
LIVES       .byte 3
DEAD        .byte 0
RESET_BOARD .byte 0 ; set this to 180 and the SOF will stop the game updates.
BEE_TIMER   .byte 0 ; show the bee for a short period of time.
SCORE       .word 0 

game_array  ; the array treats each sprite in order
            ;     speed  X       Y        sprite
            .word $FFFC, 640-96, 480-96 , 0        ; sprite  0 - car front
            .word $FFFC, 640-64, 480-96 , 1        ; sprite  1 - car back
            .word     2, 32    , 480-128, 2        ; sprite  2 - bus back
            .word     2, 64    , 480-128, 3        ; sprite  3 - bus middle
            .word     2, 96    , 480-128, 4        ; sprite  4 - bus front
            .word $FFFA, 96    , 480-160, 0        ; sprite  5 - car front
            .word $FFFA, 128   , 480-160, 1        ; sprite  6 - car back
            .word     1, 192   , 288    , 8        ; sprite  7 - oldie front
            .word     1, 224   , 288    , 9        ; sprite  8 - oldie back
            .word $FFFB, 320   , 160    , 5        ; sprite  9 - log 1
            .word $FFFB, 352   , 160    , 6        ; sprite 10 - log 2
            .word $FFFB, 384   , 160    , 7        ; sprite 11 - log 3
            .word     2, 416   , 192    , 5        ; sprite 12 - log 1
            .word     2, 448   , 192    , 7        ; sprite 13 - log 3
            .word $FFFE, 512   , 224    ,16        ; sprite 15 - lilypad
            .word     0, 0     , 0      ,PLAYER_UP ; - player sprite

; our resolution is 640 x 480 - tiles are 16 x 16 - therefore 40 x 30
; I've added 'dirty' tiles here to test the machine and FoenixIDE rendering of tiles in the border
game_board 
            .text "........................................" ;1 - not shown
            .text ".....A.............AA..................." ;2 - not shown
            .text "........................................" ;3
            .text "........................................" ;4 ; display score and remaining lives here?
            .text "........................................" ;5
            .text "........................................" ;6
            .text "..GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG.." ;7
            .text "..GGGGHHHHHHGGGGHHHHHHGGGGGGHHHHHHGGGG.." ;8
            .text "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.." ;9
            .text "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.." ;10
            .text "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.." ;11
            .text "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.." ;12
            .text "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.." ;13
            .text "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.." ;14
            .text "..CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC.." ;15
            .text "..CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC.." ;16
            .text ".AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;17
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;18
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;19
            .text ".AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;20
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;21
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;22
            .text ".AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;23
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;24
            .text "..CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC.." ;25
            .text "..CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC.." ;26
            .text "........................................" ;27
            .text "........................................" ;28
            .text "............AAA........................." ;29
            .text ".............AAA........................" ;30

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
            
            
            ; Address SONG
            JSL VGM_INIT_TIMERS
            ; load the game over music
            LDA #`SONG
            STA CURRENT_POSITION + 2
            STA SONG_START + 2
            setal
            LDA #<>SONG
            STA SONG_START
            setas
            JSL VGM_SET_SONG_POINTERS
                
            JSR INIT_DISPLAY
            
            ; Enable SOF
            LDA #~( FNX0_INT00_SOF | FNX0_INT02_TMR0)
            STA @lINT_MASK_REG0
            ; Enable Keyboard
            LDA #~( FNX1_INT00_KBD )
            STA @lINT_MASK_REG1
            CLI
            
    GAME_LOOP
            BRA GAME_LOOP

.include "interrupt_handler.asm"
.include "display.asm"
.include "vgm_player.asm"

SONG
;.binary "assets/03 Bay Yard (Daytime) (1st Day).vgm"
;.binary "assets/11 Sarinuka Sands (Daytime) (2nd Day).vgm"
.binary "assets/03 Forest Path.vgm"