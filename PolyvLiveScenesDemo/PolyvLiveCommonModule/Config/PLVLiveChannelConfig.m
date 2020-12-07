//
//  PLVLiveChannel.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/26.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveChannelConfig.h"

@interface PLVLiveChannelConfig ()

@property (nonatomic, strong) PLVLiveAccount *account;
@property (nonatomic, strong) PLVLiveWatchUser *watchUser;

@property (nonatomic, copy) NSString *channelId;

@property (nonatomic, copy) NSString *vid;

@end

@implementation PLVLiveChannelConfig
// PLVLiveConfigProtocol
@synthesize chaseFrame;
@synthesize liveParam1;
@synthesize liveParam2;
@synthesize liveParam4;
@synthesize liveParam5;

// PLVVodConfigProtocol
@synthesize vodSid;
@synthesize vodViewerAvatar;
@synthesize vodParam1;
@synthesize vodParam2;
@synthesize vodParam3;
@synthesize vodParam4;
@synthesize vodParam5;
@synthesize vodKey1;
@synthesize vodKey2;
@synthesize vodKey3;

+ (instancetype)channelWithChannelId:(NSString *)channelId watchUser:(PLVLiveWatchUser *)watchUser account:(PLVLiveAccount *)account {
    PLVLiveChannelConfig *channel = [[PLVLiveChannelConfig alloc] init];
    channel.channelId = channelId;
    channel.watchUser = watchUser;
    channel.account = account;
    
    return channel;
}

+ (instancetype)channelWithChannelId:(NSString *)channelId vid:(NSString *)vid watchUser:(PLVLiveWatchUser *)watchUser account:(PLVLiveAccount *)account {
    PLVLiveChannelConfig *channel = [[PLVLiveChannelConfig alloc] init];
    channel.channelId = channelId;
    channel.vid = vid;
    channel.watchUser = watchUser;
    channel.account = account;
    
    return channel;
}

+ (instancetype)channelWithChannelId:(NSString *)channelId vid:(NSString *)vid account:(PLVLiveAccount *)account {
    return [self channelWithChannelId:channelId vid:vid watchUser:nil account:account];
}

@end
