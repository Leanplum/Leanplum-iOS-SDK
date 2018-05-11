//
//  LPAppIconManager.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Manages App Icon features that are supported from 10.3.
 */
@interface LPAppIconManager : NSObject

/**
 * Upload all alternative icon as pngs on dev mode. Will do nothing in production.
 */
+ (void)uploadAppIconsOnDevMode;

@end
