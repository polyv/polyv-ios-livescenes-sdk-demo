//
//  PLVHCRepliedMsgView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
// 发送消息视图 - 被回复的消息视图
// 回复他人消息时，在输入框上面显示

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

/// 回复他人消息时，在输入框上面显示被回复的消息视图
@interface PLVHCRepliedMsgView : UIView

/// 根据 chatModel 得到的视图高度
@property (nonatomic, assign, readonly) CGFloat viewHeight;

/// 关闭按钮的触发回调
@property (nonatomic, copy) void(^closeButtonHandler)(void);

/// 自定义初始化方法
/// @param chatModel 被回复的消息模型
- (instancetype)initWithChatModel:(PLVChatModel *)chatModel;

@end

NS_ASSUME_NONNULL_END
