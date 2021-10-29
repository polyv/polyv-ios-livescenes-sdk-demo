//
//  PLVHCDocumentLoadingView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
// 加载文档页面进度条

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDocumentLoadingView : UIView

@property (nonatomic, strong) UIColor *color;

/// 开始动画
- (void)startAnimating;

/// 停止动画
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
