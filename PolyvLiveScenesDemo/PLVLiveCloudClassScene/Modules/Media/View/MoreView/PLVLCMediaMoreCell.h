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

#define PLVLCMediaMoreCellOptionCountPerRow 4

@protocol PLVLCMediaMoreCellDelegate;

/// 媒体更多视图TableviewCell
@interface PLVLCMediaMoreCell : UITableViewCell

@property (nonatomic, weak) id <PLVLCMediaMoreCellDelegate> delegate;

- (void)setModel:(PLVLCMediaMoreModel *)model;

- (void)openDanmuButton:(BOOL)open;

/// 配置功能开关数据
/// @param switchesDataArray 功能开关数据
- (void)setSwitchesDataArray:(NSMutableArray<PLVLCMediaMoreModel *> *)switchesDataArray;

@end

@protocol PLVLCMediaMoreCellDelegate <NSObject>

- (void)plvLCMediaMoreCell:(PLVLCMediaMoreCell *)cell buttonClickedWithModel:(PLVLCMediaMoreModel *)moreModel;

@end

NS_ASSUME_NONNULL_END
