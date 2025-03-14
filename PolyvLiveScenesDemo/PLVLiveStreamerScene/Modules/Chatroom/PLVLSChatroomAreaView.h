//
//  PLVLSChatroomAreaView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSChatroomAreaViewProtocol <NSObject>
 /// 点击【麦克风开关】按钮
- (void)chatroomAreaView_didTapMicrophoneButton:(BOOL)open;
/// 点击【摄像头开关】按钮
- (void)chatroomAreaView_didTapCameraButton:(BOOL)open;
/// 点击【切换前后置摄像头】按钮
- (void)chatroomAreaView_didTapCameraSwitchButton;

@end

/// 主页聊天区域视图
@interface PLVLSChatroomAreaView : UIView

@property (nonatomic, weak) id<PLVLSChatroomAreaViewProtocol> delegate;

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

/// 麦克风按钮状态修改
- (void)microphoneButtonOpen:(BOOL)open;

/// 摄像头按钮、切换前后置摄像头按钮状态修改
- (void)cameraButtonOpen:(BOOL)open;

/// 切换前后置摄像头按钮状态修改
- (void)cameraSwitchButtonFront:(BOOL)open;

/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 退出登录
- (void)logout;

/// 文档切换全屏状态
/// @param fullScreen 是否全屏
- (void)documentChangeFullScreen:(BOOL)fullScreen;

/// 评论下墙操作
- (void)cancelTopPinMessage:(NSString * _Nullable)msgId;

@end

NS_ASSUME_NONNULL_END
