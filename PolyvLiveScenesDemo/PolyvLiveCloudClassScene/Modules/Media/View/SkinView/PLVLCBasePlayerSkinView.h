//
//  PLVLCBasePlayerSkinView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/10/8.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCMediaCountdownTimeView.h"
#import "PLVProgressSlider.h"

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

/// 工具方法 (与 PLVLCBasePlayerSkinView 类本身没有逻辑关联，仅业务上相关)
+ (BOOL)checkView:(UIView *)otherView canBeHandlerForTouchPoint:(CGPoint)point onSkinView:(nonnull PLVLCBasePlayerSkinView *)skinView;

@end

@protocol PLVLCBasePlayerSkinViewDelegate <NSObject>

- (void)plvLCBasePlayerSkinViewBackButtonClicked:(PLVLCBasePlayerSkinView *)skinView currentFullScreen:(BOOL)currentFullScreen;

- (void)plvLCBasePlayerSkinViewMoreButtonClicked:(PLVLCBasePlayerSkinView *)skinView;

- (void)plvLCBasePlayerSkinViewPlayButtonClicked:(PLVLCBasePlayerSkinView *)skinView wannaPlay:(BOOL)wannaPlay;

- (void)plvLCBasePlayerSkinViewRefreshButtonClicked:(PLVLCBasePlayerSkinView *)skinView;

- (void)plvLCBasePlayerSkinViewFloatViewShowButtonClicked:(PLVLCBasePlayerSkinView *)skinView userWannaShowFloatView:(BOOL)wannaShow;

- (void)plvLCBasePlayerSkinViewFullScreenOpenButtonClicked:(PLVLCBasePlayerSkinView *)skinView;

/// 询问是否有其他视图处理此次触摸事件
///
/// @param skinView 媒体播放器皮肤视图
/// @param point 此次触摸事件的 CGPoint (相对于皮肤视图skinView)
///
/// @return BOOL 是否有其他视图处理 (YES:有，则skinView不再处理此触摸事件 NO:没有，则由skinView处理此触摸事件)
- (BOOL)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView askHandlerForTouchPointOnSkinView:(CGPoint)point;


- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView didChangedSkinShowStatus:(BOOL)skinShow;

- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView sliderDragEnd:(CGFloat)currentSliderProgress;

@end

NS_ASSUME_NONNULL_END
