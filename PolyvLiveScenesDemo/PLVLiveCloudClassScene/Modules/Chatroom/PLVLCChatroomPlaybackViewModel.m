//
//  PLVLCChatroomPlaybackViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCChatroomPlaybackViewModel.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

// 弹幕定时器时间间隔，单位'秒'
static NSInteger kDanmuIntervalTime = 1;
// 弹幕数组最大值
static NSInteger kDanmuMaxCount = 100;
// 公聊消息数组最大值
static NSInteger kChatArrayMaxCount = 500;

@interface PLVLCChatroomPlaybackViewModel ()<
PLVChatroomPlaybackPresenterDelegate
>

#pragma mark 外部可读属性

/// 频道号
@property (nonatomic, copy) NSString *channelId;
/// 当场回放的场次id
@property (nonatomic, copy) NSString *sessionId;
/// 当场回放的视频id
@property (nonatomic, copy) NSString *videoId;
/// 聊天回放common层presenter
@property (nonatomic, strong) PLVChatroomPlaybackPresenter *presenter;
/// 公聊消息数组，私聊无聊天回放
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArray;
/// 评论上墙最后一条消息模型
@property (nonatomic, strong) PLVChatModel *lastSpeakTopChatModel;

#pragma mark 内部属性

/// 上报需插入弹幕的文本，间隔 kDanmuIntervalTime 触发一次
@property (nonatomic, strong) NSTimer *danmuTimer;
/// 暂未上报的弹幕文本数组，数组最大容量kDanmuMaxCount
@property (nonatomic, strong) NSMutableArray <NSString *> *danmuArray;

/// 是否是重放模式
@property (nonatomic, assign) BOOL isReplayMode;

@end

@implementation PLVLCChatroomPlaybackViewModel {
    // 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _chatArrayLock;
    dispatch_semaphore_t _danmuArrayLock;
    
    // 多代理
    dispatch_queue_t multicastQueue;
    PLVMulticastDelegate<PLVLCChatroomPlaybackViewModelDelegate> *multicastDelegate;
}

#pragma mark - [ Override ]

- (void)dealloc {
    [self destroyTimer];
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId videoId:(NSString *)videoId isReplayMode:(BOOL)isReplayMode {
    self = [super init];
    if (self) {
        self.isReplayMode = isReplayMode;
        self.channelId = (channelId && [channelId isKindOfClass:[NSString class]]) ? channelId : @"";
        self.sessionId = (sessionId && [sessionId isKindOfClass:[NSString class]]) ? sessionId : @"";
        self.videoId = (videoId && [videoId isKindOfClass:[NSString class]]) ? videoId : @"";
        
        self.presenter = [[PLVChatroomPlaybackPresenter alloc] initWithChannelId:self.channelId sessionId:self.sessionId videoId:self.videoId isReplayMode:self.isReplayMode];
        self.presenter.delegate = self;
        
        // 多代理
        multicastQueue = dispatch_queue_create("com.PLVLiveScenesDemo.PLVLCChatroomPlaybackViewModel", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVLCChatroomPlaybackViewModelDelegate> *)[[PLVMulticastDelegate alloc] init];
        
        // 初始化公聊消息信号量、公聊消息数组
        _chatArrayLock = dispatch_semaphore_create(1);
        self.chatArray = [NSMutableArray arrayWithCapacity:kChatArrayMaxCount];
        
        // 初始化弹幕信号量、弹幕上报计时器、弹幕数组
        _danmuArrayLock = dispatch_semaphore_create(1);
        self.danmuArray = [[NSMutableArray alloc] initWithCapacity:kDanmuMaxCount];
        if (self.isReplayMode) {
            [self createTimer];
        } else {
            [self.presenter loadMorePlaybackChatMessage];
        }
    }
    return self;
}

- (void)updateDuration:(NSTimeInterval)duration {
    [self.presenter updateDuration:duration];
}

- (void)playbakTimeChanged {
    if (!self.isReplayMode)
        return;
    
    [self.presenter playbakTimeChanged];
}

- (void)loadMoreMessages {
    if (self.isReplayMode){
        // 聊天重放
        if ([self.chatArray count] > 0) {
            PLVChatModel *chatModel = self.chatArray[0];
            [self.presenter loadMoreMessageBefore:chatModel.playbackTime];
        } else {
            [self.presenter loadMoreMessageBefore:0];
        }
    }
    else{
        // 聊天回放
        [self.presenter loadMorePlaybackChatMessage];
    }
}

- (void)clear {
    [self replaceAllChatModels:@[]];
    [self removeAllDanmus];
    [self notifyDelegatesDidClearMessages];
}

#pragma mark - [ Private Method ]

#pragma mark Timer

- (void)createTimer {
    if (_danmuTimer) {
        [self destroyTimer];
    }
    _danmuTimer = [NSTimer scheduledTimerWithTimeInterval:kDanmuIntervalTime
                                                   target:[PLVFWeakProxy proxyWithTarget:self]
                                                 selector:@selector(danmuTimerAction)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)destroyTimer {
    [_danmuTimer invalidate];
    _danmuTimer = nil;
}

#pragma mark Multicase

- (void)addUIDelegate:(id<PLVLCChatroomPlaybackViewModelDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    });
}

- (void)removeUIDelegate:(id<PLVLCChatroomPlaybackViewModelDelegate>)delegate {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeDelegate:delegate];
    });
}

- (void)removeAllUIDelegates {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeAllDelegates];
    });
}

- (void)notifyDelegatesDidClearMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate clearMessageForPlaybackViewModel:self];
    });
}

- (void)notifyDelegatesDidReceiveNewMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate didReceiveNewMessagesForChatroomPlaybackViewModel:self];
    });
}

- (void)notifyDelegatesDidMessagesRefreshed {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate didMessagesRefreshedForChatroomPlaybackViewModel:self];
    });
}

- (void)notifyDelegatesDidLoadMoreHistoryMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:self];
    });
}

- (void)notifyDelegatesLoadMessageInfoSuccess:(BOOL)success {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate loadMessageInfoSuccess:success playbackViewModel:self];
    });
}

#pragma mark 聊天消息数组

/// 插入数据到消息数组的头部，此时不会限制数组的总量，因为如果限制总量，裁剪的都是消息数组的头部的消息
/// 其实不管头部还是尾部，都会使用'-rearrangeChatModels:'方法进行排序、去重
- (void)insertChatModels:(NSArray <PLVChatModel *> *)modelArray {
    if (![PLVFdUtil checkArrayUseable:modelArray]) {
        return;
    }
    
    NSInteger count = [modelArray count] + [self.chatArray count];
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:count];
    [muArray addObjectsFromArray:modelArray];
    [muArray addObjectsFromArray:[self.chatArray copy]];
    
    NSArray *arrangeArray = [self rearrangeChatModels:[muArray copy]];
    [self replaceAllChatModels:arrangeArray];
}

/// 插入消息到数组的尾部，此时会对数组的总量进行限制
/// 其实不管头部还是尾部，都会使用'-rearrangeChatModels:'方法进行排序、去重
- (void)addChatModels:(NSArray <PLVChatModel *> *)modelArray {
    if (![PLVFdUtil checkArrayUseable:modelArray]) {
        return;
    }
    
    NSInteger count = [modelArray count] + [self.chatArray count];
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:count];
    [muArray addObjectsFromArray:modelArray];
    [muArray addObjectsFromArray:[self.chatArray copy]];
    
    NSArray *arrangeArray = [self rearrangeChatModels:[muArray copy]];
    if ([arrangeArray count] >= kChatArrayMaxCount) {
        arrangeArray = [arrangeArray subarrayWithRange:NSMakeRange([arrangeArray count] - kChatArrayMaxCount, kChatArrayMaxCount)];
    }
    
    [self replaceAllChatModels:arrangeArray];
}

/// 全量替换消息数组的数据
- (void)replaceAllChatModels:(NSArray <PLVChatModel *> *)modelArray {
    NSArray *arrangeArray = [self rearrangeChatModels:modelArray];
    
    dispatch_semaphore_wait(_chatArrayLock, DISPATCH_TIME_FOREVER);
    [self.chatArray removeAllObjects];
    [self.chatArray addObjectsFromArray:arrangeArray];
    dispatch_semaphore_signal(_chatArrayLock);
}

// 根据msgId对数组的数据进行去重，再根据playbackTime字段进行重新排序
- (NSArray *)rearrangeChatModels:(NSArray <PLVChatModel *> *)array {
    if (![PLVFdUtil checkArrayUseable:array]) {
        return @[];
    }
    
    // 数据去重
    NSMutableSet *muSet = [[NSMutableSet alloc] init];
    [muSet addObjectsFromArray:array];
    // 数据排序
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playbackTime" ascending:YES];
    NSArray *sortedArray = [[muSet copy] sortedArrayUsingDescriptors:@[sortDescriptor]];
    return sortedArray;
}

#pragma mark 弹幕数组

- (void)addDanmuFromChatModels:(NSArray <PLVChatModel *> *)modelArray {
    if (!self.danmuTimer || !self.danmuTimer.valid) {// 如果没有上报任务则无需统计登录数据
        return;
    }
    
    dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
    if ([self.danmuArray count] >= kDanmuMaxCount) {
        [self.danmuArray removeAllObjects];
    }
    dispatch_semaphore_signal(_danmuArrayLock);
    
    int i = 0;
    for (PLVChatModel *model in modelArray) {
        NSString *content = [model content];
        if (content && [content isKindOfClass:[NSString class]] && content.length > 0) {
            i++;
            dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
            [self.danmuArray addObject:content];
            dispatch_semaphore_signal(_danmuArrayLock);
            if (i == 20) {
                break;
            }
        }
    }
}

- (NSString *)popDanmuAtIndexZero {
    NSString *danmu = nil;
    dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
    if ([self.danmuArray count] > 0) {
        danmu = self.danmuArray[0];
        [self.danmuArray removeObjectAtIndex:0];
    }
    dispatch_semaphore_signal(_danmuArrayLock);
    return danmu;
}

- (void)removeAllDanmus {
    dispatch_semaphore_wait(_danmuArrayLock, DISPATCH_TIME_FOREVER);
    [self.danmuArray removeAllObjects];
    dispatch_semaphore_signal(_danmuArrayLock);
}

#pragma mark - [ Event ]

#pragma mark Timer

- (void)danmuTimerAction {
    NSString *danmu = [self popDanmuAtIndexZero];
    if (danmu &&
        self.delegate &&
        [self.delegate respondsToSelector:@selector(didReceiveDanmu:chatroomPlaybackViewModel:)]) {
        [self.delegate didReceiveDanmu:danmu chatroomPlaybackViewModel:self];
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVChatroomPlaybackPresenterDelegate

- (void)loadMessageInfoSuccess:(BOOL)success playbackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    [self notifyDelegatesLoadMessageInfoSuccess:success];
}

- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(currentPlaybackTimeForChatroomPlaybackViewModel:)]) {
        return [self.delegate currentPlaybackTimeForChatroomPlaybackViewModel:self];
    }
    
    return 0;
}

- (void)didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    if ([PLVFdUtil checkArrayUseable:modelArray]) {
        [self addChatModels:modelArray];
        [self notifyDelegatesDidReceiveNewMessages];
        
        [self addDanmuFromChatModels:modelArray];
    }
}

- (void)didChatModelsRefreshedForChatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    [self replaceAllChatModels:@[]];
    [self notifyDelegatesDidMessagesRefreshed];
    
    [self removeAllDanmus];
    self.lastSpeakTopChatModel = nil;
}

- (void)didLoadMoreChatModels:(NSArray <PLVChatModel *> *)modelArray chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    [self insertChatModels:modelArray];
    [self notifyDelegatesDidLoadMoreHistoryMessages];
}

- (void)didReceiveSpeakTopChatModels:(NSArray <PLVChatModel *> *)modelArray
                            autoLoad:(BOOL)autoLoad
           chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    BOOL showPinMsg = NO;
    if ([PLVFdUtil checkArrayUseable:modelArray]) {
        NSArray<PLVChatModel *>*arrangeArray = [self rearrangeChatModels:[modelArray copy]];
        self.lastSpeakTopChatModel = arrangeArray.lastObject;
    }
    if (self.lastSpeakTopChatModel) {
        PLVSpeakTopMessage *speakTopMessage = self.lastSpeakTopChatModel.message;
        if ([speakTopMessage.action isEqualToString:@"top"]) {
            showPinMsg = YES;
        }
    }
    
    if (!autoLoad || (autoLoad && [PLVFdUtil checkArrayUseable:modelArray])) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(didReceiveSpeakTopMessageChatModel:showPinMsgView:chatroomPlaybackViewModel:)]) {
            return [self.delegate didReceiveSpeakTopMessageChatModel:self.lastSpeakTopChatModel showPinMsgView:showPinMsg chatroomPlaybackViewModel:self];
        }
    }
}

@end
