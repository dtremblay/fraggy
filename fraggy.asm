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

; *************************************************************************
; * Define variable for managing sprites and tiles
; *************************************************************************
NPC_SPRITES     = 60
VTILE_SET0      = $B00000
VTILE_MAP0      = $B04000
VTILE_MAP1      = $B04960
VSPRITES        = $B10000
VFROGS_UP       = $B20000             ; 4 sprites
VFROGS_DOWN     = VFROGS_UP + 4096    ; 4 sprites
VFROGS_LEFT     = VFROGS_DOWN + 4096  ; 4 sprites
VFROGS_RIGHT    = VFROGS_LEFT + 4096  ; 4 sprites
JOYSTICK_SC_TMP = $000F89

; frog sprite names
PLAYER_UP       =  0
PLAYER_LEFT     =  8
PLAYER_RIGHT    = 12
PLAYER_DOWN     =  4

; sprite names
RED_CAR         =  0
BUS             =  2
LOG             =  5
POLICE_CAR      =  8
SPORTS_CAR      = 10
TRACTOR         = 12
SPLASH_SPRITE   = 14
SPLATT_SPRITE   = 15
LILLYPAD        = 16 ; lilly pad has 8 sprites
TONGUE_SPRITE   = 24
BEE_SPRITE      = 25
BONUS_SPRITE    = 27

; the heart tile - used to display the number of player lives
TILE_HEART      = 16
; the level frog - used to display the level
LEVEL_FROG      = 42
; numbers are displayed with tiles
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

PBAR_1          = 48
RBAR_1          = 52

DEFAULT_LIVES   =  5
THREE_SECS      = 180  ; the number of SOF interrupts for 3 seconds
DEFAULT_TIMER   = 50

* = $160000
; *************************************************************************
; * Setup interrupts, load the song and initialize basic variables.
; *************************************************************************
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
            
            LDA #DEFAULT_LIVES
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
; *************************************************************************
; * Game registers
; *************************************************************************
PLAYER_X    .word 100
PLAYER_Y    .word 100
LIVES       .byte DEFAULT_LIVES
GAME_OVER   .byte 0
DEAD        .byte 0
RESET_BOARD .byte 0 ; set this to 180 and the SOF will stop the game updates.
BEE_TIMER   .byte 0 ; show the bee for a short period of time.
SCORE       .long 0 
GTIMER      .byte 50 ; this timer is used to control the game time
TONGUE_POS  .word 0
TONGUE_CTR  .byte 0
PL_MOVE_UP  .byte 0
MOVING      .byte 0
MOVING_CNT  .byte 0
SPRITE_OFFSET   .BYTE 0, 1, 2, 2, 2, 3, 0
SPRITE_MOVE     .WORD 0, 0, 8, 8, 8, 8, 0
HOME_NEST   .byte 0 ; record the nests that have been filled
LEVEL       .byte 1
NEST_UP     .byte 0 ; player has just filled the next
SOF_COUNTER .byte 0 ; count seconds - 60 SOF interrupts

.include "interrupt_handler.asm"
.include "display.asm"
.include "vgm_player.asm"

; *************************************************************************
; * Song file - in VGM format
; *************************************************************************
SONG
.binary "assets/03 Forest Path.vgm"
;.binary "assets/03 Bay Yard (Daytime) (1st Day).vgm"
;.binary "assets/11 Sarinuka Sands (Daytime) (2nd Day).vgm"

; *************************************************************************
; * The game board is 40 x 30 tiles
; *************************************************************************
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

; *************************************************************************
; *************************************************************************
; * Image files for tiles and sprites, along with color palette
; *************************************************************************
; *************************************************************************
* = $170000
TILES
            .binary "assets/fraggy-tileset.bin"
SPRITES
            .binary "assets/fraggy-sprites.bin"
PALETTE_TILES
            .binary "assets/fraggy.pal"
* = $180000
FROG_UP
            .binary "assets/frog-sheet-up.bin"
FROG_DOWN
            .binary "assets/frog-sheet-down.bin"
FROG_LEFT
            .binary "assets/frog-sheet-left.bin"
FROG_RIGHT
            .binary "assets/frog-sheet-right.bin"


; *************************************************************************
; * The game array describes the sprites, position, speed and direction
; * The FMX machine has 64 sprites.  4 sprites are reserved for the player.
; * The remaining 60 sprites can be used by the game array.
; * If this is not enough, use the SOL interrups to double the number of 
; * sprite to 128.
; *************************************************************************
game_array  ; the array treats each sprite in order
            ;     speed  X       Y        sprite
            .word     1, 640-96, 14*32-16 , TRACTOR        ; sprite  1
            .word     1, 640-64, 14*32-16 , TRACTOR + 1    ; sprite  2
            .word     1, 170   , 14*32-16 , TRACTOR        ; sprite  3
            .word     1, 202   , 14*32-16 , TRACTOR + 1    ; sprite  4
            .word $FFFA, 96    , 13*32-16 , POLICE_CAR     ; sprite  5
            .word $FFFA, 128   , 13*32-16 , POLICE_CAR + 1 ; sprite  6
            .word     2, 32    , 12*32-16 , BUS            ; sprite  7
            .word     2, 64    , 12*32-16 , BUS + 1        ; sprite  8
            .word     2, 96    , 12*32-16 , BUS + 2        ; sprite  9
            .word $FFFC, 320-96, 10*32-16 , RED_CAR        ; sprite 10
            .word $FFFC, 320-64, 10*32-16 , RED_CAR + 1    ; sprite 11
            .word     8, 192   , 11*32-16 , SPORTS_CAR     ; sprite 12
            .word     8, 224   , 11*32-16 , SPORTS_CAR +1  ; sprite 13
            .word     0, 0     , 0        , 0              ; blank  14
            .word     0, 0     , 0        , 0              ; blank  15
            .word     0, 0     , 0        , 0              ; blank  16
            .word     0, 0     , 0        , 0              ; blank  17
            .word     0, 0     , 0        , 0              ; blank  18
            .word     0, 0     , 0        , 0              ; blank  19
            .word     0, 0     , 0        , 0              ; blank  20
            .word     0, 0     , 0        , 0              ; blank  21
            .word     0, 0     , 0        , 0              ; blank  22
            .word     0, 0     , 0        , 0              ; blank  23
            .word     0, 0     , 0        , 0              ; blank  24
            .word     0, 0     , 0        , 0              ; blank  25
            .word     0, 0     , 0        , 0              ; blank  26
            .word     0, 0     , 0        , 0              ; blank  27
            .word     0, 0     , 0        , 0              ; blank  28
            .word     0, 0     , 0        , 0              ; blank  29
            .word     0, 0     , 0        , 0              ; blank  30
            
            ; line 9 *32 is safe
            .word     2,  96   , 4*32-16    , LOG            ; sprite 31
            .word     2, 128   , 4*32-16    , LOG + 2        ; sprite 32
            .word     2, 416   , 4*32-16    , LOG            ; sprite 33
            .word     2, 448   , 4*32-16    , LOG + 2        ; sprite 34
            .word $FFFD, 320   , 5*32-16    , LOG            ; sprite 35
            .word $FFFD, 352   , 5*32-16    , LOG + 1        ; sprite 36
            .word $FFFD, 384   , 5*32-16    , LOG + 2        ; sprite 37
            .word     2, 416   , 6*32-16    , LILLYPAD + 5   ; sprite 38
            .word     2, 132   , 6*32-16    , LILLYPAD + 7   ; sprite 39
            .word     1, 320   , 7*32-16    , LOG            ; sprite 40
            .word     1, 352   , 7*32-16    , LOG + 1        ; sprite 41
            .word     1, 384   , 7*32-16    , LOG + 2        ; sprite 42
            .word     1,  40   , 7*32-16    , LOG            ; sprite 43
            .word     1,  72   , 7*32-16    , LOG + 1        ; sprite 44
            .word     1, 104   , 7*32-16    , LOG + 2        ; sprite 45
            .word $FFFE, 512   , 8*32-16    , LILLYPAD + 6   ; sprite 46
            .word $FFFE, 260   , 8*32-16    , LILLYPAD + 2   ; sprite 47
            .word     0, 0     , 0          , 0              ; blank  48
            .word     0, 0     , 0          , 0              ; blank  49
            .word     0, 0     , 0          , 0              ; blank  50
            .word     0, 0     , 0          , 0              ; blank  51
            .word     0, 0     , 0          , 0              ; blank  52
            .word     0, 0     , 0          , 0              ; blank  53
            .word     0, 0     , 0          , 0              ; blank  54
            .word     0, 0     , 0          , 0              ; blank  55
            .word     0, 0     , 0          , 0              ; blank  56
            .word     0, 0     , 0          , 0              ; blank  57
            .word     0, 0     , 0          , 0              ; blank  58
            .word     0, 0     , 0          , 0              ; blank  59
            .word     0, 0     , 0          , 0              ; blank  60
            
