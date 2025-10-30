//
//  PLVCastClient.m
//  PLVVodSDKDemo
//
//  Created by MissYasiky on 2020/7/14.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCastClient.h"
#import "PLVCastCoreManager.h"
#import "PLVCastDefinitionModel.h"
#import "PLVCastDeviceViewController.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import "PLVCastNotificaion.h"
#import "PLVCastActionSheet.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPVolumeView.h>
#import <PLVLiveScenesSDK/PLVLiveVideoAPI.h>
#import "PLVRoomDataManager.h"
#import "PLVCastMirrorTipsView.h"

NSString *PLVCastClientLeaveLiveCtrlNotification = @"PLVCastClientLeaveLiveCtrlNotification";
static NSString *const kSystemVolumeDidChangeNotification = @"SystemVolumeDidChange"; // iOS 15+ 新通知名称

@interface PLVCastClient () <
PLVCastManagerDelegate,
PLVCastPlayControlViewDelegate
>

@property (nonatomic, assign) PLVCastClientState clientState;
@property (nonatomic, strong) NSString *channelID;
@property (nonatomic, strong) NSString *connectedChannelID;
@property (nonatomic, assign, getter=isConnected) BOOL connected;
@property (nonatomic, assign) BOOL reported;
@property (nonatomic, assign) BOOL needShowMirrorTips;
@property (nonatomic, strong) NSTimer *liveStatusTimer;

@property (nonatomic, weak) UIViewController *navController; // 父视图控制器

@property (nonatomic, strong) PLVCastPlayControlView *castControlView; // 投屏操作界面
@property (nonatomic, copy) NSArray <PLVCastDefinitionModel *> *definitions; // 可选清晰度模型数组
@property (nonatomic, copy) NSString *updatedDefinition; // 投屏时切换的清晰度，无切换时默认为 nil

@property (nonatomic, strong) PLVCastDeviceViewController *deviceSearchViewController;

@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, assign) float systemVolume;
@property (nonatomic, strong) PLVCastMirrorTipsView *mirrorTipsView; // 屏幕镜像功能提示视图
@property (nonatomic, assign) NSInteger lastVolumeSequenceNumber; // 上一次处理的音量通知序列号，用于去重

@end

@implementation PLVCastClient

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PLVCastCoreManager sharedManager] setDelegate:self];
    }
    return self;
}

- (void)dealloc {
    // 确保在对象销毁时移除音量监听
    [self removeSystemVolumeObserver];
}

#pragma mark - Getter & Setter

- (PLVCastPlayControlView *)castControlView {
    if (!_castControlView) {
        _castControlView = [[PLVCastPlayControlView alloc] init];
        _castControlView.delegate = self;
    }
    return _castControlView;
}

- (PLVCastMirrorTipsView *)mirrorTipsView {
    if (!_mirrorTipsView) {
        _mirrorTipsView =  [[PLVCastMirrorTipsView alloc] init];
    }
    return _mirrorTipsView;
}

- (PLVCastDeviceViewController *)deviceSearchViewController {
    if (!_deviceSearchViewController) {
        _deviceSearchViewController = [[PLVCastDeviceViewController alloc] init];
        __weak typeof(self) weakSelf = self;
        _deviceSearchViewController.selectConnectDeviceHandler = ^(NSString *deviceName) {
            // 先设置正在连接状态
            NSLog(@"PLVCastClient - 开始连接设备: %@，设置界面状态为'正在连接'", deviceName);
            weakSelf.castControlView.deviceName = @"正在连接";
            [weakSelf.castControlView show];
            
            // 开始连接设备
            [[PLVCastCoreManager sharedManager] connectServiceWithDeviceName:deviceName];
        };
    }
    return _deviceSearchViewController;
}

- (void)setConnected:(BOOL)connected {
    _connected = connected;
    [self updateState];
    if (connected) {
        self.connectedChannelID = self.channelID;
        [self startLiveStatusTimer];
    } else {
        self.connectedChannelID = nil;
        [self stopLiveStatusTimer];
    }
}

- (MPVolumeView *)volumeView {
    if (!_volumeView) {
        // 修复MPVolumeView的frame，确保能正常触发音量通知
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        _volumeView.hidden = YES; // 隐藏音量滑块，但保持视图存在以触发通知
        _volumeView.alpha = 0.01; // 设置透明度接近0但不为0，确保系统能检测到
        _volumeView.showsVolumeSlider = NO; // 隐藏音量滑块
    }
    return _volumeView;
}

- (void)setChannelID:(NSString *)channelID {
    _channelID = channelID;
    [self updateState];
}

- (BOOL)needShowMirrorTips {
    return self.mirrorTipsView.needShow;
}

#pragma mark - Public

+ (void)startAuthorize {
    [PLVCastCoreManager startAuthorize];
}

+ (BOOL)isAuthorizeSuccess {
    return [PLVCastCoreManager isAuthorizeSuccess];
}

+ (instancetype)sharedClient {
    static PLVCastClient *mananger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mananger = [[self alloc] init];
    });
    return mananger;
}

- (void)pushTheDeviceSearchViewController {
    [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];
    if (self.navController && [self.navController isKindOfClass:[UINavigationController class]]){
        UINavigationController *nav = (UINavigationController *)self.navController;
        if(![nav.topViewController isKindOfClass:[PLVCastDeviceViewController class]]) {
            [nav pushViewController:self.deviceSearchViewController animated:YES];
        }
    }
    else if(self.navController){
        [self.navController presentViewController:self.deviceSearchViewController animated:YES completion:nil];
    }
   
    self.mirrorTipsView.needShow = YES;
}

- (void)showMirrorTipsView {
    [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];
    [self.mirrorTipsView showOnView:self.navController.view];
}

- (void)setupWithNavigationController:(UIViewController *)navController
                            channelID:(NSString *)channelID {
    if (![PLVCastClient isAuthorizeSuccess]) {
        return;
    }
    self.navController = navController;

    if (channelID && [channelID isKindOfClass:[NSString class]] && channelID.length > 0) {
        self.channelID = channelID;
        if (self.clientState == PLVCastClientStateConnectCurrentChannel) {
            [self callbackForCastClientStartPlay];
            
            [self.castControlView show];
            [self addSystemVolumeObserver];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLVCast_EnterLiveRoom_Notification object:self.connectedChannelID];
        } else {
            [self.castControlView hide];
        }
    }
    
    if (!self.isConnected && self.channelID) {
        self.reported = NO;
    }
}

- (void)leave {
    // 无条件移除音量监听器，因为离开页面时必须清理资源
    [self removeSystemVolumeObserver];
    
    if (self.connected && self.connectedChannelID) {
        self.channelID = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVCast_LeaveLiveRoom_Notification object:self.connectedChannelID];
    }
}

- (void)quit {
    [self leave];
    [self stopLiveStatusTimer];
    _deviceSearchViewController = nil;
    [[PLVCastCoreManager sharedManager] clear];
}

#pragma mark - Private

- (void)startCastPlay {
    self.connected = YES;
    [self updateDefinitions];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;

    // 初始状态默认最高清晰度
    self.castControlView.definition = roomData.channelInfo.currentDefinition;

    if (!self.reported) {
        [PLVLiveVideoConfig resetCastPId];
        [PLVLiveVideoAPI reportCastPlayViewLogWithChannel:roomData.channelInfo param:roomData.customParam];
        self.reported = YES;
    }
    
    /// 开始投屏
    if ([PLVFdUtil checkStringUseable:self.playUrlString]) {
        NSString *castUrl = self.playUrlString;
        [[PLVCastCoreManager sharedManager] startPlayWithUrlString:castUrl];
        [self addSystemVolumeObserver];
    }

}

- (NSString *)urlSafeBase64String:(NSString *)inputString {
    NSData *data = [inputString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    base64String = [base64String stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    base64String = [base64String stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    return base64String;
}

- (void)updateState {
    if (self.isConnected) {
        if (self.connectedChannelID && self.channelID && [self.channelID isEqualToString:self.connectedChannelID]) {
            self.clientState = PLVCastClientStateConnectCurrentChannel;
        } else {
            self.clientState = PLVCastClientStateConnectOtherChannel;
        }
    } else {
        self.clientState = PLVCastClientStateUnconnected;
    }
}

- (void)updateDefinitions {
    NSArray *definitionArray = self.definitionsArray;
    NSMutableArray *muArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [definitionArray count]; i++) {
        NSDictionary *dict = definitionArray[i];
        PLVCastDefinitionModel *model = [[PLVCastDefinitionModel alloc] initWithDictionary:dict];
        [muArray addObject:model];
    }
    self.definitions = [muArray copy];
}

- (void)addSystemVolumeObserver {
    // 确保MPVolumeView被添加到视图层级中
    if (self.navController && self.navController.view) {
        [self.navController.view addSubview:self.volumeView];
        NSLog(@"PLVCastClient - MPVolumeView已添加到视图层级");
    } else {
        NSLog(@"PLVCastClient - 警告：navController或其view为nil，无法添加MPVolumeView");
        return;
    }
    
    self.systemVolume = [AVAudioSession sharedInstance].outputVolume;
    NSLog(@"PLVCastClient - 当前系统音量: %.2f", self.systemVolume);
    
    
    // iOS 15+ 的新通知名称
    if (@available(iOS 15.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeChanged:)
                                                     name:kSystemVolumeDidChangeNotification
                                                   object:nil];
        NSLog(@"PLVCastClient - 已注册iOS 15+音量通知监听");
    }
    
    
    NSLog(@"PLVCastClient - 音量监听器注册完成");
}

- (void)removeSystemVolumeObserver {
    [self.volumeView removeFromSuperview];
        
    if (@available(iOS 15.0, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kSystemVolumeDidChangeNotification object:nil];
    }
    
    // 重置序列号，避免下次连接时受旧值影响
    self.lastVolumeSequenceNumber = 0;
    
    NSLog(@"PLVCastClient - 音量监听器已移除");
}

#pragma mark - Timer

- (void)startLiveStatusTimer {
    self.liveStatusTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(checkLiveState) userInfo:nil repeats:YES];
    [self.liveStatusTimer fire];
}

- (void)stopLiveStatusTimer {
    [self.liveStatusTimer invalidate];
    self.liveStatusTimer = nil;
}

- (void)checkLiveState {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI getChannelMenuInfos:self.connectedChannelID completion:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
        if ([channelMenuInfo.status isEqualToString:@"N"]) {
            // 1.5秒后自动断开连接
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf castControlQuitButtonClick];
            });
        }
    } failure:nil];
}

#pragma mark - NSNotification

//系统声音改变
-(void)volumeChanged:(NSNotification *)notification {
    NSLog(@"PLVCastClient - 通知userInfo: %@", notification.userInfo);
    
    // 通过SequenceNumber去重，避免处理重复的音量通知
    NSInteger sequenceNumber = 0;
    id sequenceObject = [[notification userInfo] objectForKey:@"SequenceNumber"];
    if (sequenceObject && [sequenceObject respondsToSelector:@selector(integerValue)]) {
        sequenceNumber = [sequenceObject integerValue];
        if (sequenceNumber > 0 && sequenceNumber == self.lastVolumeSequenceNumber) {
            NSLog(@"PLVCastClient - 检测到重复的音量通知(SequenceNumber: %ld)，忽略处理", (long)sequenceNumber);
            return;
        }
        // 记录本次的SequenceNumber
        self.lastVolumeSequenceNumber = sequenceNumber;
        NSLog(@"PLVCastClient - 记录音量通知SequenceNumber: %ld", (long)sequenceNumber);
    }
    
    float volume = 0.0f;
    if ([notification.name isEqualToString:kSystemVolumeDidChangeNotification]) {
        // iOS 15+的新通知
        id volumeObject = [[notification userInfo] objectForKey:@"Volume"];
        if (volumeObject) {
            volume = [volumeObject floatValue];
            NSLog(@"PLVCastClient - 使用新版通知获取音量: %.4f", volume);
        } else {
            // 如果通知中没有音量信息，直接从AVAudioSession获取
            volume = [AVAudioSession sharedInstance].outputVolume;
            NSLog(@"PLVCastClient - 从AVAudioSession获取音量: %.2f", volume);
        }
    }
    
    if ((fabs(volume - self.systemVolume) < 0.0001) &&
        (0.0 < volume && volume < 1.0)){
        NSLog(@"PLVCastClient - 音量变化太小，忽略");
        return;
    }
    
    NSLog(@"PLVCastClient - 音量变化: %.4f -> %.4f", self.systemVolume, volume);
    BOOL plus = NO;
    if (volume > self.systemVolume ||
        (self.systemVolume == 1 && volume == self.systemVolume)) {
        plus = YES;
    }
    NSLog(@"PLVCastClient - 音量%@，同步到投屏设备", plus ? @"增加" : @"减少");
    
    if (plus) {
        [[PLVCastCoreManager sharedManager] addVolume];
    } else {
        [[PLVCastCoreManager sharedManager] reduceVolume];
    }
    
    // 更新系统音量
    self.systemVolume = volume;
}

#pragma mark - 回调
- (void)callbackForCastClientStartPlay {
    plv_dispatch_main_async_safe(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvCastClientStartPlay)]) {
            [self.delegate plvCastClientStartPlay];
        }
    })
}

#pragma mark - PLVCastCoreManager Delegate

// 设备连接错误回调
- (void)castManagerOnError:(NSError *)error{
    self.castControlView.deviceName = @"投屏错误";
}

- (void)castManagerDidConnectedWithService:(PLVCastServiceModel *)service {
    [self callbackForCastClientStartPlay];
    
    self.castControlView.deviceName = service.deviceName;
    [self startCastPlay];
}

- (void)castManagerDisonnectPassive:(BOOL)isPassive {
    self.connected = NO;
    [self removeSystemVolumeObserver];
}

// 播放状态变更回调
- (void)castManagerPlayStatusChanged:(PLVWCastPlayStatus)status {
    self.castControlView.playing = status == PLVWCastPlayStatusPlaying;
    
    if (status == PLVWCastPlayStatusStopped || status == PLVWCastPlayStatusCommpleted) {
        // 1.5秒后自动断开连接
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self castControlQuitButtonClick];
        });
    }
}

#pragma mark - PLVCastPlayControlView Delegate

// 【返回】按钮点击回调
- (void)castControlBackButtonClick {
    self.connected = NO;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
    if (isPortrait) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVCastClientLeaveLiveCtrlNotification object:nil];
        [self leave];
    } else {
        [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];
    }
}

// 【退出】按钮点击回调
- (void)castControlQuitButtonClick {
    self.connected = NO;
        
    [[PLVCastCoreManager sharedManager] stop];
    [[PLVCastCoreManager sharedManager] disconnect];

    [self.castControlView hide];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvCastClientQuitPlay)]) {
        [self.delegate plvCastClientQuitPlay];
    }
    self.updatedDefinition = nil;
}

// 【换设备】按钮点击回调
- (void)castControlDeviceButtonClick {
    [self pushTheDeviceSearchViewController];
}

// 【清晰度】按钮点击回调
- (void)castControlDefinitionButtonClick {
    NSInteger selectedIndex = -1;
    NSMutableArray *buttonTitleArray = [[NSMutableArray alloc] initWithCapacity:self.definitions.count];
    for (int i = 0; i < self.definitions.count; i++) {
        PLVCastDefinitionModel *model = self.definitions[i];
        [buttonTitleArray addObject:model.definition];
        if ([self.castControlView.definition isEqualToString:model.definition]) {
            selectedIndex = i;
        }
    }
    __weak typeof(self) weakSelf = self;
    [PLVCastActionSheet showActionSheetWithBtnTitles:[buttonTitleArray copy] selectedIndex:selectedIndex handler:^(PLVCastActionSheet * _Nonnull actionSheet, NSInteger index) {
        if (index >= 0 && index < self.definitions.count && index != selectedIndex) {
            PLVCastDefinitionModel *model = weakSelf.definitions[index];
            NSString *castUrl = model.playUrlString;
            [[PLVCastCoreManager sharedManager] startPlayWithUrlString:castUrl]; // 重新投屏
            weakSelf.castControlView.definition = model.definition;
            weakSelf.updatedDefinition = model.definition;
        }
    }];
}

// 【播放/暂停】按钮点击回调
- (void)castControlPlayButtonClick:(BOOL)play {
    if (play) {
        [[PLVCastCoreManager sharedManager] resume];
    } else {
        [[PLVCastCoreManager sharedManager] pause];
    }
}

// 【半屏/全屏】按钮点击回调
- (void)castControlFullScreenButtonClick {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
    if (isPortrait) {
        [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
    } else {
        [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];
    }
}

@end
