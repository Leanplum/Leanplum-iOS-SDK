//
//  LPDeferMessageManager.h
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 26.08.20.
//

#import <Foundation/Foundation.h>
#import "LPActionContext-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPDeferMessageManager : NSObject

+ (void)setDeferredClasses:(NSArray<Class> *)classes;
+ (BOOL)shouldDeferMessage:(LPActionContext *)context;
+ (void)triggerDeferredMessage;

@end

NS_ASSUME_NONNULL_END
