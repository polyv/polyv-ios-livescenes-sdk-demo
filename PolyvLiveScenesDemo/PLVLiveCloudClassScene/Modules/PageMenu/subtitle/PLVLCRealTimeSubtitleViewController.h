//
//  PLVLCRealTimeSubtitleViewController.h
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCRealTimeSubtitleViewController;
@class PLVLiveSubtitleTranslation;

/// 实时字幕控制器代理
@protocol PLVLCRealTimeSubtitleViewControllerDelegate <NSObject>

@optional
/// 设置翻译语言
- (void)realTimeSubtitleViewController:(PLVLCRealTimeSubtitleViewController *)viewController
                 didSetTranslateLanguage:(NSString *)language;

@end

/// 云课堂实时字幕列表控制器
@interface PLVLCRealTimeSubtitleViewController : UIViewController

/// 代理
@property (nonatomic, weak) id<PLVLCRealTimeSubtitleViewControllerDelegate> delegate;

/// 初始化
/// @param channelId 频道ID
/// @param viewerId 观众ID
/// @param originLanguage 原文语言代码
/// @param translateLanguage
/// @param availableLanguages 可用的翻译语言列表
- (instancetype)initWithChannelId:(NSString *)channelId
                         viewerId:(NSString *)viewerId
                   originLanguage:(nullable NSString *)originLanguage
                translateLanguage:(nullable NSString *)translateLanguage
               availableLanguages:(nullable NSArray<NSString *> *)availableLanguages;

/// 更新字幕列表
/// @param subtitles 字幕翻译数组
- (void)updateSubtitles:(NSArray<PLVLiveSubtitleTranslation *> *)subtitles;

@end

NS_ASSUME_NONNULL_END
