//
//  PLVECSubtitleTranslationSelectView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/10/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECBottomView.h"
#import <PLVLiveScenesSDK/PLVPlaybackVideoInfoModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECSubtitleTranslationSelectView : PLVECBottomView

/// 选择回调
@property (nonatomic, copy) void(^selectionHandler)(PLVPlaybackSubtitleModel *selectedModel);

/// 设置字幕列表和当前选中项
/// @param subtitleList 翻译字幕列表
/// @param selectedModel 当前选中的字幕模型
- (void)setupWithSubtitleList:(NSArray<PLVPlaybackSubtitleModel *> *)subtitleList 
                selectedModel:(PLVPlaybackSubtitleModel * _Nullable)selectedModel;

/// 显示翻译选择视图
- (void)showInView:(UIView *)parentView;

/// 隐藏翻译选择视图
- (void)hide;

@end

NS_ASSUME_NONNULL_END
