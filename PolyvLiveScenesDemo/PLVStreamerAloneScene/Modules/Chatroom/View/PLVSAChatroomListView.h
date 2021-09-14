//
//  PLVSAChatroomListView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;
@class PLVSAChatroomListView;

@protocol PLVSAChatroomListViewDelegate <NSObject>

/// 点击到底部 回调
- (void)chatroomListViewDidScrollTableViewUp:(PLVSAChatroomListView *)listView;

/// 重发消息 回调
- (void)chatroomListView:(PLVSAChatroomListView *)listView resendSpeakMessage:(NSString *)message;

/// 重发 图片消息 回调
- (void)chatroomListView:(PLVSAChatroomListView *)listView resendImageMessage:(NSString *)imageId image:(UIImage *)image;

/// 重发 图片表情消息 回调
- (void)chatroomListView:(PLVSAChatroomListView *)listView resendImageEmotionMessage:(NSString *)imageId imageUrl:(NSString *)imageUrl;

/// 重发 回复消息 回调
- (void)chatroomListView:(PLVSAChatroomListView *)listView resendReplyMessage:(NSString *)message replyModel:(PLVChatModel *)model;

/// 回复消息 回调
- (void)chatroomListView:(PLVSAChatroomListView *)listView didTapReplyMenuItem:(PLVChatModel *)model;

@end

/// 直播间聊天消息列表视图
@interface PLVSAChatroomListView : UIView

@property (nonatomic, weak) id<PLVSAChatroomListViewDelegate> delegate;

/// 发送消息
- (void)didSendMessage;

- (BOOL)didReceiveMessages;

- (void)didMessageDeleted;

- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

- (void)loadHistoryFailure;

- (void)scrollsToBottom:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
