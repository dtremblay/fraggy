INIT_DISPLAY
                .as
                ; set the display size - 128 x 64
                LDA #128
                STA COLS_PER_LINE
                LDA #64
                STA LINES_MAX

                ; set the visible display size - 80 x 60
                LDA #80
                STA COLS_VISIBLE
                LDA #60
                STA LINES_VISIBLE
                LDA #32
                STA BORDER_X_SIZE
                STA BORDER_Y_SIZE

                ; set the border to purple
                setas
                LDA #$20
                STA BORDER_COLOR_B
                STA BORDER_COLOR_R
                LDA #0
                STA BORDER_COLOR_G

                ; enable the border
                LDA #Border_Ctrl_Enable
                STA BORDER_CTRL_REG

                ; enable graphics, tiles and sprites display
                LDA #Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_Bitmap_En + Mstr_Ctrl_TileMap_En + Mstr_Ctrl_Sprite_En ; + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L
                
                ; display intro screen
                ; wait for user to press a key or joystick button
                
                ; load tiles
                setaxl
                LDX #<>TILES
                LDY #0
                LDA #$2100 ; 256 * 32
                MVN <`TILES,$B0

                ; load LUT
                LDX #<>PALETTE
                LDY #<>GRPH_LUT0_PTR
                LDA #1024
                MVN <`PALETTE,<`GRPH_LUT0_PTR
                
                LDX #<>FG_PALETTE
                LDY #<>GRPH_LUT1_PTR
                LDA #1024
                MVN <`FG_PALETTE,<`GRPH_LUT1_PTR
                
                setas
                
                ; enable tiles
                LDA #TILE_Enable + TILESHEET_256x256_En
                STA @lTL0_CONTROL_REG
                
                ; load tileset
                JSR LOAD_TILESET
                
                ; render the first frame
                JSR LOAD_SPRITES
                
                JSR INIT_PLAYER
                JSR INIT_NPC
                
                LDA #$9F ; - joystick in initial state
                JSR UPDATE_DISPLAY
                RTS

LOAD_SPRITES
                .as
                
                LDA #0
                XBA
                LDX #0  ; X increments in steps of 8
    LS_LOOP
                ; enable sprites
                LDA #0
                STA @lSP00_ADDY_PTR_L,X
                LDA #SPRITE_Enable
                STA @lSP00_CONTROL_REG,X
                STA @lSP00_ADDY_PTR_H,X
                TXA
                LSR
                STA @lSP00_ADDY_PTR_M,X
                ASL
                
                CLC
                ADC #8
                TAX
                CPX #64
                BNE LS_LOOP
                
                ; display player
                setal
                LDX #<>SPRITES
                LDY #0
                LDA #8*32*32
                MVN <`SPRITES,$B1
                setas
                
                
                RTS
                
INIT_PLAYER
                ; start at position (100,100)
                setal
                LDA #8 * 32 + 32
                STA PLAYER_X
                STA @lSP07_X_POS_L
                LDA #10 * 32 + 64
                STA PLAYER_Y
                STA @lSP07_Y_POS_L
                setas
                RTS

INIT_NPC
                .as
                setal
                LDX #0
                
        INIT_NPC_LOOP
                CLC
                LDA game_array + 2,X ; X POSITION
                STA @lSP00_X_POS_L,X
                LDA game_array + 4,X ; Y POSITION
                STA @lSP00_Y_POS_L,X
                
                LDA game_array + 6,X ; sprite #
                
                CLC
                TXA
                ADC #8
                TAX
                CPX #56
                BNE INIT_NPC_LOOP
                
                setas
                RTS

; ****************************************************
; * A contains the joystick byte
; ****************************************************
UPDATE_DISPLAY
                .as
                setal
        JOY_UP
                BIT #1 ; up
                BNE JOY_DOWN
                JSR PLAYER_MOVE_UP
                BRA JOY_DONE
                
        JOY_DOWN
                BIT #2 ; down
                BNE JOY_LEFT
                JSR PLAYER_MOVE_DOWN
                BRA JOY_DONE
                
        JOY_LEFT
                BIT #4
                BNE JOY_RIGHT
                JSR PLAYER_MOVE_LEFT
                BRA JOY_DONE
                
        JOY_RIGHT 
                BIT #8
                BNE JOY_DONE
                JSR PLAYER_MOVE_RIGHT
                BRA JOY_DONE
                
        JOY_DONE
                setas
                JSR UPDATE_NPC_POSITIONS
                RTS

UPDATE_NPC_POSITIONS
                .as
                setal
                LDX #0
                
        UNPC_LOOP
                CLC
                LDA game_array + 2,X ; X POSITION
                CLC
                ADC game_array,X ; add the speed
                BCC GRT_LFT_MRG
                
                CMP #16
                BCS GRT_LFT_MRG
                LDA #640-32 ; right edge
                BRA LESS_RGT_MRG
                
        GRT_LFT_MRG
                CMP #640 - 32
                BCC LESS_RGT_MRG
                LDA #0
                
        LESS_RGT_MRG
                STA @lSP00_X_POS_L,X
                STA game_array + 2,X
                
                CLC
                TXA
                ADC #8
                TAX
                CPX #56
                BNE UNPC_LOOP
                
                setas
                RTS
; ********************************************
; * Player movements
; ********************************************
PLAYER_MOVE_DOWN
                .al
                LDA PLAYER_Y
                CLC
                ADC #32
                ; check for collisions and out of screen
                CMP #480 - 96
                BCC PMD_DONE
                LDA #480 - 96 ; the lowest position on screen
                
        PMD_DONE
                STA PLAYER_Y
                STA SP07_Y_POS_L
                RTS
                
PLAYER_MOVE_UP
                LDA PLAYER_Y
                SEC
                SBC #32
                ; check for collisions and out of screen
                CMP #96
                BCS PMU_DONE
                LDA #96
                
        PMU_DONE
                STA PLAYER_Y
                STA SP07_Y_POS_L
                RTS
                
PLAYER_MOVE_RIGHT
                LDA PLAYER_X
                CLC
                ADC #32
                ; check for collisions and out of screen
                CMP #640 - 64
                BCC PMR_DONE
                LDA #640 - 64 ; the lowest position on screen
                
        PMR_DONE
                STA PLAYER_X
                STA SP07_X_POS_L
                RTS
                
PLAYER_MOVE_LEFT
                LDA PLAYER_X
                SEC
                SBC #32
                ; check for collisions and out of screen
                CMP #32
                BCS PML_DONE
                LDA #32
                
        PML_DONE
                STA PLAYER_X
                STA SP07_X_POS_L
                RTS
                
; ****************************************************
; * Write a Hex Value to the position specified by Y
; * Y contains the screen position
; * A contains the value to display
HEX_MAP         .text '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
LOW_NIBBLE      .byte 0
HIGH_NIBBLE     .byte 0
WRITE_HEX
                .as
                .xl
        PHA
            PHX
                PHY
                PHA
                    AND #$F0
                    lsr A
                    lsr A
                    lsr A
                    lsr A
                    setxs
                    TAX
                    LDA HEX_MAP,X
                    STA @lLOW_NIBBLE
                
                PLA
                AND #$0F
                TAX
                LDA HEX_MAP,X
                STA @lHIGH_NIBBLE
                
                setaxl
                PLY
                LDA @lLOW_NIBBLE
                STA [SCREENBEGIN], Y
                ; change the foreground color of the text
                LDA #$1010
                TYX
                STA @lCS_COLOR_MEM_PTR, X
                setas
            PLX
        PLA
                RTS

; *********************************************************
; * Convert the game_board to a tile set
; *********************************************************
LOAD_TILESET
                LDX #0
                LDY #0
                setdbr $AF
                setas
    GET_TILE
                LDA game_board,X

        DOT     CMP #'.'
                BNE GRASS
                LDA #0
                STA TILE_MAP0,Y
                BRA LT_DONE
                
        GRASS
                CMP #'G'
                BNE HOME
                LDA #2
                STA TILE_MAP0,Y
                BRA LT_DONE
                
        HOME
                CMP #'H'
                BNE WATER
                LDA #$12
                STA TILE_MAP0,Y
                BRA LT_DONE
             
        WATER
                CMP #'W'
                BNE CONCRETE
                LDA #4
                STA TILE_MAP0,Y
                BRA LT_DONE
                
        CONCRETE
                CMP #'C'
                BNE ASHPHALT
                LDA #1
                STA TILE_MAP0,Y
                BRA LT_DONE
                
        ASHPHALT
                CMP #'A'
                BNE DIRT
                LDA #5
                STA TILE_MAP0,Y
                BRA LT_DONE
                
        DIRT
                CMP #'D'
                BNE LT_DONE
                LDA #3
                STA TILE_MAP0,Y
                BRA LT_DONE
                
    LT_DONE
                INY
                setal
                TYA
                AND #$3F
                CMP #40
                BNE LT_NEXT_TILE
                TYA
                CLC
                ADC #24
                TAY
                
    LT_NEXT_TILE
                setas
                INX
                CPX #(640/16) * (480 / 16)
                BNE GET_TILE
                RTS
                
; our resolution is 640 x 480 - tiles are 16 x 16 - therefore 40 x 30
game_board 
                .text "........................................" ;1 - not shown
                .text "........................................" ;2 - not shown
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
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;17
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;18
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;19
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;20
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;21
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;22
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;23
                .text "..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.." ;24
                .text "..CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC.." ;25
                .text "..CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC.." ;26
                .text "........................................" ;27
                .text "........................................" ;28
                .text "........................................" ;29
                .text "........................................" ;30

PALETTE
.binary "assets/simple-tiles.data.pal"
FG_PALETTE
.binary "assets/simple-tiles.data.pal"

SPRITES
.binary "assets/car1.data"
.binary "assets/car2.data"
.binary "assets/bus1.data"
.binary "assets/bus2.data"
.binary "assets/bus3.data"
.binary "assets/car1.data"
.binary "assets/car2.data"
.binary "assets/frog.data"

* = $170000
TILES
.binary "assets/simple-tiles.data"

