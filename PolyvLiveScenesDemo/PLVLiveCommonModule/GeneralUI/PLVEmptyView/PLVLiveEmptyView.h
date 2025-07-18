//
//  PLVLiveEmptyView.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2025/6/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLiveEmptyView : UIView

/// 空状态图标
@property (nonatomic, strong, readonly) UIImageView *iconView;

/// 空状态文本
@property (nonatomic, strong, readonly) UILabel *textLabel;

/// 图标大小
@property (nonatomic, assign) CGFloat iconSize;

/// 图标和文本间距
@property (nonatomic, assign) CGFloat iconTextSpacing;

/// 文本最大宽度
@property (nonatomic, assign) CGFloat textMaxWidth;

/// 图标颜色
@property (nonatomic, strong) UIColor *iconColor;

/// 文本颜色
@property (nonatomic, strong) UIColor *textColor;

/// 文本字体
@property (nonatomic, strong) UIFont *textFont;

/// 初始化方法
/// @param frame 框架
- (instancetype)initWithFrame:(CGRect)frame;

/// 设置空状态显示
/// @param icon 图标
/// @param text 文本
- (void)setEmptyStateWithIcon:(UIImage *)icon text:(NSString *)text;

/// 设置搜索无结果状态
- (void)setSearchNoResultState;

/// 设置自定义搜索无结果状态
/// @param text 自定义文本
- (void)setSearchNoResultStateWithText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END 
