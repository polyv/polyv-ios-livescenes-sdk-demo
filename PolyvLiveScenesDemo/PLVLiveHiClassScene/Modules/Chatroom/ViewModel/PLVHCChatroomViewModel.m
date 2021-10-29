//
//  PLVHCChatroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import "PLVCloseRoomModel.h"

@interface PLVHCChatroomViewModel()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

#pragma mark 聊天室Presenter

/// 聊天室Presenter
@property (nonatomic, strong) PLVChatroomPresenter *presenter;

#pragma mark 公聊全部消息数组

/// 公聊全部消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArray;

@end

@implementation PLVHCChatroomViewModel {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _chatArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVHCChatroomViewModel *viewModel = nil;
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

#pragma mark - [ Public Method ]

- (void)setup {
    // 初始化信号量
    _chatArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.chatArray = [[NSMutableArray alloc] initWithCapacity:500];
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:10];
    [self.presenter setCourseCode:roomData.lessonInfo.courseCode lessonId:roomData.lessonInfo.lessonId];
    self.presenter.delegate = self;
    [self.presenter login];
    
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    [self.presenter destroy];
    self.presenter = nil;
    
    self.delegate = nil;
    [self removeAllPublicChatModels];
}

#pragma mark 加载历史消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

#pragma mark  发送消息

- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content replyChatModel:replyChatModel];
    if (model) {
        if (replyChatModel) {
            model.replyMessage = replyChatModel;
        }
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)sendImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    if (model) {
        model.imageId = ((PLVImageMessage *)[model message]).imageId;
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)resendSpeakMessage:(PLVChatModel *)model replyChatModel:(PLVChatModel *)replyChatModel {
    if (!model ||
        !model.message ||
        !model.content) {
        return NO;
    }
    
    PLVChatModel *tempModel = [self.presenter sendSpeakMessage:model.content replyChatModel:replyChatModel];
    if (tempModel) {
        tempModel.replyMessage = replyChatModel;
        
        [self deleteResendChatModelWithModel:model];
        [self addResendPublicChatModel:tempModel];
    }
    return tempModel != nil;
}

- (BOOL)resendImageMessage:(PLVChatModel *)model {
    if (!model ||
        !model.message ||
        ![model.message isKindOfClass:[PLVImageMessage class]]) {
        return NO;
    }
    
    PLVImageMessage *message = (PLVImageMessage *)[model message];
    PLVChatModel *tempModel = [self.presenter sendImageMessage:message.image];
    if (tempModel) {
        [self deleteResendChatModelWithModel:model];
        [self addResendPublicChatModel:tempModel];
    }
    return tempModel != nil;
}

#pragma mark - [ Private Method ]

#pragma mark Data Mode

/// 本地发送公聊消息时
- (void)addPublicChatModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatArray addObject:model];
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidSendMessage];
}

/// 本地重发公聊消息时
- (void)addResendPublicChatModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatArray addObject:model];
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidResendMessage];
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
    if (!msgId ||
        ![msgId isKindOfClass:[NSString class]] ||
        msgId.length == 0) {
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

/// 接收到聊天室关闭、开启通知时
- (void)addCloseRoomChatModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatArray addObject:model];
    dispatch_semaphore_signal(_chatArrayLock);
}

/// 处理严禁词，打标签
- (void)markChatModelWithProhibitWord:(NSString *)word {
    if (!word ||
        ![word isKindOfClass:[NSString class]] ||
        word.length == 0) {
        return;
    }
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *model in tempChatArray) {
        NSString *modelMsgId = [model msgId];
        // 含有严禁词的消息，msgID为空
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
    
    [self notifyListenerDidSendProhibitMessgae];
}

/// 给违规图片打上标签
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
    
    [self notifyListenerDidSendProhibitMessgae];
}

/// 删除已重发的消息(此时还未发到公聊)，避免重复显示
- (void)deleteResendChatModelWithModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempCharArray = [self.chatArray copy];
    for (PLVChatModel *tempModel in tempCharArray) {
        if (tempModel == model) {
            [self.chatArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
}

#pragma mark 发送PLVHCChatroomViewModelDelegate协议方法

- (void)notifyListenerDidSendMessage {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidSendMessage:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModelDidSendMessage:self];
        })
    }
}

- (void)notifyListenerDidResendMessage {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidResendMessage:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModelDidResendMessage:self];
        })
    }
}

- (void)notifyListenerDidSendProhibitMessgae {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidSendProhibitMessgae:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModelDidSendProhibitMessgae:self];
        })
    }
}

- (void)notifyListenerDidReceiveMessages {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidReceiveMessages:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModelDidReceiveMessages:self];
        })
    }
}

- (void)notifyListenerDidMessageDeleted {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidMessageDeleted:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModelDidMessageDeleted:self];
        })
    }
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidSendMessage:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModel:self loadHistorySuccess:noMore firstTime:first];
        })
    }
}

- (void)notifyListenerLoadHistoryFailure {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelLoadHistoryFailure:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModelLoadHistoryFailure:self];
        })
    }
}

- (void)notifyListenerDidReceiveCloseRoomMessages {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidReceiveCloseRoomMessage:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate chatroomViewModelDidReceiveCloseRoomMessage:self];
        })
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
    
    if ([subEvent isEqualToString:@"onSliceStart"]) { // 上课后学生和讲师收到onSliceStart事件后，需要再次发送LOGIN事件，这时聊天室才可用
        [self.presenter emitLoginEvent];
    }
}

#pragma mark  PLVChatroomPresenterProtocol

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

- (void)chatroomPresenter_receiveWarning:(NSString *)message prohibitWord:(NSString *)word {
    [self markChatModelWithProhibitWord:word];
}

- (void)chatroomPresenter_receiveImageWarningWithMsgId:(NSString *)msgId {
    [self markChatModelProhibitImageWithMsgId:msgId];
}

- (void)chatroomPresenter_didChangeCloseRoom:(BOOL)closeRoom {
    PLVChatModel *chatModel = [[PLVChatModel alloc] init];
    PLVCloseRoomModel *closeRoomModel = [[PLVCloseRoomModel alloc] init];
    closeRoomModel.closeRoom = closeRoom;
    chatModel.message = closeRoomModel;
   
    [self addCloseRoomChatModel:chatModel];
    
    [self notifyListenerDidReceiveCloseRoomMessages];
}
@end
