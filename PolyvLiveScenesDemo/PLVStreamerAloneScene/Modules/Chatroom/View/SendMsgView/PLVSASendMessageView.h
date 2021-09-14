//
//  PLVSASendMessageView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

/// 发送消息界面
@interface PLVSASendMessageView : UIView

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

/// 图片表情数据
@property (nonatomic, strong) NSArray *imageEmotionArray;

/// 发送回复消息时，显示发送消息界面到主窗口上
- (void)showWithChatModel:(PLVChatModel *)model;

/// 显示发送消息界面到主窗口上
- (void)show;

/// 从主窗口移除发送消息界面
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
