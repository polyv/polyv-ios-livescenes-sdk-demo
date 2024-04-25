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

/// 更新当前连麦时长
///
/// @param show 表示是否显示连麦时长
- (void)updateLinkMicDuration:(BOOL)show;

@end

@protocol PLVSALinkMicWindowCellDelegate <NSObject>

- (void)linkMicWindowCellDidSelectCell:(PLVSALinkMicWindowCell *)collectionViewCell;

- (void)linkMicWindowCell:(PLVSALinkMicWindowCell *)collectionViewCell
              linkMicUser:(PLVLinkMicOnlineUser *)onlineUser
            didFullScreen:(BOOL)fullScreen;

- (void)linkMicWindowCell:(PLVSALinkMicWindowCell *)collectionViewCell didScreenShareForRemoteUser:(PLVLinkMicOnlineUser *)onlineUser;

@end

NS_ASSUME_NONNULL_END
