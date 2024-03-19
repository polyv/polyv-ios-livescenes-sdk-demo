//
//  PLVSALinkMicWindowsExternalView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/10/18.
//  Copyright © 2023 PLV. All rights reserved.
//
// BAC模式 - 本地外部视图

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"
#import "PLVSALinkMicWindowCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVSALinkMicWindowsExternalView : UIView

@property (nonatomic, strong, readonly) PLVSALinkMicWindowCell *linkMicWindowCell;

/// 显示连麦用户第一画面
/// @param onlineUser 主讲的数据模型
/// @param delegate 连麦 cell 的 delegate
- (void)showExternalViewWithUserModel:(PLVLinkMicOnlineUser *)onlineUser delegate:(id<PLVSALinkMicWindowCellDelegate>)delegate;

/// 显示外部视图
- (void)showExternalViewWithExternalView:(UIView *)externalView;

/// 隐藏主讲的第一画面
- (void)hideExternalView;

@end

NS_ASSUME_NONNULL_END
