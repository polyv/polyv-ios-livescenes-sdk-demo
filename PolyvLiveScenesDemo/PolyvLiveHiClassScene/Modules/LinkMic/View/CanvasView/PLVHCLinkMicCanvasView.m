//
//  PLVHCLinkMicCanvasView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCLinkMicCanvasView.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCLinkMicCanvasView ()
/// view hierarchy
///
/// (PLVHCLinkMicCanvasView) self
///  ├── (CAGradientLayer) gradientLayer
///  └── (UIView) external rtc View
@property (nonatomic, strong) CAGradientLayer *gradientLayer;//背景

@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)

@end

@implementation PLVHCLinkMicCanvasView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = PLV_UIColorFromRGB(@"2B3145");
        /// 添加视图
        [self.layer addSublayer:self.gradientLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

#pragma mark - [ Public Methods ]

- (void)addRTCView:(UIView *)rtcView {
    plv_dispatch_main_async_safe(^{
        if (rtcView) {
            rtcView.frame = self.bounds;
            rtcView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:rtcView];
            self.rtcView = rtcView;
        }
    })
}

- (void)removeRTCView {
    for (UIView * subview in self.subviews) {
        [subview removeFromSuperview];
    }
    [self.gradientLayer removeFromSuperlayer];
}

- (void)rtcViewShow:(BOOL)rtcViewShow {
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow;
    }
}

#pragma mark - [ Private Methods ]


#pragma mark Getter & Setter

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#383F64"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#2D324C"].CGColor];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

@end
