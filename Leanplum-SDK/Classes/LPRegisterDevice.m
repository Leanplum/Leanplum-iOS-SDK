//
//  RegisterDevice.m
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPRegisterDevice.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"
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
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        BOOL isSuccess = [LPResponse isResponseSuccess:response];
        if (isSuccess) {
            self->callback(YES);
        } else {
            [self showError:[LPResponse getResponseError:response]];
        }
        LP_END_TRY
    }];
    [request onError:^(NSError *error) {
        [self showError:[error localizedDescription]];
    }];
    [request sendNow];
}

@end
