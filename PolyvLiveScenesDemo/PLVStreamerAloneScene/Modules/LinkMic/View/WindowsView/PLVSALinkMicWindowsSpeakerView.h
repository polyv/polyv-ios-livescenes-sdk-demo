//
//  PLVSALinkMicWindowsSpeakerView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/5.
//  Copyright © 2021 PLV. All rights reserved.
//
// 主讲模式 - 第一画面

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"
#import "PLVSALinkMicWindowCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVSALinkMicWindowCellDelegate;

@interface PLVSALinkMicWindowsSpeakerView : UIView

@property (nonatomic, strong, readonly) PLVSALinkMicWindowCell *linkMicWindowCell;

/// 显示主讲第一画面
/// @param onlineUser 主讲的数据模型
/// @param delegate 连麦 cell 的 delegate
- (void)showSpeakerViewWithUserModel:(PLVLinkMicOnlineUser *)onlineUser delegate:(id<PLVSALinkMicWindowCellDelegate>)delegate;

/// 隐藏主讲的第一画面
- (void)hideSpeakerView;

@end

NS_ASSUME_NONNULL_END
