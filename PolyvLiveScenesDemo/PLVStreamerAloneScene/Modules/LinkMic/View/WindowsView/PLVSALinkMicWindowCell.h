//
//  PLVSALinkMicWindowCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVSALinkMicWindowCellDelegate;

@interface PLVSALinkMicWindowCell : UICollectionViewCell

@property (nonatomic, weak) id <PLVSALinkMicWindowCellDelegate> delegate;

#pragma mark 方法

/// 设置 cell 数据模型
/// @param onlineUser 数据模型
/// @param hide 是否需要隐藏昵称，同时当摄像头关闭时，是否要显示canvasView视图
- (void)setUserModel:(PLVLinkMicOnlineUser *)onlineUser hideCanvasViewWhenCameraClose:(BOOL)hide;

/// 切换至 显示默认内容视图
- (void)switchToShowRtcContentView:(UIView *)rtcCanvasView;

/// 切换至 显示外部内容视图
- (void)switchToShowExternalContentView:(UIView *)externalContentView;

@end

@protocol PLVSALinkMicWindowCellDelegate <NSObject>

- (void)linkMicWindowCellDidSelectCell:(PLVSALinkMicWindowCell *)collectionViewCell;

- (void)linkMicWindowCell:(PLVSALinkMicWindowCell *)collectionViewCell
              linkMicUser:(PLVLinkMicOnlineUser *)onlineUser
            didFullScreen:(BOOL)fullScreen;

- (void)linkMicWindowCell:(PLVSALinkMicWindowCell *)collectionViewCell didScreenShareForRemoteUser:(PLVLinkMicOnlineUser *)onlineUser;

@end

NS_ASSUME_NONNULL_END
