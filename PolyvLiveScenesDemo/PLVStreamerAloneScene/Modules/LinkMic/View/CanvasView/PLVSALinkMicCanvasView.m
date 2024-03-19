//
//  PLVSALinkMicCanvasView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicCanvasView.h"

#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSALinkMicCanvasView ()

/// view hierarchy
///
/// (PLVSALinkMicCanvasView) self
///  ├── (UIImageView) splashImageBackgroundView
///  ├── (UIVisualEffectView) effectView
///  ├── (UIImageView) splashImageView
///  ├── (UIImageView) placeholderImageView 
///  └── (UIView) external rtc View
@property (nonatomic, strong) UIImageView * splashImageBackgroundView; // 封面图背景视图 (负责展示 封面图背景)
@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图
@property (nonatomic, strong) UIImageView * splashImageView; // 封面图视图 (负责展示 封面图)
@property (nonatomic, strong) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)
@property (nonatomic, strong) UILabel *placeholderLabel; // 背景文字 (母房间用户才显示)
@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL privatePlaceholderImage;
@property (nonatomic, assign) BOOL needShowSplashImg;
@property (nonatomic, assign) BOOL imageShouldFill;

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
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    BOOL fullScreen = viewWidth > viewHeight;
    
    self.splashImageBackgroundView.frame = self.bounds;
    self.effectView.frame = self.bounds;
    self.splashImageView.frame = self.bounds;
    self.gradientLayer.frame = self.bounds;
    if (self.privatePlaceholderImage) {
        if (!self.imageShouldFill) {
            CGFloat sideLength;
            if (fullScreen) {
                sideLength = MIN(0.52 * viewHeight, 0.24 * viewWidth);
                self.placeholderImageView.frame = CGRectMake(108, (viewHeight - sideLength - 20) / 2.0, sideLength, sideLength);
            } else {
                sideLength = MIN(0.297 * viewHeight, 0.693 * viewWidth);
                self.placeholderImageView.frame = CGRectMake((viewWidth - sideLength) / 2.0, 118, sideLength, sideLength);
            }
        } else {
            self.placeholderImageView.frame = self.bounds;
        }
    } else {
        self.placeholderImageView.frame = CGRectMake((CGRectGetWidth(self.bounds) - 30) / 2.0, (CGRectGetHeight(self.bounds) - 30) / 2.0, 30, 30);
    }
    
    if (self.masterUser) {
        CGFloat placeholderImageViewSideLength = MIN(viewWidth, viewHeight) * 0.58;
        CGFloat placeholderLabelHeight = placeholderImageViewSideLength * 0.1;
        
        if (fullScreen) {
            self.placeholderImageView.frame = CGRectMake((viewWidth - placeholderImageViewSideLength) / 2.0, (viewHeight - placeholderImageViewSideLength) / 2.0, placeholderImageViewSideLength, placeholderImageViewSideLength);
        } else {
            self.placeholderImageView.frame = CGRectMake((viewWidth - placeholderImageViewSideLength) / 2.0, (viewHeight - placeholderImageViewSideLength * 1.5) / 2.0, placeholderImageViewSideLength, placeholderImageViewSideLength);
        }
        self.gradientLayer.hidden = self.needShowSplashImg && fullScreen;
        
        self.placeholderLabel.frame = CGRectMake(CGRectGetMinX(self.placeholderImageView.frame), CGRectGetMaxY(self.placeholderImageView.frame) - placeholderLabelHeight * 3, placeholderImageViewSideLength, placeholderLabelHeight);
    }
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
    
    [self addSubview:self.splashImageBackgroundView];
    [self addSubview:self.effectView];
    [self.layer addSublayer:self.gradientLayer];
    [self addSubview:self.splashImageView];
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.placeholderLabel];
}

- (void)rtcViewShow:(BOOL)rtcViewShow placeHolderImage:(UIImage * _Nullable)placeHolderImage imageShouldFill:(BOOL)fill {
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow || (rtcViewShow && placeHolderImage);
    } else {
//        NSLog(@"PLVSALinkMicCanvasView - rtcViewShow failed, rtcView is nil");
    }
    self.imageShouldFill = fill;
    if (placeHolderImage) {
        self.privatePlaceholderImage = YES;
        self.placeholderImageView.image = placeHolderImage;;
        self.placeholderImageView.hidden = NO;
        self.gradientLayer.hidden = rtcViewShow || fill;
        self.splashImageView.hidden = YES;
        self.effectView.hidden = fill;
        self.splashImageBackgroundView.image = placeHolderImage;
        self.splashImageBackgroundView.hidden = fill;
    } else if (!self.needShowSplashImg){
        self.privatePlaceholderImage = NO;
        self.placeholderImageView.image = self.masterUser ? [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_master_user_placeholder"] : [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_placeholder"];
        self.placeholderImageView.hidden = NO;
        self.gradientLayer.hidden = NO;
        self.splashImageView.hidden = YES;
        self.effectView.hidden = YES;
        self.splashImageBackgroundView.hidden = YES;
        self.placeholderLabel.hidden = self.masterUser;
    } else {
        self.placeholderImageView.hidden = YES;
        self.gradientLayer.hidden = CGRectGetWidth(self.bounds) > CGRectGetHeight(self.bounds);
        self.placeholderLabel.hidden = YES;
        self.splashImageView.hidden = rtcViewShow;
        self.effectView.hidden = rtcViewShow;
        self.splashImageBackgroundView.hidden = rtcViewShow;
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.clipsToBounds = YES;
    [self addSubview:self.splashImageBackgroundView];
    [self addSubview:self.effectView];
    /// 添加渐变背景
    [self.layer addSublayer:self.gradientLayer];
    /// 添加视图
    [self addSubview:self.splashImageView];
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.placeholderLabel];
}

#pragma mark Getter & Setter

- (UIImageView *)splashImageBackgroundView{
    if (!_splashImageBackgroundView) {
        _splashImageBackgroundView = [[UIImageView alloc]init];
        _splashImageBackgroundView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_placeholder"];
        _splashImageBackgroundView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _splashImageBackgroundView;
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}

- (UIImageView *)splashImageView{
    if (!_splashImageView) {
        _splashImageView = [[UIImageView alloc]init];
        _splashImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_placeholder"];
        _splashImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _splashImageView;
}

- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        _placeholderImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_placeholder"];
        _placeholderImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _placeholderImageView;
}

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc]init];
        _placeholderLabel.text = PLVLocalizedString(@"暂无直播");
        _placeholderLabel.textColor = UIColor.whiteColor;
        _placeholderLabel.textAlignment = NSTextAlignmentCenter;
        _placeholderLabel.font = [UIFont systemFontOfSize:14.0];
        _placeholderLabel.adjustsFontSizeToFitWidth = YES;
        _placeholderLabel.hidden = YES;
    }
    return _placeholderLabel;
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

- (void)setMasterUser:(BOOL)masterUser {
    _masterUser = masterUser;
    _placeholderImageView.image = masterUser ? [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_master_user_placeholder"] : [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_placeholder"];
    _placeholderLabel.hidden = !masterUser;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSupportMatrixPlayback:(BOOL)supportMatrixPlayback {
    _supportMatrixPlayback = supportMatrixPlayback;
    if (supportMatrixPlayback) {
        [self.placeholderLabel removeFromSuperview];
    }
}

- (void)setupSplashImg:(NSString *)splashImg {
    _needShowSplashImg = self.masterUser && [PLVFdUtil checkStringUseable:splashImg];
    _placeholderImageView.hidden = _needShowSplashImg;
    _placeholderLabel.hidden = _needShowSplashImg;
    _gradientLayer.hidden = _needShowSplashImg && (CGRectGetWidth(self.bounds) > CGRectGetHeight(self.bounds));
    _splashImageBackgroundView.hidden = !_needShowSplashImg;
    _effectView.hidden = !_needShowSplashImg;
    _splashImageView.hidden = !_needShowSplashImg;
    
    if (_needShowSplashImg) {
        [PLVSAUtils setImageView:_splashImageBackgroundView url:[NSURL URLWithString:splashImg] placeholderImage:nil options:SDWebImageRetryFailed];
        [PLVSAUtils setImageView:_splashImageView url:[NSURL URLWithString:splashImg] placeholderImage:nil options:SDWebImageRetryFailed];
    }
}

@end
