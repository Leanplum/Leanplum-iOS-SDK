//
//  LPFileTransferManager.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/1/19.
//  Copyright © 2019 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"
#import "LPNetworkFactory.h"
#import "LPRequesting.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPFileTransferManager : NSObject

+ (instancetype)sharedInstance;

- (void)sendFilesNow:(NSArray *)filenames;
- (void)downloadFile:(NSString *)path withCompletionHandler:(void (^__nullable)(NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
