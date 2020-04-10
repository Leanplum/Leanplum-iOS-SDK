//
//  LPHitView.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPHitView : UIView

@property (weak, nonatomic, nullable) UIView *touchDelegate;

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent * _Nullable )event;

@end
