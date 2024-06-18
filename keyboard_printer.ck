fun void keeb()
{
    Hid hi;
    HidMsg msg;
    0 => int device;
    if( !hi.openKeyboard( 0 ) ) me.exit();
    <<< "keyboard '" + hi.name() + "' ready", "" >>>;

    while ( true )
    {
        // wait on event
        hi => now;
        
        // get one or more messages
        while ( hi.recv( msg ) )
        {
            if( msg.isButtonDown() )
            {
                <<< msg.which >>>;
            }
        }
    }
}
spork ~ keeb();

while (true)
{
    10::ms => now;
}