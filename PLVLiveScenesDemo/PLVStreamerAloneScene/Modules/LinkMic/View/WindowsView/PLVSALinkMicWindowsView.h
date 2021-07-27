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

@end

NS_ASSUME_NONNULL_END
