//
//  PLVCloseRoomModel.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/7.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVCloseRoomModel.h"
#import "PLVMultiLanguageManager.h"

@implementation PLVCloseRoomModel

- (NSString *)closeRoomString {
    NSString *string;
    if (self.closeRoom) {
        string = PLVLocalizedString(@"聊天室暂时关闭");
    }else {
        string = PLVLocalizedString(@"聊天室已开启");
    }
    return string;
}

@end
