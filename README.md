# Fraggy
Fraggy is a Frogger-like game for the C256 Foenix Retro Computer: https://c256foenix.com/

![Screenshot](https://github.com/dtremblay/fraggy/blob/master/fraggy.png)

The game runs on the machine and the Foenix IDE: https://github.com/Trinity-11/FoenixIDE

Release 6
---------
Updated the look of the tiles and sprites.
Tightened up the controls.
Added a timer bar.
Added code to display a big frog in the nest once the player has arrived.
Account for all the populated nest and increase the level when all nests are full.
Added scoring.

Release 3
---------
Added tile cycling for the home and water tiles.  This gives the game a more dynamic look.

Release 2
---------
Added collisions and floating on lilypads and logs.
Added home.
Added logs, antique car and lilypad.
Loading the sprites from the same file as the tiles: this reduces the amount of memory used. 
This also makes it easier to build sprites in one single sheet.

Release 1
---------
Multiple sprites (cars and buses) moving at differents speeds.
Worked out a few issues that result in tearing at the edges.
The frog moves in steps of 32 x 32.

Release 0
---------
This is the start of a very simple game.  I have a set of tiles and one generated sprite.
The joystick0 port is supported as well as the ASWD keys. The repeat rate on the keyboard is slower than SOF, so the object doesn't move as fast.
