//
//  PLVECLinkMicCanvasView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/22.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECLinkMicCanvasView.h"
#import "PLVECUtils.h"
#import "PLVRoomDataManager.h"
#import "PLVPlayerLogoView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString * const kPLVECTeacherSplashImgURLString = @"https://s1.videocc.net/default-img/channel/default-splash.png";//讲师默认封面图地址

@interface PLVECLinkMicCanvasView ()

/// view hierarchy
///
/// (PLVECLinkMicCanvasView) self
///  ├── (UIImageView) placeholderImageView
///  ├── (UIView) external rtc View
///  ├── (PLVPlayerLogoView) logoView
///  └── (UIImageView) networkQualityImageView
///  ├── (UIImageView) splashImageView
///  ├── (UIImageView) pauseWatchNoDelayImageView
///  └── (UIView) external rtc View
@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)
@property (nonatomic, strong) PLVPlayerLogoView * logoView; // 播放器LOGO视图
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)
@property (nonatomic, strong) UIImageView * splashImageView; // 音频背景视图（只支持音频模式时显示）
@property (nonatomic, strong) UIImageView * networkQualityImageView; // 信号塔视图 (负责展示 信号状态图标)
@property (nonatomic, strong) UIImageView * pauseWatchNoDelayImageView; // 无延迟直播暂停后显示的占位图

@end

@implementation PLVECLinkMicCanvasView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    self.gradientLayer.frame = self.bounds;
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    self.splashImageView.frame = self.bounds;
    self.pauseWatchNoDelayImageView.frame = self.bounds;
    
    CGFloat placeholderImageViewHeight = 40;
    self.placeholderImageView.frame = CGRectMake((viewWidth - placeholderImageViewHeight) / 2.0,
                                                 (viewHeight - placeholderImageViewHeight) / 2.0,
                                                 placeholderImageViewHeight,
                                                 placeholderImageViewHeight);
    
    CGFloat networkQualityImageViewHeight = viewHeight * 0.171;
    if (networkQualityImageViewHeight >= 24) { networkQualityImageViewHeight = 24; }
    self.networkQualityImageView.frame = CGRectMake((viewWidth - 3.5 - networkQualityImageViewHeight),
                                                    3.0,
                                                    networkQualityImageViewHeight,
                                                    networkQualityImageViewHeight);
}


#pragma mark - [ Public Methods ]

- (void)addRTCView:(UIView *)rtcView {
    plv_dispatch_main_async_safe(^{
        if (rtcView) {
            rtcView.frame = self.bounds;
            rtcView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:rtcView];
            [self bringSubviewToFront:self.networkQualityImageView];
            self.rtcView = rtcView;
        } else {
            NSLog(@"PLVECLinkMicWindowCanvasView - add rtc view failed, rtcView illegal:%@",rtcView);
        }
    })
}

- (void)removeRTCView {
    for (UIView * subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.logoView];
    self.logoView.hidden = YES;
    
    [self addSubview:self.networkQualityImageView];
    self.networkQualityImageView.hidden = YES;
    
    [self addSubview:self.splashImageView];
    [self addSubview:self.pauseWatchNoDelayImageView];
}

- (void)rtcViewShow:(BOOL)rtcViewShow {
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow;
    } else {
        NSLog(@"PLVECLinkMicCanvasView - rtcViewShow failed, rtcView is nil");
    }
}

- (void)logoViewShow:(BOOL)logoViewShow {
    plv_dispatch_main_async_safe(^{
        self.logoView.hidden = !logoViewShow;
        if (logoViewShow) {
            if (self.networkQualityImageView.hidden) {
                [self bringSubviewToFront:self.logoView];
            } else {
                [self insertSubview:self.logoView belowSubview:self.networkQualityImageView];
            }
        }
    })
}

- (void)updateNetworkQualityImageViewWithStatus:(PLVBLinkMicNetworkQuality)status {
    if (status != PLVBLinkMicNetworkQualityUnknown) {
        self.networkQualityImageView.hidden = NO;
        if (status <= PLVBLinkMicNetworkQualityGood) {
            self.networkQualityImageView.image = [self getImageWithName:@"plvec_linkmic_networkquality_good"];
        } else if (status <= PLVBLinkMicNetworkQualityFine) {
            self.networkQualityImageView.image = [self getImageWithName:@"plvec_linkmic_networkquality_fine"];
        } else {
            self.networkQualityImageView.image = [self getImageWithName:@"plvec_linkmic_networkquality_bad"];
        }
    }
}

- (void)setSplashImageWithURLString:(NSString *)urlString {
    if (![PLVFdUtil checkStringUseable:urlString]) {
        urlString = kPLVECTeacherSplashImgURLString;
    }
    self.splashImageView.hidden = NO;
    [PLVECUtils setImageView:self.splashImageView url:[NSURL URLWithString:urlString]];
}

- (void)pauseWatchNoDelayImageViewShow:(BOOL)show {
    self.pauseWatchNoDelayImageView.hidden = !show;
}

- (UIImageView *)logoImageView {
    return self.logoView.logoImageView;
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.clipsToBounds = YES;
    
    /// 添加视图
    /// 添加渐变背景
    [self.layer addSublayer:self.gradientLayer];
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.logoView];
    self.logoView.hidden = YES;
    [self addSubview:self.networkQualityImageView];
    self.networkQualityImageView.hidden = YES;
    [self addSubview:self.splashImageView];
    [self addSubview:self.pauseWatchNoDelayImageView];
}

- (UIImage *)getImageWithName:(NSString *)imageName {
    return [PLVECUtils imageForWatchResource:imageName];
}

#pragma mark Getter

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

- (PLVPlayerLogoView *)logoView {
    if (!_logoView) {
        _logoView = [[PLVPlayerLogoView alloc] init];
        PLVChannelInfoModel *channelInfo = [PLVRoomDataManager sharedManager].roomData.channelInfo;
        if ([PLVFdUtil checkStringUseable:channelInfo.logoImageUrl]) {
            PLVPlayerLogoParam *logoParam = [[PLVPlayerLogoParam alloc] init];
            logoParam.logoUrl = channelInfo.logoImageUrl;
            logoParam.position = channelInfo.logoPosition;
            logoParam.logoAlpha = channelInfo.logoOpacity;
            logoParam.logoWidthScale = 0.14;
            logoParam.logoHeightScale = 0.25;
            logoParam.logoHref = channelInfo.logoHref;
            [_logoView insertLogoWithParam:logoParam];
            [self addSubview:_logoView];
        }
    }
    return _logoView;
}

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        NSString *imageName = isPad ? @"plvec_linkmic_window_placeholder_ipad" : @"plvec_linkmic_window_placeholder";
        _placeholderImageView.image = [self getImageWithName:imageName];
    }
    return _placeholderImageView;
}

- (UIImageView *)splashImageView {
    if (!_splashImageView) {
        _splashImageView = [[UIImageView alloc] init];
        _splashImageView.contentMode = UIViewContentModeScaleAspectFit;
        _splashImageView.hidden = YES;
    }
    return _splashImageView;
}

- (UIImageView *)networkQualityImageView {
    if (!_networkQualityImageView) {
        _networkQualityImageView = [[UIImageView alloc]init];
        _networkQualityImageView.image = [self getImageWithName:@"plvec_linkmic_networkquality_good"];
        _networkQualityImageView.layer.shadowColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.3].CGColor;
        _networkQualityImageView.layer.shadowOffset = CGSizeMake(0, 0.5);
        _networkQualityImageView.layer.shadowOpacity = 1;
        _networkQualityImageView.layer.shadowRadius = 8;
    }
    return _networkQualityImageView;
}

- (UIImageView *)pauseWatchNoDelayImageView {
    if (!_pauseWatchNoDelayImageView) {
        _pauseWatchNoDelayImageView = [[UIImageView alloc] init];
        _pauseWatchNoDelayImageView.hidden = YES;
        _pauseWatchNoDelayImageView.contentMode = UIViewContentModeScaleAspectFit;
        _pauseWatchNoDelayImageView.image = [self getImageWithName:@"plvec_linkmic_window_pauseWatchNoDelay_placeholder"];
    }
    return _pauseWatchNoDelayImageView;
}

@end
