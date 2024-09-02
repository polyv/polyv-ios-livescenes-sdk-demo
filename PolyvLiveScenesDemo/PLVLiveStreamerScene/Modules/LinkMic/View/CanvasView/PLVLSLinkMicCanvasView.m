//
//  PLVLSLinkMicCanvasView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicCanvasView.h"

#import "PLVLSUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVConsoleLogger.h>

static NSString * const kPLVLSTeacherSplashImgURLString = @"https://s1.videocc.net/default-img/channel/default-splash.png";//讲师默认封面图地址

@interface PLVLSLinkMicCanvasView ()

/// view hierarchy
///
/// (PLVLCLinkMicCanvasView) self
///  ├── (UIImageView) placeholderImageView
///  ├── (UIImageView) splashImageView
///  └── (UIView) external rtc View
@property (nonatomic, strong) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)
@property (nonatomic, strong) UIImageView * splashImageView; //音频模式讲师封面图（只支持音频模式时，讲师端显示）
@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)

@end

@implementation PLVLSLinkMicCanvasView

#pragma mark - [ Life Period ]
- (void)dealloc{
    PLV_LOG_INFO(PLVConsoleLogModuleTypeLinkMic,@"%s",__FUNCTION__);
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
    
    CGFloat placeholderImageViewHeight = viewHeight * 0.485;
    self.placeholderImageView.frame = CGRectMake((viewWidth - placeholderImageViewHeight) / 2.0,
                                                 (viewHeight - placeholderImageViewHeight) / 2.0,
                                                 placeholderImageViewHeight,
                                                 placeholderImageViewHeight);
    self.splashImageView.frame = self.bounds;
}


#pragma mark - [ Public Methods ]

- (void)addRTCView:(UIView *)rtcView{
    plv_dispatch_main_async_safe(^{
        if (rtcView) {
            rtcView.frame = self.bounds;
            rtcView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:rtcView];
            self.rtcView = rtcView;
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLSLinkMicCanvasView - add rtc view failed, rtcView illegal:%@",rtcView);
        }
    })
}

- (void)removeRTCView{
    for (UIView * subview in self.subviews) { [subview removeFromSuperview]; }
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.splashImageView];
}

- (void)rtcViewShow:(BOOL)rtcViewShow{
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow;
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLSLinkMicCanvasView - rtcViewShow failed, rtcView is nil");
    }
}

- (void)setSplashImageWithURLString:(NSString *)urlString {
    if (![PLVFdUtil checkStringUseable:urlString]) {
        urlString = kPLVLSTeacherSplashImgURLString;
    }
    self.splashImageView.hidden = NO;
    [PLVLSUtils setImageView:self.splashImageView url:[NSURL URLWithString:urlString]];
}


#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.clipsToBounds = YES;
    self.backgroundColor = PLV_UIColorFromRGB(@"2B3145");
    
    /// 添加视图
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.splashImageView];
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLSUtils imageForLinkMicResource:imageName];
}

#pragma mark Getter

- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        _placeholderImageView.image = [self getImageWithName:@"plvls_linkmic_window_placeholder"];
    }
    return _placeholderImageView;
}

- (UIImageView *)splashImageView{
    if (!_splashImageView) {
        _splashImageView = [[UIImageView alloc]init];
        _splashImageView.contentMode = UIViewContentModeScaleAspectFill;
        _splashImageView.hidden = YES;
    }
    return _splashImageView;
}

@end
