// 2026 MIDI live setup harte echtzeit based on Faderfox UC4 controller
// this is adapted from https://tidalcycles.org/docs/configuration/MIDIOSC/midi/ as well as from https://userbase.tidalcycles.org/Playback_Controllers.html

// rev 0.1 - 2025-12-06


(
// declare basic variables
var on, off, cc;
var mutes, solos, muteAll, unmuteAll, unsoloAll, hush;
var playbackControl, playbackState;
var osc;

/* -- MIDI Controller Mapping ---------------------------- */
// Edit this section to configure your MIDI controller

// "mutes" and "solos" are each a Dictionary of MIDI numbers -> Pattern IDs

// In this case, C4, D4 & E4 mute patterns d1, d2 & d3
mutes = Dictionary[
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
solos = Dictionary[
	// empty for now
];

// This MIDI note triggers "muteAll"
// In this case, it's set to C5
muteAll = 4;

// This MIDI note triggers "unmuteAll"
// In this case, it's set to D5
unmuteAll = 5;

// This MIDI note triggers "unsoloAll"
// In this case, it's unused
unsoloAll = nil;

// This MIDI note triggers "hush"
// In this case, it's unused
hush = 7;

/* ------------------------------------------------------- */

playbackState = Dictionary[];

union(mutes.values.asSet, solos.values.asSet).do({
	arg item;
	playbackState.put(item, Dictionary[\mute -> false, \solo -> false]);
});

osc = NetAddr.new("127.0.0.1", 6010);

MIDIClient.init;
MIDIIn.connectAll;

on = MIDIFunc.noteOn({ |val, num, chan, src|
    osc.sendMsg("/ctrl", num.asString, val/127);
});

off = MIDIFunc.noteOff({ |val, num, chan, src|
    osc.sendMsg("/ctrl", num.asString, 0);
});

cc = MIDIFunc.cc({ |val, num, chan, src|
    osc.sendMsg("/ctrl", num.asString, val/127);
});

playbackControl = MIDIFunc.noteOn({ |val, num, chan, src|
	var patID, patState;
	if (mutes.at(num) !== nil, {
		patID = mutes.at(num);
		patState = playbackState.at(patID);
		if (patState.trueAt(\mute), {
			osc.sendMsg("/unmute", patID);
			patState.put(\mute, false);
		}, {
			osc.sendMsg("/mute", patID);
			patState.put(\mute, true);
		});
	});

	if (solos.at(num) !== nil, {
		patID = solos.at(num);
		patState = playbackState.at(patID);
		if (patState.trueAt(\solo), {
			osc.sendMsg("/unsolo", patID);
			patState.put(\solo, false);
		}, {
			osc.sendMsg("/solo", patID);
			patState.put(\solo, true);
		});
	});

	if (muteAll == num, {
		osc.sendMsg("/muteAll");
		playbackState.do({
			arg patState;
			patState.put(\mute, true);
		});
	});

	if (unmuteAll == num, {
		osc.sendMsg("/unmuteAll");
		playbackState.do({
			arg patState;
			patState.put(\mute, false);
		});
	});

	if (unsoloAll == num, {
		osc.sendMsg("/unsoloAll");
		playbackState.do({
			arg patState;
			patState.put(\solo, false);
		});
	});

	if (hush == num, {
		osc.sendMsg("/hush");
	});
});




if (~stopMidiToOsc != nil, {
    ~stopMidiToOsc.value;
});

~stopMidiToOsc = {
    on.free;
    off.free;
    cc.free;
};
if (~stopMidiMuteControl != nil, {
	~stopMidiMuteControl.value;
});

~stopMidiMuteControl = {
	playbackControl.free;
};

)

// Evaluate the line below to stop it.
//~stopMidiMuteControl.value;