//
//  PLVECLinkMicWindowsView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECLinkMicWindowsViewDelegate;
@class PLVECSeparateLinkMicView;

@interface PLVECLinkMicWindowsView : UIView

/// delegate
@property (nonatomic, weak) id <PLVECLinkMicWindowsViewDelegate> delegate;

/// 连麦第一画面Canvas视图
@property (nonatomic, weak, readonly) UIView *firstSiteCanvasView;

/// 悬浮的连麦小窗（1v1场景使用）
@property (nonatomic, strong, readonly) PLVECSeparateLinkMicView *separateLinkMicView;

/// 是否启用1v1悬浮窗布局（默认设置为NO，设置为NO时使用传统布局；设置为YES时当1v1连麦时自动显示悬浮窗）
@property (nonatomic, assign) BOOL enableSeparateLinkMicLayout;

/// 刷新连麦窗口
- (void)reloadLinkMicUserWindows;

- (void)refreshAllLinkMicCanvasPauseImageView:(BOOL)noDelayPaused;

/// 更新在线用户到第一画面
/// @param linkMicUserId 第一画面连麦用户id
- (void)updateFirstSiteCanvasViewWithUserId:(NSString *)linkMicUserId;

/// 切换连麦窗口布局
/// @param speakerMode 连麦的布局模式是否为主讲模式
- (void)switchLinkMicWindowsLayoutSpeakerMode:(BOOL)speakerMode;

@end

@protocol PLVECLinkMicWindowsViewDelegate <NSObject>

@required

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param windowsView 连麦窗口列表视图
- (NSArray *)currentOnlineUserListInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView;

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param windowsView 连麦窗口列表视图
/// @param filterBlock 筛选条件 Block
- (NSInteger)onlineUserIndexInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView
                                     filterBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filterBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param windowsView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)onlineUserInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView
                                         withTargetIndex:(NSInteger)targetIndex;
/// 第一画面连麦窗口变更
- (void)currentFirstSiteCanvasViewChangedInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView;

@end

NS_ASSUME_NONNULL_END
