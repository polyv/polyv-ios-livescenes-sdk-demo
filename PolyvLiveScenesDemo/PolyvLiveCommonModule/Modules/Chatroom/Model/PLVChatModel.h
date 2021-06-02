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

/// 不为空表示此消息含有严禁词、违规图片
/// @note message类型为PLVSpeakMessage、PLVQuoteMessage时：存放严禁词
/// @note message类型为PLVImageMessage时：存放违规图片msgId
@property (nonatomic, copy) NSString *prohibitWord;

/// 判断当前消息是否为：严禁词、违禁图片 消息
/// @note YES: 含有严禁词的消息；NO: 不含严禁词的消息
- (BOOL)isProhibitMsg;

/// 获取 message 属性的 msgId
/// 如果为文本消息、引用消息、图片消息时，msgId 不为空，否则为 nil
- (NSString *)msgId;

/// 获取 message 属性的 content
/// 如果为私聊消息、文本消息、引用消息时，content 不为空，否则为 nil
- (NSString *)content;

@end

NS_ASSUME_NONNULL_END
