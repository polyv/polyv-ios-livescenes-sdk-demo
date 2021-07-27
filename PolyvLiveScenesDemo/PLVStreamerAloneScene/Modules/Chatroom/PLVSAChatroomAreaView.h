//
//  PLVSAChatroomAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
// 聊天室视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVSAChatroomAreaView;
@protocol PLVSAChatroomAreaViewDelegate <NSObject>

/// 显示清屏手势提示视图
- (void)chatroomAreaView_showSlideRightView;

- (void)chatroomAreaView:(PLVSAChatroomAreaView *)chatroomAreaView DidChangeCloseRoom:(BOOL)closeRoom;

@end

@interface PLVSAChatroomAreaView : UIView

@property (nonatomic, weak) id<PLVSAChatroomAreaViewDelegate> delegate;

/// 当前 全体禁言 当前是否开启，UI状态
/// @note Setter 方法内实现发送禁言操作
@property (nonatomic, assign) BOOL closeRoom;

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

@end

NS_ASSUME_NONNULL_END
