//
//  PLVLiveRoomData.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/26.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveRoomData.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>

NSString *PLVLCChatroomFunctionGotNotification = @"PLVLCChatroomFunctionGotNotification";

@interface PLVLiveRoomData ()

@property (nonatomic, strong) PLVLiveChannelConfig *channel;
@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *channelMenuInfo;

@end

@implementation PLVLiveRoomData

- (instancetype)init
{
    NSLog(@"PLVLiveRoomData 初始化失败，请调用 %@ 或 %@ 方法初始化", NSStringFromSelector(@selector(initWithLiveChannel:)),NSStringFromSelector(@selector(liveRoomDataWithLiveChannel:)));
    return nil;
}

#pragma mark Init method

- (instancetype)initWithLiveChannel:(PLVLiveChannelConfig *)channel {
    self = [super init];
    if (self) {
        self.channel = channel;
    }
    return self;
}

+ (instancetype)liveRoomDataWithLiveChannel:(PLVLiveChannelConfig *)channel {
    return [[PLVLiveRoomData alloc] initWithLiveChannel:channel];
}

#pragma mark API

- (void)updateChannelInfo:(PLVLiveVideoChannelMenuInfo *)channelInfo {
    self.channelMenuInfo = channelInfo;
    self.likeCount = channelInfo.likes.unsignedIntegerValue;
    self.watchViewCount = channelInfo.pageView.unsignedIntegerValue;
}

- (void)loadFunctionSwitch {
    __weak typeof(self) weakSelf = self;
    NSUInteger channelId = [self.channel.channelId longLongValue];
    [PLVLiveVideoAPI loadChatroomFunctionSwitchWithRoomId:channelId completion:^(NSDictionary *switchInfo) {
        if (switchInfo && [switchInfo isKindOfClass:NSDictionary.class]) {
            weakSelf.welcomeShowDisable = ![switchInfo[@"welcome"] boolValue];
            weakSelf.sendImageDisable = ![switchInfo[@"viewerSendImgEnabled"] boolValue];
            weakSelf.sendLikeDisable = ![switchInfo[@"sendFlowersEnabled"] boolValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomFunctionGotNotification object:switchInfo];
        }
    } failure:nil];
}

#pragma mark - 便捷属性获取
- (CGFloat)currentTime{
    return self.duration * self.playedProgress;
}

- (NSString *)channelId {
    return self.channel.channelId;
}

- (NSString *)vid {
    return self.channel.vid;
}

- (NSString *)userIdForAccount {
    return self.channel.account.userId;
}

- (NSString *)userIdForWatchUser {
    return self.channel.watchUser.viewerId;
}

- (PLVLiveAccount *)account {
    return self.channel.account;
}

- (PLVLiveWatchUser *)watchUser {
    return self.channel.watchUser;
}

@end
