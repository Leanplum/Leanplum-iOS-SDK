//
//  LPInterstitialViewController.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 31/03/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPInterstitialViewController.h"
#import "LPMessageTemplateConstants.h"

@interface LPInterstitialViewController ()

@end

@implementation LPInterstitialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!self.context) {
        return;
    }

    self.view.backgroundColor = [self.context colorNamed:LPMT_ARG_BACKGROUND_COLOR];

    self.titleLabel.text = [self.context stringNamed:LPMT_ARG_TITLE_TEXT];
    self.titleLabel.textColor = [self.context colorNamed:LPMT_ARG_TITLE_COLOR];
    self.messageLabel.text = [self.context stringNamed:LPMT_ARG_MESSAGE_TEXT];
    self.messageLabel.textColor = [self.context colorNamed:LPMT_ARG_MESSAGE_COLOR];

    [self.acceptButton setTitle:[self.context stringNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT]
                       forState:UIControlStateNormal];
    [self.acceptButton setTitleColor:[self.context colorNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR]
                            forState:UIControlStateNormal];
    [self.acceptButton setContentEdgeInsets:UIEdgeInsetsMake(10.0, 20.0, 10.0, 20.0)];
    self.acceptButton.backgroundColor = [self.context colorNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR];
    self.acceptButton.adjustsImageWhenHighlighted = YES;
    self.acceptButton.layer.masksToBounds = YES;
    self.acceptButton.layer.cornerRadius = 7;

    self.backgroundImageView.image = [UIImage imageWithContentsOfFile:[self.context fileNamed:LPMT_ARG_BACKGROUND_IMAGE]];
}

- (IBAction)didTapAcceptButton:(id)sender
{
    [self.context runTrackedActionNamed:LPMT_ARG_ACCEPT_ACTION];
    [self dismiss:YES];
}

- (IBAction)didTapDismissButton:(id)sender
{
    [self dismiss:YES];
}

- (void)dismiss:(BOOL)animated
{
    if (self.navigationController) {
        [self.navigationController dismissViewControllerAnimated:animated completion:nil];
    } else {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
}

@end
