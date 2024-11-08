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
#import "PLVECChatCell.h"
#import "PLVECQuoteChatCell.h"
#import "PLVECLongContentChatCell.h"

static NSInteger kPLVECMaxPublicChatMessageCount = 500;

@interface PLVECChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter
/// 是否第一次加载提问消息
@property (nonatomic, assign) BOOL firstTimeLoadPrivateChat;

#pragma mark 倒计时红包

/// 当前倒计时红包类型
@property (nonatomic, assign) PLVRedpackMessageType currentRedpackType;
/// 红包倒计时
@property (nonatomic, strong) NSTimer *redpackTimer;
/// 倒计时时间，单位秒
@property (nonatomic, assign) NSInteger delayTime;

#pragma mark 登录用户上报

/// 上报登录用户计时器，间隔2秒触发一次
@property (nonatomic, strong) NSTimer *loginTimer;
/// 暂未上报的登录用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *loginUserArray;
/// 当前时间段内是否发生当前用户的登录事件
@property (nonatomic, assign) BOOL isMyselfLogin;
/// 礼物打赏开关
@property (nonatomic, assign) BOOL enableReward;
/// 是否打开【只看讲师】开关
@property (nonatomic, assign) BOOL onlyTeacher;

#pragma mark 聊天数据管理

/// 公聊数据管理计时器，间隔30秒触发一次
@property (nonatomic, strong) NSTimer *publicChatManagerTimer;

#pragma mark 数据数组

/// 公聊全部消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *publicChatArray;
/// 公聊【只看教师】消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *partOfPublicChatArray;
/// 私聊消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *privateChatArray;

@end

@implementation PLVECChatroomViewModel {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _publicChatArrayLock;
    dispatch_semaphore_t _privateChatArrayLock;
    dispatch_semaphore_t _loginArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
    
    // 多代理
    dispatch_queue_t multicastQueue;
    PLVMulticastDelegate<PLVECChatroomViewModelProtocol> *multicastDelegate;
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
        // 多代理
        multicastQueue = dispatch_queue_create("com.PLVLiveScenesDemo.PLVECChatroomViewModel", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVECChatroomViewModelProtocol> *)[[PLVMulticastDelegate alloc] init];
    }
    return self;
}

- (void)setup {
    // 初始化信号量
    _publicChatArrayLock = dispatch_semaphore_create(1);
    _privateChatArrayLock = dispatch_semaphore_create(1);
    _loginArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.publicChatArray = [NSMutableArray arrayWithCapacity:500];
    self.partOfPublicChatArray = [NSMutableArray arrayWithCapacity:100];
    self.privateChatArray = [NSMutableArray arrayWithCapacity:100];

    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:10 childRoomAllow:YES];
    self.presenter.delegate = self;
    [self.presenter login];
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        [self.presenter startPageViewTimer];
    }
    
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    // 初始化登录事件计时器，登录用户数组
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                       target:self
                                                     selector:@selector(loginTimerAction)
                                                     userInfo:nil
                                                      repeats:YES];
    self.loginUserArray = [[NSMutableArray alloc] initWithCapacity:10];
    
    // 初始化公聊数据管理计时器
    self.publicChatManagerTimer = [NSTimer scheduledTimerWithTimeInterval:6
                                                                   target:self
                                                                 selector:@selector(publicChatManagerTimerAction)
                                                                 userInfo:nil
                                                                  repeats:YES];
    
    self.firstTimeLoadPrivateChat = YES;
    [self loadQuestionHistory];
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    [self.presenter destroy];
    self.presenter = nil;
    [self removeAllDelegates];

    [self.loginTimer invalidate];
    self.loginTimer = nil;
    [self removeAllPublicChatModels];
    
    self.onlyTeacher = NO;
    
    [self stopRedpackTimer];
    
    [self.publicChatManagerTimer invalidate];
    self.publicChatManagerTimer = nil;
}

#pragma mark - [ Public Methods ]

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
        [weakSelf notifyListenerCheckRedpackStateResult:redpackState chatModel:model];
        [weakSelf notifyListenerRedpackStateChanged];
        [weakSelf.presenter recordRedpackReceiveWithID:message.redpackId time:message.time state:redpackState];
    } failure:^(NSError * _Nonnull error) {
        message.state = PLVRedpackStateUnknow;
        [weakSelf notifyListenerCheckRedpackStateResult:PLVRedpackStateUnknow chatModel:model];
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
                [self notifyListenerRedpackStateChanged];
                [self.presenter recordRedpackReceiveWithID:redpackMessage.redpackId time:redpackMessage.time state:redpackState];
                break;
            }
        }
    }
    
    return redpackState;
}
#pragma mark - 加载消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

- (void)loadImageEmotions {
    [self.presenter loadImageEmotions];
}

- (void)loadQuestionHistory {
    [self.presenter loadQuestionHistory];
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
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
    }
    return sendSuccess;
}

- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content replyChatModel:replyChatModel];
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

- (void)createAnswerChatModel {
    [self.presenter createAnswerChatModel];
}

- (void)updateOnlineList {
    [self.presenter updateOnlineList];
}

- (void)welfareLotteryCommentSuccess:(NSString *)comment {
    PLVChatModel *model = [self.presenter createWelfareLotteryCommentChatModel:comment];
    if (model) {
        [self addPublicChatModel:model];
    }
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

/// 私聊历史聊天记录接口返回消息数组时
- (void)insertPrivateChatModels:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    if (![PLVFdUtil checkArrayUseable:modelArray]) {
        [self notifyDelegatesLoadQuestionHistorySuccess:noMore firstTime:self.firstTimeLoadPrivateChat];
        return;
    }
    
    dispatch_semaphore_wait(_privateChatArrayLock, DISPATCH_TIME_FOREVER);
    if (self.privateChatArray.count > 0) {
        PLVChatModel *firstChatModel = self.privateChatArray.firstObject;
        if (![PLVFdUtil checkStringUseable:firstChatModel.user.userId]) {
            [self.privateChatArray removeObject:firstChatModel];
        }
    }
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.privateChatArray insertObject:model atIndex:0];
        }
    }
    dispatch_semaphore_signal(_privateChatArrayLock);
    
    [self notifyDelegatesLoadQuestionHistorySuccess:noMore firstTime:self.firstTimeLoadPrivateChat];
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
    
    // 由于 cell显示需要的 消息多属性文本 计算比较耗时，所以，在 子线程 中提前计算出来；
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if ([PLVECChatCell isModelValid:model]) {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECChatCell chatLabelAttributedStringWithModel:model]];
        model.cellHeightForV = [PLVECChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
    } else if ([PLVECQuoteChatCell isModelValid:model]) {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECQuoteChatCell contentAttributedStringWithChatModel:model]];
        model.cellHeightForV = [PLVECQuoteChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
    } else if ([PLVECLongContentChatCell isModelValid:model]) {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECLongContentChatCell chatLabelAttributedStringWithWithModel:model]];
        model.cellHeightForV = [PLVECLongContentChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
    }
    
    [self.publicChatArray addObject:model];
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyListenerDidSendMessage:model];
}

/// 接收到socket的公聊消息时
- (void)addPublicChatModels:(NSArray <PLVChatModel *> *)modelArray {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        // 由于 cell显示需要的 消息多属性文本 计算比较耗时，所以，在 子线程 中提前计算出来；
        PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        if ([PLVECChatCell isModelValid:model]) {
            model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECChatCell chatLabelAttributedStringWithModel:model]];
            model.cellHeightForV = [PLVECChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
        } else if ([PLVECQuoteChatCell isModelValid:model]) {
            model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECQuoteChatCell contentAttributedStringWithChatModel:model]];
            model.cellHeightForV = [PLVECQuoteChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
        } else if ([PLVECLongContentChatCell isModelValid:model]) {
            model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECLongContentChatCell chatLabelAttributedStringWithWithModel:model]];
            model.cellHeightForV = [PLVECLongContentChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
        }
        
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.publicChatArray addObject:model];
            if (model.user.specialIdentity) {
                [self.partOfPublicChatArray addObject:model];
            }
        }
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyListenerDidReceiveMessages];
}

/// 接收到socket删除公聊消息的通知时
- (void)deletePublicChatModelWithMsgId:(NSString *)msgId {
    if (!msgId || ![msgId isKindOfClass:[NSString class]] || msgId.length == 0) {
        return;
    }
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *model in tempChatArray) {
        NSString *modelMsgId = [model msgId];
        if (modelMsgId && [modelMsgId isEqualToString:msgId]) {
            [self.publicChatArray removeObject:model];
            [self.partOfPublicChatArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}

/// 接收到socket删除所有公聊消息的通知时、调用销毁接口时
- (void)removeAllPublicChatModels {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.publicChatArray removeAllObjects];
    [self.partOfPublicChatArray removeAllObjects];
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}

/// 历史聊天记录接口返回消息数组时
- (void)insertChatModels:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            if ([PLVECChatCell isModelValid:model]) {
                model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECChatCell chatLabelAttributedStringWithModel:model]];
                model.cellHeightForV = [PLVECChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
            } else if ([PLVECQuoteChatCell isModelValid:model]) {
                model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECQuoteChatCell contentAttributedStringWithChatModel:model]];
                model.cellHeightForV = [PLVECQuoteChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
            } else if ([PLVECLongContentChatCell isModelValid:model]) {
                model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECLongContentChatCell chatLabelAttributedStringWithWithModel:model]];
                model.cellHeightForV = [PLVECLongContentChatCell cellHeightWithModel:model cellWidth:self.tableViewWidth];
            }
            [self.publicChatArray insertObject:model atIndex:0];
            PLVChatUser *user = model.user;
            if (user.specialIdentity) {
                if (![self.partOfPublicChatArray containsObject:model]) {
                    [self.partOfPublicChatArray insertObject:model atIndex:0];
                }
            }
        }
    }
    BOOL first = ([self.publicChatArray count] <= [modelArray count]);
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyListenerLoadHistorySuccess:noMore firstTime:first];
}

#pragma mark - Multicase

- (void)addDelegate:(id<PLVECChatroomViewModelProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    });
}

- (void)removeDelegate:(id<PLVECChatroomViewModelProtocol>)delegate {
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

#pragma mark - Listener

- (void)notifyListenerDidSendMessage:(PLVChatModel *)model {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didSendMessage:model];
    });
}

- (void)notifyListenerDidReceiveMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didReceiveMessages];
    });
}

- (void)notifyListenerDidMessageDeleted {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didMessageDeleted];
    });
}

- (void)notifyListerDidMessageCountLimitedAutoDeleted {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didMessageCountLimitedAutoDeleted];
    });
}

- (void)notifyListenerDidSendProhibitMessage {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didSendProhibitMessage];
    });
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadHistorySuccess:noMore firstTime:first];
    });
}

- (void)notifyListenerLoadHistoryFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadHistoryFailure];
    });
}

- (void)notifyDelegatesLoadQuestionHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadQuestionHistorySuccess:noMore firstTime:first];
    });
    self.firstTimeLoadPrivateChat = NO;
}

- (void)notifyDelegatesLoadQuestionHistoryFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadQuestionHistoryFailure];
    });
}

- (void)notifyListenerRewardSuccess:(NSDictionary *)modelDict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_rewardSuccess:modelDict];
    });
}

- (void)notifyListenerDidLoginRestrict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didLoginRestrict];
    });
}

- (void)notifyListenerCloseRoom:(BOOL)closeRoom {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_closeRoom:closeRoom];
    });
}

- (void)notifyListenerFocusMode:(BOOL)focusMode {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_focusMode:focusMode];
    });
}

- (void)notifyListenerCheckRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_checkRedpackStateResult:state chatModel:model];
    });
}

- (void)notifyListenerRedpackStateChanged {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didRedpackStateChanged];
    });
}

- (void)notifyListenerShowDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_showDelayRedpackWithType:type delayTime:delayTime];
    });
}

- (void)notifyListenerHideDelayRedpack {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_hideDelayRedpack];
    });
}

- (void)notifyListenerLoadRewardEnable:(BOOL)rewardEnable payWay:(NSString *)payWay rewardModelArray:(NSArray *)modelArray pointUnit:(NSString *)pointUnit {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadRewardEnable:rewardEnable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
    });
}

- (void)notifyDelegatesDidUpdateOnlineList:(NSArray<PLVChatUser *> *)list total:(NSInteger)total {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didUpdateOnlineList:list total:total];
    });
}

#pragma mark - 加载打赏开关
- (void)loadRewardEnable {
    __weak typeof(self) weakSelf = self;
    [PLVGiveRewardPresenter requestRewardSettingCompletion:^(BOOL rewardEnable,NSString *payWay, NSArray *modelArray, NSString *pointUnit) {
        weakSelf.enableReward = rewardEnable;
        [weakSelf notifyListenerLoadRewardEnable:rewardEnable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
    } failure:^(NSString *error) {
        
    }];
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
        [self notifyListenerHideDelayRedpack];
        return;
    }
    
    [self notifyListenerShowDelayRedpackWithType:self.currentRedpackType delayTime:self.delayTime];
}

#pragma mark 公聊数据管理

- (void)publicChatManagerTimerAction {
    if (self.publicChatArray.count > kPLVECMaxPublicChatMessageCount) {
        dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
        NSUInteger removalCount = self.publicChatArray.count - kPLVECMaxPublicChatMessageCount;
        NSRange removalRange = NSMakeRange(0, removalCount);
        [self.publicChatArray removeObjectsInRange:removalRange];
        NSTimeInterval lastTime = self.publicChatArray.firstObject.time;
        NSUInteger count = 0;
        for (PLVChatModel *model in self.publicChatArray) {
            if (!(model.time == lastTime)) {
                break;
            }
            count++;
        }
        [self.presenter updateHistoryLastTime:lastTime lastTimeMessageIndex:count];
        dispatch_semaphore_signal(_publicChatArrayLock);
        [self notifyListerDidMessageCountLimitedAutoDeleted];
    }
}

#pragma mark - 定时上报登录用户

/// 有用户登录
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
        dispatch_async(multicastQueue, ^{
            [self->multicastDelegate chatroomManager_loginUsers:nil];
        });
    } else {
        if ([self.loginUserArray count] >= 10) {
            NSArray *loginUserArray = [self.loginUserArray copy];
            dispatch_async(multicastQueue, ^{
                [self->multicastDelegate chatroomManager_loginUsers:loginUserArray];
            });
            
            dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
            [self.loginUserArray removeAllObjects];
            dispatch_semaphore_signal(_loginArrayLock);
        } else if ([self.loginUserArray count] > 0) {
            PLVChatUser *user = self.loginUserArray[0];
            dispatch_async(multicastQueue, ^{
                [self->multicastDelegate chatroomManager_loginUsers:@[user]];
            });
            
            dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
            [self.loginUserArray removeObjectAtIndex:0];
            dispatch_semaphore_signal(_loginArrayLock);
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
    [self notifyListenerDidSendProhibitMessage];
}

- (void)chatroomPresenter_didLoginRestrict {
    [self notifyListenerDidLoginRestrict];
}

- (void)chatroomPresenter_didChangeCloseRoom:(BOOL)closeRoom {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live) {
        [self notifyListenerCloseRoom:closeRoom];
    }
}

- (void)chatroomPresenter_didChangeFocusMode:(BOOL)focusMode {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live) {
        self.onlyTeacher = focusMode;
        [self notifyListenerFocusMode:focusMode];
    }
}

- (void)chatroomPresenter_didReceiveDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    [self startRedpackTimerWithRedpackType:type delayTime:delayTime];
}

- (void)chatroomPresenter_loadQuestionHistorySuccess:(NSArray<PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    [self insertPrivateChatModels:modelArray noMore:noMore];
}

- (void)chatroomPresenter_loadQuestionHistoryFailure {
    [self notifyDelegatesLoadQuestionHistoryFailure];
}

- (void)chatroomPresenter_didUpdateOnlineList:(NSArray<PLVChatUser *> *)list total:(NSInteger)total {
    [self notifyDelegatesDidUpdateOnlineList:list total:total];
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
