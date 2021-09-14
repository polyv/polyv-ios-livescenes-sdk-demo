//
//  PLVRoomUser.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVRoomUser.h"
#import <UIKit/UIKit.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSString *kRoomUserTypeStudent = @"student";
static NSString *kRoomUserTypeSlice = @"slice";
static NSString *kRoomUserTypeViewer = @"viewer";
static NSString *kRoomUserTypeGuest =  @"guest";
static NSString *kRoomUserTypeTeacher = @"teacher";
static NSString *kRoomUserTypeAssistant = @"assistant";
static NSString *kRoomUserTypeManager = @"manager";
static NSString *kRoomUserTypeDummy = @"dummy";

@interface PLVRoomUser ()

@property (nonatomic, assign) PLVRoomUserType viewerType;

@end

@implementation PLVRoomUser

#pragma mark - 初始化

- (instancetype)initWithChannelType:(PLVChannelType)channelType {
    PLVRoomUserType userType = [PLVRoomUser userTypeWithChannelType:channelType];
    return [[PLVRoomUser alloc] initWithViewerId:nil viewerName:nil viewerAvatar:nil viewerType:userType];
}

- (instancetype)initWithViewerId:(NSString * _Nullable)viewerId
                      viewerName:(NSString * _Nullable)viewerName
                    viewerAvatar:(NSString * _Nullable)viewerAvatar
                      viewerType:(PLVRoomUserType)viewerType {
    self = [super init];
    if (self) {
        if (!viewerId || ![viewerId isKindOfClass:[NSString class]] || viewerId.length == 0) {
            viewerId = [self getViewerId];
        }
        if (!viewerName || ![viewerName isKindOfClass:[NSString class]] || viewerName.length == 0) {
            viewerName = [self getViewerNameWithViewerId:viewerId];
        }
        if (!viewerAvatar || ![viewerAvatar isKindOfClass:[NSString class]] || viewerAvatar.length == 0) {
            viewerAvatar = PLVLiveConstantsRoomEffectDeviceIconURL;
        }
        if (viewerType <= PLVRoomUserTypeUnknown || viewerType >= PLVRoomUserTypeManager) {
            viewerType = PLVRoomUserTypeStudent;
        }
        
        self.viewerId = viewerId;
        self.viewerName = viewerName;
        self.viewerAvatar = viewerAvatar;
        self.viewerType = viewerType;
    }
    return self;
}

#pragma mark - 获取或生成 ViewerId & ViewerName

- (NSString *)getViewerId {
    return [self getUUID];
}

/// 卸载当前设备该开发者证书下的所有应用，再重新安装，identifierForVendor 会发生改变
- (NSString *)getUUID {
    return [UIDevice currentDevice].identifierForVendor.UUIDString;;
}

- (NSString *)getViewerNameWithViewerId:(NSString *)viewerId {
    if (!viewerId || ![viewerId isKindOfClass:[NSString class]] || viewerId.length == 0) {
        return [NSString stringWithFormat:@"观众%@", [self getUUID]];
    } else {
        return [NSString stringWithFormat:@"观众%@", viewerId];
    }
}

#pragma mark - 用户类型相关工具方法

+ (PLVRoomUserType)userTypeWithChannelType:(PLVChannelType)channelType {
    if ((channelType & PLVChannelTypePPT) > 0) {
        return PLVRoomUserTypeSlice;
    } else if ((channelType & PLVChannelTypeAlone) > 0) {
        return PLVRoomUserTypeStudent;
    } else {
        return PLVRoomUserTypeViewer;
    }
}

+ (BOOL)isSpecialIdentityWithUserType:(PLVRoomUserType)userType {
    if (userType == PLVRoomUserTypeGuest ||
        userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager) {
        return YES;
    } else {
        return NO;
    }
}

+ (PLVSocketUserType)sockerUserTypeWithRoomUserType:(PLVRoomUserType)userType {
    PLVSocketUserType socketUserType = PLVSocketUserTypeUnknown;
    if (userType == PLVRoomUserTypeStudent) {
        socketUserType = PLVSocketUserTypeStudent;
    } else if (userType == PLVRoomUserTypeSlice) {
        socketUserType = PLVSocketUserTypeSlice;
    } else if (userType == PLVRoomUserTypeViewer) {
        socketUserType = PLVSocketUserTypeViewer;
    } else if (userType == PLVRoomUserTypeGuest) {
        socketUserType = PLVSocketUserTypeGuest;
    } else if (userType == PLVRoomUserTypeTeacher) {
        socketUserType = PLVSocketUserTypeTeacher;
    } else if (userType == PLVRoomUserTypeAssistant) {
        socketUserType = PLVSocketUserTypeAssistant;
    } else if (userType == PLVRoomUserTypeManager) {
        socketUserType = PLVSocketUserTypeManager;
    } else {
        socketUserType = PLVSocketUserTypeViewer;
    }
    return socketUserType;
}

+ (PLVRoomUserType)userTypeWithUserTypeString:(NSString *)userTypeString {
    if (!userTypeString || ![userTypeString isKindOfClass:[NSString class]]) {
        return PLVRoomUserTypeUnknown;
    }
    
    if (userTypeString.length == 0 || [userTypeString isEqualToString:kRoomUserTypeStudent]) {
        return PLVRoomUserTypeStudent;
    } else if ([userTypeString isEqualToString:kRoomUserTypeSlice]) {
        return PLVRoomUserTypeSlice;
    } else if ([userTypeString isEqualToString:kRoomUserTypeViewer]) {
        return PLVRoomUserTypeViewer;
    } else if ([userTypeString isEqualToString:kRoomUserTypeGuest]) {
        return PLVRoomUserTypeGuest;
    } else if ([userTypeString isEqualToString:kRoomUserTypeTeacher]) {
        return PLVRoomUserTypeTeacher;
    } else if ([userTypeString isEqualToString:kRoomUserTypeAssistant]) {
        return PLVRoomUserTypeAssistant;
    } else if ([userTypeString isEqualToString:kRoomUserTypeManager]) {
        return PLVRoomUserTypeManager;
    } else if ([userTypeString isEqualToString:kRoomUserTypeDummy]) {
        return PLVRoomUserTypeDummy;
    } else {
        return PLVRoomUserTypeUnknown;
    }
}

+ (NSString *)userTypeStringWithUserType:(PLVRoomUserType)userType {
    switch (userType) {
        case PLVRoomUserTypeStudent:
            return kRoomUserTypeStudent;
        case PLVRoomUserTypeSlice:
            return kRoomUserTypeSlice;
        case PLVRoomUserTypeViewer:
            return kRoomUserTypeViewer;
        case PLVRoomUserTypeGuest:
            return  kRoomUserTypeGuest;
        case PLVRoomUserTypeTeacher:
            return kRoomUserTypeTeacher;
        case PLVRoomUserTypeAssistant:
            return kRoomUserTypeAssistant;
        case PLVRoomUserTypeManager:
            return kRoomUserTypeManager;
        case PLVRoomUserTypeDummy:
            return kRoomUserTypeDummy;
        default:
            return @"";
    }
}

@end
