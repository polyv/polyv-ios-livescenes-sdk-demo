//
//  PLVECRealTimeSubtitleLanguageSelectView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/01/15.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECBottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECRealTimeSubtitleLanguageSelectView : PLVECBottomSheet

/// 选择回调
@property (nonatomic, copy) void(^selectionHandler)(NSString *selectedLanguage);

/// 设置语言列表和当前选中项
/// @param languages 语言代码数组（如：@[@"origin", @"zh-CN", @"en-US"]）
/// @param selectedLanguage 当前选中的语言代码
- (void)setupWithLanguages:(NSArray<NSString *> *)languages 
           selectedLanguage:(NSString * _Nullable)selectedLanguage;

/// 显示语言选择视图
- (void)showInView:(UIView *)parentView;

/// 隐藏语言选择视图
- (void)hide;

@end

NS_ASSUME_NONNULL_END
