//
//  PLVHCPermissionEvent.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/8/3.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCPermissionEvent.h"

// 模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVHCPermissionEvent()<
PLVSocketManagerProtocol
>

@end

@implementation PLVHCPermissionEvent {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static PLVHCPermissionEvent *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[PLVHCPermissionEvent alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)setup {
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
}

- (BOOL)sendRaiseHandMessageWithUserId:(NSString *)userId {
    if (!userId ||
        ![userId isKindOfClass:[NSString class]] ||
        userId.length == 0) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeSocket, @"%s sendRaiseHandMessageWithUserId failed with 【param illegal】(userId is nil)", __FUNCTION__);
        return NO;
    }
    
    return [[PLVSocketManager sharedManager] emitPermissionMessageWithUserId:userId type:PLVSocketPermissionTypeRaiseHand status:YES];
}

- (BOOL)sendGrantCupMessageWithUserId:(NSString *)userId {
    if (!userId ||
        ![userId isKindOfClass:[NSString class]] ||
        userId.length == 0) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeSocket, @"%s sendGrantCupMessageWithUserId failed with 【param illegal】(userId is nil)", __FUNCTION__);
        return NO;
    }
    BOOL specialRole = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
    if (!specialRole) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeSocket, @"%s sendGrantCupMessageWithUserId failed with 【权限不足】(specialRole:%@)", __FUNCTION__, specialRole);
        return NO;
    }
    
    return [[PLVSocketManager sharedManager] emitPermissionMessageWithUserId:userId type:PLVSocketPermissionTypeCup status:YES];
}

#pragma mark - [ Private Method ]

#pragma mark 处理TEACHER_SET_PERMISSION回调

- (void)handleSocket_TEACHER_SET_PERMISSION:(NSDictionary *)jsonDict{
    NSString * type = PLV_SafeStringForDictKey(jsonDict, @"type");;
    NSString * userId = PLV_SafeStringForDictKey(jsonDict, @"userId");
    NSString * status = PLV_SafeStringForDictKey(jsonDict, @"status");
    NSInteger raiseHandCount = PLV_SafeIntegerForDictKey(jsonDict, @"raiseHandCount");
    
    if (![PLVFdUtil checkStringUseable:type] ||
        ![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:status]){
        return;
    }
    
    if ([type isEqualToString:@"raiseHand"]) { // 举手事件
        BOOL raiseHand = [status isEqualToString:@"1"];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(permissionEvent:didChangeRaiseHandStatus:userId:raiseHandCount:)]) {
            plv_dispatch_main_async_safe(^{
                [self.delegate permissionEvent:self didChangeRaiseHandStatus:raiseHand userId:userId raiseHandCount:raiseHandCount];
            })
        }
        
    } else if ([type isEqualToString:@"cup"] &&
               [status isEqualToString:@"1"]) { // 授予奖杯事件
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(permissionEvent:didGrantCupWithUserId:)]) {
            plv_dispatch_main_async_safe(^{
                [self.delegate permissionEvent:self didGrantCupWithUserId:userId];
            })
        }
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([subEvent isEqualToString:@"TEACHER_SET_PERMISSION"]) { // 讲师授权事件
        [self handleSocket_TEACHER_SET_PERMISSION:jsonDict];
    }
}

@end
