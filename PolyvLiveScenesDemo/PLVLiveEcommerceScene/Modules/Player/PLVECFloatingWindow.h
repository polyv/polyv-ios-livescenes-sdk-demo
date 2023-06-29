//
//  PLVECFloatingWindow.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVECFloatingWindowProtocol <NSObject>

/// 悬浮窗口隐藏回调
/// @param back YES:返回直播页 NO:停留在当前页面
- (void)floatingWindow_closeWindowAndBack:(BOOL)back;

/// 悬浮窗口静音回调
/// @param mute YES:静音 NO:取消静音
- (void)floatingWindow_mute:(BOOL)mute;

@end

NS_ASSUME_NONNULL_BEGIN

/*
 悬浮窗 UIWindow 类单例
 悬浮窗尺寸固定，为160pt x 90 pt，支持手指拖动移动悬浮窗位置
*/
@interface PLVECFloatingWindow : UIWindow

@property (nonatomic, weak) id<PLVECFloatingWindowProtocol> delegate;

/// 用于开启悬浮窗后离开页面时，持有原来的页面
@property (nonatomic, strong, nullable) UIViewController *holdingViewController;

/// 当使用model方式展示直播间的时候，点击小窗恢复按钮，是present还是dismiss来恢复原直播间
@property (nonatomic, assign) BOOL restoreWithPresent;

+ (instancetype)sharedInstance;

/// 打开悬浮窗并展示内容视图contentView (默认9:16尺寸)
/// @param contentView 内容视图contentView
- (void)showContentView:(UIView *)contentView;

/// 打开悬浮窗并根据尺进行缩放，展示内容视图contentView
/// @param contentView 内容视图contentView
/// @param size 悬浮窗缩放参考尺寸，width或height为0时悬浮窗按默认9:16展示
- (void)showContentView:(UIView *)contentView size:(CGSize)size;

/// 关闭悬浮窗，不触发悬浮窗口隐藏回调
- (void)close;

/// 关闭悬浮窗并返回原来的页面
- (void)closeAndBack;

/// 静音悬浮窗
- (void)mute;

/// 取消静音悬浮窗
- (void)cancleMute;
@end

NS_ASSUME_NONNULL_END
