//
//  PLVHCBrushToolButton.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 polyv. All rights reserved.
//  自定义画笔工具 视图
// PLVHCBrushToolBarView 视图的当前画笔工具按钮

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCBrushToolButton;

@protocol PLVHCBrushToolButtonDelegate <NSObject>

- (void)brushToolButtonDidTap:(PLVHCBrushToolButton *)brushToolButton;

@end

@interface PLVHCBrushToolButton : UIView

/// 点击 触发
@property (nonatomic, copy) void(^ _Nullable didTapButton)(void);

- (void)setImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
