//
//  RegisterDevice.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Leanplum.h"

@interface LPRegisterDevice : NSObject {
@private
    LeanplumStartBlock callback;
}

- (id)initWithCallback:(LeanplumStartBlock)callback;
- (void)registerDevice:(NSString *)email;

@end
