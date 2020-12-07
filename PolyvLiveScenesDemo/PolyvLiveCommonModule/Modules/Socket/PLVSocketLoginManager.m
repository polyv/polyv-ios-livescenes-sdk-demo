//
//  PLVSocketLoginManager.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/15.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVSocketLoginManager.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import <PLVLiveScenesSDK/PLVSocketWrapper.h>

@interface PLVSocketLoginManager () <PLVSocketListenerProtocol>

@property (nonatomic, weak) id<PLVSocketLoginManagerDelegate> delegate;

@property (nonatomic, strong) PLVLiveRoomData *roomData;

@end

@implementation PLVSocketLoginManager

- (instancetype)initWithDelegate:(id<PLVSocketLoginManagerDelegate>)delegate roomData:(PLVLiveRoomData *)roomData {
    self = [super init];
       if (self) {
           self.delegate = delegate;
           self.roomData = roomData;
           // 监听socket数据
           [PLVSocketWrapper.sharedSocketWrapper addListener:self];
       }
       return self;
}

#pragma mark - Public

- (void)loginSocketServer {
    // 初始化一个登陆对象
    PLVLiveWatchUser *watchUser = self.roomData.watchUser;
    PLVBSocketUserType userType = watchUser.viewerType == PLVLiveWatchUserTypeStudent ? PLVBSocketUserTypeStudent : PLVBSocketUserTypeSlice;
    PLVBSocketUser *loginUser = [PLVBSocketUser socketLoginUser:self.roomData.channelId userId:watchUser.viewerId nickName:watchUser.viewerName avatarUrl:watchUser.viewerAvatar userType:userType userIdForAccount:self.roomData.userIdForAccount];
    
    // 登陆socket/聊天室服务器
    [PLVSocketWrapper.sharedSocketWrapper loginSocketServerWithUser:loginUser];
}

- (void)exitAndDisconnet {
    [PLVSocketWrapper.sharedSocketWrapper removeListener:self];
    [PLVSocketWrapper.sharedSocketWrapper clear];
}

#pragma mark - <PLVSocketListenerProtocol>

- (void)socket:(id<PLVSocketIOProtocol>)socket didReceiveMessage:(nonnull NSString *)string jsonDict:(nonnull NSDictionary *)jsonDict {
    NSString *userIdForWatchUser = self.roomData.userIdForWatchUser;
    
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:@"LOGIN_REFUSE"]) {
        [self authorizationVerificationFailed:PLVLiveRoomErrorReasonLoginRefuse message:@"您未被授权观看本直播"];
    } else if ([subEvent isEqualToString:@"RELOGIN"]) {
        [self authorizationVerificationFailed:PLVLiveRoomErrorReasonRelogin message:@"当前账号已在其他地方登录，您将被退出观看"];
    } else if ([subEvent isEqualToString:@"KICK"]) {
        NSDictionary *user = PLV_SafeDictionaryForDictKey(jsonDict, @"user");
        if ([PLV_SafeStringForDictKey(user, @"userId") isEqualToString:userIdForWatchUser]) {
            [self authorizationVerificationFailed:PLVLiveRoomErrorReasonBeKicked message:@"您未被授权观看本直播"];
        }
    }
}

- (void)socket:(id<PLVSocketIOProtocol>)socket didStatusChange:(PLVSocketStatus)status string:(NSString *)string {
    switch (status) {
        case PLVSocketStatusLogining: {
            NSLog(@"==========聊天室登陆中！");
        } break;
        case PLVSocketStatusLoginSuccess: {
            NSLog(@"==========登陆聊天室成功！");
            [self loginSuccess];
        } break;
        case PLVSocketStatusLoginFailed: { // 登陆失败
            PLVFSocketErrorCode code = [PLVSocketWrapper.sharedSocketWrapper socketLoginAckParser:string];
            NSString *errDescript = [PLVFSocketErrorCodeGenerator errorDescription:code];
            NSLog(@"==========登陆聊天室失败: %@",errDescript);
            if (code == PLVFSocketErrorCodeLoginAckBeKicked) {
                [self authorizationVerificationFailed:PLVLiveRoomErrorReasonBeKicked message:@"您未被授权观看本直播"];
            }
        } break;
        default:
            break;
    }
}

#pragma mark - Private

- (void)authorizationVerificationFailed:(PLVLiveRoomErrorReason)reason message:(NSString *)message {
    if ([self.delegate respondsToSelector:@selector(socketLoginManager:authorizationVerificationFailed:message:)]) {
        [self.delegate socketLoginManager:self authorizationVerificationFailed:reason message:message];
    }
}

- (void)loginSuccess {
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketLoginManager_loginSuccess:)]) {
        [self.delegate socketLoginManager_loginSuccess:self];
    }
}

@end
