//
//  PLVSALinkMicCanvasView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicCanvasView.h"

#import "PLVSAUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSALinkMicCanvasView ()

/// view hierarchy
///
/// (PLVSALinkMicCanvasView) self
///  ├── (UIImageView) placeholderImageView 
///  └── (UIView) external rtc View
@property (nonatomic, strong) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)
@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PLVSALinkMicCanvasView

#pragma mark - [ Life Period ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 不响应交互
        self.userInteractionEnabled = NO;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.gradientLayer.frame = self.bounds;
    self.placeholderImageView.frame = CGRectMake((CGRectGetWidth(self.bounds) - 30) / 2.0, (CGRectGetHeight(self.bounds) - 30) / 2.0, 30, 30);
}

#pragma mark - [ Public Methods ]

- (void)addRTCView:(UIView *)rtcView {
    plv_dispatch_main_async_safe(^{
        if (rtcView) {
            rtcView.frame = self.bounds;
            rtcView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:rtcView];
            self.rtcView = rtcView;
        }else{
//            NSLog(@"PLVSALinkMicCanvasView - add rtc view failed, rtcView illegal:%@",rtcView);
        }
    })
}

- (void)removeRTCView {
    for (UIView * subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [self addSubview:self.placeholderImageView];
}

- (void)rtcViewShow:(BOOL)rtcViewShow {
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow;
    } else {
//        NSLog(@"PLVSALinkMicCanvasView - rtcViewShow failed, rtcView is nil");
    }
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.clipsToBounds = YES;
    /// 添加渐变背景
    [self.layer addSublayer:self.gradientLayer];
    /// 添加视图
    [self addSubview:self.placeholderImageView];
}

#pragma mark Getter & Setter

- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        _placeholderImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_placeholder"];
    }
    return _placeholderImageView;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.locations = @[@(0), @(1.0)];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
        UIColor *startColor = [PLVColorUtil colorFromHexString:@"#383F64"];
        UIColor *endColor = [PLVColorUtil colorFromHexString:@"#2D324C"];
        _gradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
    }
    return _gradientLayer;
}

@end
