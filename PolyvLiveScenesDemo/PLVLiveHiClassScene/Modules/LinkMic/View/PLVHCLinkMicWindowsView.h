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

@class PLVLinkMicOnlineUser;

@protocol PLVHCLinkMicWindowsViewDelegate;

@interface PLVHCLinkMicWindowsView : UIView

@property (nonatomic, weak) id <PLVHCLinkMicWindowsViewDelegate> delegate;

/// 刷新 连麦窗口列表
///
/// @note 将触发 [plvHCLinkMicWindowsViewGetCurrentUserModelArray:] 此代理方法；
///       外部需实现此方法，以让 连麦窗口列表视图 正确获得当前连麦用户数据
- (void)reloadLinkMicUserWindows;

/// 麦克风开启或者关闭 (仅对本地预览视图有效)
/// @param enable (YES 开启 NO关闭)
- (void)linkMicWindowsViewEnableLocalMic:(BOOL)enable;

/// 摄像头开启或者关闭 (仅对本地预览视图有效)
/// @param enable (YES 开启 NO关闭)
- (void)linkMicWindowsViewEnableLocalCamera:(BOOL)enable;

/// 摄像头方向 (仅对本地预览视图有效)
/// @param switchFront (YES朝前  NO朝后)
- (void)linkMicWindowsViewSwitchLocalCameraFront:(BOOL)switchFront;

/// 摄像头开始采集画面 (仅对本地预览视图有效)
- (void)linkMicWindowsViewStartRunning;

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


/// 连麦窗口列表视图 开启本地麦克风 （仅对本地预览视图有效）
/// @param windowsView 连麦窗口列表视图
/// @param enable 开启本地麦克风(YES 开启 NO 关闭)
- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView
                 enableLocalMic:(BOOL)enable;

/// 连麦窗口列表视图 开启本地摄像头 （仅对本地预览视图有效）
/// @param windowsView 连麦窗口列表视图
/// @param enable 开启本地摄像头(YES 开启 NO 关闭)
- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView
              enableLocalCamera:(BOOL)enable;

/// 连麦窗口列表视图 切换摄像头方向 （仅对本地预览视图有效）
/// @param windowsView 连麦窗口列表视图
/// @param switchFront 切换摄像头方向(YES 朝前 NO 朝后)
- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView
         switchLocalCameraFront:(BOOL)switchFront;

@end

NS_ASSUME_NONNULL_END
