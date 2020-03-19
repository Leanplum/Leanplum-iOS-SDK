//
//  LPBaseInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseInterstitialMessageTemplate.h"
#import "LPJSON.h"

@implementation LPBaseInterstitialMessageTemplate

#pragma mark Interstitial logic

- (void)accept
{
    [self closePopupWithAnimation:YES actionNamed:LPMT_ARG_ACCEPT_ACTION track:YES];
}

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

    void (^finishCallback)(void) = ^() {
        [self removeAllViewsFrom:self->_popupGroup];
        UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
        UIView *mainView = mainWindow.subviews.lastObject;
        [[UIApplication sharedApplication] setAccessibilityElements:@[mainWindow, mainView]];
        mainWindow.isAccessibilityElement = NO;
        mainView.isAccessibilityElement = NO;

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
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
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
    [self setupPopupView];
    [self.popupGroup setAlpha:0.0];
    [self addPopupGroupInKeyWindowAndSetupAccessibilityElement];
    
    [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
        [self->_popupGroup setAlpha:1.0];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                            name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)setupPopupView {
    LPActionContext *context = self.contexts.lastObject;
    BOOL isFullscreen = [context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME];
    BOOL isPushAskToAsk = [context.actionName isEqualToString:LPMT_PUSH_ASK_TO_ASK];

    _popupView = [[UIView alloc] init];

    self.popupGroup = [[UIView alloc] init];
    self.popupGroup.backgroundColor = [UIColor clearColor];

    [self setupPopupLayout:isFullscreen isPushAskToAsk:isPushAskToAsk];

    [self.popupGroup addSubview:_popupView];
    if (!isPushAskToAsk) {
        // Dismiss button.
        self.dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.dismissButton.bounds = CGRectMake(0, 0, LPMT_DISMISS_BUTTON_SIZE, LPMT_DISMISS_BUTTON_SIZE);
        [self.dismissButton setBackgroundImage:[self dismissImage:[UIColor colorWithWhite:.9 alpha:.9]
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
}

- (void)addPopupGroupInKeyWindowAndSetupAccessibilityElement {
    //set accessibility elemements for VoiceOver
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *mainView = mainWindow.subviews.lastObject;
    [mainWindow addSubview:self.popupGroup];
    [[UIApplication sharedApplication] setAccessibilityElements:@[mainWindow, mainView, self.popupGroup]];
    mainWindow.isAccessibilityElement = YES;
    mainView.isAccessibilityElement = YES;
    self.popupGroup.isAccessibilityElement = NO;
    [self setFocusForAccessibilityElement:_popupView];
}

- (void)setFocusForAccessibilityElement:(UIView *)accessibleView {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
    accessibleView);
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    if (self.popupGroup != nil) {
        UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
        UIView *lastView = mainWindow.subviews.lastObject;
        [self setFocusForAccessibilityElement:lastView];
    }
}

- (void)removeAllViewsFrom:(UIView *)view
{
    [view.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [self removeAllViewsFrom:obj];
    }];
    [view removeFromSuperview];
    view = nil;
}

- (void)orientationDidChange:(NSNotification *)notification
{
    UIDevice *device = notification.object;
    // Bug with iOS, calls orientation did change even without change,
    // Check if the orientation is not changed than before.
    if (_orientation != device.orientation) {
        _orientation = device.orientation;
        [self updatePopupLayout];

        // isStatusBarHidden is not updated synchronously
        LPActionContext *conteext = self.contexts.lastObject;
        if ([conteext.actionName isEqualToString:LPMT_INTERSTITIAL_NAME]) {
            [self performSelector:@selector(updatePopupLayout) withObject:nil afterDelay:0];
        }
    }
}

- (void)setupPopupLayout:(BOOL)isFullscreen isPushAskToAsk:(BOOL)isPushAskToAsk
{
    _popupBackground = [[UIImageView alloc] init];
    [_popupView addSubview:_popupBackground];
    _popupBackground.contentMode = UIViewContentModeScaleAspectFill;
    if (!isFullscreen) {
        _popupView.layer.cornerRadius = 12;
    }
    _popupView.clipsToBounds = YES;

    // Accept button.
    _acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _acceptButton.layer.cornerRadius = 6;
    _acceptButton.adjustsImageWhenHighlighted = YES;
    _acceptButton.layer.masksToBounds = YES;
    _acceptButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_popupView addSubview:_acceptButton];

    if (isPushAskToAsk) {
        _acceptButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _acceptButton.layer.cornerRadius = 0;
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.layer.cornerRadius = 0;
        _cancelButton.adjustsImageWhenHighlighted = YES;
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_popupView addSubview:_cancelButton];
    }

    // Title.
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = ALIGN_CENTER;
    _titleLabel.font = [UIFont boldSystemFontOfSize:20];
    _titleLabel.backgroundColor = [UIColor clearColor];
    [_popupView addSubview:_titleLabel];

    // Message.
    _messageLabel = [[UILabel alloc] init];
    _messageLabel.textAlignment = ALIGN_CENTER;
    _messageLabel.numberOfLines = 0;
    _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _messageLabel.backgroundColor = [UIColor clearColor];
    [_popupView addSubview:_messageLabel];

    // Overlay.
    _overlayView = [UIButton buttonWithType:UIButtonTypeCustom];
    _overlayView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];

    if (!isFullscreen) {
        [_popupGroup addSubview:_overlayView];
    }

    if (isPushAskToAsk) {
        [_acceptButton addTarget:self action:@selector(enablePush)
                forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton addTarget:self action:@selector(deferPush)
                forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_acceptButton addTarget:self action:@selector(accept)
                forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)updatePopupLayout
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;

    LPActionContext *context = self.contexts.lastObject;

    BOOL fullscreen = [context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME];

    BOOL isPushAskToAsk = [context.actionName isEqualToString:LPMT_PUSH_ASK_TO_ASK];

    UIEdgeInsets safeAreaInsets = [self safeAreaInsets];

    CGFloat statusBarHeight = ([[UIApplication sharedApplication] isStatusBarHidden] || !fullscreen) ? safeAreaInsets.top
    : MIN([UIApplication sharedApplication].statusBarFrame.size.height,
          [UIApplication sharedApplication].statusBarFrame.size.width);

    UIInterfaceOrientation orientation;
    orientation = UIInterfaceOrientationPortrait;
    CGAffineTransform orientationTransform;
    switch (orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            orientationTransform = CGAffineTransformMakeRotation(M_PI);
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientationTransform = CGAffineTransformMakeRotation(M_PI / 2);
            break;
        case UIDeviceOrientationLandscapeRight:
            orientationTransform = CGAffineTransformMakeRotation(-M_PI / 2);
            break;
        default:
            orientationTransform = CGAffineTransformIdentity;
    }
    _popupGroup.transform = orientationTransform;

    CGSize screenSize = window.screen.bounds.size;
    _popupGroup.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);

    CGFloat screenWidth = screenSize.width;
    CGFloat screenHeight = screenSize.height;

    if (orientation == UIDeviceOrientationLandscapeLeft ||
        orientation == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenSize.height;
        screenHeight = screenSize.width;
    }
    _popupView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    if (!fullscreen) {
        _popupView.frame = CGRectMake(0, 0, [[context numberNamed:LPMT_ARG_LAYOUT_WIDTH] doubleValue],
                                      [[context numberNamed:LPMT_ARG_LAYOUT_HEIGHT] doubleValue]);
    }
    _popupView.center = CGPointMake(screenWidth / 2.0, screenHeight / 2.0);

    [self updateNonWebPopupLayout:statusBarHeight isPushAskToAsk:isPushAskToAsk];
        _overlayView.frame = CGRectMake(0, 0, screenWidth, screenHeight);

    CGFloat leftSafeAreaX = safeAreaInsets.left;
    CGFloat dismissButtonX = screenWidth - _dismissButton.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN / 2;
    CGFloat dismissButtonY = statusBarHeight + LPMT_ACCEPT_BUTTON_MARGIN / 2;
    if (!fullscreen) {
        dismissButtonX = _popupView.frame.origin.x + _popupView.frame.size.width - 3 * _dismissButton.frame.size.width / 4;
        dismissButtonY = _popupView.frame.origin.y - _dismissButton.frame.size.height / 4;
    }

    _dismissButton.frame = CGRectMake(dismissButtonX - leftSafeAreaX, dismissButtonY, _dismissButton.frame.size.width,
                                      _dismissButton.frame.size.height);
}

- (void)refreshPopupContent
{
    LPActionContext *context = self.contexts.lastObject;
    @try {
        NSString *actionName = [context actionName];
        if (_popupGroup) {
            _popupBackground.image = [UIImage imageWithContentsOfFile:
                                      [context fileNamed:LPMT_ARG_BACKGROUND_IMAGE]];
            _popupBackground.backgroundColor = [context colorNamed:LPMT_ARG_BACKGROUND_COLOR];
            [_acceptButton setTitle:[context stringNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT]
                           forState:UIControlStateNormal];
            [_acceptButton setBackgroundImage:[self imageFromColor:
                                               [context colorNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR]]
                                     forState:UIControlStateNormal];
            [_acceptButton setTitleColor:[context colorNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR]
                                forState:UIControlStateNormal];
            if (_cancelButton) {
                [_cancelButton setTitle:[context stringNamed:LPMT_ARG_CANCEL_BUTTON_TEXT]
                               forState:UIControlStateNormal];
                [_cancelButton setBackgroundImage:[self imageFromColor:
                                                   [context colorNamed:LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR]]
                                         forState:UIControlStateNormal];
                [_cancelButton setTitleColor:[context colorNamed:LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR]
                                    forState:UIControlStateNormal];
            }
            _titleLabel.text = [context stringNamed:LPMT_ARG_TITLE_TEXT];
            _titleLabel.textColor = [context colorNamed:LPMT_ARG_TITLE_COLOR];
            _messageLabel.text = [context stringNamed:LPMT_ARG_MESSAGE_TEXT];
            _messageLabel.textColor = [context colorNamed:LPMT_ARG_MESSAGE_COLOR];
            [self updatePopupLayout];
        }
    }
    @catch (NSException *exception) {
        LOG_LP_MESSAGE_EXCEPTION;
    }
}

- (void)updateNonWebPopupLayout:(int)statusBarHeight isPushAskToAsk:(BOOL)isPushAskToAsk
{
    _popupBackground.frame = CGRectMake(0, 0, _popupView.frame.size.width, _popupView.frame.size.height);
    CGSize textSize = [self getTextSizeFromButton:_acceptButton];

    if (isPushAskToAsk) {
        CGSize cancelTextSize = [self getTextSizeFromButton:_cancelButton];
        textSize = CGSizeMake(MAX(textSize.width, cancelTextSize.width),
                              MAX(textSize.height, cancelTextSize.height));
        _cancelButton.frame = CGRectMake(0,
                                         _popupView.frame.size.height - textSize.height - 2*LPMT_TWO_BUTTON_PADDING,
                                         _popupView.frame.size.width / 2,
                                         textSize.height + 2*LPMT_TWO_BUTTON_PADDING);
        _acceptButton.frame = CGRectMake(_popupView.frame.size.width / 2,
                                         _popupView.frame.size.height - textSize.height - 2*LPMT_TWO_BUTTON_PADDING,
                                         _popupView.frame.size.width / 2,
                                         textSize.height + 2*LPMT_TWO_BUTTON_PADDING);
    } else {
        CGFloat acceptButtonY;
        LPActionContext *context = self.contexts.lastObject;
        if ([context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME]) {
            acceptButtonY = _popupView.frame.size.height - textSize.height - 3*LPMT_ACCEPT_BUTTON_MARGIN - [self safeAreaInsets].bottom;
        } else {
            acceptButtonY = _popupView.frame.size.height - textSize.height - 3*LPMT_ACCEPT_BUTTON_MARGIN;
        }
        _acceptButton.frame = CGRectMake(
                                         (_popupView.frame.size.width - textSize.width - 2*LPMT_ACCEPT_BUTTON_MARGIN) / 2,
                                         acceptButtonY,
                                         textSize.width + 2*LPMT_ACCEPT_BUTTON_MARGIN,
                                         textSize.height + 2*LPMT_ACCEPT_BUTTON_MARGIN);

    }
    _titleLabel.frame = CGRectMake(LPMT_ACCEPT_BUTTON_MARGIN, LPMT_ACCEPT_BUTTON_MARGIN + statusBarHeight,
                                   _popupView.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN * 2, LPMT_TITLE_LABEL_HEIGHT);
    _messageLabel.frame = CGRectMake(LPMT_ACCEPT_BUTTON_MARGIN,
                                     LPMT_ACCEPT_BUTTON_MARGIN * 2 + LPMT_TITLE_LABEL_HEIGHT + statusBarHeight,
                                     _popupView.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN * 2,
                                     _popupView.frame.size.height - LPMT_ACCEPT_BUTTON_MARGIN * 4 - LPMT_TITLE_LABEL_HEIGHT - LPMT_ACCEPT_BUTTON_HEIGHT - statusBarHeight);
}

- (CGSize)getTextSizeFromButton:(UIButton *)button
{
    UIFont* font = button.titleLabel.font;
    NSString *text = button.titleLabel.text;
    CGSize textSize = CGSizeZero;
    if ([text respondsToSelector:@selector(sizeWithAttributes:)]) {
        textSize = [text sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:font.fontName size:font.pointSize]}];
    } else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        textSize = [text sizeWithFont:[UIFont fontWithName:font.fontName size:font.pointSize]];
#pragma clang diagnostic pop
    }
    textSize.width = textSize.width > 50 ? textSize.width : LPMT_ACCEPT_BUTTON_WIDTH;
    textSize.height = textSize.height > 15 ? textSize.height : LPMT_ACCEPT_BUTTON_HEIGHT;
    return textSize;
}

// Creates the X icon used in the popup's dismiss button.
- (UIImage *)dismissImage:(UIColor *)color withSize:(int)size
{
    CGRect rect = CGRectMake(0, 0, size, size);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    int margin = size * 3 / 8;

    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextMoveToPoint(context, margin, margin);
    CGContextAddLineToPoint(context, size - margin, size - margin);
    CGContextMoveToPoint(context, size - margin, margin);
    CGContextAddLineToPoint(context, margin, size - margin);
    CGContextStrokePath(context);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

-(UIEdgeInsets)safeAreaInsets
{
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    if (@available(iOS 11.0, *)) {
        insets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    } else {
        insets.top = [[UIApplication sharedApplication] isStatusBarHidden] ? 0 : 20.0;
    }
    return insets;
}

// Creates a 1x1 image with the specified color.
- (UIImage *)imageFromColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)dismiss
{
    LP_TRY
    [self closePopupWithAnimation:YES];
    LP_END_TRY
}

@end
