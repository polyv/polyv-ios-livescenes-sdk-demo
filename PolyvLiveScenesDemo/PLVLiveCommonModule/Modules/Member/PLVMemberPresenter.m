//
//  PLVMemberPresenter.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/2/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVMemberPresenter.h"

// 模块
#import "PLVRoomUser.h"
#import "PLVChatUser.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSInteger kMemberCountPerLoading = 500;
static NSInteger kLoadUserListInterval = 20;
static NSInteger kLoadKickedUserListInterval = 20;

@interface PLVMemberPresenter ()<
PLVSocketManagerProtocol // socket协议
>
/// 在线人数
@property (nonatomic, assign) NSInteger userCount;
/// 移出人数
@property (nonatomic, assign) NSInteger kickedCount;
/// 在线用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *userArray;
/// 移出用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *kickedUserArray;
/// 是否自动间隔获取在线成员列表，默认为NO，调用start方法后为YES
@property (nonatomic, assign) BOOL autoly;
/// 只读，当前连麦在线用户数组
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> * currentOnlineUserArray;

@end

@implementation PLVMemberPresenter {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _userArrayLock;
    
    /// 操作移出用户数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _kickedUserArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - [ Public Method ]

#pragma mark - Start & Stop

- (void)start {
    if (self.autoly == YES) { // 避免因多次start而产生多个自动调用的任务，想再次start，必须先stop
        return;
    }
    self.autoly = YES;
    [self loadOnlineUserListAutoly:YES];
    
    if (self.monitorKickUser) {
        [self loadKickedUserListAutoly:YES];
    }
}

- (void)stop {
    self.autoly = NO;
}

#pragma mark 用户列表

- (void)loadOnlineUserList {
    [self loadOnlineUserListAutoly:NO];
}

- (NSArray <PLVChatUser *> *)userList {
    dispatch_semaphore_wait(_userArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *userList = [self.userArray copy];
    dispatch_semaphore_signal(_userArrayLock);
    return userList;
}

- (NSArray <PLVChatUser *> *)kickedUserList {
    dispatch_semaphore_wait(_kickedUserArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *userList = [self.kickedUserArray copy];
    dispatch_semaphore_signal(_kickedUserArrayLock);
    return userList;
}

- (PLVChatUser * _Nullable)userInListWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    
    __block PLVChatUser *chatUser = nil;
    [self.userList enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            chatUser = obj;
            *stop = YES;
        }
    }];
    return chatUser;
}

#pragma mark 用户列表变动操作

- (void)kickUserWithUserId:(NSString *)userId {
    if (self.monitorKickUser) {
        PLVChatUser *kickedUser = [self searchUserInUserArrayWithUserId:userId];
        [self addKickUser:kickedUser];
    }
    
    [self removeUserWithUserId:userId];
    
    // 数据变更通知
    [self notifyUserArrayChanged];
    [self notifyKickedUserArrayChanged];
}

- (void)unkickUser:(PLVChatUser *)user {
    if (!self.monitorKickUser) {
        return;
    }
    
    [self removeKickUser:user];
    // 数据变更通知
    [self notifyKickedUserArrayChanged];
}

- (void)banUserWithUserId:(NSString *)userId banned:(BOOL)banned {
    PLVChatUser *user = [self searchUserInUserArrayWithUserId:userId];
    if (!user) {
        return;
    }
    user.banned = banned;
    
    // 数据变更通知
    [self notifyUserArrayChanged];
}

#pragma mark 连麦业务相关

- (void)refreshUserListWithLinkMicWaitUserArray:(NSArray <PLVLinkMicWaitUser *>*)linkMicWaitUserArray {
    if (!linkMicWaitUserArray ||
        ![linkMicWaitUserArray isKindOfClass:[NSArray class]]) {
        return;
    }
    
    NSArray *originUserArray = [self.userArray copy];
    NSArray <NSString *> *userIdArray = [originUserArray valueForKeyPath:@"userId"];
    for (int i = 0; i < linkMicWaitUserArray.count; i++) {
        PLVLinkMicWaitUser *waitUser = linkMicWaitUserArray[i];
        if ([userIdArray containsObject:waitUser.userId]) { // 原本已经存在对应聊天室UserId的对象
            for (int j = 0; j < originUserArray.count; j++) {
                PLVChatUser *chatUser = originUserArray[j];
                if ([chatUser.userId isEqualToString:waitUser.userId]) {
                    chatUser.onlineUser = nil;
                    chatUser.waitUser = waitUser;
                    [self sortUsers];
                    [self notifyUserArrayChanged];
                    break;
                }
            }
        } else {
            if ([PLVFdUtil checkDictionaryUseable:waitUser.originalUserDict]) { // 原本不存在对应聊天室UserId的对象
                PLVChatUser * chatUser = [[PLVChatUser alloc] initWithUserInfo:waitUser.originalUserDict];
                chatUser.onlineUser = nil;
                chatUser.waitUser = waitUser;
                [self addUser:chatUser];
                [self notifyUserArrayChanged];
            }else{
                NSLog(@"PLVMemberPresenter - refreshUserListWithLinkMicWaitUserArray failed, waitUser.originalUserDict illegal %@",waitUser.userId);
            }
        }
    }
    
    NSArray <NSString *> *waitUserIdArray = [linkMicWaitUserArray valueForKeyPath:@"userId"];
    for (int i = 0; i < originUserArray.count; i++) { // 确保linkMicOnlineUserArray数组之外，不存在任何chatUser对象持有waitUser属性
        PLVChatUser *chatUser = originUserArray[i];
        if (![PLVFdUtil checkStringUseable:chatUser.userId]) {
            NSLog(@"PLVMemberPresenter - refreshUserListWithLinkMicWaitUserArray failed, chatUser.userId illegal %@", chatUser.userId);
            continue;
        }
        if (![waitUserIdArray containsObject:chatUser.userId] &&
            chatUser.waitUser) {
            chatUser.waitUser = nil;
            [self sortUsers];
            [self notifyUserArrayChanged];
        }
    }
}

- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicOnlineUserArray{
    if (!linkMicOnlineUserArray ||
        ![linkMicOnlineUserArray isKindOfClass:[NSArray class]]) {
        return;
    }
    
    NSArray *originUserArray = [self.userArray copy];
    NSArray <NSString *> *userIdArray = [originUserArray valueForKeyPath:@"userId"];
    for (int i = 0; i < linkMicOnlineUserArray.count; i++) {
        PLVLinkMicOnlineUser *onlineUser = linkMicOnlineUserArray[i];
        if (![PLVFdUtil checkStringUseable:onlineUser.userId]) {
            NSLog(@"PLVMemberPresenter - refreshUserListWithLinkMicOnlineUserArray failed, onlineUser.userId illegal %@", onlineUser.userId);
            continue;
        }
        if ([userIdArray containsObject:onlineUser.userId]) { // 原本已经存在对应聊天室UserId的对象
            for (int j = 0; j < originUserArray.count; j++) {
                PLVChatUser *chatUser = originUserArray[j];
                if ([chatUser.userId isEqualToString:onlineUser.userId]) {
                    chatUser.waitUser = nil;
                    chatUser.onlineUser = onlineUser;
                    [self sortUsers];
                    [self notifyUserArrayChanged];
                    break;
                }
            }
        } else {
            if ([PLVFdUtil checkDictionaryUseable:onlineUser.originalUserDict]) { // 原本不存在对应聊天室UserId的对象
                PLVChatUser * chatUser = [[PLVChatUser alloc] initWithUserInfo:onlineUser.originalUserDict];
                chatUser.waitUser = nil;
                chatUser.onlineUser = onlineUser;
                [self addUser:chatUser];
                [self notifyUserArrayChanged];
            }else{
                NSLog(@"PLVMemberPresenter - refreshUserListWithLinkMicOnlineUserArray failed, onlineUser.originalUserDict illegal %@", onlineUser.userId);
            }
        }
    }
    
    NSArray <NSString *> *onlineUserIdArray = [linkMicOnlineUserArray valueForKeyPath:@"userId"];
    for (int i = 0; i < originUserArray.count; i++) { // 确保linkMicOnlineUserArray数组之外，不存在任何chatUser对象持有onlineUser属性
        PLVChatUser *chatUser = originUserArray[i];
        if (![PLVFdUtil checkStringUseable:chatUser.userId]) {
            NSLog(@"PLVMemberPresenter - refreshUserListWithLinkMicOnlineUserArray failed, chatUser.userId illegal %@", chatUser.userId);
            continue;
        }
        if (![onlineUserIdArray containsObject:chatUser.userId] &&
            chatUser.onlineUser) {
            chatUser.onlineUser = nil;
            [self sortUsers];
            [self notifyUserArrayChanged];
        }
    }
}

#pragma mark - [ Private Method ]

#pragma mark Initialize

- (void)setup {
    // 初始化信号量
    _userArrayLock = dispatch_semaphore_create(1);
    _kickedUserArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.userArray = [[NSMutableArray alloc] initWithCapacity:kMemberCountPerLoading];
    self.kickedUserArray = [[NSMutableArray alloc] initWithCapacity:20];
    
    // 监听socket消息
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
}

#pragma mark Getter
- (NSArray<PLVLinkMicOnlineUser *> *)currentOnlineUserArray{
    NSArray * currentOnlineUserList;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(currentOnlineUserListInMemberPresenter:)]) {
        currentOnlineUserList = [self.delegate currentOnlineUserListInMemberPresenter:self];
    }
    return currentOnlineUserList;
}

#pragma mark 在线用户

- (void)loadOnlineUserListAutoly:(BOOL)autoly {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSInteger roomId = [roomData.channelId integerValue];
    
    PLVRoomUser *roomUser = roomData.roomUser;
    BOOL isSpecial = [PLVRoomUser isSpecialIdentityWithUserType:roomUser.viewerType];
    // 非观看侧（开播、小班课）场景下，streamer 均为 YES；观看侧场景下，只有特殊身份 streamer 为 YES，否则后端会有性能问题
    BOOL streamer = (roomData.rtmpUrl || roomData.lessonInfo.lessonId) || isSpecial;
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestChatRoomListUsersWithRoomId:roomId page:0 length:kMemberCountPerLoading sessionId:roomData.lessonInfo.lessonId streamer:streamer success:^(NSDictionary *data) {
        NSInteger count = [data[@"count"] integerValue];
        weakSelf.userCount = count;
        
        if (count > 0) {
            NSArray *userArray = data[@"userlist"];
            if ([userArray count] > 0) {
                NSMutableArray *userMuArray = [[NSMutableArray alloc] initWithCapacity:[userArray count]];
                for (NSDictionary *userDict in userArray) {
                    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
                    [userMuArray addObject:user];
                }
                [weakSelf updateUserArray:[userMuArray copy]];
            }
        } else {
            [self removeAllUser];
        }
        
        // 数据变更通知
        [weakSelf notifyUserArrayChanged];
        
        if (autoly) {
            [weakSelf loadOnlineUserListLater];
        }
    } failure:^(NSError * _Nonnull error) {
        if (autoly) {
            [weakSelf loadOnlineUserListLater];
        }
    }];
}

- (void)loadOnlineUserListLater {
    if (!self.autoly) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kLoadUserListInterval * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        [self loadOnlineUserListAutoly:YES];
    });
}

/// 获取接口返回的在线用户列表时
- (void)updateUserArray:(NSArray <PLVChatUser *> *)userArray {
    dispatch_semaphore_wait(_userArrayLock, DISPATCH_TIME_FOREVER);
    // 删除用户
    NSArray * currentUserArray = [self.userArray copy];
    for (PLVChatUser * exsitUser in currentUserArray) {
        BOOL inCurrentList = NO;
        for (PLVChatUser * userInNewest in userArray) {
            if ([userInNewest.userId isEqualToString:exsitUser.userId]) {
                inCurrentList = YES;
                break;
            }
        }
        
        if (!inCurrentList) {
            [self.userArray removeObject:exsitUser];
        }
    }
    
    // 添加用户
    for (PLVChatUser * userInNewest in userArray) {
        BOOL inNewestList = NO;
        for (PLVChatUser * exsitUser in currentUserArray) {
            if ([exsitUser.userId isEqualToString:userInNewest.userId]) {
                inNewestList = YES;
                break;
            }
        }
        
        if (!inNewestList) {
            [self.userArray addObject:userInNewest];
        }
    }
    dispatch_semaphore_signal(_userArrayLock);
    
    // 数据变更通知
    [self notifyUserArrayChanged];
    [self refreshUserListWithLinkMicOnlineUserArray:self.currentOnlineUserArray];
}

- (void)removeAllUser {
    dispatch_semaphore_wait(_userArrayLock, DISPATCH_TIME_FOREVER);
    [self.userArray removeAllObjects];
    dispatch_semaphore_signal(_userArrayLock);
}

/// socket 接收到用户登陆的消息时
- (void)addUser:(PLVChatUser *)user {
    PLVChatUser *existedUser = [self searchUserInUserArrayWithUserId:user.userId];
    if (existedUser) {
        return;
    }
    
    dispatch_semaphore_wait(_userArrayLock, DISPATCH_TIME_FOREVER);
    if ([user isKindOfClass:[PLVChatUser class]]) {
        [self.userArray addObject:user];
        self.userCount++;
    }
    dispatch_semaphore_signal(_userArrayLock);
    
    // 往数组加用户数据之后均要重新排序
    [self sortUsers];
    [self refreshUserListWithLinkMicOnlineUserArray:self.currentOnlineUserArray];
}

- (void)removeUserWithUserId:(NSString *)userId {
    PLVChatUser *user = [self searchUserInUserArrayWithUserId:userId];
    if (!user) {
        return;
    }
    dispatch_semaphore_wait(_userArrayLock, DISPATCH_TIME_FOREVER);
    [self.userArray removeObject:user];
    self.userCount--;
    dispatch_semaphore_signal(_userArrayLock);
}

/// socket 接收到用户修改昵称的消息时
- (void)setNickNameWithUserId:(NSString *)userId nickName:(NSString *)nickName {
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:nickName]) {
        return;
    }
    PLVChatUser *user = [self searchUserInUserArrayWithUserId:userId];
    if (!user) {
        return;
    }
    user.userName = nickName;
}

- (PLVChatUser *)searchUserInUserArrayWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    dispatch_semaphore_wait(_userArrayLock, DISPATCH_TIME_FOREVER);
    PLVChatUser *searchedUser = nil;
    for (PLVChatUser *user in self.userArray) {
        if ([user.userId isEqualToString:userId]) {
            searchedUser = user;
            break;
        }
    }
    dispatch_semaphore_signal(_userArrayLock);
    return searchedUser;
}

/// 对数组 userArray 进行排序
- (void)sortUsers {
    dispatch_semaphore_wait(_userArrayLock, DISPATCH_TIME_FOREVER);
    __weak typeof(self) weakSelf = self;
    NSArray *sortedArray = [self.userArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PLVChatUser *user1 = (PLVChatUser *)obj1;
        PLVChatUser *user2 = (PLVChatUser *)obj2;
        PLVMemberOrderIndex orderIndex1 = [weakSelf memberOrderIndexWithUserType:user1];
        PLVMemberOrderIndex orderIndex2 = [weakSelf memberOrderIndexWithUserType:user2];
        if (orderIndex1 < orderIndex2) {
            return NSOrderedAscending;
        }
        if (orderIndex1 > orderIndex2) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    [self.userArray removeAllObjects];
    self.userArray = [NSMutableArray arrayWithArray:sortedArray];
    dispatch_semaphore_signal(_userArrayLock);
}

#pragma mark 踢出用户

- (void)loadKickedUserListAutoly:(BOOL)autoly {
    if (!self.monitorKickUser) {
        return;
    }
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestChatRoomListKickedWithRoomId:roomData.channelId success:^(NSArray * _Nonnull responseArray) {
        weakSelf.kickedCount = [responseArray count];
        if (weakSelf.kickedCount > 0) {
            NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:weakSelf.kickedCount];
            for (NSDictionary *userDict in responseArray) {
                PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
                [muArray addObject:user];
            }
            [weakSelf updateKickUserArray:[muArray copy]];
        } else {
            [self removeAllKickUser];
        }
        
        // 数据变更通知
        [weakSelf notifyKickedUserArrayChanged];
        
        if (autoly) {
            [weakSelf loadKickedUserListLater];
        }
    } failure:^(NSError * _Nonnull error) {
        if (autoly) {
            [weakSelf loadKickedUserListLater];
        }
    }];
}

- (void)loadKickedUserListLater {
    if (!self.autoly ||
        !self.monitorKickUser) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kLoadKickedUserListInterval * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        [self loadKickedUserListAutoly:YES];
    });
}

- (void)updateKickUserArray:(NSArray <PLVChatUser *> *)userArray {
    if (!self.monitorKickUser) {
        return;
    }
    dispatch_semaphore_wait(_kickedUserArrayLock, DISPATCH_TIME_FOREVER);
    [self.kickedUserArray removeAllObjects];
    if ([userArray count] > 0) {
        [self.kickedUserArray addObjectsFromArray:userArray];
    }
    dispatch_semaphore_signal(_kickedUserArrayLock);
}

- (void)removeAllKickUser {
    dispatch_semaphore_wait(_kickedUserArrayLock, DISPATCH_TIME_FOREVER);
    [self.kickedUserArray removeAllObjects];
    dispatch_semaphore_signal(_kickedUserArrayLock);
}

- (void)addKickUser:(PLVChatUser *)user {
    if (!user ||
        !self.monitorKickUser) {
        return;
    }
    dispatch_semaphore_wait(_kickedUserArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *currentKickedUserArray = [self.kickedUserArray copy];
    BOOL exist = NO;
    for (PLVChatUser *aUser in currentKickedUserArray) {
        if ([aUser.userId isEqualToString:user.userId]) {
            exist = YES;
            break;
        }
    }
    if (!exist) {
        [self.kickedUserArray addObject:user];
        self.kickedCount++;
    }
    dispatch_semaphore_signal(_kickedUserArrayLock);
}

- (void)removeKickUser:(PLVChatUser *)user {
    if (!user ||
        !self.monitorKickUser) {
        return;
    }
    dispatch_semaphore_wait(_kickedUserArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *currentKickedUserArray = [self.kickedUserArray copy];
    for (PLVChatUser *aUser in currentKickedUserArray) {
        if ([aUser.userId isEqualToString:user.userId]) {
            [self.kickedUserArray removeObject:aUser];
            self.kickedCount--;
            break;
        }
    }
    dispatch_semaphore_signal(_kickedUserArrayLock);
}

#pragma mark 触发回调

- (void)notifyUserArrayChanged {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(userListChangedInMemberPresenter:)]) {
        [self.delegate userListChangedInMemberPresenter:self];
    }
}

- (void)notifyKickedUserArrayChanged {
    if (!self.monitorKickUser) {
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(kickedUserListChangedInMemberPresenter:)]) {
        [self.delegate kickedUserListChangedInMemberPresenter:self];
    }
}

#pragma mark socket 事件处理

/// 有用户登陆
- (void)loginEvent:(NSDictionary *)data {
    NSDictionary *userDict = data[@"user"];
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    [self addUser:user];
    // 数据变更通知
    [self notifyUserArrayChanged];
}

/// 有用户登出
- (void)logoutEvent:(NSDictionary *)data {
    NSString *userId = data[@"userId"];
    [self removeUserWithUserId:userId];
    
    // 数据变更通知
    [self notifyUserArrayChanged];
}

/// 有用户被踢出
- (void)kickEvent:(NSDictionary *)data {
    NSString *userId = data[@"user"][@"userId"];
    [self kickUserWithUserId:userId];
}

/// 有用户被禁言/取消禁言
- (void)shieldEvent:(NSDictionary *)data banned:(BOOL)banned {
    NSString *userId = data[@"data"][@"userId"];
    [self banUserWithUserId:userId banned:banned];
}

/// 有用户修改昵称
- (void)setNickEvent:(NSDictionary *)data {
    NSString *status = data[@"status"];
    if ([status isEqualToString:@"success"]) {
        NSString *userId = data[@"userId"];
        NSString *userName = data[@"nick"];
        [self setNickNameWithUserId:userId nickName:userName];
    }
    
    // 数据变更通知
    [self notifyUserArrayChanged];
}

#pragma mark Utils

/// 根据用户模型获取对应用户列表排序枚举值
- (PLVMemberOrderIndex)memberOrderIndexWithUserType:(PLVChatUser *)user {
    PLVMemberOrderIndex orderIndex = PLVMemberOrderIndex_Unknown;
    switch (user.userType) {
        case PLVRoomUserTypeSCStudent:
            orderIndex = PLVMemberOrderIndex_SCStudent;
            break;
        case PLVRoomUserTypeStudent:
            orderIndex = PLVMemberOrderIndex_Student;
            break;
        case PLVRoomUserTypeSlice:
            orderIndex = PLVMemberOrderIndex_Slice;
            break;
        case PLVRoomUserTypeViewer:
            orderIndex = PLVMemberOrderIndex_Viewer;
            break;
        case PLVRoomUserTypeGuest:
            orderIndex = PLVMemberOrderIndex_Guests;
            break;
        case PLVRoomUserTypeTeacher:
            orderIndex = PLVMemberOrderIndex_Teacher;
            break;
        case PLVRoomUserTypeAssistant:
            orderIndex = PLVMemberOrderIndex_Assistant;
            break;
        case PLVRoomUserTypeManager:
            orderIndex = PLVMemberOrderIndex_Manager;
            break;
        case PLVRoomUserTypeDummy:
            orderIndex = PLVMemberOrderIndex_Dummy;
            break;
        default:
            orderIndex = PLVMemberOrderIndex_Unknown;
            break;
    }
    //处理学生的连麦状态
    if (orderIndex == PLVMemberOrderIndex_SCStudent ||
        orderIndex == PLVMemberOrderIndex_Student ||
        orderIndex == PLVMemberOrderIndex_Slice) {
        //设置等待连麦(举手)状态
        if (user.waitUser) {
            orderIndex = PLVMemberOrderIndex_WaitingLink;
        }
        //设置正在连麦状态
        if (user.onlineUser) {
            orderIndex = PLVMemberOrderIndex_ConnectedLink;
        }
    }
    
    BOOL isCurrentUser = [self isLoginUser:user.userId];
    if (isCurrentUser) {
        orderIndex = user.specialIdentity ? PLVMemberOrderIndex_SpecialLoginUser : (orderIndex - 1);
    }
    return orderIndex;
}

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
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
    if ([subEvent isEqualToString:@"LOGIN"]) {
        [self loginEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"LOGOUT"]) {
        [self logoutEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"KICK"]) {
        [self kickEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"ADD_SHIELD"]) {
        [self shieldEvent:jsonDict banned:YES];
    } else if ([subEvent isEqualToString:@"REMOVE_SHIELD"]) {
        [self shieldEvent:jsonDict banned:NO];
    } else if ([subEvent isEqualToString:@"SET_NICK"]) {
        [self setNickEvent:jsonDict];
    }
}

@end
