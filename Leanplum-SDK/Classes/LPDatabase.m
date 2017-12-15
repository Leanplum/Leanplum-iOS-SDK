//
//  LPDatabase.m
//  Leanplum
//
//  Created by Alexis Oyama on 6/9/17.
//  Copyright (c) 2017 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPDatabase.h"
#import "LPFileManager.h"
#import "LeanplumInternal.h"
#import "Constants.h"
#import <sqlite3.h>

#define ERROR_COUNT_TO_RECREATE_SQLITE 25

static sqlite3 *sqlite;
static BOOL retryOnCorrupt;
static BOOL willSendErrorLog;
static NSInteger errorCount;

@implementation LPDatabase

- (id)init
{
    if (self = [super init]) {
        retryOnCorrupt = NO;
        willSendErrorLog = NO;
        errorCount = 0;
        [self initSQLite];
    }
    return self;
}

/**
 * Create/Open SQLite database.
 */
- (sqlite3 *)initSQLite
{
    const char *sqliteFilePath = [[LPDatabase sqliteFilePath] UTF8String];
    int result = sqlite3_open(sqliteFilePath, &sqlite);
    if (result != SQLITE_OK) {
        [self handleSQLiteError:@"SQLite fail to open" errorResult:result query:nil];
        return nil;
    }
    retryOnCorrupt = NO;
    errorCount = 0;
    
    // Create tables.
    [self runQuery:@"CREATE TABLE IF NOT EXISTS event ("
                        "data TEXT NOT NULL"
                    "); PRAGMA user_version = 1;"];
    return sqlite;
}

- (void)dealloc
{
    sqlite3_close(sqlite);
}

+ (LPDatabase *)sharedDatabase
{
    static id _database = nil;
    static dispatch_once_t databaseToken;
    dispatch_once(&databaseToken, ^{
        _database = [self new];
    });
    return _database;
}

/**
 * Returns the file path of sqlite.
 */
+ (NSString *)sqliteFilePath
{
    return [[LPFileManager documentsDirectory] stringByAppendingPathComponent:LEANPLUM_SQLITE_NAME];
}

/**
 * Helper function that logs and sends to the server.
 */
- (void)handleSQLiteError:(NSString *)errorName errorResult:(int)result query:(NSString *)query
{
    NSString *reason = [NSString stringWithFormat:@"%s (%d)", sqlite3_errmsg(sqlite), result];
    if (query) {
        reason = [NSString stringWithFormat:@"'%@' %@", query, reason];
    }
    LPLog(LPError, @"%@: %@", errorName, reason);
    
    // If SQLite is corrupted or if there are too many errors, create a new one.
    // Using retryOnCorrupt to prevent infinite loop.
    errorCount++;
    if ((result == SQLITE_CORRUPT || errorCount >= ERROR_COUNT_TO_RECREATE_SQLITE) && !retryOnCorrupt) {
        [[NSFileManager defaultManager] removeItemAtPath:[LPDatabase sqliteFilePath] error:nil];
        retryOnCorrupt = YES;
        errorCount = 0;
        [self initSQLite];
    }
}

/**
 * Helper method that returns sqlite statement from query.
 * Used by both runQuery: and rowsFromQuery.
 */
- (sqlite3_stmt *)sqliteStatementFromQuery:(NSString *)query
                               bindObjects:(NSArray *)objectsToBind
{
    // Retry creating SQLite.
    if (!query || (!sqlite && [self initSQLite])) {
        return nil;
    }
    
    sqlite3_stmt *statement;
    int __block result = sqlite3_prepare_v2(sqlite, [query UTF8String], -1, &statement, NULL);
    if (result != SQLITE_OK) {
        [self handleSQLiteError:@"SQLite fail to prepare" errorResult:result query:query];
        return nil;
    }
    errorCount = 0;
    
    // Bind objects.
    // It is recommended to use this instead of making a full query in NSString to
    // prevent from SQL injection attacks and errors from having a quotation mark in text.
    [objectsToBind enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:[NSString class]]) {
            LPLog(LPError, @"Bind object have to be NSString.");
        }
        
        result = sqlite3_bind_text(statement, (int)idx+1, [obj UTF8String],
                                   (int)[obj lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                   SQLITE_TRANSIENT);
        
        if (result != SQLITE_OK) {
            NSString *message = [NSString stringWithFormat:@"SQLite fail to bind %@ to %ld", obj, idx+1];
            [self handleSQLiteError:message errorResult:result query:query];
        } else {
            errorCount = 0;
        }
    }];
    
    return statement;
}

- (void)runQuery:(NSString *)query
{
    [self runQuery:query bindObjects:nil];
}

- (void)runQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind
{
    // Retry creating SQLite.
    if (!sqlite && [self initSQLite]) {
        return;
    }
    
    @synchronized (self) {
        sqlite3_stmt *statement = [self sqliteStatementFromQuery:query bindObjects:objectsToBind];
        if (!statement) {
            return;
        }
        
        int result = sqlite3_step(statement);
        if (result != SQLITE_DONE) {
            [self handleSQLiteError:@"SQLite fail to run query" errorResult:result query:query];
        } else {
            errorCount = 0;
        }
        willSendErrorLog = NO;
        sqlite3_finalize(statement);
    }
}

- (NSArray *)rowsFromQuery:(NSString *)query
{
    return [self rowsFromQuery:query bindObjects:nil];
}

- (NSArray *)rowsFromQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind
{
    // Retry creating SQLite.
    if (!sqlite && [self initSQLite]) {
        return @[];
    }
    
    @synchronized (self) {
        NSMutableArray *rows = [NSMutableArray new];
        sqlite3_stmt *statement = [self sqliteStatementFromQuery:query
                                                     bindObjects:objectsToBind];
        if (!statement) {
            return @[];
        }
        
        // Iterate through rows.
        while (sqlite3_step(statement) == SQLITE_ROW) {
            // Get column data as dictionary where column name is the key
            // and value will be a blob or a string. This is a safe conversion.
            // Details: http://www.sqlite.org/c3ref/column_blob.html
            NSMutableDictionary *columnData = [NSMutableDictionary new];
            int columnsCount = sqlite3_column_count(statement);
            for (int i=0; i<columnsCount; i++){
                char *columnKeyUTF8 = (char *)sqlite3_column_name(statement, i);
                NSString *columnKey = [NSString stringWithUTF8String:columnKeyUTF8];
                
                if (sqlite3_column_type(statement, i) == SQLITE_BLOB) {
                    NSData *columnBytes = [[NSData alloc] initWithBytes:sqlite3_column_blob(statement, i)
                                                                 length:sqlite3_column_bytes(statement, i)];
                    columnData[columnKey] = [NSKeyedUnarchiver unarchiveObjectWithData:columnBytes];
                } else {
                    char *columnValueUTF8 = (char *)sqlite3_column_text(statement, i);
                    if (columnValueUTF8) {
                        NSString *columnValue = [NSString stringWithUTF8String:columnValueUTF8];
                        columnData[columnKey] = columnValue;
                    }
                }
            }
            [rows addObject:columnData];
        }
        sqlite3_finalize(statement);
        errorCount = 0;
        return rows;
    }
    return @[];
}

@end
