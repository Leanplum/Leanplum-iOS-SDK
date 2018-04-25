//
//  LPInbox.m
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

#import "LPInbox.h"
#import "Constants.h"
#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "LPVarCache.h"
#import "LeanplumInternal.h"
#import "LPAES.h"
#import "LPKeychainWrapper.h"
#import "LPFileManager.h"
#import "Utils.h"

static NSObject *updatingLock;

@implementation LPInbox

+ (LPInbox *)sharedState {
    static LPInbox *sharedInbox = nil;
    static dispatch_once_t onceInboxToken;
    dispatch_once(&onceInboxToken, ^{
        sharedInbox = [self new];
    });
    return sharedInbox;
}

- (id)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

#pragma mark - LPInbox private methods

- (void)load
{
    RETURN_IF_NOOP;
    @try {
        NSData *encryptedData = [[NSUserDefaults standardUserDefaults]
                                 dataForKey:LEANPLUM_DEFAULTS_INBOX_KEY];
        NSUInteger unreadCount = 0;
        NSMutableDictionary *messages;
        if (encryptedData) {
            NSData *decryptedData = [LPAES decryptedDataFromData:encryptedData];
            if (!decryptedData) {
                return;
            }
            
            NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:decryptedData];
            messages = (NSMutableDictionary *)[archiver decodeObjectForKey:LP_PARAM_INBOX_MESSAGES];
            if (!messages) {
                messages = [NSMutableDictionary dictionary];
            }
            
            // We remove a message from the cached ones if it has expired, and update the unreadCount accordingly.
            for (NSString *messageId in messages.allKeys) {
                if (![messages[messageId] isActive]) {
                    [messages removeObjectForKey:messageId];
                } else if(![messages[messageId] isRead]) {
                    unreadCount++;
                }
            }
            
            // Download images.
            BOOL willDownloadImages = NO;
            for (NSString *messageId in messages) {
                LPInboxMessage *inboxMessage = [self messageForId:messageId];
                willDownloadImages |= [inboxMessage downloadImageIfPrefetchingEnabled];
            }

            // Trigger inbox changed when all images are downloaded.
            if (willDownloadImages) {
                [Leanplum onceVariablesChangedAndNoDownloadsPending:^{
                    LP_END_USER_CODE
                    [self updateMessages:messages unreadCount:unreadCount];
                    LP_BEGIN_USER_CODE
                }];
            } else {
                [self updateMessages:messages unreadCount:unreadCount];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Leanplum: Could not load the Inbox data: %@", exception);
    }
}

- (void)save
{
    RETURN_IF_NOOP;
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[self messages] forKey:LP_PARAM_INBOX_MESSAGES];
    [archiver finishEncoding];
    
    NSData *encryptedData = [LPAES encryptedDataFromData:data];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:encryptedData forKey:LEANPLUM_DEFAULTS_INBOX_KEY];
    [Leanplum synchronizeDefaults];
}

- (void)updateUnreadCount:(NSUInteger)unreadCount
{
    _unreadCount = unreadCount;
    [self save];
    [self triggerInboxChanged];
}

- (void)updateMessages:(NSMutableDictionary *)messages unreadCount:(NSUInteger)unreadCount
{
    @synchronized (updatingLock) {
        _unreadCount = unreadCount;
        
        if (messages) {
            _messages = messages;
        }
    }
    
    _didLoad = YES;
    [self save];
    [self triggerInboxChanged];
}

- (void)removeMessageForId:(NSString *)messageId
{
    NSUInteger unreadCount = [[LPInbox sharedState] unreadCount];
    if (![[self messageForId:messageId] isRead]) {
        unreadCount--;
    }
    
    RETURN_IF_NOOP;
    LP_TRY
    [_messages removeObjectForKey:messageId];
    [[LPInbox sharedState] updateMessages:_messages unreadCount:unreadCount];
    
    NSDictionary *params = @{LP_PARAM_INBOX_MESSAGE_ID:messageId};
    LeanplumRequest *req = [LeanplumRequest post:LP_METHOD_DELETE_INBOX_MESSAGE
                                          params:params];
    [req send];
    LP_END_TRY
}

- (void)reset
{
    _unreadCount = 0;
    _messages = [[NSMutableDictionary alloc] init];
    _didLoad = NO;
    _inboxChangedBlocks = nil;
    _inboxChangedResponders = nil;
    _inboxSyncedBlocks = nil;
    updatingLock = [[NSObject alloc] init];
    _downloadedImageUrls = [NSMutableSet new];
}

- (void)triggerInboxChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in _inboxChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumInboxChangedBlock block in _inboxChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

- (void)triggerInboxSyncedWithStatus:(BOOL)success
{
    LP_BEGIN_USER_CODE
    for (LeanplumInboxSyncedBlock block in _inboxSyncedBlocks.copy) {
        block(success);
    }
    LP_END_USER_CODE
}

#pragma mark - LPInbox methods

- (void)downloadMessages
{
    RETURN_IF_NOOP;
    LP_TRY
    LeanplumRequest *req = [LeanplumRequest post:LP_METHOD_GET_INBOX_MESSAGES params:nil];
    [req onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        NSDictionary *messagesDict = response[LP_KEY_INBOX_MESSAGES];
        NSUInteger unreadCount = 0;
        NSMutableDictionary *messages = [[NSMutableDictionary alloc] init];
        BOOL willDownloadImage = NO;
        
        for (NSString *messageId in messagesDict) {
            NSDictionary *messageDict = messagesDict[messageId];
            NSDictionary *actionArgs = messageDict[LP_KEY_MESSAGE_DATA][LP_KEY_VARS];
            NSDate *deliveryTimestamp = [NSDate dateWithTimeIntervalSince1970:
                                [messageDict[LP_KEY_DELIVERY_TIMESTAMP] doubleValue] / 1000.0];
            NSDate *expirationTimestamp = nil;
            if (messageDict[LP_KEY_EXPIRATION_TIMESTAMP]) {
                expirationTimestamp = [NSDate dateWithTimeIntervalSince1970:
                                [messageDict[LP_KEY_EXPIRATION_TIMESTAMP] doubleValue] / 1000.0];
            }
            BOOL isRead = [messageDict[LP_KEY_IS_READ] boolValue];
            
            LPInboxMessage *message = [[LPInboxMessage alloc] initWithMessageId:messageId
                                                              deliveryTimestamp:deliveryTimestamp
                                                            expirationTimestamp:expirationTimestamp
                                                                         isRead:isRead
                                                                     actionArgs:actionArgs];
            if (!message) {
                continue;
            }

            if (!isRead) {
                unreadCount++;
            }
            willDownloadImage |= [message downloadImageIfPrefetchingEnabled];
            messages[messageId] = message;
        }

        // Trigger inbox changed when all images are downloaded.
        if (willDownloadImage) {
            [Leanplum onceVariablesChangedAndNoDownloadsPending:^{
                LP_END_USER_CODE
                [self updateMessages:messages unreadCount:unreadCount];
                [self triggerInboxSyncedWithStatus:YES];
                LP_BEGIN_USER_CODE
            }];
        } else {
            [self updateMessages:messages unreadCount:unreadCount];
            [self triggerInboxSyncedWithStatus:YES];
        }
        LP_END_TRY
    }];
    [req onError:^(NSError *error) {
        [self triggerInboxSyncedWithStatus:NO];
    }];
    [req sendIfConnected];
    LP_END_TRY
}

- (NSUInteger)count
{
    LP_TRY
    return [[self messages] count];
    LP_END_TRY

    return 0;
}

- (NSArray *)messagesIds
{
    LP_TRY
    NSMutableArray *messagesIds = [[[self messages] allKeys] mutableCopy];
    [messagesIds sortUsingComparator:^(NSString *firstId, NSString *secondId) {
        NSDate *firstDate = [[self messageForId:firstId] deliveryTimestamp];
        NSDate *secondDate = [[self messageForId:secondId] deliveryTimestamp];
        return [firstDate compare:secondDate];
    }];
    return messagesIds;
    LP_END_TRY

    return @[];
}

- (NSArray *)allMessages
{
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    LP_TRY
    NSArray *messagesIds = [self messagesIds];
    for (NSString *messageId in messagesIds) {
        [messages addObject:[self messageForId:messageId]];
    }
    LP_END_TRY
    return messages;
}

- (NSArray *)unreadMessages
{
    NSMutableArray *unreadMessages = [[NSMutableArray alloc] init];
    LP_TRY
    for (LPInboxMessage *message in [self allMessages]) {
        if (![message isRead]) {
            [unreadMessages addObject:message];
        }
    }
    LP_END_TRY
    return unreadMessages;
}

- (LPInboxMessage *)messageForId:(NSString *)messageId
{
    LP_TRY
    return self.messages[messageId];
    LP_END_TRY

    return nil;
}

- (void)onChanged:(LeanplumInboxChangedBlock)block
{
    if (!block) {
        return;
    }
    
    LP_TRY
    if (!_inboxChangedBlocks) {
        _inboxChangedBlocks = [NSMutableArray array];
    }
    [_inboxChangedBlocks addObject:[block copy]];
    LP_END_TRY
    if (_didLoad) {
        block();
    }
}

- (void)onForceContentUpdate:(LeanplumInboxSyncedBlock)block
{
    if (!block) {
        return;
    }
    
    LP_TRY
    if (!_inboxSyncedBlocks) {
        _inboxSyncedBlocks = [NSMutableArray array];
    }
    [_inboxSyncedBlocks addObject:[block copy]];
    LP_END_TRY
}

- (void)addInboxChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (!_inboxChangedResponders) {
        _inboxChangedResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [Leanplum createInvocationWithResponder:responder selector:selector];
    [Leanplum addInvocation:invocation toSet:_inboxChangedResponders];
    if (_didLoad) {
        [invocation invoke];
    }
}

- (void)removeInboxChangedResponder:(id)responder withSelector:(SEL)selector
{
    LP_TRY
    [Leanplum removeResponder:responder withSelector:selector fromSet:_inboxChangedResponders];
    LP_END_TRY
}

- (void)disableImagePrefetching
{
    LP_TRY
    [LPConstantsState sharedState].isInboxImagePrefetchingEnabled = NO;
    LP_END_TRY
}

@end

#pragma mark - LPNewsfeed implementation for backwards compatibility

@implementation LPNewsfeedMessage

- (id)init
{
    return [super init];
}

@end

@implementation LPNewsfeed

+ (LPNewsfeed *)sharedState {
    static LPNewsfeed *sharedNewsfeed = nil;
    static dispatch_once_t onceNewsfeedToken;
    dispatch_once(&onceNewsfeedToken, ^{
        sharedNewsfeed = [self new];
    });
    return sharedNewsfeed;
}

- (id)init {
    return [super init];
}

- (NSUInteger)count {
    return [[LPInbox sharedState] count];
}

- (NSUInteger)unreadCount {
    return [[LPInbox sharedState] unreadCount];
}

- (NSArray *)messagesIds {
    return [[LPInbox sharedState] messagesIds];
}

- (NSArray *)allMessages {
    return [[LPInbox sharedState] allMessages];
}

- (NSArray *)unreadMessages {
    return [[LPInbox sharedState] unreadMessages];
}

- (void)onChanged:(LeanplumNewsfeedChangedBlock)block {
    [[LPInbox sharedState] onChanged:block];
}

- (LPNewsfeedMessage *)messageForId:(NSString *)messageId {
    return (LPNewsfeedMessage *)[[LPInbox sharedState] messageForId:messageId];
}

- (void)addNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector {
    [[LPInbox sharedState]  addInboxChangedResponder:responder withSelector:selector];
}

- (void)removeNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector {
    [[LPInbox sharedState]  removeInboxChangedResponder:responder withSelector:selector];
}

@end
