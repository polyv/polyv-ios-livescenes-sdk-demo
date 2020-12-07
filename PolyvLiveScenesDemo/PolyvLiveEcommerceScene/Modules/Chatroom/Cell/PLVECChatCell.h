//
//  PLVECChatCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/28.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatModel;

NS_ASSUME_NONNULL_BEGIN

@interface PLVECChatCell : UITableViewCell

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

@end

NS_ASSUME_NONNULL_END
