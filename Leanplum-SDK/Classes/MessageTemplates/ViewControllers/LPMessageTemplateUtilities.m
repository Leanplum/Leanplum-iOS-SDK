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
        // if topViewController is getting dismissed, get view controller that presented it and let it present our new view controller,
        // otherwise we can assume that our topViewController will be in view hierarchy when presenting new view controller
        if (topViewController.isBeingDismissed) {
            [[topViewController presentingViewController] presentViewController:viewController animated:YES completion:nil];
        } else {
            [topViewController presentViewController:viewController animated:YES completion:nil];
        }
    }];
}

+(void)dismissExisitingViewController:(nullable void (^)(void)) completion
{
    UIViewController *topViewController = [self visibleViewController];
    
    // Dismiss the view controller if another message will be presented (without user interaction)
    // Dismiss only html view controller for now
    if ([topViewController isKindOfClass:[LPWebInterstitialViewController class]]) {
        if (topViewController.isBeingDismissed) {
            completion();
        } else {
            [topViewController dismissViewControllerAnimated:NO completion:completion];
        }
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

+ (UIViewController *) topViewController
{
    UIViewController *topViewController = [self visibleViewController];
    
    if ([topViewController isKindOfClass:[UITabBarController class]]) {
        topViewController = [((UITabBarController *) topViewController) selectedViewController];
    }
    
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        topViewController = [((UINavigationController *) topViewController) visibleViewController];
    }
    
    if ([topViewController isKindOfClass:[UIPageViewController class]]) {
        topViewController = [[((UIPageViewController *) topViewController) viewControllers] objectAtIndex:0];
    }
    
    // UISplitViewController is not handled at the moment
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    // if topViewController is getting dismissed, get view controller that presented it and let it present our new view controller,
    // otherwise we can assume that our topViewController will be in view hierarchy when presenting new view controller
    if (topViewController.beingDismissed) {
        topViewController = [topViewController presentingViewController];
    }
    
    return topViewController;
}

@end
