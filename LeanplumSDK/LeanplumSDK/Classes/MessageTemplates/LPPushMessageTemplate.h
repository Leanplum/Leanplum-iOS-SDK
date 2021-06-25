//
//  LPPushMessageTemplate.h
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 19.08.20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPPushMessageTemplate : NSObject

- (BOOL)shouldShowPushMessage;

- (void)showNativePushPrompt;

- (BOOL)isPushEnabled;

- (BOOL)hasDisabledAskToAsk;

@end

NS_ASSUME_NONNULL_END
