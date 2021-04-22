//
//  PLVChatroomPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVChatroomPresenter.h"
#import "PLVChatUser.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVQuoteMessage.h>
#import <PLVLiveScenesSDK/PLVSpeakMessage.h>
#import <PLVLiveScenesSDK/PLVImageMessage.h>
#import <PLVLiveScenesSDK/PLVCustomMessage.h>
#import <PLVLiveScenesSDK/PLVChatroomManager.h>
#import <PLVLiveScenesSDK/PLVSocketManager.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>

@interface PLVChatroomPresenter ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomManagerProtocol, // 聊天室SDK管理类协议
PLVRoomDataManagerProtocol  // 直播间数据管理器协议
>

#pragma mark socket数据缓冲
/// 消息缓存队列
@property (nonatomic, strong) NSMutableArray<PLVChatModel *> *chatCacheQueue;
/// 消息缓冲队列清零计时器，间隔0.5s清空消息缓冲队列并对外分发消息
@property (nonatomic, strong) NSTimer *chatCachTimer;

#pragma mark 历史聊天记录
/// 每次调用接口获取的聊天消息条数，默认20
@property (nonatomic, assign) NSUInteger eachLoadingHistoryCount;
/// 是否正在获取历史记录
@property (nonatomic, assign) BOOL loadingHistory;
/// 是否需要延迟请求历史记录，分房间开关为开且房间号为0时为YES
@property (nonatomic, assign) BOOL delayRequestHistory;
/// 获取历史记录成功的次数
@property (nonatomic, assign) NSInteger getHistoryTime;

@end

@implementation PLVChatroomPresenter {
    dispatch_semaphore_t _dataSourceLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - 生命周期

- (instancetype)init {
    return [self initWithLoadingHistoryCount:20 childRoomAllow:NO];
}

- (instancetype)initWithLoadingHistoryCount:(NSUInteger)count childRoomAllow:(BOOL)allow {
    self = [super init];
    if (self) {
        // 获取聊天消息条数初始化
        self.eachLoadingHistoryCount = MAX(1, count);
        
        // 聊天消息缓冲初始化
        _dataSourceLock = dispatch_semaphore_create(1);
        self.chatCacheQueue = [NSMutableArray arrayWithCapacity:100];
        self.chatCachTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                              target:self
                                                            selector:@selector(chatCachTimerAction)
                                                            userInfo:nil
                                                             repeats:YES];
        
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        PLVRoomUser *roomUser = roomData.roomUser;
        
        // Socket 登录管理
        PLVSocketUserType userType = [PLVRoomUser sockerUserTypeWithRoomUserType:roomUser.viewerType];
        [PLVSocketManager sharedManager].allowChildRoom = allow;
        [[PLVSocketManager sharedManager] loginWithChannelId:roomData.channelId viewerId:roomUser.viewerId viewerName:roomUser.viewerName avatarUrl:roomUser.viewerAvatar actor:nil userType:userType];
        
        // 监听socket消息
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
        
        // 监听聊天室SDK管理类回调
        PLVChatroomManager *chatroomManager = [PLVChatroomManager sharedManager];
        [chatroomManager setupWithDelegate:self channelId:roomData.channelId];
        
        if (roomData.channelInfo) {
            chatroomManager.sessionId = roomData.channelInfo.sessionId;
        }
        
        // 监听直播间数据管理器回调
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT)];
        
        [self loadHistory];
    }
    return self;
}

- (void)destroy {
    [[PLVRoomDataManager sharedManager] removeDelegate:self];
    [[PLVChatroomManager sharedManager] destroy];
    [[PLVSocketManager sharedManager] removeDelegate:self];
    
    self.delegate = nil;
    [self.chatCachTimer invalidate];
    self.chatCachTimer = nil;
    
    self.getHistoryTime = 0;
}

#pragma mark - 发送消息

/// 根据roomData生成当前用户模型
- (PLVChatUser *)loginChatUser {
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    
    PLVChatUser *user = [[PLVChatUser alloc] init];
    user.userId = roomUser.viewerId;
    user.userName = roomUser.viewerName;
    user.avatarUrl = roomUser.viewerAvatar;
    user.userType = roomUser.viewerType;
    return user;
}

#pragma mark 提问消息

- (PLVChatModel *)sendQuesstionMessage:(NSString *)content {
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    if (![PLVChatroomManager sharedManager].online) {
        return nil;
    }
    
    if (content && [content isKindOfClass:[NSString class]] && content.length > 0) {
        content = [content stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        content = [content stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    }
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = [self loginChatUser];
    model.message = content;
    
    BOOL success = [[PLVChatroomManager sharedManager] sendQuesstionMessage:content];
    return success ? model : nil;
}

#pragma mark 文本消息

- (PLVChatModel *)sendSpeakMessage:(NSString *)content {
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    if ([PLVChatroomManager sharedManager].closeRoom || ![PLVChatroomManager sharedManager].online) {
        return nil;
    }
    
    PLVSpeakMessage *message = [[PLVSpeakMessage alloc] init];
    message.content = content;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = [self loginChatUser];
    model.message = message;
    
    if ([PLVChatroomManager sharedManager].banned) { // 禁言消息只显示到本地，不推给服务器
        return model;
    }
    
    BOOL success = [[PLVChatroomManager sharedManager] sendSpeakMessage:message needIdCallback:YES];
    return success ? model : nil;
}

#pragma mark 图片消息

- (PLVChatModel *)sendImageMessage:(UIImage *)image {
    if (!image || ![image isKindOfClass:[UIImage class]]) {
        return nil;
    }
    if ([PLVChatroomManager sharedManager].closeRoom || ![PLVChatroomManager sharedManager].online) {
        return nil;
    }
    
    PLVImageMessage *message = [[PLVImageMessage alloc] init];
    message.image = image;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = [self loginChatUser];
    model.message = message;
    
    if (![PLVChatroomManager sharedManager].banned) { // 禁言消息只显示到本地，不推给服务器
        [[PLVChatroomManager sharedManager] sendImageMessage:message];
    }
    return model;
}

#pragma mark 自定义消息

- (BOOL)sendCustomMessageWithEvent:(NSString *)event
                              data:(NSDictionary *)data
                               tip:(NSString * _Nullable)tip
                          emitMode:(int)emitMode {
    if (!event || ![event isKindOfClass:[NSString class]] || event.length == 0 ||
        !data || ![data isKindOfClass:[NSDictionary class]] || [data count] == 0 ||
        !tip || ![tip isKindOfClass:[NSString class]] || tip.length == 0) {
        return NO;
    }
    if ([PLVChatroomManager sharedManager].closeRoom || ![PLVChatroomManager sharedManager].online) {
        return nil;
    }
    
    PLVCustomMessage *message = [[PLVCustomMessage alloc] init];
    message.event = event;
    message.data = data;
    message.tip = tip;
    message.emitMode = emitMode;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = [self loginChatUser];
    model.message = message;
    
    BOOL success = [[PLVChatroomManager sharedManager] sendCustonMessage:message];
    return success;
}

#pragma mark 生成教师回复信息

- (void)createAnswerChatModel {
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
    jsonDict[@"s_userId"] = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
    jsonDict[@"content"] = @"同学，您好！请问有什么问题吗？";
    jsonDict[@"user"] = @{@"nick": @"讲师",
                          @"pic" : @"https://livestatic.polyv.net/assets/images/teacher.png",
                          @"userType" : @"teacher"};
    [self teacherAnswerEvent:jsonDict];
}

#pragma mark 点赞消息

- (void)sendLike {
    // 更新 roomData 点赞属性 likeCount
    [self addLikeCount:1];
    // 由 SDK 发送点赞
    [[PLVChatroomManager sharedManager] sendLikeEvent];
}

#pragma mark - 获取历史聊天消息

- (void)loadHistory {
    if (self.loadingHistory) {
        return;
    }
    self.loadingHistory = YES;
    
    __weak typeof(self) weakSelf = self;
    NSString *roomId = [PLVSocketManager sharedManager].roomId;
    if ((!roomId || roomId.length == 0) && [PLVSocketManager sharedManager].allowChildRoom) {
        self.delayRequestHistory = YES;
        self.loadingHistory = NO;
        return;
    }
    
    if (!roomId || roomId.length == 0) {
        roomId = [PLVRoomDataManager sharedManager].roomData.channelId;
    }
    NSInteger startIndex = self.getHistoryTime * self.eachLoadingHistoryCount;
    NSInteger endIndex = (self.getHistoryTime + 1) * self.eachLoadingHistoryCount;
    [PLVLiveVideoAPI requestChatRoomHistoryWithRoomId:[roomId longLongValue] startIndex:startIndex endIndex:endIndex completion:^(NSArray * _Nonnull historyList) {
        
        BOOL success = (historyList && [historyList isKindOfClass:[NSArray class]]);
        if (success) {
            if ([historyList count] > 0) {
                NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[historyList count]];
                for (NSDictionary *dict in historyList) {
                    PLVChatModel *model = [weakSelf modelWithHistoryDict:dict];
                    if (model) {
                        [tempArray addObject:model];
                    }
                }
                BOOL noMoreHistory = [historyList count] < weakSelf.eachLoadingHistoryCount;
                [weakSelf notifyListenerLoadHistorySuccess:[tempArray copy] noMore:noMoreHistory];
            } else {
                [weakSelf notifyListenerLoadHistorySuccess:@[] noMore:YES];
            }
        } else {
            [weakSelf notifyListenerLoadHistoryFailure];
        }
        weakSelf.getHistoryTime++;
        weakSelf.loadingHistory = NO;
    } failure:^(NSError * _Nonnull error) {
        [weakSelf notifyListenerLoadHistoryFailure];
        weakSelf.loadingHistory = NO;
    }];
}

#pragma mark 历史聊天消息数据解析

/// 将 json 数据转换为消息模型 PLVChatModel 对象
- (PLVChatModel *)modelWithHistoryDict:(NSDictionary *)dict {
    PLVChatModel *model = nil;
    
    NSString *msgType = [self messageTypeWithHistoryDict:dict];
    
    if ([msgType isEqualToString:@"speak"]) {
        return [self modelSpeakChatDict:dict];
    } else if ([msgType isEqualToString:@"quote"]) {
        return [self modelQuoteChatDict:dict];
    } else if ([msgType isEqualToString:@"image"]) {
        return [self modelImageChatDict:dict];
    }
    return model;
}

/// 历史聊天消息json数据初步解析，返回消息类型
/// 图片消息 @"image"
/// 文本消息 @"speak"
/// 引用消息 @"quote"
- (NSString *)messageTypeWithHistoryDict:(NSDictionary *)dict {
    NSString *msgSource = PLV_SafeStringForDictKey(dict, @"msgSource");
    NSString *msgType = PLV_SafeStringForDictKey(dict, @"msgType");
    
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    NSString *uid = PLV_SafeStringForDictKey(userDict, @"uid");
    
    if (msgSource && [msgSource isEqualToString:@"chatImg"]) { // 图片消息
        return @"image";
    } else if (!msgType && !msgSource && ![uid isEqualToString:@"1"] && ![uid isEqualToString:@"2"]) { // 文本/引用消息
        if (PLV_SafeStringForDictKey(dict, @"content")) {
            NSDictionary *quoteDict = PLV_SafeDictionaryForDictKey(dict, @"quote");
            return quoteDict ? @"quote" : @"speak";
        }
    }
    return nil;
}

- (PLVChatModel *)modelSpeakChatDict:(NSDictionary *)dict {
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    
    NSString *msgId = PLV_SafeStringForDictKey(dict, @"id");
    NSString *content = PLV_SafeStringForDictKey(dict, @"content");
    PLVSpeakMessage *message = [[PLVSpeakMessage alloc] init];
    message.msgId = msgId;
    message.content = content;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = user;
    model.message = message;
    return model;
}

- (PLVChatModel *)modelQuoteChatDict:(NSDictionary *)dict {
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    
    NSString *msgId = PLV_SafeStringForDictKey(dict, @"id");
    NSString *content = PLV_SafeStringForDictKey(dict, @"content");
    NSDictionary *quoteDict = PLV_SafeDictionaryForDictKey(dict, @"quote");
    NSString *quoteUserId = PLV_SafeStringForDictKey(quoteDict, @"userId");
    NSString *quoteUserName = PLV_SafeStringForDictKey(quoteDict, @"nick");
    NSDictionary *quoteImageDict = PLV_SafeDictionaryForDictKey(quoteDict, @"image");
    
    PLVQuoteMessage *message = [[PLVQuoteMessage alloc] init];
    message.msgId = msgId;
    message.content = content;
    message.quoteUserId = quoteUserId;
    message.quoteUserName = quoteUserName;
    if (quoteImageDict) {
        NSString *imageUrl = PLV_SafeStringForDictKey(quoteImageDict, @"url");
        message.quoteImageUrl = [PLVFdUtil packageURLStringWithHTTPS:imageUrl];
        
        CGFloat width = PLV_SafeFloatForDictKey(quoteImageDict, @"width");
        CGFloat height = PLV_SafeFloatForDictKey(quoteImageDict, @"height");
        message.quoteImageSize = CGSizeMake(width, height);
    } else {
        message.quoteContent = PLV_SafeStringForDictKey(quoteDict, @"content");
    }
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = user;
    model.message = message;
    return model;
}

- (PLVChatModel *)modelImageChatDict:(NSDictionary *)dict {
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    
    NSString *msgId = PLV_SafeStringForDictKey(dict, @"id");
    NSDictionary *contentDict = PLV_SafeDictionaryForDictKey(dict, @"content");
    NSString *imageUrl = PLV_SafeStringForDictKey(contentDict, @"uploadImgUrl");
    NSString *imageId = PLV_SafeStringForDictKey(contentDict, @"id");
    NSDictionary *sizeDict = PLV_SafeDictionaryForDictKey(contentDict, @"size");
    CGFloat width = PLV_SafeFloatForDictKey(sizeDict, @"width");
    CGFloat height = PLV_SafeFloatForDictKey(sizeDict, @"height");
    
    PLVImageMessage *message = [[PLVImageMessage alloc] init];
    message.msgId = msgId;
    message.imageId = imageId;
    message.imageUrl = imageUrl;
    message.imageSize = CGSizeMake(width, height);
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = user;
    model.message = message;
    return model;
}

#pragma mark - Listener

- (void)notifyListenerDidReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray {
    if (!modelArray || ![modelArray isKindOfClass:[NSArray class]] || [modelArray count] == 0) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_didReceiveChatModels:)]) {
        [self.delegate chatroomPresenter_didReceiveChatModels:modelArray];
    }
}

- (void)notifyListenerDidReceiveAnswerChatModel:(PLVChatModel *)model {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_didReceiveAnswerChatModel:)]) {
        [self.delegate chatroomPresenter_didReceiveAnswerChatModel:model];
    }
}

- (void)notifyListenerDidMessageDeleted:(NSString *)msgId {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_didMessageDeleted:)]) {
        [self.delegate chatroomPresenter_didMessageDeleted:msgId];
    }
}

- (void)notifyListenerDidAllMessageDeleted {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_didAllMessageDeleted)]) {
        [self.delegate chatroomPresenter_didAllMessageDeleted];
    }
}

- (void)notifyListenerLoadHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_loadHistorySuccess:noMore:)]) {
        [self.delegate chatroomPresenter_loadHistorySuccess:modelArray noMore:noMore];
    }
}

- (void)notifyListenerLoadHistoryFailure {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_loadHistoryFailure)]) {
        [self.delegate chatroomPresenter_loadHistoryFailure];
    }
}

#pragma mark - 更新 RoomData 属性

- (void)updateOnlineCount:(NSInteger)onlineCount {
    [PLVRoomDataManager sharedManager].roomData.onlineCount = onlineCount;
}

- (void)increaseWatchCount {
    [PLVRoomDataManager sharedManager].roomData.watchCount++;
}

- (void)addLikeCount:(NSInteger)likeCount {
    [PLVRoomDataManager sharedManager].roomData.likeCount += likeCount;
}

#pragma mark - PLVRoomDataManagerProtocol

- (void)roomDataManager_didChannelInfoChanged:(PLVChannelInfoModel *)channelInfo {
    [PLVChatroomManager sharedManager].sessionId = channelInfo.sessionId;
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
    if (self.delayRequestHistory) {
        [self loadHistory];
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
    } else if ([subEvent isEqualToString:@"LOGOUT"]) { // someone logged in chatroom
        [self logoutEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"LIKES"]) {
        [self likesEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"SPEAK"]) {  // someone speaks
        [self speakMessageEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"CHAT_IMG"]) { // someone send a picture message
        [self imageMessageEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"T_ANSWER"]) {
        [self teacherAnswerEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"REMOVE_CONTENT"]) { // admin deleted a message
        [self removeContentEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"REMOVE_HISTORY"]) { // admin emptied the chatroom
        [self removeHistoryEvent];
    }
}

#pragma mark socket 数据解析

/// 有用户登陆
- (void)loginEvent:(NSDictionary *)data {
    NSInteger onlineCount = PLV_SafeIntegerForDictKey(data, @"onlineUserNumber");
    [self updateOnlineCount:onlineCount];
    
    NSDictionary *user = PLV_SafeDictionaryForDictKey(data, @"user");
    NSString *userId = PLV_SafeStringForDictKey(user, @"userId");
    if (![self isLoginUser:userId]) {
        [self increaseWatchCount]; // 他人登陆时，观看热度加1
    }
}

/// 有用户登出
- (void)logoutEvent:(NSDictionary *)data {
    NSInteger onlineCount = PLV_SafeIntegerForDictKey(data, @"onlineUserNumber");
    [self updateOnlineCount:onlineCount];
}

/// 有用户点赞
- (void)likesEvent:(NSDictionary *)data {
    NSString *userId = PLV_SafeStringForDictKey(data, @"userId");
    if ([self isLoginUser:userId]) {
        return;
    }
    NSUInteger likeCount = PLV_SafeIntegerForDictKey(data, @"count");
    likeCount = MIN(5, likeCount);
    [self addLikeCount:likeCount];
}

/// 有用户发送文本/引用消息
- (void)speakMessageEvent:(NSDictionary *)data {
    NSDictionary *user = PLV_SafeDictionaryForDictKey(data, @"user");
    NSString *status = PLV_SafeStringForDictKey(data, @"status");
    if (status || ![user isKindOfClass:NSDictionary.class]) { // status存在时为单播消息
        return;
    }
    
    NSString *userId = PLV_SafeStringForDictKey(user, @"userId");
     if ([self isLoginUser:userId]) { // 过滤掉自己的消息（开启聊天室审核后，服务器会广播所有审核后的消息，包含自己发送的消息）
        return;
    }
        
    PLVChatModel *model = [[PLVChatModel alloc] init];
    PLVChatUser *chatUser = [[PLVChatUser alloc] initWithUserInfo:user];
    model.user = chatUser;
    
    NSArray *values = PLV_SafeArraryForDictKey(data, @"values");
    NSString *msgId = PLV_SafeStringForDictKey(data, @"id");
    NSDictionary *quote = PLV_SafeDictionaryForDictKey(data, @"quote");
    NSString *content = (NSString *)values.firstObject;
    
    if (quote) {
        PLVQuoteMessage *message = [[PLVQuoteMessage alloc] init];
        message.msgId = msgId;
        message.content = content;
        message.quoteUserName = PLV_SafeStringForDictKey(quote, @"nick");
        NSDictionary *quoteImageDict = PLV_SafeDictionaryForDictKey(quote, @"image");
        if (quoteImageDict) {
            NSString *imageUrl = PLV_SafeStringForDictKey(quoteImageDict, @"url");
            message.quoteImageUrl = [PLVFdUtil packageURLStringWithHTTPS:imageUrl];
            CGFloat width = PLV_SafeFloatForDictKey(quoteImageDict, @"width");
            CGFloat height = PLV_SafeFloatForDictKey(quoteImageDict, @"height");
            message.quoteImageSize = CGSizeMake(width, height);
        } else {
            message.quoteContent = PLV_SafeStringForDictKey(quote, @"content");
        }
        model.message = message;
        [self cachChatModel:model];
    } else {
        PLVSpeakMessage *message = [[PLVSpeakMessage alloc] init];
        message.msgId = msgId;
        message.content = content;
        model.message = message;
        [self cachChatModel:model];
    }
}

/// 有用户发送图片消息
- (void)imageMessageEvent:(NSDictionary *)data {
    NSDictionary *user = PLV_SafeDictionaryForDictKey(data, @"user");
    NSArray *values = PLV_SafeArraryForDictKey(data, @"values");
    if (!user || !values) {
        return;
    }
    
    NSString *userId = PLV_SafeStringForDictKey(user, @"userId");
    if ([self isLoginUser:userId]) {
        return;
    }
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    PLVChatUser *chatUser = [[PLVChatUser alloc] initWithUserInfo:user];
    model.user = chatUser;
    
    PLVImageMessage *message = [[PLVImageMessage alloc] init];
    message.msgId = PLV_SafeStringForDictKey(data, @"id");
    
    NSDictionary *content = PLV_SafeDictionaryForValue(values.firstObject);
    message.imageId = PLV_SafeStringForDictKey(content, @"id");
    
    NSString *imageUrl = PLV_SafeStringForDictKey(content, @"uploadImgUrl");
    if ([imageUrl hasPrefix:@"http:"]) {
        message.imageUrl = [imageUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    } else {
        message.imageUrl = imageUrl;
    }
    
    NSDictionary *sizeDict = PLV_SafeDictionaryForDictKey(content, @"size");
    CGFloat width = PLV_SafeFloatForDictKey(sizeDict, @"width");
    CGFloat height = PLV_SafeFloatForDictKey(sizeDict, @"height");
    message.imageSize = CGSizeMake(width, height);
    model.message = message;
    [self cachChatModel:model];
}

/// 收到私聊回复
- (void)teacherAnswerEvent:(NSDictionary *)data {
    NSString *studentUserId = PLV_SafeStringForDictKey(data, @"s_userId");
    if ([self isLoginUser:studentUserId]) {
        
        NSDictionary *user = PLV_SafeDictionaryForDictKey(data, @"user");
        NSString *content = PLV_SafeStringForDictKey(data, @"content");
        if (content && [content isKindOfClass:[NSString class]] && content.length > 0) {
            content = [content stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
            content = [content stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        }
        
        PLVChatModel *model = [[PLVChatModel alloc] init];
        PLVChatUser *chatUser = [[PLVChatUser alloc] initWithUserInfo:user];
        model.user = chatUser;
        model.message = content;
        [self notifyListenerDidReceiveAnswerChatModel:model];
    }
}

/// 删除一条消息事件
- (void)removeContentEvent:(NSDictionary *)data {
    NSString *msgId = PLV_SafeStringForDictKey(data, @"id");
    [self notifyListenerDidMessageDeleted:msgId];
}

/// 清空所有消息事件
- (void)removeHistoryEvent {
    [self notifyListenerDidAllMessageDeleted];
}

#pragma mark socket 数据缓冲

- (void)cachChatModel:(PLVChatModel *)model {
    if (!model) {
        return;
    }
    
    dispatch_semaphore_wait(_dataSourceLock, DISPATCH_TIME_FOREVER);
    [self.chatCacheQueue addObject:model];
    dispatch_semaphore_signal(_dataSourceLock);
}

- (void)chatCachTimerAction {
    dispatch_semaphore_wait(_dataSourceLock, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [self.chatCacheQueue copy];
    [self.chatCacheQueue removeAllObjects];
    [self notifyListenerDidReceiveChatModels:tempArray];
    dispatch_semaphore_signal(_dataSourceLock);
}

#pragma mark - PLVChatroomManagerProtocol

- (void)chatroomManager_receiveWarning:(NSString *)message prohibitWord:(NSString *)word {
    NSString *tip = [NSString stringWithFormat:@"%@: %@", message, word];
    NSLog(@"PLVChatroomPresenter - %@", tip);
}

- (void)chatroomManager_sendImageMessageFaild:(PLVImageMessage *)message {
    
}

- (void)chatroomManager_sendImageMessageSuccess:(PLVImageMessage *)message {
    
}

- (void)chatroomManager_sendImageMessage:(PLVImageMessage *)message updateProgress:(CGFloat)progress {
    
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
