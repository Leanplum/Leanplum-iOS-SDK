//
//  LPPopupViewController.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 31/03/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPPopupViewController.h"
#import "LPMessageTemplateConstants.h"
#import "LPActionContext.h"

@interface LPPopupViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;

@end

@implementation LPPopupViewController

+(LPPopupViewController *)instantiateFromStoryboard
{
#ifdef SWIFTPM_MODULE_BUNDLE
    NSBundle *bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *bundle = [LPUtils leanplumBundle];
#endif
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Popup" bundle:bundle];

    return [storyboard instantiateInitialViewController];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!self.context) {
        return;
    }

    // width and height constraints
    self.widthConstraint.constant = [[self.context numberNamed:LPMT_ARG_LAYOUT_WIDTH] doubleValue];
    self.heightConstraint.constant = [[self.context numberNamed:LPMT_ARG_LAYOUT_HEIGHT] doubleValue];

    // background view params
    self.containerView.backgroundColor = [self.context colorNamed:LPMT_ARG_BACKGROUND_COLOR];
    self.containerView.layer.cornerRadius = 10;
    self.containerView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.containerView.layer.shadowRadius = 6.0;
    self.containerView.layer.shadowOpacity = 0.4;
    self.containerView.layer.shadowOffset = CGSizeZero;

    // title label params
    self.titleLabel.text = [self.context stringNamed:LPMT_ARG_TITLE_TEXT];
    self.titleLabel.textColor = [self.context colorNamed:LPMT_ARG_TITLE_COLOR];

    // message label params
    self.messageLabel.text = [self.context stringNamed:LPMT_ARG_MESSAGE_TEXT];
    self.messageLabel.textColor = [self.context colorNamed:LPMT_ARG_MESSAGE_COLOR];

    // accept button params
    [self.acceptButton setTitle:[self.context stringNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT]
                       forState:UIControlStateNormal];
    [self.acceptButton setTitleColor:[self.context colorNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR]
                            forState:UIControlStateNormal];
    [self.acceptButton setContentEdgeInsets:UIEdgeInsetsMake(10.0, 20.0, 10.0, 20.0)];
    self.acceptButton.backgroundColor = [self.context colorNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR];
    self.acceptButton.adjustsImageWhenHighlighted = YES;
    self.acceptButton.layer.masksToBounds = YES;
    self.acceptButton.layer.cornerRadius = 7;

    // background image view params
    self.backgroundImageView.image = [UIImage imageWithContentsOfFile:[self.context fileNamed:LPMT_ARG_BACKGROUND_IMAGE]];
    self.backgroundImageView.layer.cornerRadius = 10;
    self.backgroundImageView.layer.masksToBounds = YES;

    // if its pre push permission dialog, show cancel button
    if (self.shouldShowCancelButton) {
        [self.cancelButton setHidden:NO];
        [self.dismissButton setHidden:YES];

        // cancel button params
        [self.cancelButton setTitle:[self.context stringNamed:LPMT_ARG_CANCEL_BUTTON_TEXT]
                           forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[self.context colorNamed:LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR]
                                forState:UIControlStateNormal];
        [self.cancelButton setContentEdgeInsets:UIEdgeInsetsMake(10.0, 20.0, 10.0, 20.0)];
        self.cancelButton.backgroundColor = [self.context colorNamed:LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR];
        self.cancelButton.adjustsImageWhenHighlighted = YES;
        self.cancelButton.layer.masksToBounds = YES;
        self.cancelButton.layer.cornerRadius = 7;
    } else {
        [self.cancelButton setHidden:YES];
        [self.dismissButton setHidden:NO];
    }
}

- (IBAction)didTapAcceptButton:(id)sender
{
    if(self.acceptCompletionBlock != nil) {
        self.acceptCompletionBlock();
    }
    [self.context runTrackedActionNamed:LPMT_ARG_ACCEPT_ACTION];
    [self dismiss:YES];
}

- (IBAction)didTapCancelButton:(id)sender
{
    [self.context runTrackedActionNamed:LPMT_ARG_CANCEL_ACTION];
    [self dismiss:YES];
}

- (IBAction)didTapDismissButton:(id)sender
{
    [self.context runActionNamed:LPMT_ARG_DISMISS_ACTION];
    [self dismiss:YES];
}

- (void)dismiss:(BOOL)animated
{
    if (self.navigationController) {
        [self.navigationController dismissViewControllerAnimated:animated completion:^{
            [self.context actionDismissed];
        }];
    } else {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:^{
        [self.context actionDismissed];
        if (completion) {
            completion();
        }
    }];
}

@end
