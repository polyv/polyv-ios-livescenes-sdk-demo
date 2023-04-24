//
//  PLVRedpackReceiveCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/10.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，竖屏聊天室，用户领取红包消息 cell
 */
@interface PLVLCRedpackResultCell : UITableViewCell

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
