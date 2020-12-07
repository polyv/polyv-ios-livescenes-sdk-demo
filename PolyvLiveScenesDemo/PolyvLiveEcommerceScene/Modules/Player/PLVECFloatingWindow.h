//
//  PLVECFloatingWindow.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/2.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVECFloatingWindowProtocol <NSObject>

/// 悬浮窗口隐藏回调
/// @param back YES:返回直播页 NO:停留在当前页面
- (void)floatingWindow_closeWindowAndBack:(BOOL)back;

@end

NS_ASSUME_NONNULL_BEGIN

/*
 悬浮窗 UIWindow 类单例
 悬浮窗尺寸固定，为160pt x 90 pt，支持手指拖动移动悬浮窗位置
*/
@interface PLVECFloatingWindow : UIWindow

@property (nonatomic, weak) id<PLVECFloatingWindowProtocol> delegate;

+ (instancetype)sharedInstance;

/// 打开悬浮窗并展示内容视图contentView
/// @param contentView 内容视图contentView
- (void)showContentView:(UIView *)contentView;

/// 关闭悬浮窗
- (void)close;

@end

NS_ASSUME_NONNULL_END
