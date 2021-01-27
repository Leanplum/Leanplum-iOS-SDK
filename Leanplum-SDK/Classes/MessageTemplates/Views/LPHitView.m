//
//  LPHitView.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPHitView.h"

@implementation LPHitView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];

    if (!hitView) {
        return nil;
    }

    if (hitView != self || _shouldAllowTapToClose) {
        return hitView;
    }

    CGPoint convertedPoint = [self.touchDelegate convertPoint:point toView:self];

    return [self.touchDelegate hitTest:convertedPoint withEvent:event];
}

@end
