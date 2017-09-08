//
//  NSTimer+Blocks.h
//
//  Created by Jiva DeVoe on 1/14/11.
//  Copyright 2011 Random Ideas, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPTimerBlocks : NSObject

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats;
+(id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats;

@end
