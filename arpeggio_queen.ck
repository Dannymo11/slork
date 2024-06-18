// Learning
// Final Slork Piece - Danny Mottesi

// Full List of Sounds
[
"pluck/C.aif",
"pluck/D.aif",
"pluck/E.aif",
"pluck/F.aif",
"pluck/G.aif",
"pluck/Ab.aif", 
"pluck/A.aif", 
"pluck/B.aif",
"pluck/C2.aif", 
"pluck/D2.aif",
"pluck/E2.aif",
"pluck/F2.aif",
"pluck/G2.aif",
"pluck/Ab2.aif",
"pluck/A2.aif", 
"pluck/B2.aif",
"pluck/C3.aif", 
"pluck/C-1.aif", 
"pluck/D-1.aif",
"pluck/Eb-1.aif",
"pluck/E-1.aif",
"pluck/F-1.aif",
"pluck/G-1.aif",
"pluck/Ab-1.aif",
"pluck/A-1.aif", 
"pluck/B-1.aif",
"pluck/C-1.aif", 
"pluck/C#-1.aif",
"pluck/C#.aif",
"pluck/C#1.aif",
] @=> string files[];

"224.0.0.1" => string hostname;
3 => int hive_size;
if ( me.args() )
{
    me.arg(0) => Std.atoi => hive_size;
    if (me.args() >= 2 && me.arg(2) == "l" )
  {
    <<< "LOCALHOST" >>>;
    "localhost" => hostname;
  }
}
<<< "QUEEN WITH SIZE", hive_size >>>;

7777 => int port;

class GameTrak
{
    time lastTime;
    time currTime;
    
    float lastAxis[6];
    float axis[6];
}
GameTrak gt;
[
    [6, 8, 9, 10], // a,c,d.e
    [5, 8, 9, 10], // ab,c,d,e
    [4, 8, 9, 10], // g,c,d,e
    [3, 8, 9, 10], // f,c,d,e
    [3, 8, 9, 11], // 2 down - f,c,d,f
    [3, 7, 9, 11], // 2 down - f,b,d,f
    [3, 6, 9, 11], // 3 down - f,a,d,f
    [3, 6, 8, 11], // 3 down - f,a,c,f
    [3, 6, 8, 10], // 3 down - f,a,c,e
    [3, 6, 7, 10], //10 4 down - f,a,b,e
    [3, 6, 7, 9],  // 2 down- f,a,b,d
    [3, 5, 7, 9],  // 1 down - f,ab,b,d
    [2, 5, 7, 9], //  e,ab,b,d    
] @=> int arpChords[][];
0 => global int arpIndex;

global int playing;
1 => playing;
global float tempo;
150 => tempo;
0 => global int EXPLOSION;

0.0 => global float RANDOMNESS;

OscOut xmit;
xmit.dest( hostname, port );

fun void sendArpeggiate( int noteIndex, int note )
{
    noteIndex % hive_size => int receiver;
    <<< "Sending /arpeggiate ", note, receiver >>>;
    xmit.start( "/arpeggiate" );
    receiver => xmit.add;
    note => xmit.add;
    xmit.send();
}

//  ----------------------------------------------- ARP-EXLOSHION STUFF ----------------------------------------------------
// First we must increase tempo, switch explosion chords

[
    [24, 0, 3, 6, 8, 11, 14], // A-1, C, F, A, C2, F2, A2 - f
    [24, 1, 3, 6, 9, 11, 14],  // A-1, D, F, A, D2, F2, A2 - d
    [24, 28, 2, 6, 29, 10, 14], //A-1, C#, E, A, C#1, E2, A2 - A
    [24, 0, 2, 6, 8, 10, 14], //A-1, C, E, A, C2, E2, A2 - a
    [24, 0, 2, 6, 8, 11, 14],    //A-1, C, E, A, C2, F2, A2 - Fmaj7
    //[21, 33, 32, 4, 31, 11, 34], //G-1, Bb-1, Eb, G, Eb2 ,F2, Bb2 -> Can switch this to G-1, Bb-1, Eb, G, Bb, Eb2,G2 - Eb Good
    [21, 33, 32, 4, 9, 11, 34], //G-1, Bb-1, Eb, G, D2 ,F2, Bb2 -> Can switch this to G-1, Bb-1, Eb, G, Bb, Eb2,G2 - Eb with 9 and 7
    [21, 0, 2, 4, 10, 12, 16], // G-1, C, E, G, E2 ,G2, C3 -- C
    [24, 28, 2, 4, 10, 12, 14], //A-1, C#, E, G, E2 ,G2, A2 -> Can switch top two notes, or middle G -
    [24, 1, 3, 6, 9, 11, 14], // A-1, D, F, A, D2 ,F2, A2
    //[33, 32, 4, 30, 9, 12, 34], // Bb-1, Eb, G, Bb, D2 ,G2, Bb2 -- Eb
    //[23, 32, 4, 8, 31, 12, 34], // Ab-1, Eb, G, C2, Eb2 ,G2, Bb2 -- Ab

    //[23, 3, 5, 8, 11, 13, 16], // Ab-1, F, Ab, C2, F2 ,Ab2, C3 -- F min
    
    // IDK IF THE C# SOUNDS NATURAL I FEEL LIKE I WAS JUST TRYNA BE JAZZY WHEN I WROTE IT - SWITCHED ORDER, EASY SWITCH BACK
    [23, 3, 5, 29, 11, 13, 16], // MAY NEED TO CHANGE Ab-1, F, Ab, C#2, F2 ,Ab2, C3 -- C#
    [21, 2, 7, 8, 10, 12, 15], // G-1, E, B, C2, E2 ,G2, B2 -- GOOD
    
] @=> int explosionArpChord[][];
0 => global int explosionArpIndex;


// ----------------------------------------------- CHORD STUFF ----------------------------------------------------
["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"] @=> string noteLetters[];
fun string mapMidiToLetter(int midiValue)
{
    return noteLetters[midiValue % 12];
}

[
    [45, 52, 57], // a e a
    [44, 52, 60], // ab e c
    [43, 52, 59], // g e b
    [41, 52, 57], // f e a
    [41, 50, 57], // f d a
    [41, 50, 59], // f d b 
    [45, 50, 60], // a d c
    [45, 53, 60], // a f c
    [45, 52, 60], // a e c
    [41, 52, 59], //10 f e b
    [41, 52, 59], // f e b
    [41, 50, 59], // f d b
    [40, 47, 62], // e b d
    // ...
] @=> int chords[][];
0 => global int chordIndex; // where we are in chord progression

fun void sendChord()
{
    // currently coded up to that chord stations need to be ids 0, 1, 2
    for (int i; i < 3; i++)
    {
        xmit.start( "/note" );
        i => xmit.add; // reciever
        chords[chordIndex][0] => xmit.add;
        chords[chordIndex][1] => xmit.add;
        chords[chordIndex][2] => xmit.add;
        chordIndex => xmit.add;
        xmit.send();
    }
    <<< "current chord:", 
    mapMidiToLetter(chords[chordIndex][0]), 
    mapMidiToLetter(chords[chordIndex][1]), 
    mapMidiToLetter(chords[chordIndex][2])  >>>;
    // no longer need this since we have control in keeb
    // chordIndex++;
}

fun void sendRandomness(float r)
{
    xmit.start( "/randomness" );
    r => xmit.add;
    xmit.send();
}

spork ~ keeb();

fun Main( ) 
{
    sendChord();
    while (true) {
        if (EXPLOSION == 0) 
        {
            arpeggio(arpChords[arpIndex]);
        }
        if (EXPLOSION == 1) 
        {
            //arpeggio(arpChords[arpIndex]);
            arpeggio(explosionArpChord[explosionArpIndex]);
        }
    }
}

fun int getJerk()
{
    0 => int jerk;
    if (RANDOMNESS > 0.5)
    {
        Math.random2(-1, 1) * Math.random2(0, ((RANDOMNESS - 0.5)*300) $ int) => jerk;
    }
    return jerk;
}
// rec controlls receiver for arpeggiator --> Keeps increasing and gets moduloed
0 => global int rec;
fun arpeggio( int current[] ) 
{
    // for (int i; i < current.size(); i++) {
    //     <<< files[current[i]] >>>; 
    // }
    //<<< "\n \n" >>>;
    
    // walk up scale
    for (int i; i < current.size() - 1; i++) {
        sendArpeggiate(rec, current[i]);
        Math.max(tempo + getJerk(), 20)::ms => now;
        rec++;
    }
    // walk down scale
    for (current.size() - 1 => int j; j > 0; j--) {
        // these notes should continue to send to new receivers
        sendArpeggiate(rec, current[j]);
        Math.max(tempo + getJerk(), 20)::ms => now;
        rec++;
    }
}

fun explosionArpeggio( int current[] ) 
{
    [0,2,1,3,2,4,3,5,4,6] @=> int orderIndex[];


    for (int i; i < orderIndex.size() - 1; i++) {
        sendArpeggiate(rec, current[orderIndex[i]]);
        tempo::ms => now;
        rec++;
    }
    for (orderIndex.size() - 1 => int j; j > 0; j--) {
        // these notes should continue to send to new receivers
        sendArpeggiate(rec, current[orderIndex[j]]);
        tempo::ms => now;
        rec++;
    }

}

// ------------------TEMPO SMOOTHING ---------------
Envelope e => blackhole;

5000::ms => e.duration;

0.05 => global float smooth;
fun void updateTempo( float targetTempo ) { 
    // advance time by 500 ms
    // (note: this is the duration from the
    //        beginning of ATTACK to the end of SUSTAIN)
    e.keyOn();
    // key off; start RELEASE
    tempo => e.value;
    targetTempo => e.target;
    while (e.target() != e.value()){
        <<< "value", e.value() >>>;
        <<< "target", e.target() >>>;
        e.value() => tempo;
        100::ms => now;
    }
    targetTempo - tempo => float difference;
    // if (difference > 1 || difference < - 1) {
    //     (difference * smooth) + tempo => tempo;
    //     30::ms => now;
    //     //<<< "Current tempo is", tempo, "\n" >>>;
    //     updateTempo(targetTempo);
    // }
}


fun void upOrDown(int index) 
{
    Hid hi;
    HidMsg msg;
    0 => int device;
    if( !hi.openKeyboard( device ) ) me.exit();
    <<< " Checking up or down ">>>;
    0 => int stepChange; 
    20::ms => now;
    while ( true )
    {
        // wait on event
        hi => now;
        // get one or more messages
        while ( hi.recv( msg ) )
        {
            if( msg.isButtonDown() )
            {
                if (msg.which == 82) {
                    1 +=> stepChange;
                    <<< "Changing by", stepChange, "\n" >>>;
                }
                else if (msg.which == 81) {
                    1 -=> stepChange;
                    <<< "Changing by", stepChange, "\n">>>;
                }
                else if (msg.which == 40) 
                {
                    if (index == 4)
                    {
                        // <<< "In the right spot!" >>> ;
                        // 400::ms => now;
                        // (stepChange * 2000) + lp.freq() => lp.freq;
                        // <<< "Current LPF is", lp.freq() >>>;
                    }
                    else if (index == 5) {
                        updateTempo(tempo - (stepChange * 50));
                        //tempo - (stepChange * 50) => tempo;
                        //<<< "Current tempo is", tempo, "\n" >>>;
                    }
                    me.exit();
                }
            }
        }
    }
}


0 => int explosionGroup1ChordIndex;
0 => int explosionGroup2ChordIndex;

fun void sendExplosionChord(int i1, int i2)
{
    if (i1 == -1)
    {
        // tell hive to transition controls to explosion. Unreversable!
        <<< "KABOOM mofo. It's explosion time" >>>;
    }
    else if (i1 == -9)
    {
        // set up/undo explosion
    }
    xmit.start( "/explosion" );
    i1 => xmit.add;
    i2 => xmit.add;
    xmit.send();

}
0 => global int TWINKLEINDEX;
fun void sendTwinkleChange(int direction) // 1 for progress, -1 for go back
{
    if (direction == 1) <<< "INCREASING twinkle chord index by 1" >>>;
    else if (direction == -1) <<< "DECREASING twinkle chord index by 1" >>>;
    
    for (int i; i < 3; i++)
    {
        xmit.start( "/twinkle" );
        i => xmit.add; // reciever
        direction => xmit.add;
        xmit.send();
    }
}

// TAKE OUT IF DOESN"T WORK
fun void sendGain(float gain){
    xmit.start("/gain");
    gain => xmit.add;
    xmit.send();
}

// How to control Voices, tempo, and LFO
// Clicking 1-4 on the keyboard and then up/down arrown moves those voices
// Clicking 't' and then up/down arrows moves tempo
// Click return to confirm
fun void keeb()
{
    Hid hi;
    HidMsg msg;
    0 => int device;
    if( !hi.openKeyboard( device ) ) me.exit();
    <<< "keyboard '" + hi.name() + "' ready", "" >>>;
    0 => int stepChange; 
    0 => int tab;
    
    Shred arpeggioSporkId;
    while ( true )
    {
        // wait on event
        hi => now;
        
        // get one or more messages
        while ( hi.recv( msg ) )
        {
            if( msg.isButtonDown() )
            {
                // tab begins program 
                if (msg.which == 43) {
                    <<< "TAB" >>>;
                    if (!tab) {
                        <<< "main program starting" >>>;
                        spork ~ Main() @=> arpeggioSporkId;
                        sendExplosionChord(-9, -9); // revert explosion if started accidentally
                        0 => explosionGroup1ChordIndex;
                        1 => tab;
                        0 => EXPLOSION;
                    }
                    else 
                    {
                        <<< "Explosion transition" >>>;
                        1 => EXPLOSION;
                        sendExplosionChord(-1, -1);
                        80 => tempo;
                        0 => tab;
                        //spork ~ arpExplosion();
                        20::ms => now;
                    }
                }
                // else if ( msg.which == 30 )
                // {
                //     <<< "Moving Voice 1 \n" >>>;
                //     spork ~ upOrDown(0);
                //     1000::ms => now;
                // }   
                // Clicking 'Right Arrow' goes to the next chord, 
                // for both chords and arp
                else if (msg.which == 79) 
                {
                    if (chordIndex == chords.size() - 1 || arpIndex == arpChords.size() - 1) {
                        
                        <<< "OUT OF BOUNDS" >>>;

                    }
                    else {
                        arpIndex++;
                        chordIndex++;
                        sendChord();
                        <<< "Current chord is", chordIndex, "Current arp is", arpIndex >>>;
                        if (chordIndex != arpIndex) {
                            <<< "ERROR DIFFERENT INDEXES" >>>;
                        }
                    }
                }
                else if (msg.which == 44) 
                {
                    <<< "ending arpeggio" >>>;
                    arpeggioSporkId.exit();
                    
                }
                else if (msg.which == 80) 
                {
                    if (chordIndex == 0 || arpIndex == 0) {
                        
                        <<< "OUT OF BOUNDS" >>>;

                    }
                    else 
                    {
                        chordIndex--;
                        sendChord();
                        arpIndex--;
                        <<< "Current chord is", chordIndex, "Current arp is", arpIndex >>>;
                        if (chordIndex != arpIndex) 
                        {
                            <<< "ERROR DIFFERENT INDEXES" >>>;
                        }
                    }
                }
                // Clicking 'T' allows tempo toggle
                else if (msg.which == 23) 
                {
                    <<< "Changin tempo \n" >>>;
                    spork ~ upOrDown(5);
                    200::ms => now;
                }
                // EXPLOSION CHORD CONTROL
                else if (msg.which == 225) // Left shift
                {
                    
                    if (explosionArpIndex >= explosionArpChord.size() - 1) {
                        <<< "NO MORE" >>>;
                    }
                    else 
                    {
                        explosionArpIndex + 1 => explosionArpIndex;
                        <<< "Arp index", explosionArpIndex>>>;
                        20::ms => now;
                    }
                    explosionGroup1ChordIndex + 1 => explosionGroup1ChordIndex;
                    <<< "Explosion group 1 index", explosionGroup1ChordIndex >>>;
                    sendExplosionChord(explosionGroup1ChordIndex, explosionGroup2ChordIndex);
                }
                else if (msg.which == 7) // D 
                {
                    if (TWINKLEINDEX == 12) {
                        <<< "LAST CHORD \n" >>>;
                    }
                    else 
                    {
                        sendTwinkleChange(1);
                        TWINKLEINDEX++;
                        <<<"Current TWINKLE index:", TWINKLEINDEX>>>;
                    }
                }
                else if (msg.which == 4) // A
                {
                    if (TWINKLEINDEX == 0) {
                        <<< "YOU CAN'T DO THAT - OUT OF BOUNDS ARRAY \n">>>;
                    }
                    else {
                        sendTwinkleChange(-1);
                        TWINKLEINDEX--; 
                        <<<"Current TWINKLE index:", TWINKLEINDEX>>>;
                    }
                }
            }
        }
    }
}


fun float mapAxis2RangeExponential(float input, float lo, float hi, float outLo, float outHi) {
    // Sanity check
    if (outLo >= outHi) {
        <<< "WARNING: unreasonable output lo/hi range in mapAxis2RangeExponential()" >>>;
        return outLo;
    }
    
    if (lo >= hi) {
        <<< "WARNING: unreasonable input lo/hi range in mapAxis2RangeExponential()" >>>;
        return outLo;
    }
    
    // Clamp input
    if (input < lo) lo => input;
    else if (input > hi) hi => input;
    
    // Normalize input to [0, 1]
    (input - lo) / (hi - lo) => float normalized;
    
    // Apply exponential scaling (e.g., power of 3 for more sensitivity at low end)
    Math.pow(normalized, 3) => float scaled;
    
    // Map to output range
    return outLo + (scaled * (outHi - outLo));
}

// Define smoothing factor (adjust this value to control the smoothness)
0.8 => float smoothingFactor;

// Define the current and target gain values
0.0 => float currentGain;
0.0 => float targetGain;

fun void gametrak()
{
    Hid trak;
    HidMsg msg;
    0 => int device;
    if( !trak.openJoystick( device ) ) me.exit();
    <<< "joystick '" + trak.name() + "' ready", "" >>>;
    
    while( true )
    {
        trak => now;
        
        while( trak.recv( msg ) )
        {
            if( msg.isAxisMotion() )
            {            
                if( msg.which >= 0 && msg.which < 6 )
                {
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        gt.currTime => gt.lastTime;
                        now => gt.currTime;
                    }
                    
                    // save last
                    gt.axis[msg.which] => gt.lastAxis[msg.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msg.which != 2 && msg.which != 5 )
                    { msg.axisPosition => gt.axis[msg.which]; }
                    else
                    {
                        1 - ((msg.axisPosition + 1) / 2) => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                    if (EXPLOSION == 0) {
                        gt.axis[2] => RANDOMNESS;
                        sendRandomness(RANDOMNESS);
                    }
                    else if (EXPLOSION == 1) {
    
                        // // Map the Z-axis value to the target gain with exponential mapping
                        // mapAxis2RangeExponential(gt.axis[2], 0.0, 1.0, 0.0, 0.1) => targetGain;
                        
                        // // Smoothly update the current gain towards the target gain
                        // currentGain + (targetGain - currentGain) * smoothingFactor => currentGain;
                        
                        // // Set the gain of the drop
                        // sendGain(targetGain);
    
                    }
                }
                // joystick button down
                else if( msg.isButtonDown() )
                {
                    <<< "button", msg.which, "down: " >>>;
                }
            }
            20::ms => now; // no need for responsiveness here
        }
    }
} spork ~ gametrak();





while ( true ){
    50::ms => now;
}

