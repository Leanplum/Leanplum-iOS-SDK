//
//  LPUIAlert.h
//  Show an alert with a callback block.
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "Constants.h"
#import <UIKit/UIKit.h>

typedef void (^LeanplumUIAlertCompletionBlock) (NSInteger buttonIndex);

@interface LPUIAlert : NSObject

+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles
                block:(LeanplumUIAlertCompletionBlock)block;

@end

#if LP_NOT_TV
@interface LPUIAlertView : UIAlertView <UIAlertViewDelegate> {
  @public
    LeanplumUIAlertCompletionBlock block;
}
@end
#endif
