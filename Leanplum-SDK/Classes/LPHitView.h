//
//  LPHitView.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPHitView : UIView

@property (strong, nonatomic) void (^callback)(void);

- (id)initWithCallback:(void (^)(void))callback;
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event;

@end

NS_ASSUME_NONNULL_END
