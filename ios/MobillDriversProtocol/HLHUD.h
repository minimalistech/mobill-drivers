//
//  HLHUD.h
//  HeraDemo
//
//  Created by Haley on 2019/5/17.
//  Copyright © 2019 weidian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Extension.h"

#ifndef kCFCoreFoundationVersionNuFINer_iOS_7_0
#define kCFCoreFoundationVersionNuFINer_iOS_7_0 847.20
#endif

#ifndef kCFCoreFoundationVersionNuFINer_iOS_8_0
#define kCFCoreFoundationVersionNuFINer_iOS_8_0 1129.15
#endif

typedef NS_ENUM(NSUInteger, HLHUDMode) {
    /// UIActivityIndicatorView.
    HLHUDModeIndeterminate,
    /// Shows a custom view.
    HLHUDModeImageView,
    /// Shows only label.
    HLHUDModeText,
};

@interface HLHUD : UIView

/**
 * operation mode. The default is HLHUDModeIndeterminate.
 */
@property (assign, nonatomic) HLHUDMode mode;

@property (strong, nonatomic) UIColor *contentColor;

@property (strong, nonatomic, readonly) UILabel *textLabel;

@property (nonatomic, strong, readonly) UILabel *detailLabel;

@property (strong, nonatomic, readonly) UIImageView *imageView;

+ (instancetype)showHUDAddedTo:(UIView *)view mask:(BOOL)mask;

+ (BOOL)hideHUDForView:(UIView *)view;

+ (HLHUD *)HUDForView:(UIView *)view;

- (instancetype)initWithView:(UIView *)view mask:(BOOL)mask;

- (void)show;

- (void)hide;

- (void)hideAfterDelay:(NSTimeInterval)delay;

@end

/**
 * A progress view for showing definite progress by filling up a circle (pie chart).
 */
@interface FATRoundProgressView : UIView

/**
 * Progress (0.0 to 1.0)
 */
@property (nonatomic, assign) float progress;

/**
 * Indicator progress color.
 * Defaults to white [UIColor whiteColor].
 */
@property (nonatomic, strong) UIColor *progressTintColor;

/**
 * Indicator background (non-progress) color.
 * Only applicable on iOS versions older than iOS 7.
 * Defaults to translucent white (alpha 0.1).
 */
@property (nonatomic, strong) UIColor *backgroundTintColor;

/*
 * Display mode - NO = round or YES = annular. Defaults to round.
 */
@property (nonatomic, assign, getter=isAnnular) BOOL annular;

@end
