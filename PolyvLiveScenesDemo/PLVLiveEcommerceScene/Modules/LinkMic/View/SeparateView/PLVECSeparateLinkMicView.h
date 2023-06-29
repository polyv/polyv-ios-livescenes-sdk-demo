//
//  PLVECSeparateLinkMicView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/6/21.
//  Copyright © 2023 PLV. All rights reserved.
//
// 单独显示的连麦视图


#import <UIKit/UIKit.h>
#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECSeparateLinkMicView : UIView

/// 设置 数据模型
/// @param onlineUser 数据模型
- (void)setUserModel:(PLVLinkMicOnlineUser *)onlineUser;

@end

NS_ASSUME_NONNULL_END
