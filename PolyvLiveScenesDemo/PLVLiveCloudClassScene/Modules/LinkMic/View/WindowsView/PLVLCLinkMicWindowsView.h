//
//  PLVLCLinkMicWindowsView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCLinkMicWindowsViewDelegate;

/// 连麦窗口列表视图
@interface PLVLCLinkMicWindowsView : UIView

#pragma mark - [ 属性 ]
/// delegate
@property (nonatomic, weak) id <PLVLCLinkMicWindowsViewDelegate> delegate;


#pragma mark - [ 方法 ]
/// 刷新 连麦窗口列表
///
/// @note 将触发 [plvLCLinkMicWindowsViewGetCurrentUserModelArray:] 此代理方法；
///       外部需实现此代理方法，以让 连麦窗口列表视图 正确获得当前连麦用户数据
///
/// @param reloadCompleteBlock 列表刷新完成Block
- (void)reloadLinkMicUserWindowsWithCompleteBlock:(nullable void (^)(void))reloadCompleteBlock;

- (void)linkMicWindowMainSpeaker:(NSString *)linkMicUserId toMainScreen:(BOOL)mainSpeakerToMainScreen;

@end

@protocol PLVLCLinkMicWindowsViewDelegate <NSObject>

@optional
/// 连麦窗口列表视图 需获知 ‘当前频道连麦场景类型’
///
/// @return PLVChannelLinkMicSceneType 当前的频道连麦场景类型
- (PLVChannelLinkMicSceneType)plvLCLinkMicWindowsViewGetCurrentLinkMicSceneType:(PLVLCLinkMicWindowsView *)windowsView;

/// 连麦窗口列表视图 需外部展示 ‘第一画面连麦窗口’
///
/// @param windowsView 连麦窗口列表视图
/// @param canvasView 第一画面连麦窗口视图 (需外部进行添加展示)
- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView showFirstSiteCanvasViewOnExternal:(UIView *)canvasView;

/// 连麦窗口被点击事件 (表示用户希望视图位置交换)
///
/// @note 通过此回调，和外部对象，进行视图位置交换
///
/// @param windowsView 连麦窗口列表视图
/// @param linkMicUser 被点击窗口 对应的连麦用户模型
/// @param canvasView 被点击窗口 对应的连麦画布视图
///
/// @return UIView 外部对象返回的视图，将显示在被点击窗口的位置
- (UIView *)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView wantExchangeWithExternalViewForLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser canvasView:(UIView *)canvasView;

/// 连麦窗口需要回退外部视图
///
/// @note 通过此回调，告知外部对象，外部视图将进行位置回退恢复。外部无需关心 canvasView连麦画布视图 的收尾处理工作，仅需将 externalView外部视图 恢复至正确位置。
///
/// @param windowsView 连麦窗口列表视图
/// @param externalView 正在显示在列表中的外部视图
- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView rollbackExternalView:(UIView *)externalView;

/// 连麦窗口被点击事件 (表示用户希望某个窗口成为‘第一画面’)
///
/// @param windowsView 连麦窗口列表视图
/// @param index 希望成为 ‘第一画面’ 的用户下标
- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView linkMicUserWantToBecomeFirstSite:(NSInteger)index;

/// 连麦窗口列表视图 需要获取当前用户数组
///
/// @param windowsView 连麦窗口列表视图
- (NSArray *)plvLCLinkMicWindowsViewGetCurrentUserModelArray:(PLVLCLinkMicWindowsView *)windowsView;

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
///
/// @param windowsView 连麦窗口列表视图
/// @param filtrateBlockBlock 筛选条件Block
- (NSInteger)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 连麦窗口列表视图 需要根据下标值获取对应用户
///
/// @param windowsView 连麦窗口列表视图
/// @param targetIndex 目标下标值
- (PLVLinkMicOnlineUser *)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

/// 连麦窗口列表视图 需获知 ‘主讲的PPT 当前是否在主屏’
///
/// @note 此回调不保证在主线程触发
///
/// @param windowsView 连麦窗口列表视图
- (BOOL)plvLCLinkMicWindowsViewGetMainSpeakerPPTOnMain:(PLVLCLinkMicWindowsView *)windowsView;

@end

NS_ASSUME_NONNULL_END
