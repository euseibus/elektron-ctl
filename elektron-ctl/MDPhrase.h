//
//  MDPhrase.h
//  yolo
//
//  Created by Jakob Penca on 6/8/13.
//
//

#import <Foundation/Foundation.h>
#import "MDMachinedrumPublic.h"

@interface MDPhrase : NSObject
@property (strong, nonatomic) MDPattern *pattern;
@property (strong, nonatomic) MDKit *kit;
@property (strong, nonatomic) MDPatternRegion *region;
@end
