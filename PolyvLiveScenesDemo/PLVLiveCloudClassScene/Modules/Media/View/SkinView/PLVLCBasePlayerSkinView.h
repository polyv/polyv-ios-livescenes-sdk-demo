//
//  PLVLCBasePlayerSkinView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/10/8.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCMediaCountdownTimeView.h"
#import "PLVProgressSlider.h"
#import "PLVLCDocumentToolView.h"

NS_ASSUME_NONNULL_BEGIN

/// 枚举
/// 媒体播放器皮肤 场景类型
typedef NS_ENUM(NSUInteger, PLVLCBasePlayerSkinViewType) {
    /// 直播场景
    PLVLCBasePlayerSkinViewType_AloneLive = 0,     // 普通直播-直播场景
    PLVLCBasePlayerSkinViewType_PPTLive   = 1,     // 三分屏直播-直播场景
    /// 回放场景
    PLVLCBasePlayerSkinViewType_AlonePlayback = 8, // 普通直播回放
    PLVLCBasePlayerSkinViewType_PPTPlayback = 9, // 三分屏直播回放
};

/// 媒体播放器皮肤 直播状态
///
/// @note 仅在直播场景类型 PLVLCBasePlayerSkinViewType_AloneLive、PLVLCBasePlayerSkinViewType_PPTLive 中 会使用以下枚举；回放场景不涉及此枚举；
typedef NS_ENUM(NSUInteger, PLVLCBasePlayerSkinViewLiveStatus) {
    PLVLCBasePlayerSkinViewLiveStatus_None = 0,      // 无直播状态
    PLVLCBasePlayerSkinViewLiveStatus_Living_CDN = 2,    // 直播中 观看CDN 状态 (完全CDN)
    PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay = 4,    // 直播中 观看无延迟 状态 (完全RTC)
    PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PartRTC = 6, // 直播中 正在连麦 状态 (部分RTC)
    PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC = 8, // 直播中 正在连麦 状态 (完全RTC)
};

@protocol PLVLCBasePlayerSkinViewDelegate;

@interface PLVLCBasePlayerSkinView : UIView

@property (nonatomic, weak) id <PLVLCBasePlayerSkinViewDelegate> baseDelegate;

@property (nonatomic, assign, readonly) PLVLCBasePlayerSkinViewType skinViewType;

@property (nonatomic, assign) PLVLCBasePlayerSkinViewLiveStatus skinViewLiveStatus;

@property (nonatomic, assign) BOOL skinShow;

@property (nonatomic, assign) BOOL floatViewShowButtonTipsLabelHadShown;

@property (nonatomic, strong) UITapGestureRecognizer * tapGR;
@property (nonatomic, strong) UIPanGestureRecognizer * panGR;

@property (nonatomic, strong) CAGradientLayer * topShadowLayer; // 顶部阴影背景 (负责展示 阴影背景)
@property (nonatomic, strong) UIButton * backButton;
@property (nonatomic, strong) UILabel * titleLabel;
@property (nonatomic, strong) UILabel * playTimesLabel; // 仅直播
@property (nonatomic, strong) UIButton * pictureInPictureButton;
@property (nonatomic, strong) UIButton * moreButton;
@property (nonatomic, strong) PLVLCMediaCountdownTimeView * countdownTimeView; // 仅直播

@property (nonatomic, strong) CAGradientLayer * bottomShadowLayer; // 底部阴影背景 (负责展示 阴影背景)
@property (nonatomic, strong) UIButton * playButton;
@property (nonatomic, strong) UIButton * refreshButton; // 仅直播
@property (nonatomic, strong) UILabel * floatViewShowButtonTipsLabel;
@property (nonatomic, strong) UIButton * floatViewShowButton;
@property (nonatomic, strong) UIButton * fullScreenButton;
@property (nonatomic, strong) UILabel * currentTimeLabel; // 仅直播回放
@property (nonatomic, strong) UILabel * diagonalsLabel;   // 仅直播回放；斜杆符号文本框
@property (nonatomic, strong) UILabel * durationLabel;    // 仅直播回放
@property (nonatomic, strong) PLVProgressSlider * progressSlider; // 仅直播回放
@property (nonatomic, strong) PLVLCDocumentToolView *documentToolView; // 文档工具视图

- (CGFloat)getLabelTextWidth:(UILabel *)label;

- (void)switchSkinViewLiveStatusTo:(PLVLCBasePlayerSkinViewLiveStatus)skinViewLiveStatus;

- (void)setTitleLabelWithText:(NSString *)titleText;

- (void)setPlayTimesLabelWithTimes:(NSInteger)times;

- (void)setFloatViewButtonWithShowStatus:(BOOL)showFloatView;

/// 可提供给子类重写
- (void)showFloatViewShowButtonTipsLabelAnimation:(BOOL)showTips;

- (void)setPlayButtonWithPlaying:(BOOL)playing;

- (void)setCountdownTime:(NSTimeInterval)time;

/// 用于同步 ’用户点击而改变‘ 的按钮状态
- (void)synchOtherSkinViewState:(PLVLCBasePlayerSkinView *)otherSkinView;

/// 直播回放方法
- (void)setProgressWithCachedProgress:(CGFloat)cachedProgress playedProgress:(CGFloat)playedProgress durationTime:(NSTimeInterval)durationTime currentTimeString:(NSString *)currentTimeString durationString:(NSString *)durationString;

/// 可提供给子类重写
- (void)controlsSwitchShowStatusWithAnimation:(BOOL)showStatus;

- (void)setupUI;

- (void)refreshPlayTimesLabelFrame;

/// 刷新画中画按钮是否显示
/// @param show YES:显示，NO:隐藏
- (void)refreshPictureInPictureButtonShow:(BOOL)show;

/// 刷新更多按钮显示
/// @param hidden YES:隐藏，NO:恢复原来状态
- (void)refreshMoreButtonHiddenOrRestore:(BOOL)hidden;

/// 工具方法 (与 PLVLCBasePlayerSkinView 类本身没有逻辑关联，仅业务上相关)
+ (BOOL)checkView:(UIView *)otherView canBeHandlerForTouchPoint:(CGPoint)point onSkinView:(nonnull PLVLCBasePlayerSkinView *)skinView;

/// 设置PPT是否在主页
/// @param mainSpeakerPPTOnMain ppt是否在主讲页
- (void)setupMainSpeakerPPTOnMain:(BOOL)mainSpeakerPPTOnMain;

@end

@protocol PLVLCBasePlayerSkinViewDelegate <NSObject>

- (void)plvLCBasePlayerSkinViewBackButtonClicked:(PLVLCBasePlayerSkinView *)skinView currentFullScreen:(BOOL)currentFullScreen;

- (void)plvLCBasePlayerSkinViewPictureInPictureButtonClicked:(PLVLCBasePlayerSkinView *)skinView;

- (void)plvLCBasePlayerSkinViewMoreButtonClicked:(PLVLCBasePlayerSkinView *)skinView;

- (void)plvLCBasePlayerSkinViewPlayButtonClicked:(PLVLCBasePlayerSkinView *)skinView wannaPlay:(BOOL)wannaPlay;

- (void)plvLCBasePlayerSkinViewRefreshButtonClicked:(PLVLCBasePlayerSkinView *)skinView;

- (void)plvLCBasePlayerSkinViewFloatViewShowButtonClicked:(PLVLCBasePlayerSkinView *)skinView userWannaShowFloatView:(BOOL)wannaShow;

- (void)plvLCBasePlayerSkinViewFullScreenOpenButtonClicked:(PLVLCBasePlayerSkinView *)skinView;

/// ‘当前皮肤视图’ 已同步 ‘其他皮肤视图’按钮状态的回调
///
/// @note 当调用 [synchOtherSkinViewState:] 方法成功时，将触发此回调方法；
///
/// @param skinView 当前 媒体播放器皮肤视图 对象本身 (注意：该参数非 [synchOtherSkinViewState:] 中的otherSkinView)
- (void)plvLCBasePlayerSkinViewSynchOtherView:(PLVLCBasePlayerSkinView *)skinView;

/// 询问是否有其他视图处理此次触摸事件
///
/// @param skinView 媒体播放器皮肤视图
/// @param point 此次触摸事件的 CGPoint (相对于皮肤视图skinView)
///
/// @return BOOL 是否有其他视图处理 (YES:有，则skinView不再处理此触摸事件 NO:没有，则由skinView处理此触摸事件)
- (BOOL)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView askHandlerForTouchPointOnSkinView:(CGPoint)point;


- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView didChangedSkinShowStatus:(BOOL)skinShow;

- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView sliderDragEnd:(CGFloat)currentSliderProgress;

/// 点击 翻页操作 时调用
/// @param skinView 媒体播放器皮肤视图
/// @param type 翻页类型
- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView didChangePageWithType:(PLVChangePPTPageType)type;

/// 询问是否需要显示 翻页工具视图
- (BOOL)plvLCBasePlayerSkinViewShouldShowDocumentToolView:(PLVLCBasePlayerSkinView *)skinView;

/// 询问是否需要展示 画中画开启按钮
- (BOOL)plvLCBasePlayerSkinViewShouldShowPictureInPictureButton:(PLVLCBasePlayerSkinView *)skinView;

@end

NS_ASSUME_NONNULL_END
