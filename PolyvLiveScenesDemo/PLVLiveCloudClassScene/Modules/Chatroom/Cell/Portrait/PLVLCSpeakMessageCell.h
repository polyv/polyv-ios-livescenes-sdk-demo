//
//  PLVLCSpeakMessageCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，竖屏聊天室消息 cell
 支持文本消息
 */
@interface PLVLCSpeakMessageCell : PLVLCMessageCell

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(id)message user:(PLVChatUser *)user;

@end

NS_ASSUME_NONNULL_END
