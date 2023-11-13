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
static NSInteger kMemberCountMax = 1000;
static NSInteger kLoadUserListInterval = 20;
static NSInteger kLoadKickedUserListInterval = 20;

@interface PLVMemberPresenter ()<
PLVSocketManagerProtocol // socket协议
>
/// 在线人数
@property (nonatomic, assign) NSInteger userCount;
/// 移出人数
@property (nonatomic, assign) NSInteger kickedCount;
/// 在线成员字典
@property (nonatomic, strong) NSMutableDictionary<NSString *, PLVChatUser *> *localUserMDic;
/// 在线用户数组（对外UI展示用）
@property (nonatomic, strong) NSArray <PLVChatUser *> *userArrayForUI;
/// 移出用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *kickedUserArray;
/// 是否自动间隔获取在线成员列表，默认为NO，调用start方法后为YES
@property (nonatomic, assign) BOOL autoly;
/// 只读，当前连麦在线用户数组
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> * currentOnlineUserArray;
/// 只读，等待连麦在线用户数组
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicWaitUser *> * currentWaitUserArray;

///  间隔刷新UI的定时器
@property (nonatomic, strong) NSTimer *timer;
///  是否需要刷新UI
@property (nonatomic, assign) BOOL needRefreshUI;

@end

@implementation PLVMemberPresenter {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _localUserMDicLock;
    
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

- (void)dealloc {
    [self.timer invalidate];
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
    return self.userArrayForUI;
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
    
    PLVChatUser *chatUser = self.localUserMDic[userId];
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
    self.needRefreshUI = YES;
}

#pragma mark 连麦业务相关
// 时间复杂度：O(N) ~
//     N 是 本地用户localUserMDic 的长度。  N 可以很大很大。
//     M 是 新用户 newLinkMicWaitUserArray 的长度。 连麦人数最多16人，也就是说，M 最大值是 16。也就是说，可以忽略不计；
- (void)refreshUserListWithLinkMicWaitUserArray:(NSArray <PLVLinkMicWaitUser *>*)newLinkMicWaitUserArray {
    if (!newLinkMicWaitUserArray || ![newLinkMicWaitUserArray isKindOfClass:[NSArray class]] || newLinkMicWaitUserArray.count==0) {
        return;
    }
    
    // 定义 originUsers 为 本地成员数组的一个copy，长度为 N；这里的 originUsers 不涉及数据的插入和删除，所以只需要 不可变的copy；
    dispatch_semaphore_wait(_localUserMDicLock, DISPATCH_TIME_FOREVER);
    NSArray<PLVChatUser *> *localUsersArrayCopy = self.localUserMDic.allValues;
    dispatch_semaphore_signal(_localUserMDicLock);
    
    // 定义 waitUserDic 为 等待连麦成员字典，key 是 等待连麦成员id，value 是 等待连麦成员对象；长度为 M；
    NSMutableDictionary<NSString *, PLVLinkMicWaitUser *> *waitUserDic = [[NSMutableDictionary alloc] init];
    for (PLVLinkMicWaitUser *waitUser in newLinkMicWaitUserArray) {
        [waitUserDic setValue:waitUser forKey:waitUser.userId];
    }
    
    // 对于 本地成员列表 中存在的 成员， 更新其 等待连麦状态
    for (PLVChatUser* localUser in localUsersArrayCopy) { // 遍历 本地成员列表拷贝（N）
        NSString *userId = localUser.userId;
        if (![PLVFdUtil checkStringUseable:userId]) {
            continue;
        }
        PLVLinkMicWaitUser *waitUser = waitUserDic[userId];// 尝试 使用userId 从 等待连麦成员字典 中获取 等待连麦成员对象
        if (waitUser) { // 如果 等待连麦成员对象 不为空，表示 当前本地成员 在 等待连麦列表字典 中
            localUser.waitUser = waitUser; // 更新 当前本地成员 的 等待连麦信息
            [waitUserDic removeObjectForKey:userId]; // 在 等待连麦列表字典 中删除 等待连麦成员对象
        } else { // 否则 等待连麦成员对象 为空，表示 当前本地成员 不在 等待连麦列表字典 中
            if (localUser.waitUser) { // 如果 当前本地成员 之前是 等待连麦状态
                localUser.waitUser = nil; // 清空 当前本地成员 的 等待连麦信息
            }
        }
        self.needRefreshUI = YES;
    }
    
    // 对于 本地成员列表 中不存在的 成员， 把 该等待连麦成员 添加到 本地成员列表
    if (waitUserDic.count > 0) { // 如果 等待连麦成员字典 不为空，表示 部分等待连麦成员 不在 本地成员列表 中，需要 插入到 本地成员列表
        for (NSString *waitUserId in waitUserDic) { // 遍历 等待连麦成员字典
            PLVLinkMicWaitUser *waitUser = waitUserDic[waitUserId];
            if (![PLVFdUtil checkDictionaryUseable:waitUser.originalUserDict]) {
                NSLog(@"PLVMemberPresenter - refreshUserListWithLinkMicWaitUserArray failed, waitUser.originalUserDict illegal %@",waitUser.userId);
                continue;
            }
            
            // 根据 等待连麦成员对象 创建 新增成员对象，并设置其 等待连麦状态
            PLVChatUser * chatUser = [[PLVChatUser alloc] initWithUserInfo:waitUser.originalUserDict];
            chatUser.onlineUser = nil;
            chatUser.waitUser = waitUser;
            
            // 把创建的 新增成员对象 插入到 新增成员列表 中
            [self addUser:chatUser andForce:YES];
        }
    }
}

// 时间复杂度：O(N) ~
//     N 是 本地用户localUserMDic 的长度。  N 可以很大很大。
//     M 是 新用户 linkMicOnlineUserArray 的长度。 连麦人数最多16人，也就是说，M 最大值是 16。也就是说，可以忽略不计；
- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicOnlineUserArray {
    if (!linkMicOnlineUserArray || ![linkMicOnlineUserArray isKindOfClass:[NSArray class]] || linkMicOnlineUserArray.count==0) {
        return;
    }
    
    // 定义 originUsers 为 本地成员列表 的一个copy，长度为 N； 这里的 originUsers 不涉及数据的插入和删除，所以只需要 不可变的copy；
    dispatch_semaphore_wait(_localUserMDicLock, DISPATCH_TIME_FOREVER);
    NSArray<PLVChatUser *> *localUsersArrayCopy = self.localUserMDic.allValues;
    dispatch_semaphore_signal(_localUserMDicLock);
    
    // 定义 onlieUserDic 为 已连麦成员字典 ，key 是 已连麦成员id，value 是 已连麦成员对象；长度为 M；
    NSMutableDictionary<NSString*, PLVLinkMicOnlineUser*> *onlineUserDic = [[NSMutableDictionary alloc] init];
    for (PLVLinkMicOnlineUser *onlineUser in linkMicOnlineUserArray) {
        [onlineUserDic setValue:onlineUser forKey:onlineUser.userId];
    }
    
    // 对于 本地成员列表 中存在的 成员， 更新其 已连麦状态
    for (PLVChatUser *localUser in localUsersArrayCopy) { // 遍历 本地成员列表拷贝（N）
        NSString *userId = localUser.userId;
        if (![PLVFdUtil checkStringUseable:userId]) {
            continue;
        }
        PLVLinkMicOnlineUser *onlineUser = onlineUserDic[userId]; // 尝试 使用userId 从 已连麦成员字典 中获取 已连麦成员对象
        if (onlineUser) { // 如果 已连麦成员对象 不为空，表示 当前本地成员 在 已连麦成员字典 中
            localUser.onlineUser = onlineUser; // 更新 当前本地成员 的 已连麦信息
            [onlineUserDic removeObjectForKey:userId]; // 在 已连麦成员字典 中删除 该已连麦成员对象
        } else { // 否则 已连麦成员对象 为空，表示 当前本地成员 不在 已连麦成员字典 中
            if (localUser.onlineUser) { // 如果 当前本地成员 之前是 已连麦状态
                localUser.onlineUser = nil; // 清空 当前本地成员 的 已连麦信息；
            }
        }
        self.needRefreshUI = YES;
    }
    
    // 对于 本地成员列表 中不存在的 成员， 把 该已连麦成员 添加到 本地成员列表
    if (onlineUserDic.count > 0) { // 如果 已连麦成员字典 不为空，表示 部分已连麦成员 不在 本地成员列表 中，需要 插入到 本地成员列表
        for (NSString *onlineUserId in onlineUserDic) { // 遍历 已连麦成员字典
            PLVLinkMicOnlineUser *onlineUser = onlineUserDic[onlineUserId];
            if (![PLVFdUtil checkDictionaryUseable:onlineUser.originalUserDict]) {
                NSLog(@"PLVMemberPresenter - refreshUserListWithLinkMicOnlineUserArray failed, onlineUser.originalUserDict illegal %@", onlineUser.userId);
                continue;
            }
            
            // 根据 已连麦成员对象 创建 新增成员对象，并设置其 已连麦状态
            PLVChatUser * chatUser = [[PLVChatUser alloc] initWithUserInfo:onlineUser.originalUserDict];
            chatUser.waitUser = nil;
            chatUser.onlineUser = onlineUser;
            
            // 把创建的 新本地成员对象 插入到 本地列表 中
            [self addUser:chatUser andForce:YES];
        }
    }
}

#pragma mark - [ Private Method ]

#pragma mark Initialize

- (void)setup {
    // 初始化信号量
    _localUserMDicLock = dispatch_semaphore_create(1);
    _kickedUserArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.localUserMDic = [[NSMutableDictionary alloc] initWithCapacity:kMemberCountPerLoading];
    self.userArrayForUI = [[NSArray alloc] init];
    self.kickedUserArray = [[NSMutableArray alloc] initWithCapacity:20];
    
    // 监听socket消息
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    // 间隔刷新UI的定时器
    self.needRefreshUI = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.5
                                                 target:self
                                               selector:@selector(refreshUITimerBlock:)
                                               userInfo:nil
                                                repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
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

- (NSArray<PLVLinkMicWaitUser *> *)currentWaitUserArray{
    NSArray * currentWaitUserList;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(currentWaitUserListInMemberPresenter:)]) {
        currentWaitUserList = [self.delegate currentWaitUserListInMemberPresenter:self];
    }
    return currentWaitUserList;
}

#pragma mark 在线用户

- (void)loadOnlineUserListAutoly:(BOOL)autoly {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVRoomUser *roomUser = roomData.roomUser;
    NSString *roomId = roomData.channelId;
    BOOL isSpecial = [PLVRoomUser isSpecialIdentityWithUserType:roomUser.viewerType];
    // 非观看侧（开播、互动学堂）场景下，streamer 均为 YES；观看侧场景下，只有特殊身份 streamer 为 YES，否则后端会有性能问题
    BOOL streamer = (roomData.rtmpUrl || roomData.inHiClassScene) || isSpecial;
    
    __weak typeof(self) weakSelf = self;
    NSString *sessionId = nil;
    if (roomData.inHiClassScene) {
        PLVHiClassManager *manager = [PLVHiClassManager sharedManager];
        sessionId = manager.lessonId;
        BOOL inGroup = manager.groupState == PLVHiClassGroupStateInGroup;
        if (inGroup) {
            roomId = manager.groupId;
        }
    }
    [PLVLiveVideoAPI requestChatRoomListUsersWithRoomId:roomId
                                                   page:0
                                                 length:kMemberCountPerLoading
                                              sessionId:sessionId
                                               streamer:streamer
                                                success:^(NSDictionary *data) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_global_queue(0, 0), ^{
            NSLog(@"loadOnlineUserListAutoly success");
            NSInteger count = [data[@"count"] integerValue];
            weakSelf.userCount = count;
            
            if (count > 0) {
                NSArray *userArray = data[@"userlist"];
                if ([userArray count] > 0) {
                    NSMutableDictionary<NSString *, PLVChatUser *> *tempDic = [[NSMutableDictionary alloc] initWithCapacity:[userArray count]];
                    for (NSDictionary *userDict in userArray) {
                        PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
                        tempDic[user.userId] = user;
                    }
                    [weakSelf updateUsers:tempDic];
                }
            } else {
                [self removeAllUser];
            }
            
            self.needRefreshUI = YES;
            
            if (autoly) {
                [weakSelf loadOnlineUserListLater];
            }
        });
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

- (void)updateUsers:(NSDictionary<NSString *, PLVChatUser *> *)newUserDic {
    [self replaceAllUsers:newUserDic];
    [self refreshUserListWithLinkMicOnlineUserArray:self.currentOnlineUserArray];
    self.needRefreshUI = YES;
}

#pragma mark 涉及数据容器直接写操作的大并发操作
// 时间复杂度：O(1)
// 增加了 force 参数。当用户数量超过 kMemberCountMax（1000）后，只有 force为YES 才会进行真正的插入，否则只是自增 userCount 数值
- (void)addUser:(PLVChatUser *)newUser andForce:(BOOL)force {
    if (!newUser || ![newUser isKindOfClass:[PLVChatUser class]] || ![PLVFdUtil checkStringUseable:newUser.userId]) {
        return ;
    }
    NSString *userId = newUser.userId;
    PLVChatUser *localUser = self.localUserMDic[userId];
    if (localUser) {
        // 从旧代码复制多来的逻辑，不确定为什么要对 waitUser 属性进行复制
        if (!localUser.waitUser && localUser.onlineUser) {
            localUser.waitUser = newUser.waitUser;
        }
        self.needRefreshUI = YES;
    } else {
        if (self.localUserMDic.count<kMemberCountMax || force) {
            dispatch_semaphore_wait(_localUserMDicLock, DISPATCH_TIME_FOREVER);
            self.localUserMDic[userId] = newUser;
            self.userCount++;
            self.needRefreshUI = YES;
            dispatch_semaphore_signal(_localUserMDicLock);
        } else {
            self.userCount++;
        }
    }
}

// 时间复杂度：O(N + M)
//     N 是 本地用户localUserMDic 的长度。  N 可以很大很大。
//     M是 新用户 newUserDic 的长度。 newUserDic 是 Http请求返回的 新用户，最大长度是 kMemberCountPerLoading（500）
- (void)replaceAllUsers:(NSDictionary<NSString *, PLVChatUser *> *)newUserDic {
    dispatch_semaphore_wait(_localUserMDicLock, DISPATCH_TIME_FOREVER);
    [self.localUserMDic removeAllObjects];
    [self.localUserMDic addEntriesFromDictionary:newUserDic];
    dispatch_semaphore_signal(_localUserMDicLock);
}

// 时间复杂度：O(N)
//     N 是 本地用户localUserMDic 的长度。  N 可以很大很大。
- (void)removeAllUser {
    dispatch_semaphore_wait(_localUserMDicLock, DISPATCH_TIME_FOREVER);
    [self.localUserMDic removeAllObjects];
    dispatch_semaphore_signal(_localUserMDicLock);
}

// 时间复杂度：O(1)
- (void)removeUserWithUserId:(NSString *)userId {
    PLVChatUser *user = self.localUserMDic[userId];
    if (!user) {
        return;
    }
    dispatch_semaphore_wait(_localUserMDicLock, DISPATCH_TIME_FOREVER);
    [self.localUserMDic removeObjectForKey:userId];
    self.userCount--;
    self.needRefreshUI = YES;
    dispatch_semaphore_signal(_localUserMDicLock);
}

/// socket 接收到用户修改昵称的消息时
// 时间复杂度：O(1)
- (void)setNickNameWithUserId:(NSString *)userId nickName:(NSString *)nickName {
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:nickName]) {
        return;
    }
    PLVChatUser *user = self.localUserMDic[userId];
    if (!user) {
        return;
    }
    user.userName = nickName;
    self.needRefreshUI = YES;
}

// 时间复杂度：O(1)
- (PLVChatUser *)searchUserInUserArrayWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    PLVChatUser *user = self.localUserMDic[userId];
    return user;
}

/// 对数组 userArray 进行排序
// 时间复杂度：O( N * log(N) )
//     N 是 本地用户localUserMDic 的长度。  N 可以很大很大。
- (void)sortUsers {
    dispatch_semaphore_wait(_localUserMDicLock, DISPATCH_TIME_FOREVER);
    NSArray<PLVChatUser *> *userArrayCopy = self.localUserMDic.allValues;
    dispatch_semaphore_signal(_localUserMDicLock);
    
    __weak typeof(self) weakSelf = self;
    self.userArrayForUI = [userArrayCopy sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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

#pragma mark UI刷新定时器回调
- (void)refreshUITimerBlock:(NSTimer *)timer {
    if (!self.needRefreshUI) {
        return ;
    }
    [self sortUsers];
    [self notifyUserArrayChanged];
    self.needRefreshUI = NO;
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

/// 有用户登录
- (void)loginEvent:(NSDictionary *)data {
    NSDictionary *userDict = data[@"user"];
    NSString *userSource = PLV_SafeStringForDictKey(userDict, @"userSource");
    if ([userSource isEqualToString:@"chatroom"]) {
        return; // 过滤"userSource":"chatroom"的用户
    }
    
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    [self addUser:user andForce:NO];
}

/// 有用户登出
- (void)logoutEvent:(NSDictionary *)data {
    NSString *userId = data[@"userId"];
    [self removeUserWithUserId:userId];
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
        self.needRefreshUI = YES;
    }
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
