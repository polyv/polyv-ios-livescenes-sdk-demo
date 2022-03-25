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

NS_ASSUME_NONNULL_BEGIN

@class PLVECLinkMicAreaView;

@protocol PLVECLinkMicAreaViewDelegate <NSObject>

/// RTC画面窗口 需外部展示 ‘第一画面连麦窗口’
///
/// @param canvasView 第一画面连麦窗口视图 (需外部进行添加展示)
- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView showFirstSiteCanvasViewOnExternal:(UIView *)canvasView;

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

@end

/// 连麦区域视图
///
/// @note 负责处理无延迟观看的视图业务逻辑
/// 命名为LinkMic，但暂时不支持连麦功能，统一逻辑，为后续“支持连麦”做铺垫
/// 虽然叫AreaView，但暂时不需承担UI功能
@interface PLVECLinkMicAreaView : NSObject

/// PLVECLinkMicAreaViewDelegate代理
@property (nonatomic, weak) id<PLVECLinkMicAreaViewDelegate> delegate;

/// 当前 是否已暂停无延迟观看(YES:已暂停 NO:未暂停)
@property (nonatomic, assign, readonly) BOOL pausedWatchNoDelay;

#pragma mark - Method

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
