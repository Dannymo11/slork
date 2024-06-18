LPF lpf;
500 => lpf.freq; // Cutoff frequency in Hz

1::ms => dur INTERP_RATE;
0 => float DEADZONE;

// pitch dead zone (right pull)
.2 => float Z_PITCH_DEAD_ZONE_LO;
.8 => float Z_PITCH_DEAD_ZONE_HI;

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

// HID objects
Hid trak;
HidMsg msg;

0 => int device;

// open joystick 0, exit on fail
if( !trak.openJoystick( device ) ) me.exit();

<<< "joystick '" + trak.name() + "' ready", "" >>>;

// gametrack
GameTrak gt;
spork ~ gametrak();

Bowed bow;
JCRev jcRev;
Gain distortionGain;

// Connect the envelope to the Bowed instrument
bow => distortionGain => lpf => jcRev => dac;

NRev nRev => dac;
PRCRev prcRev => dac;

// set wet/dry ratio
2 => float revMix;
revMix => jcRev.mix;
revMix => nRev.mix;
revMix => prcRev.mix;
// start with jcRev
10.0 => jcRev.gain;
10.0 => nRev.gain;
10.0 => prcRev.gain;

// scale
1 => int i;
0 => float bowPressure;

bowPressure => bow.bowPressure;
0.5 => bow.bowPosition;
0.3 => bow.volume;
.8 => bow.noteOn;
0.00 => distortionGain.gain;

Vector3D iFreq;
iFreq.set( 220, 220, 2 );

spork ~ iFreq.interp( INTERP_RATE );

spork ~ apply( INTERP_RATE );

// applying the value
fun void apply( dur T )
{
    while( true )
    {
        // apply
        iFreq.value() => bow.freq;
        // mod
        //c.freq() * .5 => m.freq;
        // mod index
        //c.freq() * .9 => m.gain;
        // gain
        // advance time
        T => now;
    }
}

// map Z axis to an index
fun int mapAxis2Index( float input, float lo, float hi, int numValues )
{
    // sanity check
    if( numValues <= 0 )
    {
        // error
        <<< "WARNING: non-positive numValues in mapAxis2Index()" >>>;
        // done
        return 0;
    }
    
    // sanity check
    if( lo >= hi )
    {
        // error
        <<< "WARNING: unreasonable lo/hi range in mapAxis2Index()" >>>;
        // done
        return 0;
    }
    
    // clamp
    if( input < lo ) lo => input;
    else if( input > hi ) hi => input;
    
    // percentage
    (input - lo) / (hi - lo) => float percent;
    // figure out which
    (percent * numValues) $ int => int index;
    // boundary case
    if( index >= numValues ) numValues-1 => index;
    
    // done
    return index;
}

[ 0, 2, 4, 5, 7, 8, 9, 11 ] @=> int scale[];
// 

while (true)
{
    mapAxis2Index( gt.axis[2], Z_PITCH_DEAD_ZONE_LO, Z_PITCH_DEAD_ZONE_HI, scale.size() ) => int index;
    scale[index] + 60 => Std.mtof => iFreq.goal;
    
    (gt.axis[5] - 0.25) * 1.5 => bowPressure;
    if (bowPressure < 0) 
    {
        0 => bowPressure;
    }
    
    bowPressure => bow.bowPressure;
    
    Math.randomf() * bowPressure * bowPressure / 10 => float newDistortion; 
    if (newDistortion < 0.0)
    {
        0.0 => newDistortion;
    } else if (newDistortion > 0.2) 
    {
        0.2 => newDistortion;
    }
    
    newDistortion => distortionGain.gain;
    Std.fabs(gt.axis[3]) * 1000 + 200 => lpf.freq;
    
    Std.fabs(gt.axis[0]) - 0.25 => float vibratoFreq;
    if (vibratoFreq < 0) 0 => vibratoFreq;
    vibratoFreq => bow.vibratoFreq;
    
    Std.fabs(gt.axis[1]) - 0.25 => float vibratoGain;
    if (vibratoGain < 0) 0 => vibratoGain;
    vibratoFreq => bow.vibratoGain;
    10::ms => now;
}

// gametrack handling
fun void gametrak()
{
    while( true )
    {
        // wait on HidIn as event
        trak => now;
        
        // messages received
        while( trak.recv( msg ) )
        {
            // joystick axis motion
            if( msg.isAxisMotion() )
            {            
                // check which
                if( msg.which >= 0 && msg.which < 6 )
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
                    gt.axis[msg.which] => gt.lastAxis[msg.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msg.which != 2 && msg.which != 5 )
                    { msg.axisPosition => gt.axis[msg.which]; }
                    else
                    {
                        1 - ((msg.axisPosition + 1) / 2) - DEADZONE => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                }
            }
            
            // joystick button down
            else if( msg.isButtonDown())
            {
                
                <<< "button", msg.which, "down" >>>;
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {

                <<< "button", msg.which, "up" >>>;
            }
        }
    }
}
