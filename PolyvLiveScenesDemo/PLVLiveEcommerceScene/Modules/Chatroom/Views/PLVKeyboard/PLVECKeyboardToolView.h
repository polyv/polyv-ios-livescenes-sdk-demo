//
//  PLVECKeyboardToolView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/8.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// PLVECKeyboardToolView 当前状态
typedef NS_ENUM(NSInteger, PLVECKeyboardToolMode) {
    PLVECKeyboardToolModeNormal,     // 正常聊天输入框
    PLVECKeyboardToolModeAskQuestion,   // 提问聊天输入框
};

@class PLVECKeyboardToolView, PLVChatModel;

@protocol PLVECKeyboardToolViewDelegate <NSObject>

@optional

/// 面板弹出弹入回调
- (void)keyboardToolView:(PLVECKeyboardToolView *)toolView popBoard:(BOOL)show;

/// 发送消息文本
/// @param text 消息文本
/// @param replyModel 引用回复消息，可为空
- (void)keyboardToolView:(PLVECKeyboardToolView *)toolView sendText:(NSString *)text replyModel:(PLVChatModel * _Nullable)replyModel;

/// 输入框工具视图模式改变
/// @param mode 当前输入框工具视图模式
- (void)keyboardToolView:(PLVECKeyboardToolView *)toolView keyboardToolModeChanged:(PLVECKeyboardToolMode)mode;

@end

@interface PLVECKeyboardToolView : UIView

@property (nonatomic, weak) id<PLVECKeyboardToolViewDelegate> delegate;

/// 是否启用聊天室键盘 只对公聊有效
@property (nonatomic, assign) BOOL enabledKeyboardTool;
/// 是否开启提问功能【默认不开启】
@property (nonatomic, assign) BOOL enableAskQuestion;

/// 当前键盘的状态
@property (nonatomic, assign, readonly) PLVECKeyboardToolMode keyboardToolMode;
/// 激活键盘的Y坐标
@property (nonatomic, assign, readonly) CGFloat activatedKeyboardToolRectY;
/// 键盘是否处于激活状态
@property (nonatomic, assign, readonly) BOOL keyboardActivated;

@property (nonatomic, strong, readonly) UIView *inactivatedTextAreaView;

/// 切换键盘对应的类型
- (void)switchKeyboardToolMode:(PLVECKeyboardToolMode)keyboardToolMode;

/// 加载视图，调用该方代替 'addSubview:'
- (void)addTextViewToParentView:(UIView *)parentView;
/// 更新布局
- (void)updateTextViewFrame:(CGRect)rect;

/// 回复某条消息
- (void)replyChatModel:(PLVChatModel *)model;

- (void)changePlaceholderText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
