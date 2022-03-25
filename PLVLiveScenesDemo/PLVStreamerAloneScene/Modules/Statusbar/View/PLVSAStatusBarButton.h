//
//  PLVSAStatusBarButton.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/28.
//  Copyright © 2021 PLV. All rights reserved.
//  状态栏-自定义按钮

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSAStatusBarButton : UIView

#pragma mark UI

/// 标题，默认为nil
@property (nonatomic, copy) NSString *text;

/// 标题颜色，默认为白色
@property (nonatomic, strong) UIColor *textColor;

/// 标题字体，默认为[UIFont systemFontOfSize:12]
@property (nonatomic, strong) UIFont *font;

/// 标题左边间距，默认为2
@property (nonatomic, assign) CGFloat titlePaddingX;

#pragma mark 点击事件

/// 点击 触发
@property (nonatomic, copy) void(^ _Nullable didTapHandler)(void);

#pragma mark 设置图片

/// 设置图片
/// @param image 图片
- (void)setImage:(UIImage *)image;

/// 设置图片
/// @param image 图片
/// @param indicatorImage 指示器图片，表示可以点击，可设置为空
- (void)setImage:(UIImage *)image indicatorImage:(UIImage * _Nullable)indicatorImage;


@end

NS_ASSUME_NONNULL_END
