//
//  PLVHCClassDetailView.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//  

#import <UIKit/UIKit.h>

// 模型
#import "PLVHCLessonModel.h"

/// Cell形状枚举
typedef NS_ENUM(NSUInteger, PLVHCLessonTableViewCellShape) {
    /// 无圆角
    PLVHCLessonTableViewCellNoneRoundedCorners   = 0,
    /// 四个圆角
    PLVHCLessonTableViewCellAllRoundedCorners    = 1,
    /// 顶部圆角
    PLVHCLessonTableViewCellTopRoundedCorners    = 2,
    /// 底部圆角
    PLVHCLessonTableViewCellBottomRoundedCorners = 3
};

@interface PLVHCLessonTableViewCell : UITableViewCell

- (void)updateWithModel:(PLVHCLessonModel * _Nonnull)model title:(NSString * _Nullable)title line:(BOOL)isLine cellShape:(PLVHCLessonTableViewCellShape)cellShape;

+ (CGFloat)cellHeightWithText:(NSString * _Nonnull)text cellWidth:(CGFloat)cellWidth isTitle:(BOOL)isTitle;

@end

