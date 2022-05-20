//
//  PLVECChatroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/26.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import "PLVGiveRewardPresenter.h"

@interface PLVECChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

#pragma mark 登录用户上报

/// 上报登陆用户计时器，间隔2秒触发一次
@property (nonatomic, strong) NSTimer *loginTimer;
/// 暂未上报的登陆用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *loginUserArray;
/// 当前时间段内是否发生当前用户的登录事件
@property (nonatomic, assign) BOOL isMyselfLogin;
/// 礼物打赏开关
@property (nonatomic, assign) BOOL enableReward;

#pragma mark 数据数组

/// 公聊全部消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArray;

@end

@implementation PLVECChatroomViewModel {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _chatArrayLock;
    dispatch_semaphore_t _loginArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - 生命周期

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVECChatroomViewModel *viewModel = nil;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }
    return self;
}

- (void)setup {
    // 初始化信号量
    _chatArrayLock = dispatch_semaphore_create(1);
    _loginArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.chatArray = [[NSMutableArray alloc] initWithCapacity:500];
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:10 childRoomAllow:YES];
    self.presenter.delegate = self;
    [self.presenter login];
    
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    // 初始化登录事件计时器，登录用户数组
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                       target:self
                                                     selector:@selector(loginTimerAction)
                                                     userInfo:nil
                                                      repeats:YES];
    self.loginUserArray = [[NSMutableArray alloc] initWithCapacity:10];
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    [self.presenter destroy];
    self.presenter = nil;
    
    self.delegate = nil;
    [self.loginTimer invalidate];
    self.loginTimer = nil;
    [self removeAllPublicChatModels];
}

#pragma mark - 加载消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

- (void)loadImageEmotions {
    [self.presenter loadImageEmotions];
}

#pragma mark - 发送消息

- (BOOL)sendSpeakMessage:(NSString *)content {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
    }
    return sendSuccess;
}

- (BOOL)sendGiftMessageWithData:(NSDictionary *)data tip:(NSString *)tip {
    PLVChatModel *chatModel = [self sendCustomMessageWithEvent:@"GiftMessage" data:data tip:tip emitMode:1];
    if (chatModel) {
        [self addPublicChatModel:chatModel];
    }
    return chatModel;
}

- (PLVChatModel * _Nullable)sendCustomMessageWithEvent:(NSString *)event
                              data:(NSDictionary *)data
                               tip:(NSString * _Nullable)tip
                          emitMode:(int)emitMode {
    return [self.presenter sendCustomMessageWithEvent:event data:data tip:tip emitMode:emitMode];
}

- (void)sendLike {
    [self.presenter sendLike];
}

#pragma mark - 消息数组

/// 本地发送公聊消息时
- (void)addPublicChatModel:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatArray addObject:model];
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidSendMessage];
}

/// 接收到socket的公聊消息时
- (void)addPublicChatModels:(NSArray <PLVChatModel *> *)modelArray {
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.chatArray addObject:model];
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidReceiveMessages];
}

/// 接收到socket删除公聊消息的通知时
- (void)deletePublicChatModelWithMsgId:(NSString *)msgId {
    if (!msgId || ![msgId isKindOfClass:[NSString class]] || msgId.length == 0) {
        return;
    }
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *model in tempChatArray) {
        NSString *modelMsgId = [model msgId];
        if (modelMsgId && [modelMsgId isEqualToString:msgId]) {
            [self.chatArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}

/// 接收到socket删除所有公聊消息的通知时、调用销毁接口时
- (void)removeAllPublicChatModels {
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatArray removeAllObjects];
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}

/// 历史聊天记录接口返回消息数组时
- (void)insertChatModels:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.chatArray insertObject:model atIndex:0];
        }
    }
    BOOL first = ([self.chatArray count] <= [modelArray count]);
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerLoadHistorySuccess:noMore firstTime:first];
}

#pragma mark - Listener

- (void)notifyListenerDidSendMessage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_didSendMessage)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomManager_didSendMessage];
        });
    }
}

- (void)notifyListenerDidReceiveMessages {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_didReceiveMessages)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomManager_didReceiveMessages];
        });
    }
}

- (void)notifyListenerDidMessageDeleted {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_didMessageDeleted)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomManager_didMessageDeleted];
        });
    }
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_loadHistorySuccess:firstTime:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomManager_loadHistorySuccess:noMore firstTime:first];
        });
    }
}

- (void)notifyListenerLoadHistoryFailure {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_loadHistoryFailure)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomManager_loadHistoryFailure];
        });
    }
}

- (void)notifyListenerRewardSuccess:(NSDictionary *)modelDict {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_rewardSuccess:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomManager_rewardSuccess:modelDict];
        });
    }
}

#pragma mark - 加载打赏开关
- (void)loadRewardEnable {
    __weak typeof(self) weakSelf = self;
    [PLVGiveRewardPresenter requestRewardSettingCompletion:^(BOOL rewardEnable,NSString *payWay, NSArray *modelArray, NSString *pointUnit) {
        weakSelf.enableReward = rewardEnable;
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_loadRewardEnable:payWay:rewardModelArray:pointUnit:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate chatroomManager_loadRewardEnable:rewardEnable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
            });
        }
    } failure:^(NSString *error) {
        
    }];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomManager_loginUsers:)]) {
        if (self.isMyselfLogin) {
            self.isMyselfLogin = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate chatroomManager_loginUsers:nil];
            });
        } else {
            if ([self.loginUserArray count] >= 10) {
                NSArray *loginUserArray = [self.loginUserArray copy];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate chatroomManager_loginUsers:loginUserArray];
                });
                
                dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
                [self.loginUserArray removeAllObjects];
                dispatch_semaphore_signal(_loginArrayLock);
            } else if ([self.loginUserArray count] > 0) {
                PLVChatUser *user = self.loginUserArray[0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate chatroomManager_loginUsers:@[user]];
                });
                
                dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
                [self.loginUserArray removeObjectAtIndex:0];
                dispatch_semaphore_signal(_loginArrayLock);
            }
        }
    }
}
#pragma mark 生成 礼物 消息模型

- (PLVChatModel *)giftChatModeWithData:(NSDictionary *)data tip:(NSString *)tip user:(PLVChatUser *)user {
    if (![PLVFdUtil checkDictionaryUseable:data] ||
        ![PLVFdUtil checkStringUseable:tip] ||
        !user) {
        return nil;
    }
    
    PLVCustomMessage *customMessage = [[PLVCustomMessage alloc] init];
    customMessage.data = data;
    customMessage.tip = tip;
    
    PLVChatModel *chatModel = [[PLVChatModel alloc] init];
    chatModel.user = user;
    chatModel.message = customMessage;
    
    return chatModel;
}

#pragma mark 处理 礼物 消息

- (void)giftMessageEvent:(NSDictionary *)jsonDict {
    NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
    NSDictionary *user = PLV_SafeDictionaryForDictKey(jsonDict, @"user");
    if (![PLVFdUtil checkDictionaryUseable:user] ||
        [[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId  isEqualToString:PLV_SafeStringForDictKey(user, @"userId")]) { // 自己的消息无需重复处理
        return;
    }
    
    NSString *tip = PLV_SafeStringForDictKey(jsonDict, @"tip");
    PLVChatUser *userModel = [[PLVChatUser alloc] initWithUserInfo:user];
    PLVChatModel *chatModel = [self giftChatModeWithData:data tip:tip user:userModel];
    
    [self addPublicChatModel:chatModel];
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([event isEqualToString:@"customMessage"] &&
        [subEvent isEqualToString:@"GiftMessage"]) { // 礼物消息
        [self giftMessageEvent:jsonDict];
    }
}

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
        [self notifyListenerRewardSuccess:contentDict];
    }
}

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
    [self loadRewardEnable];
}

#pragma mark - PLVChatroomPresenterProtocol

- (void)chatroomPresenter_loadHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    [self insertChatModels:modelArray noMore:noMore];
}

- (void)chatroomPresenter_loadHistoryFailure {
    [self notifyListenerLoadHistoryFailure];
}

- (void)chatroomPresenter_didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray {
    [self addPublicChatModels:modelArray];
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
