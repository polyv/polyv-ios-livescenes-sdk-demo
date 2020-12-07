//
//  PLVChatModel.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVChatModel : NSObject

@property (nonatomic, strong) PLVChatUser *user;

@property (nonatomic, strong) id message;

/// 获取 message 属性的 msgId
/// 如果为文本消息、引用消息、图片消息时，msgId 不为空，否则为 nil
- (NSString *)msgId;

/// 获取 message 属性的 content
/// 如果为私聊消息、文本消息、引用消息时，content 不为空，否则为 nil
- (NSString *)content;

@end

NS_ASSUME_NONNULL_END
