//
//  LPAlertBaseMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseMessageTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPBaseAlertMessageTemplate : LPBaseMessageTemplate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)alertDismissedWithButtonIndex:(NSInteger)buttonIndex;

@end

NS_ASSUME_NONNULL_END
