//
//  PLVLiveRoomManager.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/8/3.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveRoomManager.h"
#import <PLVLiveScenesSDK/PLVLiveVideoAPI.h>
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>

@interface PLVLiveRoomManager ()
    
@property (nonatomic, strong) PLVLiveRoomData *roomData;

@end

@implementation PLVLiveRoomManager

- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData {
    self = [super init];
    if (self) {
        self.roomData = roomData;
        
        PLVLiveChannelConfig *channel = roomData.channel;
        
        // 配置直播、点播日志的默认观众id和昵称
        channel.liveParam1 = channel.liveParam1 ?: channel.watchUser.viewerId;
        channel.liveParam2 = channel.liveParam2 ?: channel.watchUser.viewerName;
        channel.vodSid = channel.vodSid ?: channel.watchUser.viewerId;
        channel.vodParam2 = channel.vodParam2 ?: channel.watchUser.viewerName;
        channel.vodViewerAvatar = channel.vodViewerAvatar ?: channel.watchUser.viewerAvatar;
        
        // 兼容 SDK 层配置
        [PLVLiveVideoConfig liveConfigWithUserId:channel.account.userId appId:channel.account.appId appSecret:channel.account.appSecret];
        
        PLVLiveVideoConfig *videoConfig = PLVLiveVideoConfig.sharedInstance;
        videoConfig.channelId = channel.channelId;
        videoConfig.vodId = channel.vid;
        videoConfig.videoToolBox = channel.videoToolBox;
        videoConfig.enableHttpDNS = channel.enableHttpDNS;
    }
    return self;
}

- (void)requestLiveDetail {
    NSString *channelId = self.roomData.channelId;
    if (!channelId || ![channelId isKindOfClass:NSString.class]) {
        return;
    }
    
    static BOOL loading = NO;
    if (loading) {
        return;
    }
    loading = YES;
    
    __weak typeof(self)weakSelf = self;
    [PLVLiveVideoAPI getChannelMenuInfos:channelId.integerValue completion:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
        loading = NO;
        [weakSelf.roomData updateChannelInfo:channelMenuInfo];
    } failure:^(NSError *error) {
        loading = NO;
        NSLog(@"频道菜单获取失败！%@",error);
    }];
}

- (void)requestPageview {
    NSString *channelId = self.roomData.channelId;
    if (!channelId || ![channelId isKindOfClass:NSString.class]) {
        return;
    }
    
    // 避免短时间高频调用
    static int suceess = 0;
    if (suceess == -1) {
        return;
    }
    suceess = -1;
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PLVLiveVideoAPI increaseViewerWithChannelId:channelId times:1 completion:^(NSInteger viewers){
            suceess = 1;
            weakSelf.roomData.watchViewCount ++;
            NSLog(@"exposure:%ld",viewers);
        } failure:^(NSError * _Nonnull error) {
            suceess = 0;
            NSLog(@"increaseExposure, error:%@",error.localizedDescription);
        }];
    });
}

@end
