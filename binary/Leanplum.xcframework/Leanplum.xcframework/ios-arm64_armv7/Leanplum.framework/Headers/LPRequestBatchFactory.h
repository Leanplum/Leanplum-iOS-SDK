//
//  LPRequestBatchFactory.h
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRequestBatch.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRequestBatchFactory : NSObject

+ (LPRequestBatch *)createNextBatch;
+ (void)deleteFinishedBatch:(LPRequestBatch *)batch;

@end

NS_ASSUME_NONNULL_END
