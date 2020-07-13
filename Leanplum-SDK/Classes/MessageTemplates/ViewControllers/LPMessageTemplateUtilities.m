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

// TODO: Consider moving the defer logic here to the utilities
#import "LeanplumInternal.h"
#import "LPActionManager.h"
#import "LPInternalState.h"

@implementation UIViewController (LeanplumExtension)
void leanplum_viewDidAppear(id self, SEL _cmd, BOOL animated);
void leanplum_viewDidAppear(id self, SEL _cmd, BOOL animated)
{
    ((void(*)(id, SEL, BOOL))LP_GET_ORIGINAL_IMP(@selector(viewDidAppear:)))(self, _cmd, animated);
    LP_TRY
    [LPMessageTemplateUtilities runDeferredMessages:self];
    LP_END_TRY
}
@end

@implementation LPMessageTemplateUtilities

static NSMutableArray<LPActionContext *> *deferedContexts;
static NSArray<Class> *deferedClasses;
static BOOL isPresenting;

+(void)presentOverVisible:(UIViewController *) viewController
{
    [self dismissExisitingViewController:^{
        UIViewController *topViewController = [self visibleViewController];
        // if topViewController is getting dismissed, get view controller that presented it and let it present our new view controller,
        // otherwise we can assume that our topViewController will be in view hierarchy when presenting new view controller
        if (topViewController.beingDismissed) {
            [[topViewController presentingViewController] presentViewController:viewController animated:YES completion:nil];
        } else {
            [topViewController presentViewController:viewController animated:YES completion:nil];
        }
    }];
}

+(BOOL)presentOverVisible:(UIViewController *) viewController forContext:(LPActionContext *)context
{
    UIViewController *topViewController = [self visibleViewController];
    // if topViewController is getting dismissed, get view controller that presented it and let it present our new view controller,
    // otherwise we can assume that our topViewController will be in view hierarchy when presenting new view controller
    if (topViewController.beingDismissed) {
        topViewController = [topViewController presentingViewController];
    }
    
    if ([self shouldDeferMessage: topViewController.class]) {
        if (deferedContexts == nil) {
            deferedContexts = [[NSMutableArray alloc]init];
        }
        [deferedContexts addObject:context];
        return NO;
    }
    [self dismissExisitingViewController:^{
        [topViewController presentViewController:viewController animated:YES completion:nil];
    }];
    return YES;
}

+ (void)setDeferedVc:(NSArray<Class> *)controllers
{
    deferedClasses = controllers;
}

+ (BOOL)shouldDeferMessage:(Class)vcClass
{
    if ([deferedClasses containsObject:vcClass]) {
        return YES;
    }
    return NO;
}

+ (BOOL)shouldDeferMessageForVC:(id)vc
{
    if ([vc isMemberOfClass:[UIAlertController class]]) {
        return YES;
    }
    for (Class cl in deferedClasses) {
        if ([vc isMemberOfClass:cl]) {
            return YES;
        }
    }
    return NO;
}

+(void)runDeferredMessages:(id)vc
{
    if ([deferedContexts count] == 0 || isPresenting) {
        return;
    }
    
    if ([self shouldDeferMessageForVC: vc]) {
        return;
    }
    
    LPActionContext *firstContext = deferedContexts[0];
    [deferedContexts removeObjectAtIndex:0];
    isPresenting = YES;
                [Leanplum triggerAction:firstContext handledBlock:^(BOOL success) {
                    isPresenting = NO;
                    if (success) {
                        [[LPInternalState sharedState].actionManager
                             recordMessageImpression:[firstContext messageId]];
                    }
                }];
    
}

+ (void)swizzleMethods
{
    [LPSwizzle swizzleInstanceMethod:@selector(viewDidAppear:)
                                forClass:[UIViewController class]
                   withReplacementMethod:(IMP) leanplum_viewDidAppear];
}

+(void)dismissExisitingViewController:(nullable void (^)(void)) completion
{
    UIViewController *topViewController = [self visibleViewController];
    
    // dismiss html view controller for now
    if ([topViewController isKindOfClass:[LPWebInterstitialViewController class]]) {
        [topViewController dismissViewControllerAnimated:NO completion:completion];
    } else {
        completion();
    }
}

+(UIViewController *) visibleViewController
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        topViewController = [((UINavigationController *) topViewController) visibleViewController];
    }
    
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    return topViewController;
}

@end
