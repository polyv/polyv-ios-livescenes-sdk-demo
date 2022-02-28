//
//  PLVHCLinkMicZoomAreaView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/11/15.
//  Copyright © 2021 PLV. All rights reserved.
// 连麦放大视图区域
// 用于管理每一个放大连麦视图(PLVHCLinkMicZoomItemContainer)，frame与白板区域一致，图层高于白板区域

#import <UIKit/UIKit.h>
#import "PLVHCLinkMicZoomManager.h"

NS_ASSUME_NONNULL_BEGIN
@class
PLVHCLinkMicZoomAreaView,
PLVLinkMicOnlineUser,
PLVHCLinkMicZoomModel,
PLVHCLinkMicItemView;

@protocol PLVHCLinkMicZoomAreaViewDelegate <NSObject>

@optional

/// 连麦放大视图区域 需要获取当前用户数组
- (NSArray *)linkMicZoomAreaViewGetCurrentUserModelArray:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView;

/// 点击 连麦放大视图区域 时回调
/// @note userData为nil 表示为本地预览，反之为连麦视图
- (void)linkMicZoomAreaView:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView didTapActionWithUserData:(PLVLinkMicOnlineUser * _Nullable)userData;

/// 需要刷新 【外部】连麦窗口列表 时回调
- (void)linkMicZoomAreaViewDidReLoadLinkMicUserWindows:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView;

/// 从外部获取连麦视图
- (UIView *)linkMicZoomAreaView:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView getLinkMicItemViewWithUserId:(NSString *)userId;

@end

@interface PLVHCLinkMicZoomAreaView : UIView<PLVHCLinkMicZoomManagerDelegate>

@property (nonatomic, weak) id<PLVHCLinkMicZoomAreaViewDelegate> delegate;

#pragma mark 【通用】刷新视图

/// 更新连麦视图
/// @note 连麦人数变化，cell可能会重新创建，所以需要重新将itemView赋值给放大区域
/// @param linkMicItemView 连麦视图
- (void)refreshLinkMicItemView:(PLVHCLinkMicItemView *)linkMicItemView;

/// 更新 连麦放大视图区域的所有视图
/// @note 用于在连麦数据更新时，同步连麦放大视图视图
- (void)reloadLinkMicUserZoom;

/// 改变全屏状态
/// @note 内部适配UI比例，讲师需要发送socket消息
/// @param fullScreen 是否全屏
- (void)changeFullScreen:(BOOL)fullScreen;

#pragma mark 【讲师】操作放大区域连麦画面

/// 移除本地预览连麦放大窗口
/// @note 用于正式开始上课，清除本地预览窗口以及清除本地数据缓存。当前的放大区域数据以'onSliceID'（Socket消息）返回的为准
- (void)removeLocalPreviewZoom;

/// 承载展示外部视图
/// @param externalView 外部视图
/// @param userId 用户Id
- (void)displayExternalView:(UIView *)externalView userId:(NSString *)userId;

/// 移除展示外部视图
/// @param externalView 外部视图
/// @param userId 用户Id
- (void)removeExternalView:(UIView *)externalView userId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
