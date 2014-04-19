//
//  MDPatternSequencer.m
//  yolo
//
//  Created by Jakob Penca on 7/14/13.
//
//

#import "MDPatternSequencer.h"

@interface MDPatternSequencer()<MidiInputDelegate>
@property NSUInteger step;
@end

@implementation MDPatternSequencer

static MDPatternSequencer *instance = nil;
+ (id)sharedInstance
{
	if(instance == nil)
	{
		instance = [self new];
	}
	return instance;
}

- (id)init
{
	if(self = [super init])
	{
		[[MDMIDI sharedInstance] addObserverForMidiInputParserEvents:self];
	}
	return self;
}

-(void)midiReceivedClockFromSource:(PGMidiSource *)source
{
	if(source == [[MDMIDI sharedInstance] machinedrumMidiSource])
	{
		[self tick];
	}
}

- (void)midiReceivedTransport:(uint8_t)transport fromSource:(PGMidiSource *)source
{
	if(source == [[MDMIDI sharedInstance] machinedrumMidiSource])
	{
		if(transport == MD_MIDI_RT_CONTINUE)
		{
			[self continue];
		}
		else if(transport == MD_MIDI_RT_START)
		{
			[self start];
		}
		else if(transport == MD_MIDI_RT_STOP)
		{
			[self stop];
		}
	}
}

- (void) midiReceivedNoteOn:(MidiNoteOn)noteOn fromSource:(PGMidiSource *)source{}
- (void) midiReceivedNoteOff:(MidiNoteOff)noteOff fromSource:(PGMidiSource *)source{}
- (void) midiReceivedControlChange:(MidiControlChange)controlChange fromSource:(PGMidiSource *)source{}
- (void) midiReceivedProgramChange:(MidiProgramChange)programChange fromSource:(PGMidiSource *)source{}
- (void) midiReceivedAftertouch:(MidiAftertouch)aftertouch fromSource:(PGMidiSource *)source{}
- (void) midiReceivedPitchWheel:(MidiPitchWheel)pw fromSource:(PGMidiSource *)source{}
- (void) midiReceivedSysexData:(NSData *)sysexdata fromSource:(PGMidiSource *)source{}

- (void) continue
{
	self.playing = YES;
	self.currentTickInPattern -= self.currentTickInPattern%6;
}

- (void)start
{
	self.currentTickInPattern = 0;
	self.step = 0;
	self.playing = YES;
}

- (void) stop
{
	self.playing = NO;
}

static double lastTime = 0;
static NSUInteger pLen = 16;

- (void)setPattern:(MDPattern *)pattern
{
	_pattern = pattern;
	pLen = pattern.length;
	if(_pattern == nil) pLen = 16;
}

- (void)tick
{
	if(self.playing)
	{
		if((self.currentTickInPattern+1) % 6 == 0)
		{
			[self.delegate patternSequencer:self willAdvanceToStep:self.step];
		}
		if(self.currentTickInPattern % 6 == 0)
		{
			[self.delegate patternSequencer:self didAdvanceToStep:self.step];
			
			self.step++;
			
			if(self.step >= pLen)
			{
				self.step -= pLen;
			}
		}
		
		[self.delegate patternSequencerDidTick:self];
		
		self.currentTickInPattern++;
		if(self.currentTickInPattern > pLen*24)
		{
			self.currentTickInPattern -= pLen*24;
		}
	}
	
	double time = CACurrentMediaTime();
	_timeIntervalBetweenClocks = time - lastTime;
	lastTime = time;
}

@end
