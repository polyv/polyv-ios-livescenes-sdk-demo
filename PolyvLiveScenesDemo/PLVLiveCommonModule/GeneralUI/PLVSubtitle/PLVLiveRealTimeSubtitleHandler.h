//
//  PLVLiveRealTimeSubtitleHandler.h
//  PolyvLiveScenesDemo
//

#import <Foundation/Foundation.h>
#import "PLVLiveSubtitleModel.h"
#import "PLVLiveSubtitleTranslation.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLiveRealTimeSubtitleHandler;

/// 实时字幕更新回调协议
@protocol PLVLiveRealTimeSubtitleHandlerDelegate <NSObject>

@optional
/// 实时字幕更新（单条）
- (void)subtitleHandler:(PLVLiveRealTimeSubtitleHandler *)handler didUpdateRealTimeSubtitle:(nullable PLVLiveSubtitleModel *)subtitle;

/// 所有字幕更新（列表）
- (void)subtitleHandler:(PLVLiveRealTimeSubtitleHandler *)handler didUpdateAllSubtitles:(NSArray<PLVLiveSubtitleTranslation *> *)subtitles;

@end

/// 实时字幕处理核心类
@interface PLVLiveRealTimeSubtitleHandler : NSObject

/// 代理
@property (nonatomic, weak) id<PLVLiveRealTimeSubtitleHandlerDelegate> delegate;

/// 是否启用字幕
@property (nonatomic, assign, readonly) BOOL enableSubtitle;

/// 是否显示字幕
@property (nonatomic, assign, readonly) BOOL showSubtitle;

/// 原文字幕语言
@property (nonatomic, copy, readonly, nullable) NSString *originLanguage;

/// 翻译字幕语言
@property (nonatomic, copy, readonly, nullable) NSString *translateLanguage;

/// 默认显示双语字幕
@property (nonatomic, assign) BOOL bilingualSubtitleEnabled;

/// 初始化数据
/// @param channelId 频道ID
/// @param viewerId 观众ID
- (void)initDataWithChannelId:(NSString *)channelId viewerId:(NSString *)viewerId;

/// 处理Socket消息
/// @param event 事件类型（"ADD", "TRANSLATE", "ENABLE"）
/// @param message 消息内容（JSON字符串或字典）
- (void)handleSubtitleSocketMessage:(NSString *)event message:(id)message;

/// 设置翻译语言
/// @param language 语言代码
- (void)setTranslateLanguage:(NSString *)language;

/// 根据语言编码获取语言显示名称（静态方法）
/// @param languageCode 语言代码（如："zh-CN", "en-US", "origin"等）
/// @return 对应的语言显示名称，如果未找到则返回原始代码
+ (NSString *)languageNameForCode:(NSString *)languageCode;

@end

NS_ASSUME_NONNULL_END
