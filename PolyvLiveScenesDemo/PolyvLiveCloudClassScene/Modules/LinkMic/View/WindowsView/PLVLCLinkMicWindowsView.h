//
//  PLVLCLinkMicWindowsView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCLinkMicWindowsViewDelegate;

/// 连麦窗口列表视图
@interface PLVLCLinkMicWindowsView : UIView

@property (nonatomic, weak) id <PLVLCLinkMicWindowsViewDelegate> delegate;

- (void)linkMicWindowLinkMicUserId:(NSString *)linkMicUserId wannaBecomeFirstSite:(BOOL)wannaBecomeFirstSite;

/// 在连麦窗口列表上，刷新用户信息及Rtc画面
///
/// @note 调用此方法，将展示连麦用户信息、添加 用户Rtc渲染画面视图
- (void)reloadWindowsWithDataArray:(NSArray <PLVLinkMicOnlineUser *>*)dataArray;

@end

@protocol PLVLCLinkMicWindowsViewDelegate <NSObject>

@optional

/// 连麦窗口被点击事件 (表示用户希望视图位置交换)
///
/// @note 通过此回调，和外部对象，进行视图位置交换
///
/// @param windowsView 连麦窗口列表视图
/// @param indexPath 被点击窗口 对应的下标
/// @param linkMicUser 被点击窗口 对应的连麦用户数据
/// @param canvasView 被点击窗口 对应的连麦画布视图
///
/// @return UIView 外部对象返回的视图，将显示在被点击窗口的位置
- (UIView *)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView
               windowCellDidClicked:(NSIndexPath *)indexPath
                        linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser
                         canvasView:(UIView *)canvasView;

/// 连麦窗口需要回退外部视图
///
/// @note 通过此回调，告知外部对象，外部视图将进行位置回退恢复。外部无需关心 canvasView连麦画布视图 的收尾处理工作，仅需将 externalView外部视图 恢复至正确位置。
///
/// @param windowsView 连麦窗口列表视图
/// @param externalView 正在显示在列表中的外部视图
- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView
           rollbackExternalView:(UIView *)externalView;

- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView
linkMicUserWantToBecomeFirstSite:(NSInteger)index;
@end

NS_ASSUME_NONNULL_END
