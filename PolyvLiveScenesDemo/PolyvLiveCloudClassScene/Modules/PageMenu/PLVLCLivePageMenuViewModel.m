//
//  PLVLCLivePageMenuViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCLivePageMenuViewModel.h"

@implementation PLVLCLivePageMenuViewModel

- (PLVLCLivePageMenuType)menuTypeWithMenu:(NSString *)typeString {
    if (!typeString || ![typeString isKindOfClass:[NSString class]] || typeString.length == 0) {
        return PLVLCLivePageMenuTypeUnknown;
    }
    
    if ([typeString isEqualToString:@"desc"]) {
        return PLVLCLivePageMenuTypeDesc;
    } else if ([typeString isEqualToString:@"chat"]) {
        return PLVLCLivePageMenuTypeChat;
    } else if ([typeString isEqualToString:@"quiz"]) {
        return PLVLCLivePageMenuTypeQuiz;
    } else if ([typeString isEqualToString:@"tuwen"]) {
        return PLVLCLivePageMenuTypeTuwen;
    } else if ([typeString isEqualToString:@"text"]) {
        return PLVLCLivePageMenuTypeText;
    } else if ([typeString isEqualToString:@"iframe"]) {
        return PLVLCLivePageMenuTypeIframe;
    }
    return PLVLCLivePageMenuTypeUnknown;
}

@end
