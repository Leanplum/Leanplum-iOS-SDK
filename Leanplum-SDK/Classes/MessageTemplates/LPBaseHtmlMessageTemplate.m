//
//  LPBaseInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseHtmlMessageTemplate.h"
#import "LPJSON.h"

@implementation LPBaseHtmlMessageTemplate

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
    [self setupPopupView];
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

- (void)setupPopupView {
    LPActionContext *context = self.contexts.lastObject;


    WKWebViewConfiguration* configuration = [WKWebViewConfiguration new];
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    _popupView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];

    self.popupGroup = [[UIView alloc] init];
    self.popupGroup.backgroundColor = [UIColor clearColor];
    if ([context.actionName isEqualToString:LPMT_HTML_NAME]) {
        _popupView.backgroundColor = [UIColor clearColor];
        [_popupView setOpaque:NO];
        ((WKWebView *)_popupView).scrollView.scrollEnabled = NO;
        ((WKWebView *)_popupView).scrollView.bounces = NO;
    }

    [self.popupGroup addSubview:_popupView];
    if ([context boolNamed:LPMT_HAS_DISMISS_BUTTON]) {
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


    [_popupGroup addSubview:_overlayView];

    [_acceptButton addTarget:self action:@selector(accept)
                forControlEvents:UIControlEventTouchUpInside];
}

- (void)updatePopupLayout
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;

    LPActionContext *context = self.contexts.lastObject;

    UIEdgeInsets safeAreaInsets = [self safeAreaInsets];

    CGFloat statusBarHeight = ([[UIApplication sharedApplication] isStatusBarHidden]) ? safeAreaInsets.top
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
    _popupView.center = CGPointMake(screenWidth / 2.0, screenHeight / 2.0);

    if ([context.actionName isEqualToString:LPMT_HTML_NAME]) {
        [self updateHtmlLayoutWithContext:context
                          statusBarHeight:statusBarHeight
                              screenWidth:screenWidth
                             screenHeight:screenHeight];
    }

    CGFloat leftSafeAreaX = safeAreaInsets.left;
    CGFloat dismissButtonX = screenWidth - _dismissButton.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN / 2;
    CGFloat dismissButtonY = statusBarHeight + LPMT_ACCEPT_BUTTON_MARGIN / 2;
    _dismissButton.frame = CGRectMake(dismissButtonX - leftSafeAreaX, dismissButtonY, _dismissButton.frame.size.width,
                                      _dismissButton.frame.size.height);
}

- (void)refreshPopupContent
{
    LPActionContext *context = self.contexts.lastObject;
    @try {
        NSString *actionName = [context actionName];
        if (_popupGroup) {
            [_popupGroup setHidden:YES];  // Keep hidden until load is done
            WKWebView *webView = (WKWebView *)_popupView;
            _webViewNeedsFade = YES;
            webView.navigationDelegate = self;
            if (@available(iOS 11.0, *)) {
                webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
            if ([actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
                [webView loadRequest:[NSURLRequest requestWithURL:
                                    [NSURL URLWithString:[context stringNamed:LPMT_ARG_URL]]]];
            } else {
                if (@available(iOS 9.0, *))
                {
                    NSURL *htmlURL = [context htmlWithTemplateNamed:LPMT_ARG_HTML_TEMPLATE];
                    // Allow access to base folder.
                    NSString *path = [LPFileManager documentsPath];
                    NSURL* baseURL = [NSURL fileURLWithPath:path isDirectory:YES];

                    [webView loadFileURL:htmlURL allowingReadAccessToURL:baseURL];
                }
                else
                {
                    NSURL *htmlURL = [context htmlWithTemplateNamed:LPMT_ARG_HTML_TEMPLATE];
                    [webView loadRequest:[NSURLRequest requestWithURL:htmlURL]];
                }
            }
        }
    }
    @catch (NSException *exception) {
        LOG_LP_MESSAGE_EXCEPTION;
    }
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

- (void)updateHtmlLayoutWithContext:(LPActionContext *)context
                    statusBarHeight:(CGFloat)statusBarHeight
                        screenWidth:(CGFloat)screenWidth
                       screenHeight:(CGFloat)screenHeight
{
    // Calculate the height. Fullscreen by default.
    CGFloat htmlHeight = [[context numberNamed:LPMT_ARG_HTML_HEIGHT] doubleValue];
    BOOL isFullscreen = htmlHeight < 1;
    UIEdgeInsets safeAreaInsets = [self safeAreaInsets];
    CGFloat bottomSafeAreaHeight = safeAreaInsets.bottom;
    BOOL isIPhoneX = statusBarHeight > 40 || safeAreaInsets.left > 40 || safeAreaInsets.right > 40;

    // Banner logic.
    if (!isFullscreen) {
        // Calculate Y Offset.
        CGFloat yOffset = 0;
        NSString *contextArgYOffset = [context stringNamed:LPMT_ARG_HTML_Y_OFFSET];
        if (contextArgYOffset && [contextArgYOffset length] > 0) {
            CGFloat percentRange = screenHeight - htmlHeight - statusBarHeight;
            yOffset = [self valueFromHtmlString:contextArgYOffset percentRange:percentRange];
        }

        // HTML banner logic to support top/bottom alignment with dynamic size.
        CGFloat htmlY = yOffset + statusBarHeight;
        NSString *htmlAlign = [context stringNamed:LPMT_ARG_HTML_ALIGN];
        if ([htmlAlign isEqualToString:LPMT_ARG_HTML_ALIGN_BOTTOM]) {
            htmlY = screenHeight - htmlHeight - yOffset;
        }

        // Calculate HTML width by percentage or px (it parses any suffix for extra protection).
        NSString *contextArgWidth = [context stringNamed:LPMT_ARG_HTML_WIDTH] ?: @"100%";
        CGFloat htmlWidth = screenWidth;
        if (contextArgWidth && [contextArgWidth length] > 0) {
            htmlWidth = [self valueFromHtmlString:contextArgWidth percentRange:screenWidth];
        }

        // Tap outside to close Banner
        if ([context boolNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE]) {
            _closePopupView = [[LPHitView alloc] initWithCallback:^{
                [self dismiss];
                [self->_closePopupView removeFromSuperview];
            }];
            _closePopupView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
            [[UIApplication sharedApplication].keyWindow addSubview:_closePopupView];
            [[UIApplication sharedApplication].keyWindow bringSubviewToFront:_popupGroup];
        }

        CGFloat htmlX = (screenWidth - htmlWidth) / 2.;
        // Offset iPhoneX's safe area.
        if (isIPhoneX) {
            CGFloat bottomDistance = screenHeight - (htmlY + htmlHeight);
            if (bottomDistance < bottomSafeAreaHeight) {
                htmlHeight += bottomSafeAreaHeight;
            }
        }
        _popupGroup.frame = CGRectMake(htmlX, htmlY, htmlWidth, htmlHeight);

    } else if (isIPhoneX) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            safeAreaInsets.left = 0;
            safeAreaInsets.right = 0;
            bottomSafeAreaHeight = 0;
        }

        _popupGroup.frame = CGRectMake(safeAreaInsets.left, safeAreaInsets.top,
                                       screenWidth - safeAreaInsets.left - safeAreaInsets.right,
                                       screenHeight - safeAreaInsets.top - bottomSafeAreaHeight);

        NSLog(@"frame dim %@ %@", NSStringFromCGRect(_popupGroup.frame), NSStringFromCGSize(_popupGroup.frame.size));
        NSLog(@"screen %f, %f", screenWidth, screenHeight);
        NSLog(@"insets %@", NSStringFromUIEdgeInsets(safeAreaInsets));
    }

    _popupView.frame = _popupGroup.bounds;
}

/**
 * Get float value by parsing the html string that can have either % or px as a suffix.
 */
- (CGFloat)valueFromHtmlString:(NSString *)htmlString percentRange:(CGFloat)percentRange
{
    if (!htmlString || [htmlString length] == 0) {
        return 0;
    }

    if ([htmlString hasSuffix:@"%"]) {
        NSString *percentageValue = [htmlString stringByReplacingOccurrencesOfString:@"%"
                                                                          withString:@""];
        return percentRange * [percentageValue floatValue] / 100.;
    }

    NSCharacterSet *letterSet = [NSCharacterSet letterCharacterSet];
    NSArray *components = [htmlString componentsSeparatedByCharactersInSet:letterSet];
    return [[components componentsJoinedByString:@""] floatValue];
}

- (void)dismiss
{
    LP_TRY
    [self closePopupWithAnimation:YES];
    LP_END_TRY
}

#pragma mark - WKWebViewDelegate methods

- (void)showWebview:(WKWebView *)webview {
    [_popupGroup setHidden:NO];
    if (_webViewNeedsFade) {
        _webViewNeedsFade = NO;
        [_popupGroup setAlpha:0.0];
        [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
            [self->_popupGroup setAlpha:1.0];
        }];
    }
}

- (NSDictionary *)queryComponentsFromUrl:(NSString *)url {
    NSMutableDictionary *components = [NSMutableDictionary new];
    NSArray *urlComponents = [url componentsSeparatedByString:@"?"];
    if ([urlComponents count] > 1) {
        NSString *queryString = urlComponents[1];
        NSArray *parameters = [queryString componentsSeparatedByString:@"&"];
        for (NSString *parameter in parameters) {
            NSArray *parameterComponents = [parameter componentsSeparatedByString:@"="];
            if ([parameterComponents count] > 1) {
                components[parameterComponents[0]] = [parameterComponents[1]
                    stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            }
        }
    }
    return components;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (webView.isLoading) {
        return;
    }

    // Show for WEB INSTERSTITIAL. HTML will show after js loads the template.
    LPActionContext *context = self.contexts.lastObject;
    if ([[context actionName] isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
        [self showWebview:webView];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    LPActionContext *context = self.contexts.lastObject;
    @try {

        NSString *url = [navigationAction request].URL.absoluteString;
        NSDictionary *queryComponents = [self queryComponentsFromUrl:url];
        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_CLOSE]].location != NSNotFound) {
            [self dismiss];
            if (queryComponents[@"result"]) {
                [Leanplum track:queryComponents[@"result"]];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        // Only continue for HTML Template. Web Insterstitial will be deprecated.
        if ([[context actionName] isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }

        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_OPEN]].location != NSNotFound) {
            [self showWebview:webView];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_TRACK]].location != NSNotFound) {
            NSString *event = queryComponents[@"event"];
            if (event) {
                double value = [queryComponents[@"value"] doubleValue];
                NSString *info = queryComponents[@"info"];
                NSDictionary *parameters = [LPJSON JSONFromString:queryComponents[@"parameters"]];

                if (queryComponents[@"isMessageEvent"]) {
                    [context trackMessageEvent:event
                                     withValue:value
                                       andInfo:info
                                 andParameters: parameters];
                } else {
                    [Leanplum track:event withValue:value andInfo:info andParameters:parameters];
                }
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_ACTION]].location != NSNotFound) {
            if (queryComponents[@"action"]) {
                [self closePopupWithAnimation:YES actionNamed:queryComponents[@"action"] track:NO];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([url rangeOfString:
             [context stringNamed:LPMT_ARG_URL_TRACK_ACTION]].location != NSNotFound) {
            if (queryComponents[@"action"]) {
                [self closePopupWithAnimation:YES actionNamed:queryComponents[@"action"] track:YES];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    @catch (id exception) {
        // In case we catch exception here, hide the overlaying message.
        [self dismiss];
        // Handle the exception message.
        LOG_LP_MESSAGE_EXCEPTION;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
