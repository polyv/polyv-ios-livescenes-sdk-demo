//
//  PLVECLinkMicAreaView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVLinkMicPresenter.h"
#import "PLVECLinkMicPreviewView.h"
#import "PLVECLinkMicControlBarProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVECLinkMicAreaView;

@protocol PLVECLinkMicAreaViewDelegate <NSObject>

/// 无延迟直播观看下 本地网络质量检测回调
///
/// @note 此回调不保证在主线程触发
///
/// @param linkMicAreaView 连麦区域视图
/// @param rxQuality 当前下行网络质量
- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality;

/// ‘是否在RTC房间中’ 状态值发生改变
///
/// @param linkMicAreaView 连麦区域视图
/// @param inRTCRoom 当前 是否在RTC房间中
- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView inRTCRoomChanged:(BOOL)inRTCRoom;

/// ‘是否正在连麦’ 状态值改变
///
/// @param linkMicAreaView 连麦区域视图
/// @param inLinkMic 当前是否正在连麦 (YES:正在连麦中 NO:不在连麦中)
- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView inLinkMicChanged:(BOOL)inLinkMic;

/// ‘连麦状态’ 状态值改变
/// @param linkMicAreaView 连麦区域视图
/// @param currentLinkMicStatus 当前连麦状态
- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView currentLinkMicStatus:(PLVLinkMicStatus)currentLinkMicStatus;

/// 需获知 ‘当前频道是否直播中’
///
/// @note 此回调不保证在主线程触发
///
/// @param linkMicAreaView 连麦区域视图
- (BOOL)plvECLinkMicAreaViewGetChannelInLive:(PLVECLinkMicAreaView *)linkMicAreaView;

@end

/// 连麦区域视图
///
/// @note 负责处理无延迟观看的视图业务逻辑
/// 命名为LinkMic，但暂时不支持连麦功能，统一逻辑，为后续“支持连麦”做铺垫
/// 虽然叫AreaView，但暂时不需承担UI功能
@interface PLVECLinkMicAreaView : UIView

#pragma mark - [ 属性 ]

#pragma mark 可配置项

/// PLVECLinkMicAreaViewDelegate代理
@property (nonatomic, weak) id<PLVECLinkMicAreaViewDelegate> delegate;

#pragma mark 状态

/// 当前 是否已暂停无延迟观看(YES:已暂停 NO:未暂停)
@property (nonatomic, assign, readonly) BOOL pausedWatchNoDelay;

/// 当前 是否在RTC房间中 (YES:在RTC房间中 NO:不在RTC房间中)
@property (nonatomic, assign, readonly) BOOL inRTCRoom;

/// 当前 是否连麦中 (YES:正在连麦中 NO:不在连麦中)
@property (nonatomic, assign, readonly) BOOL inLinkMic;

#pragma mark 对象

/// 当前连麦悬浮控制栏 (当前显示在屏幕上的 悬浮控制栏)
///
/// @note 便于外部作图层管理
@property (nonatomic, strong, readonly) id <PLVECLinkMicControlBarProtocol> currentControlBar;

#pragma mark UI

@property (nonatomic, strong, readonly) PLVECLinkMicPreviewView *linkMicPreView; // 连麦预览图

@property (nonatomic, weak, readonly) UIView *firstSiteCanvasView; // 连麦第一画面Canvas视图

#pragma mark - Method

/// 刷新连麦窗口
- (void)reloadLinkMicUserWindows;

/// 开始/结束观看无延迟直播
- (void)startWatchNoDelay:(BOOL)startWatch;

/// 暂停或取消暂停 无延迟观看
///
/// @note 调用后，将改变 [pausedWatchNoDelay] 值；
///
/// @param pause 暂停或取消暂停 (YES:暂停；NO:取消暂停)
- (void)pauseWatchNoDelay:(BOOL)pause;

@end

NS_ASSUME_NONNULL_END
