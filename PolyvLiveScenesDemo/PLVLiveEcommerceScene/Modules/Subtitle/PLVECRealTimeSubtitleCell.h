//
//  PLVECRealTimeSubtitleCell.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2026/1/20.
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLiveSubtitleTranslation;

/// 字幕列表Cell
@interface PLVECRealTimeSubtitleCell : UITableViewCell

/// 配置Cell数据
/// @param subtitleTranslation 字幕翻译数据（包含原文和翻译）
/// @param showOrigin 是否显示原文
/// @param showTranslation 是否显示翻译
- (void)configureWithSubtitle:(PLVLiveSubtitleTranslation *)subtitleTranslation
                   showOrigin:(BOOL)showOrigin
               showTranslation:(BOOL)showTranslation;

/// 计算Cell高度
/// @param subtitleTranslation 字幕翻译数据
/// @param showOrigin 是否显示原文
/// @param showTranslation 是否显示翻译
/// @param width Cell宽度
+ (CGFloat)cellHeightWithSubtitle:(PLVLiveSubtitleTranslation *)subtitleTranslation
                       showOrigin:(BOOL)showOrigin
                  showTranslation:(BOOL)showTranslation
                            width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
