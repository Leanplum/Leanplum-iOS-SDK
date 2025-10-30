//
//  LPFileManager.h
//  Leanplum
//
//  Created by Andrew First on 1/9/13.
//  Copyright (c) 2013 Leanplum, Inc. All rights reserved.
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

#import "Leanplum.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (LeanplumExtension)

+ (nullable NSBundle *)leanplum_mainBundle;

@end

@interface LPBundle : NSBundle

- (nullable instancetype)initWithPath:(nullable NSString *)path NS_DESIGNATED_INITIALIZER;

@end

@interface LPFileManager : NSObject

+ (nullable NSString *)appBundlePath;
+ (nullable NSString *)documentsDirectory;
+ (nullable NSString *)cachesDirectory;
+ (nullable NSString *)documentsPathRelativeToFolder:(NSString *)folder;
+ (nullable NSString *)documentsPath;
+ (nullable NSString *)bundlePathRelativeToFolder:(NSString *)folder;
+ (nullable NSString *)bundlePath;

+ (nullable NSString *)fileRelativeToAppBundle:(NSString *)path;
+ (nullable NSString *)fileRelativeToDocuments:(NSString *)path
                      createMissingDirectories:(BOOL)createMissingDirectories;
+ (nullable NSString *)fileRelativeToLPBundle:(NSString *)path;
+ (BOOL)isNewerLocally:(NSDictionary *)localAttributes
            orRemotely:(NSDictionary *)serverAttributes;

+ (BOOL)fileExists:(NSString *)name;
+ (BOOL)shouldDownloadFile:(nullable NSString *)value
              defaultValue:(nullable NSString *)defaultValue;
+ (BOOL)maybeDownloadFile:(nullable NSString *)value
             defaultValue:(nullable NSString *)defaultValue
               onComplete:(nullable void (^)(void))complete;
+ (nullable NSString *)fileValue:(NSString *)stringValue
                 withDefaultValue:(nullable NSString *)defaultValue;

+ (void)initAsync:(BOOL)async;
+ (void)initWithInclusions:(nullable NSArray *)inclusions
             andExclusions:(nullable NSArray *)exclusions
                     async:(BOOL)async;

+ (BOOL)hasInited;
+ (BOOL)initializing;
+ (void)setResourceSyncingReady:(LeanplumVariablesChangedBlock)block;

// Finds all files in absDir and adds them to the files array.
+ (void)traverse:(NSString *)absoluteDir
         current:(NSString *)relativeDir
           files:(NSMutableArray *)files;

/**
 * Adds an attribute to a file at filepath to exclude it from iCloud and iTunes backup.
 */
+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *) filePathString;
+ (void)clearCacheIfSDKUpdated;
@end

NS_ASSUME_NONNULL_END
