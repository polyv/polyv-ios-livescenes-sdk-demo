//
//  PLVHCNewMessgaeTipView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 polyv. All rights reserved.
//  聊天室 新消息提示视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 新消息提示视图，特指未显示在当前屏幕的消息
@interface PLVHCNewMessgaeTipView : UIView

/// 点击手势响应事件方法块，同时点击会把消息数清零并隐藏视图
@property (nonatomic, copy) void(^didTapNewMessageView)(void);

/// 更新文案上的消息数
///  消息数为0时隐藏视图，大于0才显示
- (void)updateMeesageCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
