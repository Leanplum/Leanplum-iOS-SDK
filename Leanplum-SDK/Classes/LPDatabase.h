//
//  LPDatabase.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPDatabase : NSObject

/**
 * Returns shared database.
 */
+ (LPDatabase *)sharedDatabase;

/**
 * Returns a file path of sqlite from the documents directory.
 */
+ (NSString *)sqliteFilePath;

/**
 * Runs a query. 
 * Use this to create, update, and delete.
 */
- (void)runQuery:(NSString *)query;

/**
 * Runs a query with objects to bind. Use this to insert.
 * Use ? in the query and pass array of NSString objects to bindObjects.
 */
- (void)runQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind;

/**
 * Return rows as array from the query. 
 * Use this for fetching data.
 * Datas are saved as NSDictionary. Key is the column's name.
 */
- (NSArray *)rowsFromQuery:(NSString *)query;

/**
 * Return rows as array from the query with objects.
 * Use ? in the query and pass array of NSString objects to bindObjects.
 */
- (NSArray *)rowsFromQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind;

@end
