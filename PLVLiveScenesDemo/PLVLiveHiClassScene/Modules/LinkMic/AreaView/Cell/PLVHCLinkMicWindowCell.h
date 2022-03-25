//
//  PLVHCLinkMicWindowCell.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLinkMicOnlineUser, PLVHCLinkMicWindowCupView, PLVHCLinkMicItemView;

@interface PLVHCLinkMicWindowCell : UICollectionViewCell

#pragma mark UI
@property (nonatomic, strong, readonly) PLVHCLinkMicItemView *itemView;

#pragma mark 数据
@property (nonatomic, weak, readonly) PLVLinkMicOnlineUser *userModel;

/// 更新用户信息
- (void)updateOnlineUser:(PLVLinkMicOnlineUser *)userModel;

/// 显示、隐藏连麦放大视图占位图
/// @param show YE：显示，NO：隐藏
- (void)showZoomPlaceholder:(BOOL)show;

@end

/// PLVHCLinkMicWindowCell  Subclass
// 1V6 连麦Cell
@interface PLVHCLinkMicWindowSixCell : PLVHCLinkMicWindowCell

@end

// 1V16 学生连麦Cell
@interface PLVHCLinkMicWindowSixteenCell : PLVHCLinkMicWindowCell

@end

// 1V16 讲师连麦Cell
@interface PLVHCLinkMicWindowSixteenTeacherCell : PLVHCLinkMicWindowCell

@end

NS_ASSUME_NONNULL_END
