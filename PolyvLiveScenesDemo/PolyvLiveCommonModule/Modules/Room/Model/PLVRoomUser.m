//
//  PLVRoomUser.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVRoomUser.h"

static NSString *kRoomUserTypeStudent = @"student";
static NSString *kRoomUserTypeSlice = @"slice";
static NSString *kRoomUserTypeViewer = @"viewer";
static NSString *kRoomUserTypeGuest =  @"guest";
static NSString *kRoomUserTypeTeacher = @"teacher";
static NSString *kRoomUserTypeAssistant = @"assistant";
static NSString *kRoomUserTypeManager = @"manager";
static NSString *kRoomUserTypeDummy = @"dummy";

@interface PLVRoomUser ()

@property (nonatomic, copy) NSString *viewerId;
@property (nonatomic, copy) NSString *viewerName;
@property (nonatomic, copy) NSString *viewerAvatar;
@property (nonatomic, assign) PLVRoomUserType viewerType;

@end

@implementation PLVRoomUser

#pragma mark - 初始化

- (instancetype)init {
    return [[PLVRoomUser alloc] initWithViewerId:nil viewerName:nil viewerAvatar:nil viewerType:PLVRoomUserTypeStudent];
}

- (instancetype)initWithViewerId:(NSString *)viewerId viewerName:(NSString *)viewerName {
    return [[PLVRoomUser alloc] initWithViewerId:viewerId viewerName:viewerName viewerAvatar:nil viewerType:PLVRoomUserTypeStudent];
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
            viewerName = [self getViewerName];
        }
        if (!viewerAvatar || ![viewerAvatar isKindOfClass:[NSString class]] || viewerAvatar.length == 0) {
            viewerAvatar = @"https://www.polyv.net/images/effect/effect-device.png";
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
    NSString *viewerIdKey = @"PLV_VIEWER_ID";
    NSString *viewerId = [[NSUserDefaults standardUserDefaults] stringForKey:viewerIdKey];
    if (!viewerId) {
        viewerId = [self createViewerId];
        [[NSUserDefaults standardUserDefaults] setObject:viewerId forKey:viewerIdKey];
    }
    
    return viewerId;
}

- (NSString *)createViewerId {
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    [mutableString appendString:@"plv_ios_"];
    [mutableString appendFormat:@"%ld", (long)[NSDate date].timeIntervalSince1970];
    [mutableString appendFormat:@"_%05d", arc4random() % 100000];
    NSString *viewerId = [mutableString copy];
    return viewerId;
}

- (NSString *)getViewerName {
    NSString *viewerNameKey = @"PLV_VIEWER_NAME";
    NSString *viewerName = [[NSUserDefaults standardUserDefaults] stringForKey:viewerNameKey];
    if (!viewerName) {
        viewerName = [@"ios用户/" stringByAppendingFormat:@"%05d",arc4random() % 100000];
        [[NSUserDefaults standardUserDefaults] setObject:viewerName forKey:viewerNameKey];
    }
    return viewerName;
}

#pragma mark - 用户类型相关工具方法

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
