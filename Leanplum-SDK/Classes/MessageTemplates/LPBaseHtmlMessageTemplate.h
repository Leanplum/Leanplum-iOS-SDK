//
//  LPBaseInterstitialMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseInterstitialMessageTemplate.h"
#import "LPHitView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPBaseHtmlMessageTemplate : LPBaseInterstitialMessageTemplate <WKNavigationDelegate>

@property  (nonatomic, assign) BOOL webViewNeedsFade;

@end

NS_ASSUME_NONNULL_END
