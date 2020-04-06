//
//  LPRegisterForPushMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRegisterForPushMessageTemplate.h"

@implementation LPRegisterForPushMessageTemplate

@synthesize context = _context;

+(void)defineAction
{
    [Leanplum defineAction:LPMT_REGISTER_FOR_PUSH
                    ofKind:kLeanplumActionKindAction
             withArguments:@[]
             withResponder:^BOOL(LPActionContext *context) {

        LPRegisterForPushMessageTemplate* template = [[LPRegisterForPushMessageTemplate alloc] init];
        template.context = context;

//        [template enableSystemPush];
        return YES;
    }];
}

@end
