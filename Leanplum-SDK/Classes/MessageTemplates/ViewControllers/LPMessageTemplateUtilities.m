//
//  LPMessageTemplateUtilities.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 09/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPMessageTemplateUtilities.h"
#import "LPPopupViewController.h"
#import "LPInterstitialViewController.h"
#import "LPWebInterstitialViewController.h"

@implementation LPMessageTemplateUtilities

+(void)presentOverVisible:(UIViewController *) viewController
{
    [self dismissExisitingViewController:^{
        UIViewController *topViewController = [self visibleViewController];
        [topViewController presentViewController:viewController animated:YES completion:nil];
    }];
}

+(void)dismissExisitingViewController:(nullable void (^)(void)) completion
{
    UIViewController *topViewController = [self visibleViewController];

    // dismiss on html view controller for now
    if ([topViewController isKindOfClass:[LPWebInterstitialViewController class]]) {
        [topViewController dismissViewControllerAnimated:NO completion:completion];
    } else {
        completion();
    }
}

+(UIViewController *) visibleViewController
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }

    return topViewController;
}

@end
