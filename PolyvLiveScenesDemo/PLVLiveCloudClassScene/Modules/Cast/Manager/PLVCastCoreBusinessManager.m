//
//  PLVCastCoreBusinessManager.m
//  PLVCloudClassSDK
//
//  Created by MissYasiky on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCastCoreBusinessManager.h"
#import "PLVCastClient.h"
#import "PLVCastNotificaion.h"

@implementation PLVCastCoreBusinessManager

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addObserver];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver];
}

#pragma mark - Initialize

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castAuthorizeNotification:) name:PLVCast_Authorize_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castEnterLiveNotification:) name:PLVCast_EnterLiveRoom_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castLeaveLiveNotification:) name:PLVCast_LeaveLiveRoom_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castStartNotification:) name:PLVCast_ConnectStart_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castSuccessNotification:) name:PLVCast_ConnectSuccess_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castDisconnectNotification:) name:PLVCast_Disconnect_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castConnectErrorNotification:) name:PLVCast_ConnectError_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castPlayErrorNotification:) name:PLVCast_PlayError_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castPlayStateChangedNotification:) name:PLVCast_PlayStateChanged_Notification object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

+ (instancetype)sharedManager {
    static PLVCastCoreBusinessManager *mananger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mananger = [[self alloc] init];
    });
    return mananger;
}

- (void)startAuthorize {
    [PLVCastClient startAuthorize];
}

- (void)quit {
    [[PLVCastClient sharedClient] quit];
}

#pragma mark - NSNotificaion

- (void)castAuthorizeNotification:(NSNotification *)notif {
    BOOL success = [notif.object boolValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(castAuthorize:)]) {
        [self.delegate castAuthorize:success];
    }
}

- (void)castEnterLiveNotification:(NSNotification *)notif {
    NSString *channnelId = (NSString *)notif.object;
    if (self.delegate && [self.delegate respondsToSelector:@selector(castEnterLiveRoom:)]) {
        [self.delegate castEnterLiveRoom:channnelId];
    }
}

- (void)castLeaveLiveNotification:(NSNotification *)notif {
    NSString *channnelId = (NSString *)notif.object;
    if (self.delegate && [self.delegate respondsToSelector:@selector(castLeaveLiveRoom:)]) {
        [self.delegate castLeaveLiveRoom:channnelId];
    }
}

- (void)castStartNotification:(NSNotification *)notif {
    if (self.delegate && [self.delegate respondsToSelector:@selector(castConnectStart)]) {
        [self.delegate castConnectStart];
    }
}

- (void)castSuccessNotification:(NSNotification *)notif {
    if (self.delegate && [self.delegate respondsToSelector:@selector(castConnectSuccess)]) {
        [self.delegate castConnectSuccess];
    }
}

- (void)castDisconnectNotification:(NSNotification *)notif {
    if (self.delegate && [self.delegate respondsToSelector:@selector(castDisconnect)]) {
        [self.delegate castDisconnect];
    }
}

- (void)castConnectErrorNotification:(NSNotification *)notif {
    NSError *error = (NSError *)notif.object;
    if (self.delegate && [self.delegate respondsToSelector:@selector(castConnectError:)]) {
        [self.delegate castConnectError:error];
    }
}

- (void)castPlayErrorNotification:(NSNotification *)notif {
    NSError *error = (NSError *)notif.object;
    if (self.delegate && [self.delegate respondsToSelector:@selector(castPlayError:)]) {
        [self.delegate castPlayError:error];
    }
}

- (void)castPlayStateChangedNotification:(NSNotification *)notif {
    PLVCastPlayStatus status = [notif.object unsignedIntegerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(castPlayStatus:)]) {
        [self.delegate castPlayStatus:status];
    }
}

@end
