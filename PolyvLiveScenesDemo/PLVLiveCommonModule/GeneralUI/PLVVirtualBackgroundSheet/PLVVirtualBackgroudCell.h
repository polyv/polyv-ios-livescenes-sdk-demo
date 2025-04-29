//
//  PLVVirtualBackgroudCell.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVVirtualBackgroudModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVVirtualBackgroudCell;

@protocol PLVVirtualBackgroudCellDelegate <NSObject>

@optional
/// 点击删除按钮回调
- (void)virtualBackgroudCellDidClickDeleteButton:(PLVVirtualBackgroudCell *)cell;

@end

@interface PLVVirtualBackgroudCell : UICollectionViewCell

/// cell类型
@property (nonatomic, assign, readonly) PLVVirtualBackgroudCellType cellType;

/// 代理对象
@property (nonatomic, weak) id<PLVVirtualBackgroudCellDelegate> delegate;

/// 初始化
- (void)configCellWithModel:(PLVVirtualBackgroudModel *)model;

/// 设置选中状态
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
