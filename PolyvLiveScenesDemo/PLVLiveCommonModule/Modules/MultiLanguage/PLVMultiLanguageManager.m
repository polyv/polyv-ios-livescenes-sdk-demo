//
//  PLVMultiLanguageManager.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/9/4.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <MJRefresh/MJRefreshConfig.h>

@interface PLVMultiLanguageManager ()

/// 多语言对应的文件名
@property (nonatomic, copy) NSString *tableName;
/// 应用内选中的语言
@property (nonatomic, assign) PLVMultiLanguageMode selectedLanguage;
/// 后台配置的语言
@property (nonatomic, assign) PLVMultiLanguageMode configLanguage;
/// 场景的语言 Bundle
@property (nonatomic, strong) NSBundle *languageModuleBundle;
/// 对应语言资源的路径
@property (nonatomic, copy) NSString *lprojPath;
/// 本地频道 id
@property (nonatomic, copy) NSString *channelId;
/// 播放场景
@property (nonatomic, assign) PLVMultiLanguageLiveScene liveScene;
/// 多语言本地偏好设置的Key
@property (nonatomic, copy, readonly) NSString *languagePreferenceKey;

/// Common 对应语言资源的路径
@property (nonatomic, copy) NSString *commonLprojPath;
/// Common的语言 Bundle
@property (nonatomic, strong) NSBundle *commonLanguageBundle;

@end

@implementation PLVMultiLanguageManager

#pragma mark - [ Life Period ]

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static PLVMultiLanguageManager *mananger = nil;
    dispatch_once(&onceToken, ^{
        mananger = [[self alloc] init];
    });
    return mananger;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tableName = @"Localizable";

        [self setupFDLocalizableConfig];
        [self updateLanguageLprojPath];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)setupLocalizedLiveScene:(PLVMultiLanguageLiveScene)liveScene channelId:(NSString *)channelId language:(NSString * _Nullable)language {
    _liveScene = liveScene;
    _channelId = channelId;

    /// 系统配置语言
    PLVMultiLanguageMode languageMode = PLVMultiLanguageModeSyetem;
    if ([PLVFdUtil checkStringUseable:language]) {
        if ([language isEqualToString:@"zh_CN"]) {
            languageMode = PLVMultiLanguageModeZH;
        } else if ([language isEqualToString:@"en"]) {
            languageMode = PLVMultiLanguageModeEN;
        } else if ([language isEqualToString:@"follow_browser"]) {
            languageMode = PLVMultiLanguageModeSyetem;
        }
    }
    _configLanguage = languageMode;
    
    NSString *resourceName = @"Languages";
    switch (liveScene) {
        case PLVMultiLanguageLiveSceneLC:
            resourceName = @"PLVLCLocalizable";
            break;
        case PLVMultiLanguageLiveSceneEC:
            resourceName = @"PLVECLocalizable";
            break;
        case PLVMultiLanguageLiveSceneLS:
            resourceName = @"PLVLSLocalizable";
            break;
        case PLVMultiLanguageLiveSceneSA:
            resourceName = @"PLVSALocalizable";
            break;
        default:
            break;
    }
    
    _languageModuleBundle = [self localizableBundleWithResourceName:resourceName];
    _selectedLanguage = [self readUserLanguagePreference];
    
    /// 切换语言模式，需要重制一次语言模型路径
    [self updateLanguageLprojPath];
}

- (void)updateLanguage:(PLVMultiLanguageMode)mode {
    if (_selectedLanguage == mode) {
        return;
    }
    
    _selectedLanguage = mode;
    [self saveUserLanguagePreference];
    /// 切换语言模式，需要重制一次语言模型路径
    [self updateLanguageLprojPath];
    
    [NSUserDefaults.standardUserDefaults setInteger:_selectedLanguage forKey:self.languagePreferenceKey];
    
    _languageUpdateCallback ? _languageUpdateCallback() : nil;
}

- (PLVMultiLanguageMode)systemSelectedLanguage {
    /// 获取系统语言
    PLVMultiLanguageMode mode = PLVMultiLanguageModeEN;
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *systemlanguage = [languages objectAtIndex:0];
    if ([systemlanguage containsString:@"zh-Hans"] || [systemlanguage containsString:@"zh-Hant"]) {
        mode = PLVMultiLanguageModeZH;
    } else if ([systemlanguage containsString:@"en"]) {
        mode = PLVMultiLanguageModeEN;
    }
    
    return mode;
}

- (PLVMultiLanguageMode)currentLanguage {
    if (_selectedLanguage != PLVMultiLanguageModeSyetem) {
        return _selectedLanguage;
    }
    if (_configLanguage != PLVMultiLanguageModeSyetem) {
        return _configLanguage;
    }
    
    return [self systemSelectedLanguage];
}

+ (NSString *)localizedStringForKey:(NSString *)key {
    return [PLVMultiLanguageManager localizedStringForKey:key value:nil];
}

+ (NSString *)localizedStringForKey:(NSString *)key value:(nullable NSString *)value {
    if (![PLVFdUtil checkStringUseable:key]) {
        return key;
    }
    
    NSBundle *bundlePath = [NSBundle bundleWithPath:[PLVMultiLanguageManager sharedManager].lprojPath];
    if (bundlePath != nil) {
        value = [bundlePath localizedStringForKey:key value:value table:[PLVMultiLanguageManager sharedManager].tableName];
    }
    
    if ([value isEqualToString:key] || ![PLVFdUtil checkStringUseable:value]) {
        NSBundle *commonBundlePath = [NSBundle bundleWithPath:[PLVMultiLanguageManager sharedManager].commonLprojPath];
        if (commonBundlePath != nil) {
            value = [commonBundlePath localizedStringForKey:key value:value table:[PLVMultiLanguageManager sharedManager].tableName];
        }
    }
    
    NSString *resultStr = [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
    return resultStr;
}

#pragma mark - [ Private Methods ]

- (void)setupFDLocalizableConfig {
    /// 设置SDK 资源包路径
    NSBundle *localizableBundle = [self localizableBundleWithResourceName:@"PLVFDLocalizable"];
    [[PLVFDI18NUtil sharedInstance] setupLocalizableBundle:localizableBundle];
}

/// 更新语言
- (void)updateLanguageLprojPath {
    NSString *appLanguage = @"en";
    if (self.currentLanguage == PLVMultiLanguageModeZH) {
        appLanguage = @"zh-Hans";
    }
    
    /// 更新SDK 语言
    [PLVFDI18NUtil sharedInstance].preferredLanguage = appLanguage;
    
    /// 更新Common 和 Scenes 语言
    _lprojPath = [self.languageModuleBundle pathForResource:appLanguage ofType:@"lproj"];
    _commonLprojPath = [self.commonLanguageBundle pathForResource:appLanguage ofType:@"lproj"];
    
    /// 更新 其他SDK 语言
    [MJRefreshConfig defaultConfig].languageCode = appLanguage;
}

- (PLVMultiLanguageMode)readUserLanguagePreference {
    PLVMultiLanguageMode selectedLanguageMode = [NSUserDefaults.standardUserDefaults integerForKey:self.languagePreferenceKey];
    return selectedLanguageMode;
}

- (void)saveUserLanguagePreference {
    [NSUserDefaults.standardUserDefaults setInteger:_selectedLanguage forKey:self.languagePreferenceKey];
}

- (NSBundle *)localizableBundleWithResourceName:(NSString *)resourceName {
    NSString *bundlePath = [[NSBundle bundleForClass:self.class] pathForResource:resourceName ofType:@"bundle"];
    if (!bundlePath) {
        bundlePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"bundle"];
    }
    return [NSBundle bundleWithPath:bundlePath];
}

#pragma mark Getter
- (NSBundle *)commonLanguageBundle {
    if (!_commonLanguageBundle) {
        _commonLanguageBundle = [self localizableBundleWithResourceName:@"PLVCMLocalizable"];
    }
    return _commonLanguageBundle;
}

- (NSString *)languagePreferenceKey {
    if (![PLVFdUtil checkStringUseable:self.channelId]) {
        return @"";
    }
    
    NSString *liveSceneKey = self.liveScene > PLVMultiLanguageLiveSceneEC ? @"LiveStream" : @"LiveWatch";
    NSString *preferenceKey = [NSString stringWithFormat:@"PLVMultiLanguageManager.Preference.%@-%@", liveSceneKey, self.channelId];
    return preferenceKey;
}

@end
