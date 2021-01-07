//
//  PLVKeyboardToolView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/6.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat const PLVKeyboardToolViewHeight = 56.0;

/// PLVKeyboardToolView 模式 - 不同模式下包含不同控件
typedef NS_ENUM(NSInteger, PLVKeyboardToolMode) {
    PLVKeyboardToolModeDefault,     // 默认模式：包含文本输入框、emoji 按钮、更多按钮
    PLVKeyboardToolModeSimple,      // 简单模式：包含文本输入框、emoji 按钮
};

/// 面板状态
typedef NS_ENUM(NSInteger, PLVKeyboardToolState) {
    PLVKeyboardToolStateNormal,       // 未弹出任何面板
    PLVKeyboardToolStateKeyboard,     // 弹出【系统键盘面板】
    PLVKeyboardToolStateEmojiboard,   // 弹出【emoji 选择面板】
    PLVKeyboardToolStateMoreboard     // 弹出【更多面板】
};

NS_ASSUME_NONNULL_BEGIN

@class PLVKeyboardToolView;

@protocol PLVKeyboardToolViewDelegate <NSObject>

@optional
/// 点击按钮或准备开始输入时触发，返回 NO 不允许响应
- (BOOL)keyboardToolView_shouldInteract:(PLVKeyboardToolView *)toolView;
/// 面板弹出弹入回调
- (void)keyboardToolView:(PLVKeyboardToolView *)toolView popBoard:(BOOL)show;
/// 发送消息文本
- (void)keyboardToolView:(PLVKeyboardToolView *)toolView sendText:(NSString *)text;
/// 点击【查看全部】或【只看讲师】
- (void)keyboardToolView:(PLVKeyboardToolView *)toolView onlyTeacher:(BOOL)on;
/// 打开相册
- (void)keyboardToolView_openAlbum:(PLVKeyboardToolView *)toolView;
/// 打开相机
- (void)keyboardToolView_openCamera:(PLVKeyboardToolView *)toolView;
/// 打开公告
- (void)keyboardToolView_readBulletin:(PLVKeyboardToolView *)toolView;

@end

@interface PLVKeyboardToolView : UIView

@property (nonatomic, weak) id<PLVKeyboardToolViewDelegate> delegate;
/// 【只看讲师】模式下是否禁止与其他控件的交互，默认 NO 不禁止
@property (nonatomic, assign) BOOL disableOtherButtonsInTeacherMode;
/// 是否显示发送图片相关按钮，默认 YES 显示，修改该属性前需先调用 'loadView' 方法
@property (nonatomic, assign) BOOL enableSendImage;
/// 是否隐藏公告按钮，默认 NO；YES - 隐藏，NO - 显示
@property (nonatomic, assign) BOOL hiddenBulletin;

/// 面板状态
@property (nonatomic, assign, readonly) PLVKeyboardToolState toolState;

/// 初始化方法，也可使用 init 初始化，将使用默认模式
- (instancetype)initWithMode:(PLVKeyboardToolMode)mode;

/// 加载视图，调用该方代替 'addSubview:'
- (void)addAtView:(UIView *)parentView frame:(CGRect)rect;

/// 完成布局后，修改正常状态下的位置 Y 值时调用
- (void)changeFrameForNewOriginY:(CGFloat)originY;

/// 释放资源，退出前调用，否则 iOShui9.0 以下系统会有 bug
- (void)clearResource;

@end

NS_ASSUME_NONNULL_END
