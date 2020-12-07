//
//  PLVLiveWatchUser.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/13.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveUser.h"

typedef NS_ENUM(NSUInteger, PLVLiveWatchUserType) {
    PLVLiveWatchUserTypeStudent   = 1, // 普通观众
    PLVLiveWatchUserTypeSlice     = 2, // 云课堂学员
    PLVLiveWatchUserTypeViewer    = 3, // 客户端的参与者
    
    PLVLiveWatchUserTypeGuest     = 4, // 嘉宾
    PLVLiveWatchUserTypeTeacher   = 5, // 讲师
    PLVLiveWatchUserTypeAssistant = 6, // 助教
};

NSString *PLVSStringWithLiveWatchUserType(PLVLiveWatchUserType userType);

/// 直播观看用户信息
@interface PLVLiveWatchUser : NSObject

/// 用户Id，用于登录socket、发送日志
@property (nonatomic, copy) NSString *viewerId;

/// 用户昵称，用于登录socket、发送日志
@property (nonatomic, copy)  NSString *viewerName;

/// 用户头像地址，登陆socket
@property (nonatomic, copy) NSString *viewerAvatar;

/// 用户类型/角色，登陆socket
@property (nonatomic, assign)  PLVLiveUserType viewerType;

/// 生成一个观看用户对象（默认生成viewerAvatar和viewerType）
+ (instancetype)watchUserWithViewerId:(NSString *)viewerId viewerName:(NSString *)viewerName;

/// 生成一个观看用户对象
+ (instancetype)watchUserWithViewerId:(NSString *)viewerId viewerName:(NSString *)viewerName viewerAvatar:(NSString *)viewerAvatar viewerType:(PLVLiveUserType)viewerType;

@end
