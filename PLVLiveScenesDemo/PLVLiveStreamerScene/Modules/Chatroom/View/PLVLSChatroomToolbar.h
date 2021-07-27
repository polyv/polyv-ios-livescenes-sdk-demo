//
//  PLVLSChatroomToolbar.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSChatroomToolbar : UIView

/// 点击麦克风按钮响应事件方法块
/// open：YES - 开麦 NO - 关麦
@property (nonatomic, copy) void(^didTapMicrophoneButton)(BOOL open);

/// 点击摄像头按钮响应事件方法块
/// open：YES - 开摄像头 NO - 关摄像头
@property (nonatomic, copy) void(^didTapCameraButton)(BOOL open);

/// 点击前后置摄像头切换按钮响应事件方法块
/// front：YES - 前置摄像头 NO - 后置摄像头
@property (nonatomic, copy) void(^didTapCameraSwitchButton)(void);

/// 点击“有话要说”按钮响应事件方法块
@property (nonatomic, copy) void(^didTapSendMessageButton)(void);

/// 麦克风按钮状态修改
- (void)microphoneButtonOpen:(BOOL)open;

/// 摄像头按钮、切换前后置摄像头按钮状态修改
- (void)cameraButtonOpen:(BOOL)open;

/// 切换前后置摄像头按钮状态修改
- (void)cameraSwitchButtonFront:(BOOL)front;

/// 隐藏除折叠按钮外的工具栏按钮
- (void)hideButton;

@end

NS_ASSUME_NONNULL_END
