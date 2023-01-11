//
//  PLVECLongContentChatCellTableViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/17.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatModel;

NS_ASSUME_NONNULL_BEGIN

/*
 直播带货场景，聊天室消息，长文本消息 cell
 */
@interface PLVECLongContentChatCell : UITableViewCell

@property (nonatomic, copy) void (^copButtonHandler)(void);
@property (nonatomic, copy) void (^foldButtonHandler)(void);

/// 设置消息数据模型，cell宽度
- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型，子类可覆写
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
