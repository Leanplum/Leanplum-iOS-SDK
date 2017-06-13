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

@implementation LPDatabase

/**
 * Create/Open SQLite database.
 */
- (id)init
{
    if (self = [super init]) {
        const char *sqliteFilePath = [[LPDatabase sqliteFilePath] UTF8String];
        sqlite3 *sqlite;
        int result = sqlite3_open(sqliteFilePath, &sqlite);
        if (result != SQLITE_OK) {
            LPLog(LPError, @"Fail to open SQLite with result of %d", result);
            return self;
        }
        
        // Create tables.
        [self runQuery:@"CREATE TABLE IF NOT EXISTS event ("
                            "id INTEGER PRIMARY KEY,"
                            "data TEXT"
                        ");"];
        NSLog(@"This is okay?");
    }
    return self;
}

+ (LPDatabase *)database
{
    static id _database = nil;
    static dispatch_once_t databaseToken;
    dispatch_once(&databaseToken, ^{
        _database = [self new];
    });
    return _database;
}

+ (NSString *)sqliteFilePath
{
    return [[LPFileManager documentsDirectory] stringByAppendingPathComponent:LEANPLUM_SQLITE_NAME];
}

/**
 * Helper method that returns sqlite statement from query.
 * Used by both runQuery: and rowsFromQuery.
 */
- (sqlite3_stmt *)sqliteStatementFromQuery:(NSString *)query
{
    const char *sqliteFilePath = [[LPDatabase sqliteFilePath] UTF8String];
    sqlite3 *sqlite;
    int result = sqlite3_open(sqliteFilePath, &sqlite);
    if (result != SQLITE_OK) {
        LPLog(LPError, @"Fail to open SQLite with result of %d", result);
        return nil;
    }
    
    sqlite3_stmt *statement;
    result = sqlite3_prepare_v2(sqlite, [query UTF8String], -1, &statement, NULL);
    if (result != SQLITE_OK) {
        LPLog(LPError, @"Preparing '%@': %s (%d)", query, sqlite3_errmsg(sqlite),
              result);
        return nil;
    }
    
    return statement;
}

- (void)runQuery:(NSString *)query
{
    sqlite3_stmt *statement = [self sqliteStatementFromQuery:query];
    if (!statement) {
        return;
    }
    
    int result = sqlite3_step(statement);
    if (result != SQLITE_DONE) {
        LPLog(LPError, @"Fail to runQuery with result of %d", result);
    }
    sqlite3_finalize(statement);
}

- (NSArray *)rowsFromQuery:(NSString *)query
{
    NSMutableArray *rows = [NSMutableArray new];
    sqlite3_stmt *statement = [self sqliteStatementFromQuery:query];
    if (!statement) {
        return @[];
    }
    
    // Iterate through rows.
    while (sqlite3_step(statement) == SQLITE_ROW) {
        // Get column data as dictionary where column name is the key
        // and value will be a string. This is a safe conversion.
        // For more details: http://www.sqlite.org/c3ref/column_blob.html
        NSMutableDictionary *columnData = [NSMutableDictionary new];
        int columnsCount = sqlite3_column_count(statement);
        for (int i=0; i<columnsCount; i++){
            char *columnKeyUTF8 = (char *)sqlite3_column_name(statement, i);
            NSString *columnKey = [NSString stringWithUTF8String:columnKeyUTF8];
            
            char *columnValueUTF8 = (char *)sqlite3_column_text(statement, i);
            NSString *columnValue = [NSString stringWithUTF8String:columnValueUTF8];
            
            columnData[columnKey] = columnValue;
        }
        [rows addObject:columnData];
    }
    sqlite3_finalize(statement);
    
    return rows;
}

@end
