//
//  PLVLiveScenesSubtitleViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/04/24.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PLVLiveScenesSubtitleItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLiveScenesSubtitleItemStyle : NSObject

@property (nonatomic, strong) UIColor *textColor; // 字体颜色
@property (nonatomic, assign) BOOL bold; // 字体是否加粗
@property (nonatomic, assign) BOOL italic; // 字体是否
@property (nonatomic, strong) UIColor *backgroundColor; // 背景颜色
@property (nonatomic, assign) CGFloat fontSize;  // 添加字号属性

+ (instancetype)styleWithTextColor:(UIColor *)textColor bold:(BOOL)bold italic:(BOOL)italic backgroundColor:(UIColor *)backgroundColor;
+ (instancetype)styleWithTextColor:(UIColor *)textColor bold:(BOOL)bold italic:(BOOL)italic backgroundColor:(UIColor *)backgroundColor fontSize:(CGFloat)fontSize;  // 添加新的初始化方法

@end

@interface PLVLiveScenesSubtitleViewModel : NSObject

@property (nonatomic, strong) PLVLiveScenesSubtitleItem *subtitleItem;
@property (nonatomic, strong) PLVLiveScenesSubtitleItem *subtitleAtTopItem;
@property (nonatomic, strong) PLVLiveScenesSubtitleItem *subtitleItem2;
@property (nonatomic, strong) PLVLiveScenesSubtitleItem *subtitleAtTopItem2;

@property (nonatomic, weak)  UILabel *subtitleLabel;    // 底部字幕 下
@property (nonatomic, weak)  UILabel *subtitleTopLabel;
@property (nonatomic, weak)  UILabel *subtitleLabel2;   // 底部字幕 上
@property (nonatomic, weak)  UILabel *subtitleTopLabel2;

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, strong) PLVLiveScenesSubtitleItemStyle *subtitleItemStyle;
@property (nonatomic, strong) PLVLiveScenesSubtitleItemStyle *subtitleAtTopItemStyle;
@property (nonatomic, strong) PLVLiveScenesSubtitleItemStyle *subtitleItemStyle2;
@property (nonatomic, strong) PLVLiveScenesSubtitleItemStyle *subtitleAtTopItemStyle2;

- (void)setSubtitleLabel:(UILabel *)subtitleLabel style:(PLVLiveScenesSubtitleItemStyle *)style;
- (void)setSubtitleTopLabel:(UILabel *)subtitleTopLabel style:(PLVLiveScenesSubtitleItemStyle *)style;
- (void)setSubtitleLabel2:(UILabel *)subtitleLabel2 style:(PLVLiveScenesSubtitleItemStyle *)style;
- (void)setSubtitleTopLabel2:(UILabel *)subtitleTopLabel2 style:(PLVLiveScenesSubtitleItemStyle *)style;

@end

NS_ASSUME_NONNULL_END
