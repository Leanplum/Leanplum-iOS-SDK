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

#pragma mark Overriding Logic for HTML

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

    ((WKWebView *)self.popupView).navigationDelegate = nil;
    [(WKWebView *)self.popupView stopLoading];

    void (^finishCallback)(void) = ^() {
        [self removeAllViewsFrom:self.popupGroup];

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
            [self.popupGroup setAlpha:0.0];
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

- (void)setupPopupView {
    LPActionContext *context = self.contexts.lastObject;

    WKWebViewConfiguration* configuration = [WKWebViewConfiguration new];
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    self.popupView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];

    self.popupGroup = [[UIView alloc] init];
    self.popupGroup.backgroundColor = [UIColor clearColor];
    if ([context.actionName isEqualToString:LPMT_HTML_NAME]) {
        self.popupView.backgroundColor = [UIColor clearColor];
        [self.popupView setOpaque:NO];
        ((WKWebView *)self.popupView).scrollView.scrollEnabled = NO;
        ((WKWebView *)self.popupView).scrollView.bounces = NO;
    }

    [self.popupGroup addSubview:self.popupView];
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

- (void)setupPopupLayout:(BOOL)isFullscreen isPushAskToAsk:(BOOL)isPushAskToAsk
{
    self.popupBackground = [[UIImageView alloc] init];
    [self.popupView addSubview:self.popupBackground];
    self.popupBackground.contentMode = UIViewContentModeScaleAspectFill;
    if (!isFullscreen) {
        self.popupView.layer.cornerRadius = 12;
    }
    self.popupView.clipsToBounds = YES;

    // Accept button.
    self.acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.acceptButton.layer.cornerRadius = 6;
    self.acceptButton.adjustsImageWhenHighlighted = YES;
    self.acceptButton.layer.masksToBounds = YES;
    self.acceptButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.popupView addSubview:self.acceptButton];

    // Title.
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = ALIGN_CENTER;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    [self.popupView addSubview:self.titleLabel];

    // Message.
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.textAlignment = ALIGN_CENTER;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageLabel.backgroundColor = [UIColor clearColor];
    [self.popupView addSubview:self.messageLabel];

    // Overlay.
    self.overlayView = [UIButton buttonWithType:UIButtonTypeCustom];
    self.overlayView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];


    [self.popupGroup addSubview:self.overlayView];

    [self.acceptButton addTarget:self action:@selector(accept)
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
    self.popupGroup.transform = orientationTransform;

    CGSize screenSize = window.screen.bounds.size;
    self.popupGroup.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);

    CGFloat screenWidth = screenSize.width;
    CGFloat screenHeight = screenSize.height;

    if (orientation == UIDeviceOrientationLandscapeLeft ||
        orientation == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenSize.height;
        screenHeight = screenSize.width;
    }
    self.popupView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    self.popupView.center = CGPointMake(screenWidth / 2.0, screenHeight / 2.0);

    if ([context.actionName isEqualToString:LPMT_HTML_NAME]) {
        [self updateHtmlLayoutWithContext:context
                          statusBarHeight:statusBarHeight
                              screenWidth:screenWidth
                             screenHeight:screenHeight];
    }

    CGFloat leftSafeAreaX = safeAreaInsets.left;
    CGFloat dismissButtonX = screenWidth - self.dismissButton.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN / 2;
    CGFloat dismissButtonY = statusBarHeight + LPMT_ACCEPT_BUTTON_MARGIN / 2;
    self.dismissButton.frame = CGRectMake(dismissButtonX - leftSafeAreaX, dismissButtonY, self.dismissButton.frame.size.width,
                                      self.dismissButton.frame.size.height);
}

- (void)refreshPopupContent
{
    LPActionContext *context = self.contexts.lastObject;
    @try {
        NSString *actionName = [context actionName];
        if (self.popupGroup) {
            [self.popupGroup setHidden:YES];  // Keep hidden until load is done
            WKWebView *webView = (WKWebView *)self.popupView;
            self.webViewNeedsFade = YES;
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
            self.closePopupView = [[LPHitView alloc] initWithCallback:^{
                [self dismiss];
                [self.closePopupView removeFromSuperview];
            }];
            self.closePopupView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
            [[UIApplication sharedApplication].keyWindow addSubview:self.closePopupView];
            [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self.popupGroup];
        }

        CGFloat htmlX = (screenWidth - htmlWidth) / 2.;
        // Offset iPhoneX's safe area.
        if (isIPhoneX) {
            CGFloat bottomDistance = screenHeight - (htmlY + htmlHeight);
            if (bottomDistance < bottomSafeAreaHeight) {
                htmlHeight += bottomSafeAreaHeight;
            }
        }
        self.popupGroup.frame = CGRectMake(htmlX, htmlY, htmlWidth, htmlHeight);

    } else if (isIPhoneX) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            safeAreaInsets.left = 0;
            safeAreaInsets.right = 0;
            bottomSafeAreaHeight = 0;
        } else {
            safeAreaInsets.top = 0;
            safeAreaInsets.bottom = 0;
            bottomSafeAreaHeight = 0;
        }

        self.popupGroup.frame = CGRectMake(safeAreaInsets.left, safeAreaInsets.top,
                                       screenWidth - safeAreaInsets.left - safeAreaInsets.right,
                                       screenHeight - safeAreaInsets.top - bottomSafeAreaHeight);

        NSLog(@"frame dim %@ %@", NSStringFromCGRect(self.popupGroup.frame), NSStringFromCGSize(self.popupGroup.frame.size));
        NSLog(@"screen %f, %f", screenWidth, screenHeight);
        NSLog(@"insets %@", NSStringFromUIEdgeInsets(safeAreaInsets));
    }

    self.popupView.frame = self.popupGroup.bounds;
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

#pragma mark - WKWebViewDelegate methods

- (void)showWebview:(WKWebView *)webview {
    [self.popupGroup setHidden:NO];
    if (self.webViewNeedsFade) {
        self.webViewNeedsFade = NO;
        [self.popupGroup setAlpha:0.0];
        [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
            [self.popupGroup setAlpha:1.0];
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
