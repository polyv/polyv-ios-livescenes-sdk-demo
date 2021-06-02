//
//  PLVRoomData.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVRoomData.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NSString *PLVLCChatroomFunctionGotNotification = @"PLVLCChatroomFunctionGotNotification";

NSString *PLVRoomDataKeyPathSessionId   = @"sessionId";
NSString *PLVRoomDataKeyPathOnlineCount = @"onlineCount";
NSString *PLVRoomDataKeyPathLikeCount   = @"likeCount";
NSString *PLVRoomDataKeyPathWatchCount  = @"watchCount";
NSString *PLVRoomDataKeyPathPlaying     = @"playing";
NSString *PLVRoomDataKeyPathChannelInfo = @"channelInfo";
NSString *PLVRoomDataKeyPathMenuInfo    = @"menuInfo";
NSString *PLVRoomDataKeyPathLiveState   = @"liveState";

@interface PLVRoomData ()

@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *menuInfo;
@property (nonatomic, strong) PLVRoomUser *roomUser;
@property (nonatomic, strong) PLVViewLogCustomParam *customParam;

@end

@implementation PLVRoomData

#pragma mark - Getter

- (NSString *)sessionId {
    if (self.channelInfo) {
        return self.channelInfo.sessionId;
    } else {
        return _sessionId;
    }
}

#pragma mark - 修改属性

/// 配置菜单信息
- (void)updateMenuInfo:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    self.menuInfo = menuInfo;
    self.likeCount = menuInfo.likes.unsignedIntegerValue;
    self.watchCount = menuInfo.pageView.unsignedIntegerValue;
}

- (void)setupRoomUser:(PLVRoomUser *)roomUser {
    if (!roomUser) {
        return;
    }
    
    self.roomUser = roomUser;
    
    // 统计后台的自定义参数，根据roomUser的属性配置默认统计参数
    PLVViewLogCustomParam *param = [[PLVViewLogCustomParam alloc] init];
    param.liveParam1 = roomUser.viewerId;
    param.liveParam2 = roomUser.viewerName;
    param.vodSid = roomUser.viewerId;
    param.vodParam2 = roomUser.viewerName;
    param.vodViewerAvatar = roomUser.viewerAvatar;
    self.customParam = param;
}

#pragma mark - 接口请求

- (void)requestChannelDetail:(void (^)(PLVLiveVideoChannelMenuInfo *))completion{
    if (!self.channelId || ![self.channelId isKindOfClass:[NSString class]]) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s request channel failed with 【param illegal】(channelId:%@)", __FUNCTION__, self.channelId);
        return;
    }
    
    static BOOL loading = NO;
    if (loading) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s request channel failed with 【repeat request】", __FUNCTION__);
        return;
    }
    loading = YES;
    
    __weak typeof(self)weakSelf = self;
    [PLVLiveVideoAPI getChannelMenuInfos:self.channelId.integerValue completion:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
        loading = NO;
        [weakSelf updateMenuInfo:channelMenuInfo];
        if (completion) { completion(channelMenuInfo); }
    } failure:^(NSError *error) {
        loading = NO;
        if (completion) { completion(nil); }
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s request channel failed with 【%@】", __FUNCTION__, error);
    }];
}

- (void)reportViewerIncrease {
    if (!self.channelId || ![self.channelId isKindOfClass:[NSString class]]) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s report viewer increase failed with 【param illegal】(channelId:%@)", __FUNCTION__, self.channelId);
        return;
    }
    
    static BOOL loading = NO;
    if (loading) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s report viewer increase failed with 【repeat request】", __FUNCTION__);
        return;
    }
    loading = YES;
    
    __weak typeof(self)weakSelf = self;
    [PLVLiveVideoAPI increaseViewerWithChannelId:self.channelId times:1 completion:^(NSInteger viewers){
        loading = NO;
        weakSelf.watchCount++;
    } failure:^(NSError *error) {
        loading = NO;
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s report viewer increase failed with 【%@】", __FUNCTION__, error);
    }];
}

- (void)requestChannelFunctionSwitch {
    __weak typeof(self) weakSelf = self;
    NSUInteger channelId = [self.channelId longLongValue];
    [PLVLiveVideoAPI loadChatroomFunctionSwitchWithRoomId:channelId completion:^(NSDictionary *switchInfo) {
        if (switchInfo && [switchInfo isKindOfClass:NSDictionary.class]) {
            weakSelf.welcomeShowDisable = ![switchInfo[@"welcome"] boolValue];
            weakSelf.sendImageDisable = ![switchInfo[@"viewerSendImgEnabled"] boolValue];
            weakSelf.sendLikeDisable = ![switchInfo[@"sendFlowersEnabled"] boolValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomFunctionGotNotification object:switchInfo];
        }
    } failure:^(NSError * _Nonnull error) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s request channel function switch failed with 【%@】", __FUNCTION__, error);
    }];
}

#pragma mark 获取商品列表
- (void)requestCommodityList:(NSUInteger)channelId rank:(NSUInteger)rank count:(NSUInteger)count completion:(void (^)(NSUInteger total, NSArray<PLVCommodityModel *> *commoditys))completion failure:(void (^)(NSError *))failure {
    [PLVLiveVideoAPI loadCommodityList:channelId rank:rank count:count completion:completion failure:failure];
}

@end
