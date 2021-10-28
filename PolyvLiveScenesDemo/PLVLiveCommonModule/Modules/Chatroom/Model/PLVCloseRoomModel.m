//
//  PLVCloseRoomModel.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/7.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVCloseRoomModel.h"

@implementation PLVCloseRoomModel

- (NSString *)closeRoomString {
    NSString *string;
    if (self.closeRoom) {
        string = @"聊天室暂时关闭";
    }else {
        string = @"聊天室已开启";
    }
    return string;
}

@end
