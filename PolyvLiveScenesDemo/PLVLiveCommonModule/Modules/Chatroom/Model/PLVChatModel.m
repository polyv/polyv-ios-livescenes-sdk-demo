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

#pragma mark - [ Public Method ]

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
    } else if ([messageObject isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *message = (PLVFileMessage *)messageObject;
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
    } else if ([messageObject isKindOfClass:[ PLVImageEmotionMessage class]]) {
        PLVImageEmotionMessage *message = ( PLVImageEmotionMessage *)messageObject;
        time = message.time;
    } else if ([messageObject isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *message = (PLVFileMessage *)messageObject;
        time = message.time;
    }
    return time;
}

- (NSTimeInterval)playbackTime {
    id messageObject = self.message;
    NSTimeInterval playbackTime = 0;
    if ([messageObject isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)messageObject;
        playbackTime = message.playbackTime;
    } else if ([messageObject isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)messageObject;
        playbackTime = message.playbackTime;
    } else if ([messageObject isKindOfClass:[PLVImageMessage class]]) {
        PLVImageMessage *message = (PLVImageMessage *)messageObject;
        playbackTime = message.playbackTime;
    } else if ([messageObject isKindOfClass:[ PLVImageEmotionMessage class]]) {
        PLVImageEmotionMessage *message = ( PLVImageEmotionMessage *)messageObject;
        playbackTime = message.playbackTime;
    } else if ([messageObject isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *message = (PLVFileMessage *)messageObject;
        playbackTime = message.playbackTime;
    }
    return playbackTime;
}

- (BOOL)isProhibitMsg {
    id messageObject = self.message;
    BOOL prohibitWordReplaced = NO;
    if ([messageObject isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)messageObject;
        prohibitWordReplaced = message.prohibitWordReplaced;
    } else if ([messageObject isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)messageObject;
        prohibitWordReplaced = message.prohibitWordReplaced;
    }
    
    if (prohibitWordReplaced) { // 消息中的严禁词已被替换并成功发送
        return YES;
    } else if ([PLVFdUtil checkStringUseable:self.prohibitWord]) { // 消息中出现严禁词，已被禁止发出
        return YES;
    } else {
        return NO;
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
    }  else if ([messageObject isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *message = (PLVFileMessage *)messageObject;
        source = message.source;
    }
    
    if ([PLVFdUtil checkStringUseable:source] &&
        [source isEqualToString:@"extend"]) { // source字段值为"extend"表示为：提醒消息
        isRemindMsg = YES;
    }
    
    return isRemindMsg;
}

- (BOOL)isOverLenMsg {
    id messageObject = self.message;
    BOOL isOverLenMsg = NO;
    
    if ([messageObject isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)messageObject;
        isOverLenMsg = message.overLen;
    } else if ([messageObject isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)messageObject;
        isOverLenMsg = message.overLen;
    }
    return isOverLenMsg;
}

+ (PLVChatModel *)chatModelFromPlaybackMessage:(PLVPlaybackMessage *)playbackMessage {
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.message = playbackMessage.message;
    model.msgState = PLVChatMsgStateSuccess;
    
    PLVChatUser *chatUser = [PLVChatUser chatUserFromPlaybackMsgUser:playbackMessage.user];
    model.user = chatUser;
    return model;
}

#pragma mark Getter & Setter

- (PLVChatMsgContentLength)contentLength {
    PLVChatMsgContentLength contentLength = PLVChatMsgContentLength_Unvalid;
    if (self.content) {
        contentLength = (self.content.length <= 500) ? PLVChatMsgContentLength_0To500 : PLVChatMsgContentLength_MoreThan500;
    }
    return contentLength;
}

- (void)setOverLenContent:(NSString *)overLenContent {
    if (![self isOverLenMsg]) {
        return;
    }
    _overLenContent = [overLenContent copy];
}

#pragma mark - [ Private Method ]

- (BOOL)isEqualToChatModel:(PLVChatModel *)chatModel {
    if (!chatModel) {
        return NO;
    }

    if (!chatModel.message || !self.message) {
        return NO;
    }
    
    NSString *myMsgId = [self msgId];
    NSString *compareMsgId = [chatModel msgId];
    return myMsgId && compareMsgId && [myMsgId isEqualToString:compareMsgId];
}

#pragma mark - [ Override ]

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }

    return [self isEqualToChatModel:(PLVChatModel *)object];
}

- (NSUInteger)hash {
    NSString *msgId = [self msgId];
    NSUInteger hash = [msgId hash];
    return hash;
}


@end
