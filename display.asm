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
                
                ; RESET the keyboard handler
                STZ KEYBOARD_SC_TMP

                ; enable the border
                LDA #Border_Ctrl_Enable
                STA BORDER_CTRL_REG

                ; enable graphics, tiles and sprites display
                LDA #Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_TileMap_En + Mstr_Ctrl_Sprite_En ; + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L
                
                ; display intro screen
                ; wait for user to press a key or joystick button
                
                
                ; set the stride of tileset0 to 256;
                LDA #8
                STA TILESET0_ADDY_CFG
                ; load tiles @ $B0:0000
                setal
                LDX #<>TILES
                LDY #<>TILE_SET0
                LDA #$2000 ; 256 * 32 - this is two rows of tiles
                MVN <`TILES,<`TILE_SET0

                ; load LUT0
                LDX #<>PALETTE
                LDY #<>GRPH_LUT0_PTR
                LDA #1024
                MVN <`PALETTE,<`GRPH_LUT0_PTR
                
                ;load LUT1 - same as LUT0 - this is a bug in Vicky
                LDX #<>PALETTE
                LDY #<>GRPH_LUT1_PTR
                LDA #1024
                MVN <`PALETTE,<`GRPH_LUT1_PTR
                
                ; enable tilemap 1
                LDA #0
                STA TL1_START_ADDY_H
                ; set the tilemap window position to 0
                LDA #0
                STA TL1_WINDOW_X_POS_L
                STA TL1_WINDOW_Y_POS_L
                ; set the columns to 40
                LDA #40
                STA TL1_TOTAL_X_SIZE_L
                ; set the rows to 30
                LDA #30
                STA TL1_TOTAL_Y_SIZE_L
                
                ; set the video RAM to B0:2000
                LDA #<>TILE_MAP0
                STA TL1_START_ADDY_L
                
                setas
                ; enable tilemap 0
                LDA #TILE_Enable + 0 ; the 0 is there to signify LUT0
                STA @lTL1_CONTROL_REG
                
                ; transform the gameboard to tilemap
                JSR TRANSFORM_BOARD_TO_TILEMAP
                
                ; render the first frame
                JSR LOAD_SPRITES
                ; enable the sprites
                JSR ENABLE_SPRITES_NPC
                
                JSR INIT_PLAYER
                JSR INIT_NPC
                
                LDA #$9F ; - joystick in initial state
                JSR UPDATE_DISPLAY
                RTS

; ******************************************************************
; * We're loading sprites (1024 bytes) from a 256x256 tileset
; * This is an odd functions, as sprites as 32x32 and the tileset is 
; * 256 bytes wide.
; ******************************************************************
sprite_line    = $6
sprite_addr    = $10
LOAD_SPRITES
                .as
                LDA #0
                STA sprite_addr
                STA sprite_addr + 1
                LDA #<`SPRITES
                STA sprite_addr + 2
                LDX #0
        NEXT_SPRITE
                LDY #0
                
        LS_LOOP
                LDA TILES + 256 * 32,X
                STA [sprite_addr],Y 
                INX
                setal
                TXA
                AND #31
                BEQ LS_NEXT_LINE
                
        LS_CONTINUE
                setas
                INY
                CPY #1024
                BNE LS_LOOP
                
                LDA sprite_addr + 1
                CLC
                ADC #4
                STA sprite_addr + 1
                AND #31
                ASL A
                ASL A
                ASL A ; multiply by 8
                STA sprite_line
                LDA sprite_addr + 1
                AND #$E0
                STA sprite_line + 1
                LDX sprite_line
                LDA sprite_addr + 1
                CMP #4 * TOTAL_SPRITES
                BNE NEXT_SPRITE

                LDA #0
                RTS
                
ENABLE_SPRITES_NPC
                .as
                setxs
                ; now enabled the sprites
                ; the address of the sprite is based on the game_array
                LDX #0  ; X increments in steps of 8

                LDA #0
                STA @lSP00_CONTROL_REG
                STA @lSP01_CONTROL_REG
                STA @lSP02_CONTROL_REG
                STA @lSP03_CONTROL_REG
                
    LSP_LOOP
                LDA #0
                STA @lSP04_ADDY_PTR_L,X
                LDA #(SPRITE_Enable | SPRITE_DEPTH0)
                STA @lSP04_CONTROL_REG,X
                LDA #1
                STA @lSP04_ADDY_PTR_H,X
                LDA game_array+6,X ; 0 to 23
                ASL A
                ASL A
                STA @lSP04_ADDY_PTR_M,X
                
                TXA
                CLC
                ADC #8
                TAX
                CPX #128
                BNE LSP_LOOP
                setxl
                RTS
                
    LS_NEXT_LINE
                .al
                TXA
                CLC
                ADC #256-32 ; go to the next line, for this sprite
                TAX
                BRA LS_CONTINUE
                
; *************************************************************
; * Initialize player position
; *************************************************************
INIT_PLAYER
                ; start at position (100,100)
                setal
                LDA #PLAYER_UP * 1024
                STA @lSP00_ADDY_PTR_L
                LDA #(SPRITE_Enable | SPRITE_DEPTH0)
                STA @lSP00_CONTROL_REG
                LDA #9 * 32 + 32
                STA PLAYER_X
                STA @lSP00_X_POS_L
                LDA #10 * 32 + 96
                STA PLAYER_Y
                STA @lSP00_Y_POS_L
                
                setas
                LDA #1
                STA @lSP00_ADDY_PTR_H
            
                RTS

; *************************************************************
; * Initialize non-player components, from the game_array
; *************************************************************
INIT_NPC
                .as
                setal
                LDX #0
                
        INIT_NPC_LOOP
                LDA game_array + 2,X ; X POSITION
                STA @lSP04_X_POS_L,X
                LDA game_array + 4,X ; Y POSITION
                STA @lSP04_Y_POS_L,X
                
                TXA
                CLC
                ADC #8
                TAX
                CPX #120
                BNE INIT_NPC_LOOP
                
                setas
                RTS

; ****************************************************
; * A contains the joystick byte
; ****************************************************
UPDATE_DISPLAY
                .as
                PHB
                PHA
                
                ; check if the player is dead
                LDA DEAD
                BEQ NOT_DEAD
                
                ; when the player is dead, wait 180 SOF cycles
                LDA RESET_BOARD
                DEC A
                STA RESET_BOARD
                BNE NO_UPDATE
                
                LDA LIVES ; 
                DEC A
                STA LIVES 
                
                LDA #0
                STA DEAD

                JSR INIT_PLAYER
        NO_UPDATE
                PLA
                PLB
                RTS
                
    NOT_DEAD
                JSR UPDATE_HOME_TILES
                JSR UPDATE_WATER_TILES
                JSR UPDATE_LILLY
                
                ; check if the frog's tongue is out
                LDA TONGUE_POS
                BEQ SKIP_TONGUE_UPDATE
                JSR UPDATE_TONGUE
                PLA
                BRA JOY_DONE
                
        SKIP_TONGUE_UPDATE
                PLA
                setal
                
        JOY_FIRE
                BIT #$10 ; fire
                BNE JOY_UP
                JSR FLICK_TONGUE
                BRA JOY_DONE
                
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
                BIT #4 ; left
                BNE JOY_RIGHT
                JSR PLAYER_MOVE_LEFT
                BRA JOY_DONE
                
        JOY_RIGHT 
                BIT #8 ; right
                BNE JOY_DONE
                JSR PLAYER_MOVE_RIGHT
                BRA JOY_DONE
                
        JOY_DONE
                setas
                JSR UPDATE_NPC_POSITIONS
                JSR COLLISION_CHECK
                PLB
                RTS

; ****************************************************
; * Update non-players
; ****************************************************
UPDATE_NPC_POSITIONS
                .as
                setal
                LDX #0
                
        UNPC_LOOP
                LDA game_array + 2,X ; X POSITION
                CLC
                ADC game_array,X ; add the speed
                BPL GRT_LFT_MRG
                 
                
;                CMP #4
;                BCS GRT_LFT_MRG
                LDA #640-4 ; right edge
                CLC
                ADC game_array,X ; add the speed
                BRA LESS_RGT_MRG
                
        GRT_LFT_MRG
                CMP #640 - 4
                BCC LESS_RGT_MRG
                LDA #0
                
        LESS_RGT_MRG
                STA @lSP04_X_POS_L,X
                STA game_array + 2,X
                
                
                TXA
                CLC
                ADC #8
                TAX
                CPX #120
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
                CMP #480 - 64
                BCC PMD_DONE
                LDA #480 - 64 ; the lowest position on screen
                
        PMD_DONE
                STA PLAYER_Y
                STA SP00_Y_POS_L
                setas
                LDA #PLAYER_DOWN * 4
                STA SP00_ADDY_PTR_M
                setal
                RTS
                
PLAYER_MOVE_UP
                .al
                LDA PLAYER_Y
                SEC
                SBC #32
                ; check for collisions and out of screen
                CMP #128
                BCS PMU_DONE
                LDA #128
                
        PMU_DONE
                STA PLAYER_Y
                STA SP00_Y_POS_L
                setas
                LDA #PLAYER_UP * 4
                STA SP00_ADDY_PTR_M
                setal
                RTS
                
PLAYER_MOVE_RIGHT
                .al
                LDA PLAYER_X
                CLC
                ADC #32
                ; check for collisions and out of screen
                CMP #640 - 32
                BCC PMR_DONE
                LDA #640 - 32 ; the lowest position on screen
                
        PMR_DONE
                STA PLAYER_X
                STA SP00_X_POS_L
                setas
                LDA #PLAYER_RIGHT * 4
                STA SP00_ADDY_PTR_M
                setal
                RTS
                
PLAYER_MOVE_LEFT
                .al
                LDA PLAYER_X
                SEC
                SBC #32
                ; check for collisions and out of screen
                CMP #64
                BCS PML_DONE
                LDA #64
                
        PML_DONE
                STA PLAYER_X
                STA SP00_X_POS_L
                setas
                LDA #PLAYER_LEFT * 4
                STA SP00_ADDY_PTR_M
                setal
                RTS
                
INITIAL_DIST    = 4
FLICK_TONGUE
                .al
                ; turn the frog to UP position
                LDA #PLAYER_UP * 1024
                STA SP00_ADDY_PTR_L
                
                ; enable the sprite
                LDA #TONGUE_SPRITE * 1024
                STA SP01_ADDY_PTR_L
                
                ; X position is the same as the player
                LDA PLAYER_X
                STA SP01_X_POS_L
                
                ; store the animation position
                LDA #INITIAL_DIST
                STA TONGUE_POS
                
                ; Y position is specified by the TONGUE_POS away from the player
                LDA PLAYER_Y
                SBC TONGUE_POS
                STA SP01_Y_POS_L
                
                setas
                LDA #1
                STA SP01_CONTROL_REG
                STA SP01_ADDY_PTR_H
                
                setal
                RTS
                
UPDATE_TONGUE
                .as
                PHB
                setdbr <`TONGUE_CTR
                INC TONGUE_CTR
                LDA TONGUE_CTR
                BIT #7  ; only move the tongue every 16 SOF
                BNE TONGUE_DONE

                CMP #$20
                BGE RETRACT_TONGUE
                
                ASL TONGUE_POS
                BRA MOVE_TONGUE
        RETRACT_TONGUE
                LSR TONGUE_POS
        MOVE_TONGUE
                setal
                LDA PLAYER_Y
                SBC TONGUE_POS
                STA SP01_Y_POS_L
                setas
                
                LDA TONGUE_POS
                CMP #2
                BNE TONGUE_DONE
                STZ TONGUE_POS
                STZ TONGUE_CTR
                ; disable the sprite
                LDA #0
                STA SP01_CONTROL_REG
                
    TONGUE_DONE
                PLB
                RTS
                
; *****************************************************************
; * Compare the location of each sprite with the player's position
; * Sprites are 32 x 32 so the math is pretty simple.
; * Collisions occur with cars and buses and with water.
; * Frog can hop on logs.
; *****************************************************************
COLLISION_CHECK
                .as
                PHB
                setdbr <`TONGUE_CTR
                setal
                LDA PLAYER_Y
                CMP #256 ; mid-screen
                
                BCC WATER_COLLISION
                JSR STREET_COLLISION
                setas
                PLB
                RTS
                
        WATER_COLLISION
                .al
        ; here do the water collision routine
                CMP #256
                BCS CCW_DONE
                
                CMP #160
                BCC HOME_LINE
                
                LDX #0
                
        NEXT_WATER_ROW
                LDA game_array+4,X  ; read the Y position
                CMP PLAYER_Y
                BNE CCW_CONTINUE
                
                LDA PLAYER_X
                CMP game_array+2,X  ; read the X position
                BEQ FLOAT
                BCC CHECK_RIGHT_BOUND_W
        CHECK_LEFT_BOUND_W
                LDA game_array+2,X
                ADC #32
                CMP PLAYER_X
                BCS FLOAT
                BRA CCW_CONTINUE
        CHECK_RIGHT_BOUND_W
                ADC #32
                CMP game_array+2,X  ; read the X position
                BCS FLOAT
                
                
        CCW_CONTINUE
                TXA
                CLC
                ADC #8
                TAX
                CPX #8*16-8
                BNE NEXT_WATER_ROW
                
                BRA W_COLLISION
                
        CCW_DONE
                setas
                PLB
                RTS
                
        FLOAT
                .al
                ; move the frog with the NPC
                CLC
                LDA PLAYER_X
                ADC game_array,X
                CMP #64
                BCC W_COLLISION
                CMP #640-32
                BCS W_COLLISION
                
                STA PLAYER_X
                STA SP00_X_POS_L
                setas
                PLB
                RTS
                
        HOME_LINE
                .al
                LDA PLAYER_X
                LSR
                LSR
                LSR
                LSR ; divide by 16
                TAX
                LDA game_board + 280,X
                AND #$FF
                CMP #'H'
                BEQ HL_DONE
                PLB
                BRA S_COLLISION
        
        HL_DONE
                setas
                PLB
                RTS
                
        W_COLLISION
                .al
                
                setas
                ; show splash sprite at player's location
                LDA #SPLASH_SPRITE * 4
                STA SP00_ADDY_PTR_M

                ; set the player to DEAD
            SET_DEAD
                LDA #1
                STA @lDEAD
                LDA #THREE_SECS
                STA RESET_BOARD
                PLB
                RTS
                
        S_COLLISION
                .al
                PHB
                setas
                ; show splash sprite at player's location
                LDA #SPLATT_SPRITE * 4
                STA SP00_ADDY_PTR_M
                BRA SET_DEAD
                
                
STREET_COLLISION
                .al
                LDX #0
        NEXT_STREET_ROW
                LDA game_array+4,X  ; read the Y position
                CMP PLAYER_Y
                BNE CCS_CONTINUE
                
                LDA PLAYER_X
                CMP game_array+2,X  ; read the X position

                BEQ S_COLLISION
                BCC CHECK_RIGHT_BOUND
        CHECK_LEFT_BOUND
                LDA game_array+2,X
                ADC #32
                CMP PLAYER_X
                BCS S_COLLISION
                BRA CCS_CONTINUE
                
        CHECK_RIGHT_BOUND
                ADC #32
                CMP game_array+2,X  ; read the X position
                BCS S_COLLISION
                
        CCS_CONTINUE
                TXA
                CLC
                ADC #8
                TAX
                CPX #8*16-8
                BNE NEXT_STREET_ROW
        CC_DONE
                setas
                RTS
                
HOME_CYCLE      .byte 0
EVEN_TILE_VAL   .byte $12
ODD_TILE_VAL    .byte $13
UPDATE_HOME_TILES
                .as
                PHB
                ; alternate the HOME tiles to imitate wind motion
                LDA HOME_CYCLE
                INC A
                CMP #15 ; only update every N SOF cycle
                BNE UT_SKIP
                LDA #0
                STA HOME_CYCLE

                LDX #280 ; line 8 in the game board
                LDY #7 * 80 ; line 8 in the tileset
                setdbr <`TILE_MAP0

        UT_GET_TILE
                LDA game_board,X
                CMP #'H'
                BNE UT_DONE
                
                TXA
                AND #1
                BEQ UT_EVEN_TILE
                LDA EVEN_TILE_VAL
                
                STA TILE_MAP0,Y
                BRA UT_DONE
                
        UT_EVEN_TILE
                LDA ODD_TILE_VAL
                STA TILE_MAP0,Y
                
        UT_DONE
                INY
                INY
                INX
                CPX #320
                BNE UT_GET_TILE
                
                ; alternate the tiles
                LDA EVEN_TILE_VAL
                CMP #$12
                BEQ ALT_ODD
                ; A is $13
                STA ODD_TILE_VAL
                LDA #$12
                STA EVEN_TILE_VAL
                PLB
                RTS
                
        ALT_ODD
                ; A is 12
                STA ODD_TILE_VAL
                LDA #$13
                STA EVEN_TILE_VAL
                PLB
                RTS
                
    UT_SKIP
                STA HOME_CYCLE
                PLB
                RTS



WATER_CYCLE     .byte 0
EVEN_WTILE_VAL  .byte $4
ODD_WTILE_VAL   .byte $14
UPDATE_WATER_TILES
                .as
                PHB
                ; alternate the WATER tiles to imitate waves
                LDA WATER_CYCLE
                INC A
                CMP #12 ; only update every N SOF cycle
                BNE UW_SKIP
                LDA #0
                STA WATER_CYCLE

                LDX #8 * 40 ; line 9 in the game board
                LDY #8 * 80 ; line 8 in the tileset
                setdbr <`TILE_MAP0

        UW_GET_TILE
                LDA game_board,X
                CMP #'W'
                BNE UW_DONE

                ;check if X is even/odd
                TXA
                AND #1
                BEQ UW_EVEN_TILE
                LDA EVEN_WTILE_VAL
                
                STA TILE_MAP0,Y
                BRA UW_DONE
                
        UW_EVEN_TILE
                LDA ODD_WTILE_VAL
                STA TILE_MAP0,Y
                
        UW_DONE
                INY
                INY
                setal
                TYA
                AND #$4F
                CMP #80
                BNE WT_NEXT_TILE
                TYA
                CLC
                ADC #24
                TAY
                
    WT_NEXT_TILE
                setas
                
                INX
                CPX #14 * 40
                BNE UW_GET_TILE
                
                ; alternate the tiles
                LDA EVEN_WTILE_VAL
                CMP #4
                BEQ W_ALT_ODD
                ; A is $14
                STA ODD_WTILE_VAL
                LDA #$4
                STA EVEN_WTILE_VAL
                PLB
                RTS
                
        W_ALT_ODD
                ; A is 4
                STA ODD_WTILE_VAL
                LDA #$14
                STA EVEN_WTILE_VAL
                PLB
                RTS
                
    UW_SKIP
                STA WATER_CYCLE
                PLB
                RTS
            
LILLY_CYCLE     .byte 0
UPDATE_LILLY
                .as
                ; alternate the HOME tiles to imitate wind motion
                LDA LILLY_CYCLE
                INC A
                CMP #10 ; only update every N SOF cycle
                BNE UL_SKIP
                LDA #0
                STA LILLY_CYCLE
                
                LDA game_array + 14 * 8 + 6
                INC A
                CMP #24
                BNE STORE_LILLY
                LDA #16
                
        STORE_LILLY
                STA game_array + 14 * 8 + 6
                ASL A
                ASL A
                STA @lSP18_ADDY_PTR_M
                RTS
                
        UL_SKIP
                STA LILLY_CYCLE
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
; * Convert the game_board to a tile map
; *********************************************************
TRANSFORM_BOARD_TO_TILEMAP                
                ; transform the game board into a tilemap
                LDX #0
                LDY #2  ; the tilemap is offset by 1 column, or 2 bytes.
                setdbr <`TILE_MAP0
                setas
    GET_TILE
                LDA game_board,X
                CMP #'.'  ; DOT
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
                
                TXA
                AND #1
                BEQ EVEN_TILE
                LDA #$13
                STA TILE_MAP0,Y
                BRA LT_DONE
                
            EVEN_TILE
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
                ; store the tileset in the next byte
                LDA #0
                STA TILE_MAP0,Y
                INY
                setal
                TYA
                AND #$4F
                CMP #80
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

PALETTE
.binary "assets/fraggy.pal"

* = $170000
TILES
.binary "assets/fraggy.bin"

