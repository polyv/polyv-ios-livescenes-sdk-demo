//
//  PLVLSLinkMicWindowsView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

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

@end
NS_ASSUME_NONNULL_END
