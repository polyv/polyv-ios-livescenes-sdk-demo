//
//  PLVLCLandscapeImageCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，横屏聊天室消息 cell
 支持图片消息
 */
@interface PLVLCLandscapeImageCell : UITableViewCell

/// 设置消息数据模型，cell宽度
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型，子类可覆写
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
