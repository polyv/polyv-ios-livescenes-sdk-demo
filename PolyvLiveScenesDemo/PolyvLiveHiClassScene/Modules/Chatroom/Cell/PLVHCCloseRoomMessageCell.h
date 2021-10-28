//
//  PLVHCCloseRoomMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/7.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCBaseMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/// 互动学堂 聊天室 聊天室开启、关闭提示消息cell
/// 支持 聊天室开启、关闭提示 消息
@interface PLVHCCloseRoomMessageCell : PLVHCBaseMessageCell

/// 设置消息数据模型
/// @param model 数据模型
- (void)updateWithModel:(PLVChatModel *)model;

/// 根据消息数据模型计算cell高度
/// @param model 数据模型
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
