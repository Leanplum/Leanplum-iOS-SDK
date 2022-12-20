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

NS_ASSUME_NONNULL_BEGIN

@interface LPMessageTemplateUtilities: NSObject

+(void)presentOverVisible:(UIViewController *) viewController;
+(void)dismissExisitingViewController:(nullable void (^)(void)) completion;
+(UIViewController *) visibleViewController;
@end

NS_ASSUME_NONNULL_END
