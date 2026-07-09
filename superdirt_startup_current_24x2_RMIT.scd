/*
This is HE startup file for the 24x2 multichannel setup at RMIT (using Dante Virtual Sound Card)
*/

(
s.reboot { // server options are only updated on reboot
    // configure the sound server: here you could add hardware specific options
    // see http://doc.sccode.org/Classes/ServerOptions.html

	s.options.numBuffers = 1024 * 256; // increase this if you need to load more samples
	s.options.numAudioBusChannels = 8192;
	s.options.numOutputBusChannels = 26;
	s.options.numInputBusChannels = 0;

	s.options.memSize = 8192 * 256;
	s.options.maxNodes = 32768;
	s.options.numWireBufs = 1024;

    // boot the server and start SuperDirt
    s.waitForBoot {
        ~dirt = SuperDirt(26, s); // two output channels, increase if you want to pan across more channels
        ~dirt.loadSoundFiles;   // load samples (path containing a wildcard can be passed in)
        ~dirt.loadSoundFiles("/Users/E131046/projects/tidal/samples-extra/*");
        s.sync; // optionally: wait for samples to be read
        ~dirt.start(57120, 0 ! 12);   // start listening on port 57120, create two busses each sending audio to channel 0

        // optional, needed for convenient access from sclang:
        (
            ~d1 = ~dirt.orbits[0]; ~d2 = ~dirt.orbits[1]; ~d3 = ~dirt.orbits[2];
            ~d4 = ~dirt.orbits[3]; ~d5 = ~dirt.orbits[4]; ~d6 = ~dirt.orbits[5];
            ~d7 = ~dirt.orbits[6]; ~d8 = ~dirt.orbits[7]; ~d9 = ~dirt.orbits[8];
            ~d10 = ~dirt.orbits[9]; ~d11 = ~dirt.orbits[10]; ~d12 = ~dirt.orbits[11];


		// Initialize the SuperDirtMixer
        ~mixer = SuperDirtMixer(~dirt);

        // You can adjust parameters before you use the ui
        ~mixer.setMasterBus(1);

        // When you added your settings in you startup file, then you should be able to use the ui at any time in any differtent SuperCollider file.
        ~mixer.gui;
        );
    };

    s.latency = 2.5; // increase this if you get "late" messages



};
);