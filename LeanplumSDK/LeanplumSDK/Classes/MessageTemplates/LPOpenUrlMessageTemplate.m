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
             withArguments:@[[LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL]]
             withResponder:^BOOL(LPActionContext *context) {
        @try {
            LPOpenUrlMessageTemplate *template = [[LPOpenUrlMessageTemplate alloc] init];
            template.context = context;
            [template openURL];

            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    }];
}

- (void) openURL
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *encodedURLString = [self urlEncodedStringFromString:[self.context stringNamed:LPMT_ARG_URL]];
        NSURL *url = [NSURL URLWithString: encodedURLString];
        [LPUtils openURL:url];
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
