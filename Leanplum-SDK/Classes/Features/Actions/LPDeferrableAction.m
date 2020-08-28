//
//  LPActionResponder.m
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 25.08.20.
//

#import "LPDeferrableAction.h"

@interface LPDeferrableAction()
@property (readwrite, copy) LeanplumActionBlock actionBlock;
@property (readwrite) BOOL isDeferrable;
@end

@implementation LPDeferrableAction

+ (LPDeferrableAction *)initWithActionBlock:(LeanplumActionBlock)responder
{
    LPDeferrableAction *instance = [LPDeferrableAction new];
    instance.actionBlock = responder;
    return instance;
}

+ (LPDeferrableAction *)initWithDeferrableActionBlock:(LeanplumActionBlock)responder
{
    LPDeferrableAction *instance = [self initWithActionBlock:responder];
    instance.isDeferrable = YES;
    return instance;
}

@end
