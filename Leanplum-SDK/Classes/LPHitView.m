//
//  LPHitView.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPHitView.h"

@implementation LPHitView

- (id)initWithCallback:(void (^)(void))callback
{
    if (self = [super init]) {
        self.callback = [callback copy];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        if (self.callback) {
            self.callback();
        }
        return nil;
    }
    return hitView;
}

@end
