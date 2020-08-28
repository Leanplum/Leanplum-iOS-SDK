//
//  LPActionResponder.h
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 25.08.20.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPDeferrableAction : NSObject
@property (readonly, copy) LeanplumActionBlock actionBlock;
@property (readonly) BOOL isDeferrable;

+ (LPDeferrableAction *)initWithActionBlock:(LeanplumActionBlock)responder;

+ (LPDeferrableAction *)initWithDeferrableActionBlock:(LeanplumActionBlock)responder;

@end

NS_ASSUME_NONNULL_END
