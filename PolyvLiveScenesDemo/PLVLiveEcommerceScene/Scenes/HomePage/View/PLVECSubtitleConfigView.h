//
//  PLVECSubtitleConfigView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/10/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECBottomSheet.h"
#import <PLVLiveScenesSDK/PLVPlaybackVideoInfoModel.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECSubtitleConfigView;

@protocol PLVECSubtitleConfigViewDelegate <NSObject>

@optional

/// 字幕设置变更回调
/// @param configView 字幕配置视图
/// @param originalSubtitle 当前勾选的原声字幕，nil 表示关闭
/// @param translateSubtitle 当前勾选的翻译字幕，nil 表示关闭
- (void)subtitleConfigView:(PLVECSubtitleConfigView *)configView
    didUpdateSubtitleOriginal:(PLVPlaybackSubtitleModel * _Nullable)originalSubtitle
                    translate:(PLVPlaybackSubtitleModel * _Nullable)translateSubtitle;

@end

@interface PLVECSubtitleConfigView : PLVECBottomSheet

@property (nonatomic, weak) id<PLVECSubtitleConfigViewDelegate> delegate;

/// 当前状态
@property (nonatomic, assign, readonly) BOOL originalEnabled;     // 原声字幕启用状态
@property (nonatomic, assign, readonly) BOOL translateEnabled;    // 翻译字幕启用状态
@property (nonatomic, strong, readonly) PLVPlaybackSubtitleModel *currentOriginalSubtitle;  // 当前选中的原声字幕
@property (nonatomic, strong, readonly) PLVPlaybackSubtitleModel *currentTranslateSubtitle;  // 当前选中的翻译字幕

/// 设置字幕列表数据
/// @param subtitleList 字幕列表数据
- (void)setupWithSubtitleList:(NSArray<PLVPlaybackSubtitleModel *> *)subtitleList;

/// 显示字幕配置视图
- (void)showInView:(UIView *)parentView;

/// 隐藏字幕配置视图
- (void)hide;

@end

NS_ASSUME_NONNULL_END
