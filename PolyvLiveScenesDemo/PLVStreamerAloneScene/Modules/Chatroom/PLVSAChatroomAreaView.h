//
//  PLVSAChatroomAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
// 聊天室视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVSAChatroomAreaView, PLVChatModel;
@protocol PLVSAChatroomAreaViewDelegate <NSObject>

/// 显示清屏手势提示视图
- (void)chatroomAreaView_showSlideRightView;

- (void)chatroomAreaView:(PLVSAChatroomAreaView *)chatroomAreaView DidChangeCloseRoom:(BOOL)closeRoom;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)chatroomAreaView:(PLVSAChatroomAreaView *)chatroomAreaView alertLongContentMessage:(PLVChatModel *)model;

@end

@interface PLVSAChatroomAreaView : UIView

@property (nonatomic, weak) id<PLVSAChatroomAreaViewDelegate> delegate;

/// 当前 全体禁言 当前是否开启，UI状态
/// @note Setter 方法内实现发送禁言操作
@property (nonatomic, assign) BOOL closeRoom;

/// 发送评论下墙消息
- (void)sendCancleTopPinMessage;

@end

NS_ASSUME_NONNULL_END
