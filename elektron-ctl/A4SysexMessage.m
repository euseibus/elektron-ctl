//
//  A4SysexMessage.m
//  A4Sysex
//
//  Created by Jakob Penca on 3/28/13.
//  Copyright (c) 2013 Jakob Penca. All rights reserved.
//

#import "A4SysexMessage.h"
#import "MDSysexUtil.h"
#import "MDMIDI.h"

static A4SysexMessageID A4SysexMessageIDConvertToTemp(A4SysexMessageID id)
{
	if(id == A4SysexMessageID_Kit)		return A4SysexMessageID_Kit_X;
	if(id == A4SysexMessageID_Pattern)	return A4SysexMessageID_Pattern_X;
	if(id == A4SysexMessageID_Sound)	return A4SysexMessageID_Sound_X;
	if(id == A4SysexMessageID_Song)		return A4SysexMessageID_Song_X;
	if(id == A4SysexMessageID_Settings) return A4SysexMessageID_Settings_X;
	if(id == A4SysexMessageID_Global)	return A4SysexMessageID_Global_X;
	return id;
}

static A4SysexMessageID A4SysexMessageIDConvertToSave(A4SysexMessageID id)
{
	if(id == A4SysexMessageID_Kit_X)		return A4SysexMessageID_Kit;
	if(id == A4SysexMessageID_Pattern_X)	return A4SysexMessageID_Pattern;
	if(id == A4SysexMessageID_Sound_X)		return A4SysexMessageID_Sound;
	if(id == A4SysexMessageID_Song_X)		return A4SysexMessageID_Song;
	if(id == A4SysexMessageID_Settings_X)	return A4SysexMessageID_Settings;
	if(id == A4SysexMessageID_Global_X)		return A4SysexMessageID_Global;
	return id;
}

@implementation A4SysexMessage

+ (instancetype)messageWithPayloadAddress:(char *)payload
{
	A4SysexMessage *instance = [self new];
	instance.payload = payload;
	instance.ownsPayload = NO;
	return instance;
}

+ (instancetype)messageWithSysexData:(NSData *)data
{
	if([self messageLengthIsValidInSysexData:data]
	   && [self checksumIsValidInSysexData:data])
	{
		A4SysexMessage *instance = [self new];
		
		const char *bytes = data.bytes;
		instance.type = A4SysexMessageIDConvertToSave(bytes[0x06]);
		instance.ownsPayload = YES;
		instance.sysexData = data;
		return instance;
	}
	return nil;
}

- (id)init
{
	if(self = [super init])
	{
		self.version = 1;
		self.revision = 1;
	}
	return self;
}

- (void)clear
{
	if(_payload)
	{
		memset(_payload, 0, self.payloadLength);
	}
}

- (void)setSysexData:(NSData *)data
{
	const char *bytes = data.bytes;
	if(_type != A4SysexMessageIDConvertToSave(bytes[0x06])) return;
	_position = bytes[0x09];
	
		 if(_type == A4SysexMessageID_Sound)	_payloadLength = A4MessagePayloadLengthSound;
	else if(_type == A4SysexMessageID_Kit)		_payloadLength = A4MessagePayloadLengthKit;
	else if(_type == A4SysexMessageID_Pattern)	_payloadLength = A4MessagePayloadLengthPattern;
	else if(_type == A4SysexMessageID_Settings) _payloadLength = A4MessagePayloadLengthSettings;
	else if(_type == A4SysexMessageID_Global)	_payloadLength = A4MessagePayloadLengthGlobal;
	else if(_type == A4SysexMessageID_Song)		_payloadLength = A4MessagePayloadLengthSong;
	
	NSData *packedPayload = [data subdataWithRange:NSMakeRange(0xA, data.length - 0xA - 0x5)];
	NSData *unpackedPayload = [MDSysexUtil dataUnpackedFrom7BitSysexEncoding:packedPayload];
	
	NSAssert1(unpackedPayload.length == _payloadLength, @"nuuu nuhhh", nil);
	
	if(!_payload)
	{
		_payload = malloc(_payloadLength);
		_ownsPayload = YES;
	}
	
	const char *newBytes = unpackedPayload.bytes;
	memcpy(_payload, newBytes, _payloadLength);
}

- (void)setPayload:(char *)payload
{
	if(self.ownsPayload && _payload)
	{
		free(_payload);
	}
	
	_payload = payload;
	if(_payload)
	{
		if(_type == A4SysexMessageID_Sound)			_payloadLength = A4MessagePayloadLengthSound;
		else if(_type == A4SysexMessageID_Kit)		_payloadLength = A4MessagePayloadLengthKit;
		else if(_type == A4SysexMessageID_Pattern)	_payloadLength = A4MessagePayloadLengthPattern;
		else if(_type == A4SysexMessageID_Settings) _payloadLength = A4MessagePayloadLengthSettings;
		else if(_type == A4SysexMessageID_Global)	_payloadLength = A4MessagePayloadLengthGlobal;
		else if(_type == A4SysexMessageID_Song)		_payloadLength = A4MessagePayloadLengthSong;
	}
	else
	{
		_payloadLength = 0;
	}
}


- (NSData *)sysexData
{
	return [self sysexDataWithType:_type position:_position];
}


- (NSData *)sysexDataWithType:(A4SysexMessageID)type position:(uint8_t)pos
{
	static uint8_t A4MessageTransportHead[] = {0xF0, 0x00, 0x20, 0x3C, 0x06, 0x00, 0x00, 0x01, 0x01, 0x00};
	static uint8_t A4MessageTransportTail[] = {0x00, 0x00, 0x00, 0x00, 0xF7};
	
	A4MessageTransportHead[0x06] = type;
	A4MessageTransportHead[0x07] = _version;
	A4MessageTransportHead[0x08] = _revision;
	A4MessageTransportHead[0x09] = pos;
	
	NSMutableData *d = [NSMutableData dataWithBytes:A4MessageTransportHead length:10];
	[d appendData:[MDSysexUtil dataPackedWith7BitSysexEncoding:[NSData dataWithBytes:_payload length:_payloadLength]]];
	[d appendBytes:A4MessageTransportTail length:5];
	
	[[self class] updateChecksumInSysexData:d];
	[[self class] updateMessageLengthInSysexData:d];
	return d;
}

- (NSData *)sysexDataForTempSend
{
	A4SysexMessageID id = A4SysexMessageIDConvertToTemp(_type);
	return [self sysexDataWithType:id position:_position];
}


+ (void) updateChecksumInSysexData:(NSMutableData *)data
{
	uint8_t *bytes = (uint8_t *) data.mutableBytes;
	uint16_t checksum = 0;
	
	NSUInteger checksumStartPos = 0x0a;
	NSUInteger checksumEndPos = data.length - 5;
	
	for (NSUInteger j = checksumStartPos; j < checksumEndPos; j++)
	{
		bytes[j] &= 0x7f;
		checksum += bytes[j];
	}
	checksum &= 0x3fff;
	bytes[checksumEndPos] = checksum >> 7;
	bytes[checksumEndPos + 1] = checksum & 0x7f;
}

+ (BOOL)checksumIsValidInSysexData:(NSData *)data
{
	const uint8_t *bytes = (const uint8_t *) data.bytes;
	uint16_t checksum = 0;
	NSUInteger checksumStartPos = 0x0a;
	NSUInteger checksumEndPos = data.length - 5;
	
	for (NSUInteger j = checksumStartPos; j < checksumEndPos; j++)
	{
		checksum += bytes[j];
	}
	
	checksum &= 0x3fff;
	
	if(bytes[checksumEndPos] != checksum >> 7
	   ||
	   bytes[checksumEndPos + 1] != (checksum & 0x7f))
	{
		return NO;
	}
	return YES;
}

+ (void) updateMessageLengthInSysexData:(NSMutableData *)data
{
	uint8_t *bytes = data.mutableBytes;
	NSUInteger totalLength = data.length;
	NSUInteger mlen = totalLength - 10;
	mlen &= 0x3fff;
	bytes[totalLength - 3] = mlen >> 7;
	bytes[totalLength - 2] = mlen & 0x7f;
}

+ (BOOL)messageLengthIsValidInSysexData:(NSData *)data
{
	const uint8_t *bytes = (const uint8_t *)data.bytes;
	uint16_t dLen = data.length;
	uint16_t len = data.length - 10;
	uint16_t mLen = (bytes[dLen - 3] << 7) | (bytes[dLen - 2] & 0x7f);
	if(len != mLen)
	{
		return NO;
	}
	return YES;
}

- (void) setByteValue:(char)byte inPayloadAtIndex:(NSUInteger)i
{
	if(i >= _payloadLength) return;
	char *bytes = _payload;
	bytes[i] = byte;
}

- (char)byteValueInPayloadAtIndex:(NSUInteger)i
{
	if(i >= _payloadLength) return 255;
	const char *bytes = _payload;
	return bytes[i];
}

- (void)send
{
	[[[MDMIDI sharedInstance] a4MidiDestination] sendSysexData:self.sysexData];
}

- (void)sendTemp
{
	[self sendWithMode:A4SendTemp];
}

- (void)sendWithMode:(A4Sendmode)mode
{
	if(mode == A4SendSave)
	{
		[self send];
	}
	else
	{
		NSData *d = [self sysexDataForTempSend];
		[[[MDMIDI sharedInstance] a4MidiDestination] sendSysexData:d];
	}
}

- (NSData *)payloadData
{
	return [NSData dataWithBytes:self.payload length:self.payloadLength];
}

- (void)dealloc
{
	if(self.ownsPayload && _payload)
		free(_payload);
}

@end
