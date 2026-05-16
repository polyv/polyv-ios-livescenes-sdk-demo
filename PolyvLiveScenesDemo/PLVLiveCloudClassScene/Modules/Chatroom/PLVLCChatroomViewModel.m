//
//  PLVLCChatroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/26.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVGiveRewardPresenter.h"
#import "PLVLCSpeakMessageCell.h"
#import "PLVLCLongContentMessageCell.h"
#import "PLVLCQuoteMessageCell.h"
#import "PLVLCFileMessageCell.h"
#import "PLVLCImageMessageCell.h"
#import "PLVLCImageEmotionMessageCell.h"
#import "PLVLCRedpackMessageCell.h"
#import "PLVLCRewardMessageCell.h"
#import "PLVLCProductConversionEffectCell.h"
#import "PLVLCLandscapeSpeakCell.h"
#import "PLVLCLandscapeLongContentCell.h"
#import "PLVLCLandscapeImageCell.h"
#import "PLVLCLandscapeImageEmotionCell.h"
#import "PLVLCLandscapeQuoteCell.h"
#import "PLVLCLandscapeFileCell.h"
#import "PLVLCLandscapeRedpackMessageCell.h"
#import "PLVLCCustomIntroductionMessageCell.h"
#import "PLVLCLandscapeCustomIntroductionMessageCell.h"
#import "PLVMultiLanguageManager.h"

static NSInteger kPLVLCMaxPublicChatMessageCount = 500;

@interface PLVLCChatroomViewModel ()<
PLVSocketManagerProtocol, // socket协议
PLVChatroomPresenterProtocol // common层聊天室Presenter协议
>

@property (nonatomic, strong) PLVChatroomPresenter *presenter; /// 聊天室Presenter

#pragma mark 倒计时红包

/// 当前倒计时红包类型
@property (nonatomic, assign) PLVRedpackMessageType currentRedpackType;
/// 红包倒计时
@property (nonatomic, strong) NSTimer *redpackTimer;
/// 倒计时时间，单位秒
@property (nonatomic, assign) NSInteger delayTime;

#pragma mark 登录用户上报

/// 上报登录用户计时器，间隔4秒触发一次
@property (nonatomic, strong) NSTimer *loginTimer;
/// 暂未上报的登录用户数组
@property (nonatomic, strong) NSMutableArray <PLVChatUser *> *loginUserArray;
/// 当前时间段内是否发生当前用户的登录事件
@property (nonatomic, assign) BOOL isMyselfLogin;
/// 商品点击消息聚合计时器，间隔2秒触发一次
@property (nonatomic, strong) NSTimer *productClickTimer;
/// 暂未展示的商品点击消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *productClickMessageArray;

#pragma mark 礼物打赏
/// 礼物打赏开关
@property (nonatomic, assign) BOOL enableReward;

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

#pragma mark 聊天数据管理

/// 公聊数据管理计时器，间隔30秒触发一次
@property (nonatomic, strong) NSTimer *publicChatManagerTimer;

#pragma mark 数据数组

/// 是否为专注模式
@property (nonatomic, assign) BOOL focusMode;
/// 是否第一次加载提问消息
@property (nonatomic, assign) BOOL firstTimeLoadPrivateChat;
/// 公聊全部消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *publicChatArray;
/// 公聊【只看教师与我】消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *partOfPublicChatArray;
/// 公聊【只看教师】消息数组，用于响应专注模式
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *partOfSpecialIdentityPublicChatArray;
/// 私聊消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *privateChatArray;

/// 是否第一次加载通知消息
@property (nonatomic, assign) BOOL firstTimeLoadCustomIntroduction;

@end

@implementation PLVLCChatroomViewModel {
    // 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _publicChatArrayLock;
    dispatch_semaphore_t _privateChatArrayLock;
    dispatch_semaphore_t _loginArrayLock;
    dispatch_semaphore_t _productClickArrayLock;
    dispatch_semaphore_t _managerMessageArrayLock;
    dispatch_semaphore_t _danmuArrayLock;
    
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;

    // 多代理
    dispatch_queue_t multicastQueue;
    PLVMulticastDelegate<PLVLCChatroomViewModelProtocol> *multicastDelegate;
}

static const NSInteger PLVLCProductClickDisplayLimitPerTick = 5;
static const NSUInteger PLVLCProductClickNicknameMaxLength = 5;

#pragma mark - 生命周期

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVLCChatroomViewModel *viewModel = nil;
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
        multicastQueue = dispatch_queue_create("com.PLVLiveScenesDemo.PLVLCChatroomViewModel", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVLCChatroomViewModelProtocol> *)[[PLVMulticastDelegate alloc] init];
    }
    return self;
}

- (void)setup {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.menuInfo.transmitMode && roomData.menuInfo.mainRoom) {
        return;
    }
    
    // 如果已存在presenter，先清理旧的
    if (self.presenter) {
        [[PLVSocketManager sharedManager] removeDelegate:self];
        [self.presenter destroy];
        self.presenter = nil;
    }
    // 初始化信号量
    _publicChatArrayLock = dispatch_semaphore_create(1);
    _privateChatArrayLock = dispatch_semaphore_create(1);
    _loginArrayLock = dispatch_semaphore_create(1);
    _productClickArrayLock = dispatch_semaphore_create(1);
    _managerMessageArrayLock = dispatch_semaphore_create(1);
    _danmuArrayLock = dispatch_semaphore_create(1);
    
    // 初始化消息数组，预设初始容量
    self.publicChatArray = [NSMutableArray arrayWithCapacity:500];
    self.partOfPublicChatArray = [NSMutableArray arrayWithCapacity:100];
    self.partOfSpecialIdentityPublicChatArray = [NSMutableArray arrayWithCapacity:100];
    self.privateChatArray = [NSMutableArray arrayWithCapacity:20];
    
    BOOL isZH = [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK;
    NSString *notificationText = isZH ? roomData.menuInfo.chatCustomIntroduction : roomData.menuInfo.chatCustomIntroductionEn;
    if ([PLVFdUtil checkStringUseable:notificationText] && roomData.videoType == PLVChannelVideoType_Live) {
        PLVCustomIntroductionMessage *notifyMsg = [[PLVCustomIntroductionMessage alloc] init];
        notifyMsg.content = notificationText;
        PLVChatModel *model = [[PLVChatModel alloc] init];
        model.message = notifyMsg;
        [self.publicChatArray addObject:model];
        self.firstTimeLoadCustomIntroduction = YES;
    }
    
    // 初始化聊天室Presenter并设置delegate
    self.presenter = [[PLVChatroomPresenter alloc] initWithLoadingHistoryCount:20];
    self.presenter.delegate = self;
    [self.presenter login];
    [self.presenter startPageViewTimer];
    
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    // 初始化登录事件计时器，登录用户数组
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                       target:self
                                                     selector:@selector(loginTimerAction)
                                                     userInfo:nil
                                                      repeats:YES];
    self.loginUserArray = [[NSMutableArray alloc] initWithCapacity:10];
    
    // 初始化商品点击消息聚合计时器，商品点击消息数组
    // 注意：定时器不依赖开关，避免 setup 阶段开关未就绪导致后续消息缓存失败
    self.productClickTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                              target:self
                                                            selector:@selector(productClickTimerAction)
                                                            userInfo:nil
                                                             repeats:YES];
    self.productClickMessageArray = [[NSMutableArray alloc] initWithCapacity:10];
    
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
    [self removeAllLoginUsers];
    
    [self.productClickTimer invalidate];
    self.productClickTimer = nil;
    [self removeAllProductClickMessages];
    
    [self.managerMessageTimer invalidate];
    self.managerMessageTimer = nil;
    [self removeAllManagerMessages];
    
    [self.danmuTimer invalidate];
    self.danmuTimer = nil;
    [self removeAllDanmus];
    
    [self removeAllPrivateChatModels];
    [self removeAllPublicChatModels];
    
    self.onlyTeacher = NO;
    self.focusMode = NO;
    
    [self stopRedpackTimer];
    
    [self.publicChatManagerTimer invalidate];
    self.publicChatManagerTimer = nil;
}

#pragma mark - 加载打赏开关
- (void)loadRewardEnable {
    __weak typeof(self) weakSelf = self;
    [PLVGiveRewardPresenter requestRewardSettingCompletion:^(BOOL rewardEnable, NSString *payWay, NSArray *modelArray, NSString *pointUnit) {
        weakSelf.enableReward = rewardEnable;
        //暂时 关闭动态特效
        weakSelf.hideRewardDisplay = YES;
//        weakSelf.hideRewardDisplay = !rewardEnable;
        [weakSelf notifyDelegatesLoadRewardEnable:rewardEnable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
    } failure:^(NSString *error) {
        
    }];
}

#pragma mark - Getter

- (NSArray *)imageEmotionArray {
    return self.presenter.imageEmotionArray;
}

#pragma mark - 加载消息

- (void)loadHistory {
    [self.presenter loadHistory];
}

- (void)loadQuestionHistory {
    [self.presenter loadQuestionHistory];
}

#pragma mark - 加载图片表情数据

- (void)loadImageEmotions {
    [self.presenter loadImageEmotions];
}

#pragma mark - [ Public Medthods ]

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
        [self cacheDanmu:@[model]];
    }
    return sendSuccess;
}

- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel *)replyChatModel {
    PLVChatModel *model = [self.presenter sendSpeakMessage:content replyChatModel:replyChatModel];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
        [self cacheDanmu:@[model]];
    }
    return sendSuccess;
}

- (BOOL)sendImageMessage:(UIImage *)image {
    PLVChatModel *model = [self.presenter sendImageMessage:image];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
    }
    return sendSuccess;
}

- (BOOL)sendImageEmotionId:(NSString *)imageId imageUrl:(NSString *)imageUrl   {
    PLVChatModel *model = [self.presenter sendImageEmotionId:imageId imageUrl:imageUrl];
    BOOL sendSuccess = model && ![PLVChatroomManager sharedManager].closeRoom;
    if (sendSuccess) {
        [self addPublicChatModel:model];
    }
    return sendSuccess;
}

- (void)sendLike {
    [self.presenter sendLike];
}

- (void)createAnswerChatModel {
    [self.presenter createAnswerChatModel];
}

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
        [weakSelf notifyDelegatesCheckRedpackStateResult:redpackState chatModel:model];
        [weakSelf notifyDelegatesRedpackStateChanged];
        [weakSelf.presenter recordRedpackReceiveWithID:message.redpackId time:message.time state:redpackState];
    } failure:^(NSError * _Nonnull error) {
        message.state = PLVRedpackStateUnknow;
        [weakSelf notifyDelegatesCheckRedpackStateResult:PLVRedpackStateUnknow chatModel:model];
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
                [self notifyDelegatesRedpackStateChanged];
                [self.presenter recordRedpackReceiveWithID:redpackMessage.redpackId time:redpackMessage.time state:redpackState];
                break;
            }
        }
    }
    
    return redpackState;
}

- (void)updateOnlineList {
    [self.presenter updateOnlineList];
}

- (void)welfareLotteryCommentSuccess:(NSString *)comment {
    PLVChatModel *model = [self.presenter createWelfareLotteryCommentChatModel:comment];
    if (model) {
        [self addPublicChatModel:model];
        [self cacheDanmu:@[model]];
    }
}

#pragma mark - 定时展示商品点击消息

- (void)cacheProductClickMessage:(PLVChatModel *)chatModel {
    if (!chatModel ||
        !self.productClickTimer ||
        !self.productClickTimer.valid) {
        return;
    }
    
    dispatch_semaphore_wait(_productClickArrayLock, DISPATCH_TIME_FOREVER);
    [self.productClickMessageArray addObject:chatModel];
    dispatch_semaphore_signal(_productClickArrayLock);
}

- (void)productClickTimerAction {
    if (self.productClickMessageArray.count == 0) {
        return;
    }
    
    dispatch_semaphore_wait(_productClickArrayLock, DISPATCH_TIME_FOREVER);
    NSArray *messageArray = [self.productClickMessageArray copy];
    [self.productClickMessageArray removeAllObjects];
    dispatch_semaphore_signal(_productClickArrayLock);
    
    if (messageArray.count <= PLVLCProductClickDisplayLimitPerTick) {
        [self addPublicChatModels:messageArray];
        return;
    }
    
    NSArray *topMessages = [messageArray subarrayWithRange:NSMakeRange(0, PLVLCProductClickDisplayLimitPerTick)];
    [self addPublicChatModels:topMessages];
    
    NSArray *overflowMessages = [messageArray subarrayWithRange:NSMakeRange(PLVLCProductClickDisplayLimitPerTick, messageArray.count - PLVLCProductClickDisplayLimitPerTick)];
    PLVChatModel *summaryModel = [self buildOverflowSummaryChatModelWithMessages:overflowMessages];
    if (summaryModel) {
        [self addPublicChatModels:@[summaryModel]];
    }
}

- (void)removeAllProductClickMessages {
    if (!_productClickArrayLock) {
        return;
    }
    
    dispatch_semaphore_wait(_productClickArrayLock, DISPATCH_TIME_FOREVER);
    [self.productClickMessageArray removeAllObjects];
    dispatch_semaphore_signal(_productClickArrayLock);
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
        if (self.focusMode) {
            return self.partOfSpecialIdentityPublicChatArray;
        } else {
            return self.partOfPublicChatArray;
        }
    } else {
        return self.publicChatArray;
    }
}

- (BOOL)productMessageEffectEnabled {
    PLVLiveVideoChannelMenuInfo *menuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    return menuInfo.effect.productEffectEnabled;
}

- (BOOL)shouldFilterEffectMessageModel:(PLVChatModel *)model {
    return (![self productMessageEffectEnabled] && [PLVLCProductConversionEffectCell isModelValid:model]);
}

/// 本地发送公聊消息时
- (void)addPublicChatModel:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    if ([self shouldFilterEffectMessageModel:model]) {
        return;
    }
    
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    
    // 由于 cell显示需要的 消息多属性文本 计算比较耗时，所以，在 子线程 中提前计算出来；
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if ([PLVLCProductConversionEffectCell isModelValid:model]) {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCProductConversionEffectCell conversionAttributedStringWithModel:model]];
        model.landscapeAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCProductConversionEffectCell conversionAttributedStringWithModel:model]];
        model.cellHeightForV = [PLVLCProductConversionEffectCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCProductConversionEffectCell cellHeightWithModel:model cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCSpeakMessageCell isModelValid:model]) {
        PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
        model.attributeString = [PLVLCSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user];
        model.landscapeAttributeString = [PLVLCLandscapeSpeakCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVLCSpeakMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeSpeakCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCLongContentMessageCell isModelValid:model]) {
        model.attributeString = [PLVLCLongContentMessageCell contentLabelAttributedStringWithModel:model];
        model.landscapeAttributeString = [PLVLCLandscapeLongContentCell contentLabelAttributedStringWithModel:model loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVLCLongContentMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeLongContentCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
        PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
        model.attributeString = [PLVLCQuoteMessageCell contentAttributedStringWithMessage:message];
        model.landscapeAttributeString = [PLVLCLandscapeQuoteCell contentLabelAttributedStringWithMessage:message user:model.user];
        model.cellHeightForV = [PLVLCQuoteMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeQuoteCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCFileMessageCell isModelValid:model]) {
        PLVFileMessage *message = (PLVFileMessage *)model.message;
        model.attributeString = [PLVLCFileMessageCell contentLabelAttributedStringWithMessage:message user:model.user];
        model.landscapeAttributeString = [PLVLCLandscapeFileCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId];
        model.cellHeightForV = [PLVLCFileMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeFileCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCLandscapeImageCell isModelValid:model]) {
        model.landscapeAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCLandscapeImageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId]];
        model.cellHeightForV = [PLVLCImageMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeImageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCLandscapeImageEmotionCell isModelValid:model]) {
        model.landscapeAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCLandscapeImageEmotionCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId]];
        model.cellHeightForV = [PLVLCImageEmotionMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeImageEmotionCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCRewardMessageCell isModelValid:model]) {
        model.cellHeightForV = [PLVLCRewardMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
    } else if ([PLVLCRedpackMessageCell isModelValid:model]) {
        model.cellHeightForV = [PLVLCRedpackMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeRedpackMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    } else if ([PLVLCCustomIntroductionMessageCell isModelValid:model]) {
        model.attributeString = [PLVLCCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
        model.landscapeAttributeString = [PLVLCLandscapeCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
        model.cellHeightForV = [PLVLCCustomIntroductionMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
        model.cellHeightForH = [PLVLCLandscapeCustomIntroductionMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
    }
    
    [self.publicChatArray addObject:model];
    [self.partOfPublicChatArray addObject:model];
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidSendMessage:model];
}

/// 接收到socket的公聊消息时
- (void)addPublicChatModels:(NSArray <PLVChatModel *> *)modelArray {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([self shouldFilterEffectMessageModel:model]) {
            continue;
        }
        if ([model isKindOfClass:[PLVChatModel class]]) {
            // 由于 cell显示需要的 消息多属性文本 计算比较耗时，所以，在 子线程 中提前计算出来；
            PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
            if ([PLVLCProductConversionEffectCell isModelValid:model]) {
                model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCProductConversionEffectCell conversionAttributedStringWithModel:model]];
                model.landscapeAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCProductConversionEffectCell conversionAttributedStringWithModel:model]];
                model.cellHeightForV = [PLVLCProductConversionEffectCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCProductConversionEffectCell cellHeightWithModel:model cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCSpeakMessageCell isModelValid:model]) {
                PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
                model.attributeString = [PLVLCSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user];
                model.landscapeAttributeString = [PLVLCLandscapeSpeakCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId];
                model.cellHeightForV = [PLVLCSpeakMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeSpeakCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCLongContentMessageCell isModelValid:model]) {
                model.attributeString = [PLVLCLongContentMessageCell contentLabelAttributedStringWithModel:model];
                model.landscapeAttributeString = [PLVLCLandscapeLongContentCell contentLabelAttributedStringWithModel:model loginUserId:roomUser.viewerId];
                model.cellHeightForV = [PLVLCLongContentMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeLongContentCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
                PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
                model.attributeString = [PLVLCQuoteMessageCell contentAttributedStringWithMessage:message];
                model.landscapeAttributeString = [PLVLCLandscapeQuoteCell contentLabelAttributedStringWithMessage:message user:model.user];
                model.cellHeightForV = [PLVLCQuoteMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeQuoteCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCFileMessageCell isModelValid:model]) {
                PLVFileMessage *message = (PLVFileMessage *)model.message;
                model.attributeString = [PLVLCFileMessageCell contentLabelAttributedStringWithMessage:message user:model.user];
                model.landscapeAttributeString = [PLVLCLandscapeFileCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:roomUser.viewerId];
                model.cellHeightForV = [PLVLCFileMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeFileCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCLandscapeImageCell isModelValid:model]) {
                model.landscapeAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCLandscapeImageCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId]];
                model.cellHeightForV = [PLVLCImageMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeImageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCLandscapeImageEmotionCell isModelValid:model]) {
                model.landscapeAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCLandscapeImageEmotionCell nickLabelAttributedStringWithUser:model.user loginUserId:roomUser.viewerId]];
                model.cellHeightForV = [PLVLCImageEmotionMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeImageEmotionCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCRewardMessageCell isModelValid:model]) {
                model.cellHeightForV = [PLVLCRewardMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
            } else if ([PLVLCRedpackMessageCell isModelValid:model]) {
                model.cellHeightForV = [PLVLCRedpackMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeRedpackMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            } else if ([PLVLCCustomIntroductionMessageCell isModelValid:model]) {
                model.attributeString = [PLVLCCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
                model.landscapeAttributeString = [PLVLCLandscapeCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
                model.cellHeightForV = [PLVLCCustomIntroductionMessageCell cellHeightWithModel:model cellWidth:self.tableViewWidthForV];
                model.cellHeightForH = [PLVLCLandscapeCustomIntroductionMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableViewWidthForH];
            }
            
            [self.publicChatArray addObject:model];
            if (model.user.specialIdentity) {
                [self.partOfPublicChatArray addObject:model];
                [self.partOfSpecialIdentityPublicChatArray addObject:model];
            }
        }
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidReceiveMessages:modelArray];
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
            [self.partOfSpecialIdentityPublicChatArray removeObject:model];
            break;
        }
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidMessageDeleted];
}

/// 接收到socket删除所有公聊消息的通知时、调用销毁接口时
- (void)removeAllPublicChatModels {
    if (!_publicChatArrayLock) {
        return;
    }
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    [self.publicChatArray removeAllObjects];
    [self.partOfPublicChatArray removeAllObjects];
    [self.partOfSpecialIdentityPublicChatArray removeAllObjects];
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesDidMessageDeleted];
}

/// 历史聊天记录接口返回消息数组时
- (void)insertChatModels:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
    for (PLVChatModel *model in modelArray) {
        if ([self shouldFilterEffectMessageModel:model]) {
            continue;
        }
        if ([model isKindOfClass:[PLVChatModel class]]) {
            [self.publicChatArray insertObject:model atIndex:0];
            PLVChatUser *user = model.user;
            if (user.specialIdentity) {
                if (![self.partOfPublicChatArray containsObject:model]) {
                    [self.partOfPublicChatArray insertObject:model atIndex:0];
                }
                if (![self.partOfSpecialIdentityPublicChatArray containsObject:model]) {
                    [self.partOfSpecialIdentityPublicChatArray insertObject:model atIndex:0];
                }
            } else if ([self isLoginUser:user.userId]) {
                if (![self.partOfPublicChatArray containsObject:model]) {
                    [self.partOfPublicChatArray insertObject:model atIndex:0];
                }
            }
        }
    }
    BOOL first = ([self.publicChatArray count] <= [modelArray count]);
    if (self.firstTimeLoadCustomIntroduction && [self.publicChatArray count] >= 1) { // 含有通知消息的需要单独判断
        first = (([self.publicChatArray count] - 1) <= [modelArray count]);
        self.firstTimeLoadCustomIntroduction = NO;
    }
    dispatch_semaphore_signal(_publicChatArrayLock);
    
    [self notifyDelegatesLoadHistorySuccess:noMore firstTime:first];
}

#pragma mark - Multicase

- (void)addDelegate:(id<PLVLCChatroomViewModelProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    });
}

- (void)removeDelegate:(id<PLVLCChatroomViewModelProtocol>)delegate {
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

- (void)notifyDelegatesDidSendMessage:(PLVChatModel *)model {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didSendMessage:model];
    });
}

- (void)notifyDelegatesDidReceiveMessages:(NSArray <PLVChatModel *> *)modelArray {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
    if (!modelArray || ![modelArray isKindOfClass:[NSArray class]] || [modelArray count] == 0) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didReceiveMessages:modelArray];
    });
}

- (void)notifyDelegatesDidMessageDeleted {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didMessageDeleted];
    });
}

- (void)notifyListerDidMessageCountLimitedAutoDeleted {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didMessageCountLimitedAutoDeleted];
    });
}

- (void)notifyDelegatesDidSendProhibitMessage {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didSendProhibitMessage];
    });
}

- (void)notifyDelegatesLoadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadHistorySuccess:noMore firstTime:first];
    });
}

- (void)notifyDelegatesLoadHistoryFailure {
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

- (void)notifyDelegatesForLoginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loginUsers:userArray];
    });
}

- (void)notifyDelegatesForManagerMessage:(NSString *)content {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_managerMessage:content];
    });
}

- (void)notifyDelegatesForDanmu:(NSString *)content {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_danmu:content];
    });
}

- (void)notifyDelegatesListenerRewardSuccess:(NSDictionary *)modelDict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_rewardSuccess:modelDict];
    });
}

- (void)notifyDelegatesLoadRewardEnable:(BOOL)enable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray * _Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadRewardEnable:enable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
    });
}

- (void)notifyDelegatesStartCardPush:(BOOL)start pushInfo:(NSDictionary *)pushDict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_startCardPush:start pushInfo:pushDict];
    });
}

- (void)notifyDelegatesShowDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_showDelayRedpackWithType:type delayTime:delayTime];
    });
}

- (void)notifyDelegatesHideDelayRedpack {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_hideDelayRedpack];
    });
}

- (void)notifyDelegatesLoadImageEmotionSuccess {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadImageEmotionSuccess:self.imageEmotionArray];
    });
}

- (void)notifyDelegatesLoadImageEmotionFailure {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_loadImageEmotionFailure];
    });
}

- (void)notifyDelegatesDidLoginRestrict {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didLoginRestrict];
    });
}

- (void)notifyDelegatesCloseRoom:(BOOL)closeRoom {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_closeRoom:closeRoom];
    });
}

- (void)notifyDelegatesFocusMode:(BOOL)focusMode {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_focusMode:focusMode];
    });
}

- (void)notifyDelegatesCheckRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_checkRedpackStateResult:state chatModel:model];
    });
}

- (void)notifyDelegatesRedpackStateChanged {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didRedpackStateChanged];
    });
}

- (void)notifyDelegatesDidUpdateOnlineList:(NSArray<PLVChatUser *> *)list total:(NSInteger)total {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_didUpdateOnlineList:list total:total];
    });
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
        [self notifyDelegatesForLoginUsers:nil];
    } else {
        if ([self.loginUserArray count] >= 10) {
            NSArray *loginUserArray = [self.loginUserArray copy];
            [self notifyDelegatesForLoginUsers:loginUserArray];
            
            dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
            [self.loginUserArray removeAllObjects];
            dispatch_semaphore_signal(_loginArrayLock);
        } else if ([self.loginUserArray count] > 0) {
            PLVChatUser *user = self.loginUserArray[0];
            [self notifyDelegatesForLoginUsers:@[user]];
            
            dispatch_semaphore_wait(_loginArrayLock, DISPATCH_TIME_FOREVER);
            [self.loginUserArray removeObjectAtIndex:0];
            dispatch_semaphore_signal(_loginArrayLock);
        }
    }
}

- (void)removeAllLoginUsers {
    if (!_loginArrayLock) {
        return;
    }
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
        if (model.user.userType == PLVRoomUserTypeManager &&
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
        [self notifyDelegatesForManagerMessage:content];
        
        dispatch_semaphore_wait(_managerMessageArrayLock, DISPATCH_TIME_FOREVER);
        [self.managerMessageArray removeObjectAtIndex:0];
        dispatch_semaphore_signal(_managerMessageArrayLock);
    }
}

- (void)removeAllManagerMessages {
    if (!_managerMessageArrayLock) {
        return;
    }
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
        [self notifyDelegatesForDanmu:content];
        
        dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
        [self.danmuArray removeObjectAtIndex:0];
        dispatch_semaphore_signal(_danmuArrayLock);
    }
}

- (void)removeAllDanmus {
    if (!_danmuArrayLock) {
        return;
    }
    dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
    [self.danmuArray removeAllObjects];
    dispatch_semaphore_signal(_danmuArrayLock);
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
        [self notifyDelegatesHideDelayRedpack];
        return;
    }
    
    [self notifyDelegatesShowDelayRedpackWithType:self.currentRedpackType delayTime:self.delayTime];
}

#pragma mark 公聊数据管理

- (void)publicChatManagerTimerAction {
    if (self.publicChatArray.count > kPLVLCMaxPublicChatMessageCount) {
        dispatch_semaphore_wait(_publicChatArrayLock, DISPATCH_TIME_FOREVER);
        NSUInteger removalCount = self.publicChatArray.count - kPLVLCMaxPublicChatMessageCount;
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

#pragma mark 转化特效消息

- (NSString *)conversionEffectTemplateWithMessageType:(PLVMessageEffectMessageType)messageType {
    PLVLiveVideoChannelMessageEffect *effect = [PLVRoomDataManager sharedManager].roomData.menuInfo.effect;
    if (messageType == PLVMessageEffectMessageTypeClickJobProduct) {
        return effect.clickJobProductEffectTip;
    } else if (messageType == PLVMessageEffectMessageTypeClickFinancialProduct) {
        return effect.clickFinancialProductEffectTip;
    } else {
        return effect.clickOrdinaryProductEffectTip;
    }
}

/// 生成单条商品点击转化聊天模型。
/// 原始 socket data 中只包含用户原始昵称，这里先解析出 PLVMessageEffectMessage，
/// 再按“单条消息昵称规则”生成 displayNickName，最后统一组装 PLVChatModel。
/// 单条规则：昵称超过 5 个可见字符时展示为“前5个字符... ”，否则原样展示。
/// @param data PRODUCT_CLICK 事件数据，支持扁平结构或 payloadData。
/// @param eventName 事件名，预期为 PRODUCT_CLICK。
- (PLVChatModel *)productClickChatModelWithData:(NSDictionary *)data eventName:(NSString *)eventName {
    PLVMessageEffectMessage *effectMessage = [PLVMessageEffectMessage messageWithEventName:eventName data:data];
    NSString *displayNickName = [self displayNicknameForProductClickMessage:effectMessage.nickName];
    return [self chatModelWithProductClickEffectMessage:effectMessage displayNickName:displayNickName];
}

/// 生成合并商品点击转化聊天模型。
/// 只在 buildOverflowSummaryChatModelWithMessages: 中调用；
/// 合并逻辑已经把多个原始昵称处理成“xxx 等N人”，这里不再计算单条昵称截断。
/// @param payload 合并消息 payload，来源于原始商品点击消息并替换 nickName 为合并展示昵称。
/// @param displayNickName 已按合并规则处理好的展示昵称，例如“张三、李... 等6人 ”。
- (PLVChatModel *)productClickSummaryChatModelWithPayload:(NSDictionary *)payload displayNickName:(NSString *)displayNickName {
    PLVMessageEffectMessage *effectMessage = [PLVMessageEffectMessage messageWithEventName:@"PRODUCT_CLICK" data:payload];
    return [self chatModelWithProductClickEffectMessage:effectMessage displayNickName:displayNickName];
}

/// 统一生成商品点击转化聊天模型。
/// 单条消息和合并消息都会先生成 PLVMessageEffectMessage，再进入这里组装 PLVChatModel，
/// 避免同一份 data/eventName 为了“计算展示昵称”和“构建消息模型”重复解析。
/// @param effectMessage 商品点击特效消息模型，内部保留原始昵称，用于后续 payload/点击逻辑。
/// @param displayNickName 用于模板展示的昵称，可能是截断后的单条昵称，也可能是“xxx 等N人”的合并昵称。
- (PLVChatModel *)chatModelWithProductClickEffectMessage:(PLVMessageEffectMessage *)effectMessage displayNickName:(NSString *)displayNickName {
    if (!effectMessage || ![effectMessage isProductClickEffectMessage]) {
        return nil;
    }

    NSString *template = [self conversionEffectTemplateWithMessageType:effectMessage.type];
    // contentWithTemplate: 只读取 effectMessage.nickName 做模板替换；
    // 这里临时替换为展示昵称，生成 content 后立即恢复原始昵称，避免影响点击 payload。
    NSString *originNickName = effectMessage.nickName;
    effectMessage.displayNickName = displayNickName;
    effectMessage.nickName = displayNickName;
    effectMessage.content = [effectMessage contentWithTemplate:template];
    effectMessage.nickName = originNickName;

    PLVChatUser *chatUser = [[PLVChatUser alloc] init];
    chatUser.userName = effectMessage.nickName;
    chatUser.userId = [NSString stringWithFormat:@"conversion_%@", effectMessage.nickName];

    PLVChatModel *chatModel = [[PLVChatModel alloc] init];
    chatModel.user = chatUser;
    chatModel.message = effectMessage;
    chatModel.contentLength = PLVChatMsgContentLength_0To500;
    return chatModel;
}

- (void)productClickEventWithSubEvent:(NSString *)subEvent jsonDict:(NSDictionary *)jsonDict {
    if (![self productMessageEffectEnabled]) {
        return;
    }
    NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
    NSDictionary *payloadData = [PLVFdUtil checkDictionaryUseable:data] ? data : jsonDict;
    NSString *eventType = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if (![PLVFdUtil checkStringUseable:eventType]) {
        eventType = PLV_SafeStringForDictKey(payloadData, @"EVENT");
    }
    eventType = [PLVFdUtil checkStringUseable:eventType] ? eventType : subEvent;
    if (![[eventType uppercaseString] isEqualToString:@"PRODUCT_CLICK"]) {
        return;
    }
    PLVChatModel *chatModel = [self productClickChatModelWithData:payloadData eventName:eventType];
    if (!chatModel) {
        return;
    }
    NSString *effectMessage = [self productClickEffectMessageWithChatModel:chatModel];
    [self notifyDelegatesProductClickEffectMessage:effectMessage];
    [self cacheProductClickMessage:chatModel];
}

- (NSString *)productClickEffectMessageWithChatModel:(PLVChatModel *)chatModel {
    if (![chatModel.message isKindOfClass:[PLVMessageEffectMessage class]]) {
        return nil;
    }
    PLVMessageEffectMessage *effectMessage = (PLVMessageEffectMessage *)chatModel.message;
    return [PLVFdUtil checkStringUseable:effectMessage.content] ? effectMessage.content : nil;
}

/// 安全获取商品点击昵称的前缀。
/// 不直接使用 substringToIndex:，是因为 NSString.length 按 UTF-16 计数，
/// emoji、组合音标等“用户看到的一个字符”可能由多个 code unit 组成，直接截取可能截坏。
/// @param string 原始昵称或合并后的昵称串。
/// @param maxLength 最多保留的用户可见字符数。
/// @param didTruncate 输出参数；YES 表示原字符串超过 maxLength，调用方需要拼接省略号。
/// @return 未超长时返回原字符串；超长时返回前 maxLength 个组合字符。
- (NSString *)productClickNicknamePrefixForString:(NSString *)string
                                        maxLength:(NSUInteger)maxLength
                                     didTruncate:(BOOL *)didTruncate {
    if (didTruncate) {
        *didTruncate = NO;
    }
    if (![PLVFdUtil checkStringUseable:string] || maxLength == 0) {
        return string;
    }
    
    // 按组合字符截取，避免 emoji 或组合字符被 substringToIndex: 从中间截断。
    __block NSUInteger characterCount = 0;
    __block NSRange prefixRange = NSMakeRange(0, 0);
    __block BOOL truncated = NO;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if (characterCount < maxLength) {
            prefixRange.length = NSMaxRange(substringRange);
            characterCount++;
        } else {
            truncated = YES;
            *stop = YES;
        }
    }];
    
    if (didTruncate) {
        *didTruncate = truncated;
    }
    return truncated ? [string substringWithRange:prefixRange] : string;
}

/// 单条商品点击消息的昵称展示规则：
/// - 昵称不超过 5 个可见字符：原样展示；
/// - 昵称超过 5 个可见字符：展示“前5个字符 + ... + 空格”，例如“张三李四王... ”。
- (NSString *)displayNicknameForProductClickMessage:(NSString *)nickName {
    if (![PLVFdUtil checkStringUseable:nickName]) {
        return nickName;
    }
    
    BOOL truncated = NO;
    NSString *prefix = [self productClickNicknamePrefixForString:nickName
                                                       maxLength:PLVLCProductClickNicknameMaxLength
                                                    didTruncate:&truncated];
    if (truncated) {
        return [prefix stringByAppendingString:@"... "];
    }
    return nickName;
}

/// 合并商品点击消息的昵称展示规则：
/// - mergedNames 是多个原始昵称用“、”拼接后的结果；
/// - 合并昵称不超过 5 个可见字符：展示“合并昵称 等N人 ”；
/// - 合并昵称超过 5 个可见字符：展示“前5个字符... 等N人 ”。
- (NSString *)displayNicknameForMergedProductClickMessages:(NSString *)mergedNames count:(NSUInteger)count {
    if (![PLVFdUtil checkStringUseable:mergedNames]) {
        mergedNames = PLVLocalizedString(@"观众");
    }
    
    BOOL truncated = NO;
    NSString *prefix = [self productClickNicknamePrefixForString:mergedNames
                                                       maxLength:PLVLCProductClickNicknameMaxLength
                                                    didTruncate:&truncated];
    NSString *displayName = truncated ? [prefix stringByAppendingString:@"..."] : prefix;
    return [NSString stringWithFormat:@"%@ 等%lu人 ", displayName, (unsigned long)count];
}

/// 生成溢出商品点击消息的合并昵称文案。
/// 注意这里先合并“原始昵称”，再统一截断；不要先截断每个用户昵称，避免出现双重截断。
- (NSString *)mergedNicknameTextForOverflowMessages:(NSArray<PLVChatModel *> *)overflowMessages {
    if (![PLVFdUtil checkArrayUseable:overflowMessages]) {
        return nil;
    }
    
    NSMutableArray<NSString *> *nameArray = [[NSMutableArray alloc] init];
    for (PLVChatModel *model in overflowMessages) {
        if (![model.message isKindOfClass:[PLVMessageEffectMessage class]]) {
            continue;
        }
        PLVMessageEffectMessage *message = (PLVMessageEffectMessage *)model.message;
        if ([PLVFdUtil checkStringUseable:message.nickName]) {
            [nameArray addObject:message.nickName];
        }
    }
    
    NSString *mergedNames = [nameArray componentsJoinedByString:@"、"];
    return [self displayNicknameForMergedProductClickMessages:mergedNames count:overflowMessages.count];
}

- (PLVChatModel *)buildOverflowSummaryChatModelWithMessages:(NSArray<PLVChatModel *> *)overflowMessages {
    if (![PLVFdUtil checkArrayUseable:overflowMessages]) {
        return nil;
    }
    
    PLVChatModel *baseModel = overflowMessages.firstObject;
    NSDictionary *payload = [self conversionPayloadWithChatModel:baseModel];
    if (![PLVFdUtil checkDictionaryUseable:payload]) {
        return nil;
    }
    
    NSMutableDictionary *summaryPayload = [payload mutableCopy];
    NSString *mergedNameText = [self mergedNicknameTextForOverflowMessages:overflowMessages];
    if ([PLVFdUtil checkStringUseable:mergedNameText]) {
        summaryPayload[@"nickName"] = mergedNameText;
    }
    return [self productClickSummaryChatModelWithPayload:[summaryPayload copy] displayNickName:mergedNameText];
}

- (void)notifyDelegatesSignInSuccessWithNickname:(NSString *)nickname {
    if (![PLVFdUtil checkStringUseable:nickname]) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_signInSuccessWithNickname:nickname];
    });
}

- (void)notifyDelegatesProductClickEffectMessage:(NSString *)message {
    if (![PLVFdUtil checkStringUseable:message]) {
        return;
    }
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate chatroomManager_productClickEffectMessage:message];
    });
}

#pragma mark - PLVSocketManager Protocol

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
        [self notifyDelegatesListenerRewardSuccess:contentDict];
    } else if ([subEvent isEqualToString:@"product"]) {
        [self productClickEventWithSubEvent:subEvent jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"SIGN_IN_TIMES"] ||
               [PLV_SafeStringForDictKey(jsonDict, @"EVENT") isEqualToString:@"SIGN_IN_TIMES"]) {
        NSString *nickname = PLV_SafeStringForDictKey(jsonDict, @"nick");
        if (![PLVFdUtil checkStringUseable:nickname]) {
            nickname = PLV_SafeStringForDictKey(jsonDict, @"nickName");
        }
        [self notifyDelegatesSignInSuccessWithNickname:nickname];
    }
}

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
    [self loadRewardEnable];
}

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = PLV_SafeDictionaryForValue(object);
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([event isEqualToString:PLVSocketCardPush_newsPush_key]) {
        NSString *newsPushEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
        if ([PLVFdUtil checkStringUseable:newsPushEvent]) {
            BOOL start = [newsPushEvent isEqualToString:@"start"];
            [self notifyDelegatesStartCardPush:start pushInfo:jsonDict];
        }
    } else if ([event isEqualToString:@"product"]) {
        [self productClickEventWithSubEvent:subEvent jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"SIGN_IN_TIMES"] ||
               [event isEqualToString:@"SIGN_IN_TIMES"] ||
               [PLV_SafeStringForDictKey(jsonDict, @"EVENT") isEqualToString:@"SIGN_IN_TIMES"]) {
        NSString *nickname = PLV_SafeStringForDictKey(jsonDict, @"nick");
        if (![PLVFdUtil checkStringUseable:nickname]) {
            nickname = PLV_SafeStringForDictKey(jsonDict, @"nickName");
        }
        [self notifyDelegatesSignInSuccessWithNickname:nickname];
    }
}


#pragma mark - PLVChatroomPresenterProtocol

- (void)chatroomPresenter_loadHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore {
    [self insertChatModels:modelArray noMore:noMore];
}

- (void)chatroomPresenter_loadHistoryFailure {
    [self notifyDelegatesLoadHistoryFailure];
}

- (void)chatroomPresenter_didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray {
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) {
        return;
    }

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

- (void)chatroomPresenter_receiveWarning:(NSString *)warning prohibitWord:(NSString *)word {
    [self notifyDelegatesDidSendProhibitMessage];
}

- (void)chatroomPresenter_loadImageEmotionsSuccess {
    [self notifyDelegatesLoadImageEmotionSuccess];
}

- (void)chatroomPresenter_loadImageEmotionsFailure {
    [self notifyDelegatesLoadImageEmotionFailure];
}

- (void)chatroomPresenter_didLoginRestrict {
    [self notifyDelegatesDidLoginRestrict];
}

- (void)chatroomPresenter_didChangeCloseRoom:(BOOL)closeRoom {
    [self notifyDelegatesCloseRoom:closeRoom];
}

- (void)chatroomPresenter_didChangeFocusMode:(BOOL)focusMode {
    self.focusMode = focusMode;
    [self notifyDelegatesFocusMode:focusMode];
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

- (BOOL)isConversionChatModel:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    if (![model.message isKindOfClass:[PLVMessageEffectMessage class]]) {
        return NO;
    }
    PLVMessageEffectMessage *message = (PLVMessageEffectMessage *)model.message;
    return [message isProductClickEffectMessage];
}

- (NSDictionary *)conversionPayloadWithChatModel:(PLVChatModel *)model {
    if (![self isConversionChatModel:model]) {
        return nil;
    }

    PLVMessageEffectMessage *message = (PLVMessageEffectMessage *)model.message;
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    if (message.type == PLVMessageEffectMessageTypeClickJobProduct) {
        payload[@"type"] = @"position";
    } else if (message.type == PLVMessageEffectMessageTypeClickFinancialProduct) {
        payload[@"type"] = @"finance";
    } else {
        payload[@"type"] = @"normal";
    }
    if ([PLVFdUtil checkStringUseable:message.rawType]) {
        payload[@"rawType"] = message.rawType;
    }
    if ([PLVFdUtil checkStringUseable:message.productName]) {
        payload[@"positionName"] = message.productName;
    }
    if ([PLVFdUtil checkStringUseable:message.nickName]) {
        payload[@"nickName"] = message.nickName;
    }
    if ([PLVFdUtil checkStringUseable:message.productId]) {
        payload[@"productId"] = message.productId;
    }
    return [payload copy];
}

@end
