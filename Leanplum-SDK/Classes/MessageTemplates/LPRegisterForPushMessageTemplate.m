//
//  LPRegisterForPushMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRegisterForPushMessageTemplate.h"
#import "LPPrePushMessageTemplate.h"

@implementation LPRegisterForPushMessageTemplate

@synthesize context;

+(void)defineAction
{
    [Leanplum defineAction:LPMT_REGISTER_FOR_PUSH
                    ofKind:kLeanplumActionKindAction
             withArguments:@[]
             withResponder:^BOOL(LPActionContext *context) {

        // TODO: when push check is moved away from templates, refactor to call it.
        LPPrePushMessageTemplate* template = [[LPPrePushMessageTemplate alloc] init];
        template.context = context;

        [template enableSystemPush];
        return YES;
    }];
}

@end
