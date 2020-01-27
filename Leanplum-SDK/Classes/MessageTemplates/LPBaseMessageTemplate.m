//
//  LPBaseMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseMessageTemplate.h"

@implementation LPBaseMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    self.contexts = contexts;
}

- (UIViewController *)visibleViewController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

@end
