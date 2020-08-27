//
//  LPActionResponder.h
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 25.08.20.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPActionResponder : NSObject
@property (readonly, copy) LeanplumActionBlock actionBlock;
@property (readonly) BOOL isPostponable;

+ (LPActionResponder *)initWithResponder:(LeanplumActionBlock)responder;

+ (LPActionResponder *)initWithPostponableResponder:(LeanplumActionBlock)responder;

@end

NS_ASSUME_NONNULL_END
