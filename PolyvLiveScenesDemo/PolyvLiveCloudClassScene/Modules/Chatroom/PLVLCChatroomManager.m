//
//  PLVLCChatroomManager.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/26.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCChatroomManager.h"

@interface PLVLCChatroomManager ()<
PLVSocketListenerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVLiveRoomData *roomData; /// 直播间数据模型

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

@property (nonatomic, strong) NSPointerArray *listeners; /// 监听者的弱引用数组

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

@implementation PLVLCChatroomManager {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _publicChatArrayLock;
    dispatch_semaphore_t _privateChatArrayLock;
    dispatch_semaphore_t _loginArrayLock;
    dispatch_semaphore_t _managerMessageArrayLock;
    dispatch_semaphore_t _danmuArrayLock;
}

#pragma mark - 生命周期

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static PLVLCChatroomManager *mananger = nil;
    dispatch_once(&onceToken, ^{
        mananger = [[self alloc] init];
    });
    return mananger;
}

- (void)setupRoomData:(PLVLiveRoomData *)roomData {
    self.roomData = roomData;
    
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
    self.presenter = [[PLVChatroomPresenter alloc] initWithRoomData:roomData];
    self.presenter.delegate = self;
    
    // 监听socket消息
    [[PLVSocketWrapper sharedSocketWrapper] addListener:self];
    
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

- (void)destroy {
    [[PLVSocketWrapper sharedSocketWrapper] removeListener:self];
    [self removeAllListeners];
    [self.presenter destroy];
    
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
    self.presenter.eachLoadingHistoryCount = 20;
    [self.presenter loadHistory];
}

#pragma mark - 发送消息

- (BOOL)sendQuesstionMessage:(NSString *)content {
    if (!content || content.length == 0) {
        return nil;
    }
    PLVChatModel *model = [self.presenter sendQuesstionMessage:content];
    if (model) {
        [self addPrivateChatModel:model local:YES];
    }
    return model != nil;
}

- (BOOL)sendSpeakMessage:(NSString *)content {
    if (!content || content.length == 0) {
        return nil;
    }
    PLVChatModel *model = [self.presenter sendSpeakMessage:content];
    if (model) {
        [self addPublicChatModel:model];
        [self cacheDanmu:@[model]];
    }
    return model != nil;
}

- (BOOL)sendImageMessage:(UIImage *)image {
    if (!image) {
        return nil;
    }
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
        [self notifyListenerDidSendQuestionMessage];
    } else {
        [self notifyListenerDidReceiveAnswerMessage];
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
    
    [self notifyListenerDidSendMessage:model];
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
    
    [self notifyListenerDidReceiveMessages:modelArray];
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
            [self.publicChatArray insertObject:model atIndex:0];
            PLVChatUser *user = model.user;
            if (user.specialIdentity || [self isLoginUser:user.userId]) {
                [self.partOfPublicChatArray insertObject:model atIndex:0];
            }
        }
    }
    BOOL first = ([self.publicChatArray count] <= [modelArray count]);
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyListenerLoadHistorySuccess:noMore firstTime:first];
}

#pragma mark - Listener

- (void)addListener:(id<PLVLCChatroomManagerProtocol>)listener {
    if (listener) {
        if (!self.listeners) {
            self.listeners = [NSPointerArray weakObjectsPointerArray];
        }
        if (![self.listeners.allObjects containsObject:listener]) {
            [self.listeners addPointer:(__bridge void * _Nullable)(listener)];
        }
    }
}

- (void)removeListener:(id<PLVLCChatroomManagerProtocol>)listener {
    if (listener) {
        NSUInteger index = [self.listeners.allObjects indexOfObject:listener];
        if (index >= 0 && index < [self.listeners count]) {
            [self.listeners removePointerAtIndex:index];
        }
    }
}

- (void)removeAllListeners {
    NSUInteger count = self.listeners.count;
    for (int i = 0; i < count; i ++) {
        [self.listeners removePointerAtIndex:0];
    }
}

- (void)notifyListenerDidSendQuestionMessage {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_didSendQuestionMessage)]) {
            [listener chatroomManager_didSendQuestionMessage];
        }
    }
}

- (void)notifyListenerDidReceiveAnswerMessage {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_didReceiveAnswerMessage)]) {
            [listener chatroomManager_didReceiveAnswerMessage];
        }
    }
}

- (void)notifyListenerDidSendMessage:(PLVChatModel *)model {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_didSendMessage:)]) {
            [listener chatroomManager_didSendMessage:model];
        }
    }
}

- (void)notifyListenerDidReceiveMessages:(NSArray <PLVChatModel *> *)modelArray {
    if (!modelArray || ![modelArray isKindOfClass:[NSArray class]] || [modelArray count] == 0) {
        return;
    }
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_didReceiveMessages:)]) {
            [listener chatroomManager_didReceiveMessages:modelArray];
        }
    }
}

- (void)notifyListenerDidMessageDeleted {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_didMessageDeleted)]) {
            [listener chatroomManager_didMessageDeleted];
        }
    }
}

- (void)notifyListenerLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_loadHistorySuccess:firstTime:)]) {
            [listener chatroomManager_loadHistorySuccess:noMore firstTime:first];
        }
    }
}

- (void)notifyListenerLoadHistoryFailure {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_loadHistoryFailure)]) {
            [listener chatroomManager_loadHistoryFailure];
        }
    }
}

- (void)notifyListenerForLoginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_loginUsers:)]) {
            [listener chatroomManager_loginUsers:userArray];
        }
    }
}

- (void)notifyListenerForManagerMessage:(NSString *)content {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_managerMessage:)]) {
            [listener chatroomManager_managerMessage:content];
        }
    }
}

- (void)notifyListenerForDanmu:(NSString *)content {
    for (id<PLVLCChatroomManagerProtocol> listener in self.listeners) {
        if ([listener respondsToSelector:@selector(chatroomManager_danmu:)]) {
            [listener chatroomManager_danmu:content];
        }
    }
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
        [self notifyListenerForLoginUsers:nil];
    } else {
        if ([self.loginUserArray count] >= 10) {
            NSArray *loginUserArray = [self.loginUserArray copy];
            [self notifyListenerForLoginUsers:loginUserArray];
            
            dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
            [self.loginUserArray removeAllObjects];
            dispatch_semaphore_signal(_loginArrayLock);
        } else if ([self.loginUserArray count] > 0) {
            PLVChatUser *user = self.loginUserArray[0];
            [self notifyListenerForLoginUsers:@[user]];
            
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
        if (model.user.userType == PLVLiveUserTypeManager &&
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
        [self notifyListenerForManagerMessage:content];
        
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
        [self notifyListenerForDanmu:content];
        
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

#pragma mark - PLVSocketListenerProtocol

- (void)socket:(id<PLVSocketIOProtocol>)socket didReceiveMessage:(nonnull NSString *)string jsonDict:(nonnull NSDictionary *)jsonDict {
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:@"LOGIN"]) {   // someone logged in chatroom
        [self loginEvent:jsonDict];
    }
}

- (void)socket:(id<PLVSocketIOProtocol>)socket didStatusChange:(PLVSocketStatus)status string:(NSString *)string {
    BOOL loginSuccess = (status == PLVSocketStatusLoginSuccess);
    if (loginSuccess) { // 登陆成功再加载聊天记录，否则分房间开启时，会使用频道号而不是房间号
        [self loadHistory];
    }
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
    
    BOOL isLoginUser = [userId isEqualToString:self.roomData.userIdForWatchUser];
    return isLoginUser;
}

@end
