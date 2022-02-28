//
//  PLVHCLinkMicAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//
// 连麦区域视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLinkMicOnlineUser, PLVHCLinkMicWindowsView,PLVHCLinkMicItemView;

@protocol PLVHCLinkMicAreaViewDelegate;

@interface PLVHCLinkMicAreaView : UIView

#pragma mark UI
@property (nonatomic, strong, readonly) PLVHCLinkMicWindowsView *windowsView;          // 连麦窗口列表视图 (负责展示1v1 1v6画面窗口)

@property (nonatomic, weak) id <PLVHCLinkMicAreaViewDelegate> delegate;

/// 刷新连麦区域用户列表
- (void)reloadLinkMicUserWindows;

/// 麦克风开启或者关闭
/// 用于上课前老师端的本地预览视图UI修改
/// @param enable (YES 开启 NO关闭)
- (void)enableLocalMic:(BOOL)enable;

/// 摄像头开启或者关闭
/// 用于上课前老师端的本地预览视图UI修改
/// @param enable (YES 开启 NO关闭)
- (void)enableLocalCamera:(BOOL)enable;

/// 显示本地摄像头预览画面
- (void)startPreview;

/// 显示本地预览连麦设置弹窗
- (void)showLocalSettingView;

/// 显示连麦设置弹窗
/// @param user 用户模型
- (void)showSettingViewWithUser:(PLVLinkMicOnlineUser *)user;

/// 根据用户Id获取连麦视图
/// @param userId 用户Id
- (UIView *)getLinkMicItemViewWithUserId:(NSString *)userId;

@end

/// 连麦区域视图Delegate
@protocol PLVHCLinkMicAreaViewDelegate <NSObject>

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param linkMicAreaView 连麦窗口列表视图
- (NSArray *)plvHCLinkMicAreaViewGetCurrentUserModelArray:(PLVHCLinkMicAreaView *)linkMicAreaView;

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param linkMicAreaView 连麦窗口列表视图
/// @param filtrateBlockBlock 筛选条件Block
- (NSInteger)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param linkMicAreaView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

/// 连麦视图切换
- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView didSwitchLinkMicWithExternalView:(UIView *)externalView userId:(NSString *)userId showInZoom:(BOOL)showInZoom;

/// 连麦视图列表 刷新时回调
- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView didRefreshLinkMiItemView:(PLVHCLinkMicItemView *)linkMicItemView;

@end

NS_ASSUME_NONNULL_END
