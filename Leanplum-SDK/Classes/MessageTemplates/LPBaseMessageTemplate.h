//
//  LPBaseMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"
#import "LPMessageTemplateConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPBaseMessageTemplate : NSObject

@property  (nonatomic, strong) NSMutableArray *contexts;

- (UIViewController *)visibleViewController;

- (void)defineActionWithContexts:(NSMutableArray *)contexts;

@end

NS_ASSUME_NONNULL_END
