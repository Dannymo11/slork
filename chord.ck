// -------------------------------------------- VARIABLES --------------------------------------------
0 => int GAME_TRAK_DEVICE;
0 => int myId;
0 => int voiceIndex;
0 => int DEADZONE;
3 => int NUM_VOICES;
6 => int NUM_CHANNELS;

float gainValue;
float bend;
1 => float MAX_PITCH_DEV;
false => int addedTwinkles;
0 => int chordProgressionIdx;

if ( me.args() )
{
  	me.arg(0) => Std.atoi => myId;
    myId => voiceIndex;
}
// Special ID for all stations
100 => int all;

// -------------------------------------------- CONNECTIONS --------------------------------------------
Hid trak;
HidMsg msgTrak;

if( !trak.openJoystick( GAME_TRAK_DEVICE ) ) me.exit();
<<< "joystick '" + trak.name() + "' ready", "" >>>;

//-------------------------------------------- SOUND/SETUP --------------------------------------------
Saxofony saxes[NUM_VOICES];
Chorus chors[NUM_CHANNELS];
Gain gains[NUM_CHANNELS];

OnePole filter[NUM_CHANNELS];
NRev reverb[NUM_CHANNELS];
int baseNotes[NUM_VOICES];

// connect sounds and set values
fun void setup()
{
    for (int i; i < NUM_CHANNELS; i++)
    {
        i%NUM_VOICES => int saxIdx;
        saxes[saxIdx] => chors[i] => gains[i] => filter[i] => reverb[i] => dac.chan(i);

        .2 => reverb[i].mix;

        10.0::ms => chors[i].baseDelay;
        .4 => chors[i].modDepth;
        1 => chors[i].modFreq;
        .2 => chors[i].mix;

        .5 => filter[i].a1;
        .2 => filter[i].b0;

        0 => gains[i].gain;

        .6 => saxes[saxIdx].stiffness;
        .6 => saxes[saxIdx].aperture;
        .5 => saxes[saxIdx].noiseGain;
        .6 => saxes[saxIdx].blowPosition;
        1 => saxes[saxIdx].vibratoFreq;
        .5 => saxes[saxIdx].vibratoGain;
        .8 => saxes[saxIdx].pressure;
        .8 => saxes[saxIdx].noteOn;
    }

    // set initial note values
    if (myId == 0)
    {
        saxes[0].freq(Std.mtof(45 - 12));
        saxes[1].freq(Std.mtof(45));
        saxes[2].freq(Std.mtof(45 + 12));

        45 - 12 => baseNotes[0];
        45 => baseNotes[1];
        45 + 12 => baseNotes[2];
    }
    else if (myId == 1)
    {
        saxes[0].freq(Std.mtof(52 - 12));
        saxes[1].freq(Std.mtof(52));
        saxes[2].freq(Std.mtof(52 + 12));

        52 - 12 => baseNotes[0];
        52 => baseNotes[1];
        52 + 12 => baseNotes[2];
    }
    else if (myId == 2)
    {
        saxes[0].freq(Std.mtof(57 - 12));
        saxes[1].freq(Std.mtof(57));
        saxes[2].freq(Std.mtof(57 + 12));

        57 - 12 => baseNotes[0];
        57 => baseNotes[1];
        57 + 12 => baseNotes[2];
    }
} 
setup();

//-------------------------------------------- GAMETRAK MAPPING --------------------------------------------
class GameTrak
{
    // timestamps
    time lastTime;
    time currTime;
    
    // previous axis data
    float lastAxis[6];
    // current axis data
    float axis[6];
}

// gametrack
GameTrak gt;
fun void gametrak()
{
    while( true )
    {
        // wait on HidIn as event
        trak => now;
        
        // messages received
        while( trak.recv( msgTrak ) )
        {
            // joystick axis motion
            if( msgTrak.isAxisMotion() )
            {            
                // check which
                if( msgTrak.which >= 0 && msgTrak.which < 6 )
                {
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    // save last
                    gt.axis[msgTrak.which] => gt.lastAxis[msgTrak.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msgTrak.which != 2 && msgTrak.which != 5 )
                    { msgTrak.axisPosition => gt.axis[msgTrak.which]; }
                    else
                    {
                        1 - ((msgTrak.axisPosition + 1) / 2) - DEADZONE => gt.axis[msgTrak.which];
                        if( gt.axis[msgTrak.which] < 0 ) 0 => gt.axis[msgTrak.which];
                    }
                }
            }
            
            // joystick button down
            else if( msgTrak.isButtonDown())
            {
                // turn off chords and start twinkles file
                
                if (!addedTwinkles)
                {
                    <<< "--------- TRANSITIONING TO TWINKLES ---------" >>>;
                    me.dir() + "twinkles.ck:" + Std.itoa(myId)  => string twinklesFilePath;
                    for (int i; i < NUM_CHANNELS; i++)
                    {
                        i%NUM_VOICES => int saxIdx;
                        0 => gains[i].gain;
                        1 => saxes[saxIdx].noteOff;
                    }
                    Machine.add(twinklesFilePath);
                    true => addedTwinkles;
                }
            }
            
            // joystick button up
            else if( msgTrak.isButtonUp() )
            {

            }
        }
    }
} 
spork ~ gametrak();

fun float mapToBendSin(float p) 
{
    if (chordProgressionIdx < 11) return 0;
    else return MAX_PITCH_DEV * Math.sin(p * Math.pi / 2);
}

fun float mapToGainSigmoid(float p, float thresh)
{
    10 => float steepness;
    if (p < thresh) return 0;
    else 
    {
        (p - thresh) / (1 - thresh) => float normalized;
        return 1 / (1 + Math.exp(-steepness * (normalized - .5)));
    }
}

fun void trackChordParams()
{
    .05 => float gainThresh;
    while (true)
    {
        gt.axis[3] => float xRight;
        mapToBendSin(xRight) => bend;

        gt.axis[2] => float zLeft;
        mapToGainSigmoid(zLeft, gainThresh) => gainValue;

        10::ms => now;
    }
}
spork ~ trackChordParams();

//-------------------------------------------- OSC --------------------------------------------
["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"] @=> string noteLetters[];
fun string mapMidiToLetter(int midiValue)
{
    return noteLetters[midiValue % 12];
}
fun void changeNote(int chord[])
{
	<<< "hive ID", myId, "recieved message" >>>;
	saxes[0].freq(Std.mtof(chord[voiceIndex] - 12));
	saxes[1].freq(Std.mtof(chord[voiceIndex]));
	saxes[2].freq(Std.mtof(chord[voiceIndex] + 12));

	chord[voiceIndex] - 12 => baseNotes[0];
	chord[voiceIndex] => baseNotes[1];
	chord[voiceIndex] + 12 => baseNotes[2];
    <<< "current chord:", mapMidiToLetter(chord[0]), mapMidiToLetter(chord[1]), mapMidiToLetter(chord[2]) >>>;
}

fun listenNoteChange()
{
	<<< "LISTENING FOR ID", myId >>>;

	OscIn oin;
	OscMsg msg;
	7777 => oin.port;
	oin.addAddress( "/note, i i i i i" );

	while ( true )
	{
		oin => now;

		while ( oin.recv( msg ) )
		{
			if ( msg.getInt(0) == all || msg.getInt(0) == myId )
			{
				changeNote([msg.getInt(1), msg.getInt(2), msg.getInt(3)]);
                msg.getInt(4) => chordProgressionIdx;
			}
		}
	}
} spork ~ listenNoteChange();

//-------------------------------------------- MAIN LOOP --------------------------------------------
fun void setChordParams()
{
    while (true)
    {
        for (int i; i < NUM_CHANNELS; i++)
        {
            if (i < 3)
            {
                Std.mtof(baseNotes[i] + bend) => saxes[i].freq;
            }
            gains[i].gain(gainValue);

            20::ms => now;
        }
    }
    
} spork ~ setChordParams();

while (true) 
{
    if (chordProgressionIdx >= 11 && !addedTwinkles)
    {
        <<< "START PITCH BENDING" >>>;
    }
    10::ms => now;
}