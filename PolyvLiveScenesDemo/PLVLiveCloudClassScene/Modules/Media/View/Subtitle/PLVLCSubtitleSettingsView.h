//
//  PLVLCSubtitleSettingsView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/5/8.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVPlaybackVideoInfoModel.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCSubtitleSettingsView;

@protocol PLVLCSubtitleSettingsViewDelegate <NSObject>

// 字幕设置变更回调
- (void)PLVLCSubtitleSettingsView:(PLVLCSubtitleSettingsView *)settingsView
           didUpdateSubtitleState:(PLVPlaybackSubtitleModel * _Nullable)originalSubtitle
                translateSubtitle:(PLVPlaybackSubtitleModel * _Nullable)translateSubtitle;

@end

@interface PLVLCSubtitleSettingsView : UIView

@property (nonatomic, weak) id<PLVLCSubtitleSettingsViewDelegate> delegate;

// 当前状态
@property (nonatomic, assign, readonly) BOOL originalEnabled;     // 原声字幕启用状态
@property (nonatomic, assign, readonly) BOOL translateEnabled;    // 翻译字幕启用状态
@property (nonatomic, strong, readonly) PLVPlaybackSubtitleModel *currentTranslateSubtitle;  // 当前选中的翻译字幕

// 数据源
@property (nonatomic, strong, readonly) NSArray<PLVPlaybackSubtitleModel *> *subtitleList;     // 全部字幕列表
@property (nonatomic, strong, readonly) NSArray<PLVPlaybackSubtitleModel *> *originalSubtitles; // 原声字幕列表
@property (nonatomic, strong, readonly) NSArray<PLVPlaybackSubtitleModel *> *translateSubtitles; // 翻译字幕列表

// 设置字幕列表数据
- (void)setupWithSubtitleList:(NSArray<NSDictionary *> *)subtitleList;

// 手动更新语言选择按钮文本
- (void)updateLanguageButtonWithLanguage:(NSString *)language;

@end

NS_ASSUME_NONNULL_END
