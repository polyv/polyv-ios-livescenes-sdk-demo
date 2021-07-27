//
//  PLVInteractBulletin.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/14.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVInteractBulletin.h"

#import "PLVInteractBaseApp+General.h"

@interface PLVInteractBulletin ()

@property (nonatomic, copy) NSString * bulletinJson; /// 公告内容

@end

@implementation PLVInteractBulletin

#pragma mark - [ Father Public Methods ]
- (instancetype)initWithJsBridge:(PLVJSBridge *)jsBridge{
    if (self = [super initWithJsBridge:jsBridge]) {
    }
    return self;
}

- (void)processInteractMessageString:(NSString *)msgString jsonDict:(NSDictionary *)jsonDict{
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:PLVSocketIOChatRoom_BULLETIN_EVENT]) { /// 打开公告
        [self openBulletin:msgString];
    } else if ([subEvent isEqualToString:PLVSocketIOChatRoom_BULLETIN_RemoveBulletin]) { /// 删除公告
        [self removeBulletin];
    }
}


#pragma mark - [ Private Methods ]
- (void)openBulletin:(NSString *)msgString{
    self.bulletinJson = msgString;
    if ([PLVFdUtil checkStringUseable:msgString]) {
        [self.jsBridge call:@"bulletin" params:@[msgString]];
    }else{
        [self.jsBridge call:@"bulletin" params:@[@"{\"EVENT\":\"BULLETIN\",\"content\":\"\"}"]];
    }
    [self callWebviewShow];
}

- (void)openLastBulletin{
    [self openBulletin:self.bulletinJson];
}

- (void)removeBulletin{
    self.bulletinJson = nil;
    [self.jsBridge call:@"removeBulletin" params:@[]];
}

@end
