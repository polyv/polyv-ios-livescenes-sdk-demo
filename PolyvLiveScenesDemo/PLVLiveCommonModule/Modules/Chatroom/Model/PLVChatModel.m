//
//  PLVChatModel.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVChatModel.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@implementation PLVChatModel

- (NSString *)msgId {
    id messageObject = self.message;
    NSString *msgId = nil;
    if ([messageObject isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)messageObject;
        msgId = message.msgId;
    } else if ([messageObject isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)messageObject;
        msgId = message.msgId;
    } else if ([messageObject isKindOfClass:[PLVImageMessage class]]) {
        PLVImageMessage *message = (PLVImageMessage *)messageObject;
        msgId = message.msgId;
    } else if ([messageObject isKindOfClass:[PLVImageEmotionMessage class]]) {
        PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)messageObject;
        msgId = message.msgId;
    } else if ([messageObject isKindOfClass:[PLVRewardMessage class]]) {
        PLVRewardMessage *message = (PLVRewardMessage *)messageObject;
        msgId = message.msgId;
    }
    return msgId;
}

- (NSString *)content {
    id messageObject = self.message;
    NSString *content = nil;
    if ([messageObject isKindOfClass:[NSString class]]) {
        content = (NSString *)messageObject;
    } else if ([messageObject isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)messageObject;
        content = message.content;
    } else if ([messageObject isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)messageObject;
        content = message.content;
    }
    return content;
}

- (BOOL)isProhibitMsg {
    if (!self.prohibitWord ||
        ![self.prohibitWord isKindOfClass:[NSString class]] ||
        self.prohibitWord.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isRemindMsg {
    id messageObject = self.message;
    NSString *source = nil;
    BOOL isRemindMsg = NO;
    
     if ([messageObject isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)messageObject;
         source = message.source;
    } else if ([messageObject isKindOfClass:[PLVImageMessage class]]) {
        PLVImageMessage *message = (PLVImageMessage *)messageObject;
        source = message.source;
    }
    
    if ([PLVFdUtil checkStringUseable:source] &&
        [source isEqualToString:@"extend"]) { // source字段值为"extend"表示为：提醒消息
        isRemindMsg = YES;
    }
    
    return isRemindMsg;
}

- (NSTimeInterval)time {
    id messageObject = self.message;
    NSTimeInterval time = 0;
    if ([messageObject isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)messageObject;
        time = message.time;
    } else if ([messageObject isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)messageObject;
        time = message.time;
    } else if ([messageObject isKindOfClass:[PLVImageMessage class]]) {
        PLVImageMessage *message = (PLVImageMessage *)messageObject;
        time = message.time;
    }
    return time;
}

@end
