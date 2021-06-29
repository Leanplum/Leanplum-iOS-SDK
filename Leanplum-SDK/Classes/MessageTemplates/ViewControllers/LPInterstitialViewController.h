//
//  LPInterstitialViewController.h
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 31/03/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LPActionContext;

NS_ASSUME_NONNULL_BEGIN

@interface LPInterstitialViewController : UIViewController

@property (strong, nonatomic) LPActionContext *context;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

+(nullable LPInterstitialViewController *)instantiateFromStoryboard;

@end

NS_ASSUME_NONNULL_END
