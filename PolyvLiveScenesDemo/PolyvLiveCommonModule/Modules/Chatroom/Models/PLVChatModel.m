//
//  PLVChatModel.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVChatModel.h"
#import <PLVLiveScenesSDK/PLVQuoteMessage.h>
#import <PLVLiveScenesSDK/PLVSpeakMessage.h>
#import <PLVLiveScenesSDK/PLVImageMessage.h>

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

@end
