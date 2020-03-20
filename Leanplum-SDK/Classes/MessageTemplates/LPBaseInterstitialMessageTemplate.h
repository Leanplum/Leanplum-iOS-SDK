//
//  LPBaseInterstitialMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseMessageTemplate.h"
#import "LPHitView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPBaseInterstitialMessageTemplate : LPBaseMessageTemplate

@property  (nonatomic, strong) UIView *popupView;
@property  (nonatomic, strong) UIView *popupGroup;
@property  (nonatomic, strong) UIButton *dismissButton;
@property  (nonatomic, strong) UIImageView *popupBackground;
@property  (nonatomic, strong) UIButton *acceptButton;
@property  (nonatomic, strong) UIButton *cancelButton;
@property  (nonatomic, strong) UILabel *titleLabel;
@property  (nonatomic, strong) UILabel *messageLabel;
@property  (nonatomic, strong) UIButton *overlayView;
@property  (nonatomic, strong) LPHitView *closePopupView;
@property  (nonatomic, assign) UIDeviceOrientation orientation;

- (void)accept;
- (void)showPopup;
- (void)closePopupWithAnimation:(BOOL)animated;
- (void)closePopupWithAnimation:(BOOL)animated
                    actionNamed:(NSString *)actionName
                          track:(BOOL)track;

- (void)removeAllViewsFrom:(UIView *)view;
- (UIImage *)dismissImage:(UIColor *)color withSize:(int)size;
-(UIEdgeInsets)safeAreaInsets;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
