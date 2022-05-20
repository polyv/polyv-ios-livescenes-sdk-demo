//
//  PLVChatroomPresenter.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVChatroomPresenter.h"
#import "PLVChatUser.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFdUtil.h>

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

#pragma mark 内部属性
///图片表情的数据
@property (nonatomic, strong) NSArray *imageEmotionArray;
/// 当前聊天室消息登录用户模型
@property (nonatomic, strong) PLVChatUser *loginChatUser;

#pragma mark 内部只读属性
/// socket处于已连接且登陆成功的状态时为YES，默认为NO
@property (nonatomic, assign, readonly) BOOL online;

#pragma mark 提醒消息历史聊天记录
/// 是否正在获取提醒消息历史记录
@property (nonatomic, assign) BOOL loadingRemindHistory;
/// 获取提醒消息历史记录成功的次数
@property (nonatomic, assign) NSInteger getRemindHistoryTime;

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

- (instancetype)initWithLoadingHistoryCount:(NSUInteger)count {
    return [self initWithLoadingHistoryCount:count childRoomAllow:NO];
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
        
        // Socket 登录管理
        [PLVSocketManager sharedManager].allowChildRoom = allow;
        
        // 监听socket消息
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
        
        // 监听聊天室SDK管理类回调
        PLVChatroomManager *chatroomManager = [PLVChatroomManager sharedManager];
        chatroomManager.specialRole = [PLVRoomUser isSpecialIdentityWithUserType:roomData.roomUser.viewerType];
        [chatroomManager setupWithDelegate:self channelId:roomData.channelId];
        
        if (roomData.sessionId) {
            chatroomManager.sessionId = roomData.sessionId;
        }
        
        // 监听直播间数据管理器回调
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT)];
        
        [self loadHistory];
        if (!roomData.inHiClassScene) { //互动学堂场景无图片表情功能
            [self loadImageEmotions];
        }
    }
    return self;
}

- (void)setCourseCode:(NSString *)courseCode lessonId:(NSString *)lessonId {
    [PLVSocketManager sharedManager].vclassDomain = YES;
    [PLVSocketManager sharedManager].courseCode = courseCode;
    [PLVSocketManager sharedManager].lessonId = lessonId;
}

- (void)login {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVRoomUser *roomUser = roomData.roomUser;
    PLVSocketUserType userType = [PLVRoomUser sockerUserTypeWithRoomUserType:roomUser.viewerType];
    //新增自定义参数字典，如果未传递则传空
    NSDictionary *extraParam = @{
        @"liveParam4" : roomData.customParam.liveParam4 ? : @"",
        @"liveParam5" : roomData.customParam.liveParam5 ? : @""
    };
    // Socket 登录管理
    [[PLVSocketManager sharedManager] loginWithChannelId:roomData.channelId
                                                viewerId:roomUser.viewerId
                                              viewerName:roomUser.viewerName
                                               avatarUrl:roomUser.viewerAvatar
                                              extraParam:extraParam
                                                   actor:roomUser.actor
                                                userType:userType];
}

- (void)emitLoginEvent {
    [[PLVSocketManager sharedManager] emitLoginEvent];
}

- (void)destroy {
    [[PLVRoomDataManager sharedManager] removeDelegate:self];
    [[PLVChatroomManager sharedManager] destroy];
    [[PLVSocketManager sharedManager] removeDelegate:self];
    
    self.delegate = nil;
    [self.chatCachTimer invalidate];
    self.chatCachTimer = nil;
    
    self.getHistoryTime = 0;
    self.getRemindHistoryTime = 0;
}

#pragma mark - Getter & Setter

- (BOOL)specialRole {
    return [PLVChatroomManager sharedManager].specialRole;
}

- (BOOL)online {
    return [PLVChatroomManager sharedManager].online;
}

- (PLVChatUser *)loginChatUser {
    if (!_loginChatUser) {
        _loginChatUser = [[PLVChatUser alloc] init];
    }
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    _loginChatUser.userId = roomUser.viewerId;
    _loginChatUser.userName = roomUser.viewerName;
    _loginChatUser.avatarUrl = roomUser.viewerAvatar;
    _loginChatUser.userType = roomUser.viewerType;
    _loginChatUser.actor = roomUser.actor;
    return _loginChatUser;
}

#pragma mark - 发送消息

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
    model.user = self.loginChatUser;
    model.message = content;
    
    BOOL success = [[PLVChatroomManager sharedManager] sendQuesstionMessage:content];
    return success ? model : nil;
}

#pragma mark 文本消息

- (PLVChatModel *)sendSpeakMessage:(NSString *)content {
    return [self sendSpeakMessage:content replyChatModel:nil];;
}

- (PLVChatModel *)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    return [self sendSpeakMessage:content replyChatModel:replyChatModel source:nil];
}

- (PLVChatModel *)sendRemindSpeakMessage:(NSString *)content {
    return [self sendSpeakMessage:content replyChatModel:nil source:@"extend"]; // source字段值为"extend"表示为：提醒消息
}

- (PLVChatModel *)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel source:(NSString * _Nullable)source {
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = self.loginChatUser;
    
    PLVSpeakMessage *message = [[PLVSpeakMessage alloc] init];
    message.content = content;
    message.source = source;
    model.message = message;

    if (replyChatModel && replyChatModel.message &&
        ([replyChatModel.message isKindOfClass:[PLVSpeakMessage class]] ||
         [replyChatModel.message isKindOfClass:[PLVImageMessage class]] ||
         [replyChatModel.message isKindOfClass:[PLVImageEmotionMessage class]] ||
         [replyChatModel.message isKindOfClass:[PLVQuoteMessage class]])) {
        PLVQuoteMessage *message = [[PLVQuoteMessage alloc] init];
        message.content = content;
        message.quoteUserId = replyChatModel.user.userId;
        message.quoteUserName = replyChatModel.user.userName;
        if ([replyChatModel.message isKindOfClass:[PLVSpeakMessage class]]) {
            PLVSpeakMessage *speakMessage = replyChatModel.message;
            message.quoteMsgId = speakMessage.msgId;
            message.quoteContent = speakMessage.content;
        } else if ([replyChatModel.message isKindOfClass:[PLVImageMessage class]]) {
            PLVImageMessage *imageMessage = replyChatModel.message;
            message.quoteMsgId = imageMessage.msgId;
            message.quoteImageUrl = imageMessage.imageUrl;
            message.quoteImageSize = imageMessage.imageSize;
        } else if ([replyChatModel.message isKindOfClass:[PLVImageEmotionMessage class]]) {
            PLVImageEmotionMessage *imageMessage = replyChatModel.message;
            message.quoteMsgId = imageMessage.msgId;
            message.quoteImageUrl = imageMessage.imageUrl;
            message.quoteImageSize = imageMessage.imageSize;
        } else if ([replyChatModel.message isKindOfClass:[PLVQuoteMessage class]]) {
            PLVQuoteMessage *quoteMessage = replyChatModel.message;
            message.quoteMsgId = quoteMessage.msgId;
            message.quoteContent = quoteMessage.content;
        }
        model.message = message;
    }
    
    if ([PLVChatroomManager sharedManager].banned) { // 禁言消息只显示到本地，不推给服务器
        return model;
    }
    
    model.msgState = PLVChatMsgStateSending;
    BOOL success = NO;
    if ([model.message isKindOfClass:[PLVSpeakMessage class]]) {
        success  = [[PLVChatroomManager sharedManager] sendSpeakMessage:model.message callback:^(NSString * _Nonnull msgId) {
            model.msgState = PLVChatMsgStateSuccess;
        }];
    } else if ([model.message isKindOfClass:[PLVQuoteMessage class]]) {
        success  = [[PLVChatroomManager sharedManager] sendQuoteMessage:model.message callback:^(NSString * _Nonnull msgId) {
            model.msgState = PLVChatMsgStateSuccess;
        }];
    }
    if (!success) {
        model.msgState = PLVChatMsgStateFail;
    }
    return model;
}

#pragma mark 图片消息

- (PLVChatModel *)sendImageMessage:(UIImage *)image {
    return [self sendImageMessage:image source:nil];
}

- (PLVChatModel *)sendRemindImageMessage:(UIImage *)image {
    return [self sendImageMessage:image source:@"extend"]; // source字段值为"extend"表示为：提醒消息
}

- (PLVChatModel *)sendImageMessage:(UIImage *)image source:(NSString * _Nullable)source {
    if (!image || ![image isKindOfClass:[UIImage class]]) {
        return nil;
    }
    
    PLVImageMessage *message = [[PLVImageMessage alloc] init];
    message.image = image;
    message.time = [PLVFdUtil curTimeInterval];
    message.source = source;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = self.loginChatUser;
    model.message = message;
    
    if (![PLVChatroomManager sharedManager].banned) { // 禁言消息只显示到本地，不推给服务器
        [[PLVChatroomManager sharedManager] sendImageMessage:message];
    }
    return model;
}

#pragma mark 图片表情消息

- (PLVChatModel * _Nullable)sendImageEmotionId:(NSString *)imageId
                                      imageUrl:(NSString *)imageUrl {
    if (!imageId || ![imageId isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    PLVImageEmotionMessage *message = [[PLVImageEmotionMessage alloc] init];
    message.imageId = imageId;
    message.imageUrl = imageUrl;
    message.sendState = PLVImageEmotionMessageSendStateReady;
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = self.loginChatUser;
    model.imageId = imageId;
    model.message = message;
    
    if (![PLVChatroomManager sharedManager].banned) { // 禁言消息只显示到本地，不推给服务器
        [[PLVChatroomManager sharedManager] sendImageEmotionMessage:message];
    }
    return model;
}

#pragma mark 自定义消息

- (PLVChatModel * _Nullable)sendCustomMessageWithEvent:(NSString *)event
                              data:(NSDictionary *)data
                               tip:(NSString * _Nullable)tip
                          emitMode:(int)emitMode {
    if (!event || ![event isKindOfClass:[NSString class]] || event.length == 0 ||
        !data || ![data isKindOfClass:[NSDictionary class]] || [data count] == 0 ||
        !tip || ![tip isKindOfClass:[NSString class]] || tip.length == 0) {
        return nil;
    }
    
    PLVCustomMessage *message = [[PLVCustomMessage alloc] init];
    message.event = event;
    message.data = data;
    message.tip = tip;
    message.emitMode = emitMode;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = self.loginChatUser;
    model.message = message;
    
    BOOL success = [[PLVChatroomManager sharedManager] sendCustonMessage:message];
    return success ? model : nil;
}

#pragma mark 生成教师回复信息

- (void)createAnswerChatModel {
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
    jsonDict[@"s_userId"] = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
    jsonDict[@"content"] = @"同学，您好！请问有什么问题吗？";
    jsonDict[@"user"] = @{@"nick": @"讲师",
                          @"pic" : PLVLiveConstantsChatroomTeacherAvatarURL,
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

- (void)changeRoom {
    self.getHistoryTime = 0;
    self.getRemindHistoryTime = 0;
    self.loadingHistory = NO;
    self.loadingRemindHistory = NO;
    [self loadHistory];
}

- (void)loadHistory {
    if (self.loadingHistory) {
        return;
    }
    self.loadingHistory = YES;
    
    __weak typeof(self) weakSelf = self;
    NSString *roomId = [PLVSocketManager sharedManager].roomId;
    if ([PLVRoomDataManager sharedManager].roomData.inHiClassScene) {
        if ([PLVHiClassManager sharedManager].groupState != PLVHiClassGroupStateNotInGroup) {
            roomId = [PLVHiClassManager sharedManager].groupId;
        }
    } else {
        if ((!roomId || roomId.length == 0) && [PLVSocketManager sharedManager].allowChildRoom) {
            self.delayRequestHistory = YES;
            self.loadingHistory = NO;
            return;
        }
    }
    
    if (!roomId || roomId.length == 0) {
        roomId = [PLVRoomDataManager sharedManager].roomData.channelId;
    }
    NSInteger startIndex = self.getHistoryTime * self.eachLoadingHistoryCount;
    NSInteger endIndex = (self.getHistoryTime + 1) * self.eachLoadingHistoryCount - 1;
    [PLVLiveVideoAPI requestChatRoomHistoryWithRoomId:roomId startIndex:startIndex endIndex:endIndex completion:^(NSArray * _Nonnull historyList) {
        
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

- (void)loadRemindHistory {
    if (self.loadingRemindHistory) {
        return;
    }
    self.loadingRemindHistory = YES;
    
    __weak typeof(self) weakSelf = self;
    NSString *roomId = [PLVSocketManager sharedManager].roomId;
    if (![PLVFdUtil checkStringUseable:roomId]) {
        roomId = [PLVRoomDataManager sharedManager].roomData.channelId;
    }
    NSInteger startIndex = self.getRemindHistoryTime * self.eachLoadingHistoryCount;
    NSInteger endIndex = (self.getRemindHistoryTime + 1) * self.eachLoadingHistoryCount - 1;
    [PLVLiveVideoAPI requestChatRoomRemindHistoryWithRoomId:roomId startIndex:startIndex endIndex:endIndex completion:^(NSArray * _Nonnull historyList) {
        BOOL success = [PLVFdUtil checkArrayUseable:historyList];
        if (success) {
            if ([historyList count] > 0) {
                NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[historyList count]];
                [historyList enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
                    PLVChatModel *model = [weakSelf modelWithHistoryDict:dict];
                    if (model) {
                        [tempArray addObject:model];
                    }
                }];
                BOOL noMoreHistory = [historyList count] < weakSelf.eachLoadingHistoryCount;
                [weakSelf notifyListenerLoadRemindHistorySuccess:[tempArray copy] noMore:noMoreHistory];
            } else {
                [weakSelf notifyListenerLoadRemindHistorySuccess:@[] noMore:YES];
            }
        } else {
            [weakSelf notifyListenerLoadRemindHistoryFailure];
        }
        weakSelf.getRemindHistoryTime++;
        weakSelf.loadingRemindHistory = NO;
    } failure:^(NSError * _Nonnull error) {
        [weakSelf notifyListenerLoadRemindHistoryFailure];
        weakSelf.loadingRemindHistory = NO;
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
    } else if ([msgType isEqualToString:@"reward"]) {
        return [self modelRewardChatDict:dict];
    } else if ([msgType isEqualToString:@"emotion"]) {
        return [self modelEmotionChatDict:dict];
    }
    return model;
}

/// 历史聊天消息json数据初步解析，返回消息类型
/// 图片消息 @"image"
/// 文本消息 @"speak"
/// 引用消息 @"quote"
/// 打赏消息 @"reward"
/// 图片表情消息 @"emotion"
- (NSString *)messageTypeWithHistoryDict:(NSDictionary *)dict {
    NSString *msgSource = PLV_SafeStringForDictKey(dict, @"msgSource");
    NSString *msgType = PLV_SafeStringForDictKey(dict, @"msgType");
    
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    NSString *uid = PLV_SafeStringForDictKey(userDict, @"uid");
    
    if (msgSource && [msgSource isEqualToString:@"chatImg"]) { // 图片消息
        //图片消息分为 直接发送的图片消息和图片表情消息
        NSDictionary *imageContent = PLV_SafeDictionaryForDictKey(dict, @"content");
        if (imageContent) {
            NSString *imageType = PLV_SafeStringForDictKey(imageContent, @"type");
            if (imageType && [imageType isEqualToString:@"emotion"]) {
                return @"emotion";
            }
        }
        return @"image";
    } else if (!msgType && !msgSource && ![uid isEqualToString:@"1"] && ![uid isEqualToString:@"2"]) { // 文本/引用消息
        if (PLV_SafeStringForDictKey(dict, @"content")) {
            NSDictionary *quoteDict = PLV_SafeDictionaryForDictKey(dict, @"quote");
            return quoteDict ? @"quote" : @"speak";
        }
    } else if (msgSource &&
               [msgSource isEqualToString:@"reward"]) { // 打赏消息：红包、礼物
        return @"reward";
    }
    return nil;
}

- (PLVChatModel *)modelSpeakChatDict:(NSDictionary *)dict {
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    
    NSString *msgId = PLV_SafeStringForDictKey(dict, @"id");
    NSString *content = PLV_SafeStringForDictKey(dict, @"content");
    NSTimeInterval time = PLV_SafeIntegerForDictKey(dict, @"time");
    PLVSpeakMessage *message = [[PLVSpeakMessage alloc] init];
    message.msgId = msgId;
    message.content = content;
    message.time = time;
    
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
    NSTimeInterval time = PLV_SafeIntegerForDictKey(dict, @"time");
    NSDictionary *quoteDict = PLV_SafeDictionaryForDictKey(dict, @"quote");
    NSString *quoteUserId = PLV_SafeStringForDictKey(quoteDict, @"userId");
    NSString *quoteUserName = PLV_SafeStringForDictKey(quoteDict, @"nick");
    NSDictionary *quoteImageDict = PLV_SafeDictionaryForDictKey(quoteDict, @"image");
    
    PLVQuoteMessage *message = [[PLVQuoteMessage alloc] init];
    message.msgId = msgId;
    message.content = content;
    message.quoteUserId = quoteUserId;
    message.quoteUserName = quoteUserName;
    message.time = time;
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
    NSTimeInterval time = PLV_SafeIntegerForDictKey(dict, @"time");
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
    message.time = time;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = user;
    model.message = message;
    return model;
}

- (PLVChatModel *)modelRewardChatDict:(NSDictionary *)dict {
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    
    NSString *msgId = PLV_SafeStringForDictKey(dict, @"id");
    
    // 礼物消息
    NSDictionary *content = PLV_SafeDictionaryForDictKey(dict, @"content");

    // 打赏的用户
    NSString *unick = PLV_SafeStringForDictKey(content, @"unick");
    
    // 打赏内容：礼物打赏为礼物名称，现金打赏为金额
    NSString *rewardContent = PLV_SafeStringForDictKey(content, @"rewardContent");
    
    // 礼物数量
    NSString *goodNum = PLV_SafeStringForDictKey(content, @"goodNum");
    
    // 礼物打赏为礼物图片，现金打赏为空
    NSString *gimg = PLV_SafeStringForDictKey(content, @"gimg");
    if ([PLVFdUtil checkStringUseable:gimg] &&
        ![gimg containsString:@"http"]) {
        gimg = [NSString stringWithFormat:@"https:%@", gimg];
    }
    
    PLVRewardMessage *message = [[PLVRewardMessage alloc] init];
    message.msgId = msgId;
    message.unick = unick;
    message.rewardContent = rewardContent;
    message.gimg = gimg;
    message.goodNum = goodNum;
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = user;
    model.message = message;
    return model;
}

- (PLVChatModel *)modelEmotionChatDict:(NSDictionary *)dict {
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    PLVChatUser *user = [[PLVChatUser alloc] initWithUserInfo:userDict];
    
    NSString *msgId = PLV_SafeStringForDictKey(dict, @"id");
    NSDictionary *contentDict = PLV_SafeDictionaryForDictKey(dict, @"content");
    NSString *imageUrl = PLV_SafeStringForDictKey(contentDict, @"uploadImgUrl");
    NSString *imageId = PLV_SafeStringForDictKey(contentDict, @"id");
    NSDictionary *sizeDict = PLV_SafeDictionaryForDictKey(contentDict, @"size");
    CGFloat width = PLV_SafeFloatForDictKey(sizeDict, @"width");
    CGFloat height = PLV_SafeFloatForDictKey(sizeDict, @"height");
    
    PLVImageEmotionMessage *message = [[PLVImageEmotionMessage alloc] init];
    message.msgId = msgId;
    message.imageId = imageId;
    message.imageUrl = imageUrl;
    message.imageSize = CGSizeMake(width, height);
    message.imageUrl = [self imageURLWithImageEmotionMessage:message];
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = user;
    model.message = message;
    
    return model;
}

#pragma mark 获取图片表情数据

///加载图片表情列表 设置为固定size
- (void)loadImageEmotions {
    __weak typeof(self) weakSelf = self;
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSString *accountId = [PLVLiveVideoConfig sharedInstance].userId;
    //暂时不处理分页，每页固定为50
    [PLVLiveVideoAPI requestEmotionImagesWithRoomId:[roomData.channelId integerValue] accountId:accountId page:1 size:50 success:^(NSDictionary * _Nonnull data) {
        NSArray *imageEmoticons = data[@"data"][@"list"];
        weakSelf.imageEmotionArray = imageEmoticons;
        [weakSelf notifyListenerLoadImageEmotionsSuccess];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf notifyListenerLoadImageEmotionsFailure];
    }];
}

#pragma mark 获取图片表情url

- (NSString *)imageURLWithImageEmotionMessage:(PLVImageEmotionMessage *)message {
    if (message.imageUrl)  {
        return message.imageUrl;
    }
    
    if (!self.imageEmotionArray ||
        !message.imageId)  {
        return nil;
    }
    
    __block NSString *imageUrl = nil;
    [self.imageEmotionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *emotionImageId = PLV_SafeStringForDictKey(obj, @"id");
        if ([message.imageId isEqualToString:emotionImageId]) {
            imageUrl = PLV_SafeStringForDictKey(obj, @"url");
            *stop = YES;
        }
    }];
    return imageUrl;
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

- (void)notifyListenerLoadRemindHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomPresenter_loadRemindHistorySuccess:noMore:)]) {
        [self.delegate chatroomPresenter_loadRemindHistorySuccess:modelArray noMore:noMore];
    }
}

- (void)notifyListenerLoadRemindHistoryFailure {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_loadRemindHistoryFailure)]) {
        [self.delegate chatroomPresenter_loadRemindHistoryFailure];
    }
}

- (void)notifyListenerLoadImageEmotionsSuccess {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_loadImageEmotionsSuccess)]) {
        [self.delegate chatroomPresenter_loadImageEmotionsSuccess];
    }
}

- (void)notifyListenerLoadImageEmotionsFailure {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomPresenter_loadImageEmotionsFailure)]) {
        [self.delegate chatroomPresenter_loadImageEmotionsFailure];
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

- (void)roomDataManager_didSessionIdChanged:(NSString *)sessionId {
    [PLVChatroomManager sharedManager].sessionId = sessionId;
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
    } else if ([subEvent isEqualToString:@"REWARD"]) { // someone reward
        [self rewardMessageEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"CLOSEROOM"]) { // admin close chatroom
        [self closeRoomEvent:jsonDict];
    }
}

- (void)socketMananger_didReceiveEvent:(NSString *)event subEvent:(NSString *)subEvent json:(NSString *)jsonString jsonObject:(id)object {
    NSDictionary *jsonDict = PLV_SafeDictionaryForValue(object);
    if ([event isEqualToString:@"emotion"]) {// someone send a image emotion
       [self imageEmotionMessageEvent:jsonDict];
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
    NSTimeInterval time = PLV_SafeIntegerForDictKey(data, @"time");
    NSString *source = PLV_SafeStringForDictKey(data, @"source");
    if (quote) {
        PLVQuoteMessage *message = [[PLVQuoteMessage alloc] init];
        message.msgId = msgId;
        message.content = content;
        message.quoteUserName = PLV_SafeStringForDictKey(quote, @"nick");
        message.time = time;
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
        message.time = time;
        message.source = source;
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
    message.time = PLV_SafeIntegerForDictKey(data, @"time");
    message.source = PLV_SafeStringForDictKey(data, @"source");
    
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

///有用户发送图片表情消息为了应对高并发只返回了图片id
- (void)imageEmotionMessageEvent:(NSDictionary *)data {
    NSDictionary *user = PLV_SafeDictionaryForDictKey(data, @"user");
    NSString *imageId = PLV_SafeStringForDictKey(data, @"id");
    if (!user || !imageId) {
        return;
    }
    
    NSString *userId = PLV_SafeStringForDictKey(user, @"userId");
    if ([self isLoginUser:userId]) {
        return;
    }
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    PLVChatUser *chatUser = [[PLVChatUser alloc] initWithUserInfo:user];
    model.user = chatUser;
    
    PLVImageEmotionMessage *message = [[PLVImageEmotionMessage alloc] init];
    message.msgId = PLV_SafeStringForDictKey(data, @"messageId");
    message.imageId = imageId;
    message.imageUrl = [self imageURLWithImageEmotionMessage:message];

    model.message = message;
    [self cachChatModel:model];
}

/// 收到私聊回复
- (void)teacherAnswerEvent:(NSDictionary *)data {
    NSString *studentUserId = PLV_SafeStringForDictKey(data, @"s_userId");
    if (![self isLoginUser:studentUserId]) {
        return;
    }
    
    NSDictionary *user = PLV_SafeDictionaryForDictKey(data, @"user");
    NSString *content = PLV_SafeStringForDictKey(data, @"content");
    if (!user || !content) {
        return;
    }
    
    NSString *senderId = PLV_SafeStringForDictKey(user, @"userId");
    if ([self isLoginUser:senderId]) {
        return;
    }
    
    NSString *msgType = PLV_SafeStringForDictKey(data, @"msgType");
    id message = nil;
    if ([msgType isEqualToString:@"image"]) {
        message = [self messageTeacherAnswerImageContent:content];
    } else {
        message = [self messageTeacherAnswerSpeakContent:content];
    }
    PLVChatUser *userModel = [[PLVChatUser alloc] initWithUserInfo:user];
    if (!message || !userModel) {
        return;
    }
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    model.user = userModel;
    model.message = message;
    [self notifyListenerDidReceiveAnswerChatModel:model];
}

/// 私聊图片消息
- (id)messageTeacherAnswerImageContent:(NSString *)content {
    NSData *imageData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *imageDict = [NSJSONSerialization JSONObjectWithData:imageData options:0 error:nil];
    if (!imageDict) {
        return nil;
    }
    
    PLVImageMessage *message = [[PLVImageMessage alloc] init];
    message.imageId = PLV_SafeStringForDictKey(imageDict, @"id");
    NSString *imageUrl = PLV_SafeStringForDictKey(imageDict, @"url");
    if ([imageUrl hasPrefix:@"http:"]) {
        message.imageUrl = [imageUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    } else {
        message.imageUrl = imageUrl;
    }
    
    CGFloat width = PLV_SafeFloatForDictKey(imageDict, @"width");
    CGFloat height = PLV_SafeFloatForDictKey(imageDict, @"height");
    message.imageSize = CGSizeMake(width, height);
    return message;
}

/// 私聊文本消息
- (id)messageTeacherAnswerSpeakContent:(NSString *)content {
    if ([content isKindOfClass:[NSString class]] && content.length > 0) {
        content = [content stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        content = [content stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        return content;
    }else {
        return nil;
    }
}

/// 有用户发送打赏消息
- (void)rewardMessageEvent:(NSDictionary *)data {
    NSString *status = PLV_SafeStringForDictKey(data, @"status");
    // status存在时为单播消息
    if (status) {
        return;
    }
    
    NSDictionary *content = PLV_SafeDictionaryForDictKey(data, @"content");
    if (!content ||
        ![content isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary *rewardUser = PLV_SafeDictionaryForDictKey(content, @"rewardUser");
    if (!rewardUser ||
        ![rewardUser isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *userId = PLV_SafeStringForDictKey(rewardUser, @"userId");
    NSString *gimg = PLV_SafeStringForDictKey(content, @"gimg");
    NSString *goodNum = PLV_SafeStringForDictKey(content, @"goodNum");
    NSString *rewardContent = PLV_SafeStringForDictKey(content, @"rewardContent");
    NSString *unick = PLV_SafeStringForDictKey(content, @"unick");

    if ([PLVFdUtil checkStringUseable:gimg] &&
        ![gimg containsString:@"http"]) {
        gimg = [NSString stringWithFormat:@"https:%@", gimg];
    }
    
    PLVChatModel *model = [[PLVChatModel alloc] init];
    PLVChatUser *chatUser = [[PLVChatUser alloc] init];
    chatUser.userId = userId;
    chatUser.userName = unick;
    model.user = chatUser;
    
    PLVRewardMessage *message = [[PLVRewardMessage alloc] init];
    message.gimg = gimg;
    message.goodNum = goodNum;
    message.rewardContent = rewardContent;
    message.unick = unick;
    model.message = message;
    [self cachChatModel:model];
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

- (void)closeRoomEvent:(NSDictionary *)data {
    NSDictionary *value = PLV_SafeDictionaryForDictKey(data, @"value");
    BOOL closeRoom = PLV_SafeBoolForDictKey(value, @"closed");
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomPresenter_didChangeCloseRoom:)]) {
        [self.delegate chatroomPresenter_didChangeCloseRoom:closeRoom];
    }
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
    PLV_LOG_WARN(PLVConsoleLogModuleTypeChatRoom, @"%@：%@", message, word);
    //严禁词
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomPresenter_receiveWarning:prohibitWord:)]) {
        [self.delegate chatroomPresenter_receiveWarning:message prohibitWord:word];
    }
}

- (void)chatroomManager_receiveImageWarningWithMsgId:(NSString *)msgId {
    PLV_LOG_WARN(PLVConsoleLogModuleTypeChatRoom, @"图片不合法：(msgId:%@)", msgId);
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomPresenter_receiveImageWarningWithMsgId:)]) {
        [self.delegate chatroomPresenter_receiveImageWarningWithMsgId:msgId];
    }
}

- (void)chatroomManager_sendImageMessageFaild:(PLVImageMessage *)message {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomPresenter_sendImageMessageFaild:)]) {
        [self.delegate chatroomPresenter_sendImageMessageFaild:message];
    }
}

- (void)chatroomManager_sendImageMessageSuccess:(PLVImageMessage *)message {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomPresenter_sendImageMessageSuccess:)]) {
        [self.delegate chatroomPresenter_sendImageMessageSuccess:message];
    }
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
