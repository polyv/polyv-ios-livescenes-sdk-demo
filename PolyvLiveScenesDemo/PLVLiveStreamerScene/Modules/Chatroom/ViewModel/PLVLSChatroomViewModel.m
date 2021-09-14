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
/// 图片表情数组
@property (nonatomic, strong) NSArray *imageEmotionArray;

@end

@implementation PLVLSChatroomViewModel{
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _chatArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
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
    }
    return self;
}

- (void)setup {
    // 初始化信号量
    _chatArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.chatArray = [[NSMutableArray alloc] initWithCapacity:500];
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:10 childRoomAllow:NO];
    self.presenter.delegate = self;
    self.presenter.specialRole = YES;
    //加载图片表情资源
    [self.presenter loadImageEmotions];

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

#pragma mark - 加载消息

- (void)loadHistory {
    [self.presenter loadHistory];
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

- (BOOL)sendImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    if (model) {
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)sendImageEmotionMessage:(NSString *)imageId
                       imageUrl:(NSString *)imageUrl {
    PLVChatModel *model = [self.presenter sendImageEmotionId:imageId];
    if (model) {
        ((PLVImageEmotionMessage *)model.message).imageUrl = imageUrl;
        [self addPublicChatModel:model];
    }
    return model != nil;
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
            
            //当接收到公聊消息为图片表情时，因为会返回图片id所以在此处从列表中取出图片地址
            if ([model.message isKindOfClass:[PLVImageEmotionMessage class]]) {
                PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)model.message;
                [self.imageEmotionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *emotionImageId = PLV_SafeStringForDictKey(obj, @"id");
                    if (emotionImageId &&
                        [message.imageId isEqualToString:emotionImageId]) {
                        message.imageUrl = PLV_SafeStringForDictKey(obj, @"url");
                        *stop = YES;
                    }
                }];
            }
            
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

/// 处理严禁词
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
        // 该消息已标记为包含严禁词消息
        if ([model isProhibitMsg]) {
            continue;
        }
        
        NSString *content = [model content];
        //只要含有违禁词，都需要处理，不局限于最近一条
        if (content &&
            [content isKindOfClass:[NSString class]] &&
            [content containsString:word]) {
            model.prohibitWord = word;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidSendMessage];
}

- (void)markChatModelProhibitImageWithMsgId:(NSString *)msgId {
    if (!msgId ||
        ![msgId isKindOfClass:[NSString class]] ||
        msgId.length == 0) {
        return;
    }
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *model in tempChatArray) {
        // 该消息已标记为包含严禁词消息
        if ([model isProhibitMsg]) {
            continue;
        }
        
        NSString *tempMsgId = [model msgId];
        // 只要含有违禁词，都需要处理，不局限于最近一条
        if (tempMsgId &&
            [tempMsgId isKindOfClass:[NSString class]] &&
            [tempMsgId isEqualToString:msgId]) {
            model.prohibitWord = tempMsgId;
            break;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidSendMessage];
}

#pragma mark - Listener

- (void)notifyListenerDidSendMessage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel_didSendMessage)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_didSendMessage];
        });
    }
}

- (void)notifyListenerDidReceiveMessages {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel_didReceiveMessages)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_didReceiveMessages];
        });
    }
}

- (void)notifyListenerDidMessageDeleted {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel_didMessageDeleted)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_didMessageDeleted];
        });
    }
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel_loadHistorySuccess:firstTime:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_loadHistorySuccess:noMore firstTime:first];
        });
    }
}

- (void)notifyListenerLoadHistoryFailure {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel_loadHistoryFailure)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_loadHistoryFailure];
        });
    }
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
}

#pragma mark - PLVChatroomPresenterProtocol

- (void)chatroomPresenter_loadHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    [self insertChatModels:modelArray noMore:noMore];
}

- (void)chatroomPresenter_loadHistoryFailure {
    [self notifyListenerLoadHistoryFailure];
}

- (void)chatroomPresenter_loadImageEmotionsSuccess:(NSArray<NSDictionary *> *)dictArray {
    self.imageEmotionArray = dictArray;
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel_loadEmotionSuccess)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_loadEmotionSuccess];
        });
    }
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

- (void)chatroomPresenter_receiveWarning:(NSString *)message prohibitWord:(NSString *)word{
    [self markChatModelWithProhibitWord:word];
}

- (void)chatroomPresenter_receiveImageWarningWithMsgId:(NSString *)msgId{
    [self markChatModelProhibitImageWithMsgId:msgId];
}

@end
