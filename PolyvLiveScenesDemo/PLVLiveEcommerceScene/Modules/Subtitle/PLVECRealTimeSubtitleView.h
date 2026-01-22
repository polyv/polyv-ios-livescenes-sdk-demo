//
//  PLVECRealTimeSubtitleView.h
//  PolyvLiveScenesDemo
//

#import <UIKit/UIKit.h>
#import "PLVLiveSubtitleTranslation.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVECRealTimeSubtitleView;
@class PLVLiveRealTimeSubtitleHandler;

/// 字幕视图代理
@protocol PLVECRealTimeSubtitleViewDelegate <NSObject>

@optional
/// 设置翻译语言
- (void)realTimeSubtitleView:(PLVECRealTimeSubtitleView *)view 
    didSetTranslateLanguage:(NSString *)language;

/// 关闭字幕
- (void)realTimeSubtitleViewDidClose:(PLVECRealTimeSubtitleView *)view;

@end

/// 实时字幕视图（电商场景 - 支持列表显示）
@interface PLVECRealTimeSubtitleView : UIView

@property (nonatomic, weak) id<PLVECRealTimeSubtitleViewDelegate> delegate;
/// 是否处于展开状态（只读）
@property (nonatomic, readonly) BOOL isExpanded;

/// 初始化数据
- (void)initDataWithChannelId:(NSString *)channelId viewerId:(NSString *)viewerId;

/// 更新字幕列表
- (void)updateSubtitles:(NSArray<PLVLiveSubtitleTranslation *> *)subtitles;

/// 展开/收起
- (void)expand;
- (void)collapse;

/// 显示设置弹窗
- (void)showSettingPopupMenu;

/// 获取字幕处理器（用于外部处理Socket消息）
- (PLVLiveRealTimeSubtitleHandler *)subtitleHandler;

/// 设置双语字幕模式（同时显示原文和译文）
/// @param enabled YES: 双语模式，NO: 仅显示译文（或原文）
- (void)setBilingualEnabled:(BOOL)enabled;

/// 应用语言选择与双语开关（以配置为准刷新显示）
/// @param language @"origin" 表示原文不翻译；其它为翻译语种（如 @"zh-CN" @"ko-KR"）
/// @param bilingualEnabled YES: 同时显示原文+译文；NO: 仅显示原文或仅显示译文（由 language 决定）
- (void)applySelectedLanguage:(NSString *)language
             bilingualEnabled:(BOOL)bilingualEnabled;

/// 设置字幕启用状态（控制整个视图的显示/隐藏）
/// @param enabled YES: 启用字幕，NO: 禁用字幕
- (void)setSubtitleEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
