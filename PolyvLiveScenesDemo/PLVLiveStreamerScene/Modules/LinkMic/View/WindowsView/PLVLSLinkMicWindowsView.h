//
//  PLVLSLinkMicWindowsView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"
#import "PLVLSLinkMicWindowCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSLinkMicWindowsViewDelegate;

@interface PLVLSLinkMicWindowsView : UIView

/// delegate
@property (nonatomic, weak) id <PLVLSLinkMicWindowsViewDelegate> delegate;

/// 刷新 连麦窗口列表
///
/// @note 将触发 [plvLCLinkMicWindowsViewGetCurrentUserModelArray:] 此代理方法；
///       外部需实现此方法，以让 连麦窗口列表视图 正确获得当前连麦用户数据
- (void)reloadLinkMicUserWindows;

/// 更新在线用户到第一画面
/// @param linkMicUserId 连麦用户id
/// @param toFirstSite 是否到第一画面
- (void)updateFirstSiteWindowCellWithUserId:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite;

/// RTC画面窗口(第一画面连麦窗口)和外部视图交换位置
///
/// @note 此方法表示用户希望 第一画面连麦视图与外部视图 externalView交换位置，将触发(plvLSLinkMicWindowsView:showFirstSiteWindowCellOnExternal:)此代理方法
- (void)firstSiteWindowCellExchangeWithExternal:(UIView *)externalView;

/// 回滚外部视图和第一画面窗口到原来的位置
///
///@note 此方法表示用户希望 第一画面连麦视图与外部视图 externalView回滚至原本位置，将触发(plvLSLinkMicWindowsView:rollbackExternalView:)此代理方法
- (void)rollbackFirstSiteWindowCellAndExternalView;

/// 本地用户连麦状态发生改变
/// @param linkMicStatus 连麦状态
- (void)updateLocalUserLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus;

/// 下课（直播结束）
- (void)finishClass;

/// 更新所有连麦者的连麦时长（除讲师外）
- (void)updateAllCellLinkMicDuration;

@end

@protocol PLVLSLinkMicWindowsViewDelegate <NSObject>

@optional

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param windowsView 连麦窗口列表视图
- (NSArray *)plvLCLinkMicWindowsViewGetCurrentUserModelArray:(PLVLSLinkMicWindowsView *)windowsView __deprecated_msg("use [plvLSLinkMicWindowsViewGetCurrentUserModelArray:] instead.");
- (NSArray *)plvLSLinkMicWindowsViewGetCurrentUserModelArray:(PLVLSLinkMicWindowsView *)windowsView;

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param windowsView 连麦窗口列表视图
/// @param filtrateBlockBlock 筛选条件Block
- (NSInteger)plvLCLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock __deprecated_msg("use [plvLSLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:] instead.");
- (NSInteger)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param windowsView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)plvLCLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex __deprecated_msg("use [plvLSLinkMicWindowsView:getUserModelFromOnlineUserArrayWithIndex:] instead.");
- (PLVLinkMicOnlineUser *)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

/// 连麦窗口列表视图 需外部展示 ‘第一画面连麦窗口’
///
/// @param windowsView 连麦窗口列表视图
/// @param windowCell 第一画面连麦窗口视图 (需外部进行添加展示)
- (void)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView showFirstSiteWindowCellOnExternal:(UIView *)windowCell;

/// 连麦窗口需要回退外部视图
///
/// @note 通过此回调，告知外部对象，外部视图将进行位置回退恢复。外部无需关心 windowCell连麦视图 的收尾处理工作，仅需将 externalView外部视图 恢复至正确位置。
///
/// @param windowsView 连麦窗口列表视图
/// @param externalView 正在显示在列表中的外部视图
- (void)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView rollbackExternalView:(UIView *)externalView;

/// 同意/取消 连麦邀请
/// @param windowsView 连麦窗口列表视图
/// @param accept 是否同意连麦邀请（YES同意，NO拒绝）
/// @param timeoutCancel 是否是超时拒绝，当accept 为NO时有效
- (void)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView acceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel;

/// 需要获取 连麦邀请 剩余的等待时间
/// @param windowsView 连麦窗口列表视图
/// @param callback 获取剩余时间的回调
- (void)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback;

/// 本地用户点击停止屏幕共享按钮
/// @param windowsView 连麦窗口列表视图
- (void)plvLSLinkMicWindowsViewDidClickStopScreenSharing:(PLVLSLinkMicWindowsView *)windowsView;

@end
NS_ASSUME_NONNULL_END
