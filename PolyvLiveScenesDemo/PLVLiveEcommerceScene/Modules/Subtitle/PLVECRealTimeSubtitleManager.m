//
//  PLVECRealTimeSubtitleManager.m
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024年 plv.net. All rights reserved.
//

#import "PLVECRealTimeSubtitleManager.h"
#import "PLVECRealTimeSubtitleView.h"
#import "PLVECRealTimeSubtitleConfigView.h"
#import "PLVLiveRealTimeSubtitleHandler.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

@interface PLVECRealTimeSubtitleManager () <PLVECRealTimeSubtitleViewDelegate, PLVECRealTimeSubtitleConfigViewDelegate>

@property (nonatomic, strong) PLVECRealTimeSubtitleView *subtitleView;
@property (nonatomic, strong) PLVECRealTimeSubtitleConfigView *configView;
@property (nonatomic, weak) UIView *parentView;

@end

@implementation PLVECRealTimeSubtitleManager

- (instancetype)init {
    if (self = [super init]) {
        // 初始化字幕视图
        self.subtitleView = [[PLVECRealTimeSubtitleView alloc] initWithFrame:CGRectZero];
        self.subtitleView.delegate = self;
        self.subtitleView.hidden = YES;
        
        // 初始化设置视图
        self.configView = [[PLVECRealTimeSubtitleConfigView alloc] init];
        self.configView.delegate = self;
    }
    return self;
}

- (void)setupInView:(UIView *)parentView
          channelId:(NSString *)channelId
           viewerId:(NSString *)viewerId
 availableLanguages:(NSArray<NSString *> *)availableLanguages {
    if (!parentView) {
        return;
    }
    
    self.parentView = parentView;
    
    // 初始化字幕视图数据
    [self.subtitleView initDataWithChannelId:channelId viewerId:viewerId];
    
    // 设置初始 frame（使用布局方法统一处理）
    [self updateSubtitleViewLayout];
    
    // 将字幕视图添加到父视图
    if (self.subtitleView.superview == nil) {
        [parentView addSubview:self.subtitleView];
    }
    [parentView bringSubviewToFront:self.subtitleView];
    self.subtitleView.userInteractionEnabled = YES;
    
    // 设置可用语言列表
    [self.configView setupWithAvailableLanguages:availableLanguages];
    
    // 从本地恢复之前的设置
    [self restoreSettings];
}

- (void)showConfigView {
    if (!self.parentView) {
        return;
    }
    
    // 从本地恢复设置状态
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"PLVECRealTimeSubtitleEnabled"];
    
    // 更新设置视图的状态
    NSString *language = [self.subtitleView subtitleHandler].translateLanguage;
    BOOL bilingualEnabled = [self.subtitleView subtitleHandler].bilingualSubtitleEnabled;
    [self.configView updateState:enabled
                bilingualEnabled:bilingualEnabled
                selectedLanguage:language];
    
    // 显示设置界面在最顶层的 window，确保覆盖字幕视图
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        // iOS 13+ 获取 keyWindow
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    } else {
        // iOS 13 以下
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    // 如果找不到 keyWindow，使用视图控制器的视图
    if (!keyWindow) {
        UIViewController *topViewController = [self findTopViewControllerFromView:self.parentView];
        if (topViewController) {
            [self.configView showInView:topViewController.view];
        } else {
            [self.configView showInView:self.parentView];
        }
    } else {
        // 在 keyWindow 上显示，确保在最上层
        [self.configView showInView:keyWindow];
    }
}

- (void)updateSubtitleViewLayout {
    if (!self.subtitleView || !self.subtitleView.superview || !self.parentView) {
        return;
    }
    
    CGFloat margin = 12.0f;
    CGFloat parentWidth = self.parentView.bounds.size.width;
    CGFloat parentHeight = self.parentView.bounds.size.height;
    
    // 判断是否为横屏（宽度大于高度）
    BOOL isLandscape = parentWidth > parentHeight;
    
    // 计算宽度
    CGFloat width;
    if (isLandscape) {
        // 横屏时：宽度使用屏幕高度（因为横屏时屏幕高度就是竖屏时的宽度）
        // 这样可以保持与竖屏时一致的阅读宽度，避免横屏时字幕过宽
        CGFloat screenHeight = parentHeight; // 横屏时的屏幕高度
        width = screenHeight - margin * 2;
        
        // 确保宽度不超过父视图宽度（安全限制）
        CGFloat maxWidth = parentWidth - margin * 2;
        width = MIN(width, maxWidth);
        
        // 确保宽度不会过窄（最小宽度限制，避免在小屏设备上显示异常）
        CGFloat minWidth = 300.0f; // 最小宽度300px
        width = MAX(width, minWidth);
    } else {
        // 竖屏时：使用父视图宽度减去边距
        width = parentWidth - margin * 2;
    }
    
    // 根据展开状态设置高度
    CGFloat height = self.subtitleView.isExpanded ? 260.0f : 106.0f;
    
    CGRect currentFrame = self.subtitleView.frame;
    CGFloat top, left;
    
    // 判断是否需要设置初始位置（首次布局或frame为空）
    BOOL firstLayout = (CGRectIsEmpty(currentFrame) ||
                        (currentFrame.origin.x == 0 && currentFrame.origin.y == 0 && currentFrame.size.width == 0));
    if (firstLayout) {
        // 首次布局：默认距离底部 400px
        top = parentHeight - 400.0f;
        // 横屏不强制居中；竖屏保持居中
        left = isLandscape ? margin : (parentWidth - width) / 2.0f;
    } else {
        // 已有位置：保持当前位置
        top = currentFrame.origin.y;
        // 横屏不需要水平居中：保持当前 x；竖屏宽度变化时重新居中
        left = isLandscape ? currentFrame.origin.x : (parentWidth - width) / 2.0f;
    }
    
    // 安全兜底：确保不超出父视图边界
    width = MIN(width, parentWidth);
    height = MIN(height, parentHeight);
    
    CGFloat minX = 0.0f;
    CGFloat minY = 0.0f;
    CGFloat maxX = MAX(minX, parentWidth - width);
    CGFloat maxY = MAX(minY, parentHeight - height);
    
    left = MAX(minX, MIN(maxX, left));
    top = MAX(minY, MIN(maxY, top));
    
    self.subtitleView.frame = CGRectMake(left, top, width, height);
    
    // 确保字幕视图在父视图中的最上层（但不会覆盖 window 级别的弹出框）
    [self.parentView bringSubviewToFront:self.subtitleView];
}

- (void)handleSubtitleSocketMessage:(NSString *)event message:(id)message {
    PLVLiveRealTimeSubtitleHandler *subtitleHandler = [self.subtitleView subtitleHandler];
    if (subtitleHandler) {
        [subtitleHandler handleSubtitleSocketMessage:event message:message];
    }
}

#pragma mark - Private Methods

/// 从视图找到最顶层的视图控制器
- (UIViewController *)findTopViewControllerFromView:(UIView *)view {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

/// 从本地恢复设置
- (void)restoreSettings {
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"PLVECRealTimeSubtitleEnabled"];
    
    // 恢复实时字幕开关状态（使用新方法）
    [self.subtitleView setSubtitleEnabled:enabled];
    
    // 恢复语言显示设置（以 language + bilingualEnabled 为准）
    // 延迟2秒调用
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL bilingualEnabled = [self.subtitleView subtitleHandler].bilingualSubtitleEnabled;
        NSString *language = [self.subtitleView subtitleHandler].translateLanguage;
        [self.subtitleView applySelectedLanguage:language bilingualEnabled:bilingualEnabled];
    });
}

#pragma mark - PLVECRealTimeSubtitleViewDelegate

- (void)realTimeSubtitleView:(PLVECRealTimeSubtitleView *)view didSetTranslateLanguage:(NSString *)language {
    // 转发给外部代理
    if ([self.delegate respondsToSelector:@selector(realTimeSubtitleManager:didSetTranslateLanguage:)]) {
        [self.delegate realTimeSubtitleManager:self didSetTranslateLanguage:language];
    }
}

- (void)realTimeSubtitleViewDidClose:(PLVECRealTimeSubtitleView *)view {
    // 同步更新设置：关闭字幕总开关
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PLVECRealTimeSubtitleEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 隐藏设置弹出框
    if (self.configView) {
        [self.configView hide];
    }
    
    // 转发给外部代理
    if ([self.delegate respondsToSelector:@selector(realTimeSubtitleManagerDidClose:)]) {
        [self.delegate realTimeSubtitleManagerDidClose:self];
    }
}

#pragma mark - PLVECRealTimeSubtitleConfigViewDelegate

- (void)realTimeSubtitleConfigView:(PLVECRealTimeSubtitleConfigView *)configView
                   didChangeEnabled:(BOOL)enabled {
    NSLog(@"实时字幕开关: %@", enabled ? @"开启" : @"关闭");
    
    // 保存设置到本地
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"PLVECRealTimeSubtitleEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 更新实时字幕视图的显示状态（使用新方法）
    [self.subtitleView setSubtitleEnabled:enabled];
}

- (void)realTimeSubtitleConfigView:(PLVECRealTimeSubtitleConfigView *)configView
              didChangeBilingualEnabled:(BOOL)enabled {
    NSLog(@"双语字幕开关: %@", enabled ? @"开启" : @"关闭");
    
    [self.subtitleView subtitleHandler].bilingualSubtitleEnabled = enabled;

    // 更新实时字幕视图的显示模式（以当前选中的语言为准）
    NSString *language = configView.selectedLanguage ?: @"origin";
    [self.subtitleView applySelectedLanguage:language bilingualEnabled:enabled];
}

- (void)realTimeSubtitleConfigView:(PLVECRealTimeSubtitleConfigView *)configView
                didSelectLanguage:(NSString *)language {
    NSLog(@"选择语言: %@", language);
    
    // 更新实时字幕的翻译语言
    PLVLiveRealTimeSubtitleHandler *subtitleHandler = [self.subtitleView subtitleHandler];
    if (subtitleHandler) {
        if (![language isEqualToString:@"origin"]) {
            // 选择翻译语种
            // **关键修改：调用字幕处理器的setTranslateLanguage方法**
            // 这会触发：1. 发送Socket消息 2. 从API加载历史字幕
            [subtitleHandler setTranslateLanguage:language];
        }
        // 注意：选择"origin"（原文不翻译）时，不需要调用setTranslateLanguage
        // 只需要通过UI层的showOrigin/showTranslate来控制显示
        [subtitleHandler setTranslateLanguage:language];
    }
    
    // 关键：语言选择后立即刷新字幕浮窗显示（解决无法从译文切回原文）
    BOOL bilingualEnabled = configView.bilingualEnabled;
    
    [self.subtitleView subtitleHandler].bilingualSubtitleEnabled = bilingualEnabled;
    [self.subtitleView applySelectedLanguage:(language ?: @"origin") bilingualEnabled:bilingualEnabled];
}

@end
