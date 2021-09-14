//
//  PLVRoomData.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
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

#pragma mark - [ Public Method ]

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

#pragma mark HTTP Request

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
    [PLVLiveVideoAPI getChannelMenuInfos:self.channelId completion:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
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

#pragma mark Utils

+ (NSString * _Nullable)resolutionStringWithType:(PLVResolutionType)resolutionType {
    NSString *string = nil;
    switch (resolutionType) {
        case PLVResolutionType720P:
            string = @"超清";
            break;
        case PLVResolutionType360P:
            string = @"高清";
            break;
        case PLVResolutionType180P:
            string = @"标清";
            break;
    }
    return string;
}

+ (PLVResolutionType)resolutionTypeWithStreamQuality:(PLVBLinkMicStreamQuality)streamQuality {
    PLVResolutionType resolution = PLVResolutionType180P;
    if (streamQuality == PLVBLinkMicStreamQuality180P) {
        resolution = PLVResolutionType180P;
    }else if (streamQuality == PLVBLinkMicStreamQuality360P){
        resolution = PLVResolutionType360P;
    }else if (streamQuality == PLVBLinkMicStreamQuality720P){
        resolution = PLVResolutionType720P;
    }
    return resolution;
}

+ (PLVBLinkMicStreamQuality)streamQualityWithResolutionType:(PLVResolutionType)resolution {
    PLVBLinkMicStreamQuality streamQuality = PLVBLinkMicStreamQuality180P;
    if (resolution == PLVResolutionType180P) {
        streamQuality = PLVBLinkMicStreamQuality180P;
    }else if (resolution == PLVResolutionType360P){
        streamQuality = PLVBLinkMicStreamQuality360P;
    }else if (resolution == PLVResolutionType720P){
        streamQuality = PLVBLinkMicStreamQuality720P;
    }
    return streamQuality;
}

#pragma mark - [ Private Method ]

/// 配置菜单信息
- (void)updateMenuInfo:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    self.menuInfo = menuInfo;
    self.likeCount = menuInfo.likes.unsignedIntegerValue;
    self.watchCount = menuInfo.pageView.unsignedIntegerValue;
}

#pragma mark Getter

- (NSString *)sessionId {
    if (self.channelInfo) {
        return self.channelInfo.sessionId;
    } else {
        return _sessionId;
    }
}

@end
