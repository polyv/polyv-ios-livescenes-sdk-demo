//
//  PLVECChatCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatModel;

NS_ASSUME_NONNULL_BEGIN

@interface PLVECChatCell : UITableViewCell

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
