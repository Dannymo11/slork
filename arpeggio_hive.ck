// CHANGE to 1.0
0 => global float RANDOMNESS;
0 => global int EXPLOSION;
0 => int arpeggioId;
if ( me.args() )
{
  me.arg(0) => Std.atoi => arpeggioId;
}
// Special ID for all stations
100 => int all;

<<< "HIVE id", arpeggioId >>>;

Shred listenArpeggiateSh;
Shred listenRandomnessSh;
Shred sweepSh;
Shred trackArpParamsSh;
Shred glitchArpSh;
Shred listenArpeggiateExplosionSh;
Shred listenGainSh;

// Droplet patch
// Delay delays[pluck.size()];
SoundFiles soundfiles;
NRev revs;
LPF lp;
SndBuf buf[soundfiles.pluck.size()];
global Gain dropGain;
global Gain distortionGain;
Gen17 distortion;
ADSR adsr;
// CHANGE THIS BACK TO 0
0 => dropGain.gain;


// Set subtle distortion coefficients
//[1.0, 0.02, 0.1, 0.05, 0.025, 0.0125, 0.006] => distortion.coefs;

// Match each wave file patch to each buf
// TODO: set up a bufs in each hive station
for (int i; i < soundfiles.pluck.size(); i++) {
    buf[i] => dropGain => distortionGain => lp => revs => dac;
    //.75 => delays[i].gain;
    //.75::second => delays[i].max => delays[i].delay;
    soundfiles.pluck[i] => buf[i].read;
    0.001 => buf[i].gain;
    <<< soundfiles.pluck[i], "loaded" >>>;
}
// CHANGE THIS BACK TO 0
0.01 => revs.mix;

20000 => float freq;
freq => lp.freq;
4 => lp.Q;
800 => global int lpfLow; // Lowest LPF freq will get
//adsr.set(  20::ms, 10::ms, .95, 100::ms );
spork ~ sweep() @=> sweepSh;
fun void sweep()
{
  1500 => float lpFreqFullSweep; // will be changed with function. this value is meaningless
  1500 => float lpFreqDefault; // lpf when RANDOMNESS is 0
  10 => int scaleFactor; // Higher values mean more non-linearity
  15000 => int lpfHigh; // Highest LPF freq will get
  0.6 => float rateParam;

  while( true )
  {
    // Generate a periodic value that changes non-linearly
    (Math.sin(now/second * rateParam) + 1) / 2 => float periodic; // 0 - 1

    // Apply an exponential function to skew the periodic value
    Math.pow(scaleFactor, periodic * (Math.log10(lpfHigh/lpfLow)) / (Math.log10(scaleFactor))) * lpfLow => lp.freq;
    // advance time
    //<<<lp.freq()>>>;
    10::ms => now;
  }
}


<<< "INSTRUCTIONS" >>>;
<<< "When conductor points at you, raise both hands and then drop them. \n Press your button after each time you play. \n When conductor raises both hands, play until he lowers them. \n After this final chord, lower the GameTrak to a middle position." >>>;

fun void listenArpeggiate()
{
  OscIn oin;
  OscMsg msg;
  7777 => oin.port;
  oin.addAddress( "/arpeggiate, i i" );
  while ( true )
  {
    oin => now;

    while ( oin.recv( msg ) )
    {
      if ( msg.getInt(0) == all || msg.getInt(0) == arpeggioId )
      {
         <<< "About to play ", msg.getInt(1) >>>;
        spork ~ play( msg.getInt(1) );
      }
    }
  }
} 
spork ~ listenArpeggiate() @=> listenArpeggiateSh;


fun void listenRandomness()
{
  OscIn oin;
  OscMsg msg;
  7777 => oin.port;
  oin.addAddress( "/randomness, f" );
  while ( true )
  {
    oin => now;

    while ( oin.recv( msg ) )
    {
      msg.getFloat(0) => RANDOMNESS;
    }
  }
} spork ~ listenRandomness() @=> listenRandomnessSh;

fun void listenExplosion()
{

  OscIn oin;
  OscMsg msg;
  7777 => oin.port;
  oin.addAddress( "/explosion, i i" );
  while ( true )
  {
    oin => now;

    while ( oin.recv( msg ) )
    {
      if ( msg.getInt(0) == -1)
      {
        <<< "EXPLOSION TIME " >>>;
        //listenArpeggiateSh.exit();
        1 => EXPLOSION;
        Machine.remove(listenRandomnessSh.id());
        2000 => lpfLow;
        <<< "Exiting Randomness" >>>;
        //Machine.remove(sweepSh.id());
        //<<< "Exiting Sweep" >>>;
        //Machine.remove(trackArpParamsSh.id());

        <<< "Exiting Glitch" >>>;
        Machine.remove(glitchArpSh.id());
        // spork ~ listenArpeggiateExplosion() @=> listenArpeggiateExplosionSh;
        // TODO: switch controls
        // spork ~ granular
      }
      else if (msg.getInt(0) == -9)
      {
        <<< "Starting piece" >>>;
        // spork ~ listenArpeggiate() @=> listenArpeggiateSh;
        // spork ~ listenRandomness() @=> listenRandomnessSh;  
        // spork ~ sweep() @=> sweepSh;
        // spork ~ trackArpParams() @=> trackArpParamsSh;
        // spork ~ glitchArp() @=> glitchArpSh;
        // listenGainSh.exit();
        // listenArpeggiateExplosionSh.exit();
      }
    }
  }
} 

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

spork ~ listenExplosion();

fun play( int i )
{
    buf[i].pos(0);
    buf[i].play();
    // 0.0 => buf[i].gain;
}

//  -------------------------------Keyboard and GameTrak setup -------------------------------
Hid hi;
HidMsg msg;
0 => int DEADZONE;
0 => int GAME_TRAK_DEVICE;
Hid trak;
HidMsg msgTrak;
//
if( !trak.openJoystick( GAME_TRAK_DEVICE ) ) me.exit();
<<< "joystick '" + trak.name() + "' ready", "" >>>;

// gametrack
GameTrak gt;

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
                    { 
                        msg.axisPosition => gt.axis[msg.which]; 
                    }
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

0.0 => float currentReverb;
0.0 => float targetReverb;

// Start the gametrak handling function
spork ~ gametrak();

fun void trackArpParams()
{
    while (true)
    {
        if (EXPLOSION == 0) {
          mapAxis2RangeExponential(gt.axis[2], 0.0, 1.0, 0.0, 0.15) => targetGain;
          // Map another axis (e.g., axis[5]) to the target reverb mix with exponential mapping
          mapAxis2RangeExponential(gt.axis[5], 0.0, 1.0, 0.0, 0.4) => targetReverb;
          // Smoothly update the current reverb mix towards the target reverb mix
          currentReverb + (targetReverb - currentReverb) * smoothingFactor => currentReverb;
        }
        // Map the Z-axis value to the target gain with exponential mapping
        //CHANGED GAIN
        else if (EXPLOSION == 1) {
          mapAxis2RangeExponential(gt.axis[2], 0.0, 1.0, 0.0, 0.35) => targetGain;
          0.01 => currentReverb;
        }        
        // Smoothly update the current gain towards the target gain
        currentGain + (targetGain - currentGain) * smoothingFactor => currentGain;
        
        // Set the gain of the drop
        currentGain => dropGain.gain;
      
        // Set the reverb mix
        currentReverb => revs.mix;

        // Print for debugging purposes
        // <<< "Current Gain:", currentGain, "Current Reverb:", currentReverb >>>;
        
        20::ms => now;
    }
}
spork ~ trackArpParams() @=> trackArpParamsSh;



fun void glitchArp()
{

  while (true)
  {
      Math.randomf() * RANDOMNESS * RANDOMNESS / 10 => float newDistortion; 
      if (newDistortion < 0.01)
      {
          0.01 => newDistortion;
      } else if (newDistortion > 0.3) 
      {
          0.3 => newDistortion;
      }
      //<<< "newDistortion", newDistortion >>>;
      newDistortion => distortionGain.gain;
      50::ms => now;
  }
}
spork ~ glitchArp() @=> glitchArpSh;


while (true) {
    50::ms => now;
}