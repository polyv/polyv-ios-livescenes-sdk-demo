//
//  PLVLSSendMessageView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/18.
//  Copyright © 2021 PLV. All rights reserved.
//
// 发送消息界面

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

/// 发送消息界面
@interface PLVLSSendMessageView : UIView

//图片表情资源
@property (nonatomic, strong) NSArray *imageEmotionArray;

/// 发送回复消息时，显示发送消息界面到主窗口上
- (void)showWithChatModel:(PLVChatModel *)model;

/// 显示发送消息界面到主窗口上
- (void)show;

/// 从主窗口移除发送消息界面
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
