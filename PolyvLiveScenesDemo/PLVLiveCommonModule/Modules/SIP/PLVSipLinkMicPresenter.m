//
//  PLVSipLinkMicPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/6/23.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSipLinkMicPresenter.h"

// 模块
#import "PLVRoomUser.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>


/// sip事件
typedef NS_ENUM(NSUInteger, PLVSipLinkMicEventType) {
    /// 呼叫
    PLVSipLinkMicEventType_Call = 0,
    /// 取消呼叫
    PLVSipLinkMicEventType_CancelCall,
    /// 重新呼叫
    PLVSipLinkMicEventType_ReCall,
    /// 呼叫超时
    PLVSipLinkMicEventType_CallTimeout,
    /// 拒绝呼叫
    PLVSipLinkMicEventType_CallReject,
    /// 断开呼叫
    PLVSipLinkMicEventType_DisconnectCall,
    /// 呼叫失败
    PLVSipLinkMicEventType_CallFail,
    /// 呼叫成功
    PLVSipLinkMicEventType_CallSuccess,
    /// 挂断
    PLVSipLinkMicEventType_HangUp,
    /// 呼入
    PLVSipLinkMicEventType_CallIn,
    /// 静音
    PLVSipLinkMicEventType_Mute,
    /// 取消静音
    PLVSipLinkMicEventType_UnMute,
};

@interface PLVSipLinkMicPresenter ()<
PLVSocketManagerProtocol // socket协议
>

/// 已入会列表
@property (nonatomic, strong) NSMutableArray <PLVSipLinkMicUser *> *inLineDialsMuArray;
/// 呼叫中列表
@property (nonatomic, strong) NSMutableArray <PLVSipLinkMicUser *> *callOutDialsMuArray;
/// 待接通列表
@property (nonatomic, strong) NSMutableArray <PLVSipLinkMicUser *> *callInDialsMuArray;
/// 已入会列表（对外）
@property (nonatomic, copy) NSArray <PLVSipLinkMicUser *> *inLineDialsArray;
/// 呼叫中列表（对外）
@property (nonatomic, copy) NSArray <PLVSipLinkMicUser *> *callOutDialsArray;
/// 待接通列表（对外）
@property (nonatomic, copy) NSArray <PLVSipLinkMicUser *> *callInDialsArray;
@property (nonatomic, strong) dispatch_queue_t arraySafeQueue;
@property (nonatomic, strong) dispatch_queue_t requestSipLinkMicOnlineListSafeQueue;

@property (nonatomic, strong) NSTimer * sipLinkMicTimer;
@end

@implementation PLVSipLinkMicPresenter {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

- (void)dealloc{
    [_sipLinkMicTimer invalidate];
    _sipLinkMicTimer = nil;
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - [ Private Methods ]

- (void)setup{
    /// 初始化 数据// 同步值

    self.inLineDialsMuArray = [[NSMutableArray<PLVSipLinkMicUser *> alloc] init];
    self.callOutDialsMuArray = [[NSMutableArray<PLVSipLinkMicUser *> alloc] init];
    self.callInDialsMuArray = [[NSMutableArray<PLVSipLinkMicUser *> alloc] init];
    self.inLineDialsArray = self.inLineDialsMuArray;
    self.callOutDialsArray = self.callOutDialsMuArray;
    self.callInDialsArray = self.callInDialsMuArray;
    self.arraySafeQueue = dispatch_queue_create("PLVSipLinkMicPresenterArraySafeQueue", DISPATCH_QUEUE_SERIAL);
    self.requestSipLinkMicOnlineListSafeQueue = dispatch_queue_create("PLVSipLinkMicPresenterRequestLinkMicOnlineListSafeQueue", DISPATCH_QUEUE_SERIAL);
    
    /// 创建 获取sip在线用户列表 定时器
    self.sipLinkMicTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(sipLinkMicTimerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.sipLinkMicTimer forMode:NSRunLoopCommonModes];
    [self.sipLinkMicTimer fire];
    
    /// 添加 socket 事件监听
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
}


/// 连麦用户列表管理
#pragma mark LinkMic User Manage

- (void)refreshSipLinkMicUserListWithDataDictionary:(NSDictionary *)dataDictionary {
    NSArray * callInDialsList = dataDictionary[@"callInDials"];
    NSArray * callOutDialsList = dataDictionary[@"callOutDials"];
    NSArray * inLineDialsList = dataDictionary[@"inLineDials"];
    
    [self refreshSipLinkMicUserListWithDataArray:callInDialsList sipLinkMicListStatus:PLVSipLinkMicListStatus_CallIn];
    [self refreshSipLinkMicUserListWithDataArray:callOutDialsList sipLinkMicListStatus:PLVSipLinkMicListStatus_CallOut];
    [self refreshSipLinkMicUserListWithDataArray:inLineDialsList sipLinkMicListStatus:PLVSipLinkMicListStatus_InLine];
}

- (void)refreshSipLinkMicUserListWithDataArray:(NSArray *)dataArray sipLinkMicListStatus:(PLVSipLinkMicListStatus)sipLinkMicListStatus {
    NSArray * currentSipLinkMicListArray;
    if (![PLVFdUtil checkArrayUseable:dataArray]) {
        [self removeAllUserWithSipLinkMicListStatus:sipLinkMicListStatus];
        return;
    }
    if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallIn) {
        currentSipLinkMicListArray = [self.callInDialsMuArray copy];
    } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallOut) {
        currentSipLinkMicListArray = [self.callOutDialsMuArray copy];
    } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_InLine) {
        currentSipLinkMicListArray = [self.inLineDialsMuArray copy];
    } else {
        return;
    }
    
    // 删除用户
    for (PLVSipLinkMicUser * exsitUser in currentSipLinkMicListArray) {
        BOOL inCurrentList = NO;
        for (NSDictionary * userInfo in dataArray) {
            NSString * phoneNum = userInfo[@"phone"];
            if ([PLVFdUtil checkStringUseable:phoneNum]) {
                if ([phoneNum isEqualToString:exsitUser.phone]) {
                    inCurrentList = YES;
                    break;
                }
            }
        }
        if (!inCurrentList) {
            [self removeUserFromUserList:exsitUser.phone sipLinkMicListStatus:sipLinkMicListStatus];
        }
    }
    // 添加用户
    for (NSDictionary * userInfo in dataArray) {
        BOOL exitList = NO;
        for (PLVSipLinkMicUser * exsitUser in currentSipLinkMicListArray) {
            NSString * phoneNum = userInfo[@"phone"];
            if ([PLVFdUtil checkStringUseable:phoneNum]) {
                if ([phoneNum isEqualToString:exsitUser.phone]) {
                    exitList = YES;
                    break;
                }
            }
        }
        if (!exitList) {
            [self addUserIntoUserList:userInfo sipLinkMicListStatus:sipLinkMicListStatus];
        }
    }
}

- (void)removeAllUserWithSipLinkMicListStatus:(PLVSipLinkMicListStatus)sipLinkMicListStatus{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallIn && [PLVFdUtil checkArrayUseable:self.callInDialsMuArray]) {
                [weakSelf.callInDialsMuArray removeAllObjects];
                weakSelf.callInDialsArray = weakSelf.callInDialsMuArray;
                [weakSelf callbackForSipLinkMicUserListRefresh];
            } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallOut && [PLVFdUtil checkArrayUseable:self.callOutDialsMuArray]) {
                [weakSelf.callOutDialsMuArray removeAllObjects];
                weakSelf.callOutDialsArray = weakSelf.callOutDialsMuArray;
                [weakSelf callbackForSipLinkMicUserListRefresh];
            } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_InLine && [PLVFdUtil checkArrayUseable:self.inLineDialsMuArray]) {
                [weakSelf.inLineDialsMuArray removeAllObjects];
                weakSelf.inLineDialsArray = self.inLineDialsMuArray;
                [weakSelf callbackForSipLinkMicUserListRefresh];
            } else {
                return;
            }
        });
    }
}

- (void)removeUserFromUserList:(NSString *)sipLinkMicUserPhoneId sipLinkMicListStatus:(PLVSipLinkMicListStatus)sipLinkMicListStatus{
    if (![PLVFdUtil checkStringUseable:sipLinkMicUserPhoneId]) {
        return;
    }
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            int index = -1;
            PLVSipLinkMicUser * user;
            if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallIn) {
                for (int i = 0; i < weakSelf.callInDialsMuArray.count; i++) {
                    user = weakSelf.callInDialsMuArray[i];
                    if ([user.phone isEqualToString:sipLinkMicUserPhoneId]) {
                        index = i;
                        break;
                    }
                }
                if (index >= 0 && index <weakSelf.callInDialsMuArray.count && user != nil) {
                    [weakSelf.callInDialsMuArray removeObject:user];
                    weakSelf.callInDialsArray = weakSelf.callInDialsMuArray;
                    [weakSelf callbackForSipLinkMicUserListRefresh];
                } else{
                    NSLog(@"PLVSipLinkMicPresenter - remove sip link mic user(%@) failed, index(%d) not in the call-in array",sipLinkMicUserPhoneId,index);
                }
            } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallOut) {
                for (int i = 0; i < weakSelf.callOutDialsMuArray.count; i++) {
                    user = weakSelf.callOutDialsMuArray[i];
                    if ([user.phone isEqualToString:sipLinkMicUserPhoneId]) {
                        index = i;
                        break;
                    }
                }
                if (index >= 0 && index <weakSelf.callOutDialsMuArray.count && user != nil) {
                    [weakSelf.callOutDialsMuArray removeObject:user];
                    weakSelf.callOutDialsArray = weakSelf.callOutDialsMuArray;
                    [weakSelf callbackForSipLinkMicUserListRefresh];
                } else{
                    NSLog(@"PLVSipLinkMicPresenter - remove sip link mic user(%@) failed, index(%d) not in the call-out array",sipLinkMicUserPhoneId,index);
                }
            } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_InLine) {
                for (int i = 0; i < weakSelf.inLineDialsMuArray.count; i++) {
                    user = weakSelf.inLineDialsMuArray[i];
                    if ([user.phone isEqualToString:sipLinkMicUserPhoneId]) {
                        index = i;
                        break;
                    }
                }
                if (index >= 0 && index <weakSelf.inLineDialsMuArray.count && user != nil) {
                    [weakSelf.inLineDialsMuArray removeObject:user];
                    weakSelf.inLineDialsArray = weakSelf.inLineDialsMuArray;
                    [weakSelf callbackForSipLinkMicUserListRefresh];
                } else{
                    NSLog(@"PLVSipLinkMicPresenter - remove sip link mic user(%@) failed, index(%d) not in the in-line array",sipLinkMicUserPhoneId,index);
                }
            }
        });
    }
}

- (void)addUserIntoUserList:(NSDictionary *)userInfo sipLinkMicListStatus:(PLVSipLinkMicListStatus)sipLinkMicListStatus {
    if (![PLVFdUtil checkDictionaryUseable:userInfo]){
        return;
    }
    PLVSipLinkMicUser *user = [[PLVSipLinkMicUser alloc]initWithUserInfo:userInfo];
    
    [self addSipLinkMicUserIntoUserList:(PLVSipLinkMicUser *)user sipLinkMicListStatus:sipLinkMicListStatus];
}

- (void)addSipLinkMicUserIntoUserList:(PLVSipLinkMicUser *)user sipLinkMicListStatus:(PLVSipLinkMicListStatus)sipLinkMicListStatus {
    if (!user || ![user isKindOfClass:PLVSipLinkMicUser.class]) {
        return;
    }
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallIn) {
                [weakSelf.callInDialsMuArray addObject:user];
                weakSelf.callInDialsArray = weakSelf.callInDialsMuArray;
                [weakSelf callbackForHasNewCallInSipLinkMicUser];
                [weakSelf callbackForSipLinkMicUserListRefresh];
            } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallOut) {
                [weakSelf.callOutDialsMuArray addObject:user];
                weakSelf.callOutDialsArray = weakSelf.callOutDialsMuArray;
                [weakSelf callbackForHasNewCallOutSipLinkMicUser];
                [weakSelf callbackForSipLinkMicUserListRefresh];
            } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_InLine) {
                [weakSelf.inLineDialsMuArray addObject:user];
                weakSelf.inLineDialsArray = weakSelf.inLineDialsMuArray;
                [weakSelf callbackForSipLinkMicUserListRefresh];
            }
        });
    }
}

- (NSInteger)findUserFromUserList:(NSString *)sipLinkMicUserPhoneId sipLinkMicListStatus:(PLVSipLinkMicListStatus)sipLinkMicListStatus {
    NSInteger targetIndex = -1;
    if (![PLVFdUtil checkStringUseable:(NSString *)sipLinkMicUserPhoneId]){
        return targetIndex;
    }
    NSArray * currentSipLinkMicListArray;
    if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallIn) {
        currentSipLinkMicListArray = [self.callInDialsMuArray copy];
    } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_CallOut) {
        currentSipLinkMicListArray = [self.callOutDialsMuArray copy];
    } else if (sipLinkMicListStatus == PLVSipLinkMicListStatus_InLine) {
        currentSipLinkMicListArray = [self.inLineDialsMuArray copy];
    } else {
        return targetIndex;
    }
    
    for (int i = 0; i < currentSipLinkMicListArray.count; i++) {
        PLVSipLinkMicUser * exsitUser = currentSipLinkMicListArray[i];
        if ([sipLinkMicUserPhoneId isEqualToString:exsitUser.phone]) {
            targetIndex = i;
            break;
        }
    }
    return targetIndex;
}
- (void)setInLineDialsArrayAllMute:(BOOL)mute{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            for (int i = 0; i < weakSelf.inLineDialsMuArray.count; i++) {
                weakSelf.inLineDialsMuArray[i].muteStatus = mute ? 1: 0;
            }
            weakSelf.inLineDialsArray = weakSelf.inLineDialsMuArray;
            [weakSelf callbackForSipLinkMicUserListRefresh];
        });
    }
}
    
- (void)setInLineDialsArrayUser:(PLVSipLinkMicUser *)user mute:(BOOL)mute{
    NSInteger index = [self findUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_InLine];
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            if (index != -1 && index < weakSelf.inLineDialsMuArray.count) {
                weakSelf.inLineDialsMuArray[index].muteStatus = mute ? 1: 0;
                weakSelf.inLineDialsArray = weakSelf.inLineDialsMuArray;
                [weakSelf callbackForSipLinkMicUserListRefresh];
            }
        });
    }
}

#pragma mark Callback

- (void)callbackForSipLinkMicUserListRefresh{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvSipLinkMicPresenterUserListRefresh:)]) {
            [self.delegate plvSipLinkMicPresenterUserListRefresh:self];
        }
    })
}

- (void)callbackForHasNewCallInSipLinkMicUser{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvSipLinkMicPresenterHasNewCallInUser:)]) {
            [self.delegate plvSipLinkMicPresenterHasNewCallInUser:self];
        }
    })
}

- (void)callbackForHasNewCallOutSipLinkMicUser{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvSipLinkMicPresenterHasNewCallOutUser:)]) {
            [self.delegate plvSipLinkMicPresenterHasNewCallOutUser:self];
        }
    })
}

#pragma mark Socket

- (PLVSipLinkMicUser *)createUserWithJsonDict:(NSDictionary *)jsonDict {
    PLVSipLinkMicUser *user = [[PLVSipLinkMicUser  alloc] init];
    user.userName = PLV_SafeStringForDictKey(jsonDict, PLVSocketIOSipLinkMic_name);
    user.phone = PLV_SafeStringForDictKey(jsonDict, PLVSocketIOSipLinkMic_phoneNumber);
    return user;
}

- (void)handleSocketEvent:(PLVSipLinkMicEventType)eventType jsonDict:(NSDictionary *)jsonDict {
    PLVSipLinkMicUser *user = [self createUserWithJsonDict:jsonDict];
    switch (eventType) {
            
        case PLVSipLinkMicEventType_Call:{
            NSInteger targetIndex = [self findUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_CallOut];
            if (targetIndex == -1) {
                user.status = 1;
                [self addSipLinkMicUserIntoUserList:user  sipLinkMicListStatus:PLVSipLinkMicListStatus_CallOut];
            } else {
                if (targetIndex < self.callOutDialsMuArray.count) {
                    self.callOutDialsMuArray[targetIndex].status = 1;
                    [self callbackForSipLinkMicUserListRefresh];
                }
            }
        } break;
            
        case PLVSipLinkMicEventType_CancelCall:{
 
        } break;
            
        case PLVSipLinkMicEventType_ReCall:{
            
        } break;
            
        case PLVSipLinkMicEventType_CallTimeout:{
            [self removeUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_CallOut];
        } break;
            
            
        case PLVSipLinkMicEventType_DisconnectCall:{
            
        } break;
            
        case PLVSipLinkMicEventType_CallFail:{
            
        } break;
            
            
        case PLVSipLinkMicEventType_CallSuccess:{
            [self removeUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_CallIn];
            [self removeUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_CallOut];
            NSInteger targetIndex = [self findUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_InLine];
            if (targetIndex == -1) {
                user.status = 1;
                [self addSipLinkMicUserIntoUserList:user  sipLinkMicListStatus:PLVSipLinkMicListStatus_InLine];
            }
        } break;
            
        case PLVSipLinkMicEventType_HangUp:{
            [self removeUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_InLine];
        } break;
            
        case PLVSipLinkMicEventType_CallIn:{
            NSInteger targetIndex = [self findUserFromUserList:user.phone sipLinkMicListStatus:PLVSipLinkMicListStatus_CallIn];
            if (targetIndex == -1) {
                user.status = 1;
                [self addSipLinkMicUserIntoUserList:user  sipLinkMicListStatus:PLVSipLinkMicListStatus_CallIn];
            }
        } break;
            
        case PLVSipLinkMicEventType_Mute:{
            BOOL isAll = [PLV_SafeStringForDictKey(jsonDict, PLVSocketIOSipLinkMic_isAll) isEqualToString:@"Y"];
            if (isAll) {
                [self setInLineDialsArrayAllMute:YES];
            } else {
                [self setInLineDialsArrayUser:user mute:YES];
            }
        } break;
            
        case PLVSipLinkMicEventType_UnMute:{
            BOOL isAll = [PLV_SafeStringForDictKey(jsonDict, PLVSocketIOSipLinkMic_isAll) isEqualToString:@"Y"];
            if (isAll) {
                [self setInLineDialsArrayAllMute:NO];
            } else {
                [self setInLineDialsArrayUser:user mute:NO];
            }
        } break;
            
        default:
            break;
    }
}

#pragma mark Getter

- (NSString *)channelId{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.channelId;
}

#pragma mark - [ Event ]
#pragma mark Timer
- (void)sipLinkMicTimerEvent:(NSTimer *)timer{
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestSIPDialLinesListWithChannelId:self.channelId completion:^(NSDictionary *data) {
        if (weakSelf.arraySafeQueue){
            dispatch_async(weakSelf.arraySafeQueue, ^{
                [weakSelf refreshSipLinkMicUserListWithDataDictionary:data];
            });
        }
    } failure:^(NSError *error) {
        NSLog(@"PLVSipLinkMicPresenter - request sip link mic online list failed, error:%@",error);
    }];
}

#pragma mark - [ Delegate ]
#pragma mark PLVSocketManagerProtocol

/// socket 接收到 "主动监听" 事件（不包含 "message" 事件）
- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([event isEqualToString:PLVSocketIOSipLinkMic_EVENT]) {
        NSString *type = PLV_SafeStringForDictKey(jsonDict, PLVSocketIOSipLinkMic_type);
        if ([type isEqualToString:PLVSocketIOSipLinkMic_call_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_Call jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_callIn_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_CallIn jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_cancelCall_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_CancelCall jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_recall_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_ReCall jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_callTimeout_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_CallTimeout jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_callReject_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_CallReject jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_disconnectCall_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_DisconnectCall jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_callFail_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_CallFail jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_callSuccess_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_CallSuccess jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_hangUp_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_HangUp jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_mute_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_Mute jsonDict:jsonDict];
        } else if ([type isEqualToString:PLVSocketIOSipLinkMic_unMute_key]) {
            [self handleSocketEvent:PLVSipLinkMicEventType_UnMute jsonDict:jsonDict];
        }
    }
}

@end
