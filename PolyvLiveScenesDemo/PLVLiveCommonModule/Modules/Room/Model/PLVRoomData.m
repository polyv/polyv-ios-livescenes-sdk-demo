//
//  PLVRoomData.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVRoomData.h"
#import "PLVMultiLanguageManager.h"
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
NSString *PLVRoomDataKeyPathHiClassStatus   = @"hiClassStatus";
NSString *PLVRoomDataKeyPathVid   = @"vid";
NSString *PLVRoomDataKeyPathSipPassword   = @"sipPassword";

@interface PLVRoomData ()

@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *menuInfo;
@property (nonatomic, strong) PLVRoomUser *roomUser;
@property (nonatomic, strong) PLVViewLogCustomParam *customParam;
@property (nonatomic, assign) PLVQualityPreferenceType pushQualityPreference;

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

- (void)setupPushQualityPreference:(NSString *)pushQualityPreferenceString {
    if (![PLVFdUtil checkStringUseable:pushQualityPreferenceString]) {
        self.pushQualityPreference = PLVQualityPreferenceTypeClear;
    } else {
        if ([pushQualityPreferenceString isEqualToString:@"PREFER_BETTER_QUALITY"]) {
            self.pushQualityPreference = PLVQualityPreferenceTypeClear;
        } else if([pushQualityPreferenceString isEqualToString:@"PREFER_BETTER_FLUENCY"]) {
            self.pushQualityPreference = PLVQualityPreferenceTypeSmooth;
        } else {
            self.pushQualityPreference = PLVQualityPreferenceTypeClear;
        }
    }
}

- (NSDictionary *)nativeAppUserParamsWithExtraParam:(NSDictionary * _Nullable)extraParam {
    NSDictionary *userInfo = @{
        @"nick" : [NSString stringWithFormat:@"%@", self.roomUser.viewerName],
        @"userId" : [NSString stringWithFormat:@"%@", self.roomUser.viewerId],
        @"pic" : [NSString stringWithFormat:@"%@", self.roomUser.viewerAvatar]
    };
    NSDictionary *channelInfo = @{
        @"channelId" : [NSString stringWithFormat:@"%@", self.channelId],
        @"roomId" : [NSString stringWithFormat:@"%@", self.channelId]
    };
    NSDictionary *sessionDict = @{
        @"appId" : [NSString stringWithFormat:@"%@", [PLVLiveVideoConfig sharedInstance].appId],
        @"appSecret" : [NSString stringWithFormat:@"%@", [PLVLiveVideoConfig sharedInstance].appSecret],
        @"sessionId" : [NSString stringWithFormat:@"%@", self.sessionId]
    };
    
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:userInfo forKey:@"userInfo"];
    [mutableDict setObject:channelInfo forKey:@"channelInfo"];
    [mutableDict addEntriesFromDictionary:sessionDict];
    if ([PLVFdUtil checkDictionaryUseable:extraParam]) {
        [mutableDict addEntriesFromDictionary:extraParam];
    }
    
    return mutableDict;
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
            weakSelf.watchFeedbackEnabled = [switchInfo[@"watchFeedbackEnabled"] boolValue];
            weakSelf.conditionLotteryEnabled = [switchInfo[@"conditionLotteryEnabled"] boolValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomFunctionGotNotification object:switchInfo];
        }
    } failure:^(NSError * _Nonnull error) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s request channel function switch failed with 【%@】", __FUNCTION__, error);
    }];
}

- (void)updateSipInfo {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestSIPInfoWithChannelId:self.channelId completion:^(NSDictionary *data) {
        weakSelf.sipNumber = PLV_SafeStringForDictKey(data, @"ucSipPhone");
        weakSelf.sipPassword = PLV_SafeStringForDictKey(data, @"ucSipId");
    } failure:^(NSError *error) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s request SIP Info failed with 【%@】", __FUNCTION__, error);
    }];
}

#pragma mark Utils

+ (NSString * _Nullable)resolutionStringWithType:(PLVResolutionType)resolutionType {
    NSString *string = nil;
    switch (resolutionType) {
        case PLVResolutionType1080P:
            string = PLVLocalizedString(@"超高清");
            break;
        case PLVResolutionType720P:
            string = PLVLocalizedString(@"超清");
            break;
        case PLVResolutionType480P:
            string = PLVLocalizedString(@"高标清");
            break;
        case PLVResolutionType360P:
            string = PLVLocalizedString(@"高清");
            break;
        case PLVResolutionType180P:
            string = PLVLocalizedString(@"标清");
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
    }else if (streamQuality == PLVBLinkMicStreamQuality1080P){
        resolution = PLVResolutionType1080P;
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
    }else if (resolution == PLVResolutionType1080P){
        streamQuality = PLVBLinkMicStreamQuality1080P;
    }
    return streamQuality;
}

+ (PLVMixLayoutType)mixLayoutTypeWithStreamerMixLayoutType:(PLVRTCStreamerMixLayoutType)streamerType {
    PLVMixLayoutType mixLayoutType = PLVMixLayoutType_Single;
    if (streamerType == PLVRTCStreamerMixLayoutType_Single) {
        mixLayoutType = PLVMixLayoutType_Single;
    }else if (streamerType == PLVRTCStreamerMixLayoutType_Tile){
        mixLayoutType = PLVMixLayoutType_Tile;
    }else if (streamerType == PLVRTCStreamerMixLayoutType_MainSpeaker){
        mixLayoutType = PLVMixLayoutType_MainSpeaker;
    }
    return mixLayoutType;
}

+ (PLVRTCStreamerMixLayoutType)streamerMixLayoutTypeWithMixLayoutType:(PLVMixLayoutType)mixLayoutType {
    PLVRTCStreamerMixLayoutType streamerMixLayoutType = PLVRTCStreamerMixLayoutType_Unknown;
    if (mixLayoutType == PLVMixLayoutType_Single) {
        streamerMixLayoutType = PLVRTCStreamerMixLayoutType_Single;
    }else if (mixLayoutType == PLVMixLayoutType_Tile){
        streamerMixLayoutType = PLVRTCStreamerMixLayoutType_Tile;
    }else if (mixLayoutType == PLVMixLayoutType_MainSpeaker){
        streamerMixLayoutType = PLVRTCStreamerMixLayoutType_MainSpeaker;
    }
    return streamerMixLayoutType;
}

+ (NSString * _Nullable)mixLayoutTypeStringWithType:(PLVMixLayoutType)mixLayoutType {
    NSString *string = nil;
    switch (mixLayoutType) {
        case PLVMixLayoutType_Single:
            string = PLVLocalizedString(@"单人模式");
            break;
        case PLVMixLayoutType_Tile:
            string = PLVLocalizedString(@"平铺模式");
            break;
        case PLVMixLayoutType_MainSpeaker:
            string = PLVLocalizedString(@"主讲模式");
            break;
    }
    return string;
}

#pragma mark - [ Private Method ]

/// 配置菜单信息
- (void)updateMenuInfo:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    self.menuInfo = menuInfo;
    self.likeCount = menuInfo.likes.unsignedIntegerValue;
    self.watchCount = menuInfo.pageView.unsignedIntegerValue;
    self.restrictChatEnabled = menuInfo.restrictChatEnabled;
    self.maxViewerCount = menuInfo.maxViewer.unsignedIntegerValue;
    self.linkmicNewStrategyEnabled = menuInfo.newMicEnabled;
    self.defaultOpenMicLinkEnabled = menuInfo.defaultOpenMicLinkEnabled;
}

#pragma mark Getter & Setter

- (void)setChannelInfo:(PLVChannelInfoModel *)channelInfo {
    _channelInfo = channelInfo;
    
    [[PLVWLogReporterManager sharedManager] setupSessionId:self.channelInfo.sessionId];
}

- (NSString *)sessionId {
    if (self.channelInfo) {
        return self.channelInfo.sessionId;
    } else {
        return _sessionId;
    }
}

- (BOOL)liveStatusIsLiving {
    if (self.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        return _liveStatusIsLiving;
    }
    return NO;
}

- (PLVBLinkMicStreamScale)streamScale {
    if (self.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        return _streamScale;
    }
    return PLVBLinkMicStreamScale16_9;
}

- (PLVMixLayoutType)defaultMixLayoutType {
    if ([PLVFdUtil checkStringUseable:self.menuInfo.mobileAlonePushMixMode]) {
        if ([self.menuInfo.mobileAlonePushMixMode isEqualToString:@"flatten"]) {
            return PLVMixLayoutType_Tile;
        } else if ([self.menuInfo.mobileAlonePushMixMode isEqualToString:@"lecture"]) {
            return PLVMixLayoutType_MainSpeaker;
        }
    }
    return PLVMixLayoutType_Tile; // 默认混流布局为平铺模式;
}

- (void)setAppWebStartResolutionRatio:(NSString *)appWebStartResolutionRatio {
    _appWebStartResolutionRatio = appWebStartResolutionRatio;
    if (![PLVFdUtil checkStringUseable:appWebStartResolutionRatio]) {
        return;
    }
    
    if ([appWebStartResolutionRatio isEqualToString:@"16:9"]) {
        _streamScale = PLVBLinkMicStreamScale16_9;
    } else if ([appWebStartResolutionRatio isEqualToString:@"4:3"]) {
        _streamScale = PLVBLinkMicStreamScale4_3;
    }
}

- (PLVChannelLinkMicMediaType)defaultChannelLinkMicMediaType {
    if ([PLVFdUtil checkStringUseable:self.defaultOpenMicLinkEnabled]) {
        if ([self.defaultOpenMicLinkEnabled isEqualToString:@"audio"]) {
            return PLVChannelLinkMicMediaType_Audio;
        } else if ([self.defaultOpenMicLinkEnabled isEqualToString:@"video"]) {
            return PLVChannelLinkMicMediaType_Video;
        }
    }
    return PLVChannelLinkMicMediaType_Unknown;
}

@end
