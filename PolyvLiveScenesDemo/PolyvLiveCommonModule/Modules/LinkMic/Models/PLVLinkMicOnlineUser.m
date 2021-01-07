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

@property (nonatomic, copy) NSString * linkMicUserId;  // 用户连麦Id
@property (nonatomic, assign) BOOL localUser;          // 是否为本地用户(自己)

@property (nonatomic, strong) UIView * rtcView; // RTC渲染画面 (详细说明见 .h 声明文件)

@property (nonatomic, assign) CGFloat currentVolume; /// 用户的当前连麦音量
@property (nonatomic, assign) BOOL currentMicOpen; /// 用户麦克风 当前是否开启
@property (nonatomic, assign) BOOL currentCameraOpen; /// 用户摄像头 当前是否开启

@end

@implementation PLVLinkMicOnlineUser

#pragma mark - [ Life Period ]
- (void)dealloc{
    if (self.willDeallocBlock) {
        self.willDeallocBlock(self);
        self.willDeallocBlock = nil;
    }
}


#pragma mark - [ Public Methods ]
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
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.volumeChangedBlock(weakSelf);
        });
    }
}

- (void)updateUserCurrentMicOpen:(BOOL)open{
    BOOL needCallBack = (_currentMicOpen != open);
    _currentMicOpen = open;
    if (needCallBack && self.micOpenChangedBlock) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.micOpenChangedBlock(weakSelf);
        });
    }
}

- (void)updateUserCurrentCameraOpen:(BOOL)open{
    BOOL needCallBack = (_currentCameraOpen != open);
    _currentCameraOpen = open;
    if (needCallBack && self.cameraOpenChangedBlock) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.cameraOpenChangedBlock(weakSelf);
        });
    }
}

#pragma mark - [ Private Methods ]
#pragma Getter
- (UIView *)rtcView{
    if (!_rtcView) {
        _rtcView = [[UIView alloc] init];
    }
    return _rtcView;
}

- (BOOL)rtcRendered{
    return (self.rtcView.subviews.count > 0 || self.rtcView.layer.sublayers.count > 0);
}

@end
