//
//  LPActionManager.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "Leanplum.h"

#import <Foundation/Foundation.h>
#if LP_NOT_TV
#import <UserNotifications/UserNotifications.h>
#endif

@interface LPContextualValues : NSObject

@property (nonatomic) NSDictionary *parameters;
@property (nonatomic) NSDictionary *arguments;
@property (nonatomic) id previousAttributeValue;
@property (nonatomic) id attributeValue;

@end
