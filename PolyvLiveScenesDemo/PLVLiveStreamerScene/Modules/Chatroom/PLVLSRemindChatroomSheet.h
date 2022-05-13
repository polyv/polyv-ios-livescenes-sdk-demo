//
//  PLVLSRemindChatroomSheet.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/11.
//  Copyright © 2022 PLV. All rights reserved.
// 提醒消息 弹层

#import "PLVLSSideSheet.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVChatModel;

@interface PLVLSRemindChatroomSheet : PLVLSSideSheet

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

@end

NS_ASSUME_NONNULL_END
