# slork2024
Stanford Laptop Orchestra 2024 project by Daniel Mottesi, Leo Jacoby, and Mattan Abrams. Includes Instruments, OSC messaging, etc.
3 instruments are included. 
1) Arpeggio. Controlled by arpeggio_queen.ck, osc signals are sent to machines running arpeggio_hive.ck. To run, in the terminal type
'arpeggio_queen.ck:NUMBER_OF_HIVES. NUMBER_OF_HIVES should be an int corresponding to the number of machines running 'arpeggio_hive.ck'.
To change chords click the right arrow. To change tempo click 't', click 'up' or 'down' however many times you want (clicking more changes the tempo
more), followed by 'return' to commit the tempo change. To change to faster arpeggios with a new chord progression, click left tab (Also switches 
hives to run granular.ck in run_arpeggio_granular.ck). To switch chords after clicking left tab, click left shift.
Machines desired to have arpeggios playing and control of granular synthesizer should run run_arpeggio_granular.ck.

2) Granular synthesizer. Found in granular.ck this instrument maps the control of a granular synthesis (grain size, grain randomness, grain length, pitch, etc.)
to the controls of a grametrak controller. Can be run alone (granular.ck) or receive messages from arpeggio_queen.ck.

3) Twinkles. A nice bell/dreamy like instrument ran by twinkles.ck and chords.ck. Chords changed by arpeggio_queen.ck.
