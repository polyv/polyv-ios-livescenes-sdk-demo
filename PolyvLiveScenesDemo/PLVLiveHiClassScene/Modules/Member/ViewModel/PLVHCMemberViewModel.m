//
//  PLVHCMemberViewModel.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/6.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCMemberViewModel.h"
#import "PLVChatUser.h"
#import "PLVLinkMicOnlineUser.h"
#import "PLVRoomDataManager.h"

/// UI
#import "PLVHCGrantCupView.h"

/// 工具类
#import "PLVHCUtils.h"

@interface PLVHCMemberViewModel ()<
PLVMemberPresenterDelegate, // common层成员Presenter协议
PLVSocketManagerProtocol
>

/// 成员common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong) PLVMemberPresenter *presenter;

/// 聊天室在线人数
@property (nonatomic, assign) NSInteger onlineCount;

/// 聊天室移出人数
@property (nonatomic, assign) NSInteger kickedCount;

/// 聊天室在线学生列表
@property (nonatomic, copy) NSArray <PLVChatUser *> *onlineUserArray;

/// 聊天室移出学生列表
@property (nonatomic, copy) NSArray <PLVChatUser *> *kickedUserArray;

@end

@implementation PLVHCMemberViewModel

#pragma mark - [ Public Method ]

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVHCMemberViewModel *viewModel = nil;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (void)setup {
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT)];
    
    // 初始化成员模块
    self.presenter = [[PLVMemberPresenter alloc] init];
    self.presenter.monitorKickUser = YES;
    self.presenter.delegate = self;
    
    if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass) { // 开始上课之后才开始获取成员列表
        [self start];
    }
}

- (void)clear {
    // 成员列表数据停止自动更新
    [self.presenter stop];
    self.presenter = nil;
    
    self.onlineCount = 0;
    self.kickedCount = 0;
    self.onlineUserArray = nil;
    self.kickedUserArray = nil;
    
    [[PLVSocketManager sharedManager] removeDelegate:self];
}

- (void)start {
    [self.presenter start];
}

- (void)stop {
    [self.presenter stop];
}

- (void)loadOnlineUserList {
    [self.presenter loadOnlineUserList];
}

- (PLVChatUser * _Nullable)userInListWithUserId:(NSString *)userId {
    return [self.presenter userInListWithUserId:userId];
}

- (void)kickUserWithUserId:(NSString *)userId {
    [self.presenter kickUserWithUserId:userId];
}

- (void)unkickUser:(PLVChatUser *)user {
    [self.presenter unkickUser:user];
}

- (void)banUserWithUserId:(NSString *)userId banned:(BOOL)banned {
    [self.presenter banUserWithUserId:userId banned:banned];
}

- (void)brushPermissionWithUserId:(NSString *)userId auth:(BOOL)auth {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    __block BOOL match = NO;
    [self.onlineUserArray enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            if (obj.onlineUser) {
                [obj.onlineUser updateUserCurrentBrushAuth:auth];
            }
            obj.currentBrushAuth = auth;
            match = YES;
            *stop = YES;
        }
    }];
    if (match) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
            __weak typeof(self) weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
            })
        }
    }
}

- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicUserArray {
    [self.presenter refreshUserListWithLinkMicOnlineUserArray:linkMicUserArray];
}

#pragma mark - [ Private Method ]

- (void)updateOnlineUser {
    NSInteger removeCount = 0;
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.presenter.userCount];
    for (PLVChatUser *user in [self.presenter userList]) {
        if (user.userType == PLVRoomUserTypeSCStudent) {
            [muArray addObject:user];
        } else {
            removeCount++;
        }
    }
    self.onlineCount = self.presenter.userCount - removeCount;
    self.onlineUserArray = [muArray copy];
}

- (void)updateKickedUser {
    NSInteger removeCount = 0;
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.presenter.kickedCount];
    for (PLVChatUser *user in [self.presenter kickedUserList]) {
        if (user.userType == PLVRoomUserTypeSCStudent) {
            [muArray addObject:user];
        } else {
            removeCount++;
        }
    }
    self.kickedCount = self.presenter.kickedCount - removeCount;
    self.kickedUserArray = [muArray copy];
}

- (void)handUpWithUserId:(NSString *)userId status:(BOOL)raiseHandStatus count:(NSInteger)raiseHandCount {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    // 找到对应的成员，并修改该成员的举手属性
    __block BOOL match = NO;
    [self.onlineUserArray enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            if (obj.onlineUser) {
                [obj.onlineUser updateUserCurrentHandUp:raiseHandStatus];
            }
            obj.currentHandUp = raiseHandStatus;
            match = YES;
            *stop = YES;
        }
    }];
    
    if (match) { // 找到匹配的成员则触发在线成员数据变化回调
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
            __weak typeof(self) weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
            })
        }
    }
    
    // 不管是否找到匹配的成员，如果当前用户是讲师，触发举手状态变化回调
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(raiseHandStatusChanged:status:count:)]) {
            __weak typeof(self) weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate raiseHandStatusChanged:weakSelf status:raiseHandStatus count:raiseHandCount];
            })
        }
    }
}

- (void)grantCupWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    // 找到对应的成员，并修改该成员的奖杯数属性
    __block NSString *nick = nil;
    [self.onlineUserArray enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            obj.cupCount++;
            if (obj.onlineUser) {
                [obj.onlineUser updateUserCurrentGrantCupCount:obj.cupCount];
            }
            nick = obj.userName;
            *stop = YES;
        }
    }];
    
    if (nick) { // 找到匹配的成员则触发在线成员数据变化回调
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
            __weak typeof(self) weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
            })
        }
    }
    
    plv_dispatch_main_async_safe(^{// 不管是否找到匹配的成员，均展示奖杯动画
        [PLVHCGrantCupView showWithNickName:nick];
    })
}

/// 处理TEACHER_SET_PERMISSION回调
- (void)handleSocket_TEACHER_SET_PERMISSION:(NSDictionary *)jsonDict {
    NSString *type = PLV_SafeStringForDictKey(jsonDict, @"type");
    NSString *userId = PLV_SafeStringForDictKey(jsonDict, @"userId");
    NSString *status = PLV_SafeStringForDictKey(jsonDict, @"status");
    
    if (![PLVFdUtil checkStringUseable:type] ||
        ![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:status]) {
        return;
    }
    
    if ([type isEqualToString:@"raiseHand"]) { // 举手事件
        BOOL raiseHand = [status isEqualToString:@"1"];
        NSInteger raiseHandCount = PLV_SafeIntegerForDictKey(jsonDict, @"raiseHandCount");
        [self handUpWithUserId:userId status:raiseHand count:raiseHandCount];
        
    } else if ([type isEqualToString:@"cup"] &&
               [status isEqualToString:@"1"]) { // 授予奖杯事件
        [self grantCupWithUserId:userId];
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVMemberPresenterDelegate

- (void)userListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    [self updateOnlineUser];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
        })
    }
}

- (void)kickedUserListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    [self updateKickedUser];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(kickedUserListChangedInMemberViewModel:)]) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            [weakSelf.delegate kickedUserListChangedInMemberViewModel:weakSelf];
        })
    }
}

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
