//
//  PLVSipLinkMicUser.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/6/23.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSipLinkMicUser : NSObject

/// 通话时长
@property (nonatomic, assign) NSInteger callDuration;
/// 通话时长(分)
@property (nonatomic, copy) NSString * _Nullable callDurationString;
/// 呼入时间
@property (nonatomic, copy) NSString * _Nullable callTime;
/// 频道ID
@property (nonatomic, assign) NSInteger channelId;
/// 挂断时间
@property (nonatomic, copy) NSString * _Nullable hangTime;
/// 自增Id
@property (nonatomic, assign) NSInteger uid;
/// 信息
@property (nonatomic, copy) NSString * _Nullable msg;
/// 是否静音(0:否/1:是)
@property (nonatomic, assign) NSInteger muteStatus;
/// 电话号码
@property (nonatomic, copy) NSString * _Nullable phone;
/// 状态(1:待接听/2:已接听/3:已拒接/4:已挂断/5:系统自动挂断/6:系统自动接听)
@property (nonatomic, assign) NSInteger status;
/// 类型(1为呼入/2为呼出)
@property (nonatomic, assign) NSInteger type;
/// 用户ID
@property (nonatomic, copy) NSString * _Nullable userId;
/// 用户名称
@property (nonatomic, copy) NSString * _Nullable userName;

#pragma mark - [ 方法 ]
#pragma mark 创建

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
