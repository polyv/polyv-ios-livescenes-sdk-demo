//
//  PLVRoomUser.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVSocketManager.h>
#import <PLVLiveScenesSDK/PLVLiveDefine.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVRoomUserType) {
    PLVRoomUserTypeUnknown   = 0,
    
    PLVRoomUserTypeStudent   = 1, // 普通观众
    PLVRoomUserTypeSlice     = 2, // 云课堂学员
    PLVRoomUserTypeViewer    = 3, // 客户端的参与者
    
    PLVRoomUserTypeGuest     = 4, // 嘉宾
    PLVRoomUserTypeTeacher   = 5, // 讲师
    PLVRoomUserTypeAssistant = 6, // 助教
    PLVRoomUserTypeManager   = 7, // 管理员
    
    PLVRoomUserTypeDummy     = 8  // 虚拟观众
};

/// 直播间用户
/// 直播间用户的属性在初始化后不允许修改
/// 如果需要修改，要重新初始化一个新的对象，再使用PLVRoomData的方法'-setupRoomUser:'重新配置
/// 否则会导致roomData里面的customParam对象的用户相关属性没能得到同步
@interface PLVRoomUser : NSObject

/// 用户唯一标识，用于登录socket、发送日志
@property (nonatomic, copy) NSString *viewerId;

/// 用户昵称，用于登录socket、发送日志
@property (nonatomic, copy) NSString *viewerName;

/// 用户头像地址，用于登陆socket
@property (nonatomic, copy) NSString *viewerAvatar;

/// 用户类型/角色，用于登陆socket
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;

/// 用户身份（中文），开播时用于登录socket
@property (nonatomic, copy) NSString *actor;

/// 用户身份（英文），开播时用于登录socket
@property (nonatomic, copy) NSString *role;

/// 初始化方法1
/// 使用自动生成的 viewerId、viewerName
/// 使用默认viewerAvatar
/// @param channelType 频道类型（不同频道类型对应不同viewerType）
- (instancetype)initWithChannelType:(PLVChannelType)channelType;

/// 初始化方法2
/// @param viewerId 用户ID
/// @param viewerName 用户昵称
/// @param viewerAvatar 用户头像
/// @param viewerType 用户类型
- (instancetype)initWithViewerId:(NSString * _Nullable)viewerId
                      viewerName:(NSString * _Nullable)viewerName
                    viewerAvatar:(NSString * _Nullable)viewerAvatar
                      viewerType:(PLVRoomUserType)viewerType;

/// 根据频道类型返回用户类型
/// PLVChannelTypePPT 对应 PLVRoomUserTypeSlice
/// PLVChannelTypeAlone 对应 PLVRoomUserTypeStudent
/// 非以上频道类型，返回 PLVRoomUserTypeViewer
/// @param channelType 频道类型（不同频道类型对应不同viewerType）
+ (PLVRoomUserType)userTypeWithChannelType:(PLVChannelType)channelType;

/// 根据roomUser用户类型返回socket模块用户类型
/// @param userType roomUser用户类型
+ (PLVSocketUserType)sockerUserTypeWithRoomUserType:(PLVRoomUserType)userType;

/// 根据用户类型枚举值判断是否是有身份用户
+ (BOOL)isSpecialIdentityWithUserType:(PLVRoomUserType)userType;

/// 将后端返回的userType字段转换为用户类型枚举值
+ (PLVRoomUserType)userTypeWithUserTypeString:(NSString *)userTypeString;

/// 将用户类型枚举值转换为字符串类型
+ (NSString *)userTypeStringWithUserType:(PLVRoomUserType)userType;

@end

NS_ASSUME_NONNULL_END
