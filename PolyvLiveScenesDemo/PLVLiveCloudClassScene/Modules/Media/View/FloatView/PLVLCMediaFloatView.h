//
//  PLVLCMediaFloatView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/15.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCFloatViewDelegate;

/// 媒体悬浮视图
@interface PLVLCMediaFloatView : UIView

/// delegate
@property (nonatomic, weak) id <PLVLCFloatViewDelegate> delegate;

/// 是否全屏
@property (nonatomic, assign) BOOL fullscreen;

/// 竖屏时是否可以移动（直播不可以，回放可以）
@property (nonatomic, assign) BOOL canMove;

@property (nonatomic, assign, readonly) BOOL floatViewShow;

/// 承载展示外部视图
///
/// @param externalView 外部视图
- (void)displayExternalView:(UIView *)externalView;

- (void)setNicknameLabalWithText:(NSString *)nicknameText;

- (void)showFloatView:(BOOL)show userOperat:(BOOL)userOperat;

/// 优先级高于 [showFloatView:userOperat:]
- (void)forceShowFloatView:(BOOL)show;

/// 触发一次视图交换事件
- (void)triggerViewExchangeEvent;

@end

@protocol PLVLCFloatViewDelegate <NSObject>

/// 悬浮视图被点击
///
/// @note 被点击时，代表用户希望 PLVLCFloatView悬浮视图 上的内容，移至外部窗口中显示。
///       因此该回调将附带 当前正在显示的视图externalView。
///
/// @param floatView 悬浮视图本身
/// @param externalView 当前正在显示的外部视图
///
/// @return UIView 外部对象返回的视图，将显示在被点击窗口的位置
- (UIView *)plvLCFloatViewDidTap:(PLVLCMediaFloatView *)floatView externalView:(UIView *)externalView;

/// 悬浮视图关闭按钮被点击
///
/// @param floatView 悬浮视图本身
- (void)plvLCFloatViewCloseButtonClicked:(PLVLCMediaFloatView *)floatView;

/// 悬浮视图出现或隐藏
///
/// @note 仅在悬浮视图的出现隐藏状态前后有变化时，会触发此回调；
///
/// @param floatView 悬浮视图本身
/// @param show 当前悬浮视图的出现隐藏状态 (YES:处于出现状态 NO:处于隐藏状态)
- (void)plvLCFloatView:(PLVLCMediaFloatView *)floatView floatViewSwitchToShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
