//
//  MachineDrum.m
//  sysexingApp
//
//  Created by Jakob Penca on 5/19/12.
//
//

#import "MDMachineDrum.h"
#import "MDMachinedrumGlobalSettings.h"
#import "MDSysexUtil.h"
#import "MDKit.h"
#import "MidiInputParser.h"

#define kTempoChanged @"tempoChanged"
#define kSetCurrentKitName @"setCurrentKitName"
#define kSysexMDPrefix @"f000203c0200"
#define kSysexEnd @"f7"

@interface MDMachineDrum()
- (NSData *)tempoMessageData;
- (NSData *)currentKitMessageData;
- (NSData *)saveKitMessageDataWithSlot:(NSUInteger) num;
- (NSData *)loadPatternMessageDataWithSlot:(NSUInteger)num;
- (NSData *)loadKitMessageDataWithSlot:(NSUInteger)num;
@end

@implementation MDMachineDrum

- (id) init
{
	if(self = [super init])
	{
		
	}
	return self;
}

- (void)loadMachine:(MDMachineID)machineID intoTrack:(uint8_t)trackIndex
{
	if(trackIndex > 15) return;
	trackIndex &= 0x0F;
	
	//DLog(@"machineID: %d", machineID);
	
	uint8_t uw = (machineID & 0x80) >> 7;
	machineID &= 0x7f;
	uint8_t init = 0;
	
	//DLog(@"message params: track: %d, machineID: %d, UW: %d, init: %d", trackIndex, machineID, uw, init);
		
	uint8_t bytes[] = {0x5b, trackIndex, machineID, uw, init};
	
	
	NSMutableData *d = [NSMutableData data];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[d appendBytes:bytes length:5];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	if(self.delegate)
		[self.delegate machineDrum:self wantsToSendSysExData:d];
}

- (NSData *)currentKitMessageData
{
	char nameBytes[16] = {};
	NSUInteger len = self.currentKitName.length;
	
	for (int i = 0; i < len; i++)
	{
		nameBytes[i] = [self.currentKitName characterAtIndex:i] & 0x7f;
	}
	
	NSMutableData *data = [[NSMutableData alloc] init];
	
	[data appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[data appendData:[MDSysexUtil dataFromHexString:@"55"]];
	[data appendData: [NSData dataWithBytes:nameBytes length:16]];
	[data appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	return data;
}


- (NSData *)tempoMessageData
{
	NSString *tempoID = @"61";
	
	int tempoMultiplied = self.tempo * 24;
	
	char tempoBytes[2] = {};
	tempoBytes[0] = (tempoMultiplied >> 7) & 0x7f;
	tempoBytes[1] = tempoMultiplied & 0x7f;
	
	NSData *tempoData = [NSData dataWithBytes:&tempoBytes length:2];
	NSMutableData *data = [[NSMutableData alloc] init];
	
	[data appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[data appendData:[MDSysexUtil dataFromHexString:tempoID]];
	[data appendData: tempoData];
	[data appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	return data;
}

- (NSData *)saveKitMessageDataWithSlot:(NSUInteger)num
{
	if(num > 63) num = 63;
	
	NSString *saveKitID = @"59";
	char slotByte = num & 0x6f;
	
	NSData *slotData = [NSData dataWithBytes:&slotByte length:1];
	
	NSMutableData *msgData = [NSMutableData new];
	
	
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[msgData appendData:[MDSysexUtil dataFromHexString:saveKitID]];
	[msgData appendData:slotData];
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	return msgData;
}

- (NSData *)loadPatternMessageDataWithSlot:(NSUInteger)num
{
	if(num > 127) num = 127;
	
	NSString *loadPatternID = @"57";
	char slotByte = num & 0x7f;
	
	NSData *slotData = [NSData dataWithBytes:&slotByte length:1];
	
	NSMutableData *msgData = [NSMutableData new];
	
	
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[msgData appendData:[MDSysexUtil dataFromHexString:loadPatternID]];
	[msgData appendData:slotData];
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	return msgData;

}

- (NSData *)loadKitMessageDataWithSlot:(NSUInteger)num
{
	if(num > 63) num = 63;
	
	NSString *loadKitID = @"58";
	char slotByte = num & 0x3f;
	
	NSData *slotData = [NSData dataWithBytes:&slotByte length:1];
	
	NSMutableData *msgData = [NSMutableData new];
	
	
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[msgData appendData:[MDSysexUtil dataFromHexString:loadKitID]];
	[msgData appendData:slotData];
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	return msgData;

}

- (NSData *)loadSongMessageDataWithSlot:(NSUInteger)num
{
	if(num > 31) num = 31;
	
	NSString *loadSongID = @"6c";
	char slotByte = num & 0x3f;
	
	NSData *slotData = [NSData dataWithBytes:&slotByte length:1];
	
	NSMutableData *msgData = [NSMutableData new];
	
	
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[msgData appendData:[MDSysexUtil dataFromHexString:loadSongID]];
	[msgData appendData:slotData];
	[msgData appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	return msgData;
	
}



- (void)saveCurrentKitToSlot:(NSUInteger)num
{
	if(self.delegate)
		[self.delegate machineDrum:self
			  wantsToSendSysExData:[self saveKitMessageDataWithSlot:num]];
}

- (void)loadPattern:(NSUInteger)num
{
	if(self.delegate)
		[self.delegate machineDrum:self
			  wantsToSendSysExData:[self loadPatternMessageDataWithSlot:num]];

}

- (void)loadKit:(NSUInteger)num
{
	if(self.delegate)
		[self.delegate machineDrum:self
			  wantsToSendSysExData:[self loadKitMessageDataWithSlot:num]];
}

- (void)loadSong:(NSUInteger)num
{
	if(self.delegate)
		[self.delegate machineDrum:self
			  wantsToSendSysExData:[self loadSongMessageDataWithSlot:num]];
}

- (void)requestKitDumpForSlot:(uint8_t)num
{
	[self requestDumpOfType:0x53 slot:num];
}

- (void)requestPatternDumpForSlot:(uint8_t)num
{
	[self requestDumpOfType:0x68 slot:num];
}

- (void)requestSongDumpForSlot:(uint8_t)num
{
	[self requestDumpOfType:0x6a slot:num];
}

- (void)requestGlobalSettingsDumpForSlot:(uint8_t)num
{
	[self requestDumpOfType:0x51 slot:num];
}

- (void)requestCurrentKitNumber
{
	[self requestStatus:0x02];
}

- (void)requestCurrentGlobalSettingsSlot
{
	[self requestStatus:0x01];
}

- (void)requestCurrentPatternNumber
{
	[self requestStatus:0x04];
}

- (void)requestCurrentSongNumber
{
	[self requestStatus:0x08];
}


- (void) requestStatus:(uint8_t) statusID
{
	char slotByte = statusID;
	NSData *slotData = [NSData dataWithBytes:&slotByte length:1];
	NSMutableData *data = [NSMutableData new];
	
	[data appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[data appendData:[MDSysexUtil dataFromHexString:@"70"]];
	[data appendData:slotData];
	[data appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	if(self.delegate)
		[self.delegate machineDrum:self wantsToSendSysExData:data];
}

- (void) requestDumpOfType:(uint8_t)dumpType slot:(uint8_t)slot
{
	char typeByte = dumpType & 0x7f;
	char slotByte = slot & 0x7f;
	
	NSMutableData *d = [NSMutableData data];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[d appendBytes:&typeByte length:1];
	[d appendBytes:&slotByte length:1];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	if(self.delegate)
		[self.delegate machineDrum:self wantsToSendSysExData:d];
}



- (void)sendPattern:(MDPattern *)pattern
{
	DLog(@"preparing to send pattern.");
	NSData *d = [pattern sysexData];
	if(d)
	{
		DLog(@"sending.");
		[self.delegate machineDrum:self wantsToSendSysExData:d];
	}
}

- (void)sendGlobalSettings:(MDMachinedrumGlobalSettings *)settings
{
	NSData *d = [settings sysexData];
	if(d) [self.delegate machineDrum:self wantsToSendSysExData:d];
}

- (void)setSampleName:(NSString *)name atSlot:(NSUInteger)slot
{
	char sampleRenameID = 0x73;
	char slotByte = slot & 0x7f;
	
	while (name.length < 4)
	{
		name = [name stringByAppendingString:@" "];
	}
	
	const char *nameChars = [[name substringToIndex:4] cStringUsingEncoding:NSASCIIStringEncoding];
	
	NSMutableData *d = [NSMutableData data];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[d appendBytes:&sampleRenameID length:1];
	[d appendBytes:&slotByte length:1];
	[d appendBytes:nameChars length:4];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	
	if(self.delegate)
		[self.delegate machineDrum:self wantsToSendSysExData:d];

}

- (void)routeTrack:(uint8_t)channel toOutput:(MDOutput)output
{
	if(channel > 15) return;
	channel &= 0x0F;
	const char messageID = 0x5C;
	const char outputByte = output;
	
	NSMutableData *d = [NSMutableData data];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexMDPrefix]];
	[d appendBytes:&messageID length:1];
	[d appendBytes:&channel length:1];
	[d appendBytes:&outputByte length:1];
	[d appendData:[MDSysexUtil dataFromHexString:kSysexEnd]];
	if(self.delegate)
		[self.delegate machineDrum:self wantsToSendSysExData:d];
}


static uint8_t masterEffectsMessage[] = {0xf0, 0x00, 0x20, 0x3c, 0x02, 0x00, 0x00, 0x00, 0x00, 0xf7};

- (void)setMasterEffect:(MDMasterEffectId)masterEffectID param:(uint8_t)param value:(uint8_t)value
{
	param = param % 8;
	value &= 0x7f;
	
	masterEffectsMessage[6] = (uint8_t) masterEffectID;
	masterEffectsMessage[7] = param;
	masterEffectsMessage[8] = value;
	
	NSData *d = [NSData dataWithBytes: &masterEffectsMessage length:10];
	if(self.delegate)
		[self.delegate machineDrum:self wantsToSendSysExData:d];
}
static uint8_t LFOMessage[] = {0xf0, 0x00, 0x20, 0x3c, 0x02, 0x00, 0x62, 0x00, 0x00, 0xf7};

- (void)setLFOAtTrack:(uint8_t)track param:(uint8_t)param value:(uint8_t)value
{
	param = param % 8;
	value &= 0x7f;
	uint8_t byte = ((track & 0xf) << 3) | (param & 0x7);
	LFOMessage[7] = byte; /// TODO: TEST THIS!!!!!!
	LFOMessage[8] = value & 0x7f;
	
	NSData *d = [NSData dataWithBytes: &LFOMessage length:10];
	if(self.delegate)
		[self.delegate machineDrum:self wantsToSendSysExData:d];
}


@end
