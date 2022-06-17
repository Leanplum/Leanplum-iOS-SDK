//
//  LPIconChangeMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPIconChangeMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPIconChangeMessageTemplate

+(void)defineAction
{
    [Leanplum defineAction:LPMT_ICON_CHANGE_NAME
                    ofKind:kLeanplumActionKindAction
             withArguments:@[
        [LPActionArg argNamed:LPMT_ARG_APP_ICON withFile:LPMT_DEFAULT_APP_ICON]
    ]
               withOptions:@{}
            presentHandler:^BOOL(LPActionContext *context) {
        @try {
            LPIconChangeMessageTemplate *template = [[LPIconChangeMessageTemplate alloc] init];
            if ([template hasAlternateIcon]) {
                NSString *filename = [context stringNamed:LPMT_ARG_APP_ICON];
                [template setAlternateIconWithFilename:filename];
                return YES;
            }
            return NO;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
        }
        return NO;
    }
            dismissHandler:^BOOL(LPActionContext * _Nonnull context) {
        return NO;
    }];
}

- (BOOL)hasAlternateIcon
{
    NSDictionary *bundleIcons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];
    NSDictionary *alternativeIconsBundle = bundleIcons[@"CFBundleAlternateIcons"];
    return alternativeIconsBundle && alternativeIconsBundle.count > 0;
}

- (void)setAlternateIconWithFilename:(NSString *)filename
{
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setAlternateIconWithFilename:filename];
            return;
        });
    }

    NSString *iconName = [filename stringByReplacingOccurrencesOfString:LPMT_ICON_FILE_PREFIX
                                                             withString:@""];
    iconName = [iconName stringByReplacingOccurrencesOfString:@".png" withString:@""];

    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(setAlternateIconName:completionHandler:)] &&
        [app respondsToSelector:@selector(alternateIconName)]) {
        // setAlternateIconName:nil sets to the default icon.
        if (iconName && (iconName.length == 0 ||
                         [iconName isEqualToString:LPMT_ICON_PRIMARY_NAME])) {
            iconName = nil;
        }

        if (@available(iOS 10.3, *)) {
            NSString *currentIconName = [app alternateIconName];
            if ((iconName && [iconName isEqualToString:currentIconName]) ||
                (iconName == nil && currentIconName == nil)) {
                return;
            }
            [app setAlternateIconName:iconName completionHandler:^(NSError * error) {
                if (!error) {
                    return;
                }

                // Common failure is when setAlternateIconName: is called right upon start.
                // Try again after 1 second.
                LPLog(LPError, @"Fail to change app icon: %@. Trying again.", error);
                dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
                dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] setAlternateIconName:iconName
                                                          completionHandler:^(NSError *error) {
                        LPLog(LPError, @"Fail to change app icon: %@", error);
                    }];
                });
            }];
        }
    }
}

@end
