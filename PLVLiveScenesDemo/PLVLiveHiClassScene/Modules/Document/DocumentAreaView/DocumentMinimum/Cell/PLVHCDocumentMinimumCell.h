//
//  PLVHCDocumentMinimumCell.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/12.
//  Copyright © 2021 PLV. All rights reserved.
// 文档最小化列表视图 PLVHCDocumentMinimumListView 的cell

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCDocumentMinimumModel;

@interface PLVHCDocumentMinimumCell : UITableViewCell

/// 点击 移除按钮 触发
@property (nonatomic, copy) void(^ _Nullable removeHandler)(PLVHCDocumentMinimumModel *documentModel);

/// cell高度
+ (CGFloat)cellHeight;

/// cellId
+ (NSString *)cellId;

/// 设置消息数据模型，cell宽度
/// @param model 数据模型
/// @param cellWidth cell宽度
- (void)updateWithModel:(PLVHCDocumentMinimumModel *)model cellWidth:(CGFloat)cellWidth;

@end

NS_ASSUME_NONNULL_END
