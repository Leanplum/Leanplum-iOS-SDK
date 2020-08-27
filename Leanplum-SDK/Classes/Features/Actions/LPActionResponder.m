//
//  LPActionResponder.m
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 25.08.20.
//

#import "LPActionResponder.h"

@interface LPActionResponder()
@property (readwrite, copy) LeanplumActionBlock actionBlock;
@property (readwrite) BOOL isPostponable;
@end

@implementation LPActionResponder

+ (LPActionResponder *)initWithResponder:(LeanplumActionBlock)responder
{
    LPActionResponder *instance = [LPActionResponder new];
    instance.actionBlock = responder;
    return instance;
}

+ (LPActionResponder *)initWithPostponableResponder:(LeanplumActionBlock)responder
{
    LPActionResponder *instance = [self initWithResponder:responder];
    instance.isPostponable = YES;
    return instance;
}

@end
