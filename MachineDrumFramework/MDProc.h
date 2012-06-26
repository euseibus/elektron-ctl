//
//  MDProcedure.h
//  MachineDrumFramework
//
//  Created by Jakob Penca on 6/26/12.
//  Copyright (c) 2012 Jakob Penca. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "MDMachinedrumPublic.h"
#import "MDPatternPublicWrapper.h"
#import "MDKit.h"

@class MDProcedureCondition;

typedef enum MDProcedureConditionsMode
{
	MDProcedureConditionsMode_ANY,
	MDProcedureConditionsMode_ALL,
	MDProcedureConditionsMode_NONE,
}
MDProcedureConditionsMode;


@interface MDProc : NSObject
@property MDProcedureConditionsMode conditionsMode;

+ (MDProc *) procedureWithMode:(MDProcedureConditionsMode)m;
- (BOOL) evaluateConditions;
- (void) processPattern:(MDPatternPublicWrapper *) pattern kit: (MDKit *)kit;
- (void) addCondition:(MDProcedureCondition *)c;
- (void) removeConditionAtIndex:(NSUInteger)i;
- (void) removeFirstCondition;
- (void) removeLastCondition;
- (void) clearConditions;
@end
