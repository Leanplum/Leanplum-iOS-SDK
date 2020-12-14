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

NS_ASSUME_NONNULL_BEGIN

#pragma mark - LPInboxMessage interface

NS_SWIFT_NAME(LeanplumInbox.Message)
@interface LPInboxMessage : NSObject <NSCoding>

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - LPInboxMessage methods

/**
 * Returns the message identifier of the inbox message.
 */
@property (strong, nonatomic, readonly, nonnull) NSString *messageId;

/**
 * Returns the title of the inbox message.
 */
@property (strong, nonatomic, readonly, nonnull) NSString *title;

/**
 * Returns the subtitle of the inbox message.
 */
@property (strong, nonatomic, readonly, nonnull) NSString *subtitle;

/**
 * Returns the image path of the inbox message. Can be nil.
 * Use with [UIImage contentsOfFile:].
 */
@property (strong, nonatomic, readonly, nullable) NSString *imageFilePath;

/**
 * Returns the image URL of the inbox message.
 * You can safely use this with prefetching enabled.
 * It will return the file URL path instead if the image is in cache.
 */
@property (strong, nonatomic, readonly, nullable) NSURL *imageURL;

/**
 * Returns the data of the inbox message. Advanced use only.
 */
@property (strong, nonatomic, readonly, nullable) NSDictionary *data;

/**
 * Returns the delivery timestamp of the inbox message.
 */
@property (strong, nonatomic, readonly, nullable) NSDate *deliveryTimestamp;

/**
 * Return the expiration timestamp of the inbox message.
 */
@property (strong, nonatomic, readonly, nullable) NSDate *expirationTimestamp;

/**
 * Returns YES if the inbox message is read.
 */
@property (assign, nonatomic, readonly) BOOL isRead;

/**
 * Mark the inbox message as read without invoking its open action.
 */
- (void)markAsRead;

/**
 * Read the inbox message, marking it as read and invoking its open action.
 */
- (void)read;

/**
 * Remove the inbox message from the inbox.
 */
- (void)remove;

@end

#pragma mark - LPInbox interface

/**
 * This block is used when you define a callback.
 */
typedef void (^LeanplumInboxChangedBlock)(void);
typedef void (^LeanplumInboxSyncedBlock)(BOOL success);

NS_SWIFT_NAME(LeanplumInbox)
@interface LPInbox : NSObject

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - LPInbox methods

/**
 * Returns the number of all inbox messages on the device.
 */
@property (assign, nonatomic, readonly) NSUInteger count;

/**
 * Returns the number of the unread inbox messages on the device.
 */
@property (assign, nonatomic, readonly) NSUInteger unreadCount;

/**
 * Returns the identifiers of all inbox messages on the device sorted in ascending
 * chronological order, i.e. the id of the oldest message is the first one, and the most
 * recent one is the last one in the array.
 */
@property (strong, nonatomic, readonly, nonnull) NSArray<NSString *> *messagesIds;

/**
 * Returns an array containing all of the inbox messages (as LPInboxMessage objects)
 * on the device, sorted in ascending chronological order, i.e. the oldest message is the 
 * first one, and the most recent one is the last one in the array.
 */
@property (strong, nonatomic, readonly, nonnull) NSArray<LPInboxMessage *> *allMessages;

/**
 * Returns an array containing all of the unread inbox messages on the device, sorted
 * in ascending chronological order, i.e. the oldest message is the first one, and the
 * most recent one is the last one in the array.
 */
@property (strong, nonatomic, readonly, nonnull) NSArray<LPInboxMessage *> *unreadMessages;

/**
 * Returns the inbox messages associated with the given messageId identifier.
 */
- (nullable LPInboxMessage *)messageForId:(NSString *)messageId
NS_SWIFT_NAME(message(id:));

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
- (void)onChanged:(LeanplumInboxChangedBlock)block
NS_SWIFT_NAME(onInboxChanged(completion:));

/**
 * Block to call when forceContentUpdate was called.
 * Returns true if syncing was successful.
 * Note: use onChanged: for UI.
 */
- (void)onForceContentUpdate:(LeanplumInboxSyncedBlock)block;

/**
 Forces downloading of inbox messages from the server. After messages are downloaded the appropriate callbacks will fire.
 */
- (void)downloadMessages;
/**
 Forces downloading of inbox messages from the server. After messages are downloaded the appropriate callbacks will fire.
 @param completionHandler  The callback to invoke when messages are downloaded.
 */
- (void)downloadMessages:(nullable LeanplumInboxSyncedBlock)completionHandler;
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

NS_ASSUME_NONNULL_END
