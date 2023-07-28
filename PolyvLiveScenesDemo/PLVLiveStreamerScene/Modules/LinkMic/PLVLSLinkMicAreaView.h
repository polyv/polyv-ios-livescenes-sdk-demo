//
//  PLVLSLinkMicAreaView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"
#import "PLVLSLinkMicWindowsView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSLinkMicAreaViewDelegate;

@interface PLVLSLinkMicAreaView : UIView

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id <PLVLSLinkMicAreaViewDelegate> delegate;

#pragma mark - [ 方法 ]
/// 刷新 连麦窗口列表
///
/// @note 将触发 [plvLSLinkMicAreaViewGetCurrentUserModelArray:] 此代理方法；
///       外部需实现此代理方法，以让 连麦窗口列表视图 正确获得当前连麦用户数据
- (void)reloadLinkMicUserWindows;

/// 更新在线用户到第一画面
/// @param linkMicUserId 连麦用户id
/// @param toFirstSite 是否到第一画面
- (void)updateFirstSiteWindowCellWithUserId:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite;

/// RTC画面窗口(第一画面连麦窗口)和外部视图交换位置
///
/// @note 此方法表示用户希望 第一画面连麦视图与外部视图 externalView交换位置，将触发(plvLSLinkMicAreaView:showFirstSiteWindowCellOnExternal:)此代理方法
- (void)firstSiteWindowCellExchangeWithExternal:(UIView *)externalView;

/// 回滚外部视图和第一画面窗口到原来的位置
///
///@note 此方法表示用户希望 第一画面连麦视图与外部视图 externalView回滚至原本位置，将触发(plvLSLinkMicAreaView:rollbackExternalView:)此代理方法
- (void)rollbackFirstSiteWindowCellAndExternalView;

/// 本地用户连麦状态发生改变
/// @param linkMicStatus 连麦状态
- (void)updateLocalUserLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus;

/// 下课（直播结束）
- (void)finishClass;

@end

/// 连麦区域视图Delegate
@protocol PLVLSLinkMicAreaViewDelegate <NSObject>

@optional

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param linkMicAreaView 连麦窗口列表视图
- (NSArray *)plvLCLinkMicWindowsViewGetCurrentUserModelArray:(PLVLSLinkMicAreaView *)linkMicAreaView __deprecated_msg("use [plvLSLinkMicAreaViewGetCurrentUserModelArray:] instead.");
- (NSArray *)plvLSLinkMicAreaViewGetCurrentUserModelArray:(PLVLSLinkMicAreaView *)linkMicAreaView;

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param linkMicAreaView 连麦窗口列表视图
/// @param filtrateBlockBlock 筛选条件Block
- (NSInteger)plvLCLinkMicWindowsView:(PLVLSLinkMicAreaView *)linkMicAreaView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock __deprecated_msg("use [plvLSLinkMicAreaView:findUserModelIndexWithFiltrateBlock:] instead.");
- (NSInteger)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param linkMicAreaView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)plvLCLinkMicWindowsView:(PLVLSLinkMicAreaView *)linkMicAreaView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex __deprecated_msg("use [plvLSLinkMicAreaView:getUserModelFromOnlineUserArrayWithIndex:] instead.");
- (PLVLinkMicOnlineUser *)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

/// RTC画面窗口 需外部展示 ‘第一画面连麦窗口’
///
/// @param linkMicAreaView 连麦区域视图
/// @param windowCell 第一画面连麦窗口视图 (需外部进行添加展示)
- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView showFirstSiteWindowCellOnExternal:(UIView *)windowCell;

/// 恢复外部视图位置
///
/// @note 当外部视图需要回归原位时，此回调将被触发；接收到此回调后，可将 externalView 重新布局在原位上
///
/// @param linkMicAreaView 连麦区域视图
/// @param externalView 被添加在连麦区域视图上的外部视图
- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView rollbackExternalView:(UIView *)externalView;

/// 同意/取消 连麦邀请
/// @param linkMicAreaView 连麦区域视图
/// @param accept 是否同意连麦邀请（YES同意，NO拒绝）
/// @param timeoutCancel 是否是超时拒绝，当accept 为NO时有效
- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView acceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel;

/// 需要获取 连麦邀请 剩余的等待时间
/// @param linkMicAreaView 连麦区域视图
/// @param callback 获取剩余时间的回调
- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback;

@end

NS_ASSUME_NONNULL_END
