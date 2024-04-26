//
//  PLVLCFileMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/7/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，竖屏聊天室消息 cell
 支持文件下载消息
 */
@interface PLVLCFileMessageCell : PLVLCMessageCell

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(id)message user:(PLVChatUser *)user;

@end

NS_ASSUME_NONNULL_END
