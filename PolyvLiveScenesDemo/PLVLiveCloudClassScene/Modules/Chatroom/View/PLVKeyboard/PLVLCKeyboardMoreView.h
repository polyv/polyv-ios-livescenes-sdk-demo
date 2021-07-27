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


@end
