//
//  PLVLCRewardCellTableViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/3/1.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"


/*
 云课堂场景，竖屏聊天室消息 cell
 礼物打赏提示消息
 */
@interface PLVLCRewardMessageCell : UITableViewCell

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

