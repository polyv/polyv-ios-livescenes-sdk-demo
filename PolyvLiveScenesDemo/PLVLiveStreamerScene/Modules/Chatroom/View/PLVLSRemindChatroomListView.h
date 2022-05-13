//
//  PLVLSRemindChatroomListView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/14.
//  Copyright © 2022 PLV. All rights reserved.
//  提醒消息列表视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSRemindChatroomListView : UIView

@property (nonatomic, copy) void(^didScrollTableViewUp)(void);
@property (nonatomic, copy) void(^didScrollTableViewTwoScreens)(void);

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

- (void)didSendMessage;

- (BOOL)didReceiveMessages;

- (void)didMessageDeleted;

- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

- (void)loadHistoryFailure;

- (void)scrollsToBottom:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
