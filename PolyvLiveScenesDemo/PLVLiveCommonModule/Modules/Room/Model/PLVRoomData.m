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

NSString * const PLVStreamerPresenterMixBgURLNormalBlack    = @"https://liveimages.videocc.net/defaultImg/appsdk/backgroud/red.jpg";
NSString * const PLVStreamerPresenterMixBgURLBlue   = @"https://liveimages.videocc.net/defaultImg/appsdk/backgroud/blue.jpg";
NSString * const PLVStreamerPresenterMixBgURLBlack  = @"https://liveimages.videocc.net/defaultImg/appsdk/backgroud/black.jpg";
NSString * const PLVStreamerPresenterMixBgURLGreen  = @"https://liveimages.videocc.net/defaultImg/appsdk/backgroud/green.jpg";
NSString * const PLVStreamerPresenterMixBgURLPurple = @"https://liveimages.videocc.net/defaultImg/appsdk/backgroud/purple.jpg";
NSString * const PLVStreamerPresenterMixBgURLOrange = @"https://liveimages.videocc.net/defaultImg/appsdk/backgroud/orange.jpg";

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
NSString *PLVRoomDataKeyPathSectionEnable = @"sectionEnable";
NSString *PLVRoomDataKeyPathPlaybackListEnable = @"playbackListEnable";

NSString * _Nonnull PLVRoomDataKeyDisableStartPipWhenExitLiveRoom = @"KRoomData_DisableStartPipWhenExitLiveRoom";
NSString * _Nonnull PLVRoomDataKeyDisableStartPipWhenEnterBackground = @"KRoomData_DdisableStartPipWhenEnterBackground";

#pragma mark - PLVPlaybackResumeConfig

@implementation PLVPlaybackResumeConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = YES;
        _headThreshold = 10.0;
        _tailThreshold = 10.0;
    }
    return self;
}

+ (instancetype)defaultConfig {
    return [[self alloc] init];
}

+ (instancetype)configWithHeadThreshold:(NSTimeInterval)headThreshold 
                           tailThreshold:(NSTimeInterval)tailThreshold {
    PLVPlaybackResumeConfig *config = [[self alloc] init];
    config.headThreshold = MAX(0, headThreshold); // 确保不为负数
    config.tailThreshold = MAX(0, tailThreshold); // 确保不为负数
    return config;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"PLVPlaybackResumeConfig: enabled=%@, head=%.1fs, tail=%.1fs", 
            @(self.enabled), self.headThreshold, self.tailThreshold];
}

@end

@interface PLVRoomData ()

@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *menuInfo;
@property (nonatomic, strong) PLVRoomUser *roomUser;
@property (nonatomic, strong) PLVViewLogCustomParam *customParam;
@property (nonatomic, assign) PLVQualityPreferenceType pushQualityPreference;
@property (nonatomic, assign) BOOL transmitMode;

@end

@implementation PLVRoomData

#pragma mark - [ Public Method ]

- (instancetype)init{
    if (self = [super init]){
        _disableStartPipWhenEnterBackground = [[[NSUserDefaults standardUserDefaults]
                                                objectForKey:PLVRoomDataKeyDisableStartPipWhenEnterBackground] boolValue];
        _disableStartPipWhenExitLiveRoom = [[[NSUserDefaults standardUserDefaults]
                                                objectForKey:PLVRoomDataKeyDisableStartPipWhenExitLiveRoom] boolValue];
        _appStartMemberListEnabled = YES;
        _appStartMultiplexingLayoutEnabled = YES;
        _appStartCheckinEnabled = YES;
        _appStartGiftDonateEnabled = YES;
        _appStartGiftEffectEnabled = YES;
        
        // 初始化续播配置
        _playbackResumeConfig = [PLVPlaybackResumeConfig defaultConfig];
    }
    return self;
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
        @"accountId" : [NSString stringWithFormat:@"%@", [PLVLiveVideoConfig sharedInstance].userId],
        @"sessionId" : [NSString stringWithFormat:@"%@", self.sessionId],
    };
    NSDictionary *sm2Key = @{
        @"platformPublicKey" : [NSString stringWithFormat:@"%@", [PLVFSignConfig sharedInstance].serverSM2PublicKey], // 平台公钥(接口提交参数加密用)
        @"userPrivateKey" : [NSString stringWithFormat:@"%@", [PLVFSignConfig sharedInstance].clientSM2PrivateKey] // 用户私钥(接口返回内容解密用)
    };
    
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:userInfo forKey:@"userInfo"];
    [mutableDict setObject:channelInfo forKey:@"channelInfo"];
    [mutableDict setObject:sm2Key forKey:@"sm2Key"];
    [mutableDict addEntriesFromDictionary:sessionDict];
    if (self.menuInfo.promotionInfo) {
        [mutableDict setObject:self.menuInfo.promotionInfo forKey:@"promotionInfo"];
    }
    if ([PLVFdUtil checkDictionaryUseable:extraParam]) {
        [mutableDict addEntriesFromDictionary:extraParam];
    }
    NSString *chatToken = [PLVSocketManager sharedManager].chatToken;
    if ([PLVFdUtil checkStringUseable:chatToken]) {
        [mutableDict setObject:chatToken forKey:@"chatToken"];
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
    } else if (mixLayoutType == PLVMixLayoutType_RightList) {
        streamerMixLayoutType = PLVRTCStreamerMixLayoutType_RightList;
    } else if (mixLayoutType == PLVMixLayoutType_BottomList) {
        streamerMixLayoutType = PLVRTCStreamerMixLayoutType_BottomList;
    }
    return streamerMixLayoutType;
}

+ (NSString * _Nullable)mixLayoutTypeStringWithType:(PLVMixLayoutType)mixLayoutType {
    NSString *string = nil;
    switch (mixLayoutType) {
        case PLVMixLayoutType_Single:
            string = PLVLocalizedString(@"单人演讲");
            break;
        case PLVMixLayoutType_Tile:
            string = PLVLocalizedString(@"宫格视图");
            break;
        case PLVMixLayoutType_MainSpeaker:
            string = PLVLocalizedString(@"底部悬浮");
            break;
        case PLVMixLayoutType_RightList:
            string = PLVLocalizedString(@"右侧列表");
            break;
        case PLVMixLayoutType_BottomList:
            string = PLVLocalizedString(@"底部列表");
            break;
    }
    return string;
}

+ (NSString * _Nullable)mixBackgroundURLStringWithType:(PLVMixLayoutBackgroundColor)colorType {
    switch (colorType) {
        case PLVMixLayoutBackgroundColor_Black:
            return PLVStreamerPresenterMixBgURLBlack;
        case PLVMixLayoutBackgroundColor_Blue:
            return PLVStreamerPresenterMixBgURLBlue;
        case PLVMixLayoutBackgroundColor_Purple:
            return PLVStreamerPresenterMixBgURLPurple;
        case PLVMixLayoutBackgroundColor_Green:
            return PLVStreamerPresenterMixBgURLGreen;
        case PLVMixLayoutBackgroundColor_Orange:
            return PLVStreamerPresenterMixBgURLOrange;
        case PLVMixLayoutBackgroundColor_NormalBlack:
            return PLVStreamerPresenterMixBgURLNormalBlack;
        default:
            return PLVStreamerPresenterMixBgURLBlack;
    }
}

+ (NSString * _Nullable)mixBackgroundDisplayNameForType:(PLVMixLayoutBackgroundColor)colorType {
    switch (colorType) {
        case PLVMixLayoutBackgroundColor_Black:
            return PLVLocalizedString(@"炫彩黑");
        case PLVMixLayoutBackgroundColor_Blue:
            return PLVLocalizedString(@"星河蓝");
        case PLVMixLayoutBackgroundColor_Purple:
            return PLVLocalizedString(@"神秘紫");
        case PLVMixLayoutBackgroundColor_Green:
            return PLVLocalizedString(@"森林绿");
        case PLVMixLayoutBackgroundColor_Orange:
            return PLVLocalizedString(@"落日橘");
        case PLVMixLayoutBackgroundColor_NormalBlack:
            return PLVLocalizedString(@"正常黑");
        default:
            return PLVLocalizedString(@"炫彩黑");
    }
}

+ (PLVMixLayoutBackgroundColor)mixBackgroundColorTypeFromURLString:(NSString * _Nullable)urlString {
    if (!urlString || urlString.length == 0) {
        return PLVMixLayoutBackgroundColor_Black;
    }
    
    if ([urlString isEqualToString:PLVStreamerPresenterMixBgURLBlack]) {
        return PLVMixLayoutBackgroundColor_Black;
    } else if ([urlString isEqualToString:PLVStreamerPresenterMixBgURLBlue]) {
        return PLVMixLayoutBackgroundColor_Blue;
    } else if ([urlString isEqualToString:PLVStreamerPresenterMixBgURLPurple]) {
        return PLVMixLayoutBackgroundColor_Purple;
    } else if ([urlString isEqualToString:PLVStreamerPresenterMixBgURLGreen]) {
        return PLVMixLayoutBackgroundColor_Green;
    } else if ([urlString isEqualToString:PLVStreamerPresenterMixBgURLOrange]) {
        return PLVMixLayoutBackgroundColor_Orange;
    } else if ([urlString isEqualToString:PLVStreamerPresenterMixBgURLNormalBlack]) {
        return PLVMixLayoutBackgroundColor_NormalBlack;
    }
    
    // 默认返回黑色
    return PLVMixLayoutBackgroundColor_Black;
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
    self.transmitMode = menuInfo.transmitMode;
    self.showMixLayoutButtonEnabled = menuInfo.showMixLayoutButtonEnabled;
    self.showOrientationButtonEnabled = menuInfo.showHVScreenButtonEnabled;
    if ([PLVFdUtil checkStringUseable:menuInfo.defaultScreenOrientation]) {
        if ([menuInfo.defaultScreenOrientation isEqualToString:@"horizontal"]) {
            self.appDefaultLandScapeEnabled = YES;
        } else if ([menuInfo.defaultScreenOrientation isEqualToString:@"portrait"]) {
            self.appDefaultLandScapeEnabled = NO;
        }
    }
    
    PLVChannelType apiChannelType = PLVChannelTypeUnknown;
    if ([menuInfo.scene isEqualToString:@"ppt"]) {
        apiChannelType = PLVChannelTypePPT;
    } else if ([menuInfo.scene isEqualToString:@"alone"] || [menuInfo.scene isEqualToString:@"topclass"]) {
        apiChannelType = PLVChannelTypeAlone;
    }
    self.channelType = apiChannelType;
}

- (NSString *)getSafeString:(NSString *)name{
    NSString *newName = name? name: @"";
    return newName;
}

- (void)saveMenuInfo{
    if (!self.menuInfo || !self.roomUser.viewerId || !self.channelId) {
        return;
    }
    
    // 保存部分menuInfo 字段到本地
    // NSUserDefault 保存NSDictionary
    // viewerId + channelId 作为 key，保存 menuInfo 字段到本地
    NSString *key = [NSString stringWithFormat:@"%@_%@", self.roomUser.viewerId, self.channelId];
    NSMutableDictionary *menuInfoDict = [NSMutableDictionary dictionary];
    // 基础数据 通过检测
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.name] forKey:@"name"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.coverImage] forKey:@"coverImage"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.publisher] forKey:@"publisher"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.likes] forKey:@"likes"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.pageView] forKey:@"pageView"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.startTime] forKey:@"startTime"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.status] forKey:@"status"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.watchStatus] forKey:@"watchStatus"];
    [menuInfoDict setObject:@[] forKey:@"channelMenus"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.scene] forKey:@"scene"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.playBackEnabled] forKey:@"playbackEnabled"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.splashImg] forKey:@"splashImg"];
    [menuInfoDict setObject:[NSNumber numberWithBool: self.menuInfo.hasPlayback] forKey:@"hasPlayback"];

    // 所需数据
    [menuInfoDict setObject:[NSNumber numberWithBool: self.menuInfo.viewerPptTurningEnabled] forKey:@"viewerPptTurningEnabled"];
    [menuInfoDict setObject:[NSNumber numberWithBool: self.menuInfo.playbackMultiplierEnabled] forKey:@"playbackMultiplierEnabled"];
    [menuInfoDict setObject:[NSNumber numberWithBool: self.menuInfo.playbackProgressBarEnabled] forKey:@"playbackProgressBarEnabled"];
    [menuInfoDict setObject:[self getSafeString:self.menuInfo.playbackProgressBarOperationType] forKey:@"playbackProgressBarOperationType"];
    [menuInfoDict setObject:[NSNumber numberWithBool: self.menuInfo.showPlayButtonEnabled] forKey:@"showPlayButtonEnabled"];
    [[NSUserDefaults standardUserDefaults] setObject:menuInfoDict forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreMenuInfo {
    NSString *key = [NSString stringWithFormat:@"%@_%@", self.roomUser.viewerId, self.channelId];
    NSDictionary *menuInfoDict = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (menuInfoDict) {
        PLVLiveVideoChannelMenuInfo *item = [[PLVLiveVideoChannelMenuInfo alloc] initWithDictionary:menuInfoDict];
        self.menuInfo = item;
    }
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
            return PLVMixLayoutType_Single;
        } else if ([self.menuInfo.mobileAlonePushMixMode isEqualToString:@"bottom"]) {
            return PLVMixLayoutType_BottomList;
        } else if ([self.menuInfo.mobileAlonePushMixMode isEqualToString:@"bottomsuspend"]) {
            return PLVMixLayoutType_MainSpeaker;
        } else if ([self.menuInfo.mobileAlonePushMixMode isEqualToString:@"right"]) {
            return PLVMixLayoutType_RightList;
        }
    }
    return PLVMixLayoutType_Tile; // 默认连麦布局为平铺模式;
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

#pragma mark 美颜开关
- (BOOL)lightBeautyEnabled{
    if ([PLVFdUtil checkStringUseable:self.appBeautyType] && [self.appBeautyType isEqualToString:@"gpu"]){
        return YES;
    }
    return NO;
}

// 暂时和轻美颜功能绑定
- (BOOL)mattingEnabled{
    return [self lightBeautyEnabled];
}

- (BOOL)canUseBeauty{
    if (self.appBeautyEnabled){
        return YES;
    }
    else if (self.lightBeautyEnabled){
        if ([PLVFdUtil checkStringUseable:self.menuInfo.rtcType] && [self.menuInfo.rtcType isEqualToString:@"trtc"]){
            return YES;
        }
    }
    return NO;
}

#pragma mark -- 小窗控制开关
- (BOOL)canAutoStartPictureInPicture{
    BOOL can = NO;
    if (@available(iOS 15.0, *)){
        if (self.menuInfo.fenestrulePlayEnabled &&
            !self.captureScreenProtect &&
            !self.systemScreenShotProtect &&
            !self.disableStartPipWhenExitLiveRoom &&
            !self.disableStartPipWhenEnterBackground){
            
            can = YES;
        }
    }
           
    return can;
}

- (BOOL)needStartPictureInPictureWhenExitLiveRoom{
    BOOL need = NO;
    if (@available(iOS 15.0, *)){
        if ( self.menuInfo.fenestrulePlayEnabled &&
            !self.captureScreenProtect &&
            !self.systemScreenShotProtect &&
            !self.disableStartPipWhenExitLiveRoom){
            need = YES;
        }
    }
    
    return need;
}

- (BOOL)canSupportPictureInPicure{
    BOOL need = NO;
    if (@available(iOS 14.0, *)){
        if ( self.menuInfo.fenestrulePlayEnabled &&
            !self.captureScreenProtect &&
            !self.systemScreenShotProtect ){
            
            need = YES;
        }
    }
          
    return need;
}

- (void)setDisableStartPipWhenEnterBackground:(BOOL)disableStartPipWhenEnterBackground{
    _disableStartPipWhenEnterBackground = disableStartPipWhenEnterBackground;
    NSNumber* value = [NSNumber numberWithBool:disableStartPipWhenEnterBackground];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:PLVRoomDataKeyDisableStartPipWhenEnterBackground];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setDisableStartPipWhenExitLiveRoom:(BOOL)disableStartPipWhenExitLiveRoom{
    _disableStartPipWhenExitLiveRoom = disableStartPipWhenExitLiveRoom;
    NSNumber* value = [NSNumber numberWithBool:disableStartPipWhenExitLiveRoom];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:PLVRoomDataKeyDisableStartPipWhenExitLiveRoom];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
