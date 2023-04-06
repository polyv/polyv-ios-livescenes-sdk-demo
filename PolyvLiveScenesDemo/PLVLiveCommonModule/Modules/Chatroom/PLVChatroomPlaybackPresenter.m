//
//  PLVChatroomPlaybackPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVChatroomPlaybackPresenter.h"
#import "PLVChatUser.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

// 定时器触发回调时间间隔，单位'秒'
static NSInteger kIntervalTime = 0.2;

@interface PLVChatroomPlaybackPresenter ()<
PLVPlaybackMessageManagerDelegate
>

/// 频道号
@property (nonatomic, copy) NSString *channelId;
/// 回放场次id
@property (nonatomic, copy) NSString *sessionId;
/// 回放视频id
@property (nonatomic, copy) NSString *videoId;
/// 回调定时器
@property (nonatomic, strong) NSTimer *timer;
/// 当前视频播放时间戳，单位毫秒
@property (nonatomic, assign) NSTimeInterval currentPlaybackTime;
/// 回放视频总时长，单位毫秒
@property (nonatomic, assign) NSTimeInterval duration;
/// 回放消息管理器
@property (nonatomic, strong) PLVPlaybackMessageManager *manager;

@end

@implementation PLVChatroomPlaybackPresenter

#pragma mark - [ Life Cycle ]

#pragma mark - [ Override ]

- (void)dealloc {
    [self destroyTimer];
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId videoId:(NSString *)videoId {
    self = [super init];
    if (self) {
        self.channelId = (channelId && [channelId isKindOfClass:[NSString class]]) ? channelId : @"";
        self.sessionId = (sessionId && [sessionId isKindOfClass:[NSString class]]) ? sessionId : @"";
        self.videoId = (videoId && [videoId isKindOfClass:[NSString class]]) ? videoId : @"";
        
        self.manager = [[PLVPlaybackMessageManager alloc] initWithChannelId:self.channelId sessionId:self.sessionId videoId:self.videoId];
        self.manager.delegate = self;
        
        // 创建定时器
        [self createTimer];
    }
    return self;
}

- (void)updateDuration:(NSTimeInterval)duration {
    if (duration > 0 && duration != self.duration) { // 注意这里self.duration单位是毫秒
        self.duration = duration * 1000;
    }
}

- (void)playbakTimeChanged {
    NSTimeInterval playbackTime = [self getPlaybackTime];
    if (playbackTime >= 0) {
        if (self.currentPlaybackTime == playbackTime) { // 播放进度未发生变化，无需做任何处理
            return;
        }
        
        // 更新当前播放时间
        self.currentPlaybackTime = playbackTime;
        
        if ([self.delegate respondsToSelector:@selector(didChatModelsRefreshedForChatroomPlaybackPresenter:)]) {
            [self.delegate didChatModelsRefreshedForChatroomPlaybackPresenter:self];
        }
        
        [self.manager loadMorePlaybackMessagBefore:self.currentPlaybackTime];
    }
}

- (void)loadMoreMessageBefore:(NSTimeInterval)playbackTime {
    [self.manager loadMorePlaybackMessagBefore:playbackTime];
}

#pragma mark - [ Private Method ]

- (NSArray <PLVChatModel *> *)chatModelArrayFromPlaybackMessageArray:(NSArray <PLVPlaybackMessage *> *)playbackMessageArray {
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:[playbackMessageArray count]];
    for (PLVPlaybackMessage *playbackMessage in playbackMessageArray) {
        PLVChatModel *chatModel = [PLVChatModel chatModelFromPlaybackMessage:playbackMessage];
        [muArray addObject:chatModel];
    }
    return [muArray copy];
}

/// 获取当前播放时间节点，单位毫秒，异常情况时返回-1
- (NSTimeInterval)getPlaybackTime {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(currentPlaybackTimeForChatroomPlaybackPresenter:)]) {
        NSTimeInterval time = [self.delegate currentPlaybackTimeForChatroomPlaybackPresenter:self];
        time = MAX(0, time); // time表示回放视频当前播放时间戳，单位秒
        return time * 1000;
    } else {
        return -1;
    }
}

#pragma mark Timer

- (void)createTimer {
    if (_timer) {
        [self destroyTimer];
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:kIntervalTime
                                              target:[PLVFWeakProxy proxyWithTarget:self]
                                            selector:@selector(timerAction:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)destroyTimer {
    [_timer invalidate];
    _timer = nil;
}

#pragma mark - [ Event ]

#pragma mark Timer

- (void)timerAction:(NSTimer *)timer {
    NSTimeInterval playbackTime = [self getPlaybackTime];
    if (playbackTime >= 0) {
        if (self.currentPlaybackTime == playbackTime) { // 播放进度未发生变化，无需做任何处理
            return;
        }
        
        NSTimeInterval lastPlaybackTime = self.currentPlaybackTime;
        if (self.duration > 0 &&
            playbackTime < lastPlaybackTime &&
            fabs(lastPlaybackTime - self.duration) < 500 && playbackTime < 500) { // 此时可假设视频播放结束后重新从头播放
            [self playbakTimeChanged];
            return;
        }
        
        self.currentPlaybackTime = playbackTime;
        if (self.currentPlaybackTime <= lastPlaybackTime) { // 视频播放时间出现后推时不予处理
            return;
        }
        
        NSArray <PLVPlaybackMessage *>*messageArray = [self.manager playbackMessagInPreloadMessagesFrom:lastPlaybackTime to:self.currentPlaybackTime];
        if ([messageArray count] == 0) {
            return;
        }
        
        NSArray <PLVChatModel *>*chatModelArray = [self chatModelArrayFromPlaybackMessageArray:messageArray];
        if ([self.delegate respondsToSelector:@selector(didReceiveChatModels:chatroomPlaybackPresenter:)]) {
            [self.delegate didReceiveChatModels:chatModelArray chatroomPlaybackPresenter:self];
        }
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVPlaybackMessageManagerDelegate

- (void)loadMessageInfoSuccess:(BOOL)success playbackMessageManager:(PLVPlaybackMessageManager *)manager {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(loadMessageInfoSuccess:playbackPresenter:)]) {
        [self.delegate loadMessageInfoSuccess:success playbackPresenter:self];
    }
}

- (NSTimeInterval)currentPlaybackTimeForPlaybackMessageManager:(PLVPlaybackMessageManager *)manager {
    return self.currentPlaybackTime;
}

- (void)loadMoreHistoryMessagesSuccess:(NSArray <PLVPlaybackMessage *>*)playbackMessags playbackMessageManager:(PLVPlaybackMessageManager *)manager {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(didLoadMoreChatModels:chatroomPlaybackPresenter:)]) {
        if ([playbackMessags count] > 0) {
            NSArray <PLVChatModel *>*chatModelArray = [self chatModelArrayFromPlaybackMessageArray:playbackMessags];
            [self.delegate didLoadMoreChatModels:chatModelArray chatroomPlaybackPresenter:self];
        } else { // 空数据也要触发回调，否则下拉控件不会停止旋转动画
            [self.delegate didLoadMoreChatModels:@[] chatroomPlaybackPresenter:self];
        }
    }
}

@end
