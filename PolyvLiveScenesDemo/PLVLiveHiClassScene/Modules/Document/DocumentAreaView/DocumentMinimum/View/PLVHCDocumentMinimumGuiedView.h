//
//  PLVHCDocumentMinimumGuiedView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/26.
//  Copyright © 2021 PLV. All rights reserved.
// 文档最小化新手引导视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDocumentMinimumGuiedView : UIView

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 隐藏列表视图
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
