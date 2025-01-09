//
//  PLVSAChatroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import "PLVSASpeakMessageCell.h"
#import "PLVSAQuoteMessageCell.h"
#import "PLVSAImageMessageCell.h"
#import "PLVSAImageEmotionMessageCell.h"
#import "PLVSALongContentMessageCell.h"
#import "PLVSARewardMessageCell.h"

static NSInteger kPLVSAMaxPublicChatMessageCount = 500;

@interface PLVSAChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

// 登录用户上报

/// 上报登录用户计时器，间隔2秒触发一次
@property (nonatomic, strong) NSTimer *loginTimer;
/// 暂未上报的登录用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *loginUserArray;
/// 当前时间段内是否发生当前用户的登录事件
@property (nonatomic, assign) BOOL isMyselfLogin;

// 数据数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArray; /// 公聊全部消息数组

@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArrayWithoutReward; /// 屏蔽礼物打赏消息数组

#pragma mark 聊天数据管理

/// 公聊数据管理计时器，间隔30秒触发一次
@property (nonatomic, strong) NSTimer *publicChatManagerTimer;

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
    self.chatArrayWithoutReward = [[NSMutableArray alloc] initWithCapacity:500];
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:10];
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
    
    // 初始化公聊数据管理计时器
    self.publicChatManagerTimer = [NSTimer scheduledTimerWithTimeInterval:6
                                                                   target:self
                                                                 selector:@selector(publicChatManagerTimerAction)
                                                                 userInfo:nil
                                                                  repeats:YES];
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    [self.presenter destroy];
    self.presenter = nil;
    
    self.delegate = nil;
    [self.loginTimer invalidate];
    self.loginTimer = nil;
    [self.publicChatManagerTimer invalidate];
    self.publicChatManagerTimer = nil;
    [self removeAllPublicChatModels];
}

#pragma mark 加载历史消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

#pragma mark - Getter

- (NSArray *)imageEmotionArray {
    return self.presenter.imageEmotionArray;
}

#pragma mark - 加载图片表情资源列表

- (void)loadImageEmotions {
    [self.presenter loadImageEmotions];
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
    PLVChatModel *model = [self.presenter sendImageEmotionId:imageId imageUrl:imageUrl];
    if (model) {
        [self addPublicChatModel:model];
    }
    return model != nil;
}

- (BOOL)sendPinMessageWithMsgId:(NSString *_Nullable)msgId toTop:(BOOL)toTop {
    return [self.presenter sendPinMessageWithMsgId:msgId toTop:toTop];
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
    return tempModel;
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

- (BOOL)resendImageEmotionMessage:(PLVChatModel *)model {
    if (!model ||
        !model.message ||
        ![model.message isKindOfClass:[PLVImageEmotionMessage class]]) {
        return NO;
    }
    
    PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)[model message];
    PLVChatModel *resendModel = [self.presenter sendImageEmotionId:message.imageId imageUrl:message.imageUrl];
    if (resendModel) {
        [self deleteResendChatModelWithModel:model];
        [self addResendPublicChatModel:resendModel];
    }
    return resendModel != nil;
}

#pragma mark - [ Private Method ]
#pragma mark Data Mode

/// 本地发送公聊消息时
- (void)addPublicChatModel:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    
    // 由于 cell显示需要的 消息多属性文本 计算比较耗时，所以，在 子线程 中提前计算出来；
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if ([PLVSASpeakMessageCell isModelValid:model]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
        model.attributeString = [PLVSASpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId prohibitWord:model.prohibitWord];
        model.cellHeightForV = [PLVSASpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSALongContentMessageCell isModelValid:model]) {
        model.attributeString = [PLVSALongContentMessageCell contentLabelAttributedStringWithModel:model loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSALongContentMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSAImageMessageCell isModelValid:model]) {
        model.attributeString = [PLVSAImageMessageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSAImageMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSAImageEmotionMessageCell isModelValid:model]) {
        model.attributeString = [PLVSAImageEmotionMessageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSAImageEmotionMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSAQuoteMessageCell isModelValid:model]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
        model.attributeString = [PLVSAQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
        model.cellHeightForV = [PLVSAQuoteMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSARewardMessageCell isModelValid:model]) {
        PLVRewardMessage *message = (PLVRewardMessage *)model.message;
        model.attributeString = [PLVSARewardMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSARewardMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    }
    
    [self.chatArray addObject:model];
    if (![PLVSARewardMessageCell isModelValid:model]) {
        [self.chatArrayWithoutReward addObject:model];
    }
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
    
    // 由于 cell显示需要的 消息多属性文本 计算比较耗时，所以，在 子线程 中提前计算出来；
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if ([PLVSASpeakMessageCell isModelValid:model]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
        model.attributeString = [PLVSASpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId prohibitWord:model.prohibitWord];
        model.cellHeightForV = [PLVSASpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSALongContentMessageCell isModelValid:model]) {
        model.attributeString = [PLVSALongContentMessageCell contentLabelAttributedStringWithModel:model loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSALongContentMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSAImageMessageCell isModelValid:model]) {
        model.attributeString = [PLVSAImageMessageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSAImageMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSAImageEmotionMessageCell isModelValid:model]) {
        model.attributeString = [PLVSAImageEmotionMessageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSAImageEmotionMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSAQuoteMessageCell isModelValid:model]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
        model.attributeString = [PLVSAQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
        model.cellHeightForV = [PLVSAQuoteMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    } else if ([PLVSARewardMessageCell isModelValid:model]) {
        PLVRewardMessage *message = (PLVRewardMessage *)model.message;
        model.attributeString = [PLVSARewardMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVSARewardMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
        
    }
    
    [self.chatArray addObject:model];
    if (![PLVSARewardMessageCell isModelValid:model]) {
        [self.chatArrayWithoutReward addObject:model];
    }
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidResendMessage];
}

/// 接收到socket的公聊消息时
- (void)addPublicChatModels:(NSArray <PLVChatModel *> *)modelArray {
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        
        // 由于 cell显示需要的 消息多属性文本 计算比较耗时，所以，在 子线程 中提前计算出来；
        PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        if ([PLVSASpeakMessageCell isModelValid:model]) {
            PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
            model.attributeString = [PLVSASpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId prohibitWord:model.prohibitWord];
            model.cellHeightForV = [PLVSASpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
            
        } else if ([PLVSALongContentMessageCell isModelValid:model]) {
            model.attributeString = [PLVSALongContentMessageCell contentLabelAttributedStringWithModel:model loginUserId:roomUser.viewerId];
            model.cellHeightForV = [PLVSALongContentMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
            
        } else if ([PLVSAImageMessageCell isModelValid:model]) {
            model.attributeString = [PLVSAImageMessageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId];
            model.cellHeightForV = [PLVSAImageMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
            
        } else if ([PLVSAImageEmotionMessageCell isModelValid:model]) {
            model.attributeString = [PLVSAImageEmotionMessageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId];
            model.cellHeightForV = [PLVSAImageEmotionMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
            
        } else if ([PLVSAQuoteMessageCell isModelValid:model]) {
            PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
            model.attributeString = [PLVSAQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
            model.cellHeightForV = [PLVSAQuoteMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
            
        } else if ([PLVSARewardMessageCell isModelValid:model]) {
            PLVRewardMessage *message = (PLVRewardMessage *)model.message;
            model.attributeString = [PLVSARewardMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId];
            model.cellHeightForV = [PLVSARewardMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidth];
            
        }
        
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.chatArray addObject:model];
            if (![PLVSARewardMessageCell isModelValid:model]) {
                [self.chatArrayWithoutReward addObject:model];
            }
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
            [self.chatArrayWithoutReward removeObject:model];
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
    [self.chatArrayWithoutReward removeAllObjects];
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerDidMessageDeleted];
}

/// 历史聊天记录接口返回消息数组时
- (void)insertChatModels:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.chatArray insertObject:model atIndex:0];
            if (![PLVSARewardMessageCell isModelValid:model]) {
                [self.chatArrayWithoutReward insertObject:model atIndex:0];
            }
        }
    }
    BOOL first = ([self.chatArray count] <= [modelArray count]);
    dispatch_semaphore_signal(_chatArrayLock);
    
    [self notifyListenerLoadHistorySuccess:noMore firstTime:first];
}

/// 处理严禁词
- (void)markChatModelWithWaring:(NSString *)warning prohibitWord:(NSString *)word {
    if (![PLVFdUtil checkStringUseable:word]) { // 发送成功，以用**代替严禁词发出
        [self notifyListenerDidSendProhibitMessgae];
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
    
    NSArray *tempChatArrayWithoutReward = [self.chatArrayWithoutReward copy];
    for (PLVChatModel *model in tempChatArrayWithoutReward) {
        NSString *modelMsgId = [model msgId];
        // 含有严禁词且发送失败的消息，msgID为空
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
        // 该消息已标记为包含违规图片消息
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
    
    NSArray *tempChatArrayWithoutReward = [self.chatArrayWithoutReward copy];
    for (PLVChatModel *model in tempChatArrayWithoutReward) {
        // 该消息已标记为包含违规图片消息
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
    
    NSArray *tempCharArrayWithoutReward = [self.chatArrayWithoutReward copy];
    for (PLVChatModel *tempModel in tempCharArrayWithoutReward) {
        if (tempModel == model) {
            [self.chatArrayWithoutReward removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_chatArrayLock);
}


#pragma mark 发送PLVSAChatroomViewModelProtocol协议方法

- (void)notifyListenerDidSendMessage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModelDidSendMessage:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelDidSendMessage:self];
        });
    }
}

- (void)notifyListenerDidResendMessage {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidResendMessage:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelDidResendMessage:self];
        });
    }
}

- (void)notifyListenerDidSendProhibitMessgae {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModelDidSendProhibitMessgae:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelDidSendProhibitMessgae:self];
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

- (void)notifyListerDidMessageCountLimitedAutoDeleted {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModelDidMessageCountLimitedAutoDeleted:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModelDidMessageCountLimitedAutoDeleted:self];
        });
    }
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomViewModel:loadHistorySuccess:firstTime:)]) {
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

- (void)notifyListenerLoadImageEmotionsSuccess {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModel_loadImageEmotionSuccess:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_loadImageEmotionSuccess:self.imageEmotionArray];
        });
    }
}

- (void)notifyListenerLoadImageEmotionsFailure {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomViewModel_loadImageEmotionFailure)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomViewModel_loadImageEmotionFailure];
        });
    }
}

#pragma mark 定时上报登录用户

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

#pragma mark 公聊数据管理

- (void)publicChatManagerTimerAction {
    if (self.chatArray.count > kPLVSAMaxPublicChatMessageCount) {
        dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
        NSUInteger removalCount = self.chatArray.count - kPLVSAMaxPublicChatMessageCount;
        NSRange removalRange = NSMakeRange(0, removalCount);
        [self.chatArray removeObjectsInRange:removalRange];
        
        [self.chatArrayWithoutReward removeAllObjects];
        
        for (PLVChatModel *model in self.chatArray) {
            if (![PLVSARewardMessageCell isModelValid:model]) {
                [self.chatArrayWithoutReward addObject:model];
            }
        }
        
        NSTimeInterval lastTime =self.chatArray.firstObject.time;
        NSUInteger count = 0;
        for (PLVChatModel *model in self.chatArray) {
            if (!(model.time == lastTime)) {
                break;
            }
            count++;
        }
        [self.presenter updateHistoryLastTime:lastTime lastTimeMessageIndex:count];
        dispatch_semaphore_signal(_chatArrayLock);
        [self notifyListerDidMessageCountLimitedAutoDeleted];
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

- (void)chatroomPresenter_didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray {
    [self addPublicChatModels:modelArray];
}

- (void)chatroomPresenter_didMessageDeleted:(NSString *)msgId {
    [self deletePublicChatModelWithMsgId:msgId];
}

- (void)chatroomPresenter_didAllMessageDeleted {
    [self removeAllPublicChatModels];
}

- (void)chatroomPresenter_receiveWarning:(NSString *)warning prohibitWord:(NSString *)word {
    [self markChatModelWithWaring:warning prohibitWord:word];
}

- (void)chatroomPresenter_receiveImageWarningWithMsgId:(NSString *)msgId {
    [self markChatModelProhibitImageWithMsgId:msgId];
}

- (void)chatroomPresenter_loadImageEmotionsSuccess {
    [self notifyListenerLoadImageEmotionsSuccess];
}

- (void)chatroomPresenter_loadImageEmotionsFailure {
    [self notifyListenerLoadImageEmotionsFailure];
}

@end
