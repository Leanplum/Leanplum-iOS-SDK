//
//  LPApplication+Extensions.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 09/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPApplication+Extensions.h"
#import "LPPopupViewController.h"
#import "LPInterstitialViewController.h"
#import "LPWebInterstitialViewController.h"

@implementation UIApplication (Extensions)

+(void)presentOverVisible:(UIViewController *) viewController
{
    [self dismissExisitingViewController];

    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *presentedViewController = rootViewController.presentedViewController;

    while (presentedViewController) {
        presentedViewController = presentedViewController.presentedViewController;
    }

    if (presentedViewController) {
        [presentedViewController presentViewController:viewController animated:true completion:nil];
    } else {
        [rootViewController presentViewController:viewController animated:nil completion:nil];
    }
}

+(void)dismissExisitingViewController
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *presentedViewController = rootViewController.presentedViewController;

    // if its one of ours, dismiss it since we will present new one
    if ([presentedViewController isKindOfClass:[LPPopupViewController class]] ||
        [presentedViewController isKindOfClass:[LPInterstitialViewController class]] ||
        [presentedViewController isKindOfClass:[LPWebInterstitialViewController class]]) {

        [presentedViewController dismissViewControllerAnimated:true completion:nil];
    }
}

@end
