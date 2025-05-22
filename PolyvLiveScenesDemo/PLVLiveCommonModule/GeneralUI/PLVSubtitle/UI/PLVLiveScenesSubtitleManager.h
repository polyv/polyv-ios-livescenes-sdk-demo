//
//  PLVLiveScenesSubtitleManager.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/04/24.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVLiveScenesSubtitleItem.h"
#import "PLVLiveScenesSubtitleViewModel.h"

@interface PLVLiveScenesSubtitleManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<PLVLiveScenesSubtitleItem *> *subtitleItems;

@property (nonatomic, strong, readonly) NSMutableArray<PLVLiveScenesSubtitleItem *> *subtitleItems2;

// 仅底部字幕 单字幕模式
+ (instancetype)managerWithSubtitle:(NSString *)subtitle label:(UILabel *)subtitleLabel error:(NSError **)error;

// 底部字幕+顶部字幕 单字幕模式
+ (instancetype)managerWithSubtitle:(NSString *)subtitle label:(UILabel *)subtitleLabel topLabel:(UILabel *)subtitleTopLabel error:(NSError **)error;

- (void)showSubtitleWithTime:(NSTimeInterval)time;

// 底部字幕+顶部字幕 单字幕模式支持样式自定义
+ (instancetype)managerWithSubtitle:(NSString *)subtitle style:(PLVLiveScenesSubtitleItemStyle *)style label:(UILabel *)subtitleLabel topLabel:(UILabel *)subtitleTopLabel error:(NSError **)error;

/// 底部+顶部字幕 支持单字幕/双字幕模式
///
/// @note 仅配置subtitle或者subtitle2时，字幕显示于label和topLabel
///       同时配置subtitle或者subtitle2时，字幕subtitle显示于label2和topLabel，字幕subtitle2显示于label和topLabel2
/// @param subtitle 字幕内容
/// @param style 字幕样式
/// @param subtitleLabel 底部字幕（下）
/// @param subtitleTopLabel 顶部字幕（上）
/// @param subtitle2 第二份字幕内容
/// @param style2 字幕样式2
/// @param subtitleLabel2 底部字幕（上）
/// @param subtitleTopLabel2 顶部字幕（下）
+ (instancetype)managerWithSubtitle:(NSString *)subtitle style:(PLVLiveScenesSubtitleItemStyle *)style error:(NSError **)error subtitle2:(NSString *)subtitle2 style2:(PLVLiveScenesSubtitleItemStyle *)style2  error2:(NSError **)error2 label:(UILabel *)subtitleLabel topLabel:(UILabel *)subtitleTopLabel label2:(UILabel *)subtitleLabel2 topLabel2:(UILabel *)subtitleTopLabel2;

@end
