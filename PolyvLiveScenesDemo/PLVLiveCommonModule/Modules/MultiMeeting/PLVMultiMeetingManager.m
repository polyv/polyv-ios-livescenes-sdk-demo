//
//  PLVMultiMeetingManager.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/10/10.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVMultiMeetingManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

@implementation PLVMultiMeetingModel

- (void)setValue:(id)value forKey:(NSString *)key {
    if (value && (![key isEqualToString:@"pv"] || ![key isEqualToString:@"startTime"])) {
        // 将vlue不为nil（null）的值转为字符串类型
        value = [NSString stringWithFormat:@"%@",value];
    } else if ([key isEqualToString:@"startTime"] && !value) {
        value = @(0);
    }
    [super setValue:value forKey:key];
}

- (PLVMultiMeetingLiveStatus)liveStatusType {
    if (![PLVFdUtil checkStringUseable:self.liveStatus]) {
        return PLVMultiMeetingLiveStatus_End;
    } else if ([self.liveStatus isEqualToString:@"live"]) {
        return PLVMultiMeetingLiveStatus_Live;
    } else if ([self.liveStatus isEqualToString:@"unStart"]) {
        return PLVMultiMeetingLiveStatus_UnStart;
    } else if ([self.liveStatus isEqualToString:@"waiting"]) {
        return PLVMultiMeetingLiveStatus_Waiting;
    } else if ([self.liveStatus isEqualToString:@"playback"]) {
        return PLVMultiMeetingLiveStatus_Playback;
    } else if ([self.liveStatus isEqualToString:@"end"]) {
        return PLVMultiMeetingLiveStatus_End;
    } else {
        return PLVMultiMeetingLiveStatus_End;
    }
}

- (NSString *)splashImgUrl {
    NSString *url = self.splashImg;
    if (![PLVFdUtil checkStringUseable:url]) {
        return kPLVMultiMeetingSplashImgURLString;
    } else if ([url hasPrefix:@"//"]) {
        url = [@"https:" stringByAppendingString:url];
    }
    return url;
}

@end

@implementation PLVMultiMeetingManager

#pragma mark - [ Life Period ]

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static PLVMultiMeetingManager *mananger = nil;
    dispatch_once(&onceToken, ^{
        mananger = [[self alloc] init];
    });
    return mananger;
}

- (void)jumpToMultiMeeting:(NSString *)channelId isPlayback:(BOOL)isPlayback {
    _jumpCallback ? _jumpCallback(channelId, isPlayback) : nil;
}

@end
