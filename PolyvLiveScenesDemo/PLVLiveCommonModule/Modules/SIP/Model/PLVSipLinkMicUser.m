//
//  PLVSipLinkMicUser.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/6/23.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSipLinkMicUser.h"

@interface PLVSipLinkMicUser ()

@end

@implementation PLVSipLinkMicUser

#pragma mark - [ Public Methods ]
#pragma mark 创建
- (instancetype)initWithUserInfo:(NSDictionary *)userInfo {
    if (![PLVFdUtil checkDictionaryUseable:userInfo]) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.callDuration = PLV_SafeIntegerForDictKey(userInfo, @"callDuration");
        self.callDurationString = PLV_SafeStringForDictKey(userInfo, @"callDurationString");
        self.callTime = PLV_SafeStringForDictKey(userInfo, @"callTime");
        self.channelId = PLV_SafeIntegerForDictKey(userInfo, @"channelId");
        self.hangTime = PLV_SafeStringForDictKey(userInfo, @"hangTime");
        self.uid = PLV_SafeIntegerForDictKey(userInfo, @"id");
        self.msg = PLV_SafeStringForDictKey(userInfo, @"msg");
        self.muteStatus = PLV_SafeIntegerForDictKey(userInfo, @"muteStatus");
        self.phone = PLV_SafeStringForDictKey(userInfo, @"phone");
        self.status = PLV_SafeIntegerForDictKey(userInfo, @"status");
        self.type = PLV_SafeIntegerForDictKey(userInfo, @"type");
        self.userId = PLV_SafeStringForDictKey(userInfo, @"userId");
        self.userName = PLV_SafeStringForDictKey(userInfo, @"userName");
    }
    return self;
}

@end
