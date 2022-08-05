//
//  LPActionContextNotification.m
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 4.08.22.
//

#import "LPActionContextNotification.h"
#import "LPActionContext-Internal.h"
#import "LPMessageTemplateConstants.h"

@implementation LPActionContextNotification

- (void)runTrackedActionNamed:(NSString *)name
{
    if ([name isEqualToString:LPMT_ARG_ACCEPT_ACTION]) {
        [super runTrackedActionNamed:LP_VALUE_DEFAULT_PUSH_ACTION];
        return;
    }
    
    [super runTrackedActionNamed:name];
}

- (LPActionContext *)parentContext {
    /**
     * Return a parent context
     * so action is treated as embedded action by the ActionManager
     * hence no impression is tracked.
     *
     * No impression for this context should be tracked,
     * otherwise it will result to another Sent event of the Push Notification.
     */
    NSString *name = NSStringFromClass([self class]);
    return [LPActionContext actionContextWithName:name args:@{} messageId:nil];
}

@end
