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

NS_ASSUME_NONNULL_BEGIN

@interface PLVSALinkMicWindowsSpeakerView : UIView

/// 显示主讲第一画面
/// @param onlineUser 主讲的数据模型
- (void)showSpeakerViewWithUserModel:(PLVLinkMicOnlineUser *)onlineUser;

- (void)hideSpeakerView;

@end

NS_ASSUME_NONNULL_END
