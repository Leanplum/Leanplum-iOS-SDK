//
//  LPEventDataManager.m
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPEventDataManager.h"
#import "LPDatabase.h"
#import "LPJSON.h"
#import "LPRequestStorage.h"

@implementation LPEventDataManager

+ (void)load
{
    [LPEventDataManager migrateRequests];
}

+ (void)migrateRequests
{
    LPRequestStorage *requestStorage = [LPRequestStorage sharedStorage];
    if ([[NSFileManager defaultManager] fileExistsAtPath:requestStorage.documentsFilePath]) {
        NSArray *requests = [requestStorage popAllRequests];
        [LPEventDataManager addEvents:requests];
    }
}

+ (void)addEvent:(NSDictionary *)event
{
    NSString *query = @"INSERT INTO event (data) VALUES (?);";
    NSArray *objectsToBind = @[[LPJSON stringFromJSON:event]];
    [[LPDatabase sharedDatabase] runQuery:query bindObjects:objectsToBind];
}

+ (void)addEvents:(NSArray *)events
{
    if (!events.count) {
        return;
    }
    
    NSMutableString *query = [@"INSERT INTO event (data) VALUES " mutableCopy];
    NSMutableArray *objectsToBind = [NSMutableArray new];
    [events enumerateObjectsUsingBlock:^(id data, NSUInteger idx, BOOL *stop) {
        NSString *postfix = idx >= events.count-1 ? @";" : @",";
        NSString *valueString = [NSString stringWithFormat:@"(?)%@", postfix];
        [query appendString:valueString];
        
        NSString *dataString = [LPJSON stringFromJSON:data];
        [objectsToBind addObject:dataString];
    }];
    [[LPDatabase sharedDatabase] runQuery:query bindObjects:objectsToBind];
}

+ (NSArray *)eventsWithLimit:(NSInteger)limit
{
    NSString *query = [NSString stringWithFormat:@"SELECT data FROM event ORDER BY rowid "
                                                  "LIMIT %ld", (long)limit];
    NSArray *rows = [[LPDatabase sharedDatabase] rowsFromQuery:query];
    
    // Convert row data to event.
    NSMutableArray *events = [NSMutableArray new];
    for (NSDictionary *row in rows) {
        NSDictionary *event = [LPJSON JSONFromString:row[@"data"]];
        if (!event || !event.count) {
            continue;
        }
        [events addObject:[event mutableCopy]];
    }
    
    return events;
}

+ (void)deleteEventsWithLimit:(NSInteger)limit
{
    // Used to be 'DELETE FROM event ORDER BY rowid LIMIT x'
    // but iOS7 sqlite3 did not compile with SQLITE_ENABLE_UPDATE_DELETE_LIMIT.
    // Consider changing it back when we drop iOS7.
    NSString *query = [NSString stringWithFormat:@"DELETE FROM event WHERE rowid IN "
                                                  "(SELECT rowid FROM event ORDER BY rowid "
                                                  "LIMIT %ld);", (long)limit];
    [[LPDatabase sharedDatabase] runQuery:query];
}

+ (NSInteger)count
{
    NSArray *rows = [[LPDatabase sharedDatabase] rowsFromQuery:@"SELECT count(*) FROM event;"];
    if (!rows || !rows.count) {
        return 0;
    }
    
    return [rows.firstObject[@"count(*)"] integerValue];
}

@end
