//
//  LPDeferMessageManager.m
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 26.08.20.
//

#import "LPDeferMessageManager.h"
#import "LeanplumInternal.h"
#import "LPMessageTemplateUtilities.h"
#import "LPMessageTemplateConstants.h"

@interface LPDeferMessageManager()
+ (BOOL)shouldDeferMessageForViewController:(id)viewController;
+ (void)triggerDeferredMessage;
@end

@implementation UIViewController (LeanplumExtension)
void leanplum_viewDidAppear(id self, SEL _cmd, BOOL animated);
void leanplum_viewDidAppear(id self, SEL _cmd, BOOL animated)
{
    ((void(*)(id, SEL, BOOL))LP_GET_ORIGINAL_IMP(@selector(viewDidAppear:)))(self, _cmd, animated);
    LP_TRY
    if (![LPDeferMessageManager shouldDeferMessageForViewController: self]) {
        [LPDeferMessageManager triggerDeferredMessage];
    }
    LP_END_TRY
}
@end

@implementation LPDeferMessageManager

static NSMutableArray<LPActionContext *> *deferredContexts;
static NSArray<NSString *> *deferredActionNames;
static NSArray<Class> *deferredClasses;
static BOOL isPresenting;

+ (void)setDeferredActionNames:(NSArray<NSString *> *)actionNames
{
    if (actionNames == nil) {
        actionNames = @[];
    }
    deferredActionNames = actionNames;
}

+ (void)setDeferredClasses:(NSArray<Class> *)classes
{
    if (classes == nil || classes.count == 0) {
        if ([deferredClasses count] > 0) {
            // Clear the deferred controllers
            deferredClasses = @[];
        }
        return;
    }

    deferredClasses = classes;
    
    if ([deferredActionNames count] == 0) {
        // Defer all built-in action names if non are provided
        deferredActionNames = [LPDeferMessageManager defaultMessageActionNames];
    }
    
    [LPDeferMessageManager swizzleViewDidAppearMethod];
}

+ (NSArray<NSString*> *)defaultMessageActionNames
{
    return @[LPMT_ALERT_NAME,
             LPMT_CONFIRM_NAME,
             LPMT_PUSH_ASK_TO_ASK,
             LPMT_CENTER_POPUP_NAME,
             LPMT_INTERSTITIAL_NAME,
             LPMT_WEB_INTERSTITIAL_NAME,
             LPMT_HTML_NAME,
             LPMT_ICON_CHANGE_NAME];
}

+ (BOOL)shouldDeferMessage:(LPActionContext *)context
{
    if ([deferredActionNames containsObject:[context actionName]]) {
        Class currentViewControllerClass = [[LPMessageTemplateUtilities topViewController] class];
        if ([deferredClasses containsObject:currentViewControllerClass]) {
            // TODO: Synchronize?
            if (deferredContexts == nil) {
                deferredContexts = [[NSMutableArray alloc]init];
            }
            [deferredContexts addObject:context];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)shouldDeferMessageForViewController:(id)viewController
{
    // TODO:
    // Uncomment to NOT show other messages on top of the alert dialog/controller
    // Add the other LP controllers here depending on the desired behavior
//    if ([viewController isMemberOfClass:[UIAlertController class]]) {
//        return YES;
//    }
    for (Class cl in deferredClasses) {
        if ([viewController isMemberOfClass:cl]) {
            return YES;
        }
    }
    return NO;
}

+(void)triggerDeferredMessage
{
    if ([deferredContexts count] == 0 || isPresenting) {
        return;
    }
    
    LPActionContext *firstContext = deferredContexts[0];
    [deferredContexts removeObjectAtIndex:0];
    isPresenting = YES;
    [Leanplum triggerAction:firstContext handledBlock:^(BOOL success) {
        isPresenting = NO;
        if (success) {
            [[LPInternalState sharedState].actionManager
             recordMessageImpression:[firstContext messageId]];
        }
    }];
}

+ (void)swizzleViewDidAppearMethod
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LP_TRY
        [LPSwizzle swizzleInstanceMethod:@selector(viewDidAppear:)
                                forClass:[UIViewController class]
                   withReplacementMethod:(IMP) leanplum_viewDidAppear];
        LP_END_TRY
    });
}

+(void)reset
{
    deferredContexts = nil;
    deferredClasses = nil;
}

@end
