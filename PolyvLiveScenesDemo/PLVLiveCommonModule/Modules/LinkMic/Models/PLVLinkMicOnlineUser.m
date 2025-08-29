//
//  PLVLinkMicOnlineUser.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/19.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLinkMicOnlineUser.h"
#import "PLVChatUser.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLinkMicOnlineUser ()

#pragma mark 对象
@property (nonatomic, strong) UIView * rtcView;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserWillDeallocBlock> * willDealloc_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserMicOpenChangedBlock> * micOpenChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCameraShouldShowChangedBlock> * cameraShouldShowChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCameraFrontChangedBlock> * cameraFrontChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCameraTorchOpenChangedBlock> * cameraTorchOpenChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock> * currentStatusVoiceChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock> * currentSpeakerAuthChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserScreenShareOpenChangedBlock> * currentScreenShareOpenChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCurrentFirstSiteChangedBlock> * currentFirstSiteChanged_MultiReceiverMap;
@property (nonatomic, strong) NSTimer *forceStopLinkMicTimer;
@property (nonatomic, assign) NSUInteger forceStopLinkMicTimerCount;

#pragma mark 数据
@property (nonatomic, copy) NSString * userId;
@property (nonatomic, copy) NSString * linkMicUserId;
@property (nonatomic, copy, nullable) NSString * actor;
@property (nonatomic, copy, nullable) NSString * nickname;
@property (nonatomic, copy, nullable) NSString * avatarPic;
@property (nonatomic, assign) PLVSocketUserType userType;
@property (nonatomic, assign) BOOL localUser;
@property (nonatomic, strong) NSDictionary * originalUserDict;
@property (nonatomic, assign) NSTimeInterval linkMicTimestamp; /// 创建用户的连麦时间戳
@property (nonatomic, assign) NSTimeInterval currentLinkMicDuration; /// 获取到的 已连麦时长

#pragma mark 状态
@property (nonatomic, assign) BOOL updateUserCurrentVolumeCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentMicOpenCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraOpenCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraShouldShowCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraFrontCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraTorchOpenCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentNetworkQualityCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentBrushAuthCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentGrantCupCountCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentHandUpCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentStatusVoiceCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentSpeakerAuthCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentScreenShareOpenCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentFirstSiteCallbackBefore;
@property (nonatomic, assign) CGFloat currentVolume;
@property (nonatomic, assign) BOOL currentMicOpen;
@property (nonatomic, assign) BOOL currentCameraOpen;
@property (nonatomic, assign) BOOL currentCameraFront;
@property (nonatomic, assign) BOOL currentCameraTorchOpen;
@property (nonatomic, assign) PLVBRTCVideoMirrorMode localVideoMirrorMode;
@property (nonatomic, assign) PLVBLinkMicNetworkQuality currentNetworkQuality;
@property (nonatomic, assign) BOOL currentStatusVoice;
@property (nonatomic, assign) BOOL currentBrushAuth;
@property (nonatomic, assign) NSInteger currentCupCount;
@property (nonatomic, assign) BOOL currentHandUp;
@property (nonatomic, assign) BOOL isRealMainSpeaker;
@property (nonatomic, assign) BOOL currentScreenShareOpen;
@property (nonatomic, assign) PLVLinkMicUserLinkMicStatus linkMicStatus;
@property (nonatomic, assign) BOOL forceCloseLinkMicIfNeed;
@property (nonatomic, assign) BOOL currentFirstSite;

@end

@implementation PLVLinkMicOnlineUser

#pragma mark - [ Life Period ]
- (void)dealloc{
    if (self.willDeallocBlock) {
        self.willDeallocBlock(self);
        self.willDeallocBlock = nil;
    }
    
    if (_willDealloc_MultiReceiverMap.count > 0) {
        NSEnumerator * enumerator = [_willDealloc_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserWillDeallocBlock block;
        while ((block = [enumerator nextObject])) {
            block(self);
        }
    }
    
    _volumeChangedBlock = nil;
    _micOpenChangedBlock = nil;
    _cameraOpenChangedBlock = nil;
    
    [self stopForceCloseLinkTimer];
}


#pragma mark - [ Private Methods ]
#pragma mark Getter
- (NSMapTable<id,PLVLinkMicOnlineUserWillDeallocBlock> *)willDealloc_MultiReceiverMap{
    if (!_willDealloc_MultiReceiverMap) {
        _willDealloc_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _willDealloc_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserMicOpenChangedBlock> *)micOpenChanged_MultiReceiverMap{
    if (!_micOpenChanged_MultiReceiverMap) {
        _micOpenChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _micOpenChanged_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserCameraShouldShowChangedBlock> *)cameraShouldShowChanged_MultiReceiverMap{
    if (!_cameraShouldShowChanged_MultiReceiverMap) {
        _cameraShouldShowChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _cameraShouldShowChanged_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserCameraFrontChangedBlock> *)cameraFrontChanged_MultiReceiverMap{
    if (!_cameraFrontChanged_MultiReceiverMap) {
        _cameraFrontChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _cameraFrontChanged_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserCameraTorchOpenChangedBlock> *)cameraTorchOpenChanged_MultiReceiverMap{
    if (!_cameraTorchOpenChanged_MultiReceiverMap) {
        _cameraTorchOpenChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _cameraTorchOpenChanged_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock> *)currentStatusVoiceChanged_MultiReceiverMap{
    if (!_currentStatusVoiceChanged_MultiReceiverMap) {
        _currentStatusVoiceChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _currentStatusVoiceChanged_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock> *)currentSpeakerAuthChanged_MultiReceiverMap{
    if (!_currentSpeakerAuthChanged_MultiReceiverMap) {
        _currentSpeakerAuthChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _currentSpeakerAuthChanged_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserScreenShareOpenChangedBlock> *)currentScreenShareOpenChanged_MultiReceiverMap{
    if (!_currentScreenShareOpenChanged_MultiReceiverMap) {
        _currentScreenShareOpenChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _currentScreenShareOpenChanged_MultiReceiverMap;
}

- (NSMapTable<id,PLVLinkMicOnlineUserCurrentFirstSiteChangedBlock> *)currentFirstSiteChanged_MultiReceiverMap{
    if (!_currentFirstSiteChanged_MultiReceiverMap) {
        _currentFirstSiteChanged_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _currentFirstSiteChanged_MultiReceiverMap;
}

- (NSTimeInterval)currentLinkMicDuration {
    NSTimeInterval currentLinkMicDuration = ([[NSDate date] timeIntervalSince1970] * 1000 - self.linkMicTimestamp) / 1000;
    return currentLinkMicDuration;
}

#pragma mark - [ Public Methods ]
#pragma mark Getter
- (UIView *)rtcView{
    if (!_rtcView) {
        _rtcView = [[UIView alloc] init];
        _rtcView.frame = CGRectMake(0, 0, 1, 1);
        _rtcView.clipsToBounds = YES;
    }
    return _rtcView;
}

- (BOOL)rtcRendered{
    return (_rtcView && (_rtcView.subviews.count > 0 || _rtcView.layer.sublayers.count > 0));
}

#pragma mark 创建

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if (![PLVFdUtil checkDictionaryUseable:dictionary]) {
        return nil;
    }
    
    PLVLinkMicOnlineUser *user = [[PLVLinkMicOnlineUser alloc] init];
    [user updateWithDictionary:dictionary];
    user.linkMicTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return user;
}

+ (instancetype)localUserModelWithChatUser:(PLVChatUser *)chatUser {
    if (!chatUser ||
        ![chatUser isKindOfClass:[PLVChatUser class]]) {
        return nil;
    }
    
    PLVLinkMicOnlineUser *user = [[PLVLinkMicOnlineUser alloc] init];
    user.userType = [PLVRoomUser sockerUserTypeWithRoomUserType:chatUser.userType];
    user.userId = chatUser.userId;
    user.linkMicUserId = chatUser.userId;
    user.nickname = chatUser.userName;
    user.avatarPic = chatUser.avatarUrl;
    user.actor = chatUser.actor;
    user.currentBrushAuth = chatUser.currentBrushAuth;
    user.currentCupCount = chatUser.cupCount;
    return user;
}

+ (instancetype)localUserModelWithUserId:(NSString *)userId linkMicUserId:(NSString *)linkMicUserId nickname:(NSString *)nickname avatarPic:(NSString *)avatarPic userType:(PLVSocketUserType)userType actor:(NSString *)actor{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        PLVLinkMicOnlineUser * user = [[PLVLinkMicOnlineUser alloc]init];
        user.userId = userId;
        user.linkMicUserId = linkMicUserId;
        user.nickname = [NSString stringWithFormat:PLVLocalizedString(@"%@ (我)"),nickname];
        user.avatarPic = avatarPic;
        user.userType = userType;
        user.localUser = YES;
        user.actor = actor;
        return user;
    }
    return nil;
}

#pragma mark 状态更新

- (void)updateWithDictionary:(NSDictionary *)dictionary {
    if (![PLVFdUtil checkDictionaryUseable:dictionary]) {
        return;
    }
    
    /// 用户类型
    NSString *userTypeString = [NSString stringWithFormat:@"%@",dictionary[@"userType"]];
    PLVRoomUserType roomUserType = [PLVRoomUser userTypeWithUserTypeString:userTypeString];
    PLVSocketUserType userType = [PLVRoomUser sockerUserTypeWithRoomUserType:roomUserType];
    self.userType = userType;
    
    /// 用户信息
    self.userId = [PLVFdUtil checkStringUseable:dictionary[@"loginId"]] ? dictionary[@"loginId"] : nil;
    self.linkMicUserId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
    self.nickname = [PLVFdUtil checkStringUseable:dictionary[@"nick"]] ? dictionary[@"nick"] : nil;
    self.avatarPic = [PLVFdUtil checkStringUseable:dictionary[@"pic"]] ? dictionary[@"pic"] : nil;
    self.actor = [PLVFdUtil checkStringUseable:dictionary[@"actor"]] ? dictionary[@"actor"] : nil;
    
    if (self.userType == PLVSocketUserTypeGuest ||
        self.userType == PLVSocketUserTypeTeacher ||
        self.userType == PLVSocketUserTypeSCStudent) {
        self.userId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
    }
    
    /// 权限
    NSDictionary * classStatusDict = dictionary[@"classStatus"];
    if ([PLVFdUtil checkDictionaryUseable:classStatusDict]) {
        BOOL currentBrushAuth = ([NSString stringWithFormat:@"%@",classStatusDict[@"paint"]].intValue == 1);
        BOOL currentStatusVoice = ([NSString stringWithFormat:@"%@",classStatusDict[@"voice"]].intValue == 1);
        NSInteger currentCupCount = PLV_SafeIntegerForDictKey(classStatusDict, @"cup");
        BOOL currentHandUp = ([NSString stringWithFormat:@"%@",classStatusDict[@"raiseHand"]].intValue == 1);
        self.groupLeader = ([NSString stringWithFormat:@"%@",classStatusDict[@"groupLeader"]].intValue == 1);
        BOOL isRealMainSpeaker = ([NSString stringWithFormat:@"%@",classStatusDict[@"speaker"]].intValue == 1);
        
        BOOL localUser = self.localUser; // 缓存真实状态
        if (self.userType == PLVSocketUserTypeGuest || self.userType == PLVSocketUserTypeSlice) {
            self.localUser = YES; // 仅为了远端(嘉宾自动上麦、观众上麦)赋值成功
        }
        [self updateUserCurrentStatusVoice:currentStatusVoice];
        self.localUser = localUser; // 还原真实状态
        
        [self updateUserCurrentBrushAuth:currentBrushAuth];
        [self updateUserCurrentGrantCupCount:currentCupCount];
        [self updateUserCurrentHandUp:currentHandUp];
        [self updateUserCurrentSpeakerAuth:isRealMainSpeaker];
    }
    
    /// 原始数据
    self.originalUserDict = dictionary;
}

- (void)updateUserCurrentVolume:(CGFloat)volume{
    if (volume < 0.0) {
        volume = 0.0;
    }else if(volume > 1.0){
        volume = 1.0;
    }
    BOOL needCallBack = (_currentVolume != volume);
    if (!_updateUserCurrentVolumeCallbackBefore) {
        needCallBack = YES;
    }
    needCallBack = self.currentMicOpen ? needCallBack : NO;
    
    _currentVolume = volume;
    if (needCallBack && self.volumeChangedBlock) {
        _updateUserCurrentVolumeCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.volumeChangedBlock(weakSelf); }
        })
    }
}

- (void)updateUserCurrentMicOpen:(BOOL)micOpen{
    BOOL needCallBack = (_currentMicOpen != micOpen);
    if (!_updateUserCurrentMicOpenCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentMicOpen = micOpen;
    if (needCallBack && self.micOpenChangedBlock) {
        _updateUserCurrentMicOpenCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.micOpenChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBack && _micOpenChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentMicOpenCallbackBefore = YES;
        NSEnumerator * enumerator = [_micOpenChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserMicOpenChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }
}

- (void)updateUserCurrentCameraOpen:(BOOL)cameraOpen{
    BOOL cameraOpenResult = cameraOpen;
    
    /// 注：
    /// 因业务逻辑的改变，_currentCameraShouldShow 暂时与 _currentCameraOpen 两值无差异
    /// 但仍建议使用 [cameraShouldShowChangedBlock]
    BOOL needCallBackCameraShouldOpen = (_currentCameraShouldShow != cameraOpenResult);
    if (!_updateUserCurrentCameraShouldShowCallbackBefore) {
        needCallBackCameraShouldOpen = YES;
    }
    _currentCameraShouldShow = cameraOpenResult;
    
    BOOL needCallBack = (_currentCameraOpen != cameraOpen);
    if (!_updateUserCurrentCameraOpenCallbackBefore) {
        needCallBack = YES;
    }
    _currentCameraOpen = cameraOpen;
    
    if (needCallBackCameraShouldOpen && self.cameraShouldShowChangedBlock) {
        _updateUserCurrentCameraShouldShowCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.cameraShouldShowChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBackCameraShouldOpen && _cameraShouldShowChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentCameraShouldShowCallbackBefore = YES;
        NSEnumerator * enumerator = [_cameraShouldShowChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserCameraShouldShowChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }

    if (needCallBack && self.cameraOpenChangedBlock) {
        _updateUserCurrentCameraOpenCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.cameraOpenChangedBlock(weakSelf); }
        })
    }
}

- (void)updateUserCurrentCameraFront:(BOOL)cameraFront{
    BOOL needCallBack = (_currentCameraFront != cameraFront);
    if (!_updateUserCurrentCameraFrontCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentCameraFront = cameraFront;
    if (needCallBack && self.cameraFrontChangedBlock) {
        _updateUserCurrentCameraFrontCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.cameraFrontChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBack && _cameraFrontChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentCameraFrontCallbackBefore = YES;
        NSEnumerator * enumerator = [_cameraFrontChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserCameraFrontChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }
}

- (void)updateUserCurrentCameraTorchOpen:(BOOL)cameraTorchOpen{
    BOOL needCallBack = (_currentCameraTorchOpen != cameraTorchOpen);
    if (!_updateUserCurrentCameraTorchOpenCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentCameraTorchOpen = cameraTorchOpen;
    if (needCallBack && self.cameraTorchOpenChangedBlock) {
        _updateUserCurrentCameraTorchOpenCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.cameraTorchOpenChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBack && _cameraTorchOpenChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentCameraTorchOpenCallbackBefore = YES;
        NSEnumerator * enumerator = [_cameraTorchOpenChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserCameraTorchOpenChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }
}

- (void)updateUserLocalVideoMirrorMode:(PLVBRTCVideoMirrorMode)localVideoMirrorMode {
    _localVideoMirrorMode = localVideoMirrorMode;
}

- (void)updateUserCurrentNetworkQuality:(PLVBLinkMicNetworkQuality)networkQuality{
    BOOL needCallBack = (_currentNetworkQuality != networkQuality);
    if (!_updateUserCurrentNetworkQualityCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentNetworkQuality = networkQuality;
    if (needCallBack && self.networkQualityChangedBlock) {
        _updateUserCurrentNetworkQualityCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.networkQualityChangedBlock(weakSelf); }
        })
    }
}

- (void)updateUserCurrentBrushAuth:(BOOL)brushAuth {
    BOOL needCallBack = (_currentBrushAuth != brushAuth);
    if (!_updateUserCurrentBrushAuthCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentBrushAuth = brushAuth;
    if (needCallBack && self.brushAuthChangedBlock) {
        _updateUserCurrentBrushAuthCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.brushAuthChangedBlock(weakSelf); }
        })
    }
}

- (void)updateUserCurrentGrantCupCount:(NSInteger)cupCount {
    BOOL needCallBack = (_currentCupCount != cupCount);
    if (!_updateUserCurrentGrantCupCountCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentCupCount = cupCount;
    if (needCallBack && self.grantCupCountChangedBlock) {
        _updateUserCurrentGrantCupCountCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.grantCupCountChangedBlock(weakSelf); }
        })
    }
}

- (void)updateUserCurrentHandUp:(BOOL)handUp {
    BOOL needCallBack = (_currentHandUp != handUp);
    if (!_updateUserCurrentHandUpCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentHandUp = handUp;
    if (needCallBack && self.handUpChangedBlock) {
        _updateUserCurrentHandUpCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.handUpChangedBlock(weakSelf); }
        })
    }
}

- (void)updateUserCurrentStatusVoice:(BOOL)currentStatusVoice{
    if (!self.localUser) { return; }
    
    BOOL needCallBack = (_currentStatusVoice != currentStatusVoice);
    if (!_updateUserCurrentStatusVoiceCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentStatusVoice = currentStatusVoice;
    if (needCallBack && self.currentStatusVoiceChangedBlock) {
        _updateUserCurrentStatusVoiceCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.currentStatusVoiceChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBack && _currentStatusVoiceChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentStatusVoiceCallbackBefore = YES;
        NSEnumerator * enumerator = [_currentStatusVoiceChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }
}

- (void)updateUserCurrentSpeakerAuth:(BOOL)isRealMainSpeaker {
    BOOL needCallBack = (_isRealMainSpeaker != isRealMainSpeaker);

    /// 注：
    /// _isRealMainSpeaker 默认值为NO， isRealMainSpeaker 值为NO时不需要更新
    if (!_updateUserCurrentSpeakerAuthCallbackBefore && needCallBack) {
        needCallBack = YES;
    }
    
    _isRealMainSpeaker = isRealMainSpeaker;
    if (needCallBack && self.currentSpeakerAuthChangedBlock) {
        _updateUserCurrentSpeakerAuthCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.currentSpeakerAuthChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBack && _currentSpeakerAuthChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentSpeakerAuthCallbackBefore = YES;
        NSEnumerator * enumerator = [_currentSpeakerAuthChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }
}

- (void)updateUserCurrentFirstSite:(BOOL)isFirstSite {
    BOOL needCallBack = (_currentFirstSite != isFirstSite);

    /// 注：
    /// _currentFirstSite 默认值为NO， isFirstSite 值为NO时不需要更新
    if (!_updateUserCurrentFirstSiteCallbackBefore && needCallBack) {
        needCallBack = YES;
    }
    
    _currentFirstSite = isFirstSite;
    if (needCallBack && self.currentFirstSiteChangedBlock) {
        _updateUserCurrentFirstSiteCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.currentFirstSiteChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBack && _currentFirstSiteChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentFirstSiteCallbackBefore = YES;
        NSEnumerator * enumerator = [_currentFirstSiteChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserCurrentFirstSiteChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }
}

- (void)updateUserIsGuestTransferPermission:(BOOL)isGuestTransferPermission {
    _isGuestTransferPermission = isGuestTransferPermission;
}

- (void)updateUserCurrentScreenShareOpen:(BOOL)screenShareOpen {
    BOOL needCallBack = (_currentScreenShareOpen != screenShareOpen);
    if (!_updateUserCurrentScreenShareOpenCallbackBefore) {
        needCallBack = YES;
    }
    
    _currentScreenShareOpen = screenShareOpen;
    if (needCallBack && self.screenShareOpenChangedBlock) {
        _updateUserCurrentScreenShareOpenCallbackBefore = YES;
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.screenShareOpenChangedBlock(weakSelf); }
        })
    }
    
    if (needCallBack && _currentScreenShareOpenChanged_MultiReceiverMap.count > 0) {
        _updateUserCurrentScreenShareOpenCallbackBefore = YES;
        NSEnumerator * enumerator = [_currentScreenShareOpenChanged_MultiReceiverMap objectEnumerator];
        PLVLinkMicOnlineUserScreenShareOpenChangedBlock block;
        __weak typeof(self) weakSelf = self;
        while ((block = [enumerator nextObject])) {
            plv_dispatch_main_async_safe(^{
                if (weakSelf) { block(weakSelf); }
            })
        }
    }
}

- (void)updateUserCurrentLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus {
    if (!(self.localUser && self.userType == PLVSocketUserTypeGuest)) {
        return;
    }
    
    _linkMicStatus = linkMicStatus;
    if (self.linkMicStatusBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.linkMicStatusBlock(weakSelf); }
        })
    }
}

- (void)startForceCloseLinkTimer {
    if (self.forceCloseLinkMicIfNeed) {
        [self stopForceCloseLinkTimer];
        [self wantForceCloseLinkMicChange];
        return;
    }
    if (!_forceStopLinkMicTimer) {
        _forceStopLinkMicTimerCount = 40;
        _forceStopLinkMicTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(forceCloseLinkTimerEvent:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.forceStopLinkMicTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)cancelForceCloseLinkTimer {
    [self stopForceCloseLinkTimer];
    self.forceCloseLinkMicIfNeed = NO;
}

- (void)stopForceCloseLinkTimer {
    if (_forceStopLinkMicTimer) {
        [_forceStopLinkMicTimer invalidate];
        _forceStopLinkMicTimer = nil;
    }
    _forceStopLinkMicTimerCount = 40;
}

- (void)forceCloseLinkTimerEvent:(NSTimer *)timer {
    if (_forceStopLinkMicTimerCount > 0) {
        _forceStopLinkMicTimerCount --;
    } else {
        [self stopForceCloseLinkTimer];
        self.forceCloseLinkMicIfNeed = YES;
        [self wantForceCloseLinkMicChange];
    }
}

#pragma mark 通知机制
- (void)wantUserRequestJoinLinkMic:(BOOL)request{
    if (self.wantRequestJoinLinkMicBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantRequestJoinLinkMicBlock(weakSelf, request); }
        })
    }
}

- (void)wantOpenUserMic:(BOOL)openMic{
    if (self.wantOpenMicBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantOpenMicBlock(weakSelf, openMic); }
        })
    }
}

- (void)wantOpenUserCamera:(BOOL)openCamera{
    if (self.wantOpenCameraBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantOpenCameraBlock(weakSelf, openCamera); }
        })
    }
}

- (void)wantSwitchUserFrontCamera:(BOOL)frontCamera{
    if (self.wantSwitchFrontCameraBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantSwitchFrontCameraBlock(weakSelf, frontCamera); }
        })
    }
}

- (void)wantCloseUserLinkMic{
    if (self.wantCloseLinkMicBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantCloseLinkMicBlock(weakSelf); }
        })
    }
}

- (void)wantForceCloseUserLinkMic:(BOOL)callbackIfFailed {
    if (self.wantForceCloseLinkMicBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantForceCloseLinkMicBlock(weakSelf,callbackIfFailed); }
        })
    }
}

- (void)wantForceCloseLinkMicChange {
    if (self.forceCloseLinkMicChangedBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.forceCloseLinkMicChangedBlock(weakSelf); }
        })
    }
}

- (void)wantForceCloseUserLinkMicWhenFailed {
    if (self.forceCloseLinkMicWhenFailedBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.forceCloseLinkMicWhenFailedBlock(weakSelf); }
        })
    }
}

- (void)wantAuthUserBrush:(BOOL)auth {
    if (self.wantBrushAuthBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantBrushAuthBlock(weakSelf, auth); }
        })
    }
}

- (void)wantGrantUserCup {
    if (self.wantGrantCupBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantGrantCupBlock(weakSelf); }
        })
    }
}

- (void)wantAuthUserSpeaker:(BOOL)authSpeaker {
    if (self.wantAuthSpeakerBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantAuthSpeakerBlock(weakSelf, authSpeaker); }
        })
    }
}

- (void)wantOpenScreenShare:(BOOL)openScreenShare {
    if (self.wantOpenScreenShareBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantOpenScreenShareBlock(weakSelf, openScreenShare);}
        })
    }
}

- (void)wantChangeUserPPTToMain:(BOOL)pptToMain {
    if (self.wantChangePPTToMainBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantChangePPTToMainBlock(weakSelf, pptToMain);}
        })
    }
}

- (void)wantAuthUserFirstSite:(BOOL)authFirstSite {
    if (self.wantAuthFirstSiteBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantAuthFirstSiteBlock(weakSelf, authFirstSite); }
        })
    }
}

#pragma mark 多接收方回调配置
- (void)addWillDeallocBlock:(PLVLinkMicOnlineUserWillDeallocBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addWillDeallocBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addWillDeallocBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.willDealloc_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addWillDeallocBlock failed，block registration limit has been reached");
        return;
    }
    [self.willDealloc_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addMicOpenChangedBlock:(PLVLinkMicOnlineUserMicOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addMicOpenChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addMicOpenChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.micOpenChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addMicOpenChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.micOpenChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCameraShouldShowChangedBlock:(PLVLinkMicOnlineUserCameraShouldShowChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraShouldShowChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraShouldShowChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.cameraShouldShowChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraShouldShowChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.cameraShouldShowChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCameraFrontChangedBlock:(PLVLinkMicOnlineUserCameraFrontChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraFrontChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraFrontChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.cameraFrontChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraFrontChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.cameraFrontChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCameraTorchOpenChangedBlock:(PLVLinkMicOnlineUserCameraTorchOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraTorchOpenChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraTorchOpenChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.cameraTorchOpenChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCameraTorchOpenChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.cameraTorchOpenChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCurrentStatusVoiceChangedBlock:(PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentStatusVoiceChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentStatusVoiceChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.currentStatusVoiceChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentStatusVoiceChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.currentStatusVoiceChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCurrentSpeakerAuthChangedBlock:(PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentSpeakerAuthChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentSpeakerAuthChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.currentSpeakerAuthChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentSpeakerAuthChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.currentSpeakerAuthChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addScreenShareOpenChangedBlock:(PLVLinkMicOnlineUserScreenShareOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addScreenShareOpenChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addScreenShareOpenChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.currentScreenShareOpenChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addScreenShareOpenChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.currentScreenShareOpenChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCurrentFirstSiteChangedBlock:(PLVLinkMicOnlineUserCurrentFirstSiteChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentFirstSiteChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentFirstSiteChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.currentFirstSiteChanged_MultiReceiverMap.count > 20) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeLinkMic, @"PLVLinkMicOnlineUser - addCurrentFirstSiteChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.currentFirstSiteChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

@end
