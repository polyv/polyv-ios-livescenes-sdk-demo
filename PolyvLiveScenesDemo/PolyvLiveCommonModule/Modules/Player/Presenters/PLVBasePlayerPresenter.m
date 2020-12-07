//
//  PLVBasePlayerPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/10.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVBasePlayerPresenter.h"

@implementation PLVBasePlayerPresenter

- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData {
    self = [super init];
    if (self) {
        self.roomData = roomData;
    }
    return self;
}

- (void)setupPlayerWithDisplayView:(UIView *)displayView {
}

- (void)setPlayerFrame:(CGRect)rect {
}

- (void)destroy {
}

- (void)cleanAllPlayers{
    
}

@end
