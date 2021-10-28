//
//  PLVHCChatroomSheet.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 polyv. All rights reserved.
//
// 聊天室弹层

#import <UIKit/UIKit.h>
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVHCChatroomSheet;

@protocol PLVHCChatroomSheetDelegate <NSObject>

// 未读消息数量 更新时回调
- (void)chatroomSheet:(PLVHCChatroomSheet *)chatroomSheet didChangeNewMessageCount:(NSUInteger)newMessageCount;

@end

@interface PLVHCChatroomSheet : UIView

@property (nonatomic, weak) id<PLVHCChatroomSheetDelegate> delegate;

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 隐藏聊天室视图
- (void)dismiss;

#pragma mark 数据

/// 开始直播
- (void)startClass;

/// 结束直播
- (void)finishClass;

@end

NS_ASSUME_NONNULL_END
