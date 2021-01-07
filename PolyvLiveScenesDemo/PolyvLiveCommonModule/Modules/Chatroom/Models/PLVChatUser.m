//
//  PLVChatUser.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVChatUser.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import <PolyvFoundationSDK/PLVColorUtil.h>

@implementation PLVChatUser

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo {
    if (![userInfo isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.banned = PLV_SafeBoolForDictKey(userInfo, @"banned");
        self.userId = PLV_SafeStringForDictKey(userInfo, @"userId");
        self.userName = PLV_SafeStringForDictKey(userInfo, @"nick");
        
        self.role = PLV_SafeStringForDictKey(userInfo, @"userType");
        self.userType = [PLVRoomUser userTypeWithUserTypeString:self.role];
        self.specialIdentity = [PLVRoomUser isSpecialIdentityWithUserType:self.userType];
        
        // 自定义参数
        NSDictionary *authorization = userInfo[@"authorization"];
        NSString *actor = PLV_SafeStringForDictKey(userInfo, @"actor");
        if ([authorization isKindOfClass:NSDictionary.class]) {
            self.actor = PLV_SafeStringForDictKey(authorization, @"actor");
            self.actorTextColor = [PLVColorUtil colorFromHexString:authorization[@"fColor"]];
            self.actorBackgroundColor = [PLVColorUtil colorFromHexString:authorization[@"bgColor"]];
        }else if (actor && actor.length) {
            self.actor = actor;
        }
        
        self.avatarUrl = PLV_SafeStringForDictKey(userInfo, @"pic");
        // 处理"//"类型开头的地址为 HTTPS
        // 不处理其他类型头像地址，如 “http://” 开头地址，此地址可能为第三方地址，无法判断是否支持 HTTPS
        if ([self.avatarUrl hasPrefix:@"//"]) {
            self.avatarUrl = [@"https:" stringByAppendingString:self.avatarUrl];
        }
        // URL percent-Encoding，头像地址中含有中文字符问题
        self.avatarUrl = [PLVFdUtil stringBySafeAddingPercentEncoding:self.avatarUrl];
    }
    return self;
}

- (BOOL)isUserSpecial {
    BOOL hasActor = (self.actor && [self.actor isKindOfClass:[NSString class]] && self.actor.length > 0);
    return (self.specialIdentity || hasActor);
}

@end
