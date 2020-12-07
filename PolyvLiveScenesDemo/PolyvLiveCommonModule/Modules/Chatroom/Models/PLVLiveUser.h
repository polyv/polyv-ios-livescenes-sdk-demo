//
//  PLVLiveUser.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/13.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Define "userType" constant string
extern NSString *const kPLVLiveUserTypeStudent;
extern NSString *const kPLVLiveUserTypeSlice;
extern NSString *const kPLVLiveUserTypeViewer;

extern NSString *const kPLVLiveUserTypeGuest;
extern NSString *const kPLVLiveUserTypeTeacher;
extern NSString *const kPLVLiveUserTypeAssistant;
extern NSString *const kPLVLiveUserTypeManager;

extern NSString *const kPLVLiveUserTypeDummy;

/// Define "userType" constant type
typedef NS_ENUM(NSUInteger, PLVLiveUserType) {
    PLVLiveUserTypeUnknown   = 0,
    
    PLVLiveUserTypeStudent   = 1, // 普通观众
    PLVLiveUserTypeSlice     = 2, // 云课堂学员
    PLVLiveUserTypeViewer    = 3, // 客户端的参与者
    
    PLVLiveUserTypeGuest     = 4, // 嘉宾
    PLVLiveUserTypeTeacher   = 5, // 讲师
    PLVLiveUserTypeAssistant = 6, // 助教
    PLVLiveUserTypeManager   = 7, // 管理员
    
    PLVLiveUserTypeDummy     = 8
};

/// 是否有身份用户
BOOL IsSpecialIdentityOfLiveUserType(PLVLiveUserType userType);

PLVLiveUserType PLVLiveUserTypeWithString(NSString *userType);

NSString *PLVSStringWithLiveUserType(PLVLiveUserType userType, BOOL english);

/// 直播用户信息抽象基类
@interface PLVLiveUser : NSObject

/// 是否是登陆用户
@property (nonatomic, assign) BOOL isLoginUser;

/// 用户Id
@property (nonatomic, copy) NSString *userId;

/// 用户昵称
@property (nonatomic, copy)  NSString *nickName;

/// 用户头像地址
@property (nonatomic, copy) NSString *avatarUrl;

/// 用户头衔
@property (nonatomic, copy) NSString *actor;

/// 用户类型/角色
@property (nonatomic, copy)  NSString *role;

/// 用户类型/角色
@property (nonatomic, assign)  PLVLiveUserType userType;

@end
