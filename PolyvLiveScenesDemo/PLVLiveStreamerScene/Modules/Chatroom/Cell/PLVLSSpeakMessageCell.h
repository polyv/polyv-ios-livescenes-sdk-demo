//
//  PLVLSSpeakMessageCell.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/18.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLSBaseMessageCell.h"
#import "PLVChatModel.h"
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，横屏聊天室消息 cell
 支持文本消息
 */
@interface PLVLSSpeakMessageCell : PLVLSBaseMessageCell

/// 设置消息数据模型，cell宽度
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型，子类可覆写
+ (BOOL)isModelValid:(PLVChatModel *)model;

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId prohibitWord:(NSString *)prohibitWord isRemindMsg:(BOOL)isRemindMsg;

@end

NS_ASSUME_NONNULL_END
