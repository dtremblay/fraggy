; *************************************************************************
; *************************************************************************
; * Attempt at a copy-cat game like Frogger
; * Tileset is stored in "game_board".
; * Sprites 0 to 3 are reserved for player animations.
; * Sprites 4 to 63 are for NPC.
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

TOTAL_SPRITES   = 27
VTILE_SET0      = $B00000
VTILE_MAP0      = $B03000
VTILE_MAP1      = $B03960
VSPRITES        = $B10000
JOYSTICK_SC_TMP = $000F89

; sprite names
PLAYER_UP       = 10
PLAYER_LEFT     = 11
PLAYER_RIGHT    = 13
PLAYER_DOWN     = 12
SPLASH_SPRITE   = 14
SPLATT_SPRITE   = 15
LILLYPAD_SPRITE = 16 ; lilly pad has 8 sprites
TONGUE_SPRITE   = 24
BEE_SPRITE      = 25
THREE_SECS      = 180

; numbers are displayed with tiles
TILE_HEART      = 16
TILE_0          = 32
TILE_1          = 33
TILE_2          = 34
TILE_3          = 35
TILE_4          = 36
TILE_5          = 37
TILE_6          = 38
TILE_7          = 39
TILE_8          = 40
TILE_9          = 41

* = $160000

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
            
            ; initialize variables
            LDA #0
            STA SCORE
            STA MOUSE_PTR_CTRL_REG_L ; disable the mouse pointer
            
            setas
            STA TONGUE_POS
            STA BEE_TIMER
            STA GAME_OVER
            STA DEAD
            
            LDA #3
            STA LIVES
            
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
            
PLAYER_X    .word 100
PLAYER_Y    .word 100
LIVES       .byte 3
GAME_OVER   .byte 0
DEAD        .byte 0
RESET_BOARD .byte 0 ; set this to 180 and the SOF will stop the game updates.
BEE_TIMER   .byte 0 ; show the bee for a short period of time.
SCORE       .word 0 
TONGUE_POS  .word 0
TONGUE_CTR  .byte 0
PL_MOVE_UP  .byte 0

.include "interrupt_handler.asm"
.include "display.asm"
.include "vgm_player.asm"

SONG
;.binary "assets/03 Bay Yard (Daytime) (1st Day).vgm"
;.binary "assets/11 Sarinuka Sands (Daytime) (2nd Day).vgm"
.binary "assets/03 Forest Path.vgm"

; our resolution is 640 x 480 - tiles are 16 x 16 - therefore 40 x 30
; I've added 'dirty' tiles here to test the machine and FoenixIDE rendering of tiles in the border
game_board 
            .binary "assets/fraggy-tilemap.tlm"  ; 40 x 30 x 2 = 2400 bytes - this could be easily compressed by removing all the even bytes.
            
game_over_board 
            .text "........................................" ;1 - not shown
            .text "........................................" ;2 - not shown
            .text "........................................" ;3
            .text "........................................" ;4 ; display score and remaining lives here?
            .text "........................................" ;5
            .text "........................................" ;6
            .text "........................................" ;7
            .text "........................................" ;8
            .text "........................................" ;9
            .text "........................................" ;10
            .text "........................................" ;11
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;12
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;13
            .text "..AA................................AA.." ;14
            .text "..AA................................AA.." ;15
            .text "..AA................................AA.." ;16
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;17
            .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;18
            .text "........................................" ;19
            .text "........................................" ;20
            .text "........................................" ;21
            .text "........................................" ;22
            .text "........................................" ;23
            .text "........................................" ;24
            .text "........................................" ;25
            .text "........................................" ;26
            .text "........................................" ;27
            .text "........................................" ;28
            .text "........................................" ;29
            .text "........................................" ;30

TILES
            .binary "assets/fraggy-tileset.bin"
PALETTE_TILES
            .binary "assets/fraggy.pal"
PALETTE_SPRITES
            .binary "assets/sprites.pal"
            
* = $170000
SPRITES
            .binary "assets/fraggy-sprites.bin"

; I'm leaving the game array at the end because I want to be able to extend the list to 64 sprites, eventually
game_array  ; the array treats each sprite in order
            ;     speed  X       Y        sprite
            .word $FFFC, 640-96, 14*32 , 0              ; sprite  0 - car front
            .word $FFFC, 640-64, 14*32 , 1              ; sprite  1 - car back
            .word     2, 32    , 13*32 , 2              ; sprite  2 - bus back
            .word     2, 64    , 13*32 , 3              ; sprite  3 - bus middle
            .word     2, 96    , 13*32 , 4              ; sprite  4 - bus front
            .word $FFFA, 96    , 12*32 , 0              ; sprite  5 - car front
            .word $FFFA, 128   , 12*32 , 1              ; sprite  6 - car back
            .word     1, 192   , 11*32 , 8              ; sprite  7 - oldie back
            .word     1, 224   , 11*32 , 9              ; sprite  8 - oldie front
            .word $FFFC, 320-96, 10*32 , 0              ; sprite  0 - car front
            .word $FFFC, 320-64, 10*32 , 1              ; sprite  1 - car back
            ; line 9 *32 is safe
            .word $FFFB, 320   , 160    , 5              ; sprite  9 - log 1
            .word $FFFB, 352   , 160    , 6              ; sprite 10 - log 2
            .word $FFFB, 384   , 160    , 7              ; sprite 11 - log 3
            .word     2, 416   , 192    , 5              ; sprite 12 - log 1
            .word     2, 448   , 192    , 7              ; sprite 13 - log 3
            .word $FFFE, 512   , 224    ,LILLYPAD_SPRITE ; sprite 15 - lilypad
            
            ;.word     0, 0     , 0      ,PLAYER_UP       ; player sprite
