//
//  PLVHCLinkMicWindowsView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 PLV. All rights reserved.
//
// 1V1 - 1V6 连麦区域


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLinkMicOnlineUser,PLVHCLinkMicItemView;

@protocol PLVHCLinkMicWindowsViewDelegate;

@interface PLVHCLinkMicWindowsView : UIView

@property (nonatomic, weak) id <PLVHCLinkMicWindowsViewDelegate> delegate;

/// 刷新 连麦窗口列表
///
/// @note 将触发 [plvHCLinkMicWindowsViewGetCurrentUserModelArray:] 此代理方法；
///       外部需实现此方法，以让 连麦窗口列表视图 正确获得当前连麦用户数据
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
@protocol PLVHCLinkMicWindowsViewDelegate <NSObject>

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param windowsView 连麦窗口列表视图
- (NSArray *)plvHCLinkMicWindowsViewGetCurrentUserModelArray:(PLVHCLinkMicWindowsView *)windowsView;

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param windowsView 连麦窗口列表视图
/// @param filtrateBlockBlock 筛选条件Block
- (NSInteger)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param windowsView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

/// 连麦视图切换
- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView didSwitchLinkMicWithExternalView:(UIView *)externalView userId:(NSString *)userId showInZoom:(BOOL)showInZoom;

/// 连麦视图列表 刷新时回调
- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView didRefreshLinkMiItemView:(PLVHCLinkMicItemView *)linkMiItemView;

@end

NS_ASSUME_NONNULL_END
