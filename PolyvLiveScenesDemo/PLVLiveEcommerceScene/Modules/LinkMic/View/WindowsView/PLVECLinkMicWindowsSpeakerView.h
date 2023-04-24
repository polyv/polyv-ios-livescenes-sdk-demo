//
//  PLVECLinkMicWindowsSpeakerView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/5.
//  Copyright © 2021 PLV. All rights reserved.
//
// 主讲模式 - 第一画面

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"
#import "PLVECLinkMicWindowCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECLinkMicWindowsSpeakerView : UIView

@property (nonatomic, strong, readonly) PLVECLinkMicWindowCell *linkMicWindowCell;

/// 显示主讲第一画面
/// @param onlineUser 主讲的数据模型
- (void)showSpeakerViewWithUserModel:(PLVLinkMicOnlineUser *)onlineUser;

/// 隐藏主讲的第一画面
- (void)hideSpeakerView;

@end

NS_ASSUME_NONNULL_END
