//
//  PLVECRealTimeSubtitleManager.h
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024年 plv.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECRealTimeSubtitleView;
@class PLVECRealTimeSubtitleConfigView;
@class PLVECRealTimeSubtitleManager;

/// 实时字幕管理器代理
@protocol PLVECRealTimeSubtitleManagerDelegate <NSObject>

@optional
/// 设置翻译语言（用于外部处理Socket消息）
- (void)realTimeSubtitleManager:(PLVECRealTimeSubtitleManager *)manager 
         didSetTranslateLanguage:(NSString *)language;

/// 关闭字幕
- (void)realTimeSubtitleManagerDidClose:(PLVECRealTimeSubtitleManager *)manager;

@end

/// 实时字幕管理器（封装字幕视图和设置视图的管理逻辑）
@interface PLVECRealTimeSubtitleManager : NSObject

/// 代理
@property (nonatomic, weak) id<PLVECRealTimeSubtitleManagerDelegate> delegate;

/// 字幕视图
@property (nonatomic, strong, readonly) PLVECRealTimeSubtitleView *subtitleView;

/// 设置视图
@property (nonatomic, strong, readonly) PLVECRealTimeSubtitleConfigView *configView;

/// 初始化管理器
- (instancetype)init;

/// 在指定的父视图中设置字幕功能
/// @param parentView 父视图
/// @param channelId 频道ID
/// @param viewerId 观众ID
/// @param availableLanguages 可用的翻译语言列表（从 menuInfo.realTimeSubtitleConfig.subtitleTranslationLanguages 获取）
- (void)setupInView:(UIView *)parentView
          channelId:(NSString *)channelId
           viewerId:(NSString *)viewerId
 availableLanguages:(NSArray<NSString *> * _Nullable)availableLanguages;

/// 显示设置视图
- (void)showConfigView;

/// 更新字幕视图的布局（当父视图大小改变时调用）
- (void)updateSubtitleViewLayout;

/// 处理Socket消息（需要外部调用）
/// @param event 事件类型（"ADD", "TRANSLATE", "ENABLE"）
/// @param message 消息内容
- (void)handleSubtitleSocketMessage:(NSString *)event message:(id)message;

@end

NS_ASSUME_NONNULL_END
