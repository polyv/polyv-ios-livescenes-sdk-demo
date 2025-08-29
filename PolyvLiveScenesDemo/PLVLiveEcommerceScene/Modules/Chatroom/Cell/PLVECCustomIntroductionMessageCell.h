//
//  PLVECCustomIntroductionMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/07/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECChatBaseCell.h"

@class PLVChatModel;

@interface PLVECCustomIntroductionMessageCell : PLVECChatBaseCell

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(id)message;

/// 计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 判断model是否有效
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end 
