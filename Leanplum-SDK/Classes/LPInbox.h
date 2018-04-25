//
//  LPInbox.h
//  Leanplum
//
//  Created by Aleksandar Gyorev on 05/08/15.
//  Copyright (c) 2015 Leanplum, Inc. All rights reserved.
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

#import <Foundation/Foundation.h>

@class LPInboxMessage;
@class LPNewsfeed;

#pragma mark - LPInbox interface

/**
 * This block is used when you define a callback.
 */
typedef void (^LeanplumInboxChangedBlock)(void);
typedef void (^LeanplumInboxSyncedBlock)(BOOL success);

@interface LPInbox : NSObject

#pragma mark - LPInbox methods

/**
 * Returns the number of all inbox messages on the device.
 */
- (NSUInteger)count;

/**
 * Returns the number of the unread inbox messages on the device.
 */
- (NSUInteger)unreadCount;

/**
 * Returns the identifiers of all inbox messages on the device sorted in ascending
 * chronological order, i.e. the id of the oldest message is the first one, and the most
 * recent one is the last one in the array.
 */
- (NSArray *)messagesIds;

/**
 * Returns an array containing all of the inbox messages (as LPInboxMessage objects)
 * on the device, sorted in ascending chronological order, i.e. the oldest message is the 
 * first one, and the most recent one is the last one in the array.
 */
- (NSArray *)allMessages;

/**
 * Returns an array containing all of the unread inbox messages on the device, sorted
 * in ascending chronological order, i.e. the oldest message is the first one, and the
 * most recent one is the last one in the array.
 */
- (NSArray *)unreadMessages;

/**
 * Returns the inbox messages associated with the given messageId identifier.
 */
- (LPInboxMessage *)messageForId:(NSString *)messageId;

/**
 * Call this method if you don't want Inbox images to be prefetched.
 * Useful if you only want to deal with image URL.
 */
- (void)disableImagePrefetching;

/**
 * Block to call when the inbox receive new values from the server.
 * This will be called on start, and also later on if the user is in an experiment
 * that can update in realtime.
 */
- (void)onChanged:(LeanplumInboxChangedBlock)block;

/**
 * Block to call when forceContentUpdate was called.
 * Returns true if syncing was successful.
 * Note: use onChanged: for UI.
 */
- (void)onForceContentUpdate:(LeanplumInboxSyncedBlock)block;

/**
 @{
 * Adds a responder to be executed when an event happens.
 * Uses NSInvocation instead of blocks.
 * @see [Leanplum onStartResponse:]
 */
- (void)addInboxChangedResponder:(id)responder withSelector:(SEL)selector;
- (void)removeInboxChangedResponder:(id)responder withSelector:(SEL)selector;
/**@}*/

@end

@interface LPInbox () {
@private
    BOOL _didLoad;
}

typedef void (^LeanplumInboxCacheUpdateBlock)(void);

#pragma mark - LPInbox properties

@property(assign, nonatomic) NSUInteger unreadCount;
@property(strong, nonatomic) NSMutableDictionary *messages;
@property(strong, nonatomic) NSMutableArray *inboxChangedBlocks;
@property(strong, nonatomic) NSMutableSet *inboxChangedResponders;
@property(strong, nonatomic) NSMutableArray *inboxSyncedBlocks;
@property(strong, nonatomic) NSMutableSet *downloadedImageUrls;

#pragma mark - LPInbox method declaration

+ (LPInbox *)sharedState;

- (void)downloadMessages;
- (void)load;
- (void)save;
- (void)updateUnreadCount:(NSUInteger)unreadCount;
- (void)updateMessages:(NSMutableDictionary *)messages unreadCount:(NSUInteger)unreadCount;
- (void)removeMessageForId:(NSString *)messageId;
- (void)reset;
- (void)triggerInboxChanged;
- (void)triggerInboxSyncedWithStatus:(BOOL)success;

@end
