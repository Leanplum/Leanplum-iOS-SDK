//
//  LPEventDataManager.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPEventDataManager : NSObject

/**
 * Add event to database.
 */
+ (void)addEvent:(NSDictionary *)event;

/**
 * Add multiple events to database.
 */
+ (void)addEvents:(NSArray *)events;

/**
 * Fetch events with limit. 
 * Usually you pass the maximum events server can handle.
 */
+ (NSArray *)eventsWithLimit:(NSInteger)limit;

/**
 * Delete first X events using limit.
 */
+ (void)deleteEventsWithLimit:(NSInteger)limit;

/**
 * Returns the number of total events stored.
 */
+ (NSInteger)count;

@end
