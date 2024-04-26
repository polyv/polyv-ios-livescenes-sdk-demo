//
//  PLVECChatroomPlaybackViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVECChatroomPlaybackViewModel.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

// 公聊消息数组最大值
static NSInteger kChatArrayMaxCount = 500;

@interface PLVECChatroomPlaybackViewModel ()<
PLVChatroomPlaybackPresenterDelegate
>

/// 频道号
@property (nonatomic, copy) NSString *channelId;
/// 当场回放场次id
@property (nonatomic, copy) NSString *sessionId;
/// 当场回放视频id
@property (nonatomic, copy) NSString *videoId;
/// 当场回放视频总时长，单位秒
@property (nonatomic, assign) NSTimeInterval duration;
/// 当前视频播放时间戳，单位秒
@property (nonatomic, assign) NSTimeInterval currentPlaybackTime;
/// 聊天重放common层presenter
@property (nonatomic, strong) PLVChatroomPlaybackPresenter *presenter;
/// 公聊消息数组
@property (nonatomic, strong) NSMutableArray <PLVChatModel *> *chatArray;

@end

@implementation PLVECChatroomPlaybackViewModel {
    // 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _chatArrayLock;
    
    // 多代理
    dispatch_queue_t multicastQueue;
    PLVMulticastDelegate<PLVECChatroomPlaybackViewModelDelegate> *multicastDelegate;
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId videoId:(NSString *)videoId {
    self = [super init];
    if (self) {
        self.channelId = (channelId && [channelId isKindOfClass:[NSString class]]) ? channelId : @"";
        self.sessionId = (sessionId && [sessionId isKindOfClass:[NSString class]]) ? sessionId : @"";
        self.videoId = (videoId && [videoId isKindOfClass:[NSString class]]) ? videoId : @"";
        
        self.presenter = [[PLVChatroomPlaybackPresenter alloc] initWithChannelId:self.channelId sessionId:self.sessionId videoId:self.videoId];
        self.presenter.delegate = self;
        
        // 多代理
        multicastQueue = dispatch_queue_create("com.PLVLiveScenesDemo.PLVECChatroomPlaybackViewModel", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVECChatroomPlaybackViewModelDelegate> *)[[PLVMulticastDelegate alloc] init];
        
        // 初始化公聊消息信号量、公聊消息数组
        _chatArrayLock = dispatch_semaphore_create(1);
        self.chatArray = [NSMutableArray arrayWithCapacity:kChatArrayMaxCount];
    }
    return self;
}

- (void)updateDuration:(NSTimeInterval)duration {
    if (duration > 0 && duration != self.duration) {
        self.duration = duration;
        [self.presenter updateDuration:self.duration];
    }
}

- (void)playbakTimeChanged {
    [self.presenter playbakTimeChanged];
}

- (void)loadMoreMessages {
    if ([self.chatArray count] > 0) {
        PLVChatModel *chatModel = self.chatArray[0];
        [self.presenter loadMoreMessageBefore:chatModel.playbackTime];
    } else {
        [self.presenter loadMoreMessageBefore:self.currentPlaybackTime];
    }
}

- (void)clear {
    [self replaceAllChatModels:@[]];
    [self notifyDelegateDidClearMessages];
    [self removeAllUIDelegates];
}

#pragma mark - [ Private Method ]

#pragma mark Multicase

- (void)addUIDelegate:(id<PLVECChatroomPlaybackViewModelDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    });
}

- (void)removeUIDelegate:(id<PLVECChatroomPlaybackViewModelDelegate>)delegate {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeDelegate:delegate];
    });
}

- (void)removeAllUIDelegates {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeAllDelegates];
    });
}

- (void)notifyDelegateDidClearMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate clearMessageForPlaybackViewModel:self];
    });
}

- (void)notifyDelegateDidLoadMessageInfoSuccess:(BOOL)success {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate loadMessageInfoSuccess:success playbackViewModel:self];
    });
}

- (void)notifyDelegateDidReceiveNewMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate didReceiveNewMessagesForChatroomPlaybackViewModel:self];
    });
}

- (void)notifyDelegateDidMessagesRefreshed {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate didMessagesRefreshedForChatroomPlaybackViewModel:self];
    });
}

- (void)notifyDelegateDidLoadMoreHistoryMessages {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:self];
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

#pragma mark - [ Delegate ]

#pragma mark PLVChatroomPlaybackPresenterDelegate

- (void)loadMessageInfoSuccess:(BOOL)success playbackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    [self notifyDelegateDidLoadMessageInfoSuccess:success];
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
        [self notifyDelegateDidReceiveNewMessages];
    }
}

- (void)didChatModelsRefreshedForChatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    [self replaceAllChatModels:@[]];
    [self notifyDelegateDidMessagesRefreshed];
}

- (void)didLoadMoreChatModels:(NSArray <PLVChatModel *> *)modelArray chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter {
    [self insertChatModels:modelArray];
    [self notifyDelegateDidLoadMoreHistoryMessages];
}

@end
