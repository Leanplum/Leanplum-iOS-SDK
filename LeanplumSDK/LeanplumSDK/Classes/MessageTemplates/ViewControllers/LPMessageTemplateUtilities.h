//
//  LPMessageTemplateUtilities.h
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 09/04/2020.
//  Copyright © 2022 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LPPopupViewController.h"
#import "LPInterstitialViewController.h"
#import "LPWebInterstitialViewController.h"
#import "LPActionContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPMessageTemplateUtilities: NSObject

+(void)presentOverVisible:(UIViewController *) viewController;
+(void)presentOverVisibleAsChild:(UIViewController *) viewController;
+(void)dismissExisitingViewController:(nullable void (^)(void)) completion;
+(UIViewController *) visibleViewController;
+(UIViewController *) topViewController;
@end

NS_ASSUME_NONNULL_END
