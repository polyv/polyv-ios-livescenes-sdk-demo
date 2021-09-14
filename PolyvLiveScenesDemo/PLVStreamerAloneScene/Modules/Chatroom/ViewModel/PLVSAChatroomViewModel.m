//
//  PLVSAChatroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChatroomViewModel.h"
#import "PLVRoomDataManager.h"

@interface PLVSAChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

// 登录用户上报

/// 上报登陆用户计时器，间隔2秒触发一次
@property (nonatomic, strong) NSTimer *loginTimer;
/// 暂未上报的登陆用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *loginUserArray;
/// 当前时间段内是否发生当前用户的登录事件
@property (nonatomic, assign) BOOL isMyselfLogin;

// 数据数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArray; /// 公聊全部消息数组
/// 图片表情数组
@property (nonatomic, strong) NSArray *imageEmotionArray;

@end

@implementation PLVSAChatroomViewModel {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _chatArrayLock;
    dispatch_semaphore_t _loginArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVSAChatroomViewModel *viewModel = nil;
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
    _loginArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.chatArray = [[NSMutableArray alloc] initWithCapacity:500];
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:10 childRoomAllow:NO];
    self.presenter.delegate = self;
    self.presenter.specialRole = YES;
    
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

#pragma mark 加载历史消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

#pragma mark - 加载图片表情资源列表

- (void)loadImageEmotions {
    [self.presenter loadImageEmotions];
}

#pragma mark  发送消息

- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    PLVChatModel *model = [self.presenter chatModelWithMsgStateForSendSpeakMessage:content replyChatModel:replyChatModel];
    if (model) {
        if (replyChatModel) {
            model.replyMessage = replyChatModel;
        }
        [self addPublicChatModel:model];
    }
    return model;
}

- (BOOL)sendImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    if (model) {
        model.imageId = ((PLVImageMessage *)[model message]).imageId;
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)sendImageEmotionMessage:(NSString *)imageId
                       imageUrl:(NSString *)imageUrl {
    PLVChatModel *model = [self.presenter sendImageEmotionId:imageId];
    if (model) {
        ((PLVImageEmotionMessage *)model.message).imageUrl = imageUrl;
        model.imageId = imageId;
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)resendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    PLVChatModel *model = [self.presenter chatModelWithMsgStateForSendSpeakMessage:content replyChatModel:replyChatModel];
    if (model) {
        [self deleteResendChatModelWithModel:model];
        if (replyChatModel) {
            model.replyMessage = replyChatModel;
        }
        [self addPublicChatModel:model];
    }
    return model;
}

- (BOOL)resendImageMessage:(UIImage *)image imageId:(NSString *)imageId {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    if (model) {
        if (imageId) {
            model.imageId = imageId;
            [self deleteResendChatModelWithModel:model];
        }
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)resendImageEmotionMessage:(NSString *)imageId imageUrl:(NSString *)imageUrl {
    PLVChatModel *model = [self.presenter sendImageEmotionId:imageId];
    if (model) {
        ((PLVImageEmotionMessage *)model.message).imageUrl = imageUrl;
        model.imageId = imageId;
        [self deleteResendChatModelWithModel:model];
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)sendCloseRoom:(BOOL)closeRoom {
    return [self.presenter sendCloseRoom:closeRoom];
}

#pragma mark - [ Private Method ]

#pragma mark Getter
- (BOOL)closeRoom {
    return self.presenter.closeRoom;
}

#pragma mark Data Mode

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
            model.msgState = PLVChatMsgStateUnknown;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidSendMessage];
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

/// 删除已重发的消息(此时还未发到公聊)，避免重复显示
- (void)deleteResendChatModelWithModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *tempChatArray = [self.chatArray copy];
    for (PLVChatModel *tempModel in tempChatArray) {
        
        id message = model.message;
       if ([message isKindOfClass:[PLVSpeakMessage class]] &&
           [tempModel.message isKindOfClass:[PLVSpeakMessage class]]) {
            PLVSpeakMessage  *speak = (PLVSpeakMessage *)message;
            NSString *content = tempModel.content;
            NSString *speakContetn = speak.content;
            if (content &&
                speakContetn &&
                [content isEqualToString:speakContetn]) {
                [self.chatArray removeObject:tempModel];
                break;
            }
        } else if ([message isKindOfClass:[PLVQuoteMessage class]] &&
                   [tempModel.message isKindOfClass:[PLVQuoteMessage class]]){
            PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)message;
            PLVQuoteMessage *tempQuoteMessage = (PLVQuoteMessage *)tempModel.message;
            
            // 讲师回复的内容
            NSString *tempContent = tempQuoteMessage.content;
            NSString *content = quoteMessage.content;
            
            // 学生发言图片地址
            NSString *tempQuoteImageUrl = tempQuoteMessage.quoteImageUrl;
            NSString *quoteImageUrl = quoteMessage.quoteImageUrl;
            
            // 学生发言内容
            NSString *tempQuoteContent = tempQuoteMessage.quoteContent;
            NSString *quoteContent = quoteMessage.quoteContent;
            
            if (tempContent &&
                content) {
                // 被老师回复的类型为图片
                if (tempQuoteImageUrl &&
                    quoteImageUrl &&
                    [tempQuoteImageUrl isEqualToString:quoteImageUrl]) { 
                    
                    [self.chatArray removeObject:tempModel];
                    break;
                    
                }
                
                // 被老师回复的类型为文字
                if (tempContent &&
                    content &&
                    tempQuoteContent &&
                    quoteContent &&
                    [tempContent isEqualToString:content] &&
                    [tempQuoteContent isEqualToString:quoteContent]) {
                    
                    [self.chatArray removeObject:tempModel];
                    break;
                    
                }
            }
        } else if ([message isKindOfClass:[PLVImageMessage class]] &&
                   [tempModel.message isKindOfClass:[PLVImageMessage class]]) {
    
            NSString *tempImageId = tempModel.imageId;
            NSString *imageId = model.imageId;
            
            if (tempImageId &&
                imageId &&
                [tempImageId isEqualToString:imageId]) {
                
                [self.chatArray removeObject:tempModel];
                break;
                
            }
        } else if ([message isKindOfClass:[PLVImageEmotionMessage class]] &&
                   [tempModel.message isKindOfClass:[PLVImageEmotionMessage class]]) {
    
            NSString *tempImageId = tempModel.imageId;
            NSString *imageId = model.imageId;
            //只能保证已经发送的图片表情消息不重复，未发送成功的因为图片id和url完全一致咱不能区分
            NSString *msgId = ((PLVImageEmotionMessage *)tempModel.message).msgId;
            if (tempImageId &&
                imageId &&
                [tempImageId isEqualToString:imageId] &&
                !msgId) {
                
                [self.chatArray removeObject:tempModel];
                break;
                
            }
        }
    }
    
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}


#pragma mark 发送PLVSAChatroomViewModelProtocol协议方法

- (void)notifyListenerDidSendMessage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModelDidSendMessage:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelDidSendMessage:self];
        });
    }
}

- (void)notifyListenerDidReceiveMessages {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModelDidReceiveMessages:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelDidReceiveMessages:self];
        });
    }
}

- (void)notifyListenerDidMessageDeleted {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModelDidMessageDeleted:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelDidMessageDeleted:self];
        });
    }
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModelDidSendMessage:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel:self loadHistorySuccess:noMore firstTime:first];
        });
    }
}

- (void)notifyListenerLoadHistoryFailure {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModelLoadHistoryFailure:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelLoadHistoryFailure:self];
        });
    }
}

#pragma mark 定时上报登录用户

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
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel:loginUsers:)]) {
        if (self.isMyselfLogin) {
            self.isMyselfLogin = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate chatroomViewModel:self loginUsers:nil];
            });
        } else {
            if ([self.loginUserArray count] >= 10) {
                NSArray *loginUserArray = [self.loginUserArray copy];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate chatroomViewModel:self loginUsers:loginUserArray];
                });
                
                dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
                [self.loginUserArray removeAllObjects];
                dispatch_semaphore_signal(_loginArrayLock);
            } else if ([self.loginUserArray count] > 0) {
                PLVChatUser *user = self.loginUserArray[0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate chatroomViewModel:self loginUsers:@[user]];
                });
                
                dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
                [self.loginUserArray removeObjectAtIndex:0];
                dispatch_semaphore_signal(_loginArrayLock);
            }
        }
    }
}

#pragma mark 赠送礼物

- (void)rewardMessageEvent:(NSDictionary *)jsonDict {
    // 礼物消息
    NSDictionary *content = PLV_SafeDictionaryForDictKey(jsonDict, @"content");

    // 打赏的用户
    NSString *nickName = PLV_SafeStringForDictKey(content, @"unick");
    // 打赏的数量
    NSInteger giftNum =  PLV_SafeIntegerForDictKey(content, @"goodNum");
    
    // 打赏内容：礼物打赏为礼物名称，现金打赏为金额
    NSString *giftContent = PLV_SafeStringForDictKey(content, @"rewardContent");
    
    // 礼物打赏为礼物图片，现金打赏为空
    NSString *giftImageUrl = PLV_SafeStringForDictKey(content, @"gimg");
    if ([PLVFdUtil checkStringUseable:giftImageUrl] &&
        ![giftImageUrl containsString:@"http"]) {
        giftImageUrl = [NSString stringWithFormat:@"https:%@", giftImageUrl];
    }
    if ([PLVFdUtil checkStringUseable:giftImageUrl]) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(chatroomViewModel:giftNickName:giftImageUrl:giftNum:giftContent:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate chatroomViewModel:self giftNickName:nickName giftImageUrl:giftImageUrl giftNum:giftNum giftContent:giftContent];
            });
        }
    } else {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(chatroomViewModel:giftNickName:cashGiftContent:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate chatroomViewModel:self giftNickName:nickName cashGiftContent:giftContent];
            });
        }
    }
}

#pragma mark Utils

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

#pragma mark - Delegate

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    // 有新用户登录聊天室
    if ([subEvent isEqualToString:@"LOGIN"]) {
        [self loginEvent:jsonDict];
    }
    // 有人送礼物
    if ([subEvent isEqualToString:@"REWARD"]) {
        [self rewardMessageEvent:jsonDict];
    }
}

#pragma mark  PLVChatroomPresenterProtocol

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

- (void)chatroomPresenter_receiveWarning:(NSString *)message prohibitWord:(NSString *)word {
    [self markChatModelWithProhibitWord:word];
}

- (void)chatroomPresenter_receiveImageWarningWithMsgId:(NSString *)msgId {
    [self markChatModelProhibitImageWithMsgId:msgId];
}

@end
