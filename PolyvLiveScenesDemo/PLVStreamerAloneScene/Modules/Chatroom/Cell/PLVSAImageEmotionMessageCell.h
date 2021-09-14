//
//  PLVSAImageEmotionMessageCell.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABaseMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/// 手机开播-纯视频 聊天室 图片表情消息cell
/// 支持图片表情消息
@interface PLVSAImageEmotionMessageCell : PLVSABaseMessageCell

/// 点击 重发按钮 触发
/// @param imageId 图片id
/// @param imageUrl 图片URL String
@property (nonatomic, copy) void(^ _Nullable resendImageEmotionHandler)(NSString *imageId, NSString *imageUrl);


/// 设置消息数据模型，cell宽度
/// @param model 数据模型
/// @param loginUserId 用户的聊天室userId
/// @param cellWidth cell宽度
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 根据消息数据模型、cell宽度计算cell高度
/// @param model 数据模型
/// @param cellWidth cell宽度计算
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型，子类可覆写
/// @param model 数据模型
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
