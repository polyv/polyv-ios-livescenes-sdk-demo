//
//  PLVLCLinkMicAreaView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLiveRoomData.h"

#import "PLVLCLinkMicVerticalControlBar.h"
#import "PLVLCLinkMicHorizontalControlBar.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCLinkMicAreaViewDelegate;

/// 连麦区域视图
///
/// @note 连麦相关的UI、逻辑都在此类中实现；
///       负责管理 [UI]连麦悬浮控制栏、[UI]连麦窗口列表视图、[Presenter]连麦管理器
@interface PLVLCLinkMicAreaView : UIView

/// delegate
@property (nonatomic, weak) id <PLVLCLinkMicAreaViewDelegate> delegate;

/// 是否正在连麦 (YES:正在连麦中 NO:不在连麦中)
@property (nonatomic, assign, readonly) BOOL inLinkMic;

/// 当前是否显示连麦区域视图
@property (nonatomic, assign, readonly) BOOL areaViewShow;

/// 当前连麦悬浮控制栏 (当前显示在屏幕上的 悬浮控制栏)
///
/// @note 便于外部作图层管理
@property (nonatomic, strong, readonly) id <PLVLCLinkMicControlBarProtocol> currentControlBar;

/// 初始化方法
- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData;

/// 此方法仅控制 AreaView 的透明度，不关心布局
- (void)showAreaView:(BOOL)showStatus;

- (void)showLinkMicControlBar:(BOOL)showStatus;

@end

/// 连麦区域视图Delegate
@protocol PLVLCLinkMicAreaViewDelegate <NSObject>

/// 连麦Rtc画面窗口被点击 (表示用户希望视图位置交换)
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

/// ‘是否正在连麦’状态值改变
///
/// @param linkMicAreaView 连麦区域视图
/// @param inLinkMic 当前是否正在连麦 (YES:正在连麦中 NO:不在连麦中)
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView inLinkMicChanged:(BOOL)inLinkMic;

@end

NS_ASSUME_NONNULL_END
