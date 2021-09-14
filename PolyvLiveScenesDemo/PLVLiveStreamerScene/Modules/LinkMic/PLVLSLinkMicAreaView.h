//
//  PLVLSLinkMicAreaView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

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

@end

NS_ASSUME_NONNULL_END
