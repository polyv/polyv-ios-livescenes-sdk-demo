//
//  PLVHCSendMsgView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 polyv. All rights reserved.
//  聊天室 发送消息视图
// 从底部弹出含有键盘的视图，可以发送文字、图片消息

#import <UIKit/UIKit.h>
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;
@class PLVHCSendMessageToolView;
@class PLVHCSendMessageView;

@protocol PLVHCSendMessageViewDelegate <NSObject>

- (void)sendMessageViewDidTapImageButton:(PLVHCSendMessageView *)sendMessageView;

@end

@interface PLVHCSendMessageView : UIView

@property (nonatomic, weak)id<PLVHCSendMessageViewDelegate> delegate;

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

/// 发送回复消息时，显示发送消息界面到主窗口上
- (void)showWithChatModel:(PLVChatModel *)model;

/// 显示发送消息界面到主窗口上
- (void)show;

/// 显示发送消息界面到主窗口上，可以携带内容
/// @param attributedString 内容
- (void)showWithAttributedString:(NSAttributedString *)attributedString;

/// 从主窗口移除发送消息界面
- (void)dismiss;

/// 开始直播
- (void)startClass;

/// 结束直播
- (void)finishClass;

@end

NS_ASSUME_NONNULL_END
