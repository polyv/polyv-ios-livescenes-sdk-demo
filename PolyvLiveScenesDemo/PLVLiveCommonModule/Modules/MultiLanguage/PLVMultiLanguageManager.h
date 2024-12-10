//
//  PLVMultiLanguageManager.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/9/4.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define PLVLocalizedString(key) [PLVMultiLanguageManager localizedStringForKey:key]

typedef void (^PLVLanguageUpdateCompletionCallback)(void);

typedef NS_ENUM(NSInteger, PLVMultiLanguageMode) {
    PLVMultiLanguageModeSyetem = 0,
    PLVMultiLanguageModeZH,
    PLVMultiLanguageModeEN,
    PLVMultiLanguageModeZH_HK,
    PLVMultiLanguageModeJA,
    PLVMultiLanguageModeKO,
};

typedef NS_ENUM(NSInteger, PLVMultiLanguageLiveScene) {
    PLVMultiLanguageLiveSceneUnknown = 0,
    PLVMultiLanguageLiveSceneLC,    // 云课堂场景
    PLVMultiLanguageLiveSceneEC,    // 直播带货场景
    PLVMultiLanguageLiveSceneLS,    // 三分屏手机开播场景
    PLVMultiLanguageLiveSceneSA,    // 纯视频手机开播场景
};

@interface PLVMultiLanguageManager : NSObject

/// 语言更新的回调
@property (nonatomic, copy) PLVLanguageUpdateCompletionCallback languageUpdateCallback;

#pragma mark - API

/// 单例方法
+ (instancetype)sharedManager;

/// 设置本地语言包
/// @param liveScene 当前场景
/// @param channelId 当前频道
/// @param language 当前的配置语言，（配置语言可为空，为空时会使用系统语言配置）zh_CN 中文、en英文、follow_browser跟随系统
- (void)setupLocalizedLiveScene:(PLVMultiLanguageLiveScene)liveScene channelId:(NSString *)channelId language:(NSString * _Nullable)language;

/// 获取用户在App内选中的语言，如果用户未选中默认是System，则使用系统语言
- (PLVMultiLanguageMode)selectedLanguage;
/// 获取用户在系统选中的语言
- (PLVMultiLanguageMode)systemSelectedLanguage;
/// 当前语言
/// 根据selectedLanguage、systemSelectedLanguage、后台配置最终使用到的语言
/// 如果用户在App选择则优先使用，否则使用后台配置了语言，未配置则使用系统语言
/// App内选中的语言 > 后台配置语言 > 系统配置语言
- (PLVMultiLanguageMode)currentLanguage;

/// 更新应用内的语言
/// @param mode 语言
- (void)updateLanguage:(PLVMultiLanguageMode)mode;

/// 将 text 翻译成对应的语言
+ (NSString *)localizedStringForKey:(NSString *)key;
+ (NSString *)localizedStringForKey:(NSString *)key value:(nullable NSString *)value;

@end

NS_ASSUME_NONNULL_END
