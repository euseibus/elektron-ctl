//
//  PGMidi.h
//  PGMidi
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@class PGMidi;
@class PGMidiSource;
@class PGMidiDestination;
@class MidiInputParser;

typedef struct MidiNoteOn
{
	uint8_t channel, note, velocity;
}
MidiNoteOn;

typedef struct MidiNoteOff
{
	uint8_t channel, note, velocity;
}
MidiNoteOff;

typedef struct MidiControlChange
{
	uint8_t channel, parameter, value;
}
MidiControlChange;


typedef struct MidiProgramChange
{
	uint8_t channel, program;
}
MidiProgramChange;

typedef struct MidiChannelPressure
{
	uint8_t channel, pressure;
}
MidiChannelPressure;

typedef struct MidiAftertouch
{
	uint8_t channel, note, pressure;
}
MidiAftertouch;

typedef struct MidiPitchWheel
{
	uint8_t channel;
	UInt16 pitch;
}
MidiPitchWheel;


@interface NSValue(MidiNoteOn)
+ (instancetype) valueWithMidiNoteOn:(MidiNoteOn)noteOn;
- (MidiNoteOn) midiNoteOnValue;
@end

@implementation NSValue(MidiNoteOn)
+ (instancetype)valueWithMidiNoteOn:(MidiNoteOn)noteOn
{
	return [NSValue valueWithBytes:&noteOn objCType:@encode(MidiNoteOn)];
}

- (MidiNoteOn)midiNoteOnValue
{
	MidiNoteOn noteOn; [self getValue:&noteOn]; return noteOn;
}
@end

























/// Delegate protocol for PGMidi class.
///
///

@protocol PGMidiDelegate <NSObject>
@optional
- (void) midiSourceAdded:(PGMidiSource *)source;
- (void) midiSourceRemoved:(PGMidiSource *)source;
- (void) midiDestinationAdded:(PGMidiDestination *)destination;
- (void) midiDestinationRemoved:(PGMidiDestination *)destination;
- (void) midiDidReset:(PGMidi *)midi;
@end

/// Class for receiving MIDI input from any MIDI device.
///
/// If you intend your app to support iOS 3.x which does not have CoreMIDI
/// support, weak link to the CoreMIDI framework, and only create a
/// PGMidi object if you are running the right version of iOS.
///
/// @see PGMidiDelegate
@interface PGMidi : NSObject
{
    MIDIClientRef      client;
    MIDIPortRef        outputPort;
    MIDIPortRef        inputPort;
    NSMutableArray    *sources, *destinations;
}

@property (nonatomic,weak)  id<PGMidiDelegate> delegate;
@property (nonatomic,readonly) NSUInteger         numberOfConnections;
@property (nonatomic,readonly) NSMutableArray    *sources;
@property (nonatomic,readonly) NSMutableArray    *destinations;


+ (PGMidi *) sharedInstance;
- (void) reset;
- (void) sendBytes:(const UInt8*)bytes size:(UInt32)size;
- (void) sendPacketList:(const MIDIPacketList *)packetList;

#if TARGET_OS_IPHONE
- (void) enableNetwork:(BOOL)enabled;
#endif

@end



/// Represents a source/destination for MIDI data
///
/// @see PGMidiSource
/// @see PGMidiDestination
@interface PGMidiConnection : NSObject
{
    PGMidi                  *_midi;
    MIDIEndpointRef          _endpoint;
    NSString                *_name;
	NSString                *_manufacturer;
	id						_midiProperties;
#if TARGET_OS_IPHONE
	BOOL					_isNetworkSession;
#endif
}
@property (nonatomic,readonly) PGMidi          *midi;
@property (nonatomic,readonly) MIDIEndpointRef  endpoint;
@property (nonatomic,readonly) NSString        *name, *manufacturer;
@property (nonatomic, strong) id				midiProperties;

#if TARGET_OS_IPHONE
@property (nonatomic,readonly) BOOL             isNetworkSession;
#endif
@end


/// Delegate protocol for PGMidiSource class.
/// Adopt this protocol in your object to receive MIDI events
///
/// IMPORTANT NOTE:
/// MIDI input is received from a high priority background thread
///
/// @see PGMidiSource
@protocol PGMidiSourceDelegate

// Raised on main run loop
/// NOTE: Raised on high-priority background thread.
///
/// To do anything UI-ish, you must forward the event to the main runloop
/// (e.g. use performSelectorOnMainThread:withObject:waitUntilDone:)
///
/// Be careful about autoreleasing objects here - there is no NSAutoReleasePool.
///
/// Handle the data like this:
///
///     // for some function HandlePacketData(Byte *data, UInt16 length)
///     const MIDIPacket *packet = &packetList->packet[0];
///     for (int i = 0; i < packetList->numPackets; ++i)
///     {
///         HandlePacketData(packet->data, packet->length);
///         packet = MIDIPacketNext(packet);
///     }
- (void) midiSource:(PGMidiSource*)input midiReceived:(const MIDIPacketList *)packetList;

@end

/// Represents a source of MIDI data identified by CoreMIDI
///
/// @see PGMidiSourceDelegate
@interface PGMidiSource : PGMidiConnection
@property (nonatomic, strong) MidiInputParser *parser;
@property (nonatomic, strong) id<PGMidiSourceDelegate> delegate;
@end

//==============================================================================

/// Represents a destination for MIDI data identified by CoreMIDI
@interface PGMidiDestination : PGMidiConnection
{
}
- (void) sendNoteOn:(MidiNoteOn)noteOn;
- (void) sendNoteOff:(MidiNoteOff)noteOff;
- (void) sendControlChange:(MidiControlChange)cc;
- (void) sendProgramChange:(MidiProgramChange)pc;
- (void) sendPitchWheel:(MidiPitchWheel)pw;
- (void) sendBytes:(const UInt8*)bytes size:(UInt32)size;
- (void) sendPacketList:(const MIDIPacketList *)packetList;
- (void) sendSysexBytes:(const UInt8*)bytes size:(UInt32)size;
- (void) sendSysexData:(NSData *)d;
@end

//==============================================================================

