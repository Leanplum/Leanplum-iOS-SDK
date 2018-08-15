//
//  UIAlertView+MKNetworkKitAdditions.m
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar (@mugunthkumar) on 11/11/11.
//  Copyright (C) 2011-2020 by Steinlogic

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
#import "UIAlertView+MKNetworkKitAdditions.h"

@implementation LPUIAlertNetworkAdditions

+(UIAlertView*) showWithError:(NSError*) networkError {

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[networkError localizedDescription]
                                                    message:[networkError localizedRecoverySuggestion]
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                          otherButtonTitles:nil];
    [alert show];
    return alert;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
+(UIAlertController *) showAlertWithError:(NSError*) networkError {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[networkError localizedDescription]
                                                                   message:[networkError localizedRecoverySuggestion]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"")
                                                     style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    
    // Recursively find the controller that can be shown
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (YES) {
        if ([controller isKindOfClass:[UINavigationController class]]) {
            controller = [(UINavigationController *)controller visibleViewController];
        } else if ([controller isKindOfClass:[UITabBarController class]]) {
            controller = [(UITabBarController *)controller selectedViewController];
        } else {
            [controller presentViewController:alert animated:YES completion:nil];
            break;
        }
    }
    return alert;
}
#endif


@end
#endif
