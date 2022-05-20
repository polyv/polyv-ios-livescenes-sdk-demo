//
//  PLVLCLinkMicAreaView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCLinkMicPortraitControlBar.h"
#import "PLVLCLinkMicLandscapeControlBar.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVLinkMicPresenter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCLinkMicAreaViewDelegate;

/// 连麦区域视图
///
/// @note 连麦相关的UI、逻辑都在此类中实现；
///       负责管理 [UI]连麦悬浮控制栏、[UI]连麦窗口列表视图、[Presenter]连麦管理器
@interface PLVLCLinkMicAreaView : UIView

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id <PLVLCLinkMicAreaViewDelegate> delegate;

#pragma mark 状态
/// 当前 是否在RTC房间中 (YES:在RTC房间中 NO:不在RTC房间中)
@property (nonatomic, assign, readonly) BOOL inRTCRoom;

/// 当前 频道连麦场景类型
@property (nonatomic, assign, readonly) PLVChannelLinkMicSceneType linkMicSceneType;

/// 当前 是否连麦中 (YES:正在连麦中 NO:不在连麦中)
@property (nonatomic, assign, readonly) BOOL inLinkMic;

/// 当前 是否已暂停无延迟观看(YES:已暂停 NO:未暂停)
@property (nonatomic, assign, readonly) BOOL pausedWatchNoDelay;

/// 当前 是否显示连麦区域视图
///
/// @note 代表的是 ”用户的主观意愿 是否希望连麦区域视图显示“；
///       当 [inRTCRoom] 发生改变时，此值会自动与 [inRTCRoom] 同步值；其他情况下，以用户意愿为主；
@property (nonatomic, assign, readonly) BOOL areaViewShow;

#pragma mark 数据
/// 当前 RTC房间在线用户数
@property (nonatomic, assign, readonly) NSInteger currentRTCRoomUserCount;

#pragma mark 对象
/// 当前连麦悬浮控制栏 (当前显示在屏幕上的 悬浮控制栏)
///
/// @note 便于外部作图层管理
@property (nonatomic, strong, readonly) id <PLVLCLinkMicControlBarProtocol> currentControlBar;

@property (nonatomic, strong, readonly) UIImageView * logoImageView; // 播放器LOGO图片


#pragma mark - [ 方法 ]
/// 连麦区域视图 切换至 ”显示/隐藏“ 状态
///
/// @note 此方法仅控制透明度，不关心布局；代表的是 ”用户的主观意愿 是否希望连麦区域视图显示“；
///       此方法将改变 [areaViewShow] 值；
///       [inRTCRoom] 为 NO 时，此方法调用无效；
- (void)showAreaView:(BOOL)showStatus;

- (void)showLinkMicControlBar:(BOOL)showStatus;

/// 开始/结束观看无延迟直播
- (void)startWatchNoDelay:(BOOL)startWatch;

/// 暂停/播放无延迟直播
- (void)pauseWatchNoDelay:(BOOL)pause;

/// 画中画占位视图的隐藏/显示
/// @param show 隐藏或显示 (YES:显示 NO:隐藏)
- (void)setPictureInPicturePlaceholderShow:(BOOL)show;

/// 退出连麦(仅发送'退出连麦消息')
///
/// @note 此方法用于将当前 等待连麦 、正在加入连麦 或 连麦中的用户退出连麦
///       仅发送退出连麦的soket消息，不关心是否真正退出RTC房间
///       适用场景：当前确认 PLVLCLinkMicAreaView 或 内部的PLVLinkMicPresenter 将很快销毁，仅希望发送 ‘退出连麦’ 的请求消息，来更新本地用户在服务器中的状态
- (void)leaveLinkMicOnlyEmit;

@end

/// 连麦区域视图Delegate
@protocol PLVLCLinkMicAreaViewDelegate <NSObject>

/// RTC画面窗口 需外部展示 ‘第一画面连麦窗口’
///
/// @param linkMicAreaView 连麦区域视图
/// @param canvasView 第一画面连麦窗口视图 (需外部进行添加展示)
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView showFirstSiteCanvasViewOnExternal:(UIView *)canvasView;

/// RTC画面窗口被点击 (表示用户希望视图位置交换)
///
/// @note 当接收到此回调时，表示用户希望 某个Rtc画布视图(即canvasView) 在外部位置中显示，可对 canvasView 作相应布局处理
///
/// @param linkMicAreaView 连麦区域视图
/// @param canvasView Rtc画布视图
- (UIView *)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView rtcWindowDidClickedCanvasView:(UIView *)canvasView;

/// 恢复外部视图位置
///
/// @note 当外部视图需要回归原位时，此回调将被触发；接收到此回调后，可将 externalView 重新布局在原位上
///
/// @param linkMicAreaView 连麦区域视图
/// @param externalView 被添加在连麦区域视图上的外部视图
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView rollbackExternalView:(UIView *)externalView;

/// ‘是否在RTC房间中’ 状态值发生改变
///
/// @param linkMicAreaView 连麦区域视图
/// @param inRTCRoom 当前 是否在RTC房间中
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView inRTCRoomChanged:(BOOL)inRTCRoom;

/// ‘RTC房间在线用户数’ 发生改变
///
/// @param linkMicAreaView 连麦区域视图
/// @param currentRTCRoomUserCount 当前 RTC房间在线用户数
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView currentRTCRoomUserCountChanged:(NSInteger)currentRTCRoomUserCount;

/// ‘是否正在连麦’ 状态值改变
///
/// @param linkMicAreaView 连麦区域视图
/// @param inLinkMic 当前是否正在连麦 (YES:正在连麦中 NO:不在连麦中)
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView inLinkMicChanged:(BOOL)inLinkMic;

/// ‘连麦状态’ 状态值改变
/// @param linkMicAreaView 连麦区域视图
/// @param currentLinkMicStatus 当前连麦状态
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView currentLinkMicStatus:(PLVLinkMicStatus)currentLinkMicStatus;

/// 需获知 ‘当前频道是否直播中’
///
/// @note 此回调不保证在主线程触发
///
/// @param linkMicAreaView 连麦区域视图
- (BOOL)plvLCLinkMicAreaViewGetChannelInLive:(PLVLCLinkMicAreaView *)linkMicAreaView;

/// 需获知 ‘主讲的PPT 当前是否在主屏’
///
/// @note 此回调不保证在主线程触发
///
/// @param linkMicAreaView 连麦区域视图
- (BOOL)plvLCLinkMicAreaViewGetMainSpeakerPPTOnMain:(PLVLCLinkMicAreaView *)linkMicAreaView;


/// 无延迟直播观看下 本地网络质量检测回调
///
/// @note 此回调不保证在主线程触发
///
/// @param linkMicAreaView 连麦区域视图
/// @param rxQuality 当前下行网络质量
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality;

@end

NS_ASSUME_NONNULL_END
