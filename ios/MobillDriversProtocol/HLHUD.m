//
//  HLHUD.m
//  HeraDemo
//
//  Created by Haley on 2019/5/17.
//  Copyright © 2019 weidian. All rights reserved.
//

#import "HLHUD.h"

static const CGFloat FATHUDLabelFontSize = 14.f;

@interface HLHUD ()

@property (nonatomic, assign) BOOL mask;

@property (strong, nonatomic) UIView *backgroundView;

@property (nonatomic, strong) UIView *bezelView;

@property (nonatomic, strong) UIView *indicator;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UILabel *detailLabel;

@property (nonatomic, weak) NSTimer *hideDelayTimer;

@end

@implementation HLHUD

#pragma mark - Class methods
+ (instancetype)showHUDAddedTo:(UIView *)view mask:(BOOL)mask {
    HLHUD *hud = [[self alloc] initWithView:view mask:mask];
    [view addSubview:hud];
    [hud show];
    return hud;
}

+ (BOOL)hideHUDForView:(UIView *)view {
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    BOOL isExit = NO;
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            isExit = YES;
            HLHUD *hud = (HLHUD *)subview;
            [hud hide];
        }
    }

    if (isExit) {
        return YES;
    }

    return NO;
}

+ (nullable HLHUD *)HUDForView:(UIView *)view {
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            HLHUD *hud = (HLHUD *)subview;
            return hud;
        }
    }
    return nil;
}

#pragma mark - LifeCycle methods
- (instancetype)initWithView:(UIView *)view mask:(BOOL)mask {
    CGRect frame = view.bounds;
    //    if (CGRectEqualToRect(frame, [UIScreen mainScreen].bounds)) {
    //        CGFloat statusHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    //        frame.origin.y = statusHeight + 44;
    //        frame.size.height -= (statusHeight + 44);
    //    }
    return [self initWithFrame:frame mask:mask];
}

- (instancetype)initWithFrame:(CGRect)frame mask:(BOOL)mask {
    if ((self = [super initWithFrame:frame])) {
        self.mask = mask;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _mode = HLHUDModeIndeterminate;
    _contentColor = [UIColor colorWithWhite:0.f alpha:0.7f];

    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.layer.allowsGroupOpacity = NO;
    self.userInteractionEnabled = self.mask;
    self.alpha = 0.0f;

    [self setupViews];
    [self updateIndicators];
}

- (void)setupViews {
    UIColor *defaultColor = self.contentColor;

    CGRect frame = self.bounds;
    UIView *backgroundView = [[UIView alloc] initWithFrame:frame];
    backgroundView.backgroundColor = [UIColor clearColor];
    backgroundView.opaque = NO;
    [self addSubview:backgroundView];
    self.backgroundView = backgroundView;

    UIView *bezelView = [UIView new];
    bezelView.layer.cornerRadius = 5.0f;
    bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8f];
    bezelView.backgroundColor = [UIColor colorWithRed:122/255.0 green:106/255.0 blue:238/255.0 alpha:0.9f];
    bezelView.alpha = 0.f;
    [self addSubview:bezelView];
    self.bezelView = bezelView;

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self.bezelView addSubview:imageView];
    self.imageView = imageView;

    UILabel *label = [UILabel new];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = defaultColor;
    label.font = [UIFont boldSystemFontOfSize:FATHUDLabelFontSize];
    label.opaque = NO;
    label.numberOfLines = 2;
    label.backgroundColor = [UIColor clearColor];
    [self.bezelView addSubview:label];
    self.textLabel = label;

    UILabel *detailsLabel = [UILabel new];
    detailsLabel.textAlignment = NSTextAlignmentCenter;
    detailsLabel.textColor = defaultColor;
    detailsLabel.numberOfLines = 2;
    detailsLabel.font = [UIFont boldSystemFontOfSize:FATHUDLabelFontSize];
    detailsLabel.opaque = NO;
    detailsLabel.backgroundColor = [UIColor clearColor];
    [self.bezelView addSubview:detailsLabel];
    self.detailLabel = detailsLabel;
}

- (void)updateIndicators {
    UIView *indicator = self.indicator;
    BOOL isActivityIndicator = [indicator isKindOfClass:[UIActivityIndicatorView class]];

    HLHUDMode mode = self.mode;
    if (mode == HLHUDModeIndeterminate) {
        if (!isActivityIndicator) {
            // Update to indeterminate indicator
            [indicator removeFromSuperview];
            indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [(UIActivityIndicatorView *)indicator startAnimating];
            [self.bezelView addSubview:indicator];
        }
    } else if (mode == HLHUDModeImageView && self.imageView != indicator) {
        // Update custom view indicator
        [indicator removeFromSuperview];
        indicator = self.imageView;
        [self.bezelView addSubview:indicator];
    } else if (mode == HLHUDModeText) {
        [indicator removeFromSuperview];
        indicator = nil;
    }
    self.indicator = indicator;

    [self updateViewsForColor:self.contentColor];

    [self setNeedsLayout];
}

- (void)updateViewsForColor:(UIColor *)color {
    if (!color) return;

    self.textLabel.textColor = color;
    self.detailLabel.textColor = color;

    UIView *indicator = self.indicator;
    if ([indicator isKindOfClass:[UIActivityIndicatorView class]]) {
        UIActivityIndicatorView *appearance = nil;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 90000
        appearance = [UIActivityIndicatorView appearanceWhenContainedIn:[HLHUD class], nil];
#else
        // For iOS 9+
        appearance = [UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[ [HLHUD class] ]];
#endif

        if (appearance.color == nil) {
            ((UIActivityIndicatorView *)indicator).color = color;
        }
    }
}

#pragma mark - show & hide
- (void)show {
    self.alpha = 1.0f;
    self.bezelView.alpha = 1.0f;
}

- (void)hide {
    self.alpha = 0.0f;
    self.bezelView.alpha = 0.0f;
    [self removeFromSuperview];
}

- (void)hideAfterDelay:(NSTimeInterval)delay {
    [self.hideDelayTimer invalidate];

    NSTimer *timer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(handleHideTimer:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.hideDelayTimer = timer;
}

#pragma mark - Timer callbacks
- (void)handleHideTimer:(NSTimer *)timer {
    [self hide];
}

#pragma mark - Properties
- (void)setMode:(HLHUDMode)mode {
    if (mode != _mode) {
        _mode = mode;
        [self updateIndicators];
    }
}

- (void)setContentColor:(UIColor *)contentColor {
    if (contentColor != _contentColor && ![contentColor isEqual:_contentColor]) {
        _contentColor = contentColor;
        [self updateViewsForColor:contentColor];
    }
}

#pragma mark - Layout
- (void)layoutSubviews {
    // There is no need to update constraints if they are going to
    // be recreated in [super layoutSubviews] due to needsUpdateConstraints being set.
    // This also avoids an issue on iOS 8, where updatePaddingConstraints
    // would trigger a zombie object access.
    [super layoutSubviews];

    HLHUDMode mode = self.mode;
    NSString *text = self.textLabel.text;
    NSString *detailText = self.detailLabel.text;
    CGFloat bezelViewW = 180.0f;
    CGFloat bezelViewH = 120.0f;
    CGFloat topPadding = 22.0f;
    CGFloat padding = 10.0f;
    CGFloat imageW = 45.0f;
    CGFloat textH = 20;
    if (mode == HLHUDModeIndeterminate) {
        self.detailLabel.hidden = YES;
        self.textLabel.hidden = NO;
        // 设置activityView的位置
        self.indicator.center = CGPointMake(bezelViewW * 0.5, topPadding + imageW * 0.5);
        // 设置label的位置
        if (text.length > 0) {
            CGSize textSize = [text boundingRectWithSize:CGSizeMake(bezelViewW - 2 * padding, textH * 2)
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:FATHUDLabelFontSize]}
                                                 context:nil]
                                  .size;
            self.textLabel.frame = CGRectMake(8, topPadding + imageW + padding, bezelViewW - 2 * padding, textSize.height);
            if (detailText.length > 0) {
                self.detailLabel.hidden = NO;
                self.detailLabel.frame = CGRectMake(8, self.textLabel.bottom + 5, self.textLabel.width, 20);
                bezelViewH += 25;
            }
        } else {
            self.textLabel.hidden = YES;
            bezelViewH = topPadding * 2 + imageW;
            
            if (detailText.length > 0) {
                self.detailLabel.hidden = NO;
                self.detailLabel.frame = CGRectMake(8, topPadding + imageW + padding, bezelViewW - 2 * padding, 20);
                bezelViewH += 25;
            }
        }
        // 设置bezelView的位置
        self.bezelView.bounds = CGRectMake(0, 0, bezelViewW, bezelViewH);
    } else if (mode == HLHUDModeImageView) {
        self.detailLabel.hidden = YES;
        self.textLabel.hidden = NO;
        // 设置imageView的位置
        CGFloat imgW = self.imageView.image.size.width;
        CGFloat imgH = self.imageView.image.size.height;
        if (imgH < imageW && imgW < imageW) {
            self.indicator.bounds = CGRectMake(0, 0, imgW, imgH);
        } else {
            self.indicator.bounds = CGRectMake(0, 0, imageW, imageW);
        }
        self.indicator.center = CGPointMake(bezelViewW * 0.5, topPadding + imageW * 0.5);
        // 设置label的位置
        if (text.length > 0) {
            CGSize textSize = [text boundingRectWithSize:CGSizeMake(bezelViewW - 2 * padding, textH * 2)
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:FATHUDLabelFontSize]}
                                                 context:nil]
                                  .size;
            self.textLabel.frame = CGRectMake(8, topPadding + imageW + padding, bezelViewW - 2 * padding, textSize.height);
        } else {
            self.textLabel.hidden = YES;
            bezelViewH = topPadding * 2 + imageW;
        }
        // 设置bezelView的位置
        self.bezelView.bounds = CGRectMake(0, 0, bezelViewW, bezelViewH);
    } else if (mode == HLHUDModeText) {
        self.textLabel.hidden = YES;
        self.indicator.hidden = YES;
        self.detailLabel.hidden = NO;

        CGFloat width = self.bounds.size.width;
        CGFloat maxBezelW = MAX(width - 80 * 2, 120);

        NSString *detailText = self.detailLabel.text;
        CGRect rect = [detailText boundingRectWithSize:CGSizeMake(maxBezelW - 2 * padding, textH * 2)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:FATHUDLabelFontSize]}
                                               context:nil];
        CGFloat detailW = MIN(rect.size.width, maxBezelW - 2 * padding);
        CGFloat detailH = MIN(rect.size.height, textH * 2);
        if (detailW == 0) {
            detailH = 0;
        }

        self.detailLabel.frame = CGRectMake(padding, topPadding, detailW, detailH);

        self.bezelView.bounds = CGRectMake(0, 0, padding * 2 + detailW, topPadding * 2 + detailH);
    }

    CGPoint bezelCenter = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    self.bezelView.center = bezelCenter;
}

@end

@implementation FATRoundProgressView

#pragma mark - Lifecycle

- (id)init {
    return [self initWithFrame:CGRectMake(0.f, 0.f, 37.f, 37.f)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        _progress = 0.f;
        _annular = NO;
        _progressTintColor = [[UIColor alloc] initWithWhite:1.f alpha:1.f];
        _backgroundTintColor = [[UIColor alloc] initWithWhite:1.f alpha:.1f];
    }
    return self;
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize {
    return CGSizeMake(37.f, 37.f);
}

#pragma mark - Properties

- (void)setProgress:(float)progress {
    if (progress != _progress) {
        _progress = progress;
        [self setNeedsDisplay];
    }
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
    NSAssert(progressTintColor, @"The color should not be nil.");
    if (progressTintColor != _progressTintColor && ![progressTintColor isEqual:_progressTintColor]) {
        _progressTintColor = progressTintColor;
        [self setNeedsDisplay];
    }
}

- (void)setBackgroundTintColor:(UIColor *)backgroundTintColor {
    NSAssert(backgroundTintColor, @"The color should not be nil.");
    if (backgroundTintColor != _backgroundTintColor && ![backgroundTintColor isEqual:_backgroundTintColor]) {
        _backgroundTintColor = backgroundTintColor;
        [self setNeedsDisplay];
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    BOOL isPreiOS7 = kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNuFINer_iOS_7_0;

    if (_annular) {
        // Draw background
        CGFloat lineWidth = isPreiOS7 ? 5.f : 2.f;
        UIBezierPath *processBackgroundPath = [UIBezierPath bezierPath];
        processBackgroundPath.lineWidth = lineWidth;
        processBackgroundPath.lineCapStyle = kCGLineCapButt;
        CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        CGFloat radius = (self.bounds.size.width - lineWidth) / 2;
        CGFloat startAngle = -((float)M_PI / 2); // 90 degrees
        CGFloat endAngle = (2 * (float)M_PI) + startAngle;
        [processBackgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [_backgroundTintColor set];
        [processBackgroundPath stroke];
        // Draw progress
        UIBezierPath *processPath = [UIBezierPath bezierPath];
        processPath.lineCapStyle = isPreiOS7 ? kCGLineCapRound : kCGLineCapSquare;
        processPath.lineWidth = lineWidth;
        endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        [processPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [_progressTintColor set];
        [processPath stroke];
    } else {
        // Draw background
        CGFloat lineWidth = 2.f;
        CGRect allRect = self.bounds;
        CGRect circleRect = CGRectInset(allRect, lineWidth / 2.f, lineWidth / 2.f);
        CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [_progressTintColor setStroke];
        [_backgroundTintColor setFill];
        CGContextSetLineWidth(context, lineWidth);
        if (isPreiOS7) {
            CGContextFillEllipseInRect(context, circleRect);
        }
        CGContextStrokeEllipseInRect(context, circleRect);
        // 90 degrees
        CGFloat startAngle = -((float)M_PI / 2.f);
        // Draw progress
        if (isPreiOS7) {
            CGFloat radius = (CGRectGetWidth(self.bounds) / 2.f) - lineWidth;
            CGFloat endAngle = (self.progress * 2.f * (float)M_PI) + startAngle;
            [_progressTintColor setFill];
            CGContextMoveToPoint(context, center.x, center.y);
            CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
            CGContextClosePath(context);
            CGContextFillPath(context);
        } else {
            UIBezierPath *processPath = [UIBezierPath bezierPath];
            processPath.lineCapStyle = kCGLineCapButt;
            processPath.lineWidth = lineWidth * 2.f;
            CGFloat radius = (CGRectGetWidth(self.bounds) / 2.f) - (processPath.lineWidth / 2.f);
            CGFloat endAngle = (self.progress * 2.f * (float)M_PI) + startAngle;
            [processPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
            // Ensure that we don't get color overlapping when _progressTintColor alpha < 1.f.
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            [_progressTintColor set];
            [processPath stroke];
        }
    }
}

@end
