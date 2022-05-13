//
//  PLVLSNewRemindMessageView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSNewRemindMessageView : UIView

/// 点击手势响应事件方法块，同时点击会把消息数清零并隐藏视图
@property (nonatomic, copy) void(^didTapNewMessageView)(void);

/// 更新文案上的消息数
///  消息数为0时隐藏视图，大于0才显示
- (void)updateMessageCount:(NSUInteger)count;

/// 更新滚动两屏提示
- (void)updateScrollMessage;

@end

NS_ASSUME_NONNULL_END
