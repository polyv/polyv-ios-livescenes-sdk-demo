//
//  PLVLiveWatchUser.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/13.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveWatchUser.h"
#import <PolyvBusinessSDK/PLVBSocketDefine.h>
#import <UIKit/UIKit.h>
#import <PolyvFoundationSDK/PLVDataUtil.h>

NSString *PLVSStringWithLiveWatchUserType(PLVLiveWatchUserType userType) {
    switch (userType) {
           case PLVLiveUserTypeStudent:
               return kPLVBSocketUserTypeStudent;
           case PLVLiveUserTypeSlice:
               return kPLVBSocketUserTypeSlice;
           case PLVLiveUserTypeViewer:
               return kPLVBSocketUserTypeViewer;
           case PLVLiveUserTypeGuest:
               return kPLVBSocketUserTypeGuest;
           case PLVLiveUserTypeTeacher:
               return kPLVBSocketUserTypeTeacher;
           case PLVLiveUserTypeAssistant:
               return kPLVBSocketUserTypeAssistant;
           default:
               return @"";
       }
}

@implementation PLVLiveWatchUser

+ (instancetype)watchUserWithViewerId:(NSString *)viewerId viewerName:(NSString *)viewerName viewerAvatar:(NSString *)viewerAvatar viewerType:(PLVLiveUserType)viewerType {
    if (!viewerId) {
        viewerId = [self getViewerId];
    }
    if (!viewerName) {
        viewerName = [self getViewerName];
    }
    if (!viewerAvatar) {
        viewerAvatar = @"https://www.polyv.net/images/effect/effect-device.png";
    }
    
    PLVLiveWatchUser *watchUser = [[PLVLiveWatchUser alloc] init];
    watchUser.viewerId = viewerId;
    watchUser.viewerName = viewerName;
    watchUser.viewerAvatar = viewerAvatar;
    watchUser.viewerType = viewerType;

    return watchUser;
}

+ (instancetype)watchUserWithViewerId:(NSString *)viewerId viewerName:(NSString *)viewerName {
    return [self watchUserWithViewerId:viewerId viewerName:viewerName viewerAvatar:nil viewerType:PLVLiveUserTypeStudent];
}

#pragma mark - 获取viewerName
+ (NSString *)getViewerName{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *VIEW_NAME_KEY = @"plv_view_name";
    
    NSString *viewerName = [userDefaults stringForKey:VIEW_NAME_KEY];
    if (! viewerName) {
        viewerName = [@"ios用户/" stringByAppendingFormat:@"%05d",arc4random() % 100000];
        [userDefaults setObject:viewerName forKey:VIEW_NAME_KEY];
    }
    
    return viewerName;
}

#pragma mark - 获取viewerId
+ (NSString *)getViewerId{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *VIEW_ID_KEY = @"plv_view_id";
    
    NSString *viewerId = [userDefaults stringForKey:VIEW_ID_KEY];
    if (! viewerId) {
        viewerId = [self createViewerId];
        [userDefaults setObject:viewerId forKey:VIEW_ID_KEY];
    }
    
    return viewerId;
}

#pragma mark - 创建viewerId
+ (NSString *)createViewerId {
    UIDevice *device = [UIDevice currentDevice];
    
    NSMutableString *deviceInfo = [NSMutableString string];
    [deviceInfo appendString:@"plv_ios_"];
    [deviceInfo appendString:device.name];
    [deviceInfo appendFormat:@"%@", device.systemName];
    [deviceInfo appendFormat:@"%@", device.systemVersion];
    [deviceInfo appendFormat:@"%.2f", device.batteryLevel];
    [deviceInfo appendFormat:@"%lld", [self getFreeDiskSpace]];
    [deviceInfo appendFormat:@"%ld", (long)[NSDate date].timeIntervalSince1970];
    
    NSString *viewerId = [[PLVDataUtil md5HexDigest:deviceInfo] uppercaseString];
    
    return viewerId;
}

#pragma mark - 获取未使用的磁盘空间
+ (int64_t)getFreeDiskSpace {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0) space = -1;
    return space;
}

@end
