//
//  AppDelegate.m
//  OSXDemo
//
//  Created by Jakob Penca on 14/03/14.
//  Copyright (c) 2014 Jakob Penca. All rights reserved.
//

#import "AppDelegate.h"
#import "MDMachinedrumPublic.h"

#define kA4ConnectedString @"A4 Connected"
#define kA4DisconnectedString @"A4 Not Connected"

@interface AppDelegate() <PGMidiDelegate, MidiInputDelegate>
@property (weak) IBOutlet NSButton *loadSoundButton;
@property (weak) IBOutlet NSTextField *connectionStatusLabel;
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// First call to [MDMIDI sharedInstane] initializes MIDI
	// this is the main MIDI controller, e.g. manages autoconnect for Analog Four / Keys & TM-1
	[MDMIDI sharedInstance];
	
	// add self as observer to be notified of connection changes via PGMidiDelegate protocol
	[[MDMIDI sharedInstance] addObserverForMidiConnectionEvents:self];
	
	// check if the A4 is connected
	BOOL a4Connected = [[MDMIDI sharedInstance] a4MidiSource] != nil;
	[self.connectionStatusLabel setStringValue: a4Connected ? kA4ConnectedString : kA4DisconnectedString];
	[self.loadSoundButton setEnabled:a4Connected];
}

- (IBAction)handleLoadSoundButton:(id)sender
{
	// this example demonstrates a powerful usage pattern which provides the backbone of this framework.
	
	// in the example, we randomly pick a sound from the sound pool and copy it into the
	// current kit's selected track.
	// we use the settings object to see which track is selected.
	// to do this, we request the current kit, current settings, and a random sound from the A4.
	// then we copy the sound into the kit and send the modified kit back to the A4.
	
	
	
	// A4 requests take an array of specially formatted NSString keys as argument;
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
	// for the sounds in the current kit, you have to specify which track sound you want.
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

- (void)midiSourceAdded:(PGMidiSource *)source
{
	if(source == [[MDMIDI sharedInstance] a4MidiSource])
	{
		// handle connection established
		[self.connectionStatusLabel setStringValue:kA4ConnectedString];
		[self.loadSoundButton setEnabled:YES];
	}
}

- (void)midiSourceRemoved:(PGMidiSource *)source
{
	if(source == [[MDMIDI sharedInstance] a4MidiSource])
	{
		// handle connection loss
		[self.connectionStatusLabel setStringValue:kA4DisconnectedString];
		[self.loadSoundButton setEnabled:NO];
	}
}


@end
