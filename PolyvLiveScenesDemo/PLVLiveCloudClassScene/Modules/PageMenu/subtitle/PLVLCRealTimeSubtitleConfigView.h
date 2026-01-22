//
//  PLVLCRealTimeSubtitleConfigView.h
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCBottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLCRealTimeSubtitleConfigView;

@protocol PLVLCRealTimeSubtitleConfigViewDelegate <NSObject>

@optional

/// 实时字幕总开关状态变更回调
/// @param configView 实时字幕配置视图
/// @param enabled 是否开启实时字幕
- (void)realTimeSubtitleConfigView:(PLVLCRealTimeSubtitleConfigView *)configView
                   didChangeEnabled:(BOOL)enabled;

/// 双语字幕开关状态变更回调
/// @param configView 实时字幕配置视图
/// @param enabled 是否显示双语字幕
- (void)realTimeSubtitleConfigView:(PLVLCRealTimeSubtitleConfigView *)configView
              didChangeBilingualEnabled:(BOOL)enabled;

/// 字幕语言选择变更回调
/// @param configView 实时字幕配置视图
/// @param language 选择的语言代码（如："zh-CN", "en-US", "origin" 表示原文不翻译）
- (void)realTimeSubtitleConfigView:(PLVLCRealTimeSubtitleConfigView *)configView
                didSelectLanguage:(NSString *)language;

@end

@interface PLVLCRealTimeSubtitleConfigView : PLVLCBottomSheet

@property (nonatomic, weak) id<PLVLCRealTimeSubtitleConfigViewDelegate> delegate;

/// 当前状态
@property (nonatomic, assign, readonly) BOOL subtitleEnabled;      // 实时字幕启用状态
@property (nonatomic, assign, readonly) BOOL bilingualEnabled;     // 双语字幕启用状态
@property (nonatomic, copy, readonly) NSString *selectedLanguage;  // 当前选中的语言代码

/// 设置可用的翻译语言列表
/// @param languages 语言代码数组（如：@[@"zh-CN", @"en-US", @"ja-JP"]）
- (void)setupWithAvailableLanguages:(NSArray<NSString *> *)languages;

/// 设置当前状态（外部调用，用于初始化或同步状态）
/// @param enabled 实时字幕开关状态
/// @param bilingualEnabled 双语字幕开关状态
/// @param language 当前选中的语言代码
- (void)updateState:(BOOL)enabled
   bilingualEnabled:(BOOL)bilingualEnabled
   selectedLanguage:(NSString *)language;

/// 显示实时字幕配置视图
- (void)showInView:(UIView *)parentView;

/// 隐藏实时字幕配置视图
- (void)hide;

@end

NS_ASSUME_NONNULL_END
