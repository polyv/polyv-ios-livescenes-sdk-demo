//
//  PLVLSChatroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/2/3.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSChatroomViewModel.h"
#import "PLVRoomDataManager.h"

@interface PLVLSChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArray; /// 公聊全部消息数组

@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatRemindArray; /// 提醒消息 全部消息数组

@end

@implementation PLVLSChatroomViewModel{
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _chatArrayLock;
    dispatch_semaphore_t _chatRemindArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
    
    dispatch_queue_t multicastQueue;
    PLVMulticastDelegate<PLVLSChatroomViewModelProtocol> *multicastDelegate;
}

#pragma mark - 生命周期

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVLSChatroomViewModel *viewModel = nil;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        
        multicastQueue = dispatch_queue_create("com.PLVLiveScenesDemo.PLVLSChatroomViewModel", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVLSChatroomViewModelProtocol> *)[[PLVMulticastDelegate alloc] init];
    }
    return self;
}

- (void)setup {
    // 初始化信号量
    _chatArrayLock = dispatch_semaphore_create(1);
    _chatRemindArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.chatArray = [[NSMutableArray alloc] initWithCapacity:500];
    self.chatRemindArray = [[NSMutableArray alloc] initWithCapacity:20];
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:10];
    self.presenter.delegate = self;
    [self.presenter login];

    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    [self.presenter destroy];
    self.presenter = nil;

    [self removeAllPublicChatModels];
}

#pragma mark - Getter

- (NSArray *)imageEmotionArray {
    return self.presenter.imageEmotionArray;
}

#pragma mark - 加载消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

- (void)loadRemindHistory {
    [self.presenter loadRemindHistory];
}

#pragma mark - 加载图片表情资源列表

- (void)loadImageEmotions {
    [self.presenter loadImageEmotions];
}

#pragma mark - 发送消息

- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content replyChatModel:replyChatModel];
    if (model) {
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)sendRemindSpeakMessage:(NSString *)content {
    PLVChatModel *model = [self.presenter sendRemindSpeakMessage:content];
    if (model) { // 提醒消息需要展示到公屏与私聊屏
        [self addPublicChatModel:model];
        [self addRemindChatModel:model];
    }
    return model != nil;
}

- (BOOL)resendRemindSpeakMessage:(PLVChatModel *)model {
    if (!model ||
        !model.message ||
        !model.content) {
        return NO;
    }
    
    PLVChatModel *tempModel = [self.presenter sendRemindSpeakMessage:model.content];
    if (tempModel) {
        [self deleteResendChatPublicModelWithModel:model];
        [self deleteResendChatRemindModelWithModel:model];
        
        [self addPublicChatModel:tempModel];
        [self addRemindChatModel:tempModel];
    }
    return tempModel != nil;
}

- (BOOL)sendImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    if (model) {
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)sendRemindImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendRemindImageMessage:image];
    if (model) { // 提醒消息需要展示到公屏与私聊屏
        [self addPublicChatModel:model];
        [self addRemindChatModel:model];
    }
    return model != nil;
}

- (BOOL)resendRemindImageMessage:(PLVChatModel *)model {
    if (!model ||
        !model.message ||
        ![model.message isKindOfClass:[PLVImageMessage class]]) {
        return NO;
    }
    
    PLVImageMessage *message = (PLVImageMessage *)[model message];
    PLVChatModel *tempModel = [self.presenter sendRemindImageMessage:message.image];
    if (tempModel) {
        [self deleteResendChatPublicModelWithModel:model];
        [self deleteResendChatRemindModelWithModel:model];
        
        [self addPublicChatModel:tempModel];
        [self addRemindChatModel:tempModel];
    }
    return tempModel != nil;
}

- (BOOL)sendImageEmotionMessage:(NSString *)imageId
                       imageUrl:(NSString *)imageUrl {
    PLVChatModel *model = [self.presenter sendImageEmotionId:imageId imageUrl:imageUrl];
    if (model) {
        [self addPublicChatModel:model];
    }
    return model != nil;
}

#pragma mark Multicast

- (void)addDelegate:(id<PLVLSChatroomViewModelProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    });
}

- (void)removeDelegate:(id<PLVLSChatroomViewModelProtocol>)delegate {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeDelegate:delegate];
    });
}

- (void)removeAllDelegates {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeAllDelegates];
    });
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

/// 本地发送提醒消息时
- (void)addRemindChatModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]] ||
        ![model isRemindMsg]) {
        return;
    }
    dispatch_semaphore_wait(_chatRemindArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatRemindArray addObject:model];
    dispatch_semaphore_signal(_chatRemindArrayLock);
    
    [self notifyListenerDidSendMessage];
}

/// 接收到socket的公聊、提醒消息时
- (void)addPublicChatModels:(NSArray <PLVChatModel *> *)modelArray {
    NSMutableArray <PLVChatModel *> *remindModelArray = [NSMutableArray arrayWithCapacity:10];
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.chatArray addObject:model];
            if ([model isRemindMsg]) { // 提醒消息
                [remindModelArray addObject:model];
            }
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidReceiveMessages];
    if ([PLVFdUtil checkArrayUseable:remindModelArray]) {
        [self addRemindChatModels:[remindModelArray copy]];
    }
}

/// 接收到socket的提醒消息时
- (void)addRemindChatModels:(NSArray <PLVChatModel *> *)modelArray {
    dispatch_semaphore_wait(_chatRemindArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.chatRemindArray addObject:model];
        }
    }
    dispatch_semaphore_signal(_chatRemindArrayLock);
    [self notifyListenerDidReceiveRemindMessages];
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

/// 接收到socket删除提醒消息的通知时
- (void)deleteRemindChatModelWithMsgId:(NSString *)msgId {
    if (!msgId || ![msgId isKindOfClass:[NSString class]] || msgId.length == 0) {
        return;
    }
    dispatch_semaphore_wait(_chatRemindArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatRemindArray copy];
    for (PLVChatModel *model in tempChatArray) {
        NSString *modelMsgId = [model msgId];
        if (modelMsgId && [modelMsgId isEqualToString:msgId]) {
            [self.chatRemindArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_chatRemindArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}

/// 删除重发的 公屏消息
- (void)deleteResendChatPublicModelWithModel:(PLVChatModel *)model{
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *tempModel in tempChatArray) {
        if (model == tempModel) {
            [self.chatArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
}

/// 删除重发的 提醒消息
- (void)deleteResendChatRemindModelWithModel:(PLVChatModel *)model{
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    
    dispatch_semaphore_wait(_chatRemindArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatRemindArray copy];
    for (PLVChatModel *tempModel in tempChatArray) {
        if (model == tempModel) {
            [self.chatRemindArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_chatRemindArrayLock);
}

/// 接收到socket删除所有公聊消息的通知时、调用销毁接口时
- (void)removeAllPublicChatModels {
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatArray removeAllObjects];
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}

- (void)removeAllRemindChatModels {
    dispatch_semaphore_wait(_chatRemindArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatRemindArray removeAllObjects];
    dispatch_semaphore_signal(_chatRemindArrayLock);
    
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

- (void)insertChatRemindModels:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    dispatch_semaphore_wait(_chatRemindArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.chatRemindArray insertObject:model atIndex:0];
        }
    }
    BOOL first = ([self.chatRemindArray count] <= [modelArray count]);
    dispatch_semaphore_signal(_chatRemindArrayLock);
    
    [self notifyListenerLoadRemindHistorySuccess:noMore firstTime:first];
}

/// 处理严禁词
/// 由于公屏、提醒聊天室消息列表储存的对象都是同一个，所以只需要处理一次即可。
- (void)markChatModelWithWaring:(NSString *)warning prohibitWord:(NSString *)word {
    if (![PLVFdUtil checkStringUseable:word]) { // 发送成功，以用**代替严禁词发出
        [self notifyListenerDidSendProhibitMessage];
        return;
    }
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *model in tempChatArray) {
        NSString *modelMsgId = [model msgId];
        // 含有严禁词且发送失败的消息，msgID为空
        if (modelMsgId && modelMsgId.length > 0) {
            continue;
        }
        // 该消息已标记为严禁词、违禁图片消息
        if ([model isProhibitMsg]) {
            continue;
        }
        
        NSString *content = [model content];
        //只要含有严禁词，都需要处理，不局限于最近一条
        if (content &&
            [content isKindOfClass:[NSString class]] &&
            [content containsString:word]) {
            model.prohibitWord = word;
            model.msgState = PLVChatMsgStateUnknown;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidSendProhibitMessage];
}


/// 处理违禁图片
- (void)markChatModelProhibitImageWithMsgId:(NSString *)msgId {
    if (!msgId ||
        ![msgId isKindOfClass:[NSString class]] ||
        msgId.length == 0) {
        return;
    }
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *model in tempChatArray) {
        // 该消息已标记为严禁词、违禁图片消息
        if ([model isProhibitMsg]) {
            continue;
        }
        
        NSString *tempMsgId = [model msgId];
        if (tempMsgId &&
            [tempMsgId isKindOfClass:[NSString class]] &&
            [tempMsgId isEqualToString:msgId]) {
            model.prohibitWord = tempMsgId;
            break;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidSendProhibitMessage];
}

#pragma mark - Listener

- (void)notifyListenerDidSendMessage {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_didSendMessage];
    });
}

- (void)notifyListenerDidSendProhibitMessage {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_didSendProhibitMessage];
    });
}

- (void)notifyListenerDidReceiveMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_didReceiveMessages];
    });
}

- (void)notifyListenerDidReceiveRemindMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_didReceiveRemindMessages];
    });
}

- (void)notifyListenerDidMessageDeleted {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_didMessageDeleted];
    });
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_loadHistorySuccess:noMore firstTime:first];
    });
}

- (void)notifyListenerLoadHistoryFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_loadHistoryFailure];
    });
}

- (void)notifyListenerLoadRemindHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_loadRemindHistorySuccess:noMore firstTime:first];
    });
}

- (void)notifyListenerLoadRemindHistoryFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_loadRemindHistoryFailure];
    });
}

- (void)notifyListenerLoadImageEmotionsSuccess {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_loadImageEmotionSuccess:self.imageEmotionArray];
    });
}

- (void)notifyListenerLoadImageEmotionsFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomViewModel_loadImageEmotionFailure];
    });
}

#pragma mark - PLVChatroomPresenterProtocol

- (void)chatroomPresenter_loadHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    [self insertChatModels:modelArray noMore:noMore];
}

- (void)chatroomPresenter_loadHistoryFailure {
    [self notifyListenerLoadHistoryFailure];
}

- (void)chatroomPresenter_loadRemindHistorySuccess:(NSArray<PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    [self insertChatRemindModels:modelArray noMore:noMore];
}

- (void)chatroomPresenter_loadRemindHistoryFailure {
    [self notifyListenerLoadRemindHistoryFailure];
}

- (void)chatroomPresenter_didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray {
    [self addPublicChatModels:modelArray];
}

- (void)chatroomPresenter_didMessageDeleted:(NSString *)msgId {
    [self deletePublicChatModelWithMsgId:msgId];
    [self deleteRemindChatModelWithMsgId:msgId];
}

- (void)chatroomPresenter_didAllMessageDeleted {
    [self removeAllPublicChatModels];
    [self removeAllRemindChatModels];
}

- (void)chatroomPresenter_receiveWarning:(NSString *)warning prohibitWord:(NSString *)word {
    [self markChatModelWithWaring:warning prohibitWord:word];
}

- (void)chatroomPresenter_receiveImageWarningWithMsgId:(NSString *)msgId{
    [self markChatModelProhibitImageWithMsgId:msgId];
}

- (void)chatroomPresenter_loadImageEmotionsSuccess {
    [self notifyListenerLoadImageEmotionsSuccess];
}

- (void)chatroomPresenter_loadImageEmotionsFailure {
    [self notifyListenerLoadImageEmotionsFailure];
}

@end
