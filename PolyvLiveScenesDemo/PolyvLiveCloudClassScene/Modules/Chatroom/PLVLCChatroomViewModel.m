//
//  PLVLCChatroomViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/26.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import <PolyvFoundationSDK/PLVMulticastDelegate.h>

@interface PLVLCChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

#pragma mark 登录用户上报

/// 上报登陆用户计时器，间隔4秒触发一次
@property (nonatomic, strong) NSTimer *loginTimer;
/// 暂未上报的登陆用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *loginUserArray;
/// 当前时间段内是否发生当前用户的登录事件
@property (nonatomic, assign) BOOL isMyselfLogin;

#pragma mark 管理员文本消息上报

/// 上报管理员发布消息文本，间隔8秒触发一次
@property (nonatomic, strong) NSTimer *managerMessageTimer;
/// 暂未上报的管理员消息文本数组
@property (nonatomic, strong) NSMutableArray <NSString *> *managerMessageArray;

#pragma mark 弹幕上报

/// 上报需插入弹幕的文本，间隔1秒触发一次
@property (nonatomic, strong) NSTimer *danmuTimer;
/// 暂未上报的弹幕文本数组
@property (nonatomic, strong) NSMutableArray <NSString *> *danmuArray;

#pragma mark 数据数组

/// 公聊全部消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *publicChatArray;
/// 公聊【只看教师与我】消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *partOfPublicChatArray;
/// 私聊消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *privateChatArray;

@end

@implementation PLVLCChatroomViewModel {
    // 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _publicChatArrayLock;
    dispatch_semaphore_t _privateChatArrayLock;
    dispatch_semaphore_t _loginArrayLock;
    dispatch_semaphore_t _managerMessageArrayLock;
    dispatch_semaphore_t _danmuArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;

    // 多代理
    dispatch_queue_t multicastQueue;
    PLVMulticastDelegate<PLVLCChatroomViewModelProtocol> *multicastDelegate;
}

#pragma mark - 生命周期

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVLCChatroomViewModel *viewModel = nil;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        // 多代理
        multicastQueue = dispatch_queue_create("com.PolyvLiveScenesDemo.PLVLCChatroomViewModel", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVLCChatroomViewModelProtocol> *)[[PLVMulticastDelegate alloc] init];
    }
    return self;
}

- (void)setup {
    // 初始化信号量
    _publicChatArrayLock = dispatch_semaphore_create(1);
    _privateChatArrayLock = dispatch_semaphore_create(1);
    _loginArrayLock = dispatch_semaphore_create(1);
    _managerMessageArrayLock = dispatch_semaphore_create(1);
    _danmuArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.publicChatArray = [NSMutableArray arrayWithCapacity:500];
    self.partOfPublicChatArray = [NSMutableArray arrayWithCapacity:100];
    self.privateChatArray = [NSMutableArray arrayWithCapacity:20];
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:20 childRoomAllow:NO];
    self.presenter.delegate = self;
    
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    // 初始化登录事件计时器，登录用户数组
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                       target:self
                                                     selector:@selector(loginTimerAction)
                                                     userInfo:nil
                                                      repeats:YES];
    self.loginUserArray = [[NSMutableArray alloc] initWithCapacity:10];
    
    // 初始化管理员文本消息上报计时器，管理员文本消息数组
    self.managerMessageTimer = [NSTimer scheduledTimerWithTimeInterval:8
                                                       target:self
                                                     selector:@selector(managerMessageTimerAction)
                                                     userInfo:nil
                                                      repeats:YES];
    self.managerMessageArray = [[NSMutableArray alloc] initWithCapacity:10];
    
    // 初始化弹幕上报计时器，弹幕文本数组
    self.danmuTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                       target:self
                                                     selector:@selector(danmuTimerAction)
                                                     userInfo:nil
                                                      repeats:YES];
    self.danmuArray = [[NSMutableArray alloc] initWithCapacity:10];
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    [self.presenter destroy];
    self.presenter = nil;
    [self removeAllDelegates];
    
    [self.loginTimer invalidate];
    self.loginTimer = nil;
    [self removeAllLoginUsers];
    
    [self.managerMessageTimer invalidate];
    self.managerMessageTimer = nil;
    [self removeAllManagerMessages];
    
    [self.danmuTimer invalidate];
    self.danmuTimer = nil;
    [self removeAllDanmus];
    
    [self removeAllPrivateChatModels];
    [self removeAllPublicChatModels];
    
    self.onlyTeacher = NO;
}

#pragma mark - 加载消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

#pragma mark - 发送消息

- (BOOL)sendQuesstionMessage:(NSString *)content {
    PLVChatModel *model = [self.presenter sendQuesstionMessage:content];
    if (model) {
        [self addPrivateChatModel:model local:YES];
    }
    return model != nil;
}

- (BOOL)sendSpeakMessage:(NSString *)content {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content];
    if (model) {
        [self addPublicChatModel:model];
        [self cacheDanmu:@[model]];
    }
    return model != nil;
}

- (BOOL)sendImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    if (model) {
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (void)sendLike {
    [self.presenter sendLike];
}

- (void)createAnswerChatModel {
    [self.presenter createAnswerChatModel];
}

#pragma mark - 消息数组

#pragma mark 私聊

/// 私聊消息有更新时，local为YES表示是本地发送的消息，NO表示是socket接收到的消息
- (void)addPrivateChatModel:(PLVChatModel *)model local:(BOOL)local {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    
    dispatch_semaphore_wait(_privateChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.privateChatArray addObject:model];
    dispatch_semaphore_signal(_privateChatArrayLock);
    
    if (local) {
        [self notifyDelegatesDidSendQuestionMessage];
    } else {
        [self notifyDelegatesDidReceiveAnswerMessage];
    }
}

/// 调用销毁接口时
- (void)removeAllPrivateChatModels {
    dispatch_semaphore_wait(_privateChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.privateChatArray removeAllObjects];
    dispatch_semaphore_signal(_privateChatArrayLock);
}

#pragma mark 公聊

- (NSMutableArray <PLVChatModel *> *)chatArray {
    if (self.onlyTeacher) {
        return self.partOfPublicChatArray;
    } else {
        return self.publicChatArray;
    }
}

/// 本地发送公聊消息时
- (void)addPublicChatModel:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.publicChatArray addObject:model];
    [self.partOfPublicChatArray addObject:model];
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidSendMessage:model];
}

/// 接收到socket的公聊消息时
- (void)addPublicChatModels:(NSArray <PLVChatModel *> *)modelArray {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.publicChatArray addObject:model];
            if (model.user.specialIdentity) {
                [self.partOfPublicChatArray addObject:model];
            }
        }
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidReceiveMessages:modelArray];
}

/// 接收到socket删除公聊消息的通知时
- (void)deletePublicChatModelWithMsgId:(NSString *)msgId {
    if (!msgId || ![msgId isKindOfClass:[NSString class]] || msgId.length == 0) {
        return;
    }
    
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempPublicChatArray = [self.publicChatArray copy];
    for (PLVChatModel *model in tempPublicChatArray) {
        NSString *modelMsgId = [model msgId];
        if (modelMsgId && [modelMsgId isEqualToString:msgId]) {
            [self.publicChatArray removeObject:model];
            [self.partOfPublicChatArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidMessageDeleted];
}

/// 接收到socket删除所有公聊消息的通知时、调用销毁接口时
- (void)removeAllPublicChatModels {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.publicChatArray removeAllObjects];
    [self.partOfPublicChatArray removeAllObjects];
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidMessageDeleted];
}

/// 历史聊天记录接口返回消息数组时
- (void)insertChatModels:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.publicChatArray insertObject:model atIndex:0];
            PLVChatUser *user = model.user;
            if (user.specialIdentity || [self isLoginUser:user.userId]) {
                [self.partOfPublicChatArray insertObject:model atIndex:0];
            }
        }
    }
    BOOL first = ([self.publicChatArray count] <= [modelArray count]);
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesLoadHistorySuccess:noMore firstTime:first];
}

#pragma mark - Multicase

- (void)addDelegate:(id<PLVLCChatroomViewModelProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    });
}

- (void)removeDelegate:(id<PLVLCChatroomViewModelProtocol>)delegate {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeDelegate:delegate];
    });
}

- (void)removeAllDelegates {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeAllDelegates];
    });
}

- (void)notifyDelegatesDidSendQuestionMessage {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didSendQuestionMessage];
    });
}

- (void)notifyDelegatesDidReceiveAnswerMessage {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didReceiveAnswerMessage];
    });
}

- (void)notifyDelegatesDidSendMessage:(PLVChatModel *)model {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didSendMessage:model];
    });
}

- (void)notifyDelegatesDidReceiveMessages:(NSArray <PLVChatModel *> *)modelArray {
    if (!modelArray || ![modelArray isKindOfClass:[NSArray class]] || [modelArray count] == 0) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didReceiveMessages:modelArray];
    });
}

- (void)notifyDelegatesDidMessageDeleted {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didMessageDeleted];
    });
}

- (void)notifyDelegatesLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadHistorySuccess:noMore firstTime:first];
    });
}

- (void)notifyDelegatesLoadHistoryFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadHistoryFailure];
    });
}

- (void)notifyDelegatesForLoginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loginUsers:userArray];
    });
}

- (void)notifyDelegatesForManagerMessage:(NSString *)content {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_managerMessage:content];
    });
}

- (void)notifyDelegatesForDanmu:(NSString *)content {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_danmu:content];
    });
}

#pragma mark - 定时上报登录用户

/// 有用户登陆
- (void)loginEvent:(NSDictionary *)data {
    if (!self.loginTimer || !self.loginTimer.valid) {// 如果没有上报任务则无需统计登录数据
        return;
    }
    
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(data, @"user");
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    BOOL isLoginUser = [self isLoginUser:user.userId];
    if (isLoginUser) {
        self.isMyselfLogin = YES;
    } else {
        dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
        [self.loginUserArray addObject:user];
        dispatch_semaphore_signal(_loginArrayLock);
    }
}

- (void)loginTimerAction {
    if (self.isMyselfLogin) {
        self.isMyselfLogin = NO;
        [self notifyDelegatesForLoginUsers:nil];
    } else {
        if ([self.loginUserArray count] >= 10) {
            NSArray *loginUserArray = [self.loginUserArray copy];
            [self notifyDelegatesForLoginUsers:loginUserArray];
            
            dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
            [self.loginUserArray removeAllObjects];
            dispatch_semaphore_signal(_loginArrayLock);
        } else if ([self.loginUserArray count] > 0) {
            PLVChatUser *user = self.loginUserArray[0];
            [self notifyDelegatesForLoginUsers:@[user]];
            
            dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
            [self.loginUserArray removeObjectAtIndex:0];
            dispatch_semaphore_signal(_loginArrayLock);
        }
    }
}

- (void)removeAllLoginUsers {
    dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
    [self.loginUserArray removeAllObjects];
    dispatch_semaphore_signal(_loginArrayLock);
}

#pragma mark - 定时上报管理员文本消息

- (void)cacheManagerMessages:(NSArray <PLVChatModel *> *)modelArray {
    if (!self.managerMessageTimer || !self.managerMessageTimer.valid) {// 如果没有上报任务则无需统计登录数据
        return;
    }
    
    for (PLVChatModel *model in modelArray) {
        NSString *content = [model content];
        if (model.user.userType == PLVRoomUserTypeManager &&
            content && [content isKindOfClass:[NSString class]] && content.length > 0) {
            
            dispatch_semaphore_wait(_managerMessageArrayLock, DISPATCH_TIME_FOREVER);
            [self.managerMessageArray addObject:content];
            dispatch_semaphore_signal(_managerMessageArrayLock);
        }
    }
}

- (void)managerMessageTimerAction {
    if ([self.managerMessageArray count] > 0) {
        NSString *content = self.managerMessageArray[0];
        [self notifyDelegatesForManagerMessage:content];
        
        dispatch_semaphore_wait(_managerMessageArrayLock, DISPATCH_TIME_FOREVER);
        [self.managerMessageArray removeObjectAtIndex:0];
        dispatch_semaphore_signal(_managerMessageArrayLock);
    }
}

- (void)removeAllManagerMessages {
    dispatch_semaphore_wait(_managerMessageArrayLock, DISPATCH_TIME_FOREVER);
    [self.managerMessageArray removeAllObjects];
    dispatch_semaphore_signal(_managerMessageArrayLock);
}

#pragma mark - 定时上报弹幕文本

- (void)cacheDanmu:(NSArray <PLVChatModel *> *)modelArray {
    if (!self.danmuTimer || !self.danmuTimer.valid) {// 如果没有上报任务则无需统计登录数据
        return;
    }
    
    for (PLVChatModel *model in modelArray) {
        NSString *content = [model content];
        if (content && [content isKindOfClass:[NSString class]] && content.length > 0) {
            
            dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
            [self.danmuArray addObject:content];
            dispatch_semaphore_signal(_danmuArrayLock);
        }
    }
}

- (void)danmuTimerAction {
    if ([self.danmuArray count] > 0) {
        NSString *content = self.danmuArray[0];
        [self notifyDelegatesForDanmu:content];
        
        dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
        [self.danmuArray removeObjectAtIndex:0];
        dispatch_semaphore_signal(_danmuArrayLock);
    }
}

- (void)removeAllDanmus {
    dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
    [self.danmuArray removeAllObjects];
    dispatch_semaphore_signal(_danmuArrayLock);
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([subEvent isEqualToString:@"LOGIN"]) {   // someone logged in chatroom
        [self loginEvent:jsonDict];
    }
}

#pragma mark - PLVChatroomPresenterProtocol

- (void)chatroomPresenter_loadHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    [self insertChatModels:modelArray noMore:noMore];
}

- (void)chatroomPresenter_loadHistoryFailure {
    [self notifyDelegatesLoadHistoryFailure];
}

- (void)chatroomPresenter_didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray {
    [self addPublicChatModels:modelArray];
    [self cacheManagerMessages:modelArray];
    [self cacheDanmu:modelArray];
}

- (void)chatroomPresenter_didReceiveAnswerChatModel:(PLVChatModel *)model {
    [self addPrivateChatModel:model local:NO];
}

- (void)chatroomPresenter_didMessageDeleted:(NSString *)msgId {
    [self deletePublicChatModelWithMsgId:msgId];
}

- (void)chatroomPresenter_didAllMessageDeleted {
    [self removeAllPublicChatModels];
}

#pragma mark - Utils

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

@end
