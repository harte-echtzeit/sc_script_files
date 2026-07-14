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
        ~dirt.loadSoundFiles(".local/share/SuperCollider/downloaded-quarks/Dirt-Samples/*");
        ~dirt.loadSoundFiles("/Users/E131046/projects/tidal/samples-extra/*");
        ~dirt.loadSoundFiles("/home/chrs/projects/audio/samples/*");
		~dirt.loadSoundFiles("/home/chrs/programmierung/audio/tidal/samples-extra/*");
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


(
// declare basic variables
// var on, off, cc;
// var mutes, solos, muteAll, unmuteAll, unsoloAll, hush;
// var playbackControl, playbackState;
// var osc;

/* -- MIDI Controller Mapping ---------------------------- */
// Edit this section to configure your MIDI controller

// "mutes" and "solos" are each a Dictionary of MIDI numbers -> Pattern IDs

// In this case, C4, D4 & E4 mute patterns d1, d2 & d3
~mutes = Dictionary[
	64 -> 1,
	65 -> 2,
	66 -> 3,
	67 -> 4,
	68 -> 5,
	69 -> 6,
	70 -> 7,
	71 -> 8,
	0 -> 9,
	1 -> 10,
	2 -> 11,
	3 -> 12
	];

// In this case, F4, G4 & A4 solo patterns d1, d2 & d3
~solos = Dictionary[
	// empty for now
];

// This MIDI note triggers "muteAll"
// In this case, it's set to C5
~muteAll = 4;

// This MIDI note triggers "unmuteAll"
// In this case, it's set to D5
~unmuteAll = 5;

// This MIDI note triggers "unsoloAll"
// In this case, it's unused
~unsoloAll = nil;

// This MIDI note triggers "hush"
// In this case, it's unused
~hush = 7;

/* ------------------------------------------------------- */

~playbackState = Dictionary[];

union(~mutes.values.asSet, ~solos.values.asSet).do({
	arg item;
	~playbackState.put(item, Dictionary[\mute -> false, \solo -> false]);
});

~osc = NetAddr.new("127.0.0.1", 6010);

MIDIClient.init;
MIDIIn.connectAll;

~on = MIDIFunc.noteOn({ |val, num, chan, src|
    ~osc.sendMsg("/ctrl", num.asString, val/127);
});

~off = MIDIFunc.noteOff({ |val, num, chan, src|
    ~osc.sendMsg("/ctrl", num.asString, 0);
});

~cc = MIDIFunc.cc({ |val, num, chan, src|
    ~osc.sendMsg("/ctrl", num.asString, val/127);
});

~playbackControl = MIDIFunc.noteOn({ |val, num, chan, src|
	var patID, patState;
	if (~mutes.at(num) !== nil, {
		patID = ~mutes.at(num);
		patState = ~playbackState.at(patID);
		if (patState.trueAt(\mute), {
			~osc.sendMsg("/unmute", patID);
			patState.put(\mute, false);
		}, {
			~osc.sendMsg("/mute", patID);
			patState.put(\mute, true);
		});
	});

	if (~solos.at(num) !== nil, {
		patID = ~solos.at(num);
		patState = ~playbackState.at(patID);
		if (patState.trueAt(\solo), {
			~osc.sendMsg("/unsolo", patID);
			patState.put(\solo, false);
		}, {
			~osc.sendMsg("/solo", patID);
			patState.put(\solo, true);
		});
	});

	if (~muteAll == num, {
		~osc.sendMsg("/muteAll");
		~playbackState.do({
			arg patState;
			patState.put(\mute, true);
		});
	});

	if (~unmuteAll == num, {
		~osc.sendMsg("/unmuteAll");
		~playbackState.do({
			arg patState;
			patState.put(\mute, false);
		});
	});

	if (~unsoloAll == num, {
		~osc.sendMsg("/unsoloAll");
		~playbackState.do({
			arg patState;
			patState.put(\solo, false);
		});
	});

	if (~hush == num, {
		~osc.sendMsg("/hush");
	});
});




if (~stopMidiToOsc != nil, {
    ~stopMidiToOsc.value;
});

~stopMidiToOsc = {
    ~on.free;
    ~off.free;
    ~cc.free;
};
if (~stopMidiMuteControl != nil, {
	~stopMidiMuteControl.value;
});

~stopMidiMuteControl = {
	~playbackControl.free;
};

);
