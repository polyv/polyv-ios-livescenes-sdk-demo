//
//  PLVHCDocumentMinimumBar.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/9.
//  Copyright © 2021 PLV. All rights reserved.
// 文档最小化后显示的 最小化数量悬浮按钮视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCDocumentMinimumBar;

@protocol PLVHCDocumentMinimumBarDelegate <NSObject>

/// 点击 按钮 回调
- (void)documentMinimumBarDidTap:(PLVHCDocumentMinimumBar *)documentMinimumBar;

@end

@interface PLVHCDocumentMinimumBar : UIView

@property (nonatomic, weak) id<PLVHCDocumentMinimumBarDelegate> delegate;

/// 设置最小化数量
/// @param total js返回的最小化数量数据
- (void)refreshPptContainerTotal:(NSInteger)total;

@end

NS_ASSUME_NONNULL_END
