//
//  PLVLinkMicOnlineUser.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/8/19.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLinkMicOnlineUser.h"

#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLinkMicOnlineUser ()

#pragma mark 对象
@property (nonatomic, strong) UIView * rtcView;

#pragma mark 数据
@property (nonatomic, copy) NSString * linkMicUserId;
@property (nonatomic, copy, nullable) NSString * actor;
@property (nonatomic, copy, nullable) NSString * nickname;
@property (nonatomic, copy, nullable) NSString * avatarPic;
@property (nonatomic, assign) PLVLinkMicOnlineUserType userType;
@property (nonatomic, assign) BOOL localUser;

#pragma mark 状态
@property (nonatomic, assign) CGFloat currentVolume;
@property (nonatomic, assign) BOOL currentMicOpen;
@property (nonatomic, assign) BOOL currentCameraOpen;

@end

@implementation PLVLinkMicOnlineUser

#pragma mark - [ Life Period ]
- (void)dealloc{
    if (self.willDeallocBlock) {
        self.willDeallocBlock(self);
        self.willDeallocBlock = nil;
    }
    
    _volumeChangedBlock = nil;
    _micOpenChangedBlock = nil;
    _cameraOpenChangedBlock = nil;
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
        
        /// 用户信息
        user.linkMicUserId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
        user.nickname = [PLVFdUtil checkStringUseable:dictionary[@"nick"]] ? dictionary[@"nick"] : nil;
        user.avatarPic = [PLVFdUtil checkStringUseable:dictionary[@"pic"]] ? dictionary[@"pic"] : nil;
        user.actor = [PLVFdUtil checkStringUseable:dictionary[@"actor"]] ? dictionary[@"actor"] : nil;
        
        /// 用户类型
        NSString * userType = [NSString stringWithFormat:@"%@",dictionary[@"userType"]];
        if ([@"teacher" isEqualToString:userType]) {
            user.userType = PLVLinkMicOnlineUserType_Teacher;
        } else if ([@"viewer" isEqualToString:userType]) {
            user.userType = PLVLinkMicOnlineUserType_Teacher;
        } else if ([@"guest" isEqualToString:userType]){
            user.userType = PLVLinkMicOnlineUserType_Guests;
        } else if ([@"slice" isEqualToString:userType]){
            user.userType = PLVLinkMicOnlineUserType_Slice;
        }
        
        return user;
    }
    return nil;
}

+ (instancetype)teacherModelWithUserId:(NSString *)userId{
    if ([PLVFdUtil checkStringUseable:userId]) {
        PLVLinkMicOnlineUser * user = [[PLVLinkMicOnlineUser alloc]init];
        user.linkMicUserId = userId;
        user.userType = PLVLinkMicOnlineUserType_Teacher;
        return user;
    }
    return nil;
}

+ (instancetype)localUserModelWithUserId:(NSString *)userId nickname:(NSString *)nickname avatarPic:(NSString *)avatarPic{
    if ([PLVFdUtil checkStringUseable:userId]) {
        PLVLinkMicOnlineUser * user = [[PLVLinkMicOnlineUser alloc]init];
        user.linkMicUserId = userId;
        user.userType = PLVLinkMicOnlineUserType_Slice;
        user.localUser = YES;
        user.nickname = [NSString stringWithFormat:@"%@ (我)",nickname];
        user.avatarPic = avatarPic;
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
    _currentVolume = volume;
    if (needCallBack && self.volumeChangedBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            weakSelf.volumeChangedBlock(weakSelf);
        })
    }
}

- (void)updateUserCurrentMicOpen:(BOOL)micOpen{
    BOOL needCallBack = (_currentMicOpen != micOpen);
    _currentMicOpen = micOpen;
    if (needCallBack && self.micOpenChangedBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            weakSelf.micOpenChangedBlock(weakSelf);
        })
    }
}

- (void)updateUserCurrentCameraOpen:(BOOL)cameraOpen{
    BOOL cameraOpenResult = cameraOpen;
    
    BOOL needCallBackCameraShouldOpen = (_currentCameraShouldShow != cameraOpenResult);
    _currentCameraShouldShow = cameraOpenResult;
    if (needCallBackCameraShouldOpen && self.cameraShouldShowChangedBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            weakSelf.cameraShouldShowChangedBlock(weakSelf);
        })
    }
    
    BOOL needCallBack = (_currentCameraOpen != cameraOpen);
    _currentCameraOpen = cameraOpen;
    if (needCallBack && self.cameraOpenChangedBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            weakSelf.cameraOpenChangedBlock(weakSelf);
        })
    }
}

@end
