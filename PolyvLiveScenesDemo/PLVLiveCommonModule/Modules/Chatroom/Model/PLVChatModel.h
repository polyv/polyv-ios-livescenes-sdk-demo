//
//  PLVChatModel.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, PLVChatMsgState) {
    PLVChatMsgStateUnknown, // 未知
    PLVChatMsgStateSending, // 发送中
    PLVChatMsgStateSuccess, // 发送成功
    PLVChatMsgStateFail,    // 发送失败
    PLVChatMsgStateImageLoading, // 图片加载中
    PLVChatMsgStateImageLoadFail, // 图片加载失败
    PLVChatMsgStateImageLoadSuccess, // 图片加载成功
};

@interface PLVChatModel : NSObject

@property (nonatomic, strong) PLVChatUser *user;

@property (nonatomic, strong) id message;

/// 被回复的原消息，用于重发回复信息
@property (nonatomic, strong) id replyMessage;

/// 不为空表示此消息含有严禁词、违规图片
/// @note message类型为PLVSpeakMessage、PLVQuoteMessage时：存放严禁词
/// @note message类型为PLVImageMessage时：存放违规图片msgId
@property (nonatomic, copy) NSString *prohibitWord;

/// 消息状态，不同状态有对应的UI视图
@property (nonatomic, assign) PLVChatMsgState msgState;

/// 违禁词提示是否已显示过，YES：已显示，不再显示；NO：未显示，显示
@property (nonatomic, assign, getter=prohibitWordTipIsShowed) BOOL prohibitWordTipShowed;

/// 图片Id，用于重发图片消息时，找到此条消息并删除
/// @note message类型为图片消息(PLVSpeakMessage)时,imageId不为空，否则为 nil
@property (nonatomic, copy) NSString *imageId;

/// 判断当前消息是否为：严禁词、违禁图片 消息
/// @note YES: 含有严禁词的消息；NO: 不含严禁词的消息
- (BOOL)isProhibitMsg;

/// 获取 message 属性的 msgId
/// 如果为文本消息、引用消息、图片消息、打赏消息，msgId 不为空，否则为 nil
- (NSString *)msgId;

/// 获取 message 属性的 content
/// 如果为私聊消息、文本消息、引用消息时，content 不为空，否则为 nil
- (NSString *)content;

@end

NS_ASSUME_NONNULL_END
