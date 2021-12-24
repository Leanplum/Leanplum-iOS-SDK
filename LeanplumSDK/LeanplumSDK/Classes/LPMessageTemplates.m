//
//  LPMessageTemplates.m
//  Leanplum
//
//  Created by Andrew First on 9/12/13.
//  Copyright 2013 Leanplum, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  1. The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  2. This software and its derivatives may only be used in conjunction with the
//  Leanplum SDK within apps that have a valid subscription to the Leanplum platform,
//  at http://www.leanplum.com
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "LPMessageTemplates.h"
#import <QuartzCore/QuartzCore.h>
#import <StoreKit/StoreKit.h>
#import "LPCountAggregator.h"
#import "LPOpenUrlMessageTemplate.h"
#import "LPPushAskToAskMessageTemplate.h"
#import "LPRegisterForPushMessageTemplate.h"
#import "LPCenterPopupMessageTemplate.h"
#import "LPInterstitialMessageTemplate.h"
#import "LPWebInterstitialMessageTemplate.h"
#import "LPRichInterstitialMessageTemplate.h"
#import "LPAlertMessageTemplate.h"
#import "LPConfirmMessageTemplate.h"
#import "LPAppRatingMessageTemplate.h"
#import "LPIconChangeMessageTemplate.h"
#import "LeanplumInternal.h"
#import <Leanplum/Leanplum-Swift.h>

#define APP_NAME (([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]) ?: \
    ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]))

@implementation LPMessageTemplatesClass

#pragma mark Initialization

+ (LPMessageTemplatesClass *)sharedTemplates
{
    static LPMessageTemplatesClass *sharedTemplates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTemplates = [[self alloc] init];
    });
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"shared_templates"];
    
    return sharedTemplates;
}

- (id)init
{
    if (self = [super init]) {
        [self defineActions];
    }
    return self;
}

// Defines the preset in-app messaging and action templates.
// The presets are:
//   Alert: Displays a system UIAlertVIew with a single button
//   Confirm: Displays a system UIAlertView with two buttons
//   Open URL: Opens a URL, that can be either handled by the app or in the browser
//   Center Popup: Displays a custom message centered in the middle of the screen
//   Interstitial: Displays a full-screen message
//   Web Interstitial: Displays a full-screen web view.
// There are two types of actions: regular actions and message templates.
// Regular actions are indicated with the flag kLeanplumActionKindAction,
// and message templates are indicated with the flag kLeanplumActionKindMessage.
// These flags control where these options show up in the dashboard.
// Please give us suggestions for other types of messages!
- (void)defineActions
{
    [LPCenterPopupMessageTemplate defineAction];
    [LPInterstitialMessageTemplate defineAction];
    [LPWebInterstitialMessageTemplate defineAction];
    [LPRichInterstitialMessageTemplate defineAction];
    [LPOpenUrlMessageTemplate defineAction];
    [LPRegisterForPushMessageTemplate defineAction];
    [LPAppRatingMessageTemplate defineAction];
    [LPIconChangeMessageTemplate defineAction];
    [LPPushAskToAskMessageTemplate defineAction];
    [LPAlertMessageTemplate defineAction];
    [LPConfirmMessageTemplate defineAction];
}

// If notification were enabled by Leanplum's "Push Ask to Ask" or "Register For Push",
// refreshPushPermissions will do the same registration for subsequent app sessions.
// refreshPushPermissions is called by [Leanplum start].
- (void)refreshPushPermissions
{
    [[Leanplum notificationsManager] refreshPushPermissions];
}

- (void)disableAskToAsk
{
    [Leanplum notificationsManager].isAskToAskDisabled = YES;
}

@end
