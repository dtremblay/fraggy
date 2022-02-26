INIT_DISPLAY
                .as

                ; set the visible display size - 80 x 60
                LDA #$20
                STA BORDER_X_SIZE
                LDA #0
                STA BORDER_Y_SIZE

                ; set the border to black
                STA BORDER_COLOR_B
                STA BORDER_COLOR_R
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
                
                JSR LOAD_ASSETS
                
                setal
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
                LDA #<>VTILE_MAP1
                STA TL1_START_ADDY_L
                
                ; enable tilemap 0 - display the GAME OVER message
                LDA #0
                STA TL0_START_ADDY_H
                ; set the tilemap window position to 0
                LDA #0
                STA TL0_WINDOW_X_POS_L
                STA TL0_WINDOW_Y_POS_L
                ; set the columns to 40
                LDA #40
                STA TL0_TOTAL_X_SIZE_L
                ; set the rows to 30
                LDA #30
                STA TL0_TOTAL_Y_SIZE_L
                ; set the video RAM to B0:2000
                LDA #<>VTILE_MAP0
                STA TL0_START_ADDY_L
                
                LDA #0
                STA SCORE
                
                setas
                ; enable tilemap 1
                LDA #TILE_Enable + 0 ; the 0 is there to signify LUT0
                STA @lTL1_CONTROL_REG
                
                ; disable tilemap 0
                LDA #0
                STA @lTL0_CONTROL_REG
                STA GAME_OVER
                STA DEAD
                STA PL_MOVE_UP
                
                LDA #3
                STA LIVES
                
                ; enable the sprites
                JSR ENABLE_SPRITES_NPC
                
                JSR INIT_PLAYER
                JSR INIT_NPC
                JSR SHOW_SCORE_BOARD
                
                LDA #$DF ; - joystick in initial state
                JSR UPDATE_DISPLAY
                RTS
                
ENABLE_SPRITES_NPC
                .as
                setxs
                ; now enabled the sprites
                ; the address of the sprite is based on the game_array
                LDX #0  ; X increments in steps of 8
                LDY #0
                LDA #0
                ; reserve the first 4 sprites
                STA @lSP00_CONTROL_REG
                STA @lSP01_CONTROL_REG
                STA @lSP02_CONTROL_REG
                STA @lSP03_CONTROL_REG
                
    LSP_LOOP
                LDA game_array, X  ; if the speed is zero skip
                BEQ LSP_SKIP_ROW
                LDA #0
                STA @lSP04_ADDY_PTR_L,X
                LDA #(SPRITE_Enable | SPRITE_DEPTH0 | SPRITE_LUT0)
                STA @lSP04_CONTROL_REG,X
                LDA #1
                STA @lSP04_ADDY_PTR_H,X
                LDA game_array+6,X ; 0 to 23
                ASL A
                ASL A
                STA @lSP04_ADDY_PTR_M,X

    LSP_SKIP_ROW
                TXA
                CLC
                ADC #8
                TAX
                INY
                CPY #32
                BNE LSP_LOOP
                setxl
                RTS
                
; *************************************************************
; * Initialize player position
; *************************************************************
INIT_PLAYER
                ; start at position (100,100)
                setal
                LDA #<>VFROGS_UP
                STA @lSP00_ADDY_PTR_L
                LDA #(SPRITE_Enable | SPRITE_DEPTH0 | SPRITE_LUT0)
                STA @lSP00_CONTROL_REG
                LDA #9 * 32 + 32
                STA PLAYER_X
                STA @lSP00_X_POS_L
                LDA #480
                STA PLAYER_Y
                STA @lSP00_Y_POS_L
                
                setas
                LDA #(`VFROGS_UP - $B0_0000)
                STA @lSP00_ADDY_PTR_H
                LDA #0
                STA MOVING_CNT
                STA MOVING
            
                RTS

; *************************************************************
; * Initialize non-player components, from the game_array
; *************************************************************
INIT_NPC
                .as
                setal
                LDX #0
                LDY #0
                
        INIT_NPC_LOOP
                LDA game_array,X
                BEQ INIT_NPC_SKIP
                LDA game_array + 2,X ; X POSITION
                STA @lSP04_X_POS_L,X
                LDA game_array + 4,X ; Y POSITION
                STA @lSP04_Y_POS_L,X
                
        INIT_NPC_SKIP
                TXA
                CLC
                ADC #8
                TAX
                INY 
                CPY #32
                BNE INIT_NPC_LOOP
                
                setas
                RTS

; display the game over/title screen 
; show the game over tilemap
GAME_OVER_DRAW
                .as

                ; enable tilemap 0
                LDA #TILE_Enable + 0 ; the 0 is there to signify LUT0
                STA @lTL0_CONTROL_REG
                
                ; disable tilemap 1
                LDA #0
                STA @lTL1_CONTROL_REG
                
                ; disable sprites
                LDA #Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_TileMap_En; + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L
                
                setdbr <`VTILE_MAP0
                
                ; transform the game board into a tilemap
                LDX #0
                LDY #2  ; the tilemap is offset by 1 column, or 2 bytes.
                setas
    GOD_GET_TILE
                LDA game_over_board,X
                CMP #'.'  ; DOT
                BNE GOD_ASHPHALT
                LDA #0
                STA VTILE_MAP0,Y
                BRA GOD_DONE
                
        GOD_ASHPHALT
                CMP #'A'
                BNE GO_DONE
                LDA #1
                STA VTILE_MAP0,Y
                
    GOD_DONE
                INY
                ; store the tileset in the next byte
                LDA #0
                STA VTILE_MAP0,Y
                INY
                setal
                TYA
                AND #$4F
                CMP #80
                BNE GOD_NEXT_TILE
                TYA
                CLC
                ADC #24
                TAY
                
    GOD_NEXT_TILE
                setas
                INX
                CPX #(640/16) * (480 / 16)
                BNE GOD_GET_TILE
                
                ; check if the fire button was pressed to restart the game
                PLA
                BIT #$10 ; fire
                BNE GO_DONE
                
                JSR INIT_DISPLAY
        GO_DONE
                PLB
                RTS
                
; ****************************************************
; * A contains the joystick byte - keyboard AWSD mimicks joystick
; ****************************************************
UPDATE_DISPLAY
                .as
                PHB
                PHA
                
                LDA GAME_OVER
                BNE GAME_OVER_DRAW
                
                ; check if the player is dead
                LDA DEAD
                BEQ NOT_DEAD
                
                ; when the player is dead, wait 180 SOF cycles
                LDA RESET_BOARD
                DEC A
                STA RESET_BOARD
                BNE NO_UPDATE
                
                LDA LIVES 
                DEC A
                STA LIVES 
                BNE RESET_FROM_DEAD
                
                ; set the GAME_OVER
                LDA #1
                STA GAME_OVER
                BRA NO_UPDATE
                
        RESET_FROM_DEAD
                LDA #0
                STA DEAD
                STA PL_MOVE_UP
                JSR SHOW_SCORE_BOARD

                JSR INIT_PLAYER
        NO_UPDATE
                PLA
                PLB
                RTS
                
                
    NOT_DEAD
                JSR UPDATE_WATER_TILES
                JSR UPDATE_LILLY
                
                ; check if the frog's tongue is out
                LDA TONGUE_POS
                BEQ SKIP_TONGUE_UPDATE
                JSR UPDATE_TONGUE
                PLA ; if the tongue is sticking out, we don't let the player move
                BRA JOY_DONE
                
        SKIP_TONGUE_UPDATE
                LDA MOVING
                BNE ANIMATE_PLAYER
                
                LDA #0
                STA MOVING_CNT
                PLA
                BIT #$10 ; fire
                BNE JOY_UP
                JSR FLICK_TONGUE
                BRA JOY_DONE
                
        JOY_UP
                BIT #1 ; up
                BNE JOY_DOWN
                JSR PLAYER_MOVE_UP
                LDA #1
                STA PL_MOVE_UP
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
                JSR UPDATE_NPC_POSITIONS
                JSR COLLISION_CHECK
                ; if the player has moved up without collision, add 10 points.
                LDA PL_MOVE_UP
                BEQ UD_DONE
                
                LDA DEAD  ; if the player is dead, score doesn't increase...
                BNE UD_DONE
                setal
                
                LDA PLAYER_Y
                TAY
                SED
                LDA SCORE
                
                ; add 10 to the score in BCD
                CLC
                ADC #10
                STA SCORE
                CLD
                setas
                
                ; reset the score flag
                LDA #0
                STA PL_MOVE_UP
                
                JSR SHOW_SCORE_BOARD
                
        UD_DONE
                PLB
                RTS

; at each 8 SOF interrupt move the player sprite
ANIMATE_PLAYER
                .as
                PLA ; we ignore the player's moves
                LDA #0
                XBA
                LDA MOVING_CNT
                INC A
                BIT #3
                BNE ANIM_DONE
                
                STA MOVING_CNT
                
                ; READ THE OFFSET
                LSR A
                LSR A
                TAX
                LDA SPRITE_OFFSET,X
                PHA
                CLC
                ADC MOVING
                DEC A
                ; MULTIPLY BY 4
                ASL A
                ASL A
                STA @lSP00_ADDY_PTR_M
                
                TXA
                ASL A
                TAX
                LDA MOVING
                CMP #PLAYER_UP + 1
                BEQ ANIM_UP_COL
                
                CMP #PLAYER_RIGHT + 1
                BEQ ANIM_RIGHT_COL
                
                CMP #PLAYER_LEFT + 1
                BEQ ANIM_LEFT_COL
                
                BRA ANIM_DOWN_COL
                
    ANIM_COMPLETE
                PLA ; check if the value was 0
                BNE JOY_DONE
                
                ; stop the moving
                LDA #0
                STA MOVING
                JMP JOY_DONE
                
    ANIM_DONE
                STA MOVING_CNT
                JMP JOY_DONE
                
ANIM_UP_COL
                setal
                
                LDA PLAYER_Y
                SEC
                SBC SPRITE_MOVE,X
                ; check for collisions and out of screen
                CMP #96
                BCS PMU_DONE
                LDA #96
                
        PMU_DONE
                STA PLAYER_Y
                STA SP00_Y_POS_L
                setas
                BRA ANIM_COMPLETE
                
ANIM_LEFT_COL
                setal
                
                LDA PLAYER_X
                SEC
                SBC SPRITE_MOVE,X
                ; check for collisions and out of screen
                CMP #64
                BCS PML_DONE
                LDA #64
                
        PML_DONE
                STA PLAYER_X
                STA SP00_X_POS_L
                setas
                
                BRA ANIM_COMPLETE
             
ANIM_RIGHT_COL             
                setal
                
                LDA PLAYER_X
                CLC
                ADC SPRITE_MOVE,X
                ; check for collisions and out of screen
                CMP #640 - 32
                BCC PMR_DONE
                LDA #640 - 32 ; the lowest position on screen
                
        PMR_DONE
                STA PLAYER_X
                STA SP00_X_POS_L
                setas
                BRA ANIM_COMPLETE
                
ANIM_DOWN_COL
                setal
                
                LDA PLAYER_Y
                CLC
                ADC SPRITE_MOVE,X
                ; check for collisions and out of screen
                CMP #480
                BCC PMD_DONE
                LDA #480 ; the lowest position on screen
                
        PMD_DONE
                STA PLAYER_Y
                STA SP00_Y_POS_L
                setas
                JMP ANIM_COMPLETE
                
; ****************************************************
; * Update non-players
; ****************************************************
UPDATE_NPC_POSITIONS
                .as
                setal
                LDX #0
                LDY #0
                
        UNPC_LOOP
                LDA game_array,X
                BEQ UNP_SKIP_ROW
                LDA game_array + 2,X ; X POSITION
                CLC
                ADC game_array,X     ; add the speed
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
                AND #7
                
        LESS_RGT_MRG
                STA @lSP04_X_POS_L,X
                STA game_array + 2,X
                
        UNP_SKIP_ROW
                TXA
                CLC
                ADC #8
                TAX
                INY
                CPY #32
                BNE UNPC_LOOP
                
                setas
                RTS

; ********************************************
; * Player movements
; ********************************************
PLAYER_MOVE_DOWN
                .as
                LDA #PLAYER_DOWN * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_DOWN + 1
                STA MOVING
                
                RTS
                
PLAYER_MOVE_UP
                .as
                LDA #PLAYER_UP * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_UP + 1
                STA MOVING
                
                RTS
                
PLAYER_MOVE_RIGHT
                .as
                LDA #PLAYER_RIGHT * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_RIGHT + 1
                STA MOVING
                
                RTS
                
PLAYER_MOVE_LEFT
                .as
                LDA #PLAYER_LEFT * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_LEFT + 1
                STA MOVING
                
                RTS
                
INITIAL_DIST    = 4
FLICK_TONGUE
                .as
                LDA #1
                STA SP01_CONTROL_REG
                STA SP01_ADDY_PTR_H
                
                setal
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
                CMP #288 ; mid-screen
                
                BCC WATER_COLLISION
                JSR STREET_COLLISION
                setas
                PLB
                RTS
                
        WATER_COLLISION
                .al
        ; here do the water collision routine
                CMP #288
                BCS CCW_DONE
                
                CMP #128
                BCC HOME_LINE
                
                LDX #16*8 
                LDY #0
                
        NEXT_WATER_ROW
                LDA game_array,X
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
                INY
                CPY #16
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
                .al
                ; add 200 to the score in BCD
                SED
                LDA SCORE
                CLC
                ADC #$200
                STA SCORE
                CLD
                LDA #0
                
                setas
                TXA
                ASL A
                TAX
                
                ; use the player's X position to redecorate the home line
                LDA #14
                STA VTILE_MAP1 + 12 * 40 , X
                LDA #15
                STA VTILE_MAP1 + 12 * 40 + 2, X
                LDA #30
                STA VTILE_MAP1 + 14 * 40, X
                LDA #31
                STA VTILE_MAP1 + 14 * 40 + 2, X
                
                ; set the crown here and restart the player on the first line
                JSR INIT_PLAYER
                
                PLB
                RTS
                
        W_COLLISION
                .al
                
                setas
                ; show splash sprite at player's location
                LDA #SPLASH_SPRITE * 4
                STA SP00_ADDY_PTR_M
                LDA #1
                STA SP00_ADDY_PTR_H

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
                LDA #1
                STA SP00_ADDY_PTR_H
                BRA SET_DEAD
                
                
STREET_COLLISION
                .al
                LDX #0
                LDY #0
        NEXT_STREET_ROW
                LDA game_array,X
                BEQ CCS_CONTINUE
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
                INY
                CPY #16
                BNE NEXT_STREET_ROW
        CC_DONE
                setas
                RTS

WATER_CYCLE     .byte 0
EVEN_WTILE_VAL  .byte $4
ODD_WTILE_VAL   .byte $5
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

                LDX #4 * 40 ; line 9 in the game board
                LDY #4 * 80 + 2; line 8 in the tileset
                setdbr <`VTILE_MAP1

        UW_GET_TILE
                LDA game_board,X
                CMP #'W'
                BNE UW_DONE

                ;check if X is even/odd
                TXA
                AND #1
                BEQ UW_EVEN_TILE
                LDA EVEN_WTILE_VAL
                
                STA VTILE_MAP1,Y
                BRA UW_DONE
                
        UW_EVEN_TILE
                LDA ODD_WTILE_VAL
                STA VTILE_MAP1,Y
                
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
                CPX #16 * 40
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
                LDA #$5
                STA EVEN_WTILE_VAL
                PLB
                RTS
                
    UW_SKIP
                STA WATER_CYCLE
                PLB
                RTS
            
LILLY_CYCLE     .byte 0

; find all the lillies in the game array and make them rotate
UPDATE_LILLY
                .as
                ; alternate the HOME tiles to imitate wind motion
                LDA LILLY_CYCLE
                INC A
                CMP #10 ; only update every N SOF cycle
                BNE UL_SKIP
                LDA #0
                STA LILLY_CYCLE
                
                LDX #8*16
                LDY #0
        UP_LI_CHECK
                LDA game_array,X
                BEQ UP_LI_SKIP_ROW
                
                LDA game_array + 6,X
                BIT #$10
                BEQ UP_LI_SKIP_ROW
                BIT #$20
                BNE UP_LI_SKIP_ROW
                
                INC A
                CMP #24
                BNE STORE_LILLY
                LDA #16
                
        STORE_LILLY
                STA game_array + 6,X
                ASL A
                ASL A
                STA @lSP04_ADDY_PTR_M,X
                
        UP_LI_SKIP_ROW
                TXA
                CLC
                ADC #8
                TAX
                
                INY
                CPY #16
                BNE UP_LI_CHECK
                
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

; display the number of lives remaining
; display the current player score
; display the high score
SHOW_SCORE_BOARD 
                .as
                PHB
                setdbr <`VTILE_MAP1
                LDA #0
                XBA
                LDA #0
                LDX #6
        HEART_CLEAR_LOOP
                STA VTILE_MAP1 + 165,X ; descending loop offset by 1
                DEX
                BNE HEART_CLEAR_LOOP
                
                ; now draw the hearts
                LDA LIVES
                BEQ SSB_SCORE
                LDY #0
                TAX
        SHOW_HEART
                LDA #TILE_HEART
                STA VTILE_MAP1 + 166,Y
                INY
                INY
                DEX
                BNE SHOW_HEART
                
                ; draw the score - each byte is 2 digits BCD 00 to 99
                ; not really elegant...
        SSB_SCORE
                LDA SCORE + 1 ; the high byte
                LSR ; get the high nibble
                LSR A
                LSR A
                LSR A
                CLC 
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 230
               
                LDA SCORE + 1 ; the low nibble
                AND #$F
                CLC
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 232
                
                LDA SCORE
                LSR ; get the high nibble
                LSR A
                LSR A
                LSR A
                CLC 
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 234
                
                LDA SCORE ; the low nibble
                AND #$F
                CLC
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 236
        
                PLB
                RTS

LOAD_ASSETS
                .as
                PHB
                ; set the stride of tileset0 to 256;
                LDA #8
                STA TILESET0_ADDY_CFG
                
                ; load tiles @ $B0:0000
                setal
                LDX #<>TILES
                LDY #<>VTILE_SET0
                LDA #256 * 48 ; three rows of tiles
                MVN <`TILES,<`VTILE_SET0

                ; load LUT0
                LDX #<>PALETTE_TILES
                LDY #<>GRPH_LUT0_PTR
                LDA #1024
                MVN <`PALETTE_TILES,<`GRPH_LUT0_PTR
                
                ; copy tilemap to video RAM
                LDX #<>game_board
                LDY #<>VTILE_MAP1
                LDA #40*30*2
                MVN <`game_board,<`VTILE_MAP1
                
                ; copy sprites to video RAM
                LDX #<>SPRITES
                LDY #<>VSPRITES
                LDA #4 * 8 * 32 * 32  ; 32 k
                MVN <`SPRITES,<`VSPRITES
                
                ; copy fraggy animation to video RAM
                LDX #<>FROG_UP
                LDY #<>VFROGS_UP
                LDA #4 * 4 * 32 * 32  ; 16 k
                MVN <`FROG_UP,<`VFROGS_UP
                
                setas
                PLB
                
                RTS
