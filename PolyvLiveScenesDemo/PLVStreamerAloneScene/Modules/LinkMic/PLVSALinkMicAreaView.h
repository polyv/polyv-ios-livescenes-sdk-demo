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

/// 退出直播时调用
- (void)clear;

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

@end

NS_ASSUME_NONNULL_END
