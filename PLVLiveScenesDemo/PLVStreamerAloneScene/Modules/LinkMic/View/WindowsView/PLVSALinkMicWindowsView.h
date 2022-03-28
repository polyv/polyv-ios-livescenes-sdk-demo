//
//  PLVSALinkMicWindowsView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVSALinkMicWindowsViewDelegate;

@interface PLVSALinkMicWindowsView : UIView

/// delegate
@property (nonatomic, weak) id <PLVSALinkMicWindowsViewDelegate> delegate;

/// 刷新连麦窗口
- (void)reloadLinkMicUserWindows;

/// 切换连麦窗口布局和主讲人
/// @note 切换连麦窗口的布局【仅当 speakerMode为YES时linkMicUserId有效】
/// @param speakerMode 连麦的布局模式是否为主讲模式
/// @param linkMicUserId 设置主讲模式时的主讲用户Id【当为空时会在内部设置连麦列表第一个人为主讲】
- (void)switchLinkMicWindowsLayoutSpeakerMode:(BOOL)speakerMode linkMicWindowMainSpeaker:(NSString * _Nullable)linkMicUserId;

@end

@protocol PLVSALinkMicWindowsViewDelegate <NSObject>

@required

/// 连麦窗口列表视图 需要获取本地用户数据
///
/// @param windowsView 连麦窗口列表视图
- (PLVLinkMicOnlineUser *)localUserInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView;

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param windowsView 连麦窗口列表视图
- (NSArray *)currentOnlineUserListInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView;

/// 连麦窗口列表视图 获取当前是否正在展示设置页的预览视图
///
/// @param windowsView 连麦窗口列表视图
- (BOOL)localUserPreviewViewInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView;

@optional

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param windowsView 连麦窗口列表视图
/// @param filterBlock 筛选条件 Block
- (NSInteger)onlineUserIndexInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView
                                     filterBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filterBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param windowsView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)onlineUserInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView
                                         withTargetIndex:(NSInteger)targetIndex;

/// 连麦窗口列表视图 点击【连麦窗口】回调
///
/// @param windowsView 连麦窗口列表视图
/// @param onlineUser 连麦用户信息
- (void)linkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView didSelectOnlineUser:(PLVLinkMicOnlineUser *)onlineUser;

/// 连麦窗口列表视图 初次连麦人数大于1时 需要外部显示连麦引导视图的回调
/// @param windowsView 连麦窗口列表视图
/// @param guideView 连麦引导视图
- (void)linkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView showGuideViewOnExternal:(UIView *)guideView;

/// 连麦窗口列表视图 需要获取当前是否已经开始上课
///
/// @param windowsView 连麦窗口列表视图
- (BOOL)classStartedInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView;

@end

NS_ASSUME_NONNULL_END