//
//  PLVKeyboardMoreView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVLCKeyboardMoreView;

@protocol PLVLCKeyboardMoreViewDelegate <NSObject>

/// 打开照相机
- (void)keyboardMoreView_openCamera:(PLVLCKeyboardMoreView *)moreView;

/// 打开相册
- (void)keyboardMoreView_openAlbum:(PLVLCKeyboardMoreView *)moreView;

/// 打开公告
- (void)keyboardMoreView_openBulletin:(PLVLCKeyboardMoreView *)moreView;

/// 打开互动应用模块
- (void)keyboardMoreView_openInteractApp:(PLVLCKeyboardMoreView *)moreView eventName:(NSString *)eventName;

/// 点击【屏蔽特效】或【展示特效】
/// @param on YES - 屏蔽特效；NO - 展示特效
- (void)keyboardMoreView_switchRewardDisplay:(PLVLCKeyboardMoreView *)moreView on:(BOOL)on;

/// 点击 语言切换
- (void)keyboardMoreView:(PLVLCKeyboardMoreView *)moreView switchLanguageMode:(NSInteger)languageMode;

/// 点击【查看全部】或【只看讲师】按钮
/// @param on YES - 只看教师；NO - 查看全部
- (void)keyboardMoreView_onlyTeacher:(PLVLCKeyboardMoreView *)moreView on:(BOOL)on;

@end

@interface PLVLCKeyboardMoreView : UIView

@property (nonatomic, weak) id<PLVLCKeyboardMoreViewDelegate> delegate;

/// 是否允许发送图片，默认 YES；YES - 显示发图按钮，NO - 隐藏发图按钮
@property (nonatomic, assign) BOOL sendImageEnable;

/// 是否隐藏公告按钮，默认 NO；YES - 隐藏，NO - 显示
@property (nonatomic, assign) BOOL hiddenBulletin;

/// 是否隐藏只看主持，默认 YES；YES - 显示，NO - 隐藏
@property (nonatomic, assign) BOOL onlyTeacherEnable;
/// 更新按钮数据（根据传入的数据动态更新按钮）
/// @param dataArray 前端传入的按钮数据
- (void)updateChatButtonDataArray:(NSArray *)dataArray;

/// 礼物打赏特效开关按钮是否隐藏，默认 YES；YES - 隐藏，NO - 显示
@property (nonatomic, assign) BOOL hideRewardDisplaySwitch;

/// 切换聊天室关闭状态
- (void)changeCloseRoomStatus:(BOOL)closeRoom;

/// 切换聊天室专注模式状态
- (void)changeFocusModeStatus:(BOOL)focusMode;

/// 是否禁用聊天室的交互、启用状态正常逻辑显示按钮，禁用状态只显示多语言按钮。默认不会仅用
- (void)disableRoomInteraction:(BOOL)disable;

@end
