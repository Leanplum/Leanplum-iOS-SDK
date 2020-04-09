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
    [self dismissExisitingViewControllers];

    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:viewController animated:YES completion:nil];
}

+(void)dismissExisitingViewControllers
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *presentedViewController = rootViewController.presentedViewController;

    if ([presentedViewController isKindOfClass:[LPPopupViewController class]] ||
        [presentedViewController isKindOfClass:[LPInterstitialViewController class]] ||
        [presentedViewController isKindOfClass:[LPWebInterstitialViewController class]]) {

        [presentedViewController dismissViewControllerAnimated:true completion:nil];
    }
}

@end
