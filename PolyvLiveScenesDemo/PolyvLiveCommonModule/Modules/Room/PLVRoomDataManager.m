//
//  PLVRoomDataManager.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVRoomDataManager.h"
#import <PolyvFoundationSDK/PLVMulticastDelegate.h>

extern NSString *PLVRoomDataKeyPathOnlineCount;
extern NSString *PLVRoomDataKeyPathLikeCount;
extern NSString *PLVRoomDataKeyPathWatchCount;
extern NSString *PLVRoomDataKeyPathPlaying;
extern NSString *PLVRoomDataKeyPathChannelInfo;
extern NSString *PLVRoomDataKeyPathMenuInfo;
extern NSString *PLVRoomDataKeyPathLiveState;

@interface PLVRoomDataManager ()

@property (nonatomic, strong) PLVRoomData *roomData;

@end

@implementation PLVRoomDataManager {
    // 多代理
    dispatch_queue_t multicastQueue;
    PLVMulticastDelegate<PLVRoomDataManagerProtocol> *multicastDelegate;
}

#pragma mark - 生命周期

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static PLVRoomDataManager *mananger = nil;
    dispatch_once(&onceToken, ^{
        mananger = [[self alloc] init];
    });
    return mananger;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 多代理
        multicastQueue = dispatch_queue_create("com.PolyvLiveScenesDemo.PLVRoomDataManager", DISPATCH_QUEUE_CONCURRENT);
        multicastDelegate = (PLVMulticastDelegate <PLVRoomDataManagerProtocol> *)[[PLVMulticastDelegate alloc] init];
    }
    return self;
}

- (void)configRoomData:(PLVRoomData *)roomData {
    self.roomData = roomData;
    [self addRoomDataObserver];
    
    //[self.roomData requestChannelDetail:nil];
    [self.roomData reportViewerIncrease];
}

- (void)removeRoomData {
    [self removeAllDelegates];
    [self removeRoomDataObserver];
    self.roomData = nil;
}

#pragma mark - KVO

- (void)addRoomDataObserver {
    [self.roomData addObserver:self forKeyPath:PLVRoomDataKeyPathOnlineCount options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [self.roomData addObserver:self forKeyPath:PLVRoomDataKeyPathLikeCount options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [self.roomData addObserver:self forKeyPath:PLVRoomDataKeyPathWatchCount options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [self.roomData addObserver:self forKeyPath:PLVRoomDataKeyPathPlaying options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [self.roomData addObserver:self forKeyPath:PLVRoomDataKeyPathChannelInfo options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [self.roomData addObserver:self forKeyPath:PLVRoomDataKeyPathMenuInfo options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [self.roomData addObserver:self forKeyPath:PLVRoomDataKeyPathLiveState options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
}

- (void)removeRoomDataObserver {
    [self.roomData removeObserver:self forKeyPath:PLVRoomDataKeyPathOnlineCount];
    [self.roomData removeObserver:self forKeyPath:PLVRoomDataKeyPathLikeCount];
    [self.roomData removeObserver:self forKeyPath:PLVRoomDataKeyPathWatchCount];
    [self.roomData removeObserver:self forKeyPath:PLVRoomDataKeyPathPlaying];
    [self.roomData removeObserver:self forKeyPath:PLVRoomDataKeyPathChannelInfo];
    [self.roomData removeObserver:self forKeyPath:PLVRoomDataKeyPathMenuInfo];
    [self.roomData removeObserver:self forKeyPath:PLVRoomDataKeyPathLiveState];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (![object isKindOfClass:[PLVRoomData class]]) {
        return;
    }
    
    if ([keyPath isEqualToString:PLVRoomDataKeyPathOnlineCount]) {
        [self notifyDelegatesDidOnlineCountChanged:self.roomData.onlineCount];
    } else if ([keyPath isEqualToString:PLVRoomDataKeyPathLikeCount]) {
        [self notifyDelegatesDidLikeCountChanged:self.roomData.likeCount];
    } else if ([keyPath isEqualToString:PLVRoomDataKeyPathWatchCount]) {
        [self notifyDelegatesDidWatchCountChanged:self.roomData.watchCount];
    } else if ([keyPath isEqualToString:PLVRoomDataKeyPathPlaying]) {
        [self notifyDelegatesDidPlayingStatusChanged:self.roomData.playing];
    } else if ([keyPath isEqualToString:PLVRoomDataKeyPathChannelInfo]) {
        [self notifyDelegatesDidChannelInfoChanged:self.roomData.channelInfo];
    } else if ([keyPath isEqualToString:PLVRoomDataKeyPathMenuInfo]) {
        [self notifyDelegatesDidMenuInfoChanged:self.roomData.menuInfo];
    } else if ([keyPath isEqualToString:PLVRoomDataKeyPathLiveState]) {
        [self notifyDelegatesDidLiveStateChanged:self.roomData.liveState];
    }
}

#pragma mark - Multicase

- (void)addDelegate:(id<PLVRoomDataManagerProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    });
}

- (void)removeDelegate:(id<PLVRoomDataManagerProtocol>)delegate {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeDelegate:delegate];
    });
}

- (void)removeAllDelegates {
    dispatch_barrier_async(multicastQueue, ^{
        [self->multicastDelegate removeAllDelegates];
    });
}

- (void)notifyDelegatesDidOnlineCountChanged:(NSUInteger)onlineCount {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate roomDataManager_didOnlineCountChanged:onlineCount];
    });
}

- (void)notifyDelegatesDidLikeCountChanged:(NSUInteger)likeCount {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate roomDataManager_didLikeCountChanged:likeCount];
    });
}

- (void)notifyDelegatesDidWatchCountChanged:(NSUInteger)watchCount {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate roomDataManager_didWatchCountChanged:watchCount];
    });
}

- (void)notifyDelegatesDidPlayingStatusChanged:(BOOL)playing {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate roomDataManager_didPlayingStatusChanged:playing];
    });
}

- (void)notifyDelegatesDidChannelInfoChanged:(PLVChannelInfoModel *)channelInfo {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate roomDataManager_didChannelInfoChanged:channelInfo];
    });
}

- (void)notifyDelegatesDidMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate roomDataManager_didMenuInfoChanged:menuInfo];
    });
}

- (void)notifyDelegatesDidLiveStateChanged:(PLVChannelLiveStreamState)liveState {
    dispatch_async(multicastQueue, ^{
        [self->multicastDelegate roomDataManager_didLiveStateChanged:liveState];
    });
}

@end
