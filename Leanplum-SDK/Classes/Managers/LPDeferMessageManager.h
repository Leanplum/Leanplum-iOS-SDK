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

+ (void)setDeferredActionNames:(NSArray<NSString*> *)actionNames;
+ (void)setDeferredClasses:(NSArray<Class> *)classes;
+ (BOOL)shouldDeferMessage:(LPActionContext *)context;
+ (NSArray<NSString*> *)defaultMessageActionNames;

@end

NS_ASSUME_NONNULL_END
