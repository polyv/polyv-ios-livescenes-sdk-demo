//
//  PLVLCLinkMicCanvasView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/22.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLinkMicCanvasView.h"

#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVRoomDataManager.h"
#import "PLVPlayerLogoView.h"
#import "PLVLivePictureInPicturePlaceholderView.h"

static NSString * const kPLVLCTeacherSplashImgURLString = @"https://s1.videocc.net/default-img/channel/default-splash.png";//讲师默认封面图地址

@interface PLVLCLinkMicCanvasView ()

/// view hierarchy
///
/// (PLVLCLinkMicCanvasView) self
///  ├── (UIImageView) placeholderImageView
///  ├── (UIView) external rtc View
///  ├── (PLVPlayerLogoView) logoView
///  └── (UIImageView) networkQualityImageView
///  ├── (UIImageView) splashImageView
///  ├── (UIImageView) pauseWatchNoDelayImageView
///  ├── (PLVLivePictureInPicturePlaceholderView) pictureInPicturePlaceholderView
///  └── (UIView) external rtc View
@property (nonatomic, strong) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)
@property (nonatomic, strong) UIImageView * splashImageView; // 音频背景视图（只支持音频模式时显示）
@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)
@property (nonatomic, strong) PLVPlayerLogoView * logoView; // 播放器LOGO视图
@property (nonatomic, strong) UIImageView * networkQualityImageView; // 信号塔视图 (负责展示 信号状态图标)
@property (nonatomic, strong) UIImageView * pauseWatchNoDelayImageView; // 无延迟直播暂停后显示的占位图
@property (nonatomic, strong) PLVLivePictureInPicturePlaceholderView *pictureInPicturePlaceholderView;    // 画中画占位图

@end

@implementation PLVLCLinkMicCanvasView

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}


- (void)layoutSubviews{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    self.splashImageView.frame = self.bounds;
    self.pauseWatchNoDelayImageView.frame = self.bounds;
    self.pictureInPicturePlaceholderView.frame = self.bounds;
    
    CGFloat placeholderImageViewHeight = MIN(viewHeight , viewWidth)  * 0.485;
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
- (void)addRTCView:(UIView *)rtcView{
    plv_dispatch_main_async_safe(^{
        if (rtcView) {
            rtcView.frame = self.bounds;
            rtcView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:rtcView];
            [self bringSubviewToFront:self.pictureInPicturePlaceholderView];
            [self bringSubviewToFront:self.networkQualityImageView];
            self.rtcView = rtcView;
        }else{
            NSLog(@"PLVLCLinkMicWindowCanvasView - add rtc view failed, rtcView illegal:%@",rtcView);
        }
    })
}

- (void)removeRTCView{
    for (UIView * subview in self.subviews) { [subview removeFromSuperview]; }
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.logoView];
    self.logoView.hidden = YES;
    [self addSubview:self.networkQualityImageView];
    self.networkQualityImageView.hidden = YES;
    [self addSubview:self.splashImageView];
    [self addSubview:self.pauseWatchNoDelayImageView];
    [self addSubview:self.pictureInPicturePlaceholderView];
}

- (void)rtcViewShow:(BOOL)rtcViewShow{
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow;
    }else{
        NSLog(@"PLVLCLinkMicCanvasView - rtcViewShow failed, rtcView is nil");
    }
}

- (void)logoViewShow:(BOOL)logoViewShow{
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

- (void)pauseWatchNoDelayImageViewShow:(BOOL)show {
    self.pauseWatchNoDelayImageView.hidden = !show;
}

- (void)pictureInPicturePlaceholderShow:(BOOL)show {
    self.pictureInPicturePlaceholderView.hidden = !show;
}

- (void)updateNetworkQualityImageViewWithStatus:(PLVBLinkMicNetworkQuality)status{
    if (status != PLVBLinkMicNetworkQualityUnknown) {
        self.networkQualityImageView.hidden = NO;
        if (status <= PLVBLinkMicNetworkQualityGood) {
            self.networkQualityImageView.image = [self getImageWithName:@"plvlc_linkmic_networkquality_good"];
        }else if(status <= PLVBLinkMicNetworkQualityFine){
            self.networkQualityImageView.image = [self getImageWithName:@"plvlc_linkmic_networkquality_fine"];
        }else{
            self.networkQualityImageView.image = [self getImageWithName:@"plvlc_linkmic_networkquality_bad"];
        }
    }
}

- (void)setSplashImageWithURLString:(NSString *)urlString {
    if (![PLVFdUtil checkStringUseable:urlString]) {
        urlString = kPLVLCTeacherSplashImgURLString;
    }
    self.splashImageView.hidden = NO;
    [PLVLCUtils setImageView:self.splashImageView url:[NSURL URLWithString:urlString]];
}

- (UIImageView *)logoImageView {
    return self.logoView.logoImageView;
}

#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.clipsToBounds = YES;
    self.backgroundColor = PLV_UIColorFromRGB(@"2B3145");
    
    /// 添加视图
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.logoView];
    self.logoView.hidden = YES;
    [self addSubview:self.networkQualityImageView];
    self.networkQualityImageView.hidden = YES;
    [self addSubview:self.splashImageView];
    [self addSubview:self.pauseWatchNoDelayImageView];
    [self addSubview:self.pictureInPicturePlaceholderView];
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLinkMicResource:imageName];
}

#pragma mark Getter
- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        NSString *imageName = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? @"plvlc_linkmic_window_placeholder_ipad" : @"plvlc_linkmic_window_placeholder"; // 占位图适配iPad、iPhone
        _placeholderImageView.image = [self getImageWithName:imageName];
    }
    return _placeholderImageView;
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

- (UIImageView *)networkQualityImageView{
    if (!_networkQualityImageView) {
        _networkQualityImageView = [[UIImageView alloc]init];
        _networkQualityImageView.image = [self getImageWithName:@"plvlc_linkmic_networkquality_good"];
        _networkQualityImageView.layer.shadowColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.3].CGColor;
        _networkQualityImageView.layer.shadowOffset = CGSizeMake(0,0.5);
        _networkQualityImageView.layer.shadowOpacity = 1;
        _networkQualityImageView.layer.shadowRadius = 8;
    }
    return _networkQualityImageView;
}

- (UIImageView *)splashImageView {
    if (!_splashImageView) {
        _splashImageView = [[UIImageView alloc] init];
        _splashImageView.contentMode = UIViewContentModeScaleAspectFit;
        _splashImageView.hidden = YES;
    }
    return _splashImageView;
}

- (UIImageView *)pauseWatchNoDelayImageView {
    if (!_pauseWatchNoDelayImageView) {
        _pauseWatchNoDelayImageView = [[UIImageView alloc] init];
        _pauseWatchNoDelayImageView.hidden = YES;
        _pauseWatchNoDelayImageView.contentMode = UIViewContentModeScaleAspectFit;
        _pauseWatchNoDelayImageView.image = [self getImageWithName:@"plvlc_linkmic_window_pauseWatchNoDelay_placeholder"];
    }
    return _pauseWatchNoDelayImageView;
}

- (PLVLivePictureInPicturePlaceholderView *)pictureInPicturePlaceholderView {
    if (!_pictureInPicturePlaceholderView) {
        _pictureInPicturePlaceholderView = [[PLVLivePictureInPicturePlaceholderView alloc] init];
        _pictureInPicturePlaceholderView.hidden = YES;
    }
    return _pictureInPicturePlaceholderView;
}

@end
