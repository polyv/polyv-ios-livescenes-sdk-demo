//
//  PLVLinkMicOnlineUser.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/19.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLinkMicOnlineUser.h"

@interface PLVLinkMicOnlineUser ()

#pragma mark 对象
@property (nonatomic, strong) UIView * rtcView;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserWillDeallocBlock> * willDealloc_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserMicOpenChangedBlock> * micOpenChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCameraShouldShowChangedBlock> * cameraShouldShowChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCameraFrontChangedBlock> * cameraFrontChanged_MultiReceiverMap;
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicOnlineUserCameraTorchOpenChangedBlock> * cameraTorchOpenChanged_MultiReceiverMap;

#pragma mark 数据
@property (nonatomic, copy) NSString * userId;
@property (nonatomic, copy) NSString * linkMicUserId;
@property (nonatomic, copy, nullable) NSString * actor;
@property (nonatomic, copy, nullable) NSString * nickname;
@property (nonatomic, copy, nullable) NSString * avatarPic;
@property (nonatomic, assign) PLVSocketUserType userType;
@property (nonatomic, assign) BOOL localUser;
@property (nonatomic, strong) NSDictionary * originalUserDict;

#pragma mark 状态
@property (nonatomic, assign) BOOL updateUserCurrentVolumeCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentMicOpenCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraOpenCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraShouldShowCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraFrontCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentCameraTorchOpenCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentNetworkQualityCallbackBefore;
@property (nonatomic, assign) BOOL updateUserCurrentStatusVoiceCallbackBefore;
@property (nonatomic, assign) CGFloat currentVolume;
@property (nonatomic, assign) BOOL currentMicOpen;
@property (nonatomic, assign) BOOL currentCameraOpen;
@property (nonatomic, assign) BOOL currentCameraFront;
@property (nonatomic, assign) BOOL currentCameraTorchOpen;
@property (nonatomic, assign) PLVBLinkMicNetworkQuality currentNetworkQuality;
@property (nonatomic, assign) BOOL currentStatusVoice;

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
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary{
    if ([PLVFdUtil checkDictionaryUseable:dictionary]) {
        PLVLinkMicOnlineUser * user = [[PLVLinkMicOnlineUser alloc]init];
        
        /// 用户类型
        NSString * userType = [NSString stringWithFormat:@"%@",dictionary[@"userType"]];
        if ([@"teacher" isEqualToString:userType]) {
            user.userType = PLVSocketUserTypeTeacher;
        } else if ([@"viewer" isEqualToString:userType]) {
            user.userType = PLVSocketUserTypeViewer;
        } else if ([@"guest" isEqualToString:userType]){
            user.userType = PLVSocketUserTypeGuest;
        } else if ([@"slice" isEqualToString:userType]){
            user.userType = PLVSocketUserTypeSlice;
        } else if ([@"student" isEqualToString:userType]){
            user.userType = PLVSocketUserTypeStudent;
        }
        
        /// 用户信息
        user.userId = [PLVFdUtil checkStringUseable:dictionary[@"loginId"]] ? dictionary[@"loginId"] : nil;
        user.linkMicUserId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
        user.nickname = [PLVFdUtil checkStringUseable:dictionary[@"nick"]] ? dictionary[@"nick"] : nil;
        user.avatarPic = [PLVFdUtil checkStringUseable:dictionary[@"pic"]] ? dictionary[@"pic"] : nil;
        user.actor = [PLVFdUtil checkStringUseable:dictionary[@"actor"]] ? dictionary[@"actor"] : nil;
        
        if (user.userType == PLVSocketUserTypeGuest ||
            user.userType == PLVSocketUserTypeTeacher) {
            user.userId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
        }
        
        /// 权限
        NSDictionary * classStatusDict = dictionary[@"classStatus"];
        if ([PLVFdUtil checkDictionaryUseable:classStatusDict]) {
            user.currentStatusVoice = ([NSString stringWithFormat:@"%@",classStatusDict[@"voice"]].intValue == 1);
        }
        
        /// 原始数据
        user.originalUserDict = dictionary;
        
        return user;
    }
    return nil;
}

+ (instancetype)localUserModelWithUserId:(NSString *)userId linkMicUserId:(NSString *)linkMicUserId nickname:(NSString *)nickname avatarPic:(NSString *)avatarPic userType:(PLVSocketUserType)userType actor:(NSString *)actor{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        PLVLinkMicOnlineUser * user = [[PLVLinkMicOnlineUser alloc]init];
        user.userId = userId;
        user.linkMicUserId = linkMicUserId;
        user.nickname = [NSString stringWithFormat:@"%@ (我)",nickname];
        user.avatarPic = avatarPic;
        user.userType = userType;
        user.localUser = YES;
        user.actor = actor;
        return user;
    }
    return nil;
}

#pragma mark 状态更新
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
}

#pragma mark 通知机制
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

#pragma mark 多接收方回调配置
- (void)addWillDeallocBlock:(PLVLinkMicOnlineUserWillDeallocBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        NSLog(@"PLVLinkMicOnlineUser - addWillDeallocBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        NSLog(@"PLVLinkMicOnlineUser - addWillDeallocBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.willDealloc_MultiReceiverMap.count > 20) {
        NSLog(@"PLVLinkMicOnlineUser - addWillDeallocBlock failed，block registration limit has been reached");
        return;
    }
    [self.willDealloc_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addMicOpenChangedBlock:(PLVLinkMicOnlineUserMicOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        NSLog(@"PLVLinkMicOnlineUser - addMicOpenChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        NSLog(@"PLVLinkMicOnlineUser - addMicOpenChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.micOpenChanged_MultiReceiverMap.count > 20) {
        NSLog(@"PLVLinkMicOnlineUser - addMicOpenChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.micOpenChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCameraShouldShowChangedBlock:(PLVLinkMicOnlineUserCameraShouldShowChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraShouldShowChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraShouldShowChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.cameraShouldShowChanged_MultiReceiverMap.count > 20) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraShouldShowChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.cameraShouldShowChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCameraFrontChangedBlock:(PLVLinkMicOnlineUserCameraFrontChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraFrontChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraFrontChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.cameraFrontChanged_MultiReceiverMap.count > 20) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraFrontChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.cameraFrontChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

- (void)addCameraTorchOpenChangedBlock:(PLVLinkMicOnlineUserCameraTorchOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey{
    if (!strongBlock) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraTorchOpenChangedBlock failed，strongBlock illegal");
        return;
    }
    if (!weakBlockKey) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraTorchOpenChangedBlock failed，weakBlockKey illegal:%@",weakBlockKey);
        return;
    }
    if (self.cameraTorchOpenChanged_MultiReceiverMap.count > 20) {
        NSLog(@"PLVLinkMicOnlineUser - addCameraTorchOpenChangedBlock failed，block registration limit has been reached");
        return;
    }
    [self.cameraTorchOpenChanged_MultiReceiverMap setObject:strongBlock forKey:weakBlockKey];
}

@end
