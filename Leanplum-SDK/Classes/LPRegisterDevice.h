//
//  RegisterDevice.h
//  Leanplum
//
//  Created by Andrew First on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
