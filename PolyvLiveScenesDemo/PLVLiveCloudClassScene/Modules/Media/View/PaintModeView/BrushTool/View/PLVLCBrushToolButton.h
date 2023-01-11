//
//  PLVLCBrushToolButton.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
//  自定义画笔工具 视图
// PLVLCBrushToolBarView 视图的当前画笔工具按钮

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVLCBrushToolButton;

@protocol PLVLCBrushToolButtonDelegate <NSObject>

- (void)brushToolButtonDidTap:(PLVLCBrushToolButton *)brushToolButton;

@end

@interface PLVLCBrushToolButton : UIView

/// 点击 触发
@property (nonatomic, copy) void(^ _Nullable didTapButton)(void);

- (void)setImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
