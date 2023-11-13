//
//  PLVLCLongContentMessageCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，竖屏聊天室消息，长文本消息 cell
 */
@interface PLVLCLongContentMessageCell : PLVLCMessageCell

@property (nonatomic, copy) void (^copButtonHandler)(void);
@property (nonatomic, copy) void (^foldButtonHandler)(void);

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithModel:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
