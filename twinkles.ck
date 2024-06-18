// -------------------------------------------- CHORD PROGRESSION --------------------------------------------
// C  D  E  F  G  A  B  C
// 60 62 64 65 67 69 71 72
[60, 64, 67, 71, 72] @=> int chord1[]; // C E G B C
[65, 69, 72, 76, 77] @=> int chord2[]; // F A C E F
[60, 64, 71, 72, 79] @=> int chord3[]; // C E B C G
[60, 65, 69, 72, 81] @=> int chord4[]; // C F A C A

[67, 72, 74, 79, 83] @=> int chord5[]; // G C D G B
[69, 76, 81, 83, 88] @=> int chord6[]; // A E A B E
[67, 74, 79, 81, 86] @=> int chord7[]; // G D G A D
[62, 69, 74, 78, 86] @=> int chord8[]; // D A D F# D
[65, 70, 74, 77, 84] @=> int chord9[]; // F A# D F C

[68, 75, 79, 80, 87] @=> int chord10[]; // G# D# G G# D#
[61, 70, 72, 73, 82] @=> int chord11[]; // C# A# C C# A#
[63, 70, 73, 84, 82] @=> int chord12[]; // D# A# C# D# A#
[68, 75, 79, 80, 87] @=> int chord13[]; // G# D# G G# D#

[chord1, chord2, chord3, chord4, chord5, chord6, chord7, chord8,
chord9, chord10, chord11, chord12, chord13] @=> int chordProgression[][]; 
/* [60, 64, 67] @=> int oldChord1[];
[65, 69, 72] @=> int oldChord2[];
[oldChord1, oldChord2] @=> int chordProgression[][]; */

// -------------------------------------------- VARIABLES --------------------------------------------
6 => int NUM_CHANNELS;
2::second => dur twinkleFadeTime;
75::ms => dur interval;
4::second => dur chordDur;
1 => float timeFactor;
1 => float baseGain;
0 => int chordProgressionIdx;

float timeBetweenTwinkles;
150 => float randomnessFactor;
75 => float minTimeBtwnTwinkles;
1800 => float maxTimeBtwnTwinkles;

float lpfFreq;
100 => float minFreq;
20000 => float maxFreq;

100 => int all;
int myId;
if (me.args()) me.arg(0) => Std.atoi => myId;

// -------------------------------------------- SOUND/SETUP --------------------------------------------
Echo echos[NUM_CHANNELS];
ADSR envs[NUM_CHANNELS];
TwoPole filters[NUM_CHANNELS];
LPF lpfs[NUM_CHANNELS];
JCRev revs[NUM_CHANNELS];
fun void setup()
{
    for (int i; i < NUM_CHANNELS; i++)
    {
        echos[i] => filters[i] => envs[i] => lpfs[i] => revs[i] => dac.chan(i);

        echos[i].delay(10::ms);

        1 => filters[i].a1;
        .5 => filters[i].a2;
        .8 => filters[i].b0;

        25::ms => envs[i].attackTime;
        50::ms => envs[i].decayTime;
        .4 => envs[i].sustainLevel;
        75::ms => envs[i].releaseTime;

        7 => lpfs[i].Q;

        .1 => revs[i].mix; 

        envs[i].keyOn();
    }
} setup();

// -------------------------------------------- GAMETRAK --------------------------------------------
0 => int device;
0 => int DEADZONE;
Hid trak;
HidMsg msgTrak;

if( !trak.openJoystick( device ) ) me.exit();
<<< "joystick '" + trak.name() + "' ready", "" >>>;

// data structure for gametrak
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
                /* chordProgressionIdx++;
                chordProgressionIdx % chordProgression.size() => chordProgressionIdx;
                <<< "switching chord index to", chordProgressionIdx >>>; */
                <<< "button", msgTrak.which, "down" >>>;
            }
            
            // joystick button up
            else if( msgTrak.isButtonUp() )
            {
                <<< "button", msgTrak.which, "up" >>>;
            }
        }
    }
} 
spork ~ gametrak();

fun float mapToGainSigmoid(float p, float thresh)
{
    6 => float steepness;
    if (p < thresh) return 0;
    else 
    {
        (p - thresh) / (1 - thresh) => float normalized;
        return 1 / (1 + Math.exp(-steepness * (normalized - .4)));
    }
}

fun float mapToFrequencySigmoid(float p)
{
    7 => float steepness;
    
    1 / (1 + Math.exp(-steepness * p)) => float sigmoidValue;
    minFreq + sigmoidValue * (maxFreq - minFreq) => float freq;
    return Math.max(minFreq, Math.min(maxFreq, freq));
}

fun float mapToFrequencySmooth(float p)
{
    .25 => float threshold;
    (p + 1) / 2 => float normalized;
    float smoothed;
    if (p <= threshold)
    {
        normalized / (threshold + 1) => float logNorm;
        Math.log10(1 + 9 * logNorm) / Math.log10(10) => smoothed;
    }
    else
    {
        3 * Math.pow(normalized, 2) - 2 * Math.pow(normalized, 3) => smoothed;
    }
    minFreq + smoothed * (maxFreq - minFreq) => float freq;
    return Math.max(minFreq, Math.min(maxFreq, freq));
}

fun float mapToFrequencyNew(float p)
{
    maxFreq - minFreq => float k;
    Math.fabs(k * Math.pow(p, 3)) => float adjustedP;
    minFreq + adjustedP => float freq;
    return Math.max(minFreq, Math.min(maxFreq, freq));
}

fun void trackTwinkleParams()
{
    .05 => float gainThresh;
    while (true)
    {
        gt.axis[2] => float zLeft;
        mapToGainSigmoid(zLeft, gainThresh) => baseGain;

        gt.axis[3] => float xRight;
        mapToFrequencyNew(xRight) => lpfFreq;
        //<<< "lpf Freq", lpfFreq >>>;

        gt.axis[5] => float zRight;
        calculateTimeBetweenTwinkles(zRight) => timeBetweenTwinkles;

        10::ms => now;
    }
} spork ~ trackTwinkleParams();

fun void setTwinkleParams()
{
    while (true)
    {
        for (int i; i < NUM_CHANNELS; i++)
        {
            lpfs[i].freq(lpfFreq);
        }
        20::ms => now;
    }
} spork ~ setTwinkleParams();


// -------------------------------------------- TWINKLES --------------------------------------------
fun float calculateTimeBetweenTwinkles(float p)
{
    3 => float exp;
    1 - Math.pow(1 - p, exp) => float adjustedP;
    maxTimeBtwnTwinkles - (adjustedP * (maxTimeBtwnTwinkles - minTimeBtwnTwinkles)) => float baseTime;
    baseTime + Math.random2f(-1, 1) * randomnessFactor => float finalTime;
    return Math.max(minTimeBtwnTwinkles, Math.min(maxTimeBtwnTwinkles, finalTime));
}

fun void twinkle(int midiNote, int n)
{
    SinOsc osc => echos[n];
    osc.gain(baseGain);

    Std.mtof(midiNote) => float baseFreq;
    baseFreq => osc.freq;
    
    baseGain / (twinkleFadeTime / interval) => float gainDecrement;
    while (osc.gain() > .01)
    {
        osc.gain() - gainDecrement => osc.gain;
        interval => now;
    }
}

fun void twinkles()
{
    int n;
    while (true)
    {
        chordProgression[chordProgressionIdx][Math.random2(0, 4)] => int midiNote;

        if (chordProgressionIdx == chordProgression.size() - 1)
        {
            Math.random2f(0, 1) => float p;
            Math.random2(0, 1) => int x;
            int offset;
            if (p <= .2) 
            {
                spork ~ twinkle(midiNote, n);
            }
            if (p > .2 && p <= .4) 
            {
                spork ~ twinkle(midiNote, n);
                n++;
                NUM_CHANNELS %=> n;
                
                if (x == 0) 12 => offset;
                else -12 => offset;
                spork ~ twinkle(midiNote + offset, n);
            }
            if (p > .4 && p <= .6) 
            {
                spork ~ twinkle(midiNote, n);
                n++;
                NUM_CHANNELS %=> n;
                spork ~ twinkle(midiNote - 7, n);
            }
            if (p > .6 && p <= .8) 
            {
                spork ~ twinkle(midiNote, n);
                n++;
                NUM_CHANNELS %=> n;
                spork ~ twinkle(midiNote + 7, n);
            }
            if (p > .8) 
            {
                spork ~ twinkle(midiNote, n);
                n++;
                NUM_CHANNELS %=> n;
                if (x == 0) -5 => offset;
                else 5 => offset;
                spork ~ twinkle(midiNote + offset, n);
            }                       
        }
        else spork ~ twinkle(midiNote, n);
        
        n++;
        NUM_CHANNELS %=> n;

        timeBetweenTwinkles::ms => now;
    } 
}

fun void oldTwinkles()
{
    int n;
    while (true)
    {
        now + chordDur => time later;
        while (now < later)
        {
            for (int i; i < chordProgression.size(); i++)
            {
                chordProgression[i][Math.random2(0, chordProgression[i].size() - 1)] => int midiNote;
                Math.random2f(0, 1) => float p;
                Math.random2(0, 1) => int x;
                int offset;
                if (p <= .2) 
                {
                    spork ~ twinkle(midiNote, n);
                }
                if (p > .2 && p <= .4) 
                {
                    spork ~ twinkle(midiNote, n);
                    n++;
                    NUM_CHANNELS %=> n;
                    
                    if (x == 0) 12 => offset;
                    else -12 => offset;
                    spork ~ twinkle(midiNote + offset, n);
                }
                if (p > .4 && p <= .6) 
                {
                    spork ~ twinkle(midiNote, n);
                    n++;
                    NUM_CHANNELS %=> n;
                    spork ~ twinkle(midiNote - 7, n);
                }
                if (p > .6 && p <= .8) 
                {
                    spork ~ twinkle(midiNote, n);
                    n++;
                    NUM_CHANNELS %=> n;
                    spork ~ twinkle(midiNote + 7, n);
                }
                if (p > .8) 
                {
                    spork ~ twinkle(midiNote, n);
                    n++;
                    NUM_CHANNELS %=> n;
                    if (x == 0) -5 => offset;
                    else 5 => offset;
                    spork ~ twinkle(midiNote + offset, n);
                }
                n++;
                NUM_CHANNELS %=> n;

                timeBetweenTwinkles::ms => now;
            }
        }
    }
}

// -------------------------------------------- OSC --------------------------------------------
fun listenChordChange()
{
	<<< "LISTENING FOR ID", myId >>>;

	OscIn oin;
	OscMsg msg;
	7777 => oin.port;
	oin.addAddress( "/twinkle, i i" );

	while ( true )
	{
		oin => now;
		while ( oin.recv( msg ) )
		{
			if ( msg.getInt(0) == all || msg.getInt(0) == myId )
			{
				chordProgressionIdx + msg.getInt(1) => chordProgressionIdx;
                if (chordProgressionIdx < 0) 0 => chordProgressionIdx;
                chordProgressionIdx % chordProgression.size() => chordProgressionIdx;
                <<< "SWITCHING CHORD INDEX TO:", chordProgressionIdx >>>;
			}
		}
	}
} spork ~ listenChordChange();

// -------------------------------------------- MAIN LOOP --------------------------------------------
spork ~ twinkles();
while (true)
{
    <<< "ON CHORD", chordProgressionIdx + 1, "OUT OF 13" >>>;
    10::ms => now;
}
