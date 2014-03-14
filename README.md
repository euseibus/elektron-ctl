## elektron-ctl

Programmatic access to the Elektron Machinedrum & Analog Four.

1. [Installation](#installation)
2. [Demo](#demo)

### Installation

Drag and drop the elektron-ctl project into your app's project inside Xcode.

In your app's target Build Phases:

Add the elektron-ctl-iOS-or-Mac library as a target dependency.

Link your app target with the following frameworks:

- CoreMIDI.framework
- AVFoundation.framework
- AudioToolbox.framework
- libelektron-ctl-iOS-or-Mac.a

Add the .payload files in elektron-ctl/A4/Resources group to your target's Copy Bundle Resources build phase.

In your Build Settings:

Add the framework folder containing the MDMachinedrumPublic.h file to your project's header search paths, or user header search paths.

In your code:

import MDMachinedrumPublic.h where you want to use the framework.

### Demo

There is a simple example project for OSX, demonstrating basic usage of bidirectional SysEx communication with the Analog Four: 

``` Objective-C

- (IBAction)handleLoadSoundButton:(id)sender
{
	// this example demonstrates the request/send mechanism for A4 sysex objects.
	
	// in the example, we randomly pick a sound from the sound pool and copy it into the
	// current kit's selected track.
	// we use the settings object to see which track is selected.
	// to do this, we request the current kit, current settings, and a random sound from the A4.
	// then we copy the sound into the kit and send the modified kit back to the A4.
	
	
	
	// Requests take an array of specially formatted NSString keys as argument;
	// the keys are in the format:
	//     type.slot
	//
	// type is a 3-letter acronym of the user data type: pat, kit, snd, set, glo, son
	// slot is the position in the A4 project, starting form 0;
	// there are 128 patterns, 128 kits, 128 sounds, 4 globals, 1 settings, several songs.
	//
	// you can also request the current unsaved buffers of these structures
	// by passing .x as the slot.
	// e.g. pat.x will request the current pattern.
	// for sounds in the current kit, you have to specify which track sound you want.
	// e.g. snd.x.1 will fetch the sound in track 2.
	//
	
	
	// requests are handled in a global FIFO queue.
	// they conveniently handle fetch operations in the background and always return on the main thread.
	// so it's safe to update the UI from the completion/error handlers.
	
	// user data from the A4 is unpacked from the incoming sysex data, and stuffed into a wrapper
	// for easy editing.
	
	// sending data is very easy too.
	// if you want to send a thing to a specific slot, use e.g.:
	// kit.position = 123; [kit send];
	// to send the thing to the active unsaved buffer, use e.g. [kit sendTemp];
	
	
	
	NSString *randomSoundKey = [NSString stringWithFormat:@"snd.%d", (int)mdmath_randi(0, 127)];
	NSString *currentKitKey = @"kit.x";
	NSString *currentSettingsKey = @"set.x";
	
	[A4Request requestWithKeys:@[randomSoundKey, currentKitKey, currentSettingsKey]
			 completionHandler:^(NSDictionary *dict) {
				
				 A4Settings *settings = dict[currentSettingsKey];
				
				 // show a user alert if the current track is not a synth track
				 
				 if(settings.selectedTrackParams > 3)
				 {
					 NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid track"
													  defaultButton:@"Dismiss" alternateButton:nil otherButton:nil
										  informativeTextWithFormat:@"Select a synth track on your A4"];
					 
					 [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
						
						 [self.loadSoundButton setEnabled:[[MDMIDI sharedInstance] a4MidiSource] != nil];
						 return;
						 
					 }];
				 }
				 
				 
				 A4Sound *sound = dict[randomSoundKey];
				 A4Kit *kit = dict[currentKitKey];
				 
				 [kit copySound:sound toTrack:settings.selectedTrackParams];
				 [kit sendTemp];
				 
				 
				 [self.loadSoundButton setEnabled:[[MDMIDI sharedInstance] a4MidiSource] != nil];
				 
			 } errorHandler:^(NSError *err) {
				 
				 NSAlert *alert = [NSAlert alertWithMessageText:@"Error"
												  defaultButton:@"Dismiss" alternateButton:nil otherButton:nil
									  informativeTextWithFormat:@"%@", err.description];
				 
				 [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
					 
					 [self.loadSoundButton setEnabled:[[MDMIDI sharedInstance] a4MidiSource] != nil];
					 return;
					 
				 }];
				 
			 }];
}