//
//  LPPushAskToAskMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPPushAskToAskMessageTemplate.h"

static NSString *DEFAULTS_ASKED_TO_PUSH = @"__Leanplum_asked_to_push";
static NSString *DEFAULTS_LEANPLUM_ENABLED_PUSH = @"__Leanplum_enabled_push";

@implementation LPPushAskToAskMessageTemplate

@synthesize context;

+(void)defineAction
{
    // might be common with others
    UIColor *defaultButtonTextColor = [UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1];
    [Leanplum defineAction:LPMT_PUSH_ASK_TO_ASK
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_TITLE_TEXT withString:APP_NAME],
                 [LPActionArg argNamed:LPMT_ARG_TITLE_COLOR
                             withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_TEXT
                            withString:LPMT_DEFAULT_ASK_TO_ASK_MESSAGE],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_COLOR
                             withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_IMAGE withFile:nil],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_COLOR
                             withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT
                            withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR
                             withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR
                             withColor:defaultButtonTextColor],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_ACTION withAction:nil],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_TEXT
                            withString:LPMT_DEFAULT_LATER_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR
                             withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR
                             withColor:[UIColor grayColor]],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_WIDTH
                            withNumber:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH)],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_HEIGHT
                            withNumber:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT)]
             ]
             withResponder:^BOOL(LPActionContext *context) {
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {
            // TODO: move push notifications check outside of templates
            
            LPPushAskToAskMessageTemplate *template = [[LPPushAskToAskMessageTemplate alloc] init];
            template.context = context;

            if ([Leanplum isPreLeanplumInstall]) {
                NSLog(@"Leanplum: 'Ask to ask' conservatively falls back to just 'ask' for pre-Leanplum installs");
                [template showPushMessage];
                return NO;
            } else if ([template isPushEnabled]) {
                NSLog(@"Leanplum: Pushes already enabled");
                return NO;
            } else if ([template hasDisabledAskToAsk]) {
                NSLog(@"Leanplum: Already asked to push");
                return NO;
            } else {
                [template showPrePushMessage];
                return YES;
            }
        } @catch (NSException *exception) {
            NSLog(@"Leanplum: Error in pushAskToAsk: %@\n%@", exception, [exception callStackSymbols]);
            return NO;
        }
    }];
}

-(void)showPushMessage
{
    [self enableSystemPush];
}

-(void)showPrePushMessage
{
    LPPopupViewController *viewController = [LPPopupViewController instantiateFromStoryboard];
    viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewController.context = self.context;

    [LPMessageTemplateUtilities presentOverVisible:viewController];
}

- (BOOL)isPushEnabled
{
    // Run on main thread.
    if (![NSThread isMainThread]) {
        BOOL __block output = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            output = [self isPushEnabled];
        });
        return output;
    }

    UIApplication *application = [UIApplication sharedApplication];
    BOOL enabled;

    // Try to use the newer isRegisteredForRemoteNotifications otherwise use the enabledRemoteNotificationTypes.
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        enabled = [application isRegisteredForRemoteNotifications];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
        enabled = types & UIRemoteNotificationTypeAlert;
#pragma clang diagnostic pop
    }
    return enabled;
}

- (void)enableSystemPush
{
    // The commented lines below are an alternative for iOS 8 that will deep link to the app in
    // device Settings.
    //    NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    //    [[UIApplication sharedApplication] openURL:appSettings];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_LEANPLUM_ENABLED_PUSH];

    // When system asks user for push notification we should also disable our dialog, because
    // if users accept/declines we don't want to show dialog anymore since system will block default one.
    [self disableAskToAsk];

    LeanplumPushSetupBlock block = [Leanplum pushSetupBlock];
    if (block) {
        // If the app used [Leanplum setPushSetup:...], call the block.
        block();
        return;
    }
    // Otherwise use boilerplate code from docs.
    id notificationCenterClass = NSClassFromString(@"UNUserNotificationCenter");
    if (notificationCenterClass) {
        // iOS 10.
        SEL selector = NSSelectorFromString(@"currentNotificationCenter");
        id notificationCenter =
        ((id (*)(id, SEL)) [notificationCenterClass methodForSelector:selector])
        (notificationCenterClass, selector);
        if (notificationCenter) {
            selector = NSSelectorFromString(@"requestAuthorizationWithOptions:completionHandler:");
            IMP method = [notificationCenter methodForSelector:selector];
            void (*func)(id, SEL, unsigned long long, void (^)(BOOL, NSError *__nullable)) =
            (void *) method;
            func(notificationCenter, selector,
                 0b111, /* badges, sounds, alerts */
                 ^(BOOL granted, NSError *__nullable error) {
                     if (error) {
                         NSLog(@"Leanplum: Failed to request authorization for user "
                               "notifications: %@", error);
                     }
                 });
        }
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else if ([[UIApplication sharedApplication] respondsToSelector:
                @selector(registerUserNotificationSettings:)]) {
            // iOS 8-9.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            UIUserNotificationSettings *settings = [UIUserNotificationSettings
                                                    settingsForTypes:UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
#pragma clang diagnostic pop
    }
}

// If notification were enabled by Leanplum's "Push Ask to Ask" or "Register For Push",
// refreshPushPermissions will do the same registration for subsequent app sessions.
// refreshPushPermissions is called by [Leanplum start].
- (void)refreshPushPermissions
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_LEANPLUM_ENABLED_PUSH]) {
        [self enableSystemPush];
    }
}

- (void)disableAskToAsk
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_ASKED_TO_PUSH];
}

- (BOOL)hasDisabledAskToAsk
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ASKED_TO_PUSH];
}

@end
