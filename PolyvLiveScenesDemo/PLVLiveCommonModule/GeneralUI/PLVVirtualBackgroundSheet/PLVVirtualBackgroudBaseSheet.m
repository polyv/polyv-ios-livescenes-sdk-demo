//
//  PLVVirtualBackgroudBaseSheet.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVVirtualBackgroudBaseSheet.h"
// 工具
#import "PLVSAUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kBottomSheetAnimationDuration = 0.25;

@interface PLVVirtualBackgroudBaseSheet ()

@property (nonatomic, strong) UIView *gestureView; // 手势区域
@property (nonatomic, strong) UIView *contentView; // 底部内容区域
@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图

#pragma mark 数据
@property (nonatomic, assign) BOOL superLandscape; // 是否支持横屏
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation; // 当前方向
@property (nonatomic, assign) CGFloat sheetCornerRadius; // 圆角

@end

@implementation PLVVirtualBackgroudBaseSheet

#pragma mark - Life Cycle

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight {
    return [self initWithSheetHeight:sheetHeight sheetLandscapeWidth:0];
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    return [self initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth backgroundColor:nil];
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth backgroundColor:(UIColor *)backgroundColor {
    self = [super init];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.sheetHight = MAX(0, sheetHeight);
        self.sheetLandscapeWidth = sheetLandscapeWidth;
        self.superLandscape = sheetLandscapeWidth > 0;
        self.sheetCornerRadius = 16.0f;
        
        [self addSubview:self.gestureView];
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.effectView];
        
        if (backgroundColor) {
            self.gestureView.backgroundColor = backgroundColor;
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.sheetCornerRadius > 0) {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.contentView.bounds;
        UIRectCorner corners = UIRectCornerTopLeft | UIRectCornerTopRight;
        if (self.isLandscape &&
            self.superLandscape) {
            corners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
        }
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(self.sheetCornerRadius, self.sheetCornerRadius)].CGPath;
        self.contentView.layer.mask = maskLayer;
    }
}

- (BOOL)isLandscape{
    return ([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height);
}

#pragma mark - [ Public Method ]

- (void)deviceOrientationDidChange {
    [self resetWithAnimate];
}

- (void)setSheetCornerRadius:(CGFloat)cornerRadius {
    _sheetCornerRadius = cornerRadius;
}

#pragma mark - Getter

- (UIView *)gestureView {
    if (!_gestureView) {
        _gestureView = [[UIView alloc] init];
        _gestureView.backgroundColor = PLV_UIColorFromRGBA(@"#000000",0.5);
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [_gestureView addGestureRecognizer:tapGesture];
    }
    return _gestureView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = PLV_UIColorFromRGBA(@"#888888", 0.5);
    }
    return _contentView;
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}

#pragma mark - Show & Hide

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    
    [parentView addSubview:self];
    [parentView insertSubview:self atIndex:parentView.subviews.count - 1];
    
    if (self.superLandscape) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    [self resetWithAnimate];
}

- (void)dismiss {
    if (!self.superview) {
        return;
    }
    
    [UIView animateWithDuration:kBottomSheetAnimationDuration animations:^{
        if (self.isLandscape &&
            self.superLandscape) {
            self.contentView.frame = CGRectMake(self.bounds.size.width, 0, self.sheetLandscapeWidth, self.bounds.size.height);
        } else {
            self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
        }
        self.effectView.frame = self.contentView.bounds;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if (self.didCloseSheet) {
            self.didCloseSheet();
        }
    }];
}

- (void)reset {
    self.frame = self.superview.bounds;
    self.gestureView.frame = self.bounds;
    
    if (self.isLandscape &&
        self.superLandscape) {
        self.contentView.frame = CGRectMake(self.bounds.size.width, 0, self.sheetLandscapeWidth, self.bounds.size.height);
    } else {
        self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
       
    }
    self.effectView.frame = self.contentView.bounds;
}

- (UIEdgeInsets)areaInsets{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)resetWithAnimate {
    [self reset];
    [UIView animateWithDuration:kBottomSheetAnimationDuration animations:^{
        if (self.isLandscape &&
            self.superLandscape) {
            self.contentView.frame = CGRectMake(self.bounds.size.width - self.sheetLandscapeWidth - self.areaInsets.right, 0, self.sheetLandscapeWidth + self.areaInsets.right, self.bounds.size.height);
        } else {
            self.contentView.frame = CGRectMake(0, self.bounds.size.height - self.sheetHight, self.bounds.size.width, self.sheetHight);
        }
        self.effectView.frame = self.contentView.bounds;
    } completion:nil];
}

#pragma mark - [ Delegate ]
#pragma mark UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChangeNotification:(NSNotification *)notify {
    UIInterfaceOrientation orientaion = [UIApplication sharedApplication].statusBarOrientation;

    if (orientaion == UIInterfaceOrientationPortrait ||
        orientaion == UIInterfaceOrientationLandscapeLeft ||
        orientaion == UIInterfaceOrientationLandscapeRight) {
        [self deviceOrientationDidChange];
    }
}

@end
