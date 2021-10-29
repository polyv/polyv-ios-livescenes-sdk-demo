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

@class PLVLinkMicOnlineUser;

@protocol PLVHCLinkMicAreaViewDelegate;

@interface PLVHCLinkMicAreaView : UIView

@property (nonatomic, weak) id <PLVHCLinkMicAreaViewDelegate> delegate;

///刷新连麦区域用户列表
- (void)reloadLinkMicUserWindows;

/// 麦克风开启或者关闭 (仅对本地预览视图有效)
/// @param enable (YES 开启 NO关闭)
- (void)linkMicAreaViewEnableLocalMic:(BOOL)enable;

/// 摄像头开启或者关闭 (仅对本地预览视图有效)
/// @param enable (YES 开启 NO关闭)
- (void)linkMicAreaViewEnableLocalCamera:(BOOL)enable;

/// 摄像头方向 (仅对本地预览视图有效)
/// @param switchFront (YES朝前  NO朝后)
- (void)linkMicAreaViewSwitchLocalCameraFront:(BOOL)switchFront;

/// 摄像头开始采集画面 (仅对本地预览视图有效)
- (void)linkMicAreaViewStartRunning;

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

/// 连麦窗口列表视图 开启本地麦克风 （仅对本地预览视图有效）
/// @param linkMicAreaView 连麦窗口列表视图
/// @param enable 开启本地麦克风(YES 开启 NO 关闭)
- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView
              enableLocalMic:(BOOL)enable;

/// 连麦窗口列表视图 开启本地摄像头 （仅对本地预览视图有效）
/// @param linkMicAreaView 连麦窗口列表视图
/// @param enable 开启本地摄像头(YES 开启 NO 关闭)
- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView
           enableLocalCamera:(BOOL)enable;

/// 连麦窗口列表视图 切换摄像头方向 （仅对本地预览视图有效）
/// @param linkMicAreaView 连麦窗口列表视图
/// @param switchFront 切换摄像头方向(YES 朝前 NO 朝后)
- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView
      switchLocalCameraFront:(BOOL)switchFront;

@end

NS_ASSUME_NONNULL_END
