//
//  PLVCastCoreManager.m
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/14.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCastCoreManager.h"
#import "PLVNetworkDetactor.h"
#import "PLVCastNotificaion.h"
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>
#import <PLVDLNA/PLVDLNA.h>

#define PLVSearchingTime 5 // 搜索持续时间
#define PLVStatusPollingTime 2 // 状态轮询间隔

@interface PLVCastCoreManager () <PLVFindDeviceDelegate, PLVControlDeviceDelegate>

/// 乐播 SDK 是否已授权成功
@property (class, nonatomic, assign) BOOL authSuccess;

@property (nonatomic, strong) NSMutableArray <PLVCastServiceModel *>*plv_servicesArr;
@property (nonatomic, strong) NSArray <PLVUPnPDevice *>*discoveredDevices; // 保存原始设备列表
@property (nonatomic, strong) PLVControlDevice *controlDevice; // 当前控制的设备
@property (nonatomic, strong) NSTimer *searchTimer;
@property (nonatomic, strong) NSTimer *statusPollingTimer; // 播放状态轮询
@property (nonatomic, strong) PLVNetworkDetactor *networkDetactor;
@property (nonatomic, assign) BOOL connecting;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) BOOL startService;
@property (nonatomic, assign) NSInteger retryCount; // 重试计数器

- (void)addCastServiceModel:(PLVCastServiceModel *)model;
- (void)removeCastServiceModel:(PLVCastServiceModel *)model;
- (void)updateCaseServiceId:(NSString *)TVUid state:(NSString *)state;

@end

@implementation PLVCastCoreManager

static BOOL _authSuccess = NO;

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.networkDetactor = [[PLVNetworkDetactor alloc] init];
        _lock = [[NSLock alloc] init];
        _retryCount = 0;
    }
    return self;
}

- (void)dealloc {
    [self stopTimer];
    [self stopStatusPolling];
}

#pragma mark - Getter & Setter

+ (BOOL)authSuccess {
    return _authSuccess;
}

+ (void)setAuthSuccess:(BOOL)authSuccess {
    _authSuccess = authSuccess;
}

- (NSMutableArray *)plv_servicesArr {
    if (!_plv_servicesArr) {
        _plv_servicesArr = [[NSMutableArray alloc] init];
    }
    return _plv_servicesArr;
}

#pragma mark - Public

+ (BOOL)isAuthorizeSuccess {
    return self.authSuccess;
}

+ (void)startAuthorize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // PLVDLNA 无需AppID/SecretKey，直接认为授权成功
        PLVCastCoreManager.authSuccess = YES;
        // 设置设备发现的代理
        [[PLVFindDevice sharedInstance] setDelegate:[PLVCastCoreManager sharedManager]];
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVCast_Authorize_Notification object:@(PLVCastCoreManager.authSuccess)];
    });
}

+ (instancetype)sharedManager {
    static PLVCastCoreManager *mananger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mananger = [[self alloc] init];
    });
    return mananger;
}

- (void)clear {
    [self stopSearchService];
    [self disconnect];
    
    // 确保完全清理状态
    self.startService = NO;
    self.retryCount = 0; // 重置重试计数器
    [self.plv_servicesArr removeAllObjects];
    self.discoveredDevices = nil;
    
    // 给一点时间让socket完全释放
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"PLVCastCoreManager - Clear completed, all resources released");
    });
}

#pragma mark 设备搜索操作

- (void)startSearchService {
    if (![self.networkDetactor isWIFIReachable]) {
        return;
    }
    
    // 确保之前的搜索已完全停止，避免socket绑定冲突
    if (self.startService) {
        [[PLVFindDevice sharedInstance] stopFindDevice];
        // 等待一小段时间确保socket完全释放
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performStartSearchService];
        });
    } else {
        [self performStartSearchService];
    }
}

- (void)performStartSearchService {
    // 如果已经在搜索中，避免重复启动
    if (self.startService) {
        NSLog(@"PLVCastCoreManager - Search service already running, skipping duplicate start");
        return;
    }
    
    [[PLVFindDevice sharedInstance] startFindDevice];
    self.startService = YES;
    
    // 重置重试计数器，因为开始新的搜索
    self.retryCount = 0;
    
    // 回调搜索状态
    if ([self.deviceDelegate respondsToSelector:@selector(castManagerSearchStateChanged:)]) {
        [self.deviceDelegate castManagerSearchStateChanged:YES];
    }
    
    [self createFutureEvent];
}

- (void)stopSearchService {
    if (self.startService) {
        [[PLVFindDevice sharedInstance] stopFindDevice];
        self.startService = NO;
        
        // 回调搜索状态
        if ([self.deviceDelegate respondsToSelector:@selector(castManagerSearchStateChanged:)]) {
            [self.deviceDelegate castManagerSearchStateChanged:NO];
        }
        
        [self stopTimer];
    }
}

#pragma mark 设备连接操作

- (PLVCastServiceModel *)connectServiceWithDeviceName:(NSString *)deviceName {
    PLVCastServiceModel *plv_s = [self getPlvServiceInfoWithDeviceName:deviceName];
    if (plv_s) {
        [self connectServiceWithModel:plv_s];
    }
    return plv_s;
}

- (void)connectServiceWithModel:(PLVCastServiceModel *)plv_s {
    if (!plv_s.tvUID || ![plv_s.tvUID isKindOfClass: [NSString class]] || plv_s.tvUID.length == 0) {
        // 通知连接失败 - 设备信息无效
        NSError *error = [NSError errorWithDomain:@"PLVCastError" 
                                             code:-1002 
                                         userInfo:@{NSLocalizedDescriptionKey: @"设备信息无效"}];
        if ([self.delegate respondsToSelector:@selector(castManagerOnError:)]) {
            [self.delegate castManagerOnError:error];
        }
        return;
    }
    
    self.connecting = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVCast_ConnectStart_Notification object:nil];
    
    PLVUPnPDevice *targetDevice = nil;
    for (PLVUPnPDevice *device in self.discoveredDevices) {
        if ([device.uuid isEqualToString:plv_s.tvUID]) {
            targetDevice = device;
            break;
        }
    }
    
    if (!targetDevice) {
        NSLog(@"PLVCastCoreManager - Error: Could not find target device in discovered list.");
        self.connecting = NO;
        
        // 通知连接失败
        NSError *error = [NSError errorWithDomain:@"PLVCastError" 
                                             code:-1001 
                                         userInfo:@{NSLocalizedDescriptionKey: @"找不到目标设备"}];
        if ([self.delegate respondsToSelector:@selector(castManagerOnError:)]) {
            [self.delegate castManagerOnError:error];
        }
        return;
    }
    
    // 如果当前已有连接，先断开
    if (self.controlDevice) {
        [self disconnect];
    }
    
    self.controlDevice = [[PLVControlDevice alloc] initWithDevice:targetDevice];
    self.controlDevice.delegate = self;
    self.connecting = NO;
    
    if ([self.delegate respondsToSelector:@selector(castManagerDidConnectedWithService:)]) {
        [self.delegate castManagerDidConnectedWithService:plv_s];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVCast_ConnectSuccess_Notification object:nil];
}

- (void)disconnect {
    if (self.controlDevice) {
        [self.controlDevice stop];
        self.controlDevice.delegate = nil;
        self.controlDevice = nil;
        [self stopStatusPolling];
    }
}

- (BOOL)isServiceConnecting:(PLVCastServiceModel *)service {
    return self.connecting && [self.controlDevice.device.uuid isEqualToString:service.tvUID];
}

#pragma mark 设备播放操作

- (void)startPlayWithUrlString:(NSString *)urlString {
    if (!urlString || ![urlString isKindOfClass: [NSString class]] || urlString.length == 0) {
        NSLog(@"PLVCastCoreManager - 播放链接非法 链接：%@",urlString);
        return;
    } else if (!self.controlDevice) {
        NSLog(@"PLVCastCoreManager - 投屏设备未连接");
        return;
    }
    
    [self.controlDevice setAVTransportURL:urlString];
}

- (void)pause {
    if (!self.controlDevice) return;
    [self.controlDevice pause];
}

- (void)resume {
    if (!self.controlDevice) return;
    [self.controlDevice play];
}

- (void)seekTo:(NSInteger)seekTime {
    if (!self.controlDevice) return;
    [self.controlDevice seekToTime:(float)seekTime];
}

- (NSString *)formatSeekTime:(NSInteger)seekTime {
    NSInteger hours = seekTime / 3600;
    NSInteger minutes = (seekTime % 3600) / 60;
    NSInteger seconds = seekTime % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

- (void)stop {
    [self disconnect];
}

- (void)addVolume {
    if (!self.controlDevice) return;
    [self.controlDevice setVolumeIncre:5];
}

- (void)reduceVolume {
    if (!self.controlDevice) return;
    [self.controlDevice setVolumeIncre:-5];
}

- (void)setVolume:(NSInteger)value {
    if (!self.controlDevice) return;
    [self.controlDevice setVolume:(int)value];
}

#pragma mark - Timer

- (void)createFutureEvent {
    [self stopTimer];
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:PLVSearchingTime target:self selector:@selector(timeEvent:) userInfo:nil repeats:NO];
}

- (void)stopTimer {
    if (_searchTimer) {
        [_searchTimer invalidate];
        _searchTimer = nil;
    }
}

- (void)timeEvent:(NSTimer *)timer {
    [self stopSearchService];
}

- (void)startStatusPolling {
    [self stopStatusPolling];
    self.statusPollingTimer = [NSTimer scheduledTimerWithTimeInterval:PLVStatusPollingTime
                                                               target:self
                                                             selector:@selector(pollStatus)
                                                             userInfo:nil
                                                              repeats:YES];
}

- (void)stopStatusPolling {
    if (self.statusPollingTimer) {
        [self.statusPollingTimer invalidate];
        self.statusPollingTimer = nil;
    }
}

- (void)pollStatus {
    if (self.controlDevice) {
        [self.controlDevice getTransportInfo];
    } else {
        [self stopStatusPolling];
    }
}

#pragma mark - PLVFindDeviceDelegate

- (void)plv_UPnPDeviceChanged:(NSArray<PLVUPnPDevice *> *)devices {
    // 成功发现设备，重置重试计数器
    self.retryCount = 0;
    
    self.discoveredDevices = devices;
    [self.plv_servicesArr removeAllObjects];
    for (PLVUPnPDevice *device in devices) {
        PLVCastServiceModel *model = [[PLVCastServiceModel alloc] init];
        model.deviceName = device.friendlyName;
        model.tvUID = device.uuid;
        [self.plv_servicesArr addObject:model];
    }
    
    if ([self.deviceDelegate respondsToSelector:@selector(castManagerFindServices:)]) {
        [self.deviceDelegate castManagerFindServices:self.plv_servicesArr];
    }
}

- (void)plv_UPnPDeviceFindFaild:(NSError *)error {
    NSLog(@"PLVCastCoreManager - Find device failed: %@", error);
    
    // 如果是地址已被占用错误，尝试重新启动搜索（最多重试3次）
    if (error.code == 48 && [error.domain isEqualToString:NSPOSIXErrorDomain] && self.retryCount < 3) {
        self.retryCount++;
        NSLog(@"PLVCastCoreManager - Socket binding conflict detected, attempting recovery (attempt %ld/3)...", (long)self.retryCount);
        
        // 停止当前搜索
        self.startService = NO;
        [[PLVFindDevice sharedInstance] stopFindDevice];
        
        // 延迟重试，给socket更多时间释放
        NSTimeInterval delay = self.retryCount * 1.0; // 递增延迟时间，增加到1秒倍数
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 检查网络状态
            if (![self.networkDetactor isWIFIReachable]) {
                NSLog(@"PLVCastCoreManager - WiFi not available during retry, aborting");
                self.retryCount = 0;
                return;
            }
            
            NSLog(@"PLVCastCoreManager - Retrying device discovery after socket cleanup (delay: %.1fs)", delay);
            // 直接调用底层搜索，避免重新进入startSearchService的逻辑
            [[PLVFindDevice sharedInstance] startFindDevice];
            self.startService = YES;
            
            // 回调搜索状态
            if ([self.deviceDelegate respondsToSelector:@selector(castManagerSearchStateChanged:)]) {
                [self.deviceDelegate castManagerSearchStateChanged:YES];
            }
            
            [self createFutureEvent];
        });
        return; // 不通知delegate，因为这是自动重试
    }
    
    // 重置重试计数器
    self.retryCount = 0;
    
    // 通知delegate有错误发生
    if ([self.delegate respondsToSelector:@selector(castManagerOnError:)]) {
        [self.delegate castManagerOnError:error];
    }
}

#pragma mark - PLVControlDeviceDelegate

- (void)plv_setAVTransportURLReponse {
    NSLog(@"PLVCastCoreManager - Set AVTransport URL response received. Starting playback.");
    [self.controlDevice play];
    [self startStatusPolling];
}

- (void)plv_getTransportInfoResponse:(PLVUPnPTransportInfo *)transportInfo {
    PLVWCastPlayStatus playStatus = PLVWCastPlayStatusUnkown;
    if ([transportInfo.currentTransportState isEqualToString:@"PLAYING"]) {
        playStatus = PLVWCastPlayStatusPlaying;
    } else if ([transportInfo.currentTransportState isEqualToString:@"PAUSED_PLAYBACK"]) {
        playStatus = PLVWCastPlayStatusPause;
    } else if ([transportInfo.currentTransportState isEqualToString:@"STOPPED"]) {
        playStatus = PLVWCastPlayStatusStopped;
    }
    
    if ([self.delegate respondsToSelector:@selector(castManagerPlayStatusChanged:)]) {
        [self.delegate castManagerPlayStatusChanged:playStatus];
    }
}

// Optional: Implement other control delegate methods for logging/debugging if needed
- (void)plv_playResponse { NSLog(@"PLVCastCoreManager - Play response received."); }
- (void)plv_pauseResponse { NSLog(@"PLVCastCoreManager - Pause response received."); }
- (void)plv_stopResponse { NSLog(@"PLVCastCoreManager - Stop response received."); }
- (void)plv_seekResponse { NSLog(@"PLVCastCoreManager - Seek response received."); }
- (void)plv_setVolumeResponse { NSLog(@"PLVCastCoreManager - Volume response received."); }

#pragma mark - Private (Legacy - can be removed or refactored)

// This method is no longer directly called by the new SDK's delegate system.
// It's kept for reference in case any internal logic relies on it. It can be removed.
- (void)updateCaseServiceId:(NSString *)TVUid state:(NSString *)state {
    // ...
}

- (void)addCastServiceModel:(PLVCastServiceModel *)model {
    if (!model.tvUID || ![model.tvUID isKindOfClass:NSString.class] || model.tvUID.length == 0) return;
    if (!model.deviceName || ![model.deviceName isKindOfClass:NSString.class] || model.deviceName.length == 0) return;
    
    [self.lock lock];
    BOOL found = NO;
    for (PLVCastServiceModel *existModel in self.plv_servicesArr) {
        if ([existModel.tvUID isEqualToString:model.tvUID]) {
            found = YES;
            break;
        }
    }
    if (!found) {
        [self.plv_servicesArr addObject:model];
    }
    [self.lock unlock];
}

- (void)removeCastServiceModel:(PLVCastServiceModel *)model {
     if (self.plv_servicesArr.count == 0) return;
    [self.lock lock];
    PLVCastServiceModel *foundModel = nil;
    for (PLVCastServiceModel *existModel in self.plv_servicesArr) {
        if ([existModel.tvUID isEqualToString:model.tvUID]) {
            foundModel = existModel;
            break;
        }
    }
    if (foundModel) {
        [self.plv_servicesArr removeObject:foundModel];
    }
    [self.lock unlock];
}

#pragma mark 信息模型

- (PLVCastServiceModel *)getPlvServiceInfoWithDeviceName:(NSString *)deviceName {
    PLVCastServiceModel * plv_s = nil;
    for (PLVCastServiceModel *model in self.plv_servicesArr) {
        if ([model.deviceName isEqualToString:deviceName]) {
            plv_s = model;
            break;
        }
    }
    if (plv_s == nil) {
        NSLog(@"PLVCastCoreManager - 警告：无法找到对应Plv设备信息模型 deviceName %@", deviceName);
    }
    return plv_s;
}

@end

@implementation PLVCastServiceModel
@end
