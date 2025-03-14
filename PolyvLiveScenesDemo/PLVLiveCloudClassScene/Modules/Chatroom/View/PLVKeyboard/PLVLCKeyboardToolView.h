//
//  PLVLCKeyboardToolView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/6.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat const PLVLCKeyboardToolViewHeight = 56.0;

/// PLVLCKeyboardToolView 模式 - 不同模式下包含不同控件
typedef NS_ENUM(NSInteger, PLVLCKeyboardToolMode) {
    PLVLCKeyboardToolModeDefault,     // 默认模式：包含文本输入框、emoji 按钮、更多按钮、互动功能入口
    PLVLCKeyboardToolModeSimple,      // 简单模式：包含文本输入框、emoji 按钮
};

/// 面板状态
typedef NS_ENUM(NSInteger, PLVLCKeyboardToolState) {
    PLVLCKeyboardToolStateNormal,       // 未弹出任何面板
    PLVLCKeyboardToolStateKeyboard,     // 弹出【系统键盘面板】
    PLVLCKeyboardToolStateEmojiboard,   // 弹出【emoji 选择面板】
    PLVLCKeyboardToolStateMoreboard     // 弹出【更多面板】
};

NS_ASSUME_NONNULL_BEGIN

@class PLVLCKeyboardToolView, PLVChatModel;

@protocol PLVLCKeyboardToolViewDelegate <NSObject>

@optional
/// 点击按钮或准备开始输入时触发，返回 NO 不允许响应
- (BOOL)keyboardToolView_shouldInteract:(PLVLCKeyboardToolView *)toolView;
/// 面板弹出弹入回调
- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView popBoard:(BOOL)show;
/// 发送消息文本
/// @param text 消息文本
/// @param replyModel 引用回复消息，可为空
- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView sendText:(NSString *)text replyModel:(PLVChatModel * _Nullable)replyModel;
/// 发送图片表情消息
- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView
      sendImageEmotionId:(NSString *)imageId
                imageUrl:(NSString *)imageUrl;
/// 点击【查看全部】或【只看讲师】
- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView onlyTeacher:(BOOL)on;
/// 打开相册
- (void)keyboardToolView_openAlbum:(PLVLCKeyboardToolView *)toolView;
/// 打开相机
- (void)keyboardToolView_openCamera:(PLVLCKeyboardToolView *)toolView;
/// 打开公告
- (void)keyboardToolView_readBulletin:(PLVLCKeyboardToolView *)toolView;
/// 打开互动应用模块
- (void)keyboardToolView_openInteractApp:(PLVLCKeyboardToolView *)moreView eventName:(NSString *)eventName;
/// 打开礼物打赏面板
- (void)keyboardToolView_openReward:(PLVLCKeyboardToolView *)c;
/// 点击【屏蔽特效】或【展示特效】
- (void)keyboardToolView_switchRewardDisplay:(PLVLCKeyboardToolView *)moreView on:(BOOL)on;
/// 点击语言切换
- (void)keyboardToolView:(PLVLCKeyboardToolView *)moreView switchLanguageMode:(NSInteger)languageMode;
/// 键盘显示互动功能入口
- (void)keyboardToolView_showIarEntranceView:(PLVLCKeyboardToolView *)iarEntranceView show:(BOOL)show;
/// 小窗播放设置
- (void)keyboardToolView_pipSet:(PLVLCKeyboardToolView *)toolView;


@end

@interface PLVLCKeyboardToolView : UIView

@property (nonatomic, weak) id<PLVLCKeyboardToolViewDelegate> delegate;
/// 【只看讲师】模式下是否禁止与其他控件的交互，默认 NO 不禁止
@property (nonatomic, assign) BOOL disableOtherButtonsInTeacherMode;
/// 是否显示发送图片相关按钮，默认 YES 显示，修改该属性前需先调用 'loadView' 方法
@property (nonatomic, assign) BOOL enableSendImage;
/// 是否隐藏公告按钮，默认 NO；YES - 隐藏，NO - 显示
@property (nonatomic, assign) BOOL hiddenBulletin;
/// 是否隐藏积分打赏按钮，默认NO；YES - 显示，NO - 隐藏
@property (nonatomic, assign) BOOL enablePointReward;
///键盘的图片表情
@property (nonatomic, strong) NSArray *imageEmotions;
/// 是否隐藏礼物打赏按钮，默认NO；YES - 显示，NO - 隐藏
@property (nonatomic, assign) BOOL enableReward;
/// 是否支持小窗播放设置
@property (nonatomic, assign) BOOL enablePipSet;

/// 面板状态
@property (nonatomic, assign, readonly) PLVLCKeyboardToolState toolState;

/// 初始化方法，也可使用 init 初始化，将使用默认模式
- (instancetype)initWithMode:(PLVLCKeyboardToolMode)mode;

/// 改变输入框提示文本，默认是“我也来聊几句”
- (void)changePlaceholderText:(NSString *)text;

/// 加载视图，调用该方代替 'addSubview:'
- (void)addAtView:(UIView *)parentView frame:(CGRect)rect;

/// 切换聊天室关闭状态，开启/禁用输入框、emoji 选择、查看更多中的部分功能
- (void)changeCloseRoomStatus:(BOOL)closeRoom;

/// 切换聊天室专注模式状态，开启/禁用输入框、emoji 选择、查看更多中的部分功能，启用只看讲师功能
- (void)changeFocusMode:(BOOL)focusMode;

/// 刷新文本和按钮布局，iPad分屏尺寸变动时调用
- (void)updateTextViewAndButton;

/// 更新按钮数据
- (void)updateChatButtonDataArray:(NSArray *)dataArray;

/// 完成布局后，修改正常状态下的位置 Y 值时调用
- (void)changeFrameForNewOriginY:(CGFloat)originY;

/// 释放资源，退出前调用，否则 iOShui9.0 以下系统会有 bug
- (void)clearResource;

/// 回复某条消息
- (void)replyChatModel:(PLVChatModel *)model;

/// 获取键盘默认模式高度
- (CGFloat)getKeyboardToolViewHeight;

@end

NS_ASSUME_NONNULL_END
