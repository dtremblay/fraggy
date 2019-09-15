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
                LDA #52
                MVN <`PALETTE,<`GRPH_LUT0_PTR
                
                LDX #<>PALETTE
                LDY #<>GRPH_LUT1_PTR
                LDA #28
                MVN <`PALETTE,<`GRPH_LUT1_PTR
                
                ; start at position (100,100)
                LDA #100
                STA @lSP01_X_POS_L
                LDA #100
                STA @lSP01_Y_POS_L
                
                setas
                
                ; enable tiles
                LDA #TILE_Enable + TILESHEET_256x256_En
                STA @lTL0_CONTROL_REG
                ; enable sprite 0
                LDA #SPRITE_Enable
                STA @lSP01_CONTROL_REG
                
                ; load tileset
                JSR LOAD_TILESET
                
                ; render the first frame
                JSR LOAD_SPRITE
                LDA #$9F ; - joystick in initial state
                JSR UPDATE_DISPLAY
                
                RTS

LOAD_SPRITE
                .as
                ; read joystick
                ; display player
                LDA #0
                STA @lSP01_ADDY_PTR_L
                STA @lSP01_ADDY_PTR_M
                LDA #1
                STA @lSP01_ADDY_PTR_H  ; address of the sprite data - sprite data is located at $B1:0000
                
                LDX #32 * 32
                LDA #2
        BUILD_SPRITE
                STA @l$B0FFFF,X
                ;INC A
            COLOR_RAMP
                DEX
                BNE BUILD_SPRITE
                
                RTS
                
                
; ****************************************************
; * A contains the joystick byte
; ****************************************************
UPDATE_DISPLAY
                .as
                LDY #0
                JSR WRITE_HEX
                
                PHA
                setal
                LDA @lPLAYER_X
                TAX
                LDA @lPLAYER_Y
                TAY
                setas
                PLA
        JOY_UP
                BIT #1 ; up
                BNE JOY_DOWN
                DEY
                DEY
                CPY #32
                BNE JOY_LEFT
                LDY #480-64
                BRA JOY_LEFT
                
        JOY_DOWN
                BIT #2 ; down
                BNE JOY_LEFT
                INY
                INY
                CPY #480-64
                BNE JOY_LEFT
                LDY #32
                
        JOY_LEFT
                BIT #4
                BNE JOY_RIGHT
                DEX
                DEX
                CPX #32
                BNE JOY_DONE
                LDX #640-64
                BRA JOY_DONE
                
        JOY_RIGHT 
                BIT #8
                BNE JOY_DONE
                INX
                INX
                CPX #640-64
                BNE JOY_DONE
                LDX #32
                
        JOY_DONE
                setal
                TXA
                STA PLAYER_X
                STA @lSP01_X_POS_L
                
                TYA
                STA PLAYER_Y
                STA @lSP01_Y_POS_L
                setas
                
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
                .text "..GGGGHHHGGGGGGGGGHHHHGGGGGGGGGHHHGGGG.." ;8
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
                .text "........................................" ;25
                .text "........................................" ;26
                .text "........................................" ;27
                .text "........................................" ;28
                .text "........................................" ;29
                .text "........................................" ;30


PALETTE         
                .byte $ff,$ff,$ff,$00 
                .byte $00,$cc,$99,$00 
                .byte $99,$99,$99,$00 
                .byte $00,$00,$00,$00 
                .byte $00,$33,$6,$00 
                
                .byte $33,$33,$33,$00 
                .byte $ff,$99,$33,$00 
                .byte $ff,$00,$00,$00 
                .byte $00,$99,$33,$00 
                
                .byte $33,$33,$ff,$00 
                .byte $66,$99,$00,$00 
                .byte $33,$00,$99,$00 
                .byte $00,$ff,$ff,$00  
                
* = $170000
TILES
.binary "assets/simple-tiles.data"