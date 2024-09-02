//
//  PLVLCMediaAreaView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/15.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCMediaPlayerSkinView.h"
#import "PLVLCMediaFloatView.h"
#import "PLVLCRetryPlayView.h"
#import "PLVLiveMarqueeView.h"
#import "PLVLCDocumentPaintModeView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

#define PPTPlayerViewScale (9.0 / 16.0)
#define NormalPlayerViewScale (9.0 / 16.0)

NS_ASSUME_NONNULL_BEGIN

/// 媒体区域 直播场景类型
///
/// @note 观看直播的过程中，也存在“拥有不同交互的多种直播观看场景”；
///       该枚举，则用于划分各种直播观看场景；
///       该枚举与 ‘直播状态’ 没有直接的关系；
///       因为不由 ‘直播流的变化’ 来触发，而是由 ‘业务交互’ 触发；
typedef NS_ENUM(NSUInteger, PLVLCMediaAreaViewLiveSceneType) {
    PLVLCMediaAreaViewLiveSceneType_WatchCDN = 0,     /// 正在观看 ‘CDN’ 场景（包含 直播中、直播结束）
    PLVLCMediaAreaViewLiveSceneType_WatchNoDelay = 2, /// 正在观看 ‘无延迟’ 场景
    PLVLCMediaAreaViewLiveSceneType_InLinkMic = 4,    /// 正在进行 ‘连麦’ 场景
};

@protocol PLVLCMediaAreaViewDelegate;

/// 媒体区域视图
///
/// @note 播放相关的UI、逻辑都在此类中实现；
///       负责管理 [UI]媒体播放器皮肤视图、[UI]媒体悬浮视图、[UI]媒体更多视图、[Presenter]播放器管理器
@interface PLVLCMediaAreaView : UIView <PLVLCBasePlayerSkinViewDelegate>

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id <PLVLCMediaAreaViewDelegate> delegate;

/// 是否限制 内容画面 在安全区域内
///
/// @note YES:内容画面 仅在安全区域内显示，低于iOS 11时需搭配配置 [CGFloat topPaddingBelowiOS11] 属性
///       NO:内容画面 不考虑安全区域
///       具体来说，“内容画面” 指私有的 contentBackgroudView
@property (nonatomic, assign) BOOL limitContentViewInSafeArea;

/// 顶部安全距离
///
/// @note 仅在 [limitContentViewInSafeArea] 为YES 且 系统是iOS 11以下时，此值会使用；
///       说明：当低于 iOS 11 时，无法判断顶部有无状态栏遮挡 (即开发者是否将 AreaView 置于状态栏下方)。
///       此时开发者需根据对 AreaView 的布局，告知顶部安全距离 (若无状态栏遮挡，则此值应该为0)；
@property (nonatomic, assign) CGFloat topPaddingBelowiOS11;

/// 是否在iPad上显示全屏按钮
///
/// @note NO-在iPad上竖屏时不显示全屏按钮，YES-显示
///       当项目未适配分屏时，建议设置为YES
@property (nonatomic,assign) BOOL fullScreenButtonShowOnIpad;

/// 双师模式时允许切换PPT
@property (nonatomic, assign) BOOL allowChangePPT;

#pragma mark 状态
/// 当前播放时间
@property (nonatomic, assign, readonly) NSTimeInterval currentPlayTime;

/// 当前播放器类型
///
/// @note 可通过 [switchAreaViewLiveSceneTypeTo:] 方法进行切换；仅适用在视频类型为 ‘直播’ 时使用此类型值
@property (nonatomic, assign, readonly) PLVLCMediaAreaViewLiveSceneType currentLiveSceneType;

/// 该频道是否 ‘直播中’ (以 ‘直播流状态’ 作为依据)
@property (nonatomic, assign, readonly) BOOL channelInLive;

/// 是否正在播放广告
@property (nonatomic, assign, readonly) BOOL advertPlaying;

/// 该频道是否观看 ‘无延迟直播’
@property (nonatomic, assign, readonly) BOOL channelWatchNoDelay;

/// 该频道是否观看 ‘快直播’
@property (nonatomic, assign, readonly) BOOL channelWatchQuickLive;

/// 该频道是否观看 ‘公共流’
@property (nonatomic, assign, readonly) BOOL channelWatchPublicStream;

/// 当前是否为无延迟观看模式（包括无延迟直播和快直播）
@property (nonatomic, assign, readonly) BOOL noDelayWatchMode;

/// 播放器当前是否正在播放无延迟直播
@property (nonatomic, assign, readonly) BOOL noDelayLiveWatching;

/// 播放器当前是否正在播放快直播
@property (nonatomic, assign, readonly) BOOL quickLiveWatching;

/// 播放器当前是否正在播放公共流
@property (nonatomic, assign, readonly) BOOL publicStreamWatching;

/// 无延迟直播的当前 ‘开始结束状态’
@property (nonatomic, assign, readonly) BOOL noDelayLiveStart;

/// 直播场景中 主讲的PPT 当前是否在主屏
@property (nonatomic, assign, readonly) BOOL mainSpeakerPPTOnMain;

/// 当前是否处于画笔模式
@property (nonatomic, assign, readonly) BOOL isInPaintMode;

#pragma mark UI
/// 媒体播放器皮肤视图 (用于 竖屏时 显示)
///
/// @note 暴露给外部的“竖屏 媒体播放器皮肤视图“，便于和其他 播放器皮肤视图 作交互
@property (nonatomic, strong, readonly) PLVLCMediaPlayerSkinView * skinView;

/// 跑马灯视图
///
/// @note 便于外部作图层管理
@property (nonatomic, strong, readonly) PLVLiveMarqueeView * marqueeView;

/// 媒体悬浮视图
///
/// @note 便于外部作图层管理
@property (nonatomic, strong, readonly) PLVLCMediaFloatView * floatView;

/// 播放重试视图（用于直播回放场景，播放中断时显示提示视图）
///
/// @note 便于外部作图层管理
@property (nonatomic, strong, readonly) PLVLCRetryPlayView *retryPlayView;

/// 画笔模式视图
///
/// @note 便于外部作图层管理
@property (nonatomic, strong, readonly) PLVLCDocumentPaintModeView *paintModeView;


#pragma mark - [ 方法 ]
/// 显示或隐藏弹幕
- (void)showDanmu:(BOOL)show;

/// 显示弹幕设置
- (void)danmuSettingViewOnSuperview:(UIView *)superview;

/// 插入一条滚动弹幕
- (void)insertDanmu:(NSString *)danmu;

- (void)refreshUIInfo;

/// [直播场景] 切换直播场景类型
///
/// @note 切换后，媒体区域视图 AreaView，将更新布局至对应的效果；
///       仅适用在视频类型为 ‘直播’ 时，调用此方法；
///
/// @param toType 需要切换至的直播场景类型
- (void)switchAreaViewLiveSceneTypeTo:(PLVLCMediaAreaViewLiveSceneType)toType;

/// [连麦场景] 媒体区域展示一个内容视图
- (void)displayContentView:(UIView *)contentView;

/// [连麦场景] 在媒体区域中，获取当前的内容视图，用于与外部进行交换
///
/// @note 非连麦场景中的视图交换：指PPT与CDN播放器画面，进行视图交换；由点击 floatView 触发（全程在 AreaView 中完成）
///       连麦场景中的视图交换：指PPT与RTC播放器画面 或 两个RTC播放器画面之间，进行视图交换；由点击 RTC播放器画面 触发（在 AreaView 与 外部视图中完成）
///       因此以下该“对外方法”，仅应该在 连麦场景中 被调用。
- (UIView *)getContentViewForExchange;

///  视频跳至某个时间点
- (void)seekLivePlaybackToTime:(NSTimeInterval)time;

/// 显示网络不佳提示视图
- (void)showNetworkQualityMiddleView;

/// 显示网络糟糕提示视图
- (void)showNetworkQualityPoorView;

/// 刷新画中画按钮是否显示
/// @param show YES:显示，NO:隐藏
- (void)refreshPictureInPictureButtonShow:(BOOL)show;

/// 开始画中画播放
/// 该方法将触发 [plvLCMediaAreaViewPictureInPictureDidStart:] 回调
- (void)startPictureInPicture;

/// 结束画中画播放
- (void)stopPictureInPicture;

/// 切换暂存视频
/// @param fileId 暂存视频fileId
- (void)changeFileId:(NSString *)fileId;

/// 指定数据 进行播放器切换
///
/// @note PLVLCMediaAreaView 对象创建时，内部同时创建播放器。此时”频道号、直播回放Id"默认以 PLVRoomDataManager 中的配置为准；
///       而该方法则用于 切换 播放器的 ”频道号、直播回放Id“
///       该方法，暂时仅支持同视频类型的切换 (即:“直播”视频类型下，调用该方法，则默认仍是切至”直播“；而”视频类型videoType”在 PLVRoomDataManager 初始化期间已定下）
///
/// @param channelId 频道号Id（必传）
/// @param vodId 直播回放Id (PLVChannelVideoType_Live 时传值无效，PLVChannelVideoType_Playback 时且 recordEnable 为 YES 时传值无效；PLVChannelVideoType_Playback 时且 recordEnable 为 NO 时必传)
/// @param vodList 是否是“点播列表”视频 (PLVChannelVideoType_Live 时传值无效；PLVChannelVideoType_Playback 时且 recordEnable 为 NO 时必传)
/// @param recordFile 暂存视频模型（PLVChannelVideoType_Live 时传值无效；PLVChannelVideoType_Playback 时且 recordEnable 为 YES 时必传）
/// @param recordEnable 是否是“暂存”视频可用 (PLVChannelVideoType_Live 时传值无效；PLVChannelVideoType_Playback 时必传
- (void)changePlayertoChannelId:(NSString * _Nonnull)channelId vodId:(NSString * _Nullable)vodId vodList:(BOOL)vodList recordFile:(PLVLiveRecordFileModel * _Nullable)recordFile recordEnable:(BOOL)recordEnable;

/// 退出画笔模式
- (void)exitPaintMode;

/// 切换ppt，属性allowChangePPT为YES才能生效
- (void)changePPTWithAutoId:(NSUInteger)autoId pageNumber:(NSInteger)pageNumber;

/// 更新评论上墙视图
/// @param show 是否显示 评论上墙视图
/// @param message 消息详情
- (void)showPinMessagePopupView:(BOOL)show message:(PLVSpeakTopMessage * _Nullable)message;

@end

@protocol PLVLCMediaAreaViewDelegate <NSObject>

/// 用户希望退出当前页面
///
/// @param mediaAreaView 连麦区域视图
- (void)plvLCMediaAreaViewWannaBack:(PLVLCMediaAreaView *)mediaAreaView;

/// 媒体区域视图需要得知当前‘是否正在连麦’
///
/// @note 此回调不保证在主线程触发
///
/// @param mediaAreaView 媒体区域视图
///
/// @return BOOL 由外部告知的当前是否连麦中 (YES:正在连麦中 NO:不在连麦中)
- (BOOL)plvLCMediaAreaViewGetInLinkMic:(PLVLCMediaAreaView *)mediaAreaView;

/// 媒体区域视图需要得知当前‘是否正在连麦的过程中’ 
/// @param mediaAreaView 媒体区域视图
/// @return BOOL 由外部告知的当前是否在连麦过程中 (YES:正在连麦过程中 NO:不在连麦过程中:PLVLinkMicStatus_Open、PLVLinkMicStatus_NotOpen)
- (BOOL)plvLCMediaAreaViewGetInLinkMicProcess:(PLVLCMediaAreaView *)mediaAreaView;

/// 媒体区域视图需要得知当前‘是否暂停无延迟观看’
///
/// @note 此回调不保证在主线程触发
///
/// @param mediaAreaView 媒体区域视图
///
/// @return BOOL 由外部告知的当前是否已暂停无延迟观看 (YES:已暂停 NO:未暂停)
- (BOOL)plvLCMediaAreaViewGetPausedWatchNoDelay:(PLVLCMediaAreaView *)mediaAreaView;

/// 媒体区域视图需要得知当前‘是否在RTC房间中’
///
/// @note 此回调不保证在主线程触发
///
/// @param mediaAreaView 媒体区域视图
///
/// @return BOOL 由外部告知的当前是否在RTC房间中 (YES:在RTC房间中 NO:不在RTC房间中)
- (BOOL)plvLCMediaAreaViewGetInRTCRoom:(PLVLCMediaAreaView *)mediaAreaView;

/// 直播 ‘流状态’ 更新
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView livePlayerStateDidChange:(PLVChannelLiveStreamState)livePlayerState;

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playerPlayingDidChange:(BOOL)playing;

/// 媒体区域的 悬浮视图 出现/隐藏回调
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView floatViewSwitchToShow:(BOOL)show;

/// 媒体区域的 皮肤视图 出现/隐藏回调
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangedSkinShowStatus:(BOOL)skinShow forSkinView:(PLVLCBasePlayerSkinView *)skinView;

/// 媒体区域希望横屏皮肤显示更多视图
- (void)plvLCMediaAreaViewWannaLiveRoomSkinViewShowMoreView:(PLVLCMediaAreaView *)mediaAreaView;

/// 媒体区域视图询问是否有 外部视图 处理此次触摸事件
///
/// @note 并非任何触摸事件，都将回调此方法，因为有些触摸事件是点击 皮肤视图skinView 上的有效控件的。
///       此方法，主要是为了解决 “一些触摸事件被皮肤视图遮挡” 的场景问题。
///
/// @param mediaAreaView 媒体区域视图
/// @param point 此次触摸事件的 CGPoint (相对于皮肤视图skinView；可用于判断该触摸，是否在某个外部视图的范围内)
/// @param skinView 触摸事件所在的 skinView
///
/// @return BOOL 是否有外部视图处理 (YES:由外部视图处理 NO:外部视图不处理，交回给皮肤视图skinView)
- (BOOL)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView askHandlerForTouchPoint:(CGPoint)point onSkinView:(PLVLCBasePlayerSkinView *)skinView;

/// 用户希望连麦区域视图 隐藏/显示
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView userWannaLinkMicAreaViewShow:(BOOL)wannaShow onSkinView:(PLVLCBasePlayerSkinView *)skinView;

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView noDelayLiveStartUpdate:(BOOL)noDelayLiveStart;

/// [无延迟直播] 无延迟观看模式 发生改变
///
/// @note 仅 无延迟直播 频道会触发，快直播不会触发该回调；
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView noDelayWatchModeSwitched:(BOOL)noDelayWatchMode;

/// [无延迟直播] 无延迟直播 ‘播放或暂停’
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView noDelayLiveWannaPlay:(BOOL)wannaPlay;

///  广告‘正在播放状态’ 发生改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView advertViewPlayingDidChange:(BOOL)playing;

/// 回放场景
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView progressUpdateWithCachedProgress:(CGFloat)cachedProgress playedProgress:(CGFloat)playedProgress durationTime:(NSTimeInterval)durationTime currentTimeString:(NSString *)currentTimeString durationString:(NSString *)durationString;

/// 回放场景
/// seek成功回调
- (void)plvLCMediaAreaViewDidSeekSuccess:(PLVLCMediaAreaView *)mediaAreaView;

/// 文档、白板页码变化的回调
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView pageStatusChangeWithAutoId:(NSUInteger)autoId pageNumber:(NSUInteger)pageNumber totalPage:(NSUInteger)totalPage pptStep:(NSUInteger)step maxNextNumber:(NSUInteger)maxNextNumber;

/// 用户画笔权限变化的回调
/// @param mediaAreaView 播放器管理器
/// @param permission 是否有画笔权限
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangePaintPermission:(BOOL)permission;

/// 用户画笔模式变化的回调
/// @param mediaAreaView 播放器管理器
/// @param paintMode 是否在画笔模式（YES：进入画笔模式，NO退出画笔模式）
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangeInPaintMode:(BOOL)paintMode;

/// mainSpeakerPPTOnMain 发生改变回调
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangeMainSpeakerPPTOnMain:(BOOL)mainSpeakerPPTOnMain;

/// 播放器 ‘回放视频尺寸’ 发生改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playbackVideoSizeChange:(CGSize)videoSize;

/// 播放器 ‘回放视频信息’ 发生改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playbackVideoInfoDidUpdated:(PLVPlaybackVideoInfoModel *)videoInfo;

/// 用户想要开启小窗
- (void)plvLCMediaAreaViewWannaStartPictureInPicture:(PLVLCMediaAreaView *)mediaAreaView;

#pragma mark 画中画的回调
/// 画中画即将开始
/// @param mediaAreaView 播放器管理器
- (void)plvLCMediaAreaViewPictureInPictureWillStart:(PLVLCMediaAreaView *)mediaAreaView;

/// 画中画已经开始
/// @param mediaAreaView 播放器管理器
- (void)plvLCMediaAreaViewPictureInPictureDidStart:(PLVLCMediaAreaView *)mediaAreaView;

/// 画中画开启失败
/// @param mediaAreaView 播放器管理器
/// @param error 失败错误原因
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView pictureInPictureFailedToStartWithError:(NSError *)error;

/// 画中画即将停止
/// @param mediaAreaView 播放器管理器
- (void)plvLCMediaAreaViewPictureInPictureWillStop:(PLVLCMediaAreaView *)mediaAreaView;

/// 画中画已经停止
/// @param mediaAreaView 播放器管理器
- (void)plvLCMediaAreaViewPictureInPictureDidStop:(PLVLCMediaAreaView *)mediaAreaView;

/// 画中画播放器播放状态改变
/// @param mediaAreaView 播放器管理器
/// @param playing 是否正在播放
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView pictureInPicturePlayerPlayingStateDidChange:(BOOL)playing;

#pragma mark 下载视图的回调
- (void)plvLCMediaAreaViewClickDownloadListButton:(PLVLCMediaAreaView *)mediaAreaView;

@end

NS_ASSUME_NONNULL_END
