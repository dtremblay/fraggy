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
                LDA #Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_Bitmap_En + Mstr_Ctrl_TileMap_En + Mstr_Ctrl_Sprite_En + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L
                
                
                
                ; display intro screen
                ; wait for user to press a key or joystick button
                
                ; load tiles
                setaxl
                LDX #<>TILES
                LDY #0
                LDA #$1100 ; 256 * 16
                MVN <`TILES,$B0
                
                
                ; load tileset

                ; load LUT
                LDX #<>PALETTE
                LDY #<>GRPH_LUT0_PTR
                LDA #28
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
                LDY #480-32
                BRA JOY_LEFT
                
        JOY_DOWN
                BIT #2 ; down
                BNE JOY_LEFT
                INY
                INY
                CPY #480-32
                BNE JOY_LEFT
                LDY #32
                
        JOY_LEFT
                BIT #4
                BNE JOY_RIGHT
                DEX
                DEX
                CPX #32
                BNE JOY_DONE
                LDX #640-32
                BRA JOY_DONE
                
        JOY_RIGHT 
                BIT #8
                BNE JOY_DONE
                INX
                INX
                CPX #640-32
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
                
; our resolution is 640 x 480 - tiles are 16 x 16 - therefore 40 x 30
game_board 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "..................o....................." 
                .text "................o...o..................." 
                .text "........................................" 
                .text "........................................" 
                .text "................#####..................." 
                .text "...........#............................" 
                .text ".........###............#_#............." 
                .text "........####............#.#............." 
                .text "#########################.##############" 
                .text "........................#.#............." 
                .text "........................#.#............." 
                .text "........................#.#............." 
                .text ".........###############...#............" 
                .text ".........#.ooooooooooooooo.#............" 
                .text ".........###################............" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 
                .text "........................................" 

PALETTE         .byte 0,0,0, $00           ;black
                .byte $40,$20,$e0, $00     ;red
                .byte $40,$80,$c0, $00     ;brown
                .byte $40,$c0,$20, $00     ;green
                .byte $00,$00,$FF, $00     ;pure red
                .byte $00,$FF,$00, $00     ;pure green
                .byte $FF,$00,$00, $00     ;pure blue
                
* = $170000
TILES
.binary "simple-tiles.data"