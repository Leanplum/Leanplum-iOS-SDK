//
//  RegisterDevice.m
//  Leanplum
//
//  Created by Andrew First on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LPRegisterDevice.h"
#import "LeanplumRequest.h"
#import "Constants.h"

@implementation LPRegisterDevice

- (id)initWithCallback:(LeanplumStartBlock)callback_
{
    if (self = [super init]) {
        self->callback = callback_;
    }
    return self;
}

- (void)showError:(NSString *)message
{
    NSLog(@"Leanplum: Device registration error: %@", message);
    self->callback(NO);
}

- (void)registerDevice:(NSString *)email
{
    LeanplumRequest *request = [LeanplumRequest post:LP_METHOD_REGISTER_FOR_DEVELOPMENT
                                              params:@{ LP_PARAM_EMAIL: email }];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        LP_TRY
        NSDictionary* registerResponse = [LPResponse getLastResponse:json];
        BOOL isSuccess = [LPResponse isResponseSuccess:registerResponse];
        if (isSuccess) {
            self->callback(YES);
        } else {
            [self showError:[LPResponse getResponseError:registerResponse]];
        }
        LP_END_TRY
    }];
    [request onError:^(NSError *error) {
        [self showError:[error localizedDescription]];
    }];
    [request sendNow];
}

@end
