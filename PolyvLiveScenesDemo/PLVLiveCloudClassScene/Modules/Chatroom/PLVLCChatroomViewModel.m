//
//  PLVLCChatroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/26.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVGiveRewardPresenter.h"

@interface PLVLCChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

#pragma mark 倒计时红包

/// 当前倒计时红包类型
@property (nonatomic, assign) PLVRedpackMessageType currentRedpackType;
/// 红包倒计时
@property (nonatomic, strong) NSTimer *redpackTimer;
/// 倒计时时间，单位秒
@property (nonatomic, assign) NSInteger delayTime;

#pragma mark 登录用户上报

/// 上报登陆用户计时器，间隔4秒触发一次
@property (nonatomic, strong) NSTimer *loginTimer;
/// 暂未上报的登陆用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *loginUserArray;
/// 当前时间段内是否发生当前用户的登录事件
@property (nonatomic, assign) BOOL isMyselfLogin;

#pragma mark 礼物打赏
/// 礼物打赏开关
@property (nonatomic, assign) BOOL enableReward;

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

/// 是否为专注模式
@property (nonatomic, assign) BOOL focusMode;
/// 公聊全部消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *publicChatArray;
/// 公聊【只看教师与我】消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *partOfPublicChatArray;
/// 公聊【只看教师】消息数组，用于响应专注模式
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *partOfSpecialIdentityPublicChatArray;
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
        multicastQueue = dispatch_queue_create("com.PLVLiveScenesDemo.PLVLCChatroomViewModel", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVLCChatroomViewModelProtocol> *)[[PLVMulticastDelegate alloc] init];
    }
    return self;
}

- (void)setup {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.menuInfo.transmitMode && roomData.menuInfo.mainRoom) {
        return;
    }
    
    // 初始化信号量
    _publicChatArrayLock = dispatch_semaphore_create(1);
    _privateChatArrayLock = dispatch_semaphore_create(1);
    _loginArrayLock = dispatch_semaphore_create(1);
    _managerMessageArrayLock = dispatch_semaphore_create(1);
    _danmuArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.publicChatArray = [NSMutableArray arrayWithCapacity:500];
    self.partOfPublicChatArray = [NSMutableArray arrayWithCapacity:100];
    self.partOfSpecialIdentityPublicChatArray = [NSMutableArray arrayWithCapacity:100];
    self.privateChatArray = [NSMutableArray arrayWithCapacity:20];
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:20];
    self.presenter.delegate = self;
    [self.presenter login];
    
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
    self.focusMode = NO;
    
    [self stopRedpackTimer];
}

#pragma mark - 加载打赏开关
- (void)loadRewardEnable {
    __weak typeof(self) weakSelf = self;
    [PLVGiveRewardPresenter requestRewardSettingCompletion:^(BOOL rewardEnable, NSString *payWay, NSArray *modelArray, NSString *pointUnit) {
        weakSelf.enableReward = rewardEnable;
        //暂时 关闭动态特效
        weakSelf.hideRewardDisplay = YES;
//        weakSelf.hideRewardDisplay = !rewardEnable;
        [weakSelf notifyDelegatesLoadRewardEnable:rewardEnable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
    } failure:^(NSString *error) {
        
    }];
}

#pragma mark - Getter

- (NSArray *)imageEmotionArray {
    return self.presenter.imageEmotionArray;
}

#pragma mark - 加载消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

#pragma mark - 加载图片表情数据

- (void)loadImageEmotions {
    [self.presenter loadImageEmotions];
}

#pragma mark - [ Public Medthods ]

- (BOOL)sendQuesstionMessage:(NSString *)content {
    PLVChatModel *model = [self.presenter sendQuesstionMessage:content];
    if (model) {
        [self addPrivateChatModel:model local:YES];
    }
    return model != nil;
}

- (BOOL)sendSpeakMessage:(NSString *)content {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
        [self cacheDanmu:@[model]];
    }
    return sendSuccess;
}

- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content replyChatModel:replyChatModel];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
        [self cacheDanmu:@[model]];
    }
    return sendSuccess;
}

- (BOOL)sendImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
    }
    return sendSuccess;
}

- (BOOL)sendImageEmotionId:(NSString *)imageId imageUrl:(NSString *)imageUrl   {
    PLVChatModel *model = [self.presenter sendImageEmotionId:imageId imageUrl:imageUrl];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
    }
    return sendSuccess;
}

- (void)sendLike {
    [self.presenter sendLike];
}

- (void)createAnswerChatModel {
    [self.presenter createAnswerChatModel];
}

- (void)checkRedpackStateWithChatModel:(PLVChatModel *)model {
    if (!model.message || ![model.message isKindOfClass:[PLVRedpackMessage class]]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    PLVRedpackMessage *message = (PLVRedpackMessage *)model.message;
    [self.presenter loadRedpackReceiveCacheWithRedpackId:message.redpackId
                                              redCacheId:message.redCacheId
                                              completion:^(PLVRedpackState redpackState) {
        message.state = redpackState;
        [weakSelf notifyDelegatesCheckRedpackStateResult:redpackState chatModel:model];
        [weakSelf notifyDelegatesRedpackStateChanged];
        [weakSelf.presenter recordRedpackReceiveWithID:message.redpackId time:message.time state:redpackState];
    } failure:^(NSError * _Nonnull error) {
        message.state = PLVRedpackStateUnknow;
        [weakSelf notifyDelegatesCheckRedpackStateResult:PLVRedpackStateUnknow chatModel:model];
    }];
}

- (PLVRedpackState)changeRedpackStateWithRedpackId:(NSString *)redpackId state:(NSString *)state {
    if (![PLVFdUtil checkStringUseable:redpackId] ||
        ![PLVFdUtil checkStringUseable:state]) {
        return PLVRedpackStateUnknow;
    }
    
    PLVRedpackState redpackState = PLVRedpackStateUnknow;
    if ([state isEqualToString:@"expired"]) {
        redpackState = PLVRedpackStateExpired;
    } else if ([state isEqualToString:@"none_redpack"]) {
        redpackState = PLVRedpackStateNoneRedpack;
    } else if ([state isEqualToString:@"received"]) {
        redpackState = PLVRedpackStateReceive;
    } else if ([state isEqualToString:@"noReceive"]) {
        redpackState = PLVRedpackStateSuccess;
    }
    
    if (redpackState == PLVRedpackStateExpired ||
        redpackState == PLVRedpackStateReceive ||
        redpackState == PLVRedpackStateNoneRedpack) {
        NSArray *modelArray = [self.publicChatArray copy];
        for (int i = 0; i < [modelArray count]; i++) {
            PLVChatModel *model = modelArray[i];
            if (!model.message ||
                ![model.message isKindOfClass:[PLVRedpackMessage class]]) {
                continue;
            }
            PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)model.message;
            if (redpackMessage.redpackId &&
                [redpackMessage.redpackId isEqualToString:redpackId] &&
                redpackMessage.state != redpackState) {
                redpackMessage.state = redpackState;
                [self notifyDelegatesRedpackStateChanged];
                [self.presenter recordRedpackReceiveWithID:redpackMessage.redpackId time:redpackMessage.time state:redpackState];
                break;
            }
        }
    }
    
    return redpackState;
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
    if (!_privateChatArrayLock) {
        return;
    }
    dispatch_semaphore_wait(_privateChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.privateChatArray removeAllObjects];
    dispatch_semaphore_signal(_privateChatArrayLock);
}

#pragma mark 公聊

- (NSMutableArray <PLVChatModel *> *)chatArray {
    if (self.onlyTeacher) {
        if (self.focusMode) {
            return self.partOfSpecialIdentityPublicChatArray;
        } else {
            return self.partOfPublicChatArray;
        }
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
                [self.partOfSpecialIdentityPublicChatArray addObject:model];
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
            [self.partOfSpecialIdentityPublicChatArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidMessageDeleted];
}

/// 接收到socket删除所有公聊消息的通知时、调用销毁接口时
- (void)removeAllPublicChatModels {
    if (!_publicChatArrayLock) {
        return;
    }
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.publicChatArray removeAllObjects];
    [self.partOfPublicChatArray removeAllObjects];
    [self.partOfSpecialIdentityPublicChatArray removeAllObjects];
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
            if (user.specialIdentity) {
                [self.partOfPublicChatArray insertObject:model atIndex:0];
                [self.partOfSpecialIdentityPublicChatArray insertObject:model atIndex:0];
            } else if ([self isLoginUser:user.userId]) {
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
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
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

- (void)notifyDelegatesDidSendProhibitMessage {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didSendProhibitMessage];
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
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loginUsers:userArray];
    });
}

- (void)notifyDelegatesForManagerMessage:(NSString *)content {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_managerMessage:content];
    });
}

- (void)notifyDelegatesForDanmu:(NSString *)content {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_danmu:content];
    });
}

- (void)notifyDelegatesListenerRewardSuccess:(NSDictionary *)modelDict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_rewardSuccess:modelDict];
    });
}

- (void)notifyDelegatesLoadRewardEnable:(BOOL)enable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray * _Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadRewardEnable:enable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
    });
}

- (void)notifyDelegatesStartCardPush:(BOOL)start pushInfo:(NSDictionary *)pushDict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_startCardPush:start pushInfo:pushDict];
    });
}

- (void)notifyDelegatesShowDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_showDelayRedpackWithType:type delayTime:delayTime];
    });
}

- (void)notifyDelegatesHideDelayRedpack {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_hideDelayRedpack];
    });
}

- (void)notifyDelegatesLoadImageEmotionSuccess {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadImageEmotionSuccess:self.imageEmotionArray];
    });
}

- (void)notifyDelegatesLoadImageEmotionFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadImageEmotionFailure];
    });
}

- (void)notifyDelegatesDidLoginRestrict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didLoginRestrict];
    });
}

- (void)notifyDelegatesCloseRoom:(BOOL)closeRoom {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_closeRoom:closeRoom];
    });
}

- (void)notifyDelegatesFocusMode:(BOOL)focusMode {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_focusMode:focusMode];
    });
}

- (void)notifyDelegatesCheckRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_checkRedpackStateResult:state chatModel:model];
    });
}

- (void)notifyDelegatesRedpackStateChanged {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didRedpackStateChanged];
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
    if (!_loginArrayLock) {
        return;
    }
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
    if (!_managerMessageArrayLock) {
        return;
    }
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
    if (!_danmuArrayLock) {
        return;
    }
    dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
    [self.danmuArray removeAllObjects];
    dispatch_semaphore_signal(_danmuArrayLock);
}

#pragma mark 倒计时红包

- (void)startRedpackTimerWithRedpackType:(PLVRedpackMessageType)redpackType delayTime:(NSInteger)delayTime {
    if (_redpackTimer) {
        [self stopRedpackTimer];
    }
    
    self.currentRedpackType = redpackType;
    self.delayTime = delayTime;
    
    plv_dispatch_main_async_safe(^{
        self.redpackTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(redpackTimerAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.redpackTimer forMode:NSRunLoopCommonModes];
    })
}

- (void)stopRedpackTimer {
    [_redpackTimer invalidate];
    _redpackTimer = nil;
}

- (void)redpackTimerAction {
    if (--self.delayTime == 0) {
        self.currentRedpackType = PLVRedpackMessageTypeUnknown;
        [self stopRedpackTimer];
        [self notifyDelegatesHideDelayRedpack];
        return;
    }
    
    [self notifyDelegatesShowDelayRedpackWithType:self.currentRedpackType delayTime:self.delayTime];
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
    } else if ([subEvent isEqualToString:@"REWARD"]) {
        NSDictionary *contentDict = jsonDict[@"content"];
        [self notifyDelegatesListenerRewardSuccess:contentDict];
    }
}

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
    [self loadRewardEnable];
}

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = PLV_SafeDictionaryForValue(object);
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([event isEqualToString:PLVSocketCardPush_newsPush_key]) {
        NSString *newsPushEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
        if ([PLVFdUtil checkStringUseable:newsPushEvent]) {
            BOOL start = [newsPushEvent isEqualToString:@"start"];
            [self notifyDelegatesStartCardPush:start pushInfo:jsonDict];
        }
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
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }

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

- (void)chatroomPresenter_receiveWarning:(NSString *)warning prohibitWord:(NSString *)word {
    [self notifyDelegatesDidSendProhibitMessage];
}

- (void)chatroomPresenter_loadImageEmotionsSuccess {
    [self notifyDelegatesLoadImageEmotionSuccess];
}

- (void)chatroomPresenter_loadImageEmotionsFailure {
    [self notifyDelegatesLoadImageEmotionFailure];
}

- (void)chatroomPresenter_didLoginRestrict {
    [self notifyDelegatesDidLoginRestrict];
}

- (void)chatroomPresenter_didChangeCloseRoom:(BOOL)closeRoom {
    [self notifyDelegatesCloseRoom:closeRoom];
}

- (void)chatroomPresenter_didChangeFocusMode:(BOOL)focusMode {
    self.focusMode = focusMode;
    [self notifyDelegatesFocusMode:focusMode];
}

- (void)chatroomPresenter_didReceiveDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    [self startRedpackTimerWithRedpackType:type delayTime:delayTime];
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
