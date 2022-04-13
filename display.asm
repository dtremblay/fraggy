; *************************************************************************
; * Initialize the video RAM and machine registers
; *************************************************************************
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
                
                ; load sprites and tiles
                JSR LOAD_ASSETS
                
                setal
                LDA #0
                STA RESET_BOARD
                
                ; enable tilemap 1
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
                
                LDA #$50
                STA SP02_Y_POS_L
                
                LDA #0
                STA SCORE
                
                setas
                STA SCORE + 2
                STA HOME_NEST
                ; enable tilemap 1
                LDA #TILE_Enable + 0 ; the 0 is there to signify LUT0
                STA @lTL1_CONTROL_REG
                
                ; disable tilemap 0
                LDA #0
                STA @lTL0_CONTROL_REG
                STA DEAD
                STA PL_MOVE_UP
                STA NEST_UP
                STA SP01_CONTROL_REG
                ; prepare the bee sprite
                STA SP02_ADDY_PTR_L
                STA SP02_CONTROL_REG
                LDA #1
                STA SP02_ADDY_PTR_H
                LDA #BEE_SPRITE * 4
                STA SP02_ADDY_PTR_M
                
                
                LDA #DEFAULT_LIVES
                STA LIVES
                
                LDA #1
                STA LEVEL
                
                ; enable the non-player sprites
                JSR ENABLE_SPRITES_NPC
                ; initialize the player to the bottom row
                JSR INIT_PLAYER
                JSR INIT_NPC
                JSR SHOW_SCORE_BOARD
                JSR SHOW_LEVEL
                
                ; reset the timer bar
                LDA #0
                STA SOF_COUNTER
                
                LDA #$DF ; - joystick in initial state
                JSR UPDATE_DISPLAY
                
                RTS

; *************************************************************
; * Setup the sprite registers for the non-player sprites
; *************************************************************
ENABLE_SPRITES_NPC
                .as
                ; now enabled the sprites
                ; the address of the sprite is based on the game_array
                LDX #0  ; X increments in steps of 8
                LDY #0  ; Y counts the number of sprites total - 60
                LDA #0
                ; reserve the first 4 sprites
                STA @lSP00_CONTROL_REG
                STA @lSP01_CONTROL_REG
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
                setal
                TXA
                CLC
                ADC #8
                TAX
                setas
                INY
                CPY #NPC_SPRITES
                BNE LSP_LOOP
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
                LDA #9 * 32 + 32  ; the middle of the screen
                STA PLAYER_X
                STA @lSP00_X_POS_L
                
                LDA #15 * 32-16      ; the bottom row
                ;LDA #9 * 32-16        ; use this to debug the middle line
                STA PLAYER_Y
                STA @lSP00_Y_POS_L
                
                setas
                LDA #(`VFROGS_UP - $B0_0000)
                STA @lSP00_ADDY_PTR_H
                LDA #0
                STA MOVING_CNT
                STA MOVING
                STA BEE_NEST
                STA @l SP02_CONTROL_REG  ; hide the bee
                
                LDA #DEFAULT_BEE_TIME/2
                STA BEE_TIMER
                
                LDA #DEFAULT_TIMER
                STA GTIMER
                JSR UPDATE_TIMER_BAR
            
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
                CPY #NPC_SPRITES
                BNE INIT_NPC_LOOP
                
                setas
                RTS

; *************************************************************
; * Display the game over/title screen 
; * Show the game over tilemap
; *************************************************************
GAME_OVER_DRAW
                .as
                LDA GAME_OVER
                CMP #2
                BGE G_O_LOAD_DONE
                
                JSR DRAW_GAME_OVER_MAP
                
    G_O_LOAD_DONE
                ; check if the fire button was pressed to restart the game
                PLA
                BIT #$10 ; fire
                BNE GO_DONE
                
                LDA #0
                STA GAME_OVER
                JSR INIT_DISPLAY
                
        GO_DONE
                PLB
                RTS
                
; *************************************************************
; * The function gets called 60 times a second, by the SOF interrupt.
; * A contains the joystick byte - keyboard AWSD mimicks joystick.
; *************************************************************
UPDATE_DISPLAY
                .as
                PHB
                PHA
                
                LDA GAME_OVER    ; GAME_OVER=1 signifies the player lost
                BNE GAME_OVER_DRAW
                
                ; when the player is dead, wait 180 SOF cycles
                LDA RESET_BOARD   ; wait until RESET_BOARD is zero
                BEQ CHECK_DEAD

                DEC A
                STA RESET_BOARD
                BNE NO_UPDATE
                
       CHECK_DEAD
                ; check if the player is dead
                LDA DEAD
                BEQ NOT_DEAD

                ; if the player died, decrease the remaining lives
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

                JSR INIT_PLAYER
        NO_UPDATE
                PLA
                PLB
                RTS
                
                
    NOT_DEAD
                LDA NEST_UP
                BEQ REG_FLOW

                ; when a player fills the nest, we wait 3 seconds and then reset the player
                LDA #0
                STA NEST_UP

                JSR INIT_PLAYER
                
                LDA HOME_NEST
                CMP #$1F ; go to the next chapter.
                BNE REG_FLOW
                
                ; the player has filled all the nest - go to the next level and reset the game board
                LDA LEVEL
                INC A
                STA LEVEL
                
                ; add 1000 points to the player's score - since the score has 3 bytes, we only add 10 to the middle byte
                setal
                SED
                LDA SCORE+1
                CLC
                ADC #$10
                STA SCORE+1
                CLD
                setas
                
                JSR SHOW_SCORE_BOARD
                LDA #0
                STA HOME_NEST
                JSR SHOW_LEVEL
                
        REG_FLOW
                ; count SOF and update the progress bar, if tick has occured
                LDA SOF_COUNTER
                INC A
                CMP #60
                BNE REG_FLOW_CONTINUE
                
                ; check the bee timer - if timer is zero, change the bee position randomly
                JSR CHECK_BEE_TIMER
                
                ; update the progress bar
                LDA #0
                STA SOF_COUNTER
                ; check the timer
                LDA GTIMER
                DEC A
                BNE GTIMER_UPDATE
                
                ; player has run out of time
                STA GTIMER
                JSR UPDATE_TIMER_BAR

                LDA #SPLATT_SPRITE * 4
                STA SP00_ADDY_PTR_M
                LDA #1
                STA SP00_ADDY_PTR_H
                PLA
                PLB
                JMP SET_DEAD  ; this JMP calls RTS
                
                
            GTIMER_UPDATE
                STA GTIMER
                JSR UPDATE_TIMER_BAR
                BRA REG_FLOW_CONTINUE_2
        
        REG_FLOW_CONTINUE
                STA SOF_COUNTER
        REG_FLOW_CONTINUE_2
                JSR UPDATE_LILLY
                JSR UPDATE_TURTLE
                
                ; check if the frog's tongue is out
                LDA TONGUE_POS
                BEQ SKIP_TONGUE_UPDATE
                JSR UPDATE_TONGUE
                PLA ; if the tongue is sticking out, we don't let the player move
                BRA JOY_DONE
                
        SKIP_TONGUE_UPDATE
                LDA MOVING
                BEQ SKIP_TONGUE_BR
                JMP ANIMATE_PLAYER
                
       SKIP_TONGUE_BR
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
                LDA MOVING
                BNE NO_COLLISION_WHILE_ANIMATING
                JSR COLLISION_CHECK
                
        NO_COLLISION_WHILE_ANIMATING
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
                setas
                
                BCC NOCOL_FINISH
                ; Add 1 to the hi-byte of the score
                CLC
                LDA SCORE+2
                ADC #1
                STA SCORE+2
                
        NOCOL_FINISH
                CLD
                
                ; reset the score flag
                LDA #0
                STA PL_MOVE_UP
                
                JSR SHOW_SCORE_BOARD
                
        UD_DONE
                PLB
                RTS

; *************************************************************
; * The player can move left, right, up and down.
; * When the player is in-flight, moves are not allowed.
; * When the player is in-flight, no collision is computed.
; * Animation occurs ever 4 SOF interrupt move the player sprite
; *************************************************************
ANIMATE_PLAYER
                .as
                PLA ; we ignore the player's moves
                LDA #0
                XBA
                LDA MOVING_CNT
                INC A
                BIT #1
                BNE ANIM_DONE
                
                STA MOVING_CNT
                
                ; READ THE OFFSET
                LSR A
                ;LSR A
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
                BEQ ANIM_COMPLETE_BR
                JMP JOY_DONE
        ANIM_COMPLETE_BR
                ; stop the moving
                LDA #0
                STA MOVING
                JMP JOY_DONE
                
    ANIM_DONE
                STA MOVING_CNT
                JMP JOY_DONE
           
; *************************************************************     
ANIM_UP_COL
                setal
                
                LDA PLAYER_Y
                SEC
                SBC SPRITE_MOVE,X
                ; check for collisions and out of screen
                CMP #80
                BCS PMU_DONE
                LDA #80
                
        PMU_DONE
                STA PLAYER_Y
                STA SP00_Y_POS_L
                setas
                BRA ANIM_COMPLETE
                
; *************************************************************
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

; *************************************************************
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

; *************************************************************
ANIM_DOWN_COL
                setal
                
                LDA PLAYER_Y
                CLC
                ADC SPRITE_MOVE,X
                ; check for collisions and out of screen
                CMP #464
                BCC PMD_DONE
                LDA #464 ; the lowest position on screen
                
        PMD_DONE
                STA PLAYER_Y
                STA SP00_Y_POS_L
                setas
                JMP ANIM_COMPLETE
                
; ****************************************************
; * Update non-players sprites
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
                ;LDA #640-4 ; right edge
                ;CLC
                ;ADC game_array,X ; add the speed
                ADC #640-4
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
                CPY #NPC_SPRITES
                BNE UNPC_LOOP
                
                setas
                RTS

; ********************************************
; * Player Movements
; ********************************************
PLAYER_MOVE_DOWN
                .as
                LDA #PLAYER_DOWN * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_DOWN + 1
                STA MOVING
                
                RTS
; ********************************************
PLAYER_MOVE_UP
                .as
                LDA #PLAYER_UP * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_UP + 1
                STA MOVING
                
                RTS
; ********************************************
PLAYER_MOVE_RIGHT
                .as
                LDA #PLAYER_RIGHT * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_RIGHT + 1
                STA MOVING
                
                RTS
; ********************************************
PLAYER_MOVE_LEFT
                .as
                LDA #PLAYER_LEFT * 4
                STA SP00_ADDY_PTR_M
                LDA #PLAYER_LEFT + 1
                STA MOVING
                
                RTS

; ********************************************
; * Flick the frog's tongue
; * This will used to pick flies remotely.
; ********************************************
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
; ********************************************
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
                CMP #273 ; mid-screen
                
                BLT WATER_COL_BR
                JSR STREET_COLLISION
                setas
                PLB
                RTS
                
        WATER_COL_BR
                .al
        ; here do the water collision routine
                JSR WATER_COLLISION
                setas
                PLB
                RTS
; *****************************************************************
; * Detect a collision when the player position is greather than 288
; *****************************************************************
STREET_COLLISION
                .al
                LDX #0
                LDY #0
        NEXT_STREET_ROW
                LDA game_array,X     ; if speed is 0, skip the row
                BEQ CCS_CONTINUE

                LDA game_array+4,X  ; read the Y position
                CMP PLAYER_Y
                BNE CCS_CONTINUE
                
                LDA PLAYER_X
                CMP game_array+2,X  ; read the X position

                BEQ S_COLLISION
                BLT CHECK_RIGHT_BOUND
                
        CHECK_LEFT_BOUND
                LDA game_array+2,X
                ADC #PLAYER_WIDTH+PADDING
                CMP PLAYER_X
                BGE S_COLLISION   ; BCS
                BRA CCS_CONTINUE
                
        CHECK_RIGHT_BOUND
                ADC #PLAYER_WIDTH + PADDING
                CMP game_array+2,X  ; read the X position
                BGE S_COLLISION
                
        CCS_CONTINUE
                TXA
                CLC
                ADC #8
                TAX
                INY
                CPY #NPC_SPRITES / 2  ; half of the sprites are bottom of the screen
                BNE NEXT_STREET_ROW
        CC_DONE
                setas
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
                PLB
                JMP SET_DEAD

; *****************************************************************
; *  Detect a collision when the player position is less than 288
; *****************************************************************
WATER_COLLISION
                .al
                CMP #262
                BLT WC_CONTINUE
                RTS
                
       WC_CONTINUE
                CMP #80
                BNE WC_COMPARE_ROWS
                JMP HOME_LINE
                
        WC_COMPARE_ROWS
                LDX #NPC_SPRITES / 2 * 8 ; we ignore the first 30 sprites in the game array
                LDY #0
                
        NEXT_WATER_ROW
                ; Skip row if speed is 0
                LDA game_array,X
                BEQ CCW_CONTINUE
                
                ; 
                LDA game_array+4,X  ; read the sprite Y position
                CMP PLAYER_Y
                BNE CCW_CONTINUE

                LDA PLAYER_X
                CMP game_array+2,X  ; read the X position
                BEQ FLOAT
                BCC CHECK_RIGHT_BOUND_W
        CHECK_LEFT_BOUND_W
                LDA game_array+2,X
                ADC #PLAYER_WIDTH+PADDING
                CMP PLAYER_X
                BCS FLOAT
                BRA CCW_CONTINUE
                
        CHECK_RIGHT_BOUND_W
                ADC #PLAYER_WIDTH+PADDING
                CMP game_array+2,X  ; read the X position
                BCS FLOAT
                
        CCW_CONTINUE
                TXA
                CLC
                ADC #8
                TAX
                INY
                CPY #30
                BNE NEXT_WATER_ROW
                ; if none of the sprites match, then the player has fallen in water
                JMP W_COLLISION
        ; the player jumps on logs, lilly pads and turtles   
        FLOAT
                .al
                ; move the frog with the NPC
                CLC
                LDA PLAYER_X
                ADC game_array,X
                CMP #54-PADDING      ; added a fuzzy buffer
                BCC W_COLLISION
                CMP #640-22+PADDING  ; added a fuzzy buffer
                BCS W_COLLISION
                
                STA PLAYER_X
                STA SP00_X_POS_L
                RTS
               
       H_COLLISION
                .al
                setas
                ; show splash sprite at player's location
                LDA #SPLATT_SPRITE * 4
                STA SP00_ADDY_PTR_M
                LDA #1
                STA SP00_ADDY_PTR_H
                JMP SET_DEAD
                
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
                STA @lRESET_BOARD
                RTS
                
; *****************************************************************
; * At the home line, check if the player is aligned with a free nest.
; * If the nest is free, then the player gets a 200 point bonus.
; * If the nest is not free or the player is not aligned, then death occurs.
; *****************************************************************
        HOME_LINE
                .al
                LDA PLAYER_X
                LDX #1        ; nest state
                LDY #6*2      ; the first draw tile
                CMP #62+32
                BLT H_COLLISION
                CMP #97+32
                BLT HOME_CHECK_VALID
                
                LDX #2        ; nest state
                LDY #13*2     ; the first draw tile
                CMP #174+32
                BLT H_COLLISION
                CMP #210+32
                BLT HOME_CHECK_VALID
                
                LDX #4        ; nest state
                LDY #20*2     ; the first draw tile
                CMP #286+32
                BLT H_COLLISION
                CMP #322+32
                BLT HOME_CHECK_VALID

                LDX #8        ; nest state
                LDY #27*2     ; the first draw tile
                CMP #398+32
                BLT H_COLLISION
                CMP #434+32
                BLT HOME_CHECK_VALID

                LDX #$10      ; nest state
                LDY #34*2     ; the first draw tile
                CMP #510+32
                BLT H_COLLISION
                CMP #546+32
                BGE H_COLLISION
                
        HOME_CHECK_VALID
                setas
                TXA
                AND #$1F
                BIT HOME_NEST
                BEQ HOME_NO_COLLISION_BRANCH
                JMP H_COLLISION
        HOME_NO_COLLISION_BRANCH
                ORA HOME_NEST
                STA HOME_NEST
                
                ; check if the bee is present
                TXA
                AND #$1F
                BIT BEE_NEST
                BEQ ADD_50_ONLY
                
                ; Display the BONUS SCORE where the frog was located
                LDA #BONUS_SPRITE * 4
                STA @lSP00_ADDY_PTR_M
                LDA #1
                STA SP00_ADDY_PTR_H
                
                ; add 200 to score
                setal
                SED
                CLC
                LDA SCORE
                ADC #$200
                STA SCORE
                BRA SCR_CONTINUE
                
                
       ADD_50_ONLY
                setal
                SED
                CLC
                LDA SCORE
                ADC #$50
                STA SCORE
                
      SCR_CONTINUE
                BCC HL_MULTIPLY_TIMER
                
                ; the carry was set, so increase the hi-byte
                setas
                CLC
                LDA SCORE + 2
                ADC #1
                STA SCORE + 2
                setal
                
        HL_MULTIPLY_TIMER
                ; prepare X to be the multiplier
                LDA GTIMER
                AND #$FF
                TAX
        
                ; multiply the number of seconds remaining by 10
                LDA SCORE
        HL_MULTIPLY_LOOP
                CLC
                ADC #$10
                STA SCORE
                BCC HL_MULT_LP_END

                setas  ; there was a carry, so add 1 to the hi byte
                CLC
                LDA SCORE + 2
                ADC #1
                STA SCORE + 2
                setal
                LDA #0 ; the thousands have rolled over, so set A to 0.

        HL_MULT_LP_END
                DEX
                BNE HL_MULTIPLY_LOOP
        
                CLD
    
                LDA #0
                
                setas
                ; pause the display for three seconds!
                LDA #THREE_SECS
                STA RESET_BOARD
                
                LDA #1         ; flag that the player has nested and the position needs to be reset
                STA NEST_UP
                
                TYX
                
                ; Place a big frog in the nest - this location is no longer available.
                LDA #30
                STA VTILE_MAP1 + 6 * 40 , X
                LDA #31
                STA VTILE_MAP1 + 6 * 40 + 2, X
                LDA #46
                STA VTILE_MAP1 + 8 * 40, X
                LDA #47
                STA VTILE_MAP1 + 8 * 40 + 2, X
                
                ; set the crown here and restart the player on the first line
                JSR SHOW_SCORE_BOARD
                
                RTS
            
; *****************************************************************
; * Make the lilly pads turn
; *****************************************************************
LILLY_CYCLE     .byte 0

; find all the lillies in the game array and make them rotate
UPDATE_LILLY
                .as
                ; alternate the HOME tiles to imitate wind motion
                LDA @l LILLY_CYCLE
                INC A
                CMP #10 ; only update every N SOF cycle
                BNE UL_SKIP
                LDA #0
                STA @l LILLY_CYCLE
                
                PHP
                setdbr `<game_array
                ; skip the road NPC sprites
                LDX #NPC_SPRITES / 2 * 8
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
                CMP #LILLYPAD+8
                BNE STORE_LILLY
                LDA #LILLYPAD
                
        STORE_LILLY
                STA game_array + 6,X
                ASL A
                ASL A
                STA SP04_ADDY_PTR_M,X
                
        UP_LI_SKIP_ROW
                setal
                TXA
                CLC
                ADC #8
                TAX
                setas
                INY
                CPY #NPC_SPRITES/2
                BNE UP_LI_CHECK
                PLB
                RTS
                
        UL_SKIP
                STA @l LILLY_CYCLE
                RTS

; *****************************************************************
; * Make the turtles swim
; *****************************************************************
TURTLE_CYCLE    .byte 0

; find all the turtles in the game array and make them swim
UPDATE_TURTLE
                .as
                ; alternate the HOME tiles to imitate wind motion
                LDA @l TURTLE_CYCLE
                INC A
                CMP #10 ; only update every N SOF cycle
                BNE UT_SKIP
                LDA #0
                STA @l TURTLE_CYCLE
                
                LDX #NPC_SPRITES / 2 * 8
                LDY #0
        UP_TTL_CHECK
                LDA @l game_array,X
                BEQ UP_TTL_SKIP_ROW
                
                LDA @l game_array + 6,X
                BIT #TURTLE1
                BEQ UP_TTL_SKIP_ROW
                CMP #TURTLE4 + 1
                BGE UP_TTL_SKIP_ROW
                
                INC A
                CMP #TURTLE4+1
                BNE STORE_TURTLE
                LDA #TURTLE1
                
        STORE_TURTLE
                STA @l game_array + 6,X
                ASL A
                ASL A
                STA @l SP04_ADDY_PTR_M,X
                
        UP_TTL_SKIP_ROW
                setal
                TXA
                CLC
                ADC #8
                TAX
                setas
                INY
                CPY #NPC_SPRITES
                BNE UP_TTL_CHECK
                
                RTS
                
        UT_SKIP
                STA @l TURTLE_CYCLE
                RTS
                
; *****************************************************************
; * Write a Hex Value to the position specified by Y
; * Y contains the screen position
; * A contains the value to display
; *****************************************************************
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

; *****************************************************************
; * Display the number of lives remaining
; * Display the current player score
; * Display the high score
; *****************************************************************
SHOW_SCORE_BOARD 
                .as
                PHB
                setdbr <`VTILE_MAP1
                LDA #0
                LDX #0
                LDY #12 ; clear the 6 tiles
        HEART_CLEAR_LOOP
                STA VTILE_MAP1 + (40+2)*2,X ; descending loop offset by 1
                INX
                DEY
                BNE HEART_CLEAR_LOOP
                
                ; now draw the hearts
                XBA
                LDA LIVES
                BEQ SSB_SCORE
                ASL A
                TAX
        SHOW_HEART
                LDA #TILE_HEART
                STA VTILE_MAP1 + (40+2)*2,X
                DEX
                DEX
                BNE SHOW_HEART
                
                ; draw the score - each byte is 2 digits BCD 00 to 99
                ; not really elegant...
        SSB_SCORE
                LDA SCORE + 2 ; the high byte
                LSR ; get the high nibble
                LSR A
                LSR A
                LSR A
                CLC 
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 146
               
                LDA SCORE + 2 ; the low nibble
                AND #$F
                CLC
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 148
                
                LDA SCORE + 1 ; the high byte
                LSR ; get the high nibble
                LSR A
                LSR A
                LSR A
                CLC 
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 150
               
                LDA SCORE + 1 ; the low nibble
                AND #$F
                CLC
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 152
                
                LDA SCORE
                LSR ; get the high nibble
                LSR A
                LSR A
                LSR A
                CLC 
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 154
                
                LDA SCORE ; the low nibble
                AND #$F
                CLC
                ADC #TILE_0 ; tiles are offset at 20
                STA VTILE_MAP1 + 156
                
                PLB
                RTS
                
; *****************************************************************
; * Display the level
; *****************************************************************
SHOW_LEVEL
                .as
                PHB
                setdbr <`VTILE_MAP1
                ; clear the level display - 32 bytes
                LDA #0
                LDY #32
                LDX #0
        SSB_LEVEL_CLR
                STA VTILE_MAP1 + (29*40+3)*2, X
                INX
                DEY
                BNE SSB_LEVEL_CLR
                
                ; display the level at the bottom of the display
                ; the maximum is 16
                XBA
                LDA LEVEL
                AND #$F ; mask to 16
                ASL A
                TAX
                LDA #LEVEL_FROG
        SSB_LEVEL
                STA VTILE_MAP1 + (29*40+2)*2, X
                DEX
                DEX
                BNE SSB_LEVEL
                
                ; clear the nest positions
                LDY #5
                LDX #6*2
        SSB_ERASE_NEST
                LDA #5
                STA VTILE_MAP1 + 6 * 40 , X
                LDA #4
                STA VTILE_MAP1 + 6 * 40 + 2, X
                LDA #8
                STA VTILE_MAP1 + 8 * 40, X
                LDA #9
                STA VTILE_MAP1 + 8 * 40 + 2, X
                TXA
                ADC #14
                TAX
                DEY
                BNE SSB_ERASE_NEST
                
                
                PLB
                RTS

; *****************************************************************
; * The player has 50 seconds to get to the nest.
; * Each tile signifies 4 seconds.  
; * PBAR_1 is 4
; * PBAR_2 is 3
; * PBAR_3 is 2
; * PBAR_4 is 1
; * TILE_0 is 0
; * When the time gets below 10 seconds, use the red progress bar.
; *****************************************************************
UPDATE_TIMER_BAR
                .as
                PHB
                setdbr <`VTILE_MAP1
                LDA #0
                XBA
                LDA #0
                LDY #26 ; clear the 13 tiles
                LDX #0
                ; clear all the tiles - up to 13
        UTB_CLEAR
                STA VTILE_MAP1 + (29*40+23)*2, X
                INX
                DEY
                BNE UTB_CLEAR
                
                LDA GTIMER
                CMP #11
                BLT RED_PROGRESS
                
                LSR A ; divide by 4 to get the number of full tiles
                LSR A ; this number should never be 0
                TAY
                LDX #26
                LDA #PBAR_1
        UTB_DRAW_PRG
                STA VTILE_MAP1 + (29*40+22)*2, X
                DEX
                DEX
                DEY
                BNE UTB_DRAW_PRG
                
        UTB_DRAW_SUBTILE
                LDA GTIMER
                AND #3  ; remainder of division by 4
                BEQ UTB_BLANK_DONE

                EOR #3  ; flip the bits                
                SEC     ; magic math - two's complement
                ADC #PBAR_1
                
                STA VTILE_MAP1 + (29*40+22)*2, X
        UTB_BLANK_DONE
                PLB
                RTS
                
                
    RED_PROGRESS
                LSR A
                LSR A  ; divide by 4 to get the number of full tiles
                BEQ DRAW_RED_SUBTILE
                TAY
                LDX #26
                LDA #RBAR_1
    UTB_DRAW_RED_PRG
                STA VTILE_MAP1 + (29*40+22)*2, X
                DEX
                DEX
                DEY
                BNE UTB_DRAW_RED_PRG
    DRAW_RED_SUBTILE
                LDA GTIMER
                AND #3  ; remainder of division by 4
                BEQ UTB_BLANK_DONE

                EOR #3  ; flip the bits                
                SEC     ; magic math - two's complement
                ADC #RBAR_1
                STA VTILE_MAP1 + (29*40+22)*2, X
                
                PLB
                RTS

; *****************************************************************
; * Load sprites and tiles into Video RAM
; *****************************************************************
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
                LDA #256 * 80 ; four rows of tiles
                MVN <`TILES,<`VTILE_SET0

                ; load LUT0
                LDX #<>PALETTE_TILES
                LDY #<>GRPH_LUT0_PTR
                LDA #1024
                MVN <`PALETTE_TILES,<`GRPH_LUT0_PTR
                
                ; copy game-over tilemap to video RAM
                LDX #<>game_over_board
                LDY #<>VTILE_MAP0
                LDA #40*30*2
                MVN <`game_over_board,<`VTILE_MAP0
                                
                ; copy game board tilemap to video RAM
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
                
                ; copy turtles
                LDX #<>TURTLE
                LDY #<>VTURTLE
                LDA #4 * 32 * 32      ; 4 k
                MVN <`TURTLE,<`VTURTLE
                
                setas
                PLB
                
                RTS

J_TABLE
                .byte 0
                .byte 1
                .byte 2
                .byte 4
                .byte $8
                .byte $10
                .byte 0
                .byte 0
X_TABLE         .word 0
                .word $70
                .word $e0
                .word $150
                .word $1c0
                .word $230
; *****************************************************************
; * Every time the timer gets to zero the bee moves to a new nest.
; *****************************************************************
; random value between 0 and 5
; 0 - hide
; 1 - 1st nest - X =  $70
; 2 - 2nd nest - X =  $E0
; 3 - 3rd nest - X = $150
; 4 - 4th nest - X = $1C0
; 5 - 5th nest - X = $230
; 6, 7 - hide
CHECK_BEE_TIMER
                .as
                LDA BEE_TIMER
                DEC A
                BEQ CBT_CONTINUE
                
                STA BEE_TIMER
                RTS
                
        CBT_CONTINUE
                LDA #DEFAULT_BEE_TIME
                STA BEE_TIMER
                
                LDA #GABE_RNG_CTRL_EN
                STA GABE_RNG_CTRL
                
                PHB
                setdbr $16 
        
; TEST CODE        
;                LDA #0
;                XBA
;                INC BEE_NEST
;                LDY BEE_NEST
;                TYA
;                ASL A
;                TAY
;                
;                LDA #(SPRITE_Enable | SPRITE_DEPTH0 | SPRITE_LUT0)
;                STA SP02_CONTROL_REG
;                
;                setal
;                LDA X_TABLE,Y
;                STA SP02_X_POS_L
;                setas
;                PLB 
;                RTS
                
        CBT_TRY_AGAIN
                ; display the bee sprite in a random nest
                LDA GABE_RNG_DAT_LO
                
                AND #7
                CMP #6
                BGE CBT_TRY_AGAIN
                CMP #0
                BEQ CBT_TRY_AGAIN
                
                TAY
                LDA J_TABLE,Y
                BIT HOME_NEST     ; the bee should not appear if the nest is already full
                BNE CBT_TRY_AGAIN
                STA BEE_NEST
                
                TYA
                ASL A
                TAY
                setal
                LDA X_TABLE,Y
                STA @l SP02_X_POS_L
                setas
                
                LDA #(SPRITE_Enable | SPRITE_DEPTH0 | SPRITE_LUT0)
                STA @l SP02_CONTROL_REG
                
                BRA CBT_DONE
                
    CBT_HIDE
                LDA #0
                STA BEE_NEST
                STA @l SP02_CONTROL_REG  ; hide the bee
    CBT_DONE
                PLB
                RTS
                
DRAW_GAME_OVER_MAP
                .as
                .databank 0
                ; enable tilemap 0
                LDA #TILE_Enable + 0 ; the 0 is there to signify LUT0
                STA @lTL0_CONTROL_REG
                
                ; disable tilemap 1
                LDA #0
                STA @lTL1_CONTROL_REG
                
                LDA #2
                STA GAME_OVER  ; signify that the tilemap is loaded
                
                ; disable sprites
                LDA #Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_TileMap_En; + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L
                
                RTS