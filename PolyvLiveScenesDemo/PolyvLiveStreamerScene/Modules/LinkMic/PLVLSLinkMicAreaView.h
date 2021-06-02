//
//  PLVLSLinkMicAreaView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 polyv. All rights reserved.
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

- (void)reloadLinkMicUserWindows;


@end

/// 连麦区域视图Delegate
@protocol PLVLSLinkMicAreaViewDelegate <NSObject>

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param linkMicAreaView 连麦窗口列表视图
- (NSArray *)plvLCLinkMicWindowsViewGetCurrentUserModelArray:(PLVLSLinkMicAreaView *)linkMicAreaView;

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param linkMicAreaView 连麦窗口列表视图
/// @param filtrateBlockBlock 筛选条件Block
- (NSInteger)plvLCLinkMicWindowsView:(PLVLSLinkMicAreaView *)linkMicAreaView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param linkMicAreaView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)plvLCLinkMicWindowsView:(PLVLSLinkMicAreaView *)linkMicAreaView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

@end

NS_ASSUME_NONNULL_END
