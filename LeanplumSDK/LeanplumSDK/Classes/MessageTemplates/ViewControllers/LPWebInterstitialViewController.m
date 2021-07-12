//
//  LPWebInterstitialViewController.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 03/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPWebInterstitialViewController.h"
#import "LPMessageTemplateConstants.h"
#import "LPHitView.h"
#import "LPActionContext.h"

@interface LPWebInterstitialViewController ()

@property (nonatomic, strong) WKWebView *webView;
@property(nonatomic) UIDeviceOrientation orientation;
@property (nonatomic, assign) BOOL isBanner;

@end

@implementation LPWebInterstitialViewController

+(LPWebInterstitialViewController *)instantiateFromStoryboard
{
#ifdef SWIFTPM_MODULE_BUNDLE
    NSBundle *bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *bundle = [LPUtils leanplumBundle];
#endif
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"WebInterstitial" bundle:bundle];

    return [storyboard instantiateInitialViewController];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;

    // must be inserted at index 0
    [self.view insertSubview:self.webView atIndex:0];

    NSString* actionName = [self.context actionName];
    // configure and load web interstitial message
    if ([actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
        [self configureFullscreen];
        [self loadURL];
    } else if ([actionName isEqualToString:LPMT_HTML_NAME]) {
        CGFloat height = [[self.context numberNamed:LPMT_ARG_HTML_HEIGHT] doubleValue];
        self.isBanner = height > 0;

        if (self.isBanner) {
            [self configureBannerTemplate];
        } else {
            [self configureFullscreenTemplate];
        }

        [self loadTemplate];
    }

    // hide dismiss button if necessary
    if (![self.context boolNamed:LPMT_HAS_DISMISS_BUTTON]) {
        [self.dismissButton setHidden:YES];
    }

    // add gesture recognizer to close message if tap outside to close is set to true.
    BOOL tapOutside = [self.context boolNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE];
    if (tapOutside) {
        UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOutside)];
        [self.view addGestureRecognizer:gestureRecognizer];
    }
    
    // passthrough view to send touch events to underlaying ViewController
    LPHitView* passthroughView = (LPHitView *) self.view;
    if (passthroughView) {
        passthroughView.shouldAllowTapToClose = tapOutside;
        passthroughView.touchDelegate = self.presentingViewController.view;
    }
    
    _orientation = UIDevice.currentDevice.orientation;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

/// Fullscreen web interstitial configuration
- (void)configureFullscreen
{
    [self addFullscreenConstraints];
}

/// Fullscreen web template interstitial configuration
- (void)configureFullscreenTemplate
{
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.bounces = NO;

    self.view.backgroundColor = [UIColor clearColor];
    [self.view setOpaque:NO];

    self.webView.backgroundColor = [UIColor clearColor];
    [self.webView setOpaque:NO];

    [self addTemplateConstraints];
}

/// Banner template configuration
- (void)configureBannerTemplate
{
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.bounces = NO;

    self.view.backgroundColor = [UIColor clearColor];
    [self.view setOpaque:NO];

    self.webView.backgroundColor = [UIColor clearColor];
    [self.webView setOpaque:NO];

    [self addBannerConstraints];
}

- (void)loadTemplate
{
    NSURL *htmlURL = [self.context htmlWithTemplateNamed:LPMT_ARG_HTML_TEMPLATE];
    // Allow access to base folder.
    NSString *path = [LPFileManager documentsPath];
    NSURL* baseURL = [NSURL fileURLWithPath:path isDirectory:YES];

    if (htmlURL == nil || baseURL == nil) {
        [self dismiss:NO];
        return;
    }
    
    [self.webView loadFileURL:htmlURL allowingReadAccessToURL:baseURL];
}

- (void)loadURL
{
    NSString *url = [self.context stringNamed:LPMT_ARG_URL];
    
    if (url == nil) {
        [self dismiss:NO];
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request];
}

- (void)addFullscreenConstraints
{
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0] setActive:YES];
    [[self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0] setActive:YES];
    [[self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0] setActive:YES];
    [[self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0] setActive:YES];
}

- (void)addTemplateConstraints
{
    [self updateTemplateConstraints];
}

- (void)updateTemplateConstraints
{
    [self.view removeConstraints:[self.view constraints]];
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:NO];

    CGFloat top = 0;
    CGFloat bottom = 0;
    CGFloat left = 0;
    CGFloat right = 0;

    if (@available(iOS 11, *)) {
        top = -UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        bottom = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
        left = -UIApplication.sharedApplication.keyWindow.safeAreaInsets.left;
        right = UIApplication.sharedApplication.keyWindow.safeAreaInsets.right;
    }

    [[self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:top] setActive:YES];
    [[self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:bottom] setActive:YES];
    [[self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:left] setActive:YES];
    [[self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:right] setActive:YES];
}

- (void)addBannerConstraints
{
    [self updateBannerConstraints];
}

- (void)updateBannerConstraints
{
    NSString *alignArgument = [self.context stringNamed:LPMT_ARG_HTML_ALIGN];
    NSString *widthArgument = [self.context stringNamed:LPMT_ARG_HTML_WIDTH];
    NSString *heightArgument = [self.context stringNamed:LPMT_ARG_HTML_HEIGHT];

    CGFloat width = self.view.frame.size.width;
    CGFloat height = [heightArgument doubleValue];
    BOOL alignBottom = [alignArgument isEqualToString:LPMT_ARG_HTML_ALIGN_BOTTOM];

    if (widthArgument && [widthArgument length] > 0) {
        width = [self valueFromHtmlString:widthArgument percentRange:width];
    }

    [self.view removeConstraints:[self.view constraints]];
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    CGFloat top = 0;
    CGFloat left = 0;
    CGFloat right = 0;
    CGFloat bottom = 0;

    if (@available(iOS 11, *)) {
        top = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        bottom = -UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
        left = -UIApplication.sharedApplication.keyWindow.safeAreaInsets.left;
        right = UIApplication.sharedApplication.keyWindow.safeAreaInsets.right;
    }

    if (alignBottom) {
        [[self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:bottom] setActive:YES];
    } else {
        [[self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:top] setActive:YES];
    }
    [[self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:left] setActive:YES];
    [[self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:right] setActive:YES];

    // height constraint
    [[self.webView.heightAnchor constraintEqualToConstant:height] setActive:YES];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    LPActionContext *context = self.context;
    @try {
        NSString *url = [navigationAction request].URL.absoluteString;
        NSDictionary *queryComponents = [self queryComponentsFromUrl:url];

        // Handle AppStore links
        // Example URL: itms-apps://itunes.apple.com/us/app/id
        NSURL *navigationUrl = [navigationAction request].URL;
        if ([navigationUrl.scheme isEqualToString:LPMT_APP_STORE_SCHEMA])
        {
            UIApplication *app = [UIApplication sharedApplication];
            if ([app canOpenURL:navigationUrl])
            {
                [self.webView stopLoading];
                [LPUtils openURL:[NSURL URLWithString:url]];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            } else{
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }

        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_CLOSE]].location != NSNotFound) {
            [self.context runActionNamed:LPMT_ARG_DISMISS_ACTION];
            [self dismiss:YES];
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
                [self trackAction:queryComponents[@"action"] track:NO];
                [self dismiss:YES];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([url rangeOfString: [context stringNamed:LPMT_ARG_URL_TRACK_ACTION]].location != NSNotFound) {
            if (queryComponents[@"action"]) {
                [self trackAction:queryComponents[@"action"] track:YES];
                [self dismiss:YES];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    @catch (id exception) {
        // In case we catch exception here, hide the overlaying message.
        [self dismiss:YES];
        // Handle the exception message.
        LOG_LP_MESSAGE_EXCEPTION;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}
- (void)trackAction:(NSString *)actionName track:(BOOL)track
{
    if (actionName) {
        if (track) {
            [self.context runTrackedActionNamed:actionName];
        } else {
            [self.context runActionNamed:actionName];
        }
    }
}

- (NSDictionary *)queryComponentsFromUrl:(NSString *)url
{
    NSMutableDictionary *components = [NSMutableDictionary new];
    NSArray *urlComponents = [url componentsSeparatedByString:@"?"];
    if ([urlComponents count] > 1) {
        NSString *queryString = urlComponents[1];
        NSArray *parameters = [queryString componentsSeparatedByString:@"&"];
        for (NSString *parameter in parameters) {
            NSArray *parameterComponents = [parameter componentsSeparatedByString:@"="];
            if ([parameterComponents count] > 1) {
                components[parameterComponents[0]] = [parameterComponents[1] stringByRemovingPercentEncoding];
            }
        }
    }
    return components;
}

- (IBAction)didTapDismissButton:(id)sender
{
    [self.context runActionNamed:LPMT_ARG_DISMISS_ACTION];
    [self dismiss:YES];
}

- (void)didTapOutside
{
    [self.context runActionNamed:LPMT_ARG_DISMISS_ACTION];
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

#pragma mark Orientation
- (void)orientationDidChange:(NSNotification *)notification
{
    UIDevice *device = notification.object;
    // Bug with iOS, calls orientation did change even without change,
    // Check if the orientation is not changed than before.
    if (_orientation != device.orientation) {
        _orientation = device.orientation;
        [self updateLayout];
    }
}

- (void)updateLayout
{
    if ([self.context.actionName isEqualToString:LPMT_HTML_NAME]) {
        if (self.isBanner) {
            [self updateBannerConstraints];
        } else {
            [self updateTemplateConstraints];
        }
    }
}

@end
