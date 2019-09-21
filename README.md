# c256-game

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
