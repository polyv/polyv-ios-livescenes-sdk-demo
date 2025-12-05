//
//  PLVLSLinkMicWindowCell.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSLinkMicWindowCellDelegate;

@interface PLVLSLinkMicWindowCell : UICollectionViewCell

@property (nonatomic, weak) id<PLVLSLinkMicWindowCellDelegate> delegate;

#pragma mark 方法
- (void)setModel:(PLVLinkMicOnlineUser *)userModel;

/// 切换至 显示默认内容视图
- (void)switchToShowRtcContentView:(UIView *)rtcCanvasView;

/// 切换至 显示外部内容视图
- (void)switchToShowExternalContentView:(UIView *)externalContentView;

/// 更新当前连麦时长
///
/// @param show 表示是否显示连麦时长
- (void)updateLinkMicDuration:(BOOL)show;

@end

@protocol PLVLSLinkMicWindowCellDelegate <NSObject>

@optional
/// 本地用户点击停止屏幕共享按钮
/// @param cell 连麦窗口Cell
- (void)linkMicWindowCellDidClickStopScreenSharing:(PLVLSLinkMicWindowCell *)cell;

@end

NS_ASSUME_NONNULL_END
