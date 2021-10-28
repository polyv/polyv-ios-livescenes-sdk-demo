//
//  PLVHCDocumentDeleteView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
// 文档列表页 PLVHCDocumentListView 长按 cell 时出现的红色气泡+删除按钮自定义 UIView

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCDocumentDeleteView;

@protocol PLVHCDocumentDeleteViewDelegate <NSObject>

/// 点击删除按钮时回调
- (void)documentDeleteView:(PLVHCDocumentDeleteView *)documentDeleteView didTapDeleteAtIndex:(NSInteger)index;

@end

@interface PLVHCDocumentDeleteView : UIView

/// 代理
@property (nonatomic, weak) id<PLVHCDocumentDeleteViewDelegate> delegate;

/// 当前下标
@property (nonatomic, assign) NSInteger index;

/// 显示在目标视图上层
/// @param view 目标视图
- (void)showInView:(UIView *)view;

/// 隐藏视图
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
