//
//  PLVLCMediaAreaView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/15.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCMediaAreaView.h"

// UI
#import "PLVLCMediaPlayerCanvasView.h"
#import "PLVLCMediaMoreView.h"
#import "PLVPlayerLogoView.h"
#import "PLVWatermarkView.h"

// 模块
#import "PLVDocumentView.h"
#import "PLVDanMu.h"
#import "PLVEmoticonManager.h"
#import "PLVRoomDataManager.h"
#import "PLVPlayerPresenter.h"

// 工具
#import "PLVLCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const PLVLCMediaAreaView_Data_ModeOptionTitle = @"模式";
static NSString *const PLVLCMediaAreaView_Data_QualityOptionTitle = @"视频质量";
static NSString *const PLVLCMediaAreaView_Data_RouteOptionTitle = @"线路";
static NSString *const PLVLCMediaAreaView_Data_LiveDelayOptionTitle = @"延迟";
static NSString *const PLVLCMediaAreaView_Data_SpeedOptionTitle = @"倍速";
static NSInteger const PLVLCMediaAreaView_Data_TryPlayPPTViewMaxNum = 5;

@interface PLVLCMediaAreaView () <
PLVLCFloatViewDelegate,
PLVLCMediaMoreViewDelegate,
PLVLCMediaPlayerCanvasViewDelegate,
PLVDocumentViewDelegate,
PLVPlayerPresenterDelegate,
PLVLCRetryPlayViewDelegate,
PLVRoomDataManagerProtocol
>

#pragma mark 状态
@property (nonatomic, assign, readonly) BOOL inLinkMic; // 只读，是否正在连麦
@property (nonatomic, assign, readonly) BOOL inRTCRoom; // 只读，是否正在RTC房间中
@property (nonatomic, assign, readonly) BOOL isOnlyAudio; // 只读，当前频道是否只支持音频模式
@property (nonatomic, assign, readonly) PLVChannelType channelType; // 只读，当前 频道类型
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType; // 只读，当前 视频类型
@property (nonatomic, assign, readonly) PLVChannelLiveStreamState liveState; // 只读，当前 直播流状态
@property (nonatomic, assign, readonly) PLVChannelLinkMicSceneType linkMicSceneType; // 只读，当前 连麦场景类型
@property (nonatomic, assign) PLVChannelLinkMicSceneType lastLinkMicSceneType; // 上次 连麦场景类型
@property (nonatomic, assign) PLVLCMediaAreaViewLiveSceneType currentLiveSceneType;
@property (nonatomic, assign, readonly) BOOL pptOnMainSite;     // 只读，PPT当前是否处于主屏 (此属性仅适合判断PPT是否在主屏，不适合判断其他视图所处位置)
@property (nonatomic, assign) BOOL networkQualityMiddleViewShowed;         // 网络不佳提示视图是否显示过
@property (nonatomic, assign) BOOL networkQualityPoorViewShowed;   // 网络糟糕提示视图是否显示过
@property (nonatomic, assign, readonly) BOOL pausedWatchNoDelay; //只读，是否暂停无延迟直播

#pragma mark 模块
@property (nonatomic, strong) PLVPlayerPresenter * playerPresenter; // 播放器 功能模块
@property (nonatomic, strong) PLVDocumentView * pptView;                 // PPT 功能模块
@property (nonatomic, assign) NSInteger tryPlayPPTViewNum; // 尝试播放PPTView次数

#pragma mark 数据
@property (nonatomic, readonly) PLVRoomData *roomData;  // 只读，当前直播间数据

#pragma mark UI
/// view hierarchy
///
/// [竖屏] 主屏显示 播放器画面 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   ├── (UIView) contentBackgroudView
/// │   │    └── (PLVLCMediaPlayerCanvasView) canvasView
/// │   ├── (PLVWatermarkView) watermarkView
/// │   └── (PLVLCMediaPlayerSkinView) skinView
/// │
/// ├── (PLVMarqueeView) marqueeView
/// │
/// └── (PLVLCMediaFloatView) floatView
///      └── (UIView) contentBackgroudView
///           └── (PLVPPTView) pptView
///
/// [竖屏] 主屏显示 PPT 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   ├── (UIView) contentBackgroudView
/// │   │    └── (PLVPPTView) pptView
/// │   ├── (PLVWatermarkView) watermarkView
/// │   └── (PLVLCMediaPlayerSkinView) skinView
/// │
/// ├── (PLVMarqueeView) marqueeView
/// │
/// └── (PLVLCMediaFloatView) floatView
///      └── (UIView) contentBackgroudView
///           └── (PLVLCMediaPlayerCanvasView) canvasView
///
/// [横屏] 主屏显示 播放器画面 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   └── (UIView) contentBackgroudView
/// │   ├── (PLVWatermarkView) watermarkView
/// │   └── (PLVLCMediaPlayerCanvasView) canvasView
/// │
/// ├── (PLVLCMediaFloatView) floatView
/// │     └── (UIView) contentBackgroudView
/// │          └── (PLVPPTView) pptView
/// │
/// ├── (PLVLCLiveRoomPlayerSkinView) liveRoomSkinView
/// │
/// └── (PLVMarqueeView) marqueeView
///
/// [横屏] 主屏显示 PPT 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   └── (UIView) contentBackgroudView
/// │   ├── (PLVWatermarkView) watermarkView
/// │   └── (PLVLCMediaPlayerCanvasView) pptView
/// │
/// ├── (PLVLCMediaFloatView) floatView
/// │     └── (UIView) contentBackgroudView
/// │          └── (PLVLCMediaPlayerCanvasView) canvasView
/// │
/// ├── (PLVLCLiveRoomPlayerSkinView) liveRoomSkinView
/// │
/// └── (PLVMarqueeView) marqueeView
@property (nonatomic, strong) UIView * contentBackgroudView; // 内容背景视图 (负责承载 不同类型的内容画面（播放器画面、或PPT画面）；直接决定了’内容画面‘ 在 PLVLCMediaAreaView 中的布局、图层)
@property (nonatomic, strong) PLVLCMediaPlayerCanvasView * canvasView; // 播放器背景视图 (负责承载 播放器画面；可能会被移动添加至外部视图类中；当被移动添加至外部时，仍被 PLVLCMediaAreaView 持有，但subview关系改变；)
@property (nonatomic, strong) PLVLCMediaPlayerSkinView * skinView;     // 竖屏播放器皮肤视图 (负责承载 播放器的控制按钮)
@property (nonatomic, strong) PLVLCMediaFloatView * floatView;
@property (nonatomic, strong) PLVLCMediaMoreView * moreView;
@property (nonatomic, strong) PLVDanMu *danmuView;  // 弹幕 (用于显示 ‘聊天室消息’)
@property (nonatomic, strong) PLVMarqueeView * marqueeView; // 跑马灯 (用于显示 ‘用户昵称’，规避非法录屏)
@property (nonatomic, strong) PLVPlayerLogoView * logoView; // LOGO视图 （用于显示 '播放器LOGO'）
@property (nonatomic, strong) PLVWatermarkView * watermarkView; // 防录屏水印
@property (nonatomic, strong) PLVLCRetryPlayView *retryPlayView; // 播放重试视图（用于直播回放场景，播放中断时显示提示视图）
@property (nonatomic, assign) NSTimeInterval interruptionTime;
@property (nonatomic, strong) UILabel *networkQualityMiddleLable; // 网络不佳提示视图
@property (nonatomic, strong) UIView *networkQualityPoorView; // 网络糟糕提示视图

@end

@implementation PLVLCMediaAreaView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.tryPlayPPTViewNum = 0;
        [self setupUI];
        [self setupModule];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat superviewWidth = CGRectGetWidth(self.superview.bounds);
    CGFloat superviewHeight = CGRectGetHeight(self.superview.bounds);
    
    // 安全区域计算
    CGFloat toppadding;
    CGFloat leftpadding;
    CGFloat viewSafeWidth;
    CGFloat viewSafeHeight;
    if (@available(iOS 11.0, *)) {
        toppadding = self.safeAreaInsets.top;
        leftpadding = self.safeAreaInsets.left;
        viewSafeWidth = self.safeAreaLayoutGuide.layoutFrame.size.width;
        viewSafeHeight = self.safeAreaLayoutGuide.layoutFrame.size.height;
    } else {
        toppadding = fullScreen ? 0 : self.topPaddingBelowiOS11;
        leftpadding = 0;
        viewSafeWidth = viewWidth;
        viewSafeHeight = viewHeight - toppadding;
    }
    
    if (!fullScreen) {
        // 竖屏
        CGFloat contentBackgroudViewY = self.limitContentViewInSafeArea ? toppadding : 0;
        CGFloat contentBackgroudViewHeight = self.limitContentViewInSafeArea ? viewSafeHeight : viewHeight;
        self.contentBackgroudView.frame = CGRectMake(0, contentBackgroudViewY, viewWidth, contentBackgroudViewHeight);
        self.networkQualityMiddleLable.frame = CGRectMake(16, viewHeight - 28 - 36, 219, 28);
        self.networkQualityPoorView.frame = CGRectMake(viewWidth - 275 - 4, contentBackgroudViewY + 39, 275, 28);
    } else {
        // 横屏
        CGFloat contentBackgroudViewX = self.limitContentViewInSafeArea ? leftpadding : 0;
        CGFloat contentBackgroudViewWidth = self.limitContentViewInSafeArea ? viewSafeWidth : viewWidth;
        self.contentBackgroudView.frame = CGRectMake(contentBackgroudViewX, 0, contentBackgroudViewWidth, viewHeight);
        self.networkQualityMiddleLable.frame = CGRectMake(contentBackgroudViewX + 16, viewHeight - 28 - 58, 219, 28);
        self.networkQualityPoorView.frame = CGRectMake(superviewWidth - 275 - 4 - leftpadding, 50, 275, 28);
    }
    
    [self.danmuView resetFrame:self.contentBackgroudView.frame];

    self.skinView.frame = self.bounds;
    
    CGFloat floatViewWidth = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 224 : 150;
    CGFloat floatViewHeight = floatViewWidth * PPTPlayerViewScale;
    
    /// 将 floatView 添加在父视图上
    /// (注:不可添加在window上，否则页面push时将一并带去)
    if (self.superview && !_floatView.superview) { [self.superview addSubview:self.floatView]; }
    self.floatView.frame = CGRectMake((superviewWidth - floatViewWidth),
                                      (superviewHeight - floatViewHeight) / 2.0 + 50,
                                      floatViewWidth, floatViewHeight);
    
    if (self.superview && !self.marqueeView.superview) { [self.superview addSubview:self.marqueeView]; }
    self.marqueeView.frame = self.contentBackgroudView.frame;
    
    // iPad分屏尺寸变动，刷新更多弹框布局
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.moreView setNeedsLayout];
        [self.moreView layoutIfNeeded];
    }

    self.retryPlayView.frame = self.frame;
    self.watermarkView.frame = self.contentBackgroudView.frame;
}


#pragma mark - [ Public Methods ]
- (void)refreshUIInfo {
    PLVRoomData *roomData = self.roomData;
    [self.skinView setTitleLabelWithText:roomData.menuInfo.name];
    [self.skinView setPlayTimesLabelWithTimes:roomData.menuInfo.pageView.integerValue];
}

- (void)switchAreaViewLiveSceneTypeTo:(PLVLCMediaAreaViewLiveSceneType)toType{
    if (self.currentLiveSceneType == toType) {
        NSLog(@"PLVLCMediaAreaView - switchAreaViewLiveSceneTypeTo failed, type is same");
        return;
    }else if(self.videoType != PLVChannelVideoType_Live){
        NSLog(@"PLVLCMediaAreaView - switchAreaViewLiveSceneTypeTo failed, video type is not 'Live'");
        return;
    }
    
    if (toType == PLVLCMediaAreaViewLiveSceneType_WatchCDN) { /// 观看 ‘CDN’ 场景
        if (self.liveState == PLVChannelLiveStreamState_Live) {
            // 直播中
            if (self.channelType == PLVChannelTypePPT) {
                /// 出现 floatView
                /// 其中 userOperat:YES 表示 ’代表用户去执行’，即强制执行
                [self.floatView showFloatView:YES userOperat:YES];
            } else if(self.channelType == PLVChannelTypeAlone){
                [self contentBackgroundViewDisplaySubview:self.canvasView];
            }
            
            /// 恢复直播播放器
            [self.playerPresenter resumePlay];
            
            if (self.lastLinkMicSceneType == PLVChannelLinkMicSceneType_Alone_PartRtc) {
                /// 直播播放器 解除静音
                [self.playerPresenter cancelMute];
            }
            
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
        }else{
            // 直播已结束
            if (self.channelType == PLVChannelTypePPT) {
                /// 确保 ‘播放器画面’ 位于主屏
                if (self.pptOnMainSite) { [self.floatView triggerViewExchangeEvent]; }
            } else if(self.channelType == PLVChannelTypeAlone){
                [self contentBackgroundViewDisplaySubview:self.canvasView];
            }
            
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        }
    } else if (toType == PLVLCMediaAreaViewLiveSceneType_WatchNoDelay) {
        if (self.currentLiveSceneType == PLVLCMediaAreaViewLiveSceneType_WatchCDN) {
            /// 播放器 清理
            [self.playerPresenter cleanPlayer];
            
            /// 确保 PPT 位于主屏
            if (!self.pptOnMainSite) {
                [self.floatView triggerViewExchangeEvent];
            }
            
            /// 隐藏 floatView
            /// userOperat:YES 表示代表用户强制执行
            [self.floatView showFloatView:NO userOperat:YES];
        }
        /// 竖屏皮肤视图
        [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay];
    } else if (toType == PLVLCMediaAreaViewLiveSceneType_InLinkMic){ /// 正在 ‘连麦’ 场景
        if (self.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_WatchNoDelay) {
            if (self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PartRtc) {
                /// 直播播放器 仅作静音
                [self.playerPresenter mute];
                
                /// 竖屏皮肤视图
                [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PartRTC];
            } else if (self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PureRtc){
                /// 直播播放器 清理
                [self.playerPresenter cleanPlayer];
                
                /// 竖屏皮肤视图
                [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC];
            }else if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc){
                /// 确保 PPT 位于主屏
                if (!self.pptOnMainSite) { [self.floatView triggerViewExchangeEvent]; }
                
                /// 直播播放器清理
                [self.playerPresenter cleanPlayer];
                
                /// 隐藏 floatView
                /// userOperat:YES 表示代表用户强制执行
                [self.floatView showFloatView:NO userOperat:YES];
                
                /// 竖屏皮肤视图
                [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC];
            }
        } else {
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC];
        }
        self.lastLinkMicSceneType = self.linkMicSceneType;
        /// 隐藏更多设置视图
        if (self.moreView.moreViewShow) {
            [self.moreView switchShowStatusWithAnimation];
        }
    } else {
        NSLog(@"PLVLCMediaAreaView - switchAreaViewLiveSceneTypeTo failed, type%lud not support",(unsigned long)toType);
    }
    
    self.currentLiveSceneType = toType;
}

- (void)displayContentView:(UIView *)contentView{
    if (contentView && [contentView isKindOfClass:UIView.class]) {
        // 设置PPT是否在主页
        [self setupMainSpeakerPPTOnMain:[self isPptView:contentView]];
        [self contentBackgroundViewDisplaySubview:contentView];
    }else{
        NSLog(@"PLVLCMediaAreaView - displayExternalView failed, view is illegal : %@",contentView);
    }
}

- (UIView *)getContentViewForExchange{
    if (self.currentLiveSceneType == PLVLCMediaAreaViewLiveSceneType_InLinkMic || self.currentLiveSceneType == PLVLCMediaAreaViewLiveSceneType_WatchNoDelay) {
        UIView * currentContentView = self.contentBackgroudView.subviews.firstObject;
        if (currentContentView) {
            return currentContentView;
        }else{
            NSLog(@"PLVLCMediaAreaView - getViewForExchange failed, currentContentView is illegal : %@",currentContentView);
        }
    }else{
        NSLog(@"PLVLCMediaAreaView - getViewForExchange failed, this method should been call in LinkMic or NoDelay, but current liveSceneType is %lu",(unsigned long)self.currentLiveSceneType);
    }
    return nil;
}

- (void)seekLivePlaybackToTime:(NSTimeInterval)time {
    [self.playerPresenter seekLivePlaybackToTime:time];
}

- (BOOL)isPptView:(UIView *)view {
    if (view &&
        [view isKindOfClass:[PLVDocumentView class]]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark 网络质量
- (void)showNetworkQualityMiddleView {
    if (self.networkQualityMiddleViewShowed) {
        return;
    }
    self.networkQualityMiddleViewShowed = YES;
    self.networkQualityMiddleLable.hidden = NO;

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.networkQualityMiddleLable.hidden = YES;
    });
}

- (void)showNetworkQualityPoorView {
    if (self.networkQualityPoorViewShowed) {
        return;
    }
    self.networkQualityPoorViewShowed = YES;
    self.networkQualityPoorView.hidden = NO;

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.networkQualityPoorView.hidden = YES;
    });
}

#pragma mark Getter
- (BOOL)channelInLive{
    return self.playerPresenter.channelInLive;
}

- (BOOL)channelWatchNoDelay{
    return self.playerPresenter.channelWatchNoDelay;
}

- (BOOL)channelWatchQuickLive{
    return self.playerPresenter.channelWatchQuickLive;
}

- (BOOL)noDelayWatchMode {
    return self.playerPresenter.noDelayWatchMode;
}

- (BOOL)quickLiveWatching {
    return self.playerPresenter.quickLiveWatching;
}

- (BOOL)noDelayLiveWatching{
    return self.playerPresenter.noDelayLiveWatching;
}

- (BOOL)noDelayLiveStart{
    return self.playerPresenter.currentNoDelayLiveStart;
}

- (BOOL)mainSpeakerPPTOnMain{
    return self.pptView.mainSpeakerPPTOnMain;
}

#pragma mark - [ Private Methods ]
- (void)setupData{
    self.currentLiveSceneType = PLVLCMediaAreaViewLiveSceneType_WatchCDN;
}

- (void)setupUI{
    /// 添加视图
    [self addSubview:self.contentBackgroudView];
    
    [self contentBackgroundViewDisplaySubview:self.canvasView]; // 无直播时的默认状态，是‘播放器画面’位于主屏
    
    [self addSubview:self.danmuView];
    
    [self addSubview:self.skinView];
    
    [self addSubview:self.retryPlayView];
    
    /// 网络质量提示
    [self.skinView.superview addSubview:self.networkQualityMiddleLable];
    [self.skinView.superview addSubview:self.networkQualityPoorView];
}

- (void)contentBackgroundViewDisplaySubview:(UIView *)subview{
    [self removeSubview:self.contentBackgroudView];
    [self.contentBackgroudView addSubview:subview];
    subview.frame = self.contentBackgroudView.bounds;
    subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)setupModule{
    /// 注意：懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    if (self.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 直播 模块
        self.playerPresenter = [[PLVPlayerPresenter alloc] initWithVideoType:PLVChannelVideoType_Live];
        self.playerPresenter.delegate = self;
        [self.playerPresenter setupPlayerWithDisplayView:self.canvasView.playerSuperview];
         
        /// PPT模块
        [self.floatView displayExternalView:self.pptView]; /// 无直播时的默认状态，是‘PPT画面’位于副屏(悬浮小窗)
        
    }else if (self.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        /// 直播回放 模块
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        self.playerPresenter = [[PLVPlayerPresenter alloc] initWithVideoType:PLVChannelVideoType_Playback];
        self.playerPresenter.delegate = self;
        [self.playerPresenter setupPlayerWithDisplayView:self.canvasView.playerSuperview];
        
        /// PPT模块
        [self.floatView displayExternalView:self.pptView]; /// 默认状态，是‘PPT画面’位于副屏(悬浮小窗)
        [self.floatView showFloatView:YES userOperat:NO];
        [self playPPTView];
    }
}

- (void)playPPTView {
    NSString *channelId = self.roomData.channelId;
    NSString *videoId = self.playerPresenter.videoId;
    if ([PLVFdUtil checkStringUseable:channelId] &&
        [PLVFdUtil checkStringUseable:videoId]) { // videoId 在app启动后立马取值不一定有值，需要递归处理
        [self.pptView pptStartWithVideoId:videoId channelId:channelId];
    } else {
        if(self.tryPlayPPTViewNum < PLVLCMediaAreaView_Data_TryPlayPPTViewMaxNum) { // 限制重试次数
            __weak typeof(self)weakSelf = self;
            CGFloat afterTime = (self.tryPlayPPTViewNum * 2 + 1) * 0.5; // 重试时间间隔随次数增长而增长
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((afterTime * NSEC_PER_SEC))), dispatch_get_main_queue(), ^{
                weakSelf.tryPlayPPTViewNum +=1;
                [weakSelf playPPTView];
            });
        } else {
            [PLVLCUtils showHUDWithTitle:@"" detail:@"加载PPT出错，请重新登录" view:[PLVFdUtil getCurrentViewController].view afterDelay:3.0];
        }
    }
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForMediaResource:imageName];
}

- (void)removeSubview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

- (NSArray *)getMoreViewDefaultDataArray{
    if (self.videoType == PLVChannelVideoType_Playback) { // 视频类型为 直播回放
        PLVLCMediaMoreModel * speedModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_SpeedOptionTitle optionItemsArray:@[@"0.5x",@"1.0x",@"1.5x",@"2.0x"] selectedIndex:1];
        speedModel.optionSpecifiedWidth = 50.0;
        return @[speedModel];
    }
    return nil;
}

- (void)updateMoreviewWithData {
    // 音视频切换选项数据
    PLVLCMediaMoreModel *modeModel = nil;
    // 视频质量选项数据
    PLVLCMediaMoreModel *qualityModel = nil;
    // 线路选项数据
    PLVLCMediaMoreModel *routeModel = nil;
    // 直播延迟选项数据
    PLVLCMediaMoreModel *liveDelayModel = nil;
    
    // 无延迟直播和快直播频道支持切换延迟模式
    if (self.channelWatchNoDelay || self.channelWatchQuickLive) {
        liveDelayModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_LiveDelayOptionTitle optionItemsArray:@[@"无延迟",@"正常延迟"] selectedIndex:!self.noDelayWatchMode];
    }

    // 观看无延迟直播和快直播时不支持切换音视频模式、视频质量和线路
    if (!self.noDelayWatchMode) {
        NSArray<NSString *> *optionItemsArray = self.isOnlyAudio ? @[@"仅听声音"] : @[@"播放画面",@"仅听声音"];
        modeModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_ModeOptionTitle optionItemsArray:optionItemsArray selectedIndex:self.playerPresenter.audioMode];
        
        qualityModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_QualityOptionTitle optionItemsArray:self.playerPresenter.codeRateNamesOptions];
        [qualityModel setSelectedIndexWithOptionItemString:self.playerPresenter.currentCodeRate];
        
        NSMutableArray * routeArray = [[NSMutableArray alloc] init];
        for (int i = 1; i <= self.playerPresenter.lineNum; i++) {
            NSString * route = [NSString stringWithFormat:@"线路%d",i];
            [routeArray addObject:route];
        }
        routeModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_RouteOptionTitle optionItemsArray:routeArray selectedIndex:self.playerPresenter.currentLineIndex];
    }
    
    // 整合数据
    NSMutableArray * modelArray = [[NSMutableArray alloc] init];
    if (modeModel) { [modelArray addObject:modeModel]; }
    if (qualityModel) { [modelArray addObject:qualityModel]; }
    if (routeModel) { [modelArray addObject:routeModel]; }
    if (liveDelayModel) { [modelArray addObject:liveDelayModel]; }

    // 更新 moreView
    [self.moreView refreshTableViewWithDataArray:modelArray];
    [self.moreView refreshTableView];
}

/// 延迟模式切换
- (void)switchToNoDelayWatchMode:(BOOL)noDelayWatchMode {
    if (self.inLinkMic) {
        return;
    }
    if (self.playerPresenter.audioMode) {
        [self switchLiveToAudioMode:NO];
    }
    [self.playerPresenter switchToNoDelayWatchMode:noDelayWatchMode];
    self.networkQualityMiddleViewShowed = self.networkQualityPoorViewShowed = NO;
    if (self.channelWatchNoDelay) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaView:noDelayWatchModeSwitched:)]) {
            [self.delegate plvLCMediaAreaView:self noDelayWatchModeSwitched:noDelayWatchMode];
        }
    }
}

/// 音视频观看模式切换
- (void)switchLiveToAudioMode:(BOOL)audioMode {
    self.logoView.hidden = !audioMode;
    [self.canvasView switchTypeTo:audioMode ? PLVLCMediaPlayerCanvasViewType_Audio : PLVLCMediaPlayerCanvasViewType_Video];
    [self.playerPresenter switchLiveToAudioMode:audioMode];
}

#pragma mark Danmu
- (void)showDanmu:(BOOL)show {
    self.danmuView.hidden = !show;
}

- (void)insertDanmu:(NSString *)danmu {
    UIFont *font = [UIFont systemFontOfSize:14];
    NSShadow *shadow = [NSShadow new];
    shadow.shadowOffset = CGSizeMake(1, 1);
    shadow.shadowColor = PLV_UIColorFromRGB(@"#333333");
    NSDictionary *dict = @{NSFontAttributeName:font,
                           NSForegroundColorAttributeName:[UIColor whiteColor],
                           NSShadowAttributeName:shadow};
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:danmu attributes:dict];
    NSMutableAttributedString *muString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attString font:font];
    [self.danmuView insertDML:muString];
}

#pragma mark Marquee
- (void)setupMarquee:(PLVChannelInfoModel *)channel customNick:(NSString *)customNick  {
    __weak typeof(self) weakSelf = self;
    [self handleMarquee:channel customNick:customNick completion:^(PLVMarqueeStyleModel *model, NSError *error) {
        if (model) {
            [weakSelf loadVideoMarqueeView:model];
        } else if (error) {
            if (error.code == -10000) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(plvLCMediaAreaViewWannaBack:)]) {
                    [weakSelf.delegate plvLCMediaAreaViewWannaBack:weakSelf];
                }
            } else {
                NSLog(@"自定义跑马灯加载失败：%@",error);
            }
        } else {
            NSLog(@"无跑马灯或跑马灯不显示");
        }
    }];
}

- (void)handleMarquee:(PLVChannelInfoModel *)channel customNick:(NSString *)customNick completion:(void (^)(PLVMarqueeStyleModel * model, NSError *error))completion {
    switch (channel.marqueeType) {
        case PLVChannelMarqueeType_Nick:
            if (customNick) {
                channel.marquee = customNick;
            } else {
                channel.marquee = @"自定义昵称";
            }
        case PLVChannelMarqueeType_Fixed: {
            float alpha = channel.marqueeOpacity.floatValue/100.0;
            PLVMarqueeStyleModel *model = [PLVMarqueeStyleModel createMarqueeModelWithContent:channel.marquee fontSize:channel.marqueeFontSize.unsignedIntegerValue fontColor:channel.marqueeFontColor alpha:alpha style:channel.marqueeSetting];
            completion(model, nil);
        } break;
        case PLVChannelMarqueeType_URL: {
            if (channel.marquee) {
                [PLVLiveVideoAPI loadCustomMarquee:[NSURL URLWithString:channel.marquee] withChannelId:channel.channelId.integerValue userId:channel.accountUserId code:@"" completion:^(BOOL valid, NSDictionary *marqueeDict) {
                    if (valid) {
                        completion([PLVMarqueeStyleModel createMarqueeModelWithMarqueeDict:marqueeDict], nil);
                    } else {
                        NSError *error = [NSError errorWithDomain:@"net.plv.cloudClassBaseMediaError" code:-10000 userInfo:@{NSLocalizedDescriptionKey:marqueeDict[@"msg"]}];
                        completion(nil, error);
                    }
                } failure:^(NSError *error) {
                    completion(nil, error);
                }];
            }
        } break;
        default:
            completion(nil, nil);
            break;
    }
}

- (void)loadVideoMarqueeView:(PLVMarqueeStyleModel *)model {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 设置跑马灯
        [weakSelf.marqueeView setPLVMarqueeModel:model];
        [weakSelf.marqueeView start];
    });
}

#pragma mark  播放器LOGO
- (void)setupPlayerLogoImage {
    if (self.canvasView) {
        [self.logoView addAtView:self.canvasView];
    }
}

#pragma mark 防录屏水印
- (void)setupWatermark {
    if (self.contentBackgroudView) {
        [self addSubview:self.watermarkView];
    }
}

#pragma mark Getter
- (CGFloat)topPaddingBelowiOS11{
    /// 仅在 [limitContentViewInSafeArea] 为YES，会使用此值，否则均返回 0
    return self.limitContentViewInSafeArea ? _topPaddingBelowiOS11 : 0;
}

- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
    }
    return _contentBackgroudView;
}

- (PLVLCMediaPlayerCanvasView *)canvasView{
    if (!_canvasView) {
        _canvasView = [[PLVLCMediaPlayerCanvasView alloc] init];
        _canvasView.delegate = self;
    }
    return _canvasView;
}

- (PLVMarqueeView *)marqueeView{
    if (!_marqueeView) {
        _marqueeView = [[PLVMarqueeView alloc] init];
        _marqueeView.backgroundColor = [UIColor clearColor];
        _marqueeView.userInteractionEnabled = NO;
    }
    return _marqueeView;
}

- (PLVDanMu *)danmuView {
    if (!_danmuView) {
        _danmuView = [[PLVDanMu alloc] init];
        _danmuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _danmuView.hidden = YES;
        _danmuView.userInteractionEnabled = NO;
    }
    return _danmuView;
}

- (PLVLCMediaPlayerSkinView *)skinView{
    if (!_skinView) {
        _skinView = [[PLVLCMediaPlayerSkinView alloc] init];
        _skinView.baseDelegate = self;
    }
    return _skinView;
}

- (PLVLCMediaFloatView *)floatView{
    if (!_floatView && self.channelType != PLVChannelTypeAlone) {
        _floatView = [[PLVLCMediaFloatView alloc] init];
        _floatView.delegate = self;
    }
    return _floatView;
}

- (PLVLCMediaMoreView *)moreView{
    if (!_moreView) {
        _moreView = [[PLVLCMediaMoreView alloc] init];
        _moreView.delegate = self;
        _moreView.topPaddingBelowiOS11 = 20.0;
        [_moreView refreshTableViewWithDataArray:[self getMoreViewDefaultDataArray]]; // 本地可决定的选项数据，则创建时一并设置
    }
    return _moreView;
}

- (PLVDocumentView *)pptView{
    if (!_pptView && self.channelType != PLVChannelTypeAlone) {
        _pptView = [[PLVDocumentView alloc] initWithScene:PLVDocumentViewSceneCloudClass];
        _pptView.delegate = self;
        _pptView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B3045"];
        UIImage *pptBgImage = [self getImageWithName:@"plvlc_media_ppt_placeholder"];
        [_pptView setBackgroudImage:pptBgImage widthScale:180.0/375.0];
        [_pptView loadRequestWitParamString:nil];
    }
    return _pptView;
}

- (PLVLCRetryPlayView *)retryPlayView {
    if (!_retryPlayView) {
        _retryPlayView = [[PLVLCRetryPlayView alloc]init];
        _retryPlayView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.1);
        _retryPlayView.hidden = YES;
        _retryPlayView.delegate = self;
    }
    return _retryPlayView;
}

- (PLVWatermarkView *)watermarkView {
    if (!_watermarkView) {
        PLVChannelInfoModel *channel = self.roomData.channelInfo;
        if (channel.watermarkRestrict) {
            NSString *content = channel.watermarkContent;
            if (channel.watermarkType == PLVChannelWatermarkType_Nick) {
                content = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerName;
            }
            PLVWatermarkModel *model = [PLVWatermarkModel watermarkModelWithContent:content fontSize:channel.watermarkFontSize opacity:channel.watermarkOpacity];
            _watermarkView = [[PLVWatermarkView alloc] initWithWatermarkModel:model];
        }
    }
    return _watermarkView;
}

- (PLVPlayerLogoView *)logoView {
    if (!_logoView) {
        PLVChannelInfoModel *channel = self.roomData.channelInfo;
        if ([PLVFdUtil checkStringUseable:channel.logoImageUrl]) {
            PLVPlayerLogoParam *logoParam = [[PLVPlayerLogoParam alloc] init];
            logoParam.logoUrl = channel.logoImageUrl;
            logoParam.position = channel.logoPosition;
            logoParam.logoAlpha = channel.logoOpacity;
            logoParam.logoWidthScale = 0.14;
            logoParam.logoHeightScale = 0.25;

            _logoView = [[PLVPlayerLogoView alloc] init];
            [_logoView insertLogoWithParam:logoParam];
        }
    }
    return _logoView;
}

- (UILabel *)networkQualityMiddleLable {
    if (!_networkQualityMiddleLable) {
        _networkQualityMiddleLable = [[UILabel alloc] init];
        _networkQualityMiddleLable.text = @"您的网络状态不佳，可尝试切换网络";
        _networkQualityMiddleLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _networkQualityMiddleLable.textColor = [UIColor whiteColor];
        _networkQualityMiddleLable.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.6);
        _networkQualityMiddleLable.layer.masksToBounds = YES;
        _networkQualityMiddleLable.layer.cornerRadius = 12;
        _networkQualityMiddleLable.hidden = YES;
        _networkQualityMiddleLable.textAlignment = NSTextAlignmentCenter;
    }
    return _networkQualityMiddleLable;
}

- (UIView *)networkQualityPoorView {
    if (!_networkQualityPoorView) {
        _networkQualityPoorView = [[UIView alloc] init];
        _networkQualityPoorView.hidden = YES;
        _networkQualityPoorView.backgroundColor =  PLV_UIColorFromRGBA(@"#000000", 0.6);
        _networkQualityPoorView.layer.masksToBounds = YES;
        _networkQualityPoorView.layer.cornerRadius = 12;
        
        UILabel *tipsLable = [[UILabel alloc] init];
        tipsLable = [[UILabel alloc] init];
        tipsLable.text = @"您的网络状态糟糕，可尝试";
        tipsLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        tipsLable.textColor = [UIColor whiteColor];
        [_networkQualityPoorView addSubview:tipsLable];
        tipsLable.frame = CGRectMake(12, 0, 147, 28);

        UIButton *swithDelayLiveButton = [[UIButton alloc] init];
        [swithDelayLiveButton setTitle:@"切换到正常延迟" forState:UIControlStateNormal];
        [swithDelayLiveButton setTitleColor:PLV_UIColorFromRGB(@"#6DA7FF") forState:UIControlStateNormal];
        [swithDelayLiveButton addTarget:self action:@selector(swithDelayLiveClick:) forControlEvents:UIControlEventTouchUpInside];
        swithDelayLiveButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        [_networkQualityPoorView addSubview:swithDelayLiveButton];
        swithDelayLiveButton.frame = CGRectMake(161, 0, 86, 28);
        
        UIButton *closeButton = [[UIButton alloc] init];
        [closeButton addTarget:self action:@selector(closeNetworkTipsViewClick:) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setImage:[self getImageWithName:@"plvlc_media_network_tips_close"] forState:UIControlStateNormal];
        [_networkQualityPoorView addSubview:closeButton];
        closeButton.frame = CGRectMake(250, 6, 16, 16);
    }
    return _networkQualityPoorView;
}

- (BOOL)inLinkMic{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaViewGetInLinkMic:)]) {
        return [self.delegate plvLCMediaAreaViewGetInLinkMic:self];
    }else{
        NSLog(@"PLVLCMediaViewController - delegate not implement method:[plvLCMediaAreaViewGetInLinkMic:]");
        return NO;
    }
}

- (BOOL)pausedWatchNoDelay {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaViewGetPausedWatchNoDelay:)]) {
        return [self.delegate plvLCMediaAreaViewGetPausedWatchNoDelay:self];
    }else{
        NSLog(@"PLVLCMediaViewController - delegate not implement method:[plvLCMediaAreaViewGetPausedWatchNoDelay:]");
        return NO;
    }
}

- (BOOL)inRTCRoom{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaViewGetInLinkMic:)]) {
        return [self.delegate plvLCMediaAreaViewGetInRTCRoom:self];
    }else{
        NSLog(@"PLVLCMediaViewController - delegate not implement method:[plvLCMediaAreaViewGetInRTCRoom:]");
        return NO;
    }
}

- (NSTimeInterval)currentPlayTime {
    return self.playerPresenter.currentPlaybackTime;
}

- (PLVRoomData *)roomData {
    return [PLVRoomDataManager sharedManager].roomData;
}

- (BOOL)isOnlyAudio {
    return [PLVRoomDataManager sharedManager].roomData.channelInfo.isOnlyAudio;
}

- (PLVChannelType)channelType{
    return [PLVRoomDataManager sharedManager].roomData.channelType;
}

- (PLVChannelVideoType)videoType{
    return [PLVRoomDataManager sharedManager].roomData.videoType;
}

- (PLVChannelLiveStreamState)liveState{
    return [PLVRoomDataManager sharedManager].roomData.liveState;
}

- (PLVChannelLinkMicSceneType)linkMicSceneType{
    return [PLVRoomDataManager sharedManager].roomData.linkMicSceneType;
}

- (BOOL)pptOnMainSite{
    if (self.pptView.superview == self.contentBackgroudView) {
        return YES;
    }else{
        return NO;
    }
}

- (void)setupMainSpeakerPPTOnMain:(BOOL)pptOnMainSite {
    [self.skinView setupMainSpeakerPPTOnMain:pptOnMainSite];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCMediaAreaView:didChangeMainSpeakerPPTOnMain:)]) {
        [self.delegate plvLCMediaAreaView:self didChangeMainSpeakerPPTOnMain:pptOnMainSite];
    }
}

#pragma mark - [ Delegate ]
#pragma mark PLVLCBasePlayerSkinViewDelegate
- (void)plvLCBasePlayerSkinViewBackButtonClicked:(PLVLCBasePlayerSkinView *)skinView currentFullScreen:(BOOL)currentFullScreen{
    Boolean isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    if (currentFullScreen && !isPad) {
        // 非iPad的全屏下，返回竖屏
        [PLVFdUtil changeDeviceOrientationToPortrait];
    }else{
        __weak typeof(self) weakSelf = self;
        [PLVFdUtil showAlertWithTitle:@"确认退出直播间？" message:nil viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:@"按错了" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:@"退出" confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(plvLCMediaAreaViewWannaBack:)]) {
                [weakSelf.delegate plvLCMediaAreaViewWannaBack:weakSelf];
            }
        }];
    }
}

- (void)plvLCBasePlayerSkinViewSynchOtherView:(PLVLCBasePlayerSkinView *)skinView{
    //更新MoreView视图的Superview，执行此代理时意味着skinView对象为当前显示的皮肤
    [self.moreView updateMoreViewOnSuperview:skinView.superview];
}

- (void)plvLCBasePlayerSkinViewMoreButtonClicked:(PLVLCBasePlayerSkinView *)skinView{
    [self.moreView showMoreViewOnSuperview:skinView.superview];
}

- (void)plvLCBasePlayerSkinViewPlayButtonClicked:(PLVLCBasePlayerSkinView *)skinView wannaPlay:(BOOL)wannaPlay{
    if (self.noDelayLiveWatching) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaView:noDelayLiveWannaPlay:)]) {
            [self.delegate plvLCMediaAreaView:self noDelayLiveWannaPlay:wannaPlay];
        }
    } else {
        if (wannaPlay) {
            [self.playerPresenter resumePlay];
        }else{
            [self.playerPresenter pausePlay];
        }
    }
}

- (void)plvLCBasePlayerSkinViewRefreshButtonClicked:(PLVLCBasePlayerSkinView *)skinView{
    [self.playerPresenter resumePlay];
}

- (void)plvLCBasePlayerSkinViewFloatViewShowButtonClicked:(PLVLCBasePlayerSkinView *)skinView userWannaShowFloatView:(BOOL)wannaShow{
    if (!self.inRTCRoom) {
        [self.floatView showFloatView:wannaShow userOperat:YES];
    }else{
        if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:userWannaLinkMicAreaViewShow:onSkinView:)]) {
            [self.delegate plvLCMediaAreaView:self userWannaLinkMicAreaViewShow:wannaShow onSkinView:skinView];
        }
    }
}

- (void)plvLCBasePlayerSkinViewFullScreenOpenButtonClicked:(PLVLCBasePlayerSkinView *)skinView{
    [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
}

/// 询问是否有其他视图处理此次触摸事件
- (BOOL)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView askHandlerForTouchPointOnSkinView:(CGPoint)point{
    if ([PLVLCBasePlayerSkinView checkView:self.canvasView.playCanvasButton canBeHandlerForTouchPoint:point onSkinView:skinView]){
        /// 判断触摸事件是否应由 ‘音频模式按钮’ 处理
        return YES;
    }else if ([PLVLCBasePlayerSkinView checkView:self.playerPresenter.warmUpImageView canBeHandlerForTouchPoint:point onSkinView:skinView]){
        return YES;
    }else if ([PLVLCBasePlayerSkinView checkView:self.networkQualityPoorView canBeHandlerForTouchPoint:point onSkinView:skinView]){
        return YES;
    }else{
        BOOL externalViewHandle = NO;
        /// 询问外部视图
        if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:askHandlerForTouchPoint:onSkinView:)]) {
            externalViewHandle = [self.delegate plvLCMediaAreaView:self askHandlerForTouchPoint:point onSkinView:skinView];
        }
        return externalViewHandle;
    }
}

- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView didChangedSkinShowStatus:(BOOL)skinShow{
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:didChangedSkinShowStatus:forSkinView:)]) {
        [self.delegate plvLCMediaAreaView:self didChangedSkinShowStatus:skinShow forSkinView:skinView];
    }
}

- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView sliderDragEnd:(CGFloat)currentSliderProgress{
    NSTimeInterval currentTime = self.playerPresenter.duration * currentSliderProgress;
    
    // 拖动进度条后，同步当前进度时间
    [self playerPresenter:self.playerPresenter downloadProgress:0 playedProgress:currentSliderProgress playedTimeString:[PLVFdUtil secondsToString:currentTime] durationTimeString:[PLVFdUtil secondsToString:self.playerPresenter.duration]];
    [self.playerPresenter seekLivePlaybackToTime:currentTime];
}

- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView didChangePageWithType:(PLVChangePPTPageType)type {
    [self.pptView changePPTPageWithType:type];
}

- (BOOL)plvLCBasePlayerSkinViewShouldShowDocumentToolView:(PLVLCBasePlayerSkinView *)skinView {
    return self.pptOnMainSite; // ppt在主屏时可显示翻页工具
}

#pragma mark PLVLCFloatViewDelegate
/// 悬浮视图被点击
- (UIView *)plvLCFloatViewDidTap:(PLVLCMediaFloatView *)floatView externalView:(nonnull UIView *)externalView{
    UIView * willMoveView = self.contentBackgroudView.subviews.firstObject;
    if (externalView) {
        [self.contentBackgroudView addSubview:externalView];
        externalView.frame = self.contentBackgroudView.bounds;
        externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // 设置PPT是否在主页
        [self setupMainSpeakerPPTOnMain:[self isPptView:externalView]];
    }
    return willMoveView;
}

- (void)plvLCFloatViewCloseButtonClicked:(PLVLCMediaFloatView *)floatView{
    [self.skinView showFloatViewShowButtonTipsLabelAnimation:YES];
}

- (void)plvLCFloatView:(PLVLCMediaFloatView *)floatView floatViewSwitchToShow:(BOOL)show{
    [self.skinView setFloatViewButtonWithShowStatus:show];
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:floatViewSwitchToShow:)]) {
        [self.delegate plvLCMediaAreaView:self floatViewSwitchToShow:show];
    }
}

#pragma mark PLVLCMediaMoreViewDelegate
- (void)plvLCMediaMoreView:(PLVLCMediaMoreView *)moreView optionItemSelected:(PLVLCMediaMoreModel *)model{
    if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_ModeOptionTitle]) {
        // 用户点选了”模式“中的选项
        [self switchLiveToAudioMode:model.selectedIndex == 1];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_QualityOptionTitle]) {
        // 用户点选了”视频质量“中的选项
        [self.playerPresenter switchLiveToCodeRate:model.currentSelectedItemString];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_RouteOptionTitle]) {
        // 用户点选了”线路“中的选项
        [self.playerPresenter switchLiveToLineIndex:model.selectedIndex];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_SpeedOptionTitle]) {
        // 用户点选了”倍速“中的选项
        CGFloat speed = [[model.currentSelectedItemString substringToIndex:model.currentSelectedItemString.length - 1] floatValue];
        [self.playerPresenter switchLivePlaybackSpeedRate:speed];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_LiveDelayOptionTitle]) {
        // 用户点选了“延迟”中的选项
        [self switchToNoDelayWatchMode:model.selectedIndex == 0];
    }
}

#pragma mark PLVLCMediaPlayerCanvasViewDelegate
/// ‘播放画面’按钮被点击
- (void)plvLCMediaPlayerCanvasViewPlayCanvasButtonClicked:(PLVLCMediaPlayerCanvasView *)playerCanvasView{
    // 更新数据
    PLVLCMediaMoreModel * modeModel = [self.moreView getMoreModelAtIndex:0];
    modeModel.selectedIndex = 0;
    [self.moreView refreshTableView];
    
    // 切换为视频模式
    [self.playerPresenter switchLiveToAudioMode:NO];
}

#pragma mark PLVDocumentViewDelegate
- (void)documentView_pageStatusChangeWithAutoId:(NSUInteger)autoId pageNumber:(NSUInteger)pageNumber totalPage:(NSUInteger)totalPage pptStep:(NSUInteger)step maxNextNumber:(NSUInteger)maxNextNumber {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCMediaAreaView:pageStatusChangeWithAutoId:pageNumber:totalPage:pptStep:maxNextNumber:)]) {
        [self.delegate plvLCMediaAreaView:self pageStatusChangeWithAutoId:autoId pageNumber:pageNumber totalPage:totalPage pptStep:step maxNextNumber:maxNextNumber];
    }
    [self.skinView.documentToolView setupPageNumber:pageNumber totalPage:totalPage maxNextNumber:maxNextNumber];
    
}

#pragma mark PLVStreamerPPTView Delegate
/// PPT获取刷新的延迟时间
- (unsigned int)documentView_getRefreshDelayTime {
    return self.inRTCRoom ? 0 : self.quickLiveWatching ? 500 : 5000;
}

/// PPT视图 PPT位置需切换
- (void)documentView_changePPTPositionToMain:(BOOL)pptToMain {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.videoType == PLVChannelVideoType_Live){ // 视频类型为 直播
            /// 仅在 非观看RTC场景下 执行 (观看RTC场景下，由 PLVLCLinkMicAreaView 自行处理)
            if (self.inRTCRoom == NO &&
                self.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_WatchNoDelay &&
                self.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_InLinkMic) {
                if (pptToMain != self.pptOnMainSite) {
                    [self.floatView triggerViewExchangeEvent];
                }
                [self setupMainSpeakerPPTOnMain:pptToMain];
            }
        } else if (self.videoType == PLVChannelVideoType_Playback) { // 视频类型为 直播回放
            if (pptToMain != self.pptOnMainSite) {
                [self.floatView triggerViewExchangeEvent];
            }
        }
    });
}

/// [回放场景] PPT视图 需要获取视频播放器的当前播放时间点
- (NSTimeInterval)documentView_getPlayerCurrentTime {
    return self.playerPresenter.currentPlaybackTime * 1000;
}

#pragma mark PLVPlayerPresenterDelegate
// 通用
/// 播放器 ‘正在播放状态’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter playerPlayingStateDidChanged:(BOOL)playing{
    [self.skinView setPlayButtonWithPlaying:playing];
    if (playing) {
        [self.marqueeView start];
    }else {
        [self.marqueeView pause];
    }
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:playerPlayingDidChange:)]) {
        [self.delegate plvLCMediaAreaView:self playerPlayingDidChange:playing];
    }
}

/// 播放器 发生错误
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter loadPlayerFailureWithMessage:(NSString *)errorMessage{
    [PLVLCUtils showHUDWithTitle:@"" detail:errorMessage view:[PLVFdUtil getCurrentViewController].view];
}

/// 播放器 ‘视频大小’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter videoSizeChange:(CGSize)videoSize{
    self.canvasView.videoSize = videoSize;
}

/// 播放器 ‘SEI信息’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter seiDidChange:(long)timeStamp newTimeStamp:(long)newTimeStamp{
    [self.pptView setSEIDataWithNewTimestamp:newTimeStamp];
}

/// 播放器 ‘频道信息’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo{
    /// 设置 跑马灯
    PLVRoomData *roomData = self.roomData;
    [self setupMarquee:roomData.channelInfo customNick:roomData.roomUser.viewerName];
    if (self.videoType == PLVChannelVideoType_Playback) {
        [self setupWatermark];
        [self setupPlayerLogoImage];
    }
}

// 直播相关
/// 直播 ‘流状态’ 更新
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged{
    /// 根据直播流状态，刷新 ‘画布视图’
    [self.canvasView refreshCanvasViewWithStreamState:newestStreamState];
    
    if (newestStreamState == PLVChannelLiveStreamState_Live) {
        if (!self.noDelayLiveWatching && self.inLinkMic == NO) {
            [self.floatView showFloatView:YES userOperat:NO];
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
            
            /// 确保 直播状态变更为‘直播中’时，PPT 位于主屏
            if (streamStateDidChanged && (self.mainSpeakerPPTOnMain != self.pptOnMainSite)) {
                [self.floatView triggerViewExchangeEvent];
            }
        }
        
        /// 开启跑马灯
        [self.marqueeView start];
        
        /// 设置播放器logo
        [self setupPlayerLogoImage];
        /// 设置防录屏水印
        [self setupWatermark];
        
        if (self.isOnlyAudio) {
            [self.canvasView setSplashImageWithURLString:self.roomData.menuInfo.splashImg];
            [self.playerPresenter switchLiveToAudioMode:YES];
        }
    }else if (newestStreamState == PLVChannelLiveStreamState_Stop ||
              newestStreamState == PLVChannelLiveStreamState_End){
        /// 确保 直播状态变更为‘直播暂停’、‘直播结束’时，播放器画面 位于主屏
        if (self.pptOnMainSite) {
            [self.floatView triggerViewExchangeEvent];
        }
        [self.logoView removeFromSuperview];
        [self.watermarkView removeFromSuperview];
        [self.floatView forceShowFloatView:NO];
        [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        
        /// 停止跑马灯
        [self.marqueeView stop];
        [self.canvasView hideSplashImageView];
        /// 切换到视频模式
        if (self.playerPresenter.audioMode) {
            [self switchLiveToAudioMode:NO];
        }
    } else if(newestStreamState == PLVChannelLiveStreamState_Unknown){
        /// ’未知‘状态下，保持原样
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaView:livePlayerStateDidChange:)]) {
        [self.delegate plvLCMediaAreaView:self livePlayerStateDidChange:newestStreamState];
    }
}

/// 直播播放器 ‘码率可选项、当前码率、线路可选数、当前线路‘ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter codeRateOptions:(NSArray <NSString *> *)codeRateOptions currentCodeRate:(NSString *)currentCodeRate lineNum:(NSInteger)lineNum currentLineIndex:(NSInteger)currentLineIndex{
    // 更新 ‘更多视图’
    [self updateMoreviewWithData];
}

/// 直播播放器 需获知外部 ‘当前是否正在连麦’
- (BOOL)playerPresenterGetInLinkMic:(PLVPlayerPresenter *)playerPresenter{
    return self.inLinkMic;
}

/// 直播播放器 需获知外部 ‘当前是否已暂停无延迟观看’
- (BOOL)playerPresenterGetPausedWatchNoDelay:(PLVPlayerPresenter *)playerPresenter{
    return self.pausedWatchNoDelay;
}

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter noDelayLiveStartUpdate:(BOOL)noDelayLiveStart noDelayLiveStartDidChanged:(BOOL)noDelayLiveStartDidChanged{
    [self.skinView setPlayButtonWithPlaying:noDelayLiveStart];
    if (noDelayLiveStartDidChanged) {
        if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:noDelayLiveStartUpdate:)]) {
            [self.delegate plvLCMediaAreaView:self noDelayLiveStartUpdate:noDelayLiveStart];
        }
    }
}

/// [快直播] 快直播 网络质量检测
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter quickLiveNetworkQuality:(PLVLivePlayerQuickLiveNetworkQuality)netWorkQuality {
    if (netWorkQuality == PLVLivePlayerQuickLiveNetworkQuality_Poor) {
        [self showNetworkQualityPoorView];
    } else if (netWorkQuality == PLVLivePlayerQuickLiveNetworkQuality_Middle) {
        [self showNetworkQualityMiddleView];
    }
}

// 非直播相关
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString{
    [self.skinView setProgressWithCachedProgress:downloadProgress playedProgress:playedProgress durationTime:playerPresenter.duration currentTimeString:playedTimeString durationString:durationTimeString];
    
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:progressUpdateWithCachedProgress:playedProgress:durationTime:currentTimeString:durationString:)]) {
        [self.delegate plvLCMediaAreaView:self progressUpdateWithCachedProgress:downloadProgress playedProgress:playedProgress durationTime:playerPresenter.duration currentTimeString:playedTimeString durationString:durationTimeString];
    }
}

// 回放视频播放中断
- (void)playerPresenterPlaybackInterrupted:(PLVPlayerPresenter *)playerPresenter {
    self.retryPlayView.hidden = NO;
}

#pragma mark PLVLCRetryPlayViewDelegate
/// 重试按钮被点击
- (void)plvLCRetryPlayViewReplayButtonClicked {
    self.retryPlayView.hidden = YES;
    [self.playerPresenter resumePlay];
}

#pragma mark PLVRoomDataManagerProtocol
- (void)roomDataManager_didVidChanged:(NSString *)vid {
    NSString *videoId = [PLVRoomDataManager sharedManager].roomData.videoId;
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    [self.playerPresenter changeVid:vid];
    [self.pptView pptStartWithVideoId:videoId channelId:channelId];
}

#pragma mark - [ Action ]
- (void)swithDelayLiveClick:(UIButton *)button {
    [self switchToNoDelayWatchMode:NO];
    self.networkQualityPoorView.hidden = YES;
}

- (void)closeNetworkTipsViewClick:(UIButton *)button {
    self.networkQualityPoorView.hidden = YES;
}

@end