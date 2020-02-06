//
//  LPBaseMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseMessageTemplate.h"

@implementation LPBaseMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    self.contexts = contexts;
}

- (UIViewController *)visibleViewController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

#pragma mark Interstitial logic

- (void)closePopupWithAnimation:(BOOL)animated
{
    [self closePopupWithAnimation:animated actionNamed:nil track:NO];
}

- (void)closePopupWithAnimation:(BOOL)animated
                    actionNamed:(NSString *)actionName
                          track:(BOOL)track
{
    if (!self.popupGroup) {
        return;
    }

    // UI can't be modified in background.
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self closePopupWithAnimation:animated actionNamed:actionName track:track];
        });
        return;
    }

    LPActionContext *context = self.contexts.lastObject;
    [self.contexts removeLastObject];

    if ([[context actionName] isEqualToString:LPMT_WEB_INTERSTITIAL_NAME] ||
        [[context actionName] isEqualToString:LPMT_HTML_NAME] ) {
        ((WKWebView *)_popupView).navigationDelegate = nil;
        [(WKWebView *)_popupView stopLoading];
    }

    void (^finishCallback)(void) = ^() {
        [self removeAllViewsFrom:self->_popupGroup];

        if (actionName) {
            if (track) {
                [context runTrackedActionNamed:actionName];
            } else {
                [context runActionNamed:actionName];
            }
        }
    };

    if (animated) {
        [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
            [self->_popupGroup setAlpha:0.0];
        } completion:^(BOOL finished) {
            finishCallback();
        }];
    } else {
        finishCallback();
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}

// Displays the Center Popup, Interstitial and Web Interstitial.
- (void)showPopup
{
    // UI can't be modified in background.
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self showPopup];
        });
        return;
    }

    LPActionContext *context = self.contexts.lastObject;
    BOOL isFullscreen = [context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME];
    BOOL isWeb = [context.actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME] ||
                 [context.actionName isEqualToString:LPMT_HTML_NAME];
    BOOL isPushAskToAsk = [context.actionName isEqualToString:LPMT_PUSH_ASK_TO_ASK];

    if (isWeb) {
        WKWebViewConfiguration* configuration = [WKWebViewConfiguration new];
        configuration.allowsInlineMediaPlayback = YES;
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

        _popupView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    } else {
        _popupView = [[UIView alloc] init];
    }

    self.popupGroup = [[UIView alloc] init];
    self.popupGroup.backgroundColor = [UIColor clearColor];
    if ([context.actionName isEqualToString:LPMT_HTML_NAME]) {
        _popupView.backgroundColor = [UIColor clearColor];
        [_popupView setOpaque:NO];
        ((WKWebView *)_popupView).scrollView.scrollEnabled = NO;
        ((WKWebView *)_popupView).scrollView.bounces = NO;
    }

    if (!isWeb) {
        [self setupPopupLayout:isFullscreen isPushAskToAsk:isPushAskToAsk];
    }

    [self.popupGroup addSubview:_popupView];
    if ((!isWeb || [context boolNamed:LPMT_HAS_DISMISS_BUTTON]) && !isPushAskToAsk) {
        // Dismiss button.
        self.dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.dismissButton.bounds = CGRectMake(0, 0, LPMT_DISMISS_BUTTON_SIZE, LPMT_DISMISS_BUTTON_SIZE);
        [self.dismissButton setBackgroundImage:[LPMessageTemplatesClass dismissImage:[UIColor colorWithWhite:.9 alpha:.9]
                                                                        withSize:LPMT_DISMISS_BUTTON_SIZE] forState:UIControlStateNormal];
        [self.dismissButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.dismissButton.adjustsImageWhenHighlighted = YES;
        self.dismissButton.layer.masksToBounds = YES;
        self.dismissButton.titleLabel.font = [UIFont systemFontOfSize:13];
        self.dismissButton.layer.borderWidth = 0;
        self.dismissButton.layer.cornerRadius = LPMT_DISMISS_BUTTON_SIZE / 2;
        [self.popupGroup addSubview:self.dismissButton];
    }

    [self.dismissButton addTarget:self action:@selector(dismiss)
             forControlEvents:UIControlEventTouchUpInside];

    [self refreshPopupContent];
    [self updatePopupLayout];

    [self.popupGroup setAlpha:0.0];
    [[UIApplication sharedApplication].keyWindow addSubview:self.popupGroup];
    [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
        [self->_popupGroup setAlpha:1.0];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


@end
