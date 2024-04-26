//
//  PLVSALongContentMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/22.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABaseMessageCell.h"
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

/*
 手机开播（纯视频）场景，聊天室长文本消息 cell
 */
@interface PLVSALongContentMessageCell : PLVSABaseMessageCell

@property (nonatomic, copy) void (^resendHandler)(PLVChatModel *model);
@property (nonatomic, copy) void (^copButtonHandler)(void);
@property (nonatomic, copy) void (^foldButtonHandler)(void);

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
+ (BOOL)isModelValid:(PLVChatModel *)model;

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithModel:(PLVChatModel *)model
                                                         loginUserId:(NSString *)loginUserId;

@end

NS_ASSUME_NONNULL_END
