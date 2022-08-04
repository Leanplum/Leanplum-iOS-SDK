//
//  LPOpenUrlMessageTemplate.m
//  Leanplum-iOS-SDK
//
//  Created by Mayank Sanganeria on 2/6/20.
//

#import "LPOpenUrlMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPOpenUrlMessageTemplate

@synthesize context;

+(void)defineAction
{
    [Leanplum defineAction:LPMT_OPEN_URL_NAME
                    ofKind:kLeanplumActionKindAction
             withArguments:@[
        [LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL]
    ]
               withOptions:@{}
            presentHandler:^BOOL(LPActionContext *context) {
        @try {
            LPOpenUrlMessageTemplate *template = [[LPOpenUrlMessageTemplate alloc] init];
            template.context = context;
            
            [template openURLWithCompletion:^(BOOL success) {
                /**
                 * When the action is dismissed, the ActionManager queue continues to perform actions.
                 * If the URL opens an external app or browser, there is a delay
                 * before UIApplication.willResignActiveNotification or UIScene.willDeactivateNotification are executed.
                 * This delay causes next actions in the queue to execute before the app resigns or application state changes.
                 * If there are other OpenURL actions in the queue, those actions will be perfomed by the ActionManager
                 * until the application resigns active (which pauses the main queue respectively the ActionManager queue).
                 * However, the application:openURL will fail to open them hence they will not be presented.
                 *
                 * This happens in the edge case where there are multiple Open URL actions executed one after another, likely when the queue was paused and actions were opened.
                 * Since real use case implications should be extremely minimal, the implementation is left as is.
                 * If a workaround should be added, dispatch the actionDismissed after a delay - pausing the queue when app willResign will not work due to the delay explained above.
                 * dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                 *     [context actionDismissed];
                 * });
                 */
                dispatch_async(dispatch_get_main_queue(), ^{
                    [context actionDismissed];
                });
            }];

            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    }
            dismissHandler:^BOOL(LPActionContext * _Nonnull context) {
        return NO;
    }];
}

- (void)openURLWithCompletion:(void (^ __nonnull)(BOOL success))completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *encodedURLString = [self urlEncodedStringFromString:[self.context stringNamed:LPMT_ARG_URL]];
        NSURL *url = [NSURL URLWithString: encodedURLString];
        [LPUtils openURL:url completionHandler:completion];
    });
}

- (NSString *)urlEncodedStringFromString:(NSString *)urlString {
    NSString *unreserved = @":-._~/?&=#+";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    return [urlString
            stringByAddingPercentEncodingWithAllowedCharacters:
            allowed];
}

@end
