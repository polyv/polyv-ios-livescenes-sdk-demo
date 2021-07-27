//
//  PLVLCMediaMoreCell.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCMediaMoreModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCMediaMoreCellDelegate;

/// 媒体更多视图TableviewCell
@interface PLVLCMediaMoreCell : UITableViewCell

@property (nonatomic, weak) id <PLVLCMediaMoreCellDelegate> delegate;

- (void)setModel:(PLVLCMediaMoreModel *)model;

@end

@protocol PLVLCMediaMoreCellDelegate <NSObject>

- (void)plvLCMediaMoreCell:(PLVLCMediaMoreCell *)cell buttonClickedWithModel:(PLVLCMediaMoreModel *)moreModel;

@end

NS_ASSUME_NONNULL_END
