//
//  Leanplum.m
//  Leanplum
//
//  Created by Andrew First on 4/30/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
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

#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "Constants.h"
#import "UIDevice+IdentifierAddition.h"
#import "LPVarCache.h"
#import "Leanplum_SocketIO.h"
#import "LeanplumSocket.h"
#import "LPJSON.h"
#import "LPRegisterDevice.h"
#import "LPFileManager.h"
#import <QuartzCore/QuartzCore.h>
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPActionManager.h"
#import "LPMessageTemplates.h"
#include <sys/sysctl.h>
#import "LPRevenueManager.h"
#import "JRSwizzle.h"
#import "LPInbox.h"
#import "LPUIAlert.h"
#import "Utils.h"
#import "LPAppIconManager.h"
#import "LPUIEditorWrapper.h"

typedef void (^LPFileCallback)(NSString* value, NSString *defaultValue);

#pragma mark - LPInternalState implementation

@implementation LPInternalState

#pragma mark - LPInternalState singleton methods

+ (LPInternalState *)sharedState {
    static LPInternalState *sharedLPInternalState = nil;
    static dispatch_once_t onceLPInternalStateToken;
    dispatch_once(&onceLPInternalStateToken, ^{
        sharedLPInternalState = [[self alloc] init];
    });
    return sharedLPInternalState;
}

- (id)init {
    if (self = [super init]) {
        _startBlocks = nil;
        _variablesChangedBlocks = nil;
        _interfaceChangedBlocks = nil;
        _eventsChangedBlocks = nil;
        _noDownloadsBlocks = nil;
        _onceNoDownloadsBlocks = nil;
        _actionBlocks = nil;
        _actionResponders = nil;
        _startResponders = nil;
        _variablesChangedResponders = nil;
        _interfaceChangedResponders = nil;
        _eventsChangedResponders = nil;
        _noDownloadsResponders = nil;
        _customExceptionHandler = nil;
        _registration = nil;
        _calledStart = NO;
        _hasStarted = NO;
        _hasStartedAndRegisteredAsDeveloper = NO;
        _startSuccessful = NO;
        _initializedMessageTemplates = NO;
        _actionManager = nil;
        _deviceId = nil;
        _userAttributeChanges = [NSMutableArray array];
        _stripViewControllerFromState = NO;
        _calledHandleNotification = NO;
    }
    return self;
}

@end


#pragma mark - The rest of the Leanplum SDK

static NSString *leanplum_deviceId = nil;
static NSString *registrationEmail = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
__weak static NSExtensionContext *_extensionContext = nil;
#else
__weak static id *_extensionContext = nil;
#endif
static LeanplumPushSetupBlock pushSetupBlock;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@implementation NSExtensionContext (Leanplum)

- (void)leanplum_completeRequestReturningItems:(NSArray *)items
                             completionHandler:(void(^)(BOOL expired))completionHandler
{
    [self leanplum_completeRequestReturningItems:items completionHandler:completionHandler];
    LP_TRY
    [Leanplum pause];
    LP_END_TRY
}

- (void)leanplum_cancelRequestWithError:(NSError *)error
{
    [self leanplum_cancelRequestWithError:error];
    LP_TRY
    [Leanplum pause];
    LP_END_TRY
}

@end
#endif

void leanplumExceptionHandler(NSException *exception);

BOOL printedCallbackWarning = NO;
BOOL inForeground = NO;

@implementation Leanplum

+ (void)throwError:(NSString *)reason
{
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        @throw([NSException
            exceptionWithName:@"Leanplum Error"
                       reason:[NSString stringWithFormat:@"Leanplum: %@ This error is only thrown "
                                                         @"in development mode.", reason]
                     userInfo:nil]);
    } else {
        NSLog(@"Leanplum: Error: %@", reason);
    }
}

// _initPush is a hidden method so that Unity can do swizzling early enough

+ (void)_initPush
{
    [LPActionManager sharedManager];
}

+ (void)setApiHostName:(NSString *)hostName
       withServletName:(NSString *)servletName
              usingSsl:(BOOL)ssl
{
    if ([Utils isNullOrEmpty:hostName]) {
        [self throwError:@"[Leanplum setApiHostName:withServletName:usingSsl:] Empty hostname "
         @"parameter provided."];
        return;
    }
    if ([Utils isNullOrEmpty:servletName]) {
        [self throwError:@"[Leanplum setApiHostName:withServletName:usingSsl:] Empty servletName "
         @"parameter provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].apiHostName = hostName;
    [LPConstantsState sharedState].apiServlet = servletName;
    [LPConstantsState sharedState].apiSSL = ssl;
    LP_END_TRY
}

+ (void)setSocketHostName:(NSString *)hostName withPortNumber:(int)port
{
    if ([Utils isNullOrEmpty:hostName]) {
        [self throwError:@"[Leanplum setSocketHostName:withPortNumber] Empty hostname parameter "
         @"provided."];
        return;
    }

    [LPConstantsState sharedState].socketHost = hostName;
    [LPConstantsState sharedState].socketPort = port;
}

+ (void)setClient:(NSString *)client withVersion:(NSString *)version
{
    [LPConstantsState sharedState].client = client;
    [LPConstantsState sharedState].sdkVersion = version;
}

+ (void)setFileHashingEnabledInDevelopmentMode:(BOOL)enabled
{
    LP_TRY
    [LPConstantsState sharedState].checkForUpdatesInDevelopmentMode = enabled;
    LP_END_TRY
}

+ (void)setVerboseLoggingInDevelopmentMode:(BOOL)enabled
{
    LP_TRY
    [LPConstantsState sharedState].verboseLoggingInDevelopmentMode = enabled;
    LP_END_TRY
}

+ (void)setNetworkTimeoutSeconds:(int)seconds
{
    if (seconds < 0) {
        [self throwError:@"[Leanplum setNetworkTimeoutSeconds:] Invalid seconds parameter "
         @"provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].networkTimeoutSeconds = seconds;
    [LPConstantsState sharedState].networkTimeoutSecondsForDownloads = seconds;
    LP_END_TRY
}

+ (void)setNetworkTimeoutSeconds:(int)seconds forDownloads:(int)downloadSeconds
{
    if (seconds < 0) {
        [self throwError:@"[Leanplum setNetworkTimeoutSeconds:forDownloads:] Invalid seconds "
         @"parameter provided."];
        return;
    }
    if (downloadSeconds < 0) {
        [self throwError:@"[Leanplum setNetworkTimeoutSeconds:forDownloads:] Invalid "
         @"downloadSeconds parameter provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].networkTimeoutSeconds = seconds;
    [LPConstantsState sharedState].networkTimeoutSecondsForDownloads = downloadSeconds;
    LP_END_TRY
}

+ (void)setNetworkActivityIndicatorEnabled:(BOOL)enabled
{
    LP_TRY
    [LPConstantsState sharedState].networkActivityIndicatorEnabled = enabled;
    LP_END_TRY
}

+ (void)setCanDownloadContentMidSessionInProductionMode:(BOOL)value
{
    LP_TRY
    [LPConstantsState sharedState].canDownloadContentMidSessionInProduction = value;
    LP_END_TRY
}

+ (BOOL)isRichPushEnabled
{
    NSString *plugInsPath = [NSBundle mainBundle].builtInPlugInsPath;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
                                         enumeratorAtPath:plugInsPath];
    NSString *filePath;
    while (filePath = [enumerator nextObject]) {
        if([filePath hasSuffix:@".appex/Info.plist"]) {
            NSString *newPath = [[plugInsPath stringByAppendingPathComponent:filePath]
                                 stringByDeletingLastPathComponent];
            NSBundle *currentBundle = [NSBundle bundleWithPath:newPath];
            NSDictionary *extensionKey =
                [currentBundle objectForInfoDictionaryKey:@"NSExtension"];
            if ([[extensionKey objectForKey:@"NSExtensionPrincipalClass"]
                 isEqualToString:@"NotificationService"]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (void)setInAppPurchaseEventName:(NSString *)event
{
    if ([Utils isNullOrEmpty:event]) {
        [self throwError:@"[Leanplum setInAppPurchaseEventName:] Empty event parameter provided."];
        return;
    }

    LP_TRY
    [LPRevenueManager sharedManager].eventName = event;
    LP_END_TRY
}

+ (void)setAppId:(NSString *)appId withDevelopmentKey:(NSString *)accessKey
{
    if ([Utils isNullOrEmpty:appId]) {
        [self throwError:@"[Leanplum setAppId:withDevelopmentKey:] Empty appId parameter "
         @"provided."];
        return;
    }
    if ([Utils isNullOrEmpty:accessKey]) {
        [self throwError:@"[Leanplum setAppId:withDevelopmentKey:] Empty accessKey parameter "
         @"provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].isDevelopmentModeEnabled = YES;
    [LeanplumRequest setAppId:appId withAccessKey:accessKey];
    LP_END_TRY
}

+ (void)setAppVersion:(NSString *)appVersion
{
    LP_TRY
    [LPInternalState sharedState].appVersion = appVersion;
    LP_END_TRY
}

+ (void)setAppId:(NSString *)appId withProductionKey:(NSString *)accessKey
{
    if ([Utils isNullOrEmpty:appId]) {
        [self throwError:@"[Leanplum setAppId:withProductionKey:] Empty appId parameter provided."];
        return;
    }
    if ([Utils isNullOrEmpty:accessKey]) {
        [self throwError:@"[Leanplum setAppId:withProductionKey:] Empty accessKey parameter "
         @"provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].isDevelopmentModeEnabled = NO;
    [LeanplumRequest setAppId:appId withAccessKey:accessKey];
    LP_END_TRY
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
+ (void)setExtensionContext:(NSExtensionContext *)context
{
    LP_TRY
    _extensionContext = context;
    LP_END_TRY
}
#endif

+ (void)allowInterfaceEditing
{
    [self throwError:@"Leanplum UI Editor has moved to separate Pod."
     "Please remove this method call and include this "
     "line in your Podfile: pod 'Leanplum-iOS-UIEditor'"];
}

+ (BOOL)interfaceEditingEnabled
{
    [self throwError:@"Leanplum UI Editor has moved to separate Pod."
     "Please remove this method call and include this "
     "line in your Podfile: pod 'Leanplum-iOS-UIEditor'"];
    return NO;
}

+ (void)setDeviceId:(NSString *)deviceId
{
    if ([Utils isBlank:deviceId]) {
        [self throwError:@"[Leanplum setDeviceId:] Empty deviceId parameter provided."];
        return;
    }
    if ([deviceId isEqualToString:LP_INVALID_IDFA]) {
        [self throwError:[NSString stringWithFormat:@"[Leanplum setDeviceId:] Failed to set '%@' "
                          "as deviceId. You are most likely attempting to use the IDFA as deviceId "
                          "when the user has limited ad tracking on iOS10 or above.",
                          LP_INVALID_IDFA]];
        return;
    }
    LP_TRY
    [LPInternalState sharedState].deviceId = deviceId;
    LP_END_TRY
}

+ (void)syncResources
{
    [self syncResourcesAsync:NO];
}

+ (void)syncResourcesAsync:(BOOL)async
{
    LP_TRY
    [LPFileManager initAsync:async];
    LP_END_TRY
}

+ (void)syncResourcePaths:(NSArray *)patternsToIncludeOrNil
                excluding:(NSArray *)patternsToExcludeOrNil
{
    [self syncResourcePaths:patternsToIncludeOrNil excluding:patternsToExcludeOrNil async:NO];
}

+ (void)syncResourcePaths:(NSArray *)patternsToIncludeOrNil
                excluding:(NSArray *)patternsToExcludeOrNil
                    async:(BOOL)async
{
    LP_TRY
    [LPFileManager initWithInclusions:patternsToIncludeOrNil andExclusions:patternsToExcludeOrNil
                                async:async];
    LP_END_TRY
}

+ (void)synchronizeDefaults
{
    static dispatch_queue_t queue = NULL;
    if (!queue) {
        queue = dispatch_queue_create("com.leanplum.defaultsSyncQueue", NULL);
    }
    static BOOL isSyncing = NO;
    if (isSyncing) {
        return;
    }
    isSyncing = YES;
    dispatch_async(queue, ^{
        isSyncing = NO;
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

+ (NSString *)pushTokenKey
{
    return [NSString stringWithFormat: LEANPLUM_DEFAULTS_PUSH_TOKEN_KEY,
            LeanplumRequest.appId, LeanplumRequest.userId, LeanplumRequest.deviceId];
}

+ (void)start
{
    [self startWithUserId:nil userAttributes:nil responseHandler:nil];
}

+ (void)startWithResponseHandler:(LeanplumStartBlock)response
{
    [self startWithUserId:nil userAttributes:nil responseHandler:response];
}

+ (void)startWithUserAttributes:(NSDictionary *)attributes
{
    [self startWithUserId:nil userAttributes:attributes responseHandler:nil];
}

+ (void)startWithUserId:(NSString *)userId
{
    [self startWithUserId:userId userAttributes:nil responseHandler:nil];
}

+ (void)startWithUserId:(NSString *)userId responseHandler:(LeanplumStartBlock)response
{
    [self startWithUserId:userId userAttributes:nil responseHandler:response];
}

+ (void)startWithUserId:(NSString *)userId userAttributes:(NSDictionary *)attributes
{
    [self startWithUserId:userId userAttributes:attributes responseHandler:nil];
}

+ (void)triggerStartIssued
{
    [LPInternalState sharedState].issuedStart = YES;
    for (LeanplumStartIssuedBlock block in [LPInternalState sharedState].startIssuedBlocks.copy) {
        block();
    }
    [[LPInternalState sharedState].startIssuedBlocks removeAllObjects];
}

+ (void)triggerStartResponse:(BOOL)success
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState].startResponders.copy) {
        [invocation setArgument:&success atIndex:2];
        [invocation invoke];
    }

    for (LeanplumStartBlock block in [LPInternalState sharedState].startBlocks.copy) {
        block(success);
    }
    LP_END_USER_CODE
    [[LPInternalState sharedState].startResponders removeAllObjects];
    [[LPInternalState sharedState].startBlocks removeAllObjects];
}

+ (void)triggerVariablesChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState]
            .variablesChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumVariablesChangedBlock block in [LPInternalState sharedState]
             .variablesChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerInterfaceChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState]
             .interfaceChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumInterfaceChangedBlock block in [LPInternalState sharedState]
             .interfaceChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerEventsChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState].eventsChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumEventsChangedBlock block in [LPInternalState sharedState]
             .eventsChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerVariablesChangedAndNoDownloadsPending
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState].noDownloadsResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumVariablesChangedBlock block in [LPInternalState sharedState]
             .noDownloadsBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
    NSArray *onceNoDownloadsBlocksCopy;
    @synchronized ([LPInternalState sharedState].onceNoDownloadsBlocks) {
        onceNoDownloadsBlocksCopy = [LPInternalState sharedState].onceNoDownloadsBlocks.copy;
        [[LPInternalState sharedState].onceNoDownloadsBlocks removeAllObjects];
    }
    LP_BEGIN_USER_CODE
    for (LeanplumVariablesChangedBlock block in onceNoDownloadsBlocksCopy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerAction:(LPActionContext *)context
{
    [self triggerAction:context handledBlock:nil];
}

+ (void)triggerAction:(LPActionContext *)context handledBlock:(LeanplumHandledBlock)handledBlock
{
    LeanplumVariablesChangedBlock triggerBlock = ^{
        BOOL handled = NO;
        LP_BEGIN_USER_CODE
        for (NSInvocation *invocation in [[LPInternalState sharedState].actionResponders
                                          objectForKey:context.actionName]) {
            [invocation setArgument:(void *)&context atIndex:2];
            [invocation invoke];
            BOOL invocationHandled = NO;
            [invocation getReturnValue:&invocationHandled];
            handled |= invocationHandled;
        }

        for (LeanplumActionBlock block in [LPInternalState sharedState].actionBlocks
                                           [context.actionName]) {
            handled |= block(context);
        }
        LP_END_USER_CODE

        if (handledBlock) {
            handledBlock(handled);
        }
    };

    if ([context hasMissingFiles]) {
        [Leanplum onceVariablesChangedAndNoDownloadsPending:triggerBlock];
    } else {
        triggerBlock();
    }
}

+ (void)setDeveloperEmail:(NSString *)email __deprecated
{
    registrationEmail = email;
}

+ (void)onHasStartedAndRegisteredAsDeveloper
{
    if ([LPFileManager initializing]) {
        [LPFileManager setResourceSyncingReady:^{
            [self onHasStartedAndRegisteredAsDeveloperAndFinishedSyncing];
        }];
    } else {
        [self onHasStartedAndRegisteredAsDeveloperAndFinishedSyncing];
    }
}

+ (void)onHasStartedAndRegisteredAsDeveloperAndFinishedSyncing
{
    if (![LPInternalState sharedState].hasStartedAndRegisteredAsDeveloper) {
        [LPInternalState sharedState].hasStartedAndRegisteredAsDeveloper = YES;
    }
}

+ (NSDictionary *)validateAttributes:(NSDictionary *)attributes named:(NSString *)argName
                          allowLists:(BOOL)allowLists
{
    NSMutableDictionary *validAttributes = [NSMutableDictionary dictionary];
    for (id key in attributes) {
        if (![key isKindOfClass:NSString.class]) {
            [self throwError:[NSString stringWithFormat:
                              @"%@ keys must be of type NSString.", argName]];
            continue;
        }
        id value = attributes[key];
        if (allowLists &&
            ([value isKindOfClass:NSArray.class] ||
             [value isKindOfClass:NSSet.class])) {
            BOOL valid = YES;
            for (id item in value) {
                if (![self validateScalarValue:item argName:argName]) {
                    valid = NO;
                    break;
                }
            }
            if (!valid) {
                continue;
            }
        } else {
            if ([value isKindOfClass:NSDate.class]) {
                value = [NSNumber numberWithUnsignedLongLong:
                         [(NSDate *) value timeIntervalSince1970] * 1000];
            }
            if (![self validateScalarValue:value argName:argName]) {
                continue;
            }
        }
        validAttributes[key] = value;
    }
    return validAttributes;
}

+ (BOOL)validateScalarValue:(id)value argName:(NSString *)argName
{
    if (![value isKindOfClass:NSString.class] &&
        ![value isKindOfClass:NSNumber.class] &&
        ![value isKindOfClass:NSNull.class]) {
        [self throwError:[NSString stringWithFormat:
                          @"%@ values must be of type NSString, NSNumber, or NSNull.", argName]];
        return NO;
    }
    if ([value isKindOfClass:NSNumber.class]) {
        if ([value isEqualToNumber:[NSDecimalNumber notANumber]]) {
            [self throwError:[NSString stringWithFormat:
                              @"%@ values must not be [NSDecimalNumber notANumber].", argName]];
            return NO;
        }
    }
    return YES;
}

+ (void)reset
{
    LPInternalState *state = [LPInternalState sharedState];
    state.calledStart = NO;
    state.hasStarted = NO;
    state.hasStartedAndRegisteredAsDeveloper = NO;
    state.startSuccessful = NO;
    [state.startBlocks removeAllObjects];
    [state.startResponders removeAllObjects];
    [state.actionBlocks removeAllObjects];
    [state.actionResponders removeAllObjects];
    [state.variablesChangedBlocks removeAllObjects];
    [state.interfaceChangedBlocks removeAllObjects];
    [state.eventsChangedBlocks removeAllObjects];
    [state.variablesChangedResponders removeAllObjects];
    [state.interfaceChangedResponders removeAllObjects];
    [state.eventsChangedResponders removeAllObjects];
    [state.noDownloadsBlocks removeAllObjects];
    [state.onceNoDownloadsBlocks removeAllObjects];
    [state.noDownloadsResponders removeAllObjects];
    [state.userAttributeChanges removeAllObjects];
    state.calledHandleNotification = NO;

    [[LPInbox sharedState] reset];
}

+ (NSString *)platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);

    if ([results isEqualToString:@"i386"] ||
        [results isEqualToString:@"x86_64"]) {
        results = [[UIDevice currentDevice] model];
    }

    return results;
}

+ (void)startWithUserId:(NSString *)userId
         userAttributes:(NSDictionary *)attributes
        responseHandler:(LeanplumStartBlock)startResponse
{
    if ([LeanplumRequest appId] == nil) {
        [self throwError:@"Please provide your app ID using one of the [Leanplum setAppId:] "
         @"methods."];
        return;
    }
    LP_TRY
    NSDate *startTime = [NSDate date];
    if (startResponse) {
        [self onStartResponse:startResponse];
    }
    LPInternalState *state = [LPInternalState sharedState];
    if (IS_NOOP) {
        state.hasStarted = YES;
        state.startSuccessful = YES;
        [LPVarCache applyVariableDiffs:@{} messages:@{} updateRules:@[] eventRules:@[]
                              variants:@[] regions:@{}];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self triggerStartResponse:YES];
            [self triggerVariablesChanged];
            [self triggerInterfaceChanged];
            [self triggerEventsChanged];
            [self triggerVariablesChangedAndNoDownloadsPending];
            [[self inbox] updateMessages:[[NSMutableDictionary alloc] init] unreadCount:0];
        });
        return;
    }

    if (state.calledStart) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        // With iOS extensions, Leanplum may already be loaded when the extension runs.
        // This is because Leanplum can stay loaded when the extension is opened and closed
        // multiple times.
        if (_extensionContext) {
            [Leanplum resume];
            return;
        }
#endif
        [self throwError:@"Already called start."];
    }

    state.initializedMessageTemplates = YES;
    [LPMessageTemplatesClass sharedTemplates];
    attributes = [self validateAttributes:attributes named:@"userAttributes" allowLists:YES];
    if (attributes != nil) {
        [state.userAttributeChanges addObject:attributes];
    }
    state.calledStart = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [Leanplum trackCrashes];
    });
    state.actionManager = [LPActionManager sharedManager];

    [LeanplumRequest loadToken];
    [LPVarCache setSilent:YES];
    [LPVarCache loadDiffs];
    [LPVarCache setSilent:NO];
    [[self inbox] load];

    // Setup class members.
    [LPVarCache onUpdate:^{
        [self triggerVariablesChanged];

        if (LeanplumRequest.numPendingDownloads == 0) {
            [self triggerVariablesChangedAndNoDownloadsPending];
        }
    }];
    [LPVarCache onInterfaceUpdate:^{
        [self triggerInterfaceChanged];
    }];
    [LPVarCache onEventsUpdate:^{
        [self triggerEventsChanged];
    }];
    [LeanplumRequest onNoPendingDownloads:^{
        [self triggerVariablesChangedAndNoDownloadsPending];
    }];

    // Set device ID.
    NSString *deviceId = [LeanplumRequest deviceId];
    // This is the device ID set when the MAC address is used on iOS 7.
    // This is to allow apps who upgrade to the new ID to forget the old one.
    if ([deviceId isEqualToString:@"0f607264fc6318a92b9e13c65db7cd3c"]) {
        deviceId = nil;
    }
    if (!deviceId) {
#if IOS_6_SUPPORTED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (state.deviceId) {
            deviceId = state.deviceId;
        } else {
            deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
#endif
#endif
        if (!deviceId) {
            deviceId = [[UIDevice currentDevice] leanplum_uniqueGlobalDeviceIdentifier];
        }
        [LeanplumRequest setDeviceId:deviceId];
    }

    // Set user ID.
    if (!userId) {
        userId = [LeanplumRequest userId];
        if (!userId) {
            userId = [LeanplumRequest deviceId];
        }
    }
    [LeanplumRequest setUserId:userId];

    // Setup parameters.
    NSString *versionName = [LPInternalState sharedState].appVersion;
    if (!versionName) {
        versionName = [[[NSBundle mainBundle] infoDictionary]
                       objectForKey:@"CFBundleVersion"];
    }
    UIDevice *device = [UIDevice currentDevice];
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *currentLocaleString = [NSString stringWithFormat:@"%@_%@",
                                     [[NSLocale preferredLanguages] objectAtIndex:0],
                                     [currentLocale objectForKey:NSLocaleCountryCode]];
    NSString *deviceName = device.name;
    if (!deviceName) {
        deviceName = @"";
    }
    NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
    NSNumber *timezoneOffsetSeconds =
        [NSNumber numberWithInteger:[localTimeZone secondsFromGMTForDate:[NSDate date]]];
    NSMutableDictionary *params = [@{
        LP_PARAM_INCLUDE_DEFAULTS: @(NO),
        LP_PARAM_VERSION_NAME: versionName,
        LP_PARAM_DEVICE_NAME: deviceName,
        LP_PARAM_DEVICE_MODEL: [self platform],
        LP_PARAM_DEVICE_SYSTEM_NAME: device.systemName,
        LP_PARAM_DEVICE_SYSTEM_VERSION: device.systemVersion,
        LP_KEY_LOCALE: currentLocaleString,
        LP_KEY_TIMEZONE: [localTimeZone name],
        LP_KEY_TIMEZONE_OFFSET_SECONDS: timezoneOffsetSeconds,
        LP_KEY_COUNTRY: LP_VALUE_DETECT,
        LP_KEY_REGION: LP_VALUE_DETECT,
        LP_KEY_CITY: LP_VALUE_DETECT,
        LP_KEY_LOCATION: LP_VALUE_DETECT,
        LP_PARAM_RICH_PUSH_ENABLED: @([self isRichPushEnabled])
    } mutableCopy];
    BOOL startedInBackground = NO;
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground &&
        !_extensionContext) {
        params[LP_PARAM_BACKGROUND] = @(YES);
        startedInBackground = YES;
    }

    if (attributes != nil) {
        params[LP_PARAM_USER_ATTRIBUTES] = attributes ?
                [LPJSON stringFromJSON:attributes] : @"";
    }
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        params[LP_PARAM_DEV_MODE] = @(YES);
    }

    NSDictionary *timeParams = [self initializePreLeanplumInstall];
    if (timeParams) {
        [params addEntriesFromDictionary:timeParams];
    }

    // Get the current Inbox messages on the device.
    params[LP_PARAM_INBOX_MESSAGES] = [self.inbox messagesIds];
    
    // Push token.
    NSString *pushTokenKey = [Leanplum pushTokenKey];
    NSString *pushToken = [[NSUserDefaults standardUserDefaults] stringForKey:pushTokenKey];
    if (pushToken) {
        params[LP_PARAM_DEVICE_PUSH_TOKEN] = pushToken;
    }

    // Issue start API call.
    LeanplumRequest *req = [LeanplumRequest post:LP_METHOD_START params:params];
    [req onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        state.hasStarted = YES;
        state.startSuccessful = YES;
        NSDictionary *values = response[LP_KEY_VARS];
        NSString *token = response[LP_KEY_TOKEN];
        NSDictionary *messages = response[LP_KEY_MESSAGES];
        NSArray *updateRules = response[LP_KEY_UPDATE_RULES];
        NSArray *eventRules = response[LP_KEY_EVENT_RULES];
        NSArray *variants = response[LP_KEY_VARIANTS];
        NSDictionary *regions = response[LP_KEY_REGIONS];
        [LeanplumRequest setToken:token];
        [LeanplumRequest saveToken];
        [LPVarCache applyVariableDiffs:values
                              messages:messages
                           updateRules:updateRules
                            eventRules:eventRules
                              variants:variants
                               regions:regions];

        if ([response[LP_KEY_SYNC_INBOX] boolValue]) {
            [[self inbox] downloadMessages];
        }

        if ([response[LP_KEY_LOGGING_ENABLED] boolValue]) {
            [LPConstantsState sharedState].loggingEnabled = YES;
        }

        // TODO: Need to call this if we fix encryption.
        // [LPVarCache saveUserAttributes];
        [self triggerStartResponse:YES];

        // Allow bidirectional realtime variable updates.
        if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
            // Register device.
            if (registrationEmail && ![response[LP_KEY_IS_REGISTERED] boolValue]) {
                state.registration = [[LPRegisterDevice alloc] initWithCallback:^(BOOL success) {
                                    if (success) {
                                        [Leanplum onHasStartedAndRegisteredAsDeveloper];
                                    }}];
                [state.registration registerDevice:registrationEmail];
            } else if ([response[LP_KEY_IS_REGISTERED_FROM_OTHER_APP] boolValue]) {
                // Show if registered from another app ID.
                [LPUIAlert showWithTitle:@"Leanplum"
                                 message:@"Your device is registered."
                       cancelButtonTitle:NSLocalizedString(@"OK", nil)
                       otherButtonTitles:nil
                                   block:nil];
            } else {
                // Check for updates.
                NSString *latestVersion = response[LP_KEY_LATEST_VERSION];
                if (latestVersion) {
                    NSLog(@"Leanplum: A newer version of the SDK, %@, is available. Please go to "
                          @"leanplum.com to download it.", latestVersion);
                }
            }

            NSDictionary *valuesFromCode = response[LP_KEY_VARS_FROM_CODE];
            NSDictionary *actionDefinitions = response[LP_PARAM_ACTION_DEFINITIONS];
            NSDictionary *fileAttributes = response[LP_PARAM_FILE_ATTRIBUTES];

            [LeanplumRequest setUploadUrl:response[LP_KEY_UPLOAD_URL]];
            [LPVarCache setDevModeValuesFromServer:valuesFromCode
                                    fileAttributes:fileAttributes
                                 actionDefinitions:actionDefinitions];
            [[LeanplumSocket sharedSocket] connectToAppId:LeanplumRequest.appId
                                                 deviceId:LeanplumRequest.deviceId];
            if ([response[LP_KEY_IS_REGISTERED] boolValue]) {
                [Leanplum onHasStartedAndRegisteredAsDeveloper];
            }
        } else {
            // Report latency for 0.1% of users.
            NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:startTime];
            if (arc4random() % 1000 == 0) {
                [[LeanplumRequest post:LP_METHOD_LOG
                               params:@{
                                        LP_PARAM_TYPE: LP_VALUE_SDK_START_LATENCY,
                                        @"startLatency": [@(latency) description]
                                        }] send];
            }
        }

        // Upload alternative app icons.
        [LPAppIconManager uploadAppIconsOnDevMode];

        if (!startedInBackground) {
            inForeground = YES;
            [self maybePerformActions:@[@"start", @"resume"]
                        withEventName:nil
                           withFilter:kLeanplumActionFilterAll
                        fromMessageId:nil
                 withContextualValues:nil];
            [self recordAttributeChanges];
        }
        LP_END_TRY
    }];
    [req onError:^(NSError *err) {
        LP_TRY
        state.hasStarted = YES;
        state.startSuccessful = NO;

        // Load the variables that were stored on the device from the last session.
        [LPVarCache loadDiffs];
        LP_END_TRY

        [self triggerStartResponse:NO];
    }];
    [req sendIfConnected];
    [self triggerStartIssued];

    // Pause.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidEnterBackgroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                    RETURN_IF_NOOP;
                    LP_TRY
                    if (![[[[NSBundle mainBundle] infoDictionary]
                            objectForKey:@"UIApplicationExitsOnSuspend"] boolValue]) {
                        [Leanplum pause];
                    }
                    LP_END_TRY
                }];

    // Resume.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                    RETURN_IF_NOOP;
                    LP_TRY
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && LP_NOT_TV
                    if ([[UIApplication sharedApplication]
                            respondsToSelector:@selector(currentUserNotificationSettings)]) {
                        [[LPActionManager sharedManager] sendUserNotificationSettingsIfChanged:
                                                             [[UIApplication sharedApplication]
                                                                 currentUserNotificationSettings]];
                    }
#endif
                    [Leanplum resume];
                    if (startedInBackground && !inForeground) {
                        inForeground = YES;
                        [self maybePerformActions:@[@"start", @"resume"]
                                    withEventName:nil
                                       withFilter:kLeanplumActionFilterAll
                                    fromMessageId:nil
                             withContextualValues:nil];
                        [self recordAttributeChanges];
                    } else {
                        [self maybePerformActions:@[@"resume"]
                                    withEventName:nil
                                       withFilter:kLeanplumActionFilterAll
                                    fromMessageId:nil
                             withContextualValues:nil];
                    }
                    LP_END_TRY
                }];

    // Stop.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillTerminateNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                    RETURN_IF_NOOP;
                    LP_TRY
                    BOOL exitOnSuspend = [[[[NSBundle mainBundle] infoDictionary]
                        objectForKey:@"UIApplicationExitsOnSuspend"] boolValue];
                    [[LeanplumRequest post:LP_METHOD_STOP params:nil]
                        sendIfConnectedSync:exitOnSuspend];
                    LP_END_TRY
                }];

    // Heartbeat.
    [LPTimerBlocks scheduledTimerWithTimeInterval:HEARTBEAT_INTERVAL block:^() {
        RETURN_IF_NOOP;
        LP_TRY
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            [[LeanplumRequest post:LP_METHOD_HEARTBEAT params:nil] sendIfDelayed];
        }
        LP_END_TRY
    } repeats:YES];

    // Extension close.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (_extensionContext) {
        [LPSwizzle
            swizzleMethod:@selector(completeRequestReturningItems:completionHandler:)
               withMethod:@selector(leanplum_completeRequestReturningItems:completionHandler:)
                    error:nil
                    class:[NSExtensionContext class]];
        [LPSwizzle swizzleMethod:@selector(cancelRequestWithError:)
                      withMethod:@selector(leanplum_cancelRequestWithError:)
                           error:nil
                           class:[NSExtensionContext class]];
    }
#endif
    [self maybeRegisterForNotifications];
    LP_END_TRY
}

// On first run with Leanplum, determine if this app was previously installed without Leanplum.
// This is useful for detecting if the user may have already rejected notifications.
+ (NSDictionary *)initializePreLeanplumInstall
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[[defaults dictionaryRepresentation] allKeys]
            containsObject:LEANPLUM_DEFAULTS_PRE_LEANPLUM_INSTALL_KEY]) {
        return nil;
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *urlToDocumentsFolder = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                           inDomains:NSUserDomainMask] lastObject];
        __autoreleasing NSError *error;
        NSDate *installDate =
            [[fileManager attributesOfItemAtPath:urlToDocumentsFolder.path error:&error]
                objectForKey:NSFileCreationDate];
        NSString *pathToInfoPlist = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSString *pathToAppBundle = [pathToInfoPlist stringByDeletingLastPathComponent];
        NSDate *updateDate = [[fileManager attributesOfItemAtPath:pathToAppBundle error:&error]
            objectForKey:NSFileModificationDate];

        // Considered pre-Leanplum install if its been more than a day (86400 seconds) since
        // install.
        NSTimeInterval secondsBetween = [updateDate timeIntervalSinceDate:installDate];
        [[NSUserDefaults standardUserDefaults] setBool:(secondsBetween > 86400)
                                                forKey:LEANPLUM_DEFAULTS_PRE_LEANPLUM_INSTALL_KEY];
        return @{
            LP_PARAM_INSTALL_DATE:
                [NSString stringWithFormat:@"%f", [installDate timeIntervalSince1970]],
            LP_PARAM_UPDATE_DATE:
                [NSString stringWithFormat:@"%f", [updateDate timeIntervalSince1970]]
        };
    }
}

// If the app has already accepted notifications, register for this instance of the app and trigger
// sending push tokens to server.
+ (void)maybeRegisterForNotifications
{
#if LP_NOT_TV
    Class userMessageTemplatesClass = NSClassFromString(@"LPMessageTemplates");
    if (userMessageTemplatesClass
        && [[userMessageTemplatesClass sharedTemplates]
            respondsToSelector:@selector(refreshPushPermissions)]) {
        [[userMessageTemplatesClass sharedTemplates] refreshPushPermissions];
    } else {
        [[LPMessageTemplatesClass sharedTemplates] refreshPushPermissions];
    }
#endif
}

+ (void)pause
{
    UIApplication *application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier __block backgroundTask;
    
    // Block that finish task.
    void (^finishTaskHandler)() = ^(){
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    };
    
    // Start background task to make sure it runs when the app is in background.
    backgroundTask = [application beginBackgroundTaskWithExpirationHandler:finishTaskHandler];
    
    // Send pause event.
    LeanplumRequest *request = [LeanplumRequest post:LP_METHOD_PAUSE_SESSION params:nil];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        finishTaskHandler();
    }];
    [request onError:^(NSError *error) {
        finishTaskHandler();
    }];
    [request sendIfConnected];
}

+ (void)resume
{
    [[LeanplumRequest post:LP_METHOD_RESUME_SESSION params:nil] sendIfDelayed];
}

+ (void)trackCrashes
{
    LP_TRY
    Class crittercism = NSClassFromString(@"Crittercism");
    SEL selector = NSSelectorFromString(@"didCrashOnLastLoad:");
    if (crittercism && [crittercism respondsToSelector:selector]) {
        IMP imp = [crittercism methodForSelector:selector];
        BOOL (*func)(id, SEL) = (void *)imp;
        BOOL didCrash = func(crittercism, selector);
        if (didCrash) {
            [Leanplum track:@"Crash"];
        }
    }
    LP_END_TRY
}

+ (BOOL)hasStarted
{
    LP_TRY
    return [LPInternalState sharedState].hasStarted;
    LP_END_TRY
    return NO;
}

+ (BOOL)hasStartedAndRegisteredAsDeveloper
{
    LP_TRY
    return [LPInternalState sharedState].hasStartedAndRegisteredAsDeveloper;
    LP_END_TRY
    return NO;
}

+ (NSInvocation *)createInvocationWithResponder:(id)responder selector:(SEL)selector
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [responder methodSignatureForSelector:selector]];
    invocation.target = responder;
    invocation.selector = selector;
    return invocation;
}

+ (void)addInvocation:(NSInvocation *)invocation toSet:(NSMutableSet *)responders
{
    for (NSInvocation *savedResponder in responders) {
        if (savedResponder.target == invocation.target &&
           savedResponder.selector == invocation.selector) {
            return;
        }
    }
    [responders addObject:invocation];
}

+ (void)removeResponder:(id)responder withSelector:(SEL)selector fromSet:(NSMutableSet *)responders
{
    LP_TRY
    for (NSInvocation *invocation in responders.copy) {
        if (invocation.target == responder && invocation.selector == selector) {
            [responders removeObject:invocation];
        }
    }
    LP_END_TRY
}

+ (void)onStartIssued:(LeanplumStartIssuedBlock)block
{
    if ([LPInternalState sharedState].issuedStart) {
        block();
    } else {
        if (![LPInternalState sharedState].startIssuedBlocks) {
            [LPInternalState sharedState].startIssuedBlocks = [NSMutableArray array];
        }
        [[LPInternalState sharedState].startIssuedBlocks addObject:[block copy]];
    }
}

+ (void)onStartResponse:(LeanplumStartBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onStartResponse:] Nil block parameter provided."];
        return;
    }

    if ([LPInternalState sharedState].hasStarted) {
        block([LPInternalState sharedState].startSuccessful);
    } else {
        LP_TRY
        if (![LPInternalState sharedState].startBlocks) {
            [LPInternalState sharedState].startBlocks = [NSMutableArray array];
        }
        [[LPInternalState sharedState].startBlocks addObject:[block copy]];
        LP_END_TRY
    }
}

+ (void)addStartResponseResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum addStartResponseResponder:withSelector:] Empty responder "
         @"parameter provided."];
        return;
    }
    if (!selector) {
        [self throwError:@"[Leanplum addStartResponseResponder:withSelector:] Empty selector "
         @"parameter provided."];
        return;
    }

    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    if ([LPInternalState sharedState].hasStarted) {
        BOOL startSuccessful = [LPInternalState sharedState].startSuccessful;
        [invocation setArgument:&startSuccessful atIndex:2];
        [invocation invoke];
    } else {
        LP_TRY
        if (![LPInternalState sharedState].startResponders) {
            [LPInternalState sharedState].startResponders = [NSMutableSet set];
        }
        [self addInvocation:invocation toSet:[LPInternalState sharedState].startResponders];
        LP_END_TRY
    }
}

+ (void)removeStartResponseResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].startResponders];
}

+ (void)onVariablesChanged:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onVariablesChanged:] Nil block parameter provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].variablesChangedBlocks) {
        [LPInternalState sharedState].variablesChangedBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].variablesChangedBlocks addObject:[block copy]];
    LP_END_TRY
    if ([LPVarCache hasReceivedDiffs]) {
        block();
    }
}

+ (void)onInterfaceChanged:(LeanplumInterfaceChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onStartResponse:] Nil block parameter provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].interfaceChangedBlocks) {
        [LPInternalState sharedState].interfaceChangedBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].interfaceChangedBlocks addObject:[block copy]];
    LP_END_TRY
    if ([LPVarCache hasReceivedDiffs]) {
        block();
    }
}

+ (void)onEventsChanged:(LeanplumEventsChangedBlock)block
{
    if (![LPInternalState sharedState].eventsChangedBlocks) {
        [LPInternalState sharedState].eventsChangedBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].eventsChangedBlocks addObject:[block copy]];
    if ([LPVarCache hasReceivedDiffs]) {
        block();
    }
}

+ (void)addVariablesChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil block "
         @"parameter provided."];
        return;
    }
    if (!selector) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil selector "
         @"parameter provided."];
        return;
    }

    if (![LPInternalState sharedState].variablesChangedResponders) {
        [LPInternalState sharedState].variablesChangedResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].variablesChangedResponders];
    if ([LPVarCache hasReceivedDiffs]) {
        [invocation invoke];
    }
}

+ (void)addInterfaceChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil block "
         @"parameter provided."];
        return;
    }
    if (!selector) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil selector "
         @"parameter provided."];
        return;
    }

    if (![LPInternalState sharedState].interfaceChangedResponders) {
        [LPInternalState sharedState].interfaceChangedResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].interfaceChangedResponders];
    if ([LPVarCache hasReceivedDiffs] && invocation) {
        [invocation invoke];
    }
}

+ (void)addEventsChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (![LPInternalState sharedState].eventsChangedResponders) {
        [LPInternalState sharedState].eventsChangedResponders = [NSMutableSet set];
    }

    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].eventsChangedResponders];
    if ([LPVarCache hasReceivedDiffs] && invocation) {
        [invocation invoke];
    }
}

+ (void)removeVariablesChangedResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].variablesChangedResponders];
}

+ (void)removeInterfaceChangedResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].interfaceChangedResponders];
}

+ (void)removeEventsChangedResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].eventsChangedResponders];
}

+ (void)onVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onVariablesChangedAndNoDownloadsPending:] Nil block parameter "
         @"provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].noDownloadsBlocks) {
        [LPInternalState sharedState].noDownloadsBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].noDownloadsBlocks addObject:[block copy]];
    LP_END_TRY
    if ([LPVarCache hasReceivedDiffs] && LeanplumRequest.numPendingDownloads == 0) {
        block();
    }
}

+ (void)onceVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onceVariablesChangedAndNoDownloadsPending:] Nil block "
         @"parameter provided."];
        return;
    }

    if ([LPVarCache hasReceivedDiffs] && LeanplumRequest.numPendingDownloads == 0) {
        block();
    } else {
        LP_TRY
        static dispatch_once_t onceNoDownloadsBlocksToken;
        dispatch_once(&onceNoDownloadsBlocksToken, ^{
            [LPInternalState sharedState].onceNoDownloadsBlocks = [NSMutableArray array];
        });
        @synchronized ([LPInternalState sharedState].onceNoDownloadsBlocks) {
            [[LPInternalState sharedState].onceNoDownloadsBlocks addObject:[block copy]];
        }
        LP_END_TRY
    }
}

+ (void)addVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum "
         @"addVariablesChangedAndNoDownloadsPendingResponder:withSelector:] Nil "
         @"responder parameter provided."];
    }
    if (!selector) {
        [self throwError:@"[Leanplum onceVariablesChangedAndNoDownloadsPending:] Nil selector "
         @"parameter provided."];
    }

    if (![LPInternalState sharedState].noDownloadsResponders) {
        [LPInternalState sharedState].noDownloadsResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].noDownloadsResponders];
    if ([LPVarCache hasReceivedDiffs]
        && LeanplumRequest.numPendingDownloads == 0) {
        [invocation invoke];
    }
}

+ (void)removeVariablesChangedAndNoDownloadsPendingResponder:(id)responder
                                                withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].noDownloadsResponders];
}

+ (void)defineAction:(NSString *)name
              ofKind:(LeanplumActionKind)kind
       withArguments:(NSArray *)args
{
    [self defineAction:name ofKind:kind withArguments:args withOptions:@{} withResponder:nil];
}

+ (void)defineAction:(NSString *)name
              ofKind:(LeanplumActionKind)kind
       withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options
{
    [self defineAction:name ofKind:kind withArguments:args withOptions:options withResponder:nil];
}

+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
       withResponder:(LeanplumActionBlock)responder
{
    [self defineAction:name ofKind:kind withArguments:args withOptions:@{} withResponder:responder];
}

+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options
       withResponder:(LeanplumActionBlock)responder
{
    if ([Utils isNullOrEmpty:name]) {
        [self throwError:@"[Leanplum defineAction:ofKind:withArguments:] Empty name parameter "
         @"provided."];
        return;
    }
    if (!kind) {
        [self throwError:@"[Leanplum defineAction:ofKind:withArguments:] Nil kind parameter "
         @"provided."];
        return;
    }
    if (!args) {
        [self throwError:@"[Leanplum defineAction:ofKind:withArguments:] Nil args parameter "
         @"provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].initializedMessageTemplates) {
        [LPInternalState sharedState].initializedMessageTemplates = YES;
        [LPMessageTemplatesClass sharedTemplates];
    }
    [[LPInternalState sharedState].actionBlocks removeObjectForKey:name];
    [LPVarCache registerActionDefinition:name ofKind:kind withArguments:args andOptions:options];
    if (responder) {
        [Leanplum onAction:name invoke:responder];
    }
    LP_END_TRY
}

+ (void)onAction:(NSString *)actionName invoke:(LeanplumActionBlock)block
{
    if ([Utils isNullOrEmpty:actionName]) {
        [self throwError:@"[Leanplum onAction:invoke:] Empty actionName parameter provided."];
        return;
    }
    if (!block) {
        [self throwError:@"[Leanplum onAction:invoke::] Nil block parameter provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].actionBlocks) {
        [LPInternalState sharedState].actionBlocks = [NSMutableDictionary dictionary];
    }
    NSMutableArray *blocks = [LPInternalState sharedState].actionBlocks[actionName];
    if (!blocks) {
        blocks = [NSMutableArray array];
        [LPInternalState sharedState].actionBlocks[actionName] = blocks;
    }
    [blocks addObject:[block copy]];
    LP_END_TRY
}

+ (void)handleNotification:(NSDictionary *)userInfo
    fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler
{
    LP_TRY
    [LPInternalState sharedState].calledHandleNotification = YES;
    [[LPActionManager sharedManager] didReceiveRemoteNotification:userInfo
                                                       withAction:nil
                                           fetchCompletionHandler:completionHandler];
    LP_END_TRY
}

#if LP_NOT_TV
+ (void)handleActionWithIdentifier:(NSString *)identifier
              forLocalNotification:(UILocalNotification *)notification
                 completionHandler:(void (^)())completionHandler
{
    LP_TRY
    [[LPActionManager sharedManager] didReceiveRemoteNotification:[notification userInfo]
                                                       withAction:identifier
                                           fetchCompletionHandler:completionHandler];
    LP_END_TRY
}
#endif

+ (void)handleActionWithIdentifier:(NSString *)identifier
             forRemoteNotification:(NSDictionary *)notification
                 completionHandler:(void (^)())completionHandler
{
    LP_TRY
    [[LPActionManager sharedManager] didReceiveRemoteNotification:notification
                                                       withAction:identifier
                                           fetchCompletionHandler:completionHandler];
    LP_END_TRY
}

+ (void)setShouldOpenNotificationHandler:(LeanplumShouldHandleNotificationBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum setShouldOpenNotificationHandler:] Nil block parameter "
         @"provided."];
        return;
    }
    LP_TRY
    [[LPActionManager sharedManager] setShouldHandleNotification:block];
    LP_END_TRY
}

+ (void)addResponder:(id)responder withSelector:(SEL)selector forActionNamed:(NSString *)actionName
{
    if (!responder) {
        [self throwError:@"[Leanplum addResponder:withSelector:forActionNamed:] Nil responder "
         @"parameter provided."];
    }
    if (!selector) {
        [self throwError:@"[Leanplum addResponder:withSelector:forActionNamed:] Nil selector "
         @"parameter provided."];
    }

    LP_TRY
    if (![LPInternalState sharedState].actionResponders) {
        [LPInternalState sharedState].actionResponders = [NSMutableDictionary dictionary];
    }
    NSMutableSet *responders =
        [LPInternalState sharedState].actionResponders[actionName];
    if (!responders) {
        responders = [NSMutableSet set];
        [LPInternalState sharedState].actionResponders[actionName] = responders;
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:responders];
    LP_END_TRY
}

+ (void)removeResponder:(id)responder withSelector:(SEL)selector
         forActionNamed:(NSString *)actionName
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].actionResponders[actionName]];
}

+ (void)maybePerformActions:(NSArray *)whenConditions
              withEventName:(NSString *)eventName
                 withFilter:(LeanplumActionFilter)filter
              fromMessageId:(NSString *)sourceMessage
       withContextualValues:(LPContextualValues *)contextualValues
{
    NSDictionary *messages = [LPVarCache messages];
    NSMutableArray *actionContexts = [NSMutableArray array];
    for (NSString *messageId in [messages allKeys]) {
        if (sourceMessage != nil && [messageId isEqualToString:sourceMessage]) {
            continue;
        }
        NSDictionary *messageConfig = messages[messageId];
        NSString *actionType = messageConfig[@"action"];
        if (![actionType isKindOfClass:NSString.class]) {
            continue;
        }

        NSString *internalMessageId;
        if ([actionType isEqualToString:LP_HELD_BACK_ACTION]) {
            // Spoof the message ID if this is a held back message.
            internalMessageId = [LP_HELD_BACK_MESSAGE_PREFIX stringByAppendingString:messageId];
        } else {
            internalMessageId = messageId;
        }

        // Filter action types that don't match the filtering criteria.
        BOOL isForeground = ![actionType isEqualToString:LP_PUSH_NOTIFICATION_ACTION];
        if (isForeground) {
            if (!(filter & kLeanplumActionFilterForeground)) {
                continue;
            }
        } else {
            if (!(filter & kLeanplumActionFilterBackground)) {
                continue;
            }
        }

        LeanplumMessageMatchResult result = LeanplumMessageMatchResultMake(NO, NO, NO);
        for (NSString *when in whenConditions) {
            LeanplumMessageMatchResult conditionResult =
            [[LPInternalState sharedState].actionManager shouldShowMessage:internalMessageId
                                                                withConfig:messageConfig
                                                                      when:when
                                                             withEventName:eventName
                                                          contextualValues:contextualValues];
            result.matchedTrigger |= conditionResult.matchedTrigger;
            result.matchedUnlessTrigger |= conditionResult.matchedUnlessTrigger;
            result.matchedLimit |= conditionResult.matchedLimit;
        }

        // Make sure we cancel before matching in case the criteria overlap.
        if (result.matchedUnlessTrigger) {
            NSString *cancelActionName = [@"__Cancel" stringByAppendingString:actionType];
            LPActionContext *context = [LPActionContext actionContextWithName:cancelActionName
                                                                         args:@{}
                                                                    messageId:messageId];
            [self triggerAction:context handledBlock:^(BOOL success) {
                if (success) {
                    // Track cancel.
                    [Leanplum track:@"Cancel" withValue:0.0 andInfo:nil
                            andArgs:@{LP_PARAM_MESSAGE_ID: messageId} andParameters:nil];
                }
            }];
        }
        if (result.matchedTrigger) {
            [[LPInternalState sharedState].actionManager recordMessageTrigger:internalMessageId];
            if (result.matchedLimit) {
                NSNumber *priority = messageConfig[@"priority"];
                if (!priority) {
                    priority = [NSNumber numberWithInt:DEFAULT_PRIORITY];
                }
                LPActionContext *context = [LPActionContext
                                            actionContextWithName:actionType
                                            args:[messageConfig objectForKey:LP_KEY_VARS]
                                            messageId:internalMessageId
                                            originalMessageId:messageId
                                            priority:priority];
                context.contextualValues = contextualValues;
                [actionContexts addObject:context];
            }
        }
    }

    if ([actionContexts count] > 0) {
        [LPActionContext sortByPriority:actionContexts];
        NSNumber *priorityThreshold = [((LPActionContext *) [actionContexts firstObject]) priority];
        for (LPActionContext *actionContext in actionContexts) {
            NSNumber *priority = [actionContext priority];
            if ([priority intValue] <= [priorityThreshold intValue]) {
              if ([[actionContext actionName] isEqualToString:LP_HELD_BACK_ACTION]) {
                  [[LPInternalState sharedState].actionManager
                      recordHeldBackImpression:[actionContext messageId]
                             originalMessageId:[actionContext originalMessageId]];
              } else {
                  [self triggerAction:actionContext handledBlock:^(BOOL success) {
                      if (success) {
                          [[LPInternalState sharedState].actionManager
                              recordMessageImpression:[actionContext messageId]];
                      }
                  }];
              }
            } else {
                break;
            }
        }
    }
}

+ (LPActionContext *)createActionContextForMessageId:(NSString *)messageId
{
    NSDictionary *messageConfig = [LPVarCache messages][messageId];
    LPActionContext *context =
        [LPActionContext actionContextWithName:messageConfig[@"action"]
                                          args:messageConfig[LP_KEY_VARS]
                                     messageId:messageId];
    return context;
}

+ (void)trackAllAppScreens
{
    [Leanplum trackAllAppScreensWithMode:LPTrackScreenModeDefault];
}

+ (void)trackAllAppScreensWithMode:(LPTrackScreenMode)trackScreenMode;
{
    RETURN_IF_NOOP;
    LP_TRY
    BOOL stripViewControllerFromState = trackScreenMode == LPTrackScreenModeStripViewController;
    [[LPInternalState sharedState] setStripViewControllerFromState:stripViewControllerFromState];
    [LPUIEditorWrapper enableAutomaticScreenTracking];
    LP_END_TRY
}

+ (void)trackInAppPurchases
{
    RETURN_IF_NOOP;
    LP_TRY
    [[LPRevenueManager sharedManager] trackRevenue];
    LP_END_TRY
}

+ (void)trackInAppPurchase:(SKPaymentTransaction *)transaction
{
    RETURN_IF_NOOP;
    LP_TRY
    if (!transaction) {
        [self throwError:@"[Leanplum trackInAppPurchase:] Nil transaction parameter provided."];
    } else if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
        [[LPRevenueManager sharedManager] addTransaction:transaction];
    } else {
        [self throwError:@"You are trying to track a transaction that is not purchased yet!"];
    }
    LP_END_TRY
}

+ (void)track:(NSString *)event withValue:(double)value andInfo:(NSString *)info
      andArgs:(NSDictionary *)args andParameters:(NSDictionary *)params
{
    RETURN_IF_NOOP;
    LP_TRY
    NSString *valueStr = [NSString stringWithFormat:@"%f", value];
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 valueStr, LP_PARAM_VALUE, nil];
    if (args) {
        [arguments addEntriesFromDictionary:args];
    }
    if (event) {
        arguments[LP_PARAM_EVENT] = event;
    }
    if (info) {
        arguments[LP_PARAM_INFO] = info;
    }
    if (params) {
        params = [Leanplum validateAttributes:params named:@"params" allowLists:NO];
        arguments[LP_PARAM_PARAMS] = [LPJSON stringFromJSON:params];
    }
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        arguments[@"allowOffline"] = @YES;
    }

    [self onStartIssued:^{
        [self trackInternal:event withArgs:arguments andParameters:params];
    }];
    LP_END_TRY
}

+ (void)trackInternal:(NSString *)event withArgs:(NSDictionary *)args
        andParameters:(NSDictionary *)params
{
    [[LeanplumRequest post:LP_METHOD_TRACK params:args] send];

    // Perform event actions.
    NSString *messageId = args[LP_PARAM_MESSAGE_ID];
    if (messageId) {
        if (event && event.length > 0) {
            event = [NSString stringWithFormat:@".m%@ %@", messageId, event];
        } else {
            event = [NSString stringWithFormat:@".m%@", messageId];
        }
    }

    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
    contextualValues.parameters = params;
    NSMutableDictionary *contextualArguments = [args mutableCopy];
    if (args[LP_PARAM_PARAMS]) {
        contextualArguments[LP_PARAM_PARAMS] = [LPJSON JSONFromString:args[LP_PARAM_PARAMS]];
    }
    contextualValues.arguments = contextualArguments;

    [self maybePerformActions:@[@"event"]
                withEventName:event
                   withFilter:kLeanplumActionFilterAll
                fromMessageId:messageId
         withContextualValues:contextualValues];
}

+ (void)track:(NSString *)event
{
    [self track:event withValue:0.0 andInfo:nil andParameters:nil];
}

+ (void)track:(NSString *)event withValue:(double)value
{
    [self track:event withValue:value andInfo:nil andParameters:nil];
}

+ (void)track:(NSString *)event withInfo:(NSString *)info
{
    [self track:event withValue:0.0 andInfo:info andParameters:nil];
}

+ (void)track:(NSString *)event withParameters:(NSDictionary *)params
{
    [self track:event withValue:0.0 andInfo:nil andParameters:params];
}

+ (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params
{
    [self track:event withValue:value andInfo:nil andParameters:params];
}

+ (void)track:(NSString *)event withValue:(double)value andInfo:(NSString *)info
{
    [self track:event withValue:value andInfo:info andParameters:nil];
}

+ (void)track:(NSString *)event
    withValue:(double)value
      andArgs:(NSDictionary *)args
andParameters:(NSDictionary *)params
{
    [self track:event withValue:value andInfo:nil andArgs:args andParameters:params];
}

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(NSString *)info
andParameters:(NSDictionary *)params
{
    [self track:event withValue:value andInfo:info andArgs:nil andParameters:params];
}

+ (void)trackException:(NSException *) exception
{
    RETURN_IF_NOOP;
    LP_TRY
    NSDictionary *exceptionDict = @{
        LP_KEY_REASON: exception.reason,
        LP_KEY_USER_INFO: exception.userInfo,
        LP_KEY_STACK_TRACE: exception.callStackSymbols
    };
    NSString *info = [LPJSON stringFromJSON:exceptionDict];
    [self track:LP_EVENT_EXCEPTION withInfo:info];
    LP_END_TRY
}

+ (void)setUserAttributes:(NSDictionary *)attributes
{
    [self setUserId:@"" withUserAttributes:attributes];
}

+ (void)setUserId:(NSString *)userId
{
    [self setUserId:userId withUserAttributes:@{}];
}

+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes
{
    RETURN_IF_NOOP;
    // TODO(aleksandar): Allow this to be called before start, which will
    // modify the arguments to start rather than issuing a separate API call.
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call setUserId before calling start"];
        return;
    }
    LP_TRY
    attributes = [self validateAttributes:attributes named:@"userAttributes" allowLists:YES];
    [self onStartIssued:^{
        [self setUserIdInternal:userId withAttributes:attributes];
    }];
    LP_END_TRY
}

+ (void)setUserIdInternal:(NSString *)userId withAttributes:(NSDictionary *)attributes
{
    // Some clients are calling this method with NSNumber. Handle it gracefully.
    id tempUserId = userId;
    if ([tempUserId isKindOfClass:[NSNumber class]]) {
        LPLog(LPWarning, @"setUserId is called with NSNumber. Please use NSString.");
        userId = [tempUserId stringValue];
    }

    // Attributes can't be nil
    if (!attributes) {
        attributes = @{};
    }

    [[LeanplumRequest post:LP_METHOD_SET_USER_ATTRIBUTES params:@{
        LP_PARAM_USER_ATTRIBUTES: attributes ? [LPJSON stringFromJSON:attributes] : @"",
        LP_PARAM_NEW_USER_ID: userId ? userId : @""
    }] send];

    if (userId.length) {
        [LeanplumRequest setUserId:userId];
        if ([LPInternalState sharedState].hasStarted) {
            [LPVarCache saveDiffs];
        }
    }

    if (attributes != nil) {
        [[LPInternalState sharedState].userAttributeChanges addObject:attributes];
    }

    [Leanplum onStartResponse:^(BOOL success) {
        LP_END_USER_CODE
        [self recordAttributeChanges];
        LP_BEGIN_USER_CODE
    }];

}

// Returns if attributes have changed.
+ (void)recordAttributeChanges
{
    BOOL madeChanges = NO;
    // Making a copy. Other threads can add attributes while iterating.
    NSMutableArray *attributeChanges = [[LPInternalState sharedState].userAttributeChanges copy];
    // Keep track of processed changes to be removed at the end.
    NSMutableArray *processedChanges = [NSMutableArray new];
    for (NSDictionary *attributes in attributeChanges) {
        NSMutableDictionary *existingAttributes = [LPVarCache userAttributes];
        [processedChanges addObject:attributes];
        for (NSString *attributeName in [attributes allKeys]) {
            id existingValue = existingAttributes[attributeName];
            id value = attributes[attributeName];
            if (![value isEqual:existingValue]) {
                LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
                contextualValues.previousAttributeValue = existingValue;
                contextualValues.attributeValue = value;
                existingAttributes[attributeName] = value;
                [Leanplum maybePerformActions:@[@"userAttribute"]
                                withEventName:attributeName
                                   withFilter:kLeanplumActionFilterAll
                                fromMessageId:nil
                         withContextualValues:contextualValues];
                madeChanges = YES;
            }
        }
    }
    // Remove only processed changes.
    [[LPInternalState sharedState].userAttributeChanges removeObjectsInArray:processedChanges];
    if (madeChanges) {
        [LPVarCache saveUserAttributes];
    }
}

+ (void)setTrafficSourceInfo:(NSDictionary *)info
{
    if ([Utils isNullOrEmpty:info]) {
        [self throwError:@"[Leanplum setTrafficSourceInfo:] Empty info parameter provided."];
        return;
    }
    RETURN_IF_NOOP;
    LP_TRY
    info = [self validateAttributes:info named:@"info" allowLists:NO];
    [self onStartIssued:^{
        [self setTrafficSourceInfoInternal:info];
    }];
    LP_END_TRY
}

+ (void)setTrafficSourceInfoInternal:(NSDictionary *)info
{
    [[LeanplumRequest post:LP_METHOD_SET_TRAFFIC_SOURCE_INFO params:@{
        LP_PARAM_TRAFFIC_SOURCE: info
    }] send];
}

+ (void)advanceTo:(NSString *)state
{
    [self advanceTo:state withInfo:nil];
}

+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info
{
    [self advanceTo:state withInfo:info andParameters:nil];
}

+ (void)advanceTo:(NSString *)state withParameters:(NSDictionary *)params
{
    [self advanceTo:state withInfo:nil andParameters:params];
}

+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info andParameters:(NSDictionary *)params
{
    RETURN_IF_NOOP;
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call advanceTo before calling start"];
        return;
    }
    LP_TRY
    if (state &&
        [[LPInternalState sharedState] stripViewControllerFromState] &&
        [state hasSuffix:@"ViewController"]) {
        state = [state substringToIndex:([state length] - [@"ViewController" length])];
    }
    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 state ? state : @"", LP_PARAM_STATE, nil];
    if (info) {
        args[LP_PARAM_INFO] = info;
    }
    if (params) {
        params = [Leanplum validateAttributes:params named:@"params" allowLists:NO];
        args[LP_PARAM_PARAMS] = [LPJSON stringFromJSON:params];
    }

    [self onStartIssued:^{
        [self advanceToInternal:state withArgs:args andParameters:params];
    }];
    LP_END_TRY
}

+ (void)advanceToInternal:(NSString *)state withArgs:(NSDictionary *)args
            andParameters:(NSDictionary *)params
{
    [[LeanplumRequest post:LP_METHOD_ADVANCE params:args] send];
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
    contextualValues.parameters = params;
    [self maybePerformActions:@[@"state"]
                withEventName:state
                   withFilter:kLeanplumActionFilterAll
                fromMessageId:nil
         withContextualValues:contextualValues];
}

+ (void)pauseState
{
    RETURN_IF_NOOP;
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call pauseState before calling start"];
        return;
    }
    LP_TRY
    [self onStartIssued:^{
        [self pauseStateInternal];
    }];
    LP_END_TRY
}

+ (void)pauseStateInternal
{
     [[LeanplumRequest post:LP_METHOD_PAUSE_STATE params:@{}] send];
}

+ (void)resumeState
{
    RETURN_IF_NOOP;
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call resumeState before calling start"];
        return;
    }
    LP_TRY
    [self onStartIssued:^{
        [self resumeStateInternal];
    }];
    LP_END_TRY
}

+ (void)resumeStateInternal
{
    [[LeanplumRequest post:LP_METHOD_RESUME_STATE params:@{}] send];
}

+ (void)forceContentUpdate
{
    [self forceContentUpdate:nil];
}

+ (void)forceContentUpdate:(LeanplumVariablesChangedBlock)block
{
    if (IS_NOOP) {
        if (block) {
            block();
        }
        return;
    }
    LP_TRY
    NSDictionary *params = @{
        LP_PARAM_INCLUDE_DEFAULTS: @(NO),
        LP_PARAM_INBOX_MESSAGES: [[self inbox] messagesIds]
    };
    LeanplumRequest* req = [LeanplumRequest
                            post:LP_METHOD_GET_VARS
                            params:params];
    [req onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        NSDictionary *values = response[LP_KEY_VARS];
        NSDictionary *messages = response[LP_KEY_MESSAGES];
        NSArray *updateRules = response[LP_KEY_UPDATE_RULES];
        NSArray *eventRules = response[LP_KEY_EVENT_RULES];
        NSArray *variants = response[LP_KEY_VARIANTS];
        NSDictionary *regions = response[LP_KEY_REGIONS];
        if (![values isEqualToDictionary:LPVarCache.diffs] ||
            ![messages isEqualToDictionary:LPVarCache.messageDiffs] ||
            ![updateRules isEqualToArray:LPVarCache.updateRulesDiffs] ||
            ![eventRules isEqualToArray:LPVarCache.eventRulesDiffs] ||
            ![regions isEqualToDictionary:LPVarCache.regions]) {
            [LPVarCache applyVariableDiffs:values
                                  messages:messages
                               updateRules:updateRules
                                eventRules:eventRules
                                  variants:variants
                                   regions:regions];

        }
        if ([response[LP_KEY_SYNC_INBOX] boolValue]) {
            [[self inbox] downloadMessages];
        }
        LP_END_TRY
        if (block) {
            block();
        }
    }];
    [req onError:^(NSError *error) {
        if (block) {
            block();
        }
    }];
    [req sendIfConnected];
    LP_END_TRY
}

+ (void)enableTestMode
{
    LP_TRY
    [LPConstantsState sharedState].isTestMode = YES;
    LP_END_TRY
}

+ (void)setTestModeEnabled:(BOOL)isTestModeEnabled
{
    LP_TRY
    [LPConstantsState sharedState].isTestMode = isTestModeEnabled;
    LP_END_TRY
}

void leanplumExceptionHandler(NSException *exception)
{
    [Leanplum trackException:exception];
    if ([LPInternalState sharedState].customExceptionHandler) {
        [LPInternalState sharedState].customExceptionHandler(exception);
    }
}

+ (void)createDefaultExceptionHandler
{
    RETURN_IF_NOOP;
    [LPInternalState sharedState].customExceptionHandler = nil;
    NSSetUncaughtExceptionHandler(&leanplumExceptionHandler);
}

+ (void)createExceptionHandler:(NSUncaughtExceptionHandler *)customHandler
{
    RETURN_IF_NOOP;
    [LPInternalState sharedState].customExceptionHandler = customHandler;
    NSSetUncaughtExceptionHandler(&leanplumExceptionHandler);
}

+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)extension
{
    if ([Utils isNullOrEmpty:name]) {
        [self throwError:@"[Leanplum pathForResource:ofType:] Empty name parameter provided."];
        return nil;
    }
    if ([Utils isNullOrEmpty:extension]) {
        [self throwError:@"[Leanplum pathForResource:ofType:] Empty name extension provided."];
        return nil;
    }
    LP_TRY
    LPVar *resource = [LPVar define:name withFile:[name stringByAppendingFormat:@".%@", extension]];
    return [resource fileValue];
    LP_END_TRY
    return nil;
}

+ (id)objectForKeyPath:(id)firstComponent, ...
{
    LP_TRY
    NSMutableArray *components = [[NSMutableArray alloc] init];
    va_list args;
    va_start(args, firstComponent);
    for (id component = firstComponent;
         component != nil; component = va_arg(args, id)) {
        [components addObject:component];
    }
    va_end(args);
    return [LPVarCache getMergedValueFromComponentArray:components];
    LP_END_TRY
    return nil;
}

+ (id)objectForKeyPathComponents:(NSArray *) pathComponents
{
    LP_TRY
    return [LPVarCache getMergedValueFromComponentArray:pathComponents];
    LP_END_TRY
    return nil;
}

+ (NSArray *)variants
{
    LP_TRY
    NSArray *variants = [LPVarCache variants];
    if (variants) {
        return variants;
    }
    LP_END_TRY
    return [NSArray array];
}

+ (NSDictionary *)messageMetadata
{
    LP_TRY
    NSDictionary *messages = [LPVarCache messages];
    if (messages) {
        return messages;
    }
    LP_END_TRY
    return [NSDictionary dictionary];
}

+ (void)setPushSetup:(LeanplumPushSetupBlock)block
{
    LP_TRY
    pushSetupBlock = block;
    LP_END_TRY
}

+ (LeanplumPushSetupBlock)pushSetupBlock
{
    LP_TRY
    return pushSetupBlock;
    LP_END_TRY
    return nil;
}

+ (BOOL)isPreLeanplumInstall
{
    LP_TRY
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"[Leanplum start] must be called before calling isPreLeanplumInstall"];
        return NO;
    }
    return [[NSUserDefaults standardUserDefaults]
            boolForKey:LEANPLUM_DEFAULTS_PRE_LEANPLUM_INSTALL_KEY];
    LP_END_TRY
    return NO;
}

+ (NSString *)deviceId
{
    LP_TRY
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"[Leanplum start] must be called before calling deviceId"];
        return nil;
    }
    return [LeanplumRequest deviceId];
    LP_END_TRY
    return nil;
}

+ (NSString *)userId
{
    LP_TRY
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"[Leanplum start] must be called before calling userId"];
        return nil;
    }
    return [LeanplumRequest userId];
    LP_END_TRY
    return nil;
}

+ (LPInbox *)inbox
{
    LP_TRY
    return [LPInbox sharedState];
    LP_END_TRY
    return nil;
}

+ (LPNewsfeed *)newsfeed
{
    LP_TRY
    return [LPNewsfeed sharedState];
    LP_END_TRY
    return nil;
}

void LPLog(LPLogType type, NSString *format, ...) {
    va_list vargs;
    va_start(vargs, format);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:vargs];
    va_end(vargs);

    NSString *message;
    switch (type) {
        case LPDebug:
#ifdef DEBUG
            message = [NSString stringWithFormat:@"Leanplum DEBUG: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
#endif
            return;
        case LPVerbose:
            if ([LPConstantsState sharedState].isDevelopmentModeEnabled
                && [LPConstantsState sharedState].verboseLoggingInDevelopmentMode) {
                message = [NSString stringWithFormat:@"Leanplum VERBOSE: %@", formattedMessage];
                printf("%s\n", [message UTF8String]);
                [Leanplum maybeSendLog:message];
            }
            return;
        case LPError:
            message = [NSString stringWithFormat:@"Leanplum ERROR: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
            [Leanplum maybeSendLog:message];
            return;
        case LPWarning:
            message = [NSString stringWithFormat:@"Leanplum WARNING: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
            [Leanplum maybeSendLog:message];
            return;
        case LPInfo:
            message = [NSString stringWithFormat:@"Leanplum INFO: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
            [Leanplum maybeSendLog:message];
            return;
        case LPInternal:
            message = [NSString stringWithFormat:@"Leanplum INTERNAL: %@", formattedMessage];
            [Leanplum maybeSendLog:message];
            return;
        default:
            return;
    }
}

+ (void)maybeSendLog:(NSString *)message {
    if (![LPConstantsState sharedState].loggingEnabled) {
        return;
    }

    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    BOOL isLogging = [[[[NSThread currentThread] threadDictionary]
                       objectForKey:LP_IS_LOGGING] boolValue];

    if (isLogging) {
        return;
    }

    threadDict[LP_IS_LOGGING] = @YES;

    @try {
        [[LeanplumRequest post:LP_METHOD_LOG params:@{
                                                      LP_PARAM_TYPE: LP_VALUE_SDK_LOG,
                                                      LP_PARAM_MESSAGE: message
                                                      }] sendEventually];
    } @catch (NSException *exception) {
        NSLog(@"Leanplum: Unable to send log: %@", exception);
    } @finally {
        [threadDict removeObjectForKey:LP_IS_LOGGING];
    }
}

/**
 * Returns the name of LPLocationAccuracyType.
 */
+ (NSString *)getLocationAccuracyTypeName:(LPLocationAccuracyType)locationAccuracyType
{
    switch(locationAccuracyType) {
        case LPLocationAccuracyIP:
            return @"ip";
        case LPLocationAccuracyCELL:
            return @"cell";
        case LPLocationAccuracyGPS:
            return @"gps";
        default:
            LPLog(LPError, @"Unexpected LPLocationType.");
            return nil;
    }
}

+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
{
    [Leanplum setDeviceLocationWithLatitude:latitude
                                  longitude:longitude
                                       type:LPLocationAccuracyCELL];
}

+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 type:(LPLocationAccuracyType)type
{
    [Leanplum setDeviceLocationWithLatitude:latitude longitude:longitude
                                       city:nil region:nil country:nil
                                       type:type];
}

+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 city:(NSString *)city
                               region:(NSString *)region
                              country:(NSString *)country
                                 type:(LPLocationAccuracyType)type
{
    LP_TRY
    if ([LPConstantsState sharedState].isLocationCollectionEnabled &&
        NSClassFromString(@"LPLocationManager")) {
        LPLog(LPWarning, @"Leanplum is automatically collecting device location, "
              "so there is no need to call setDeviceLocation. If you prefer to "
              "always set location manually, then call disableLocationCollection:.");
    }

    [self setUserLocationAttributeWithLatitude:latitude longitude:longitude
                                          city:city region:region country:country
                                          type:type responseHandler:nil];
    LP_END_TRY
}

+ (void)setUserLocationAttributeWithLatitude:(double)latitude
                                   longitude:(double)longitude
                                        city:(NSString *)city
                                      region:(NSString *)region
                                     country:(NSString *)country
                                        type:(LPLocationAccuracyType)type
                             responseHandler:(LeanplumSetLocationBlock)response
{
    LP_TRY
    NSMutableDictionary *params = [@{
        LP_KEY_LOCATION: [NSString stringWithFormat:@"%.6f,%.6f", latitude, longitude],
        LP_KEY_LOCATION_ACCURACY_TYPE: [self getLocationAccuracyTypeName:type]
    } mutableCopy];
    if (city) {
        params[LP_KEY_CITY] = city;
    }
    if (region) {
        params[LP_KEY_REGION] = region;
    }
    if (country) {
        params[LP_KEY_COUNTRY] = country;
    }

    LeanplumRequest *req = [LeanplumRequest post:LP_METHOD_SET_USER_ATTRIBUTES params:params];
    [req onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (response) {
            response(YES);
        }
    }];
    [req onError:^(NSError *error) {
        LPLog(LPError, @"setUserAttributes failed with error: %@", error);
        if (response) {
            response(NO);
        }
    }];
    [req send];
    LP_END_TRY
}

+ (void)disableLocationCollection
{
    LP_TRY
    [LPConstantsState sharedState].isLocationCollectionEnabled = NO;
    LP_END_TRY
}

@end

@implementation LPVar

@synthesize private_IsInternal=_isInternal;
@synthesize private_Name=_name;
@synthesize private_NameComponents=_nameComponents;
@synthesize private_StringValue=_stringValue;
@synthesize private_NumberValue=_numberValue;
@synthesize private_HadStarted=_hadStarted;
@synthesize private_Value=_value;
@synthesize private_DefaultValue=_defaultValue;
@synthesize private_Kind=_kind;
@synthesize private_FileReadyBlocks=_fileReadyBlocks;
@synthesize private_valueChangedBlocks=_valueChangedBlocks;
@synthesize private_FileIsPending=_fileIsPending;
@synthesize private_Delegate=_delegate;
@synthesize private_HasChanged=_hasChanged;

- (instancetype)initWithName:(NSString *)name withComponents:(NSArray *)components
            withDefaultValue:(NSNumber *)defaultValue withKind:(NSString *)kind
{
    self = [super init];
    if (self) {
        LP_TRY
        _name = name;
        _nameComponents = [LPVarCache getNameComponents:name];
        _defaultValue = defaultValue;
        _value = defaultValue;
        _kind = kind;
        [self cacheComputedValues];

        [LPVarCache registerVariable:self];
        if ([kind isEqualToString:LP_KIND_FILE]) { // TODO: && var.stringValue)
            [LPVarCache registerFile:_stringValue withDefaultValue:_defaultValue];
        }
        if ([name hasPrefix:LP_VALUE_RESOURCES_VARIABLE]) {
            _isInternal = YES;
        }
        [self update];
        LP_END_TRY
    }
    return self;
}

#pragma mark Defines

+ (LPVar *)define:(NSString *)name
{
    return [LPVarCache define:name with:nil kind:nil];
}

+ (LPVar *)define:(NSString *)name withInt:(int)defaultValue
{
    return [LPVarCache define:name with:[NSNumber numberWithInt:defaultValue] kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withFloat:(float)defaultValue
{
    return [LPVarCache define:name with:[NSNumber numberWithFloat:defaultValue] kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withDouble:(double)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithDouble:defaultValue]
                         kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withCGFloat:(CGFloat)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithDouble:defaultValue]
                         kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withShort:(short)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithShort:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withChar:(char)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithChar:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withBool:(BOOL)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithBool:defaultValue]
                         kind:LP_KIND_BOOLEAN];
}

+ (LPVar *)define:(NSString *)name withInteger:(NSInteger)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithInteger:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withLong:(long)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withLongLong:(long long)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithLongLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedChar:(unsigned char)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithUnsignedChar:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedInt:(unsigned int)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithUnsignedInt:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithUnsignedInteger:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedLong:(unsigned long)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithUnsignedLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithUnsignedLongLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedShort:(unsigned short)defaultValue
{
    return [LPVarCache define:name
                         with:[NSNumber numberWithUnsignedShort:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withString:(NSString *)defaultValue
{
    return [LPVarCache define:name with:defaultValue kind:LP_KIND_STRING];
}

+ (LPVar *)define:(NSString *)name withNumber:(NSNumber *)defaultValue
{
    return [LPVarCache define:name with:defaultValue kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withFile:(NSString *)defaultFilename
{
    return [LPVarCache define:name with:defaultFilename kind:LP_KIND_FILE];
}

+ (LPVar *)define:(NSString *)name withDictionary:(NSDictionary *)defaultValue
{
    return [LPVarCache define:name with:defaultValue kind:LP_KIND_DICTIONARY];
}

+ (LPVar *)define:(NSString *)name withArray:(NSArray *)defaultValue
{
    return [LPVarCache define:name with:defaultValue kind:LP_KIND_ARRAY];
}

+ (LPVar *)define:(NSString *)name withColor:(UIColor *)defaultValue
{
    return [LPVarCache define:name with:@(leanplum_colorToInt(defaultValue)) kind:LP_KIND_COLOR];
}

#pragma mark Updating

- (void) cacheComputedValues
{
    // Cache computed values.
    if ([_value isKindOfClass:NSString.class]) {
        _stringValue = (NSString *) _value;
        _numberValue = [NSNumber numberWithDouble:[_stringValue doubleValue]];
    } else if ([_value isKindOfClass:NSNumber.class]) {
        _stringValue = [NSString stringWithFormat:@"%@", _value];
        _numberValue = (NSNumber *) _value;
    } else {
        _stringValue = nil;
        _numberValue = nil;
    }
}

- (void)update
{
    NSObject *oldValue = _value;
    _value = [LPVarCache getMergedValueFromComponentArray:_nameComponents];
    if ([_value isEqual:oldValue] && _hadStarted) {
        return;
    }
    [self cacheComputedValues];

    if (![_value isEqual:oldValue]) {
        _hasChanged = YES;
    }

    if (LPVarCache.silent && [[self name] hasPrefix:LP_VALUE_RESOURCES_VARIABLE]
        && [_kind isEqualToString:LP_KIND_FILE] && !_fileIsPending) {
        [self triggerFileIsReady];
    }

    if (LPVarCache.silent) {
        return;
    }

    if ([LPInternalState sharedState].hasStarted) {
        [self triggerValueChanged];
    }

    // Check if file exists, otherwise we need to download it.
    // Ignore app icon. This is a special variable that only needs the filename.
    if ([_kind isEqualToString:LP_KIND_FILE]) {
        if ([LPFileManager maybeDownloadFile:_stringValue
                                defaultValue:_defaultValue
                                  onComplete:^{[self triggerFileIsReady];}]) {
            _fileIsPending = YES;
        }
        if ([LPInternalState sharedState].hasStarted && !_fileIsPending) {
            [self triggerFileIsReady];
        }
    }

    if ([LPInternalState sharedState].hasStarted) {
        _hadStarted = YES;
    }
}

#pragma mark Basic accessors

- (NSString *)name
{
    return _name;
}

- (NSArray *)nameComponents
{
    return _nameComponents;
}

- (id)defaultValue
{
    return _defaultValue;
}

- (NSString *)kind
{
    return _kind;
}

- (void)triggerValueChanged
{
    LP_BEGIN_USER_CODE
    if (self.private_Delegate &&
        [self.private_Delegate respondsToSelector:@selector(valueDidChange:)]) {
        [self.private_Delegate valueDidChange:self];
    }

    for (LeanplumVariablesChangedBlock block in _valueChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

- (void)onValueChanged:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [Leanplum throwError:@"[LPVar onValueChanged:] Nil block parameter provided."];
    }

    LP_TRY
    if (!_valueChangedBlocks) {
        _valueChangedBlocks = [NSMutableArray array];
    }
    [_valueChangedBlocks addObject:[block copy]];
    if ([LPInternalState sharedState].hasStarted) {
        [self triggerValueChanged];
    }
    LP_END_TRY
}

#pragma mark File handling

- (void)triggerFileIsReady
{
    _fileIsPending = NO;
    LP_BEGIN_USER_CODE
    if (self.private_Delegate &&
        [self.private_Delegate respondsToSelector:@selector(fileIsReady:)]) {
        [self.private_Delegate fileIsReady:self];
    }

    for (LeanplumVariablesChangedBlock block in _fileReadyBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

- (void)onFileReady:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [Leanplum throwError:@"[LPVar onFileReady:] Nil block parameter provided."];
    }

    LP_TRY
    if (!_fileReadyBlocks) {
        _fileReadyBlocks = [NSMutableArray array];
    }
    [_fileReadyBlocks addObject:[block copy]];
    if ([LPInternalState sharedState].hasStarted && !_fileIsPending) {
        [self triggerFileIsReady];
    }
    LP_END_TRY
}

- (void)setDelegate:(id<LPVarDelegate>)delegate
{
    LP_TRY
    self.private_Delegate = delegate;
    if ([LPInternalState sharedState].hasStarted && !_fileIsPending) {
        [self triggerFileIsReady];
    }
    LP_END_TRY
}

- (void)warnIfNotStarted
{
    if (!_isInternal && ![LPInternalState sharedState].hasStarted && !printedCallbackWarning) {
        NSLog(@"Leanplum: WARNING: Leanplum hasn't finished retrieving values from the server. You "
              @"should use a callback to make sure the value for '%@' is ready. Otherwise, your "
              @"app may not use the most up-to-date value.", self.name);
        printedCallbackWarning = YES;
    }
}

- (NSString *)fileValue
{
    LP_TRY
    [self warnIfNotStarted];
    if ([_kind isEqualToString:LP_KIND_FILE]) {
        return [LPFileManager fileValue:_stringValue withDefaultValue:_defaultValue];
    }
    LP_END_TRY
    return nil;
}

- (UIImage *)imageValue
{
    LP_TRY
    NSString *fileValue = [self fileValue];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileValue]) {
        return [UIImage imageWithContentsOfFile:fileValue];
    }
    LP_END_TRY
    return [UIImage imageNamed:_defaultValue];
}

#pragma mark Dictionary handling

- (id) objectForKey:(NSString *)key
{
    return [self objectForKeyPath:key, nil];
}

- (id) objectAtIndex:(NSUInteger)index
{
    return [self objectForKeyPath:@(index), nil];
}

- (id) objectForKeyPath:(id)firstComponent, ...
{
    LP_TRY
    [self warnIfNotStarted];
    NSMutableArray *components = [_nameComponents mutableCopy];
    va_list args;
    va_start(args, firstComponent);
    for (id component = firstComponent;
         component != nil; component = va_arg(args, id)) {
        [components addObject:component];
    }
    va_end(args);
    return [LPVarCache getMergedValueFromComponentArray:components];
    LP_END_TRY
    return nil;
}

- (id)objectForKeyPathComponents:(NSArray *)pathComponents
{
    LP_TRY
    [self warnIfNotStarted];
    NSMutableArray *components = [_nameComponents mutableCopy];
    [components addObjectsFromArray:pathComponents];
    return [LPVarCache getMergedValueFromComponentArray:components];
    LP_END_TRY
    return nil;
}

- (NSUInteger)count
{
    LP_TRY
    return [[LPVarCache getMergedValueFromComponentArray:_nameComponents] count];
    LP_END_TRY
}

#pragma mark Value accessors

- (BOOL)hasChanged { return _hasChanged; }

- (NSNumber *)numberValue
{
    [self warnIfNotStarted];
    return _numberValue;
}

- (NSString *)stringValue
{
    [self warnIfNotStarted];
    return _stringValue;
}

- (int)intValue { return [[self numberValue] intValue]; }
- (double)doubleValue { return [[self numberValue] doubleValue];}
- (float)floatValue { return [[self numberValue] floatValue]; }
- (CGFloat)cgFloatValue { return [[self numberValue] doubleValue]; }
- (short)shortValue { return [[self numberValue] shortValue];}
- (BOOL)boolValue { return [[self numberValue] boolValue]; }
- (char)charValue { return [[self numberValue] charValue]; }
- (long)longValue { return [[self numberValue] longValue]; }
- (long long)longLongValue { return [[self numberValue] longLongValue]; }
- (NSInteger)integerValue { return [[self numberValue] integerValue]; }
- (unsigned char)unsignedCharValue { return [[self numberValue] unsignedCharValue]; }
- (unsigned short)unsignedShortValue { return [[self numberValue] unsignedShortValue]; }
- (unsigned int)unsignedIntValue { return [[self numberValue] unsignedIntValue]; }
- (NSUInteger)unsignedIntegerValue { return [[self numberValue] unsignedIntegerValue]; }
- (unsigned long)unsignedLongValue { return [[self numberValue] unsignedLongValue]; }
- (unsigned long long)unsignedLongLongValue { return [[self numberValue] unsignedLongLongValue]; }
- (UIColor *)colorValue { return leanplum_intToColor([self longLongValue]); }

@end


@implementation LPActionArg : NSObject

@synthesize private_Name=_name;
@synthesize private_Kind=_kind;
@synthesize private_DefaultValue=_defaultValue;

+ (LPActionArg *)argNamed:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPVar argNamed:with:kind:] Empty name parameter provided."];
        return nil;
    }
    LPActionArg *arg = [LPActionArg new];
    LP_TRY
    arg->_name = name;
    arg->_kind = kind;
    arg->_defaultValue = defaultValue;
    if ([kind isEqualToString:LP_KIND_FILE]) {
        [LPVarCache registerFile:(NSString *) defaultValue
                withDefaultValue:(NSString *) defaultValue];
    }
    LP_END_TRY
    return arg;
}

+ (LPActionArg *)argNamed:(NSString *)name withNumber:(NSNumber *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_FLOAT];
}

+ (LPActionArg *)argNamed:(NSString *)name withString:(NSString *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_STRING];
}

+ (LPActionArg *)argNamed:(NSString *)name withBool:(BOOL)defaultValue
{
    return [self argNamed:name with:@(defaultValue) kind:LP_KIND_BOOLEAN];
}

+ (LPActionArg *)argNamed:(NSString *)name withFile:(NSString *)defaultValue
{
    if (defaultValue == nil) {
        defaultValue = @"";
    }
    return [self argNamed:name with:defaultValue kind:LP_KIND_FILE];
}

+ (LPActionArg *)argNamed:(NSString *)name withDict:(NSDictionary *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_DICTIONARY];
}

+ (LPActionArg *)argNamed:(NSString *)name withArray:(NSArray *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_ARRAY];
}

+ (LPActionArg *)argNamed:(NSString *)name withAction:(NSString *)defaultValue
{
    if (defaultValue == nil) {
        defaultValue = @"";
    }
    return [self argNamed:name with:defaultValue kind:LP_KIND_ACTION];
}

+ (LPActionArg *)argNamed:(NSString *)name withColor:(UIColor *)defaultValue
{
    return [self argNamed:name with:@(leanplum_colorToInt(defaultValue)) kind:LP_KIND_COLOR];
}

- (NSString *)name
{
    return _name;
}

- (id)defaultValue
{
    return _defaultValue;
}

- (NSString *)kind
{
    return _kind;
}

@end


@implementation LPActionContext

@synthesize private_Name=_name;
@synthesize private_MessageId=_messageId;
@synthesize private_OriginalMessageId=_originalMessageId;
@synthesize private_Priority=_priority;
@synthesize private_Args=_args;
@synthesize private_ParentContext=_parentContext;
@synthesize private_ContentVersion=_contentVersion;
@synthesize private_Key=_key;
@synthesize private_PreventRealtimeUpdating=_preventRealtimeUpdating;
@synthesize private_IsRooted=_isRooted;
@synthesize private_IsPreview=_isPreview;
@synthesize contextualValues=_contextualValues;

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
{
    return [LPActionContext actionContextWithName:name
                                             args:args
                                        messageId:messageId
                                originalMessageId:nil
                                         priority:[NSNumber numberWithInt:DEFAULT_PRIORITY]];
}

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
                         originalMessageId:(NSString *)originalMessageId
                                  priority:(NSNumber *)priority

{
    LPActionContext *context = [[LPActionContext alloc] init];
    context->_name = name;
    context->_args = args;
    context->_messageId = messageId;
    context->_originalMessageId = originalMessageId;
    context->_contentVersion = [LPVarCache contentVersion];
    context->_preventRealtimeUpdating = NO;
    context->_isRooted = YES;
    context->_isPreview = NO;
    context->_priority = priority;
    return context;
}

- (NSString *)messageId
{
    return _messageId;
}

- (NSString *)originalMessageId
{
    return _originalMessageId;
}

- (NSNumber *)priority
{
    return _priority;
}

- (void)preventRealtimeUpdating
{
    _preventRealtimeUpdating = YES;
}

- (void)setIsRooted:(BOOL)value
{
    _isRooted = value;
}

- (void)setIsPreview:(BOOL)value
{
    _isPreview = value;
}

- (NSDictionary *)defaultValues
{
    return LPVarCache.actionDefinitions[_name][@"values"];
}

/**
 * Downloads missing files that are part of this action.
 */
- (void)maybeDownloadFiles
{
    [self maybeDownloadFilesWithinArgs:_args withPrefix:@"" withDefaultValues:[self defaultValues]];
}

/**
 * Downloads missing files that are part of this action.
 */
- (void)maybeDownloadFilesWithinArgs:(NSDictionary *)args
                          withPrefix:(NSString *)prefix
                   withDefaultValues:(NSDictionary *)defaultValues
{
    [self forEachFile:args
           withPrefix:prefix
    withDefaultValues:defaultValues
             callback:^(NSString *value, NSString *defaultValue) {
                 [LPFileManager maybeDownloadFile:value
                                     defaultValue:defaultValue
                                       onComplete:^{}];
             }];
}

- (void)forEachFile:(NSDictionary *)args
         withPrefix:(NSString *)prefix
  withDefaultValues:(NSDictionary *)defaultValues
           callback:(LPFileCallback)callback
{
    NSDictionary *kinds = LPVarCache.actionDefinitions[_name][@"kinds"];
    for (NSString *arg in args) {
        id value = args[arg];
        id defaultValue = nil;
        if ([defaultValues isKindOfClass:[NSDictionary class]]) {
            defaultValue = defaultValues[arg];
        }
        NSString *prefixAndArg = [NSString stringWithFormat:@"%@%@", prefix, arg];
        NSString *kind = kinds[prefixAndArg];

        if ((kind == nil || ![kind isEqualToString:LP_KIND_ACTION])
            && [value isKindOfClass:[NSDictionary class]]
            && !value[LP_VALUE_ACTION_ARG]) {
            [self forEachFile:value
                   withPrefix:[NSString stringWithFormat:@"%@.", prefixAndArg]
            withDefaultValues:defaultValue
                     callback:callback];

        } else if ([kind isEqualToString:LP_KIND_FILE] &&
                   ![arg isEqualToString:LP_APP_ICON_NAME]) {
                callback(value, defaultValue);

        // Check for specific file type extension (HTML).
        } else if ([arg hasPrefix:@"__file__"] && ![Utils isNullOrEmpty:value]) {
            callback(value, defaultValue);

        // Need to check for nil because server actions like push notifications aren't
        // defined in the SDK, and so there's no associated metadata.
        } else if ([kind isEqualToString:LP_KIND_ACTION] || kind == nil) {
            NSDictionary *actionArgs = [self dictionaryNamed:prefixAndArg];
            if (![actionArgs isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            LPActionContext *context = [LPActionContext
                                        actionContextWithName:actionArgs[LP_VALUE_ACTION_ARG]
                                        args:actionArgs
                                        messageId:_messageId];
            [context forEachFile:context->_args
                      withPrefix:@""
               withDefaultValues:[context defaultValues]
                        callback:callback];
        }
    }
}

- (BOOL)hasMissingFiles
{
    __block BOOL hasMissingFiles = NO;
    LP_TRY
    [self forEachFile:_args
           withPrefix:@""
    withDefaultValues:[self defaultValues]
             callback:^(NSString *value, NSString *defaultValue) {
                 if ([LPFileManager shouldDownloadFile:value defaultValue:defaultValue]) {
                     hasMissingFiles = YES;
                 }
             }];
    LP_END_TRY
    return hasMissingFiles;
}

- (NSString *)actionName
{
    return _name;
}

- (NSDictionary *)args
{
    return _args;
}

- (void)setProperArgs
{
    if (!_preventRealtimeUpdating && [LPVarCache contentVersion] > _contentVersion) {
        LPActionContext *parent = _parentContext;
        if (parent) {
            _args = [parent getChildArgs:_key];
        } else if (_messageId) {
            _args = LPVarCache.messages[_messageId][LP_KEY_VARS];
        }
    }
}

- (id)objectNamed:(NSString *)name
{
    LP_TRY
    [self setProperArgs];
    return [LPVarCache getValueFromComponentArray:[LPVarCache getNameComponents:name]
                                         fromDict:_args];
    LP_END_TRY
    return nil;
}

- (NSString *)stringNamed:(NSString *)name
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext stringNamed:] Empty name parameter provided."];
        return nil;
    }
    return [self fillTemplate:[[self objectNamed:name] description]];
}

- (NSString *)fillTemplate:(NSString *)value
{
    if (!_contextualValues || !value || [value rangeOfString:@"##"].location == NSNotFound) {
        return value;
    }

    NSDictionary *parameters = _contextualValues.parameters;

    for (NSString *parameterName in [parameters keyEnumerator]) {
        NSString *placeholder = [NSString stringWithFormat:@"##Parameter %@##", parameterName];
        value = [value stringByReplacingOccurrencesOfString:placeholder
                                                 withString:[parameters[parameterName]
                                                             description]];
    }
    if (_contextualValues.previousAttributeValue) {
        value = [value
            stringByReplacingOccurrencesOfString:@"##Previous Value##"
                                      withString:[_contextualValues
                                                  .previousAttributeValue description]];
    }
    if (_contextualValues.attributeValue) {
        value = [value stringByReplacingOccurrencesOfString:@"##Value##"
                                                 withString:[_contextualValues.attributeValue
                                                             description]];
    }
    return value;
}

- (NSString *)htmlWithTemplateNamed:(NSString *)templateName
{
    if ([Utils isNullOrEmpty:templateName]) {
        [Leanplum throwError:@"[LPActionContext htmlWithTemplateNamed:] "
                            "Empty name parameter provided."];
        return nil;
    }

    LP_TRY
    [self setProperArgs];

    // Replace to local file path recursively.
    __block __weak NSMutableDictionary* (^weakReplaceFileToLocalPath) (NSMutableDictionary *);
    NSMutableDictionary* (^replaceFileToLocalPath) (NSMutableDictionary *);
    weakReplaceFileToLocalPath = replaceFileToLocalPath =
            [^ NSMutableDictionary* (NSMutableDictionary *vars){
        for (NSString *key in [vars allKeys]) {
            id obj = vars[key];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                vars[key] = weakReplaceFileToLocalPath(obj);
            } else if ([key hasPrefix:@"__file__"] && [obj isKindOfClass:[NSString class]]
                       && [obj length] > 0 && ![key isEqualToString:templateName]) {
                NSString *filePath = [LPFileManager fileValue:obj withDefaultValue:@""];
                NSString *prunedKey = [key stringByReplacingOccurrencesOfString:@"__file__"
                                                                     withString:@""];
                vars[prunedKey] = [[NSString stringWithFormat:@"file://%@", filePath]
                                   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
                [vars removeObjectForKey:key];
            }
        }
        return vars;
    } copy];
    NSMutableDictionary *htmlVars = replaceFileToLocalPath([_args mutableCopy]);
    htmlVars[@"messageId"] = self.messageId;

    // Triggering Event.
    if (self.contextualValues && self.contextualValues.arguments) {
        htmlVars[@"displayEvent"] = self.contextualValues.arguments;
    }

    // Add HTML Vars.
    NSString *jsonString = [LPJSON stringFromJSON:htmlVars];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    // Template.
    NSError *error;
    NSString *htmlString = [NSString stringWithContentsOfFile:[self fileNamed:templateName]
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (error) {
        LPLog(LPError, @"Fail to get HTML template.");
        return nil;
    }
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"##Vars##"
                                                       withString:jsonString];
    return [self fillTemplate:htmlString];
    LP_END_TRY
    return @"";
}

- (NSString *)getDefaultValue:(NSString *)name
{
    NSArray *components = [name componentsSeparatedByString:@"."];
    NSDictionary *defaultValues = self.defaultValues;
    for (int i = 0; i < components.count; i++) {
        if (defaultValues == nil) {
            return nil;
        }
        id value = defaultValues[components[i]];
        if (i == components.count - 1) {
            return (NSString *) value;
        }
        defaultValues = (NSDictionary *) value;
    }
    return nil;
}

- (NSString *)fileNamed:(NSString *)name
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext fileNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    NSString *stringValue = [self stringNamed:name];
    NSString *defaultValue = [self getDefaultValue:name];
    return [LPFileManager fileValue:stringValue withDefaultValue:defaultValue];
    LP_END_TRY
}

- (NSNumber *)numberNamed:(NSString *)name
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext numberNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:NSNumber.class]) {
        return object;
    }
    return [NSNumber numberWithDouble:[[object description] doubleValue]];
    LP_END_TRY
}

- (BOOL)boolNamed:(NSString *)name
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext boolNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:NSNumber.class]) {
        return [(NSNumber *) object boolValue];
    }
    return [[object description] boolValue];
    LP_END_TRY
}

- (NSDictionary *)dictionaryNamed:(NSString *)name
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext dictionaryNamed:] Empty name parameter provided."];
        return nil;
    }
    return (NSDictionary *) [self objectNamed:name];
}

- (NSArray *)arrayNamed:(NSString *)name
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext arrayNamed:] Empty name parameter provided."];
        return nil;
    }
    return (NSArray *) [self objectNamed:name];
}

- (UIColor *)colorNamed:(NSString *)name
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext colorNamed:] Empty name parameter provided."];
        return nil;
    }
    return leanplum_intToColor([[self numberNamed:name] longLongValue]);
}

- (NSDictionary *)getChildArgs:(NSString *)name
{
    LP_TRY
    NSDictionary *actionArgs = [self dictionaryNamed:name];
    if (![actionArgs isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *defaultArgs = LPVarCache.actionDefinitions
                                  [actionArgs[LP_VALUE_ACTION_ARG]]
                                 [@"values"];
    actionArgs = [LPVarCache mergeHelper:defaultArgs withDiffs:actionArgs];
    return actionArgs;
    LP_END_TRY
}

/**
 * Prefix given event with all parent actionContext names to while filtering out the string
 * "action" (used in ExperimentVariable names but filtered out from event names).
 */
- (NSString *)eventWithParentEventNamesFromEvent:(NSString *)event
{
    LP_TRY
    NSMutableString *fullEventName = [NSMutableString string];
    LPActionContext *context = self;
    NSMutableArray *parents = [NSMutableArray array];
    while (context->_parentContext != nil) {
        [parents addObject:context];
        context = context->_parentContext;
    }
    NSString *actionName;
    for (NSInteger i = parents.count - 1; i >= -1; i--) {
        if (i > -1) {
            actionName = ((LPActionContext *) parents[i])->_key;
        } else {
            actionName = event;
        }
        if (actionName == nil) {
            fullEventName = nil;
            break;
        }
        actionName = [actionName stringByReplacingOccurrencesOfString:@" action"
                                                           withString:@""
                                                              options:NSCaseInsensitiveSearch
                                                                range:NSMakeRange(0,
                                                                                  actionName.length)
                      ];

        if (fullEventName.length) {
            [fullEventName appendString:@" "];
        }
        [fullEventName appendString:actionName];
    }

    return fullEventName;
    LP_END_TRY
}

- (void)runActionNamed:(NSString *)name
{
    LP_TRY
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext runActionNamed:] Empty name parameter provided."];
        return;
    }
    NSDictionary *args = [self getChildArgs:name];
    if (!args) {
        return;
    }

    // Chain to existing message.
    NSString *messageId = args[LP_VALUE_CHAIN_MESSAGE_ARG];
    NSString *actionType = args[LP_VALUE_ACTION_ARG];
    if (messageId && [actionType isEqualToString:LP_VALUE_CHAIN_MESSAGE_ACTION_NAME]) {
        NSDictionary *message = [LPVarCache messages][messageId];
        if (message) {
            LPActionContext *chainedActionContext =
                    [Leanplum createActionContextForMessageId:messageId];
            chainedActionContext.contextualValues = self.contextualValues;
            chainedActionContext->_preventRealtimeUpdating = _preventRealtimeUpdating;
            chainedActionContext->_isRooted = _isRooted;
            dispatch_async(dispatch_get_main_queue(), ^{
                [Leanplum triggerAction:chainedActionContext handledBlock:^(BOOL success) {
                    if (success) {
                        // Track when the chain message is viewed.
                        [[LPInternalState sharedState].actionManager
                         recordMessageImpression:[chainedActionContext messageId]];
                    }
                }];
            });
            return;
        }
    }

    LPActionContext *childContext = [LPActionContext
                                     actionContextWithName:args[LP_VALUE_ACTION_ARG]
                                     args:args messageId:_messageId];
    childContext.contextualValues = self.contextualValues;
    childContext->_preventRealtimeUpdating = _preventRealtimeUpdating;
    childContext->_isRooted = _isRooted;
    childContext->_parentContext = self;
    childContext->_key = name;
    dispatch_async(dispatch_get_main_queue(), ^{
        [Leanplum triggerAction:childContext];
    });
    LP_END_TRY
}

- (void)runTrackedActionNamed:(NSString *)name
{
    if (!IS_NOOP && _messageId && _isRooted) {
        if ([Utils isNullOrEmpty:name]) {
            [Leanplum throwError:@"[LPActionContext runTrackedActionNamed:] Empty name parameter "
             @"provided."];
            return;
        }
        [self trackMessageEvent:name withValue:0.0 andInfo:nil andParameters:nil];
    }
    [self runActionNamed:name];
}

- (void)trackMessageEvent:(NSString *)event withValue:(double)value andInfo:(NSString *)info
            andParameters:(NSDictionary *)params
{
    if (!IS_NOOP && _messageId) {
        event = [self eventWithParentEventNamesFromEvent:event];
        if (event) {
            [Leanplum track:event
                  withValue:value
                    andInfo:info
                    andArgs:@{LP_PARAM_MESSAGE_ID: _messageId}
              andParameters:params];
        }
    }
}

- (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params
{
    if (!IS_NOOP && _messageId) {
        [Leanplum track:event
              withValue:value
                andInfo:nil
                andArgs:@{LP_PARAM_MESSAGE_ID: _messageId}
          andParameters:params];
    }
}

- (void)muteFutureMessagesOfSameKind
{
    LP_TRY
    [[LPActionManager sharedManager] muteFutureMessagesOfKind:_messageId];
    LP_END_TRY
}

+ (void)sortByPriority:(NSMutableArray *)actionContexts
{
    [actionContexts sortUsingComparator:^(LPActionContext *contextA, LPActionContext *contextB) {
        NSNumber *priorityA = [contextA priority];
        NSNumber *priorityB = [contextB priority];
        return [priorityA compare:priorityB];
    }];
}

@end

@implementation LeanplumCompatibility

NSString *TYPE = @"&t";
NSString *EVENT_CATEGORY = @"&ec";
NSString *EVENT_ACTION = @"&ea";
NSString *EVENT_LABEL = @"&el";
NSString *EVENT_VALUE = @"&ev";
NSString *EXCEPTION_DESCRIPTION = @"&exd";
NSString *TRANSACTION_AFFILIATION = @"&ta";
NSString *ITEM_NAME = @"&in";
NSString *ITEM_CATEGORY = @"&iv";
NSString *SOCIAL_NETWORK = @"&sn";
NSString *SOCIAL_ACTION = @"&sa";
NSString *SOCIAL_TARGET = @"&st";
NSString *TIMING_NAME = @"&utv";
NSString *TIMING_CATEGORY = @"&utc";
NSString *TIMING_LABEL = @"&utl";
NSString *TIMING_VALUE = @"&utt";
NSString *CAMPAIGN_SOURCE = @"&cs";
NSString *CAMPAIGN_NAME = @"&cn";
NSString *CAMPAIGN_MEDUIM = @"&cm";
NSString *CAMPAIGN_CONTENT = @"&cc";

+ (NSString *)getEventNameFromParams:(NSMutableDictionary *)params andKeys:(NSArray *)keys
{
    NSMutableArray *resultValues = [[NSMutableArray alloc] init];
    for (NSString *key in keys) {
        if(params[key] && ![params[key] isKindOfClass:[NSNull class]]) {
            [resultValues addObject:params[key]];
            [params removeObjectForKey:key];
        }
    }
    return [resultValues componentsJoinedByString:@" "];
}

+ (void)gaTrack:(NSObject *)trackingObject
{
    LP_TRY
    if ([trackingObject isKindOfClass:[NSString class]]) {
        [Leanplum track:(NSString *)trackingObject];
    } else if ([trackingObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *trackingObjectDict = [trackingObject mutableCopy];
        NSString *event = @"";
        NSNumber *value = nil;

        // Event.
        if (trackingObjectDict[EVENT_CATEGORY] ||
            trackingObjectDict[EVENT_ACTION] ||
            trackingObjectDict[EVENT_LABEL]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                @[ EVENT_CATEGORY, EVENT_ACTION, EVENT_LABEL ]];
            if (trackingObjectDict[EVENT_VALUE] &&
                ![trackingObjectDict[EVENT_VALUE] isKindOfClass:[NSNull class]]) {
                value = (NSNumber *)trackingObjectDict[EVENT_VALUE];
            }
            if (value) {
                [trackingObjectDict removeObjectForKey:EVENT_VALUE];
            }
        // Exception.
        } else if (trackingObjectDict[EXCEPTION_DESCRIPTION]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                @[ EXCEPTION_DESCRIPTION, TYPE ]];
        // Transaction.
        } else if (trackingObjectDict[TRANSACTION_AFFILIATION]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                @[ TRANSACTION_AFFILIATION, TYPE ]];
        // Item.
        } else if (trackingObjectDict[ITEM_CATEGORY] ||
                   trackingObjectDict[ITEM_NAME]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                @[ ITEM_CATEGORY, ITEM_NAME, TYPE ]];
        // Social.
        } else if (trackingObjectDict[SOCIAL_NETWORK] ||
                   trackingObjectDict[SOCIAL_ACTION] ||
                   trackingObjectDict[SOCIAL_TARGET]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                @[ SOCIAL_NETWORK, SOCIAL_ACTION, SOCIAL_TARGET ]];
        // Timing.
        } else if (trackingObjectDict[TIMING_CATEGORY] ||
                   trackingObjectDict[TIMING_NAME] ||
                   trackingObjectDict[TIMING_LABEL]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                @[ TIMING_CATEGORY, TIMING_NAME, TIMING_LABEL, TYPE ]];
            if (trackingObjectDict[TIMING_VALUE] &&
                ![trackingObjectDict[TIMING_VALUE] isKindOfClass:[NSNull class]]) {
                value = (NSNumber *)trackingObjectDict[TIMING_VALUE];
            }
            if (value) {
                [trackingObjectDict removeObjectForKey:TIMING_VALUE];
            }
        // We are skipping traffic source events.
        } else if (trackingObjectDict[CAMPAIGN_MEDUIM] ||
                   trackingObjectDict[CAMPAIGN_CONTENT] ||
                   trackingObjectDict[CAMPAIGN_NAME] ||
                   trackingObjectDict[CAMPAIGN_SOURCE]) {
            return;
        } else {
            return;
        }

        // Clear NSNull values
        for(NSString *key in trackingObjectDict.allKeys) {
            if ([trackingObjectDict[key] isKindOfClass:[NSNull class]]) {
                [trackingObjectDict removeObjectForKey:key];
            }
        }

        // Event value.
        if (value) {
            [Leanplum track:event
                  withValue:value.doubleValue
              andParameters:trackingObjectDict];
        } else {
            [Leanplum track:event withParameters:trackingObjectDict];
        }
    }
    LP_END_TRY
}

@end
