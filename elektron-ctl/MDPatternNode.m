//
//  MDPatternSelectionNode.m
//  MachineDrumFrameworkOSX
//
//  Created by Jakob Penca on 7/20/12.
//  Copyright (c) 2012 Jakob Penca. All rights reserved.
//

#import "MDPatternNode.h"

@interface MDPatternNode()
{
	MDPatternNodePosition *_position;
	NSMutableArray *_locks;
	BOOL _trig;
}

- (void) updateLocks;

@end


@implementation MDPatternNode

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ | t: %d s: %d numLocks: %d", [super description], self.position.track, self.position.step, [self.locks count]];
}

+ (id)nodeAtTrack:(uint8_t)track step:(uint8_t)step
{
	MDPatternNode *n = [self new];
	n.position = [MDPatternNodePosition nodePositionAtTrack:track step:step];
	return n;
}

+ (id)nodeWithPosition:(MDPatternNodePosition *)position
{
	MDPatternNode *n = [self new];
	n.position = position;
	return n;
}

- (void)setTrig:(BOOL)trig
{
	_trig = trig;
	if(!trig) [self clear];
}

- (BOOL)trig
{
	return _trig;
}

- (void)clear
{
	_locks = [NSMutableArray array];
	_trig = NO;
}

- (void)addLock:(MDParameterLock *)lock
{
	if(!lock) return;
	
	MDParameterLock *newLock = [lock copy];
	
	for (MDParameterLock *pLock in self.locks)
	{
		if(pLock.param == newLock.param)
		{
			pLock.lockValue = newLock.lockValue;
			break;
		}
	}
	
	[_locks addObject:newLock];
	[self updateLocks];
}

- (void)removeLockForParam:(uint8_t)param
{
	NSMutableArray *bin = [NSMutableArray array];
	
	for (MDParameterLock *l in self.locks)
	{
		if(l.param == param)
			[bin addObject:l];
	}
	
	for (id i in bin)
		[self.locks removeObject:i];
}

- (void)updateLocks
{
	for (MDParameterLock *pLock in self.locks)
	{
		pLock.track = _position.track;
		pLock.step = _position.step;
	}
}

- (id)init
{
	if(self = [super init])
	{
		_locks = [NSMutableArray array];
	}
	return self;
}

- (void)setPosition:(MDPatternNodePosition *)position
{
	_position = position;
	[self updateLocks];
}

- (MDPatternNodePosition *)position
{
	return _position;
}

@end
