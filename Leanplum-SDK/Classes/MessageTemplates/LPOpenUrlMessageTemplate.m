//
//  LPOpenUrlMessageTemplate.m
//  Leanplum-iOS-SDK
//
//  Created by Mayank Sanganeria on 2/6/20.
//

#import "LPOpenUrlMessageTemplate.h"

@implementation LPOpenUrlMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    [super defineActionWithContexts:contexts];

    [Leanplum defineAction:LPMT_OPEN_URL_NAME
                    ofKind:kLeanplumActionKindAction
             withArguments:@[[LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL]]
             withResponder:^BOOL(LPActionContext *context) {
        @try {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *encodedURLString = [self urlEncodedStringFromString:[context stringNamed:LPMT_ARG_URL]];
                NSURL *url = [NSURL URLWithString: encodedURLString];
                if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                    if (@available(iOS 10.0, *)) {
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    [[UIApplication sharedApplication] openURL:url];
                }
            });
            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    }];
}

- (NSString *)urlEncodedStringFromString:(NSString *)urlString {
    NSString *unreserved = @":-._~/?&=";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    return [urlString
            stringByAddingPercentEncodingWithAllowedCharacters:
            allowed];
}

@end
