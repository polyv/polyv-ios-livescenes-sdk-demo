//
//  PLVLiveScenesSubtitleView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/4/24.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLiveScenesSubtitleView : UIView

/// 主字幕是否隐藏
@property (nonatomic, assign) BOOL *fisrtSubtitleHidden;
/// 第二字幕是否隐藏
@property (nonatomic, assign) BOOL *secondSubtitleHidden;
/// 主字幕标签（底部字幕）
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
/// 第二字幕标签（底部字幕上方）
@property (nonatomic, strong, readonly) UILabel *subtitleLabel2;
/// 主字幕顶部标签
@property (nonatomic, strong, readonly) UILabel *subtitleTopLabel;
/// 第二字幕顶部标签
@property (nonatomic, strong, readonly) UILabel *subtitleTopLabel2;

/// 初始化字幕视图（支持两种字幕样式）
/// @param backgroundColor 背景颜色
/// @param fontSize1 第一字幕字号
/// @param textColor1 第一字幕颜色
/// @param fontSize2 第二字幕字号
/// @param textColor2 第二字幕颜色
- (instancetype)initBackgroundColor:(UIColor *)backgroundColor
                          fontSize1:(CGFloat)fontSize1
                         textColor1:(UIColor *)textColor1
                          fontSize2:(CGFloat)fontSize2
                         textColor2:(UIColor *)textColor2;

/// 更新字幕视图
- (void)update;

/// 字幕显示
/// @param playtime 播放时间
- (void)showSubtilesWithPlaytime:(NSTimeInterval)playtime;

/// 设置两个字幕内容
/// @param subtitleContent1 第一字幕内容（SRT格式）
/// @param subtitleContent2 第二字幕内容（SRT格式）
- (void)setSubtitleContent1:(NSString * _Nullable)subtitleContent1 subtitleContent2:(NSString * _Nullable)subtitleContent2;

@end

NS_ASSUME_NONNULL_END
