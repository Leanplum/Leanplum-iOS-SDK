//
//  LPAppIconManager.h
//  Leanplum
//
//  Created by Alexis Oyama on 2/23/17.
//  Copyright (c) 2017 Leanplum. All rights reserved.
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
