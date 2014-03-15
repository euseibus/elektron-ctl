//
//  MDPatternTrigGenerator.m
//  MachineDrumFramework
//
//  Created by Jakob Penca on 8/7/12.
//  Copyright (c) 2012 Jakob Penca. All rights reserved.
//

#import "MDPatternTrigGenerator.h"
#import "MDMath.h"
@implementation MDPatternTrigGenerator

- (void) generateTrigsWithStartStride:(uint8_t)startStride endStride:(uint8_t)endStride mode:(MDPatternTrigGeneratorMode)mode
{
	if(!self.pattern || !self.region) return;
	if(!startStride) startStride = 1;
	if(!endStride) endStride = 1;
	
	int t = self.region.track;
	int lt = t + self.region.numTracks;
	
	if(lt < t)
	{
		int tmp = lt;
		lt = t;
		t = tmp;
	}
	
	for (int track = t; track < lt; track++)
	{
		int s = self.region.step;
		int ls = self.region.step + self.region.numSteps;
		int step = s;
		
		if(ls > s)
		{
			
			while (step < ls)
			{
				[self setTrigInPattern:self.pattern atTrack:track step:step mode:mode];
				int stride = round(mdmath_map(step, s, ls, startStride, endStride));
				step+=stride;
			}
		}
		else
		{
			int step = s-1;
			while (step > ls)
			{
				[self setTrigInPattern:self.pattern atTrack:track step:step mode:mode];
				int stride = roundf(mdmath_map(step, s, ls, startStride, endStride));
				step-=stride;
			}
		}
	}
}

- (void) setTrigInPattern: (MDPattern *) p atTrack:(int)t step:(int)s mode:(MDPatternTrigGeneratorMode)mode
{
	t = mdmath_wrap(t, 0, 15);
	s = mdmath_wrap(s, 0, 63);
	
	if(mode == MDPatternTrigGeneratorMode_Replace)
	{
		[p setTrigAtTrack:t step:s toValue:0];
		[p setTrigAtTrack:t step:s toValue:1];
	}
	else if(mode == MDPatternTrigGeneratorMode_Toggle)
	{
		[p toggleTrigAtTrack:t step:s];
	}
	else if(mode == MDPatternTrigGeneratorMode_Remove)
	{
		[p setTrigAtTrack:t step:s toValue:0];
	}
	else if(mode == MDPatternTrigGeneratorMode_Fill)
	{
		[p setTrigAtTrack:t step:s toValue:1];
	}
}



@end
