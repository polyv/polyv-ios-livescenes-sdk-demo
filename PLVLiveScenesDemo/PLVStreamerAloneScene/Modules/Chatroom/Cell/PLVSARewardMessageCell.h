//
//  PLVSARewardMessageCell.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/17.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABaseMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/// 手机开播-纯视频 聊天室 打赏消息cell
/// 支持打赏消息
/// 只支持单行显示、现金打赏使用本地图片、其他打赏使用网络图片
/// 不支持头衔显示、不支持换行，文字过长中间显示省略号
@interface PLVSARewardMessageCell : PLVSABaseMessageCell

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

/// 判断model是否为有效类型，子类可覆写
/// @param model 数据模型
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
