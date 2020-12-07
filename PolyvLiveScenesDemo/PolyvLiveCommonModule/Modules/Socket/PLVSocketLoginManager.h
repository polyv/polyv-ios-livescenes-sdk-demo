//
//  PLVSocketLoginManager.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/15.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVLiveRoomData.h"

typedef NS_ENUM(NSInteger, PLVLiveRoomErrorReason) {
    PLVLiveRoomErrorReasonRelogin,     // 有相同用户userId登陆，当前登陆用户被迫下线
    PLVLiveRoomErrorReasonLoginRefuse, // 登陆被拒（曾被管理人员踢出，目前暂未解封）
    PLVLiveRoomErrorReasonBeKicked,    // 被管理人员踢出房间
};

@class PLVSocketLoginManager;

@protocol PLVSocketLoginManagerDelegate <NSObject>

- (void)socketLoginManager_loginSuccess:(PLVSocketLoginManager *)socketLoginManager;

@required

- (void)socketLoginManager:(PLVSocketLoginManager *)socketLoginManager authorizationVerificationFailed:(PLVLiveRoomErrorReason)reason message:(NSString *)message;

@end

/// 信令用户登录服务
@interface PLVSocketLoginManager : NSObject

/// 初始化方法
- (instancetype)initWithDelegate:(id<PLVSocketLoginManagerDelegate>)delegate roomData:(PLVLiveRoomData *)roomData;

/// 登录socket服务器，连接聊天室
- (void)loginSocketServer;

/// 退出和断开socket连接
- (void)exitAndDisconnet;

@end
