//
//  A4PerformanceMacroHandler.h
//  MachineDrumFramework
//
//  Created by Jakob Penca on 21/11/13.
//  Copyright (c) 2013 Jakob Penca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MidiInputParser.h"
#import "PGMidi.h"
#import "A4PVal.h"

@class A4ControllerdataHandler;


@protocol A4ControllerdataHandlerDelegate <NSObject>
@optional
- (void) a4ControllerdataHandler:(A4ControllerdataHandler *)handler performanceKnob:(uint8_t)knob didChangeValue:(uint8_t)value;
- (void) a4ControllerdataHandler:(A4ControllerdataHandler *)handler track:(uint8_t) trackIdx wasMuted:(BOOL)muted;
- (void) a4ControllerdataHandler:(A4ControllerdataHandler *)handler track:(uint8_t) track synthParamChanged:(A4PVal)pval;
- (void) a4ControllerdataHandler:(A4ControllerdataHandler *)handler FXParamChanged:(A4PVal)pval;
@end

@interface A4ControllerdataHandler : NSObject <MidiInputDelegate, PGMidiDelegate>
@property (nonatomic, weak) id<A4ControllerdataHandlerDelegate> delegate;
@property (nonatomic) uint8_t performanceChannel;
@property (nonatomic) BOOL enabled;
+ (instancetype) controllerdataHandlerWithDelegate:(id<A4ControllerdataHandlerDelegate>)delegate;
@end
