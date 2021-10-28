//
//  PLVHCQuoteMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/25.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCBaseMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/// 互动学堂 聊天室 引用回复消息cell
/// 支持文本、图片消息
@interface PLVHCQuoteMessageCell : PLVHCBaseMessageCell

/// 点击 重发按钮 触发
@property (nonatomic, copy) void(^ _Nullable resendReplyHandler)(PLVChatModel *model);

/// 设置消息数据模型，cell宽度
/// @param model 数据模型
/// @param loginUserId 用户的聊天室userId
/// @param cellWidth cell宽度
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 根据消息数据模型、cell宽度计算cell高度
/// @param model 数据模型
/// @param loginUserId 用户的聊天室userId
/// @param cellWidth cell宽度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

@end

NS_ASSUME_NONNULL_END
