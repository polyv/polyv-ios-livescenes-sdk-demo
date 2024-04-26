//
//  PLVLSRemindSpeakMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSRemindBaseMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSRemindSpeakMessageCell : PLVLSRemindBaseMessageCell

/// 点击 重发按钮 触发
@property (nonatomic, copy) void(^ _Nullable resendHandler)(PLVChatModel *model);

/// 设置消息数据模型，cell宽度
/// @param model 数据模型
/// @param loginUserId 用户的聊天室userId
/// @param cellWidth cell宽度
/// @param previousUserId 前一个消息的用户Id
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth previousUserId:(NSString *)previousUserId;

/// 根据消息数据模型、cell宽度计算cell高度
/// @param model 数据模型
/// @param loginUserId 用户的聊天室userId
/// @param cellWidth cell宽度
/// @param previousUserId 前一个消息的用户Id
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth previousUserId:(NSString *)previousUserId;

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId prohibitWord:(NSString *)prohibitWord;

@end

NS_ASSUME_NONNULL_END
