//
//  MDPatternSequencer.h
//  yolo
//
//  Created by Jakob Penca on 7/14/13.
//
//

#import <Foundation/Foundation.h>
#import "MDMachinedrumPublic.h"

@class MDPatternSequencer;

@protocol MDPatternSequencerDelegate <NSObject>
- (void) patternSequencer: (MDPatternSequencer *)sequencer didAdvanceToStep:(NSUInteger)step;
- (void) patternSequencerDidTick: (MDPatternSequencer *)sequencer;
- (void) patternSequencer: (MDPatternSequencer *)sequencer willAdvanceToStep:(NSUInteger)step;
@end

@interface MDPatternSequencer : NSObject

@property (strong, nonatomic) MDPattern *pattern;
@property NSUInteger currentTickInPattern;
@property (nonatomic, readonly) NSTimeInterval timeIntervalBetweenClocks;
@property (assign, nonatomic) id<MDPatternSequencerDelegate> delegate;
@property BOOL playing;

+ (MDPatternSequencer *) sharedInstance;
- (void) tick;
- (void) start;
@end
