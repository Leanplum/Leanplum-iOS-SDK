//
//  LPPopupViewController.h
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 31/03/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Leanplum.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPPopupViewController : UIViewController

@property (strong, nonatomic) LPActionContext *context;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end

NS_ASSUME_NONNULL_END
