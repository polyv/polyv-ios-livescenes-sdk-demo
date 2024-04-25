//
//  PLVSALinkMicAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSALinkMicWindowsView;

@protocol PLVSALinkMicAreaViewDelegate;

@interface PLVSALinkMicAreaView : UIView

@property (nonatomic, weak) id <PLVSALinkMicAreaViewDelegate> delegate;

@property (nonatomic, strong, readonly) PLVSALinkMicWindowsView *windowsView; // 连麦窗口视图

/// 刷新连麦窗口
- (void)reloadLinkMicUserWindows;

/// 更新在线用户到第一画面
/// @param linkMicUserId 连麦用户id
/// @param toFirstSite 是否到第一画面
- (void)updateFirstSiteCanvasViewWithUserId:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite;

/// 本地用户连麦状态发生改变
/// @param linkMicStatus 连麦状态
- (void)updateLocalUserLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus;

/// 下课（直播结束）
- (void)finishClass;

/// 退出直播时调用
- (void)clear;

/// 更新连麦用户的连麦时长
- (void)updateUsersLinkMicDuration;

@end

/// 连麦区域视图Delegate
@protocol PLVSALinkMicAreaViewDelegate <NSObject>

@required

/// 连麦窗口列表视图 需要获取本地用户数据
///
/// @param areaView 连麦窗口列表视图
- (PLVLinkMicOnlineUser *)localUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView;

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param areaView 连麦窗口列表视图
- (NSArray *)currentOnlineUserListInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView;

/// 连麦窗口列表视图 获取当前是否正在展示设置预览页
///
/// @param areaView 连麦窗口列表视图
- (BOOL)localUserPreviewViewInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView;

@optional

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param areaView 连麦窗口列表视图
/// @param filterBlock 筛选条件 Block
- (NSInteger)onlineUserIndexInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView
                                  filterBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filterBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param areaView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)onlineUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView
                                      withTargetIndex:(NSInteger)targetIndex;

/// 点击连麦用户窗口回调（点击自己不触发）
///
/// @param areaView 连麦窗口列表视图
- (void)didSelectLinkMicUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView;

/// 连麦窗口列表视图 收到WindowsView对象【showGuideViewOnExternal：】事件的回调
/// @param areaView 连麦窗口列表视图
/// @param guideView 连麦引导视图
- (void)linkMicAreaView:(PLVSALinkMicAreaView *)areaView showGuideViewOnExternal:(UIView *)guideView;

/// 连麦窗口列表视图 需要获取当前是否已经开始上课
/// @param areaView 连麦窗口列表视图
- (BOOL)classStartedInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView;

/// 开启 或者 关闭全屏
/// @param areaView 连麦窗口列表视图
/// @param onlineUser 连麦用户信息
/// @param isFullScreen 是否开启全屏(YES 开启 NO 关闭)
- (void)linkMicAreaView:(PLVSALinkMicAreaView *)areaView onlineUser:(PLVLinkMicOnlineUser *)onlineUser isFullScreen:(BOOL)isFullScreen;

/// 同意/取消 连麦邀请
/// @param areaView 连麦窗口列表视图
/// @param accept 是否同意连麦邀请（YES同意，NO拒绝）
/// @param timeoutCancel 是否是超时拒绝，当accept 为NO时有效
- (void)plvSALinkMicAreaView:(PLVSALinkMicAreaView *)areaView acceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel;

/// 需要获取 连麦邀请 剩余的等待时间
/// @param areaView 连麦窗口列表视图
/// @param callback 获取剩余时间的回调
- (void)plvSALinkMicAreaView:(PLVSALinkMicAreaView *)areaView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback;

@end

NS_ASSUME_NONNULL_END
