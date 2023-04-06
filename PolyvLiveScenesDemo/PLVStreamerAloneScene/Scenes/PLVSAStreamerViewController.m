//
//  PLVSAStreamerViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStreamerViewController.h"

// 工具类
#import "PLVSAUtils.h"

// UI
#import "PLVSALinkMicAreaView.h"
#import "PLVSAShadowMaskView.h"
#import "PLVSAStreamerSettingView.h"
#import "PLVSACountDownView.h"
#import "PLVSAStreamerHomeView.h"
#import "PLVSAStreamerFinishView.h"
#import "PLVSAFinishStreamerSheet.h"
#import "PLVBroadcastExtensionLauncher.h"
#import "PLVSABeautySheet.h"
#import "PLVShareLiveSheet.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVSAChatroomViewModel.h"
#import "PLVMemberPresenter.h"
#import "PLVStreamerPresenter.h"
#import "PLVBeautyViewModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSString *kPLVSAUserDefaultsUserStreamInfo = @"kPLVSAUserDefaultsUserStreamInfo";

/// PLVSAStreamerViewController 所处的四种状态，不同状态下，展示不同的页面
typedef NS_ENUM(NSInteger, PLVSAStreamerViewState) {
    PLVSAStreamerViewStateBeforeSteam = 0, // 开播前的设置页
    PLVSAStreamerViewStateBeginSteam  = 1, // 准备开播的倒计时页
    PLVSAStreamerViewStateSteaming    = 2, // 开播中的推流页
    PLVSAStreamerViewStateFinishSteam = 3  // 结束开播的结束页
};

@interface PLVSAStreamerViewController ()<
PLVSAStreamerSettingViewDelegate,
PLVSALinkMicAreaViewDelegate,
PLVSocketManagerProtocol,
PLVStreamerPresenterDelegate,
PLVMemberPresenterDelegate,
PLVSAStreamerHomeViewDelegate,
PLVSABeautySheetDelegate,
UIGestureRecognizerDelegate,
PLVShareLiveSheetDelegate
>

#pragma mark 模块
@property (nonatomic, strong) PLVStreamerPresenter *streamerPresenter;
@property (nonatomic, strong) PLVMemberPresenter *memberPresenter;

@property (nonatomic, copy) void (^tryStartClassBlock) (void); // 用于无法立刻’尝试开始上课‘，后续需自动’尝试开始‘上课的场景；执行优先级低于 [tryResumeClassBlock]
@property (nonatomic, copy) void (^tryResumeClassBlock) (void); // 用于在合适的时机，进行’恢复直播‘处理；执行优先级高于 [tryStartClassBlock]

#pragma mark UI
/// view hierarchy
///
/// 开播前（viewState为PLVSAStreamerViewStateBeforeSteam时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    │     └── (PLVSALinkMicWindowsView) linkMicWindowsView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerSettingView) settingView
///
/// 准备开播（viewState为PLVSAStreamerViewStateBeginSteam时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    │     └── (PLVSALinkMicWindowsView) linkMicWindowsView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerHomeView) homeView
///
/// 开播时（viewState为PLVSAStreamerViewStateSteaming时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerHomeView) homeView
///          └── (PLVSALinkMicWindowsView) linkMicWindowsView
///
/// 开播结束（viewState为PLVSAStreamerViewStateFinishSteam时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerFinishView) finishView
@property (nonatomic, assign) PLVSAStreamerViewState viewState; // 控制器所处的页面状态
@property (nonatomic, strong) PLVSALinkMicAreaView *linkMicAreaView; // 连麦视图
@property (nonatomic, strong) PLVSAShadowMaskView *shadowMaskView; // 渐变遮罩视图
@property (nonatomic, strong) PLVSAStreamerSettingView *settingView; // 开播前的设置页
@property (nonatomic, strong) PLVSACountDownView *countDownView; // 准备开播的倒计时页
@property (nonatomic, strong) PLVSAStreamerHomeView *homeView; // 开播中的推流页
@property (nonatomic, strong) PLVSAStreamerFinishView *finishView; // 结束开播的结束页
@property (nonatomic, strong) PLVSABeautySheet *beautySheet; // 美颜设置弹层
@property (nonatomic, strong) PLVShareLiveSheet *shareLiveSheet; // 分享直播弹层
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture; //缩放手势

#pragma mark 数据
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中
@property (nonatomic, assign, readonly) NSString * channelId; // 当前频道号
@property (nonatomic, assign) NSTimeInterval showMicTipsTimeInterval; // 显示'请打开麦克风提示'时的时间戳
@property (nonatomic, assign) CGFloat currentCameraZoomRatio;   // 当前摄像头的变焦倍数
@property (nonatomic, assign) CGFloat maxCameraZoomRatio;   // 当前摄像头允许的最大变焦倍数
@property (nonatomic, assign) BOOL localUserScreenShareOpen; // 本地用户是否开启了屏幕共享
@property (nonatomic, assign) BOOL otherUserFullScreen; // 非本地用户开启了全屏
@property (nonatomic, assign, readonly) PLVBLinkMicStreamScale streamScale; // 当前直播流比例

@end

@implementation PLVSAStreamerViewController

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        // 启动聊天室管理器
        [[PLVSAChatroomViewModel sharedViewModel] setup];
        
        // 监听socket消息
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [PLVSAUtils sharedUtils].homeVC = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupModule];
    [self preapareStartClass];
    [self clearDatedChannelStreamInfo];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self getEdgeInset];
    
    self.linkMicAreaView.frame = self.view.bounds;
    self.shadowMaskView.frame = self.view.bounds;
    
    // 此处不可使用 self. 会触发初始化
    _settingView.frame = self.view.bounds;
    _countDownView.frame = self.view.bounds;
    _homeView.frame = self.view.bounds;
    _finishView.frame = self.view.bounds;
}

#pragma mark - [ Override ]

- (BOOL)shouldAutorotate {
    return !self.streamerPresenter.classStarted && _settingView.canAutorotate; // 只允许 未开播时在'设置页'使用'横竖屏按钮'设置屏幕旋转
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.streamerPresenter.classStarted) { // 开播后 返回开播前设置好的屏幕方向
        return [PLVSAUtils sharedUtils].interfaceOrientationMask;
    } else { // 未开播 允许所有方向
        if (_settingView.canAutorotate) {
            return UIInterfaceOrientationMaskAll;
        } else {
            return [PLVSAUtils sharedUtils].interfaceOrientationMask;
        }
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [PLVSAUtils sharedUtils].interfaceOrientation;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - [ Private Method ]

/// 登出操作
- (void)logout {
    [self socketLogout];
    [PLVRoomLoginClient logout];
    [self.streamerPresenter enableBeautyProcess:NO]; // 关闭美颜管理器
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerViewControllerLogout:)]) {
        [self.delegate streamerViewControllerLogout:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)guestLogout {
    [self.streamerPresenter finishClass];
    // 退出聊天室，资源释放、状态位清零
    [[PLVSAChatroomViewModel sharedViewModel] clear];
    // 成员列表数据停止自动更新
    [self.memberPresenter stop];
    [self logout];
}

/// 启动、挂断视频连麦
- (void)startLinkMic:(BOOL)start videoLinkMic:(BOOL)videoLinkMic {
    NSString *typeTitle = videoLinkMic ? @"视频" : @"语音";
    NSString *suceessTitle = start ? [NSString stringWithFormat:@"已开启%@连麦，观众可以申请连麦", typeTitle] : @"已挂断所有连麦";
    NSString *failTitle = start ? [NSString stringWithFormat:@"开启%@连麦失败，请稍后再试", typeTitle] : [NSString stringWithFormat:@"关闭%@连麦失败，请稍后再试", typeTitle];
    
    __weak typeof(self) weakSelf = self;
    void (^ emitCompleteBlock) (BOOL emitSuccess) = ^(BOOL emitSuccess) {
        if (emitSuccess) { // 成功
            [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
            [weakSelf.homeView setLinkMicButtonSelected:start];
            [PLVSAUtils showToastInHomeVCWithMessage:suceessTitle];
        } else {
            [weakSelf.homeView setLinkMicButtonSelected:weakSelf.streamerPresenter.channelLinkMicOpen];
            [PLVSAUtils showToastInHomeVCWithMessage:failTitle];
        }
    };
    
    if (videoLinkMic) {
        [self.streamerPresenter openVideoLinkMic:start
                               emitCompleteBlock:^(BOOL emitSuccess) {
            emitCompleteBlock(emitSuccess);
        }];
    } else {
        [self.streamerPresenter openAudioLinkMic:start emitCompleteBlock:^(BOOL emitSuccess) {
            emitCompleteBlock(emitSuccess);
        }];
    }
}

/// 缩放手势
- (void)pinchGesture:(UIPinchGestureRecognizer *)recognizer {
    if (self.localUserScreenShareOpen ||
        self.otherUserFullScreen) {
        return;
    }
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            CGFloat zoomRatio = self.currentCameraZoomRatio * recognizer.scale;
            if (zoomRatio >= 1.0 && zoomRatio <= self.maxCameraZoomRatio){
                [self.streamerPresenter setCameraZoomRatio:zoomRatio];
            }
        } break;
        default:
            break;
    }
}

#pragma mark Getter & Setter

- (PLVSALinkMicAreaView *)linkMicAreaView {
    if (!_linkMicAreaView) {
        _linkMicAreaView = [[PLVSALinkMicAreaView alloc] init];
        _linkMicAreaView.delegate = self;
    }
    return _linkMicAreaView;
}

- (PLVSAShadowMaskView *)shadowMaskView {
    if (!_shadowMaskView) {
        _shadowMaskView = [[PLVSAShadowMaskView alloc] init];
    }
    return _shadowMaskView;
}

- (PLVSAStreamerSettingView *)settingView {
    if (!_settingView) {
        _settingView = [[PLVSAStreamerSettingView alloc] init];
        _settingView.delegate = self;
    }
    return _settingView;
}

- (PLVSACountDownView *)countDownView {
    if (!_countDownView) {
        _countDownView = [[PLVSACountDownView alloc] init];
        __weak typeof(self) weakSelf = self;
        _countDownView.countDownCompletedHandler = ^{ // 结束倒计时
            // 开始上课
            int resultCode = [weakSelf.streamerPresenter startClass];
            if (resultCode < 0) {
                [PLVSAUtils showToastWithMessage:[NSString stringWithFormat:@"上课错误 %d",resultCode] inView:weakSelf.view];
            }
            // 更新界面UI
            [weakSelf updateViewState:PLVSAStreamerViewStateSteaming];
            // 保存当前上课数据
            [weakSelf saveChannelStreamInfo];
        };
    }
    return _countDownView;
}

- (PLVSAStreamerFinishView *)finishView {
    if (!_finishView) {
        _finishView = [[PLVSAStreamerFinishView alloc] init];
        _finishView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        __weak typeof(self) weakSelf = self;
        _finishView.finishButtonHandler = ^{
            [weakSelf logout];
        };
    }
    return _finishView;
}

- (NSString *)channelId{
    return [PLVRoomDataManager sharedManager].roomData.channelId;
}

- (PLVRoomUserType)viewerType{
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
}

- (PLVSABeautySheet *)beautySheet {
    if (!_beautySheet) {
        _beautySheet = [[PLVSABeautySheet alloc] initWithSheetHeight:190 sheetLandscapeWidth:301];
        _beautySheet.delegate = self;
    }
    return _beautySheet;
}

- (PLVShareLiveSheet *)shareLiveSheet {
    if (!_shareLiveSheet) {
        _shareLiveSheet = [[PLVShareLiveSheet alloc] initWithType:PLVShareLiveSheetSceneTypeSA];
        _shareLiveSheet.delegate = self;
    }
    return _shareLiveSheet;
}

- (UIPinchGestureRecognizer *)pinchGesture {
    if (!_pinchGesture) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        _pinchGesture.delegate = self;
    }
    return _pinchGesture;
}

- (PLVBLinkMicStreamScale)streamScale {
    return [PLVRoomDataManager sharedManager].roomData.streamScale;
}

#pragma mark Initialize

- (void)setupUI {
    [self.view addSubview:self.linkMicAreaView];
    [self.view addSubview:self.shadowMaskView];
    [self.view addSubview:self.settingView];
    [self.view addGestureRecognizer:self.pinchGesture];
}

- (void)setupModule {
    // 初始化成员模块
    self.memberPresenter = [[PLVMemberPresenter alloc] init];
    self.memberPresenter.delegate = self;
    [self.memberPresenter start];// 开始获取成员列表数据并开启自动更新
    
    // 初始化推流模块
    self.streamerPresenter = [[PLVStreamerPresenter alloc] init];
    self.streamerPresenter.delegate = self;
    self.streamerPresenter.preRenderContainer = self.linkMicAreaView;
    self.streamerPresenter.localPreviewViewFillMode = PLVBRTCVideoViewFillMode_Fit;
    
    // 设置麦克风、摄像头默认配置
    self.streamerPresenter.micDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultFront = ![PLVRoomDataManager sharedManager].roomData.appDefaultPureViewEnabled;
    
    self.streamerPresenter.previewType = PLVStreamerPresenterPreviewType_UserArray;
    [self.streamerPresenter setupStreamQuality:[PLVRoomData streamQualityWithResolutionType:[PLVRoomDataManager sharedManager].roomData.defaultResolution]];
    [self.streamerPresenter setupStreamScale:PLVBLinkMicStreamScale9_16];
    [self.streamerPresenter setupLocalVideoPreviewSameAsRemoteWatch:YES];
    [self.streamerPresenter setupMixLayoutType:PLVRTCStreamerMixLayoutType_Tile];
    
    // 初始化美颜
    [self.streamerPresenter initBeauty];
    
    // 设置默认开播流比例
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        [self setupLiveroomStreamScale];
    }
    // 设置默认开播方向
    if ([PLVRoomDataManager sharedManager].roomData.appDefaultLandScapeEnabled) {
        [self.settingView changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
    }
    
    self.viewState = PLVSAStreamerViewStateBeforeSteam;
}

/// 设置直播间 流比例
- (void)setupLiveroomStreamScale {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVBLinkMicStreamScale streamScale = roomData.streamScale;
    PLVBLinkMicStreamScale localStreamScale = [self getCurrentChannelLocalStreamScale];
    if (localStreamScale > -1 && roomData.appWebStartResolutionRatioEnabled) {
        streamScale = localStreamScale;
    }
    [self.settingView synchPushStreamScale:streamScale];
}

- (void)getEdgeInset {
    [PLVSAUtils sharedUtils].landscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (@available(iOS 11, *)) {
        [[PLVSAUtils sharedUtils] setupAreaInsets:self.view.safeAreaInsets];
    }
}

#pragma mark UI

- (void)updateViewState:(PLVSAStreamerViewState)viewState {
    if (viewState <= self.viewState) { // viewState 只能递增，不能递减
        return;
    }
    self.viewState = viewState;
    
    if (_settingView && _settingView.superview) {
        [_settingView removeFromSuperview];
        _settingView = nil;
    }
    if (_countDownView && _countDownView.superview) {
        [_countDownView removeFromSuperview];
        _countDownView = nil;
    }
    if (_homeView && _homeView.superview) {
        [_homeView removeFromSuperview];
        _homeView = nil;
    }
    if (_finishView && _finishView.superview) {
        [_finishView removeFromSuperview];
        _finishView = nil;
    }
    
    if (self.viewState == PLVSAStreamerViewStateBeginSteam) {
        [self.view addSubview:self.countDownView];
        [self.countDownView startCountDown];
    } else if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [self setupHomeView];
        [self.view addSubview:self.homeView];
        // 更新连麦列表
        [self.linkMicAreaView reloadLinkMicUserWindows];
    } else if (self.viewState == PLVSAStreamerViewStateFinishSteam) {
        [self.linkMicAreaView clear];
        [self.view addSubview:self.finishView];
    }
}

- (void)setupHomeView { // home不使用懒加载，是为了避免在回调中提前初始化
    self.homeView = [[PLVSAStreamerHomeView alloc] initWithLocalOnlineUser:self.streamerPresenter.localOnlineUser
                                                        linkMicWindowsView:self.linkMicAreaView.windowsView];
    self.homeView.delegate = self;
    [self.homeView updateUserList:[self.memberPresenter userList]
                        userCount:self.memberPresenter.userCount
                      onlineCount:[self.streamerPresenter.onlineUserArray count]];
}

#pragma mark Start Class

- (void)preapareStartClass {
    __weak typeof(self) weakSelf = self;
    [self.streamerPresenter prepareLocalMicCameraPreviewCompletion:^(BOOL granted, BOOL prepareSuccess) {
        if (prepareSuccess) {
            [weakSelf.streamerPresenter setupLocalPreviewWithCanvaView:nil setupCompletion:^(BOOL setupResult) {
                if (setupResult) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(700 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                        [weakSelf.streamerPresenter startLocalMicCameraPreviewByDefault];
                    });
                    [weakSelf.streamerPresenter switchLocalUserCamera:weakSelf.streamerPresenter.cameraDefaultFront];
                    
                    [weakSelf tryResumeClass];
                    // 开启RTC图像数据回调给美颜处理
                    [weakSelf.streamerPresenter enableBeautyProcess:[PLVBeautyViewModel sharedViewModel].beautyIsOpen];
                    
                    [weakSelf.settingView enableMirrorButton:weakSelf.streamerPresenter.currentCameraFront];
                }
            }];
        }
        if (!granted) {
            [PLVSAUtils showAlertWithTitle:@"音视频权限申请"
                                   Message:@"请前往“设置-隐私”开启权限"
                         cancelActionTitle:@"取消"
                         cancelActionBlock:nil
                        confirmActionTitle:@"设置" confirmActionBlock:^{
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
        [weakSelf.settingView cameraAuthorizationGranted:granted];
    }];
}

- (void)tryResumeClass {
    if ([PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving) {
        __weak typeof(self) weakSelf = self;
        [PLVSAUtils showAlertWithMessage:@"检测到之前异常退出，是否恢复直播" cancelActionTitle:@"结束直播" cancelActionBlock:^{
            /// 重置值、结束服务器中该频道上课状态
            [PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving = NO;
            [weakSelf.streamerPresenter finishClass];
        } confirmActionTitle:@"恢复直播" confirmActionBlock:^{
            [weakSelf tryResumeDeviceOrientation];
            [weakSelf.streamerPresenter joinRTCChannel];
            weakSelf.tryResumeClassBlock = ^{
                PLVResolutionType type = [PLVRoomDataManager sharedManager].roomData.defaultResolution;
                [weakSelf streamerSettingViewStartButtonClickWithResolutionType:type];
            };
        }];
    }
}

/// 尝试开始上课
///
/// @note 若上课条件不符，将可能上课失败；并根据已重试次数，进行自动重试；
///
/// @param retryCount 已重试次数 (传值 0 表示首次调用)
- (void)tryStartClassRetryCount:(NSInteger)retryCount {
    BOOL needRetry = NO;
    __weak typeof(self) weakSelf = self;
    if (self.streamerPresenter.micCameraGranted &&
        self.streamerPresenter.inRTCRoom) {
        if (self.streamerPresenter.networkQuality == PLVBLinkMicNetworkQualityUnknown) {
            // 麦克风和摄像头当前全部关闭时
            if (!self.streamerPresenter.currentMicOpen &&
                !self.streamerPresenter.currentCameraOpen) {
                /// 开始上课倒数
                [self updateViewState:PLVSAStreamerViewStateBeginSteam];
            }else{
                needRetry = YES;
            }
        } else if(self.streamerPresenter.networkQuality == PLVBLinkMicNetworkQualityDown) {
            needRetry = YES;
        }else{
            /// 开始上课倒数
            [self updateViewState:PLVSAStreamerViewStateBeginSteam];
        }
    }else{
        if (!self.streamerPresenter.micCameraGranted) {
            /// 重新‘准备上课’
            [self preapareStartClass];
        } else if(!self.streamerPresenter.inRTCRoom) {
            /// 重新‘加入RTC房间‘
            [self.streamerPresenter joinRTCChannel];
            self.tryStartClassBlock = ^{
                [weakSelf tryStartClassRetryCount:0];
            };
        }
    }
        
    if (needRetry) {
        /// 需要重试
        if (retryCount >= 0 && retryCount < 3) {
            retryCount++;
            NSInteger waitTime = (1.5 * retryCount);
            [PLVSAUtils showToastWithMessage:@"处理中..." inView:self.view afterDelay:waitTime];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf tryStartClassRetryCount:retryCount];
            });
        }else{
            [PLVSAUtils showAlertWithMessage:@"网络当前不佳，请稍后再试" cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:@"知道了" confirmActionBlock:nil];
        }
    }
}

- (void)startClass { // 在此处理推流正式开始的UI更新
    [self.homeView startClass:YES];
}

#pragma mark finishClass（直播推流结束时调用）

- (void)finishClass {
    plv_dispatch_main_async_safe(^{
        if (self.viewerType == PLVRoomUserTypeGuest) {
            [self.streamerPresenter finishClass];
            [self.homeView startClass:NO];
        } else {
            // 结束上课
            self.finishView.duration = self.streamerPresenter.pushStreamValidDuration;
            self.finishView.startTime = self.streamerPresenter.startPushStreamTimestamp;
            [self.streamerPresenter finishClass];
            // 退出聊天室，资源释放、状态位清零
            [PLVRoomLoginClient logout];
            [[PLVSAChatroomViewModel sharedViewModel] clear];
            // 成员列表数据停止自动更新
            [self.memberPresenter stop];
            // 更新界面UI
            [self updateViewState:PLVSAStreamerViewStateFinishSteam];
        }
    })
}

#pragma mark 断开socket（退出到登录页时调用）

- (void)socketLogout { // 单独抽离的原因:调用后所有正在发送的socket消息会被中断，如'finishClass'、'OPEN_MICROPHONE'消息，导致直播间无法结束。
    [[PLVSocketManager sharedManager] logout];
}

#pragma mark 续播
/// 存储频道开播信息
- (void)saveChannelStreamInfo {
    NSMutableDictionary *dict = [[[NSUserDefaults standardUserDefaults] objectForKey:kPLVSAUserDefaultsUserStreamInfo] mutableCopy];
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        dict = [NSMutableDictionary dictionary];
    }
    /// 保存屏幕方向、开播时间、推流比例
    if ([PLVFdUtil checkStringUseable:self.channelId]) {
        UIDeviceOrientation orientation = [PLVSAUtils sharedUtils].deviceOrientation;
        NSInteger timeInterval = (NSInteger)[[NSDate date] timeIntervalSince1970];
        dict[self.channelId] = @{@"orientation" : @(orientation),
                                 @"startTime" : @(timeInterval),
                                 @"streamScale" :@(self.streamScale)
        };
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kPLVSAUserDefaultsUserStreamInfo];
    }
}

/// 存储频道开播信息
- (void)saveChannelStreamScaleInfo {
    NSMutableDictionary *dict = [[[NSUserDefaults standardUserDefaults] objectForKey:kPLVSAUserDefaultsUserStreamInfo] mutableCopy];
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        dict = [NSMutableDictionary dictionary];
    }
    /// 保存推流比例
    if ([PLVFdUtil checkStringUseable:self.channelId]) {
        dict[self.channelId] = @{@"streamScale" :@(self.streamScale)};
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kPLVSAUserDefaultsUserStreamInfo];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

/// 读取频道开播信息
- (NSDictionary *)getCurrentChannelStoringStreamInfo{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kPLVSAUserDefaultsUserStreamInfo];
    if ([PLVFdUtil checkDictionaryUseable:dict] &&
        [PLVFdUtil checkStringUseable:self.channelId]) {
        NSDictionary *userDict = dict[self.channelId];
        return userDict;
    }
    return nil;
}

/// 读取频道开播画面比例信息
- (PLVBLinkMicStreamScale)getCurrentChannelLocalStreamScale{
    NSDictionary *userDict = [self getCurrentChannelStoringStreamInfo];
    if ([PLVFdUtil checkDictionaryUseable:userDict] &&
        [userDict.allKeys containsObject:@"streamScale"]) {
        PLVBLinkMicStreamScale localStreamScale = MIN([userDict[@"streamScale"] integerValue], PLVBLinkMicStreamScale4_3);
        return localStreamScale;
    }
    
    return -1;
}

/// 清理过期频道开播信息
- (void)clearDatedChannelStreamInfo {
    NSInteger startTime = 0;
    NSDictionary *userDict = [self getCurrentChannelStoringStreamInfo];
    startTime = [userDict[@"startTime"] integerValue];
    
    NSInteger oneDay = 86400;
    NSInteger currentTime = (NSInteger)[[NSDate date] timeIntervalSince1970];
    if ((currentTime - startTime) > oneDay) {
        NSMutableDictionary *dict = [[[NSUserDefaults standardUserDefaults] objectForKey:kPLVSAUserDefaultsUserStreamInfo] mutableCopy];
        if ([PLVFdUtil checkDictionaryUseable:dict] &&
            [PLVFdUtil checkStringUseable:self.channelId]) {
            [dict removeObjectForKey:self.channelId];
            [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kPLVSAUserDefaultsUserStreamInfo];
        }
    }
}

/// 恢复屏幕方向
- (void)tryResumeDeviceOrientation {
    UIDeviceOrientation orientation = UIDeviceOrientationPortrait;
    NSDictionary *userDict = [self getCurrentChannelStoringStreamInfo];
    orientation = [userDict[@"orientation"] longValue];
    
    if (orientation != UIDeviceOrientationPortrait) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.settingView changeDeviceOrientation:orientation];
        });
    }
}

#pragma mark 美颜
- (void)showBeautySheet:(BOOL)show {
    if (![PLVBeautyViewModel sharedViewModel].beautyIsReady) {
        [PLVSAUtils showToastInHomeVCWithMessage:@"美颜未准备就绪，请退出重新登录"];
        return;
    }
    
    if (show) {
        [self.beautySheet showInView:self.view];
    } else {
        if (_beautySheet) {
            [self.beautySheet dismiss];
        }
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVMemberPresenterDelegate

- (void)userListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    if (self.viewState != PLVSAStreamerViewStateSteaming) { // 尚未进入开播页，则尚未初始化成员列表弹层，无需更新数据
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.homeView updateUserList:[weakSelf.memberPresenter userList]
                                userCount:weakSelf.memberPresenter.userCount
                              onlineCount:[weakSelf.streamerPresenter.onlineUserArray count]];
    });
}

- (NSArray *)currentOnlineUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter{
    return self.streamerPresenter.onlineUserArray;
}

#pragma mark PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString { // 登陆成功
    if (![PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving) {
        /// 正常场景下（即非异常退出而临时断流的场景）则正常加入RTC房间
        /// 原因：异常退出场景下，加入RTC房间的操作，应延后至用户确认“是否恢复直播”后
        /// 讲师socket登录成功后可直接加入频道 嘉宾在进入房间后才可以加入频道
        if (self.viewerType == PLVRoomUserTypeTeacher) {
            [self.streamerPresenter joinRTCChannel];
        }
    }
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    if (error.code == PLVSocketLoginErrorCodeKick) {
        plv_dispatch_main_async_safe(^{
            [PLVSAUtils showToastWithMessage:@"频道已被禁止直播" inView:self.view afterDelay:3.0];
        })
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf logout]; // 使用weakSelf，不影响self释放内存
        });
    } else if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin) &&
        error.localizedDescription) {
        plv_dispatch_main_async_safe(^{
            [PLVSAUtils showAlertWithMessage:error.localizedDescription cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
                [weakSelf logout];
            }];
        })
    }
}

- (void)socketMananger_didConnectStatusChange:(PLVSocketConnectStatus)connectStatus {
    if(self.viewState != PLVSAStreamerViewStateSteaming){
        return;
    }
    if (connectStatus == PLVSocketConnectStatusReconnect) {
        self.socketReconnecting = YES;
        plv_dispatch_main_async_safe(^{
            [PLVSAUtils showToastWithMessage:@"聊天室重连中" inView:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVSAUtils showToastWithMessage:@"聊天室重连成功" inView:self.view];
            })
        }
    }
}

#pragma mark PLVStreamerPresenterDelegate

/// ‘房间加入状态’ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRtcRoomJoinStatus:(PLVStreamerPresenterRoomJoinStatus)currentRtcRoomJoinStatus
            inRTCRoomChanged:(BOOL)inRTCRoomChanged
                   inRTCRoom:(BOOL)inRTCRoom {
    if (inRTCRoomChanged) {
        if (self.viewerType == PLVRoomUserTypeTeacher) {
            /// Block执行
            if (self.tryResumeClassBlock) {
                self.tryResumeClassBlock();
            } else if(self.tryStartClassBlock) {
                self.tryStartClassBlock();
            }
            /// 无论是否调用，均进行清空处理
            self.tryResumeClassBlock = nil;
            self.tryStartClassBlock = nil;
        } else if (self.viewerType == PLVRoomUserTypeGuest) {
            if (inRTCRoom) {
                [self startClass];
            } else {
                [self finishClass];
            }
        }
    }
}

/// ‘网络状态’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
    networkQualityDidChanged:(PLVBLinkMicNetworkQuality)networkQuality {
    BOOL updateNetState = YES;
    if (self.viewerType == PLVRoomUserTypeGuest) {
        /// 嘉宾角色在非上麦状态下，不更新网络状态UI
        updateNetState = self.streamerPresenter.localOnlineUser.currentStatusVoice;
    }
    if (updateNetState && networkQuality == PLVBLinkMicNetworkQualityUnknown) {
        /// 硬件全关场景下，不更新网络状态UI
        updateNetState = !(!self.streamerPresenter.currentCameraOpen && !self.streamerPresenter.currentMicOpen);
    }
    if (updateNetState) {
        [self.homeView setNetworkQuality:networkQuality];
    }
}

/// ’等待连麦用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
  linkMicWaitUserListRefresh:(NSArray <PLVLinkMicWaitUser *>*)waitUserArray
            newWaitUserAdded:(BOOL)newWaitUserAdded {
    if (newWaitUserAdded) {
        [self.homeView showNewWaitUserAdded];
    }
    
    if (waitUserArray &&
        [waitUserArray count] > 0) {
        [self.homeView showMemberBadge:YES];
    } else {
        [self.homeView showMemberBadge:NO];
    }
    
    [self.memberPresenter refreshUserListWithLinkMicWaitUserArray:waitUserArray];
}

/// ’RTC房间在线用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
linkMicOnlineUserListRefresh:(NSArray <PLVLinkMicOnlineUser *>*)onlineUserArray {
    [self.linkMicAreaView reloadLinkMicUserWindows];
    [self.memberPresenter refreshUserListWithLinkMicOnlineUserArray:onlineUserArray];
    [self.homeView updateHomeViewOnlineUserCount:onlineUserArray.count];
}

/// ‘主讲权限’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
           linkMicOnlineUser:(PLVLinkMicOnlineUser *)onlineUser
                 authSpeaker:(BOOL)authSpeaker {
    if (onlineUser && onlineUser.userType == PLVSocketUserTypeTeacher) {
        /// 讲师主讲权限变更不需要提醒
        return;
    }
    
    [self.linkMicAreaView updateFirstSiteCanvasViewWithUserId:onlineUser.linkMicUserId toFirstSite:onlineUser.isRealMainSpeaker];
    NSString *message = nil;
    if (onlineUser.isGuestTransferPermission) {
        if (self.streamerPresenter.localOnlineUser.currentScreenShareOpen) {
            message = @"你已移除主讲权限，屏幕共享已结束";
            [self.streamerPresenter.localOnlineUser wantOpenScreenShare:NO];
        } else {
            message = @"已移交主讲权限";
        }
    } else if (onlineUser.localUser) {
        if (authSpeaker) {
           message = @"你已被授予主讲权限";
        } else if (self.streamerPresenter.localOnlineUser.currentScreenShareOpen) {
            message = @"你已被移除主讲权限，屏幕共享已结束";
            [self.streamerPresenter.localOnlineUser wantOpenScreenShare:NO];
        } else {
            message = @"你已被移除主讲权限";
        }
    } else {
        if (authSpeaker) {
            message = [NSString stringWithFormat:@"%@ 成为主讲人", onlineUser.nickname];
        } else {
            message = [NSString stringWithFormat:@"%@ 的主讲权限已被移除", onlineUser.nickname];
        }
    }
    [PLVSAUtils showToastWithMessage:message inView:self.view];
    [onlineUser updateUserIsGuestTransferPermission:NO];
}

/// ‘是否上课已开始’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
      classStartedDidChanged:(BOOL)classStarted
          startClassInfoDict:(NSDictionary *)startClassInfoDict{
    [PLVRoomDataManager sharedManager].roomData.startTimestamp = presenter.startPushStreamTimestamp;
    [PLVRoomDataManager sharedManager].roomData.liveDuration = presenter.pushStreamValidDuration;
    if (classStarted) {
        [self startClass];
    }
}

/// 当前 ’已有效推流时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
currentPushStreamValidDuration:(NSTimeInterval)pushStreamValidDuration {
    [self.homeView setPushStreamDuration:pushStreamValidDuration];
}

/// 当前 ’单次重连时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
currentReconnectingThisTimeDuration:(NSInteger)reconnectingThisTimeDuration{
    if (reconnectingThisTimeDuration == 20) {
        [PLVSAUtils showAlertWithMessage:@"网络断开，已停止直播，请更换网络后重试" cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:nil confirmActionBlock:nil];
    }
}

/// 当前远端 ’已推流时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRemotePushDuration:(NSTimeInterval)currentRemotePushDuration{
    [self.homeView setPushStreamDuration:currentRemotePushDuration];
}

/// sessionId 场次Id发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
         sessionIdDidChanged:(NSString *)sessionId{
    [PLVRoomDataManager sharedManager].roomData.sessionId = sessionId;
}

/// 已挂断 某位远端用户的连麦 事件回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
   didCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser {
    
}

/// 本地用户的 ’麦克风开关状态‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
     localUserMicOpenChanged:(BOOL)currentMicOpen {
    if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [PLVSAUtils showToastWithMessage:(currentMicOpen ? @"已开启麦克风" : @"已关闭麦克风") inView:self.view];
    }
    self.showMicTipsTimeInterval = 0;
    [self.homeView setCurrentMicOpen:currentMicOpen];
}

/// 本地用户的 ’摄像头是否应该显示值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
localUserCameraShouldShowChanged:(BOOL)currentCameraShouldShow {
    if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [PLVSAUtils showToastWithMessage:(currentCameraShouldShow ? @"已开启摄像头" : @"已关闭摄像头") inView:self.view];
    }
    self.maxCameraZoomRatio = [self.streamerPresenter getMaxCameraZoomRatio];
}

/// 本地用户的 ’摄像头前后置状态值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
 localUserCameraFrontChanged:(BOOL)currentCameraFront {
    self.maxCameraZoomRatio = [self.streamerPresenter getMaxCameraZoomRatio];
}

/// 本地用户的 ’屏幕共享开关状态‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserScreenShareOpenChanged:(BOOL)currentScreenShareOpen {
    self.localUserScreenShareOpen = currentScreenShareOpen;
    if (self.streamerPresenter.localOnlineUser.isRealMainSpeaker ||
        self.streamerPresenter.localOnlineUser.userType == PLVSocketUserTypeTeacher) {
        NSString *message = currentScreenShareOpen ? @"其他人现在可以看到你的屏幕" : @"共享已结束";
        [PLVSAUtils showToastWithMessage:message inView:self.view];
    }
    [self.homeView changeScreenShareButtonSelectedState:currentScreenShareOpen];
}

/// 远程用户的  ’屏幕共享开关状态‘  发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUser:(PLVLinkMicOnlineUser *)onlineUser screenShareOpenChanged:(BOOL)screenShareOpen {

}

/// 推流管理器 ‘发生错误’ 回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
               didOccurError:(NSError *)error
               fullErrorCode:(NSString *)fullErrorCodeString {
    NSString * message = @"";
    if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedEmitFailed) {
        message = @"上课错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedNetError){
        message = @"推流请求错误，请退出重新登录";
    }else if (error.code == PLVStreamerPresenterErrorCode_UpdateRTCTokenFailedNetError){
        message = @"更新Token错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_RTCManagerError){
        message = @"RTC内部错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_RTCManagerErrorStartAudioFailed){
        message = @"RTC内部错误，启动音频模块失败，请退出重新登录";
    }else if (error.code == PLVStreamerPresenterErrorCode_EndClassFailedNetFailed){
        message = @"下课错误，请直接退出上课页";
    }else if (error.code == PLVStreamerPresenterErrorCode_UnknownError){
        message = @"未知错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_NoError){
        message = @"错误";
    }
    message = [message stringByAppendingFormat:@" code:%@",fullErrorCodeString];
    
    [PLVSAUtils showToastWithMessage:message inView:self.view afterDelay:3];
}

/// 本地用户 麦克风音量大小检测
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserVoiceValue:(CGFloat)localVoiceValue receivedLocalAudibleVoice:(BOOL)voiceAudible {
    if (!self.streamerPresenter.currentMicOpen && localVoiceValue >= 0.4) {
        NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
        if (currentTimeInterval - self.showMicTipsTimeInterval > 180) {
            [PLVSAUtils showToastWithMessage:@"您已静音，请开启麦克风后发言" inView:self.view];
            self.showMicTipsTimeInterval = [[NSDate date] timeIntervalSince1970];
        }
    }
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter beautyDidInitWithResult:(int)result {
    if (result == 0) {
        // 配置美颜
        PLVBeautyManager *beautyManager = [self.streamerPresenter shareBeautyManager];
        [[PLVBeautyViewModel sharedViewModel] startBeautyWithManager:beautyManager];
    } else {
        [PLVSAUtils showToastInHomeVCWithMessage:[NSString stringWithFormat:@"美颜初始化失败 %d 请重进直播间", result]];
    }
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter beautyProcessDidOccurError:(NSError *)error {
    if (error) {
        NSString *errorDes = error.userInfo[NSLocalizedDescriptionKey];
        [PLVSAUtils showToastInHomeVCWithMessage:errorDes];
    }
}

#pragma mark PLVSALinkMicAreaViewDelegate

- (PLVLinkMicOnlineUser *)localUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
    return self.streamerPresenter.localOnlineUser;
}

- (NSArray *)currentOnlineUserListInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
    return self.streamerPresenter.onlineUserArray;
}

- (BOOL)localUserPreviewViewInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
    return self.viewState == PLVSAStreamerViewStateBeforeSteam;
}

- (NSInteger)onlineUserIndexInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView
                                  filterBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filterBlock {
    return [self.streamerPresenter findOnlineUserModelIndexWithFiltrateBlock:filterBlock];
}

- (PLVLinkMicOnlineUser *)onlineUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView
                                      withTargetIndex:(NSInteger)targetIndex {
    return [self.streamerPresenter getOnlineUserModelFromOnlineUserArrayWithIndex:targetIndex];
}

- (void)didSelectLinkMicUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
}

- (void)linkMicAreaView:(PLVSALinkMicAreaView *)areaView showGuideViewOnExternal:(UIView *)guideView {
    [self.homeView addExternalLinkMicGuideView:guideView];
}

- (BOOL)classStartedInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
    return self.streamerPresenter.classStarted;
}

- (void)linkMicAreaView:(PLVSALinkMicAreaView *)areaView onlineUser:(PLVLinkMicOnlineUser *)onlineUser isFullScreen:(BOOL)isFullScreen {
    self.otherUserFullScreen = isFullScreen && !onlineUser.localUser;
}

#pragma mark PLVSAStreamerSettingViewDelegate

- (void)streamerSettingViewBackButtonClick {
    [self logout];
}

- (void)streamerSettingViewStartButtonClickWithResolutionType:(PLVResolutionType)type {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:type];
    PLVBLinkMicStreamScale currentStreamScale =[PLVSAUtils sharedUtils].isLandscape ? self.streamScale : PLVBLinkMicStreamScale9_16;
    [self.streamerPresenter setupStreamScale:currentStreamScale];
    [self.streamerPresenter setupStreamQuality:streamQuality];
    if (self.viewerType == PLVRoomUserTypeGuest) {
        [self.streamerPresenter joinRTCChannel];
        [self updateViewState:PLVSAStreamerViewStateSteaming];
    } else {
        [self tryStartClassRetryCount:0];
    }
}

- (void)streamerSettingViewCameraReverseButtonClick {
    [self.streamerPresenter switchLocalUserFrontCamera];
    [self.settingView enableMirrorButton:self.streamerPresenter.currentCameraFront];
}

- (void)streamerSettingViewMirrorButtonClickWithMirror:(BOOL)mirror {
    [self.streamerPresenter setupLocalVideoPreviewMirrorMode:(mirror ? PLVBRTCVideoMirrorMode_Auto : PLVBRTCVideoMirrorMode_Disabled)];
}

- (void)streamerSettingViewBitRateButtonClickWithResolutionType:(PLVResolutionType)type {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:type];
    [self.streamerPresenter setupStreamQuality:streamQuality];
}

- (void)streamerSettingViewDidClickBeautyButton:(PLVSAStreamerSettingView *)streamerSettingView {
    if (self.streamerPresenter.currentCameraOpen) {
        [self showBeautySheet:YES];
    } else {
        [PLVSAUtils showToastWithMessage:@"请开启摄像头后使用" inView:self.view];
    }
}

- (void)streamerSettingViewDidChangeDeviceOrientation:(PLVSAStreamerSettingView *)streamerSettingView {
    [self.beautySheet deviceOrientationDidChange];
    BOOL isLandscape = ([PLVSAUtils sharedUtils].deviceOrientation != UIDeviceOrientationPortrait);
    PLVBLinkMicStreamScale currentStreamScale = isLandscape ? self.streamScale : PLVBLinkMicStreamScale9_16;
    [self.streamerPresenter setupStreamScale:currentStreamScale];
}

- (void)streamerSettingViewStreamScaleButtonClickWithStreamScale:(PLVBLinkMicStreamScale)streamScale {
    if ([PLVSAUtils sharedUtils].isLandscape) {
        [self saveChannelStreamScaleInfo];
    }
    [self.streamerPresenter setupStreamScale:streamScale];
}

#pragma mark PLVSAStreamerHomeViewProtocol

- (void)bandUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId banned:(BOOL)banned {
    [self.memberPresenter banUserWithUserId:userId banned:banned];
}

- (void)kickUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId {
    [self.memberPresenter kickUserWithUserId:userId];
}

- (void)streamerHomeViewDidTapCloseButton:(PLVSAStreamerHomeView *)homeView {
    __weak typeof(self) weakSelf = self;
    PLVSAFinishStreamerSheet *actionSheet = [[PLVSAFinishStreamerSheet alloc] init];
    [actionSheet showInView:self.view finishAction:^{
        if (weakSelf.viewerType == PLVRoomUserTypeGuest) {
            [weakSelf guestLogout]; //嘉宾会直接退出直播间
        } else {
            [weakSelf finishClass];
        }
    }];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeCameraOpen:(BOOL)cameraOpen{
    [self.streamerPresenter openLocalUserCamera:cameraOpen];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)moreInfoSheet didChangeFlashOpen:(BOOL)flashOpen{
    [self.streamerPresenter openLocalUserCameraTorch:flashOpen];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeMicOpen:(BOOL)micOpen{
    [self.streamerPresenter openLocalUserMic:micOpen];
}

- (void)streamerHomeViewDidChangeCameraFront:(PLVSAStreamerHomeView *)homeView {
    [self.streamerPresenter switchLocalUserFrontCamera];
    if (self.streamerPresenter.currentCameraFront) {
        [self.homeView changeFlashButtonSelectedState:NO];
    }
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)moreInfoSheet didChangeMirrorOpen:(BOOL)mirrorOpen{
    [self.streamerPresenter setupLocalVideoPreviewMirrorMode:(mirrorOpen ? PLVBRTCVideoMirrorMode_Auto : PLVBRTCVideoMirrorMode_Disabled)];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeScreenShareOpen:(BOOL)screenShareOpen {
    if (self.viewerType != PLVRoomUserTypeTeacher &&
        !self.streamerPresenter.localOnlineUser.isRealMainSpeaker) {
        [PLVSAUtils showToastWithMessage:@"屏幕共享需讲师授权" inView:self.view];
        [self.homeView changeScreenShareButtonSelectedState:NO];
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        [self.streamerPresenter openLocalUserScreenShare:screenShareOpen];
        if (screenShareOpen) {
            if (@available(iOS 12.0, *)) {
                [[PLVBroadcastExtensionLauncher sharedInstance] launch];
            } else {
                NSString *message = @"请到控制中心，长按录制按钮，选择 POLYV屏幕共享 打开录制";
                [PLVSAUtils showAlertWithMessage:message cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:@"我知道了" confirmActionBlock:nil];
            }
        }
     } else {
         if (screenShareOpen) {
             [PLVSAUtils showToastWithMessage:@"屏幕共享功能需要iOS11以上系统支持" inView:self.view];
             [self.homeView changeScreenShareButtonSelectedState:!screenShareOpen];
         }
     }
}

- (PLVResolutionType)streamerHomeViewCurrentQuality:(PLVSAStreamerHomeView *)homeView {
    PLVResolutionType resolutionType = [PLVRoomData resolutionTypeWithStreamQuality:self.streamerPresenter.streamQuality];
    return resolutionType;
}

- (BOOL)streamerHomeViewChannelLinkMicOpen:(PLVSAStreamerHomeView *)homeView {
    return self.streamerPresenter.channelLinkMicOpen;
}

/// 点击连麦按钮回调
- (void)streamerHomeViewDidTapLinkMicButton:(PLVSAStreamerHomeView *)homeView linkMicButtonSelected:(BOOL)selected videoLinkMic:(BOOL)videoLinkMic {
    if (!self.streamerPresenter.pushStreamStarted) {
        // 未开启连麦，更新连麦UI为未选中
        [self.homeView setLinkMicButtonSelected:NO];
        return;
    }
    
    if ([PLVRoomDataManager sharedManager].roomData.interactNumLimit == 0) {
        [PLVSAUtils showToastWithMessage:@"尚未开通，请联系管理员" inView:self.view];
        [self.homeView setLinkMicButtonSelected:NO];
        return;
    }
    
    if (!self.streamerPresenter.channelLinkMicOpen) {
        [self startLinkMic:YES videoLinkMic:videoLinkMic];
    } else {
        __weak typeof(self) weakSelf = self;
        NSString *title = self.streamerPresenter.channelLinkMicMediaType == PLVChannelLinkMicMediaType_Audio ? @"确定关闭语音连麦吗？" : @"确定关闭视频连麦吗？";
        [PLVSAUtils showAlertWithTitle:title Message:@"关闭后将挂断进行中的所有连麦" cancelActionTitle:@"取消" cancelActionBlock:^{
            [weakSelf.homeView setLinkMicButtonSelected:YES];
        } confirmActionTitle:@"确定" confirmActionBlock:^{
            [weakSelf startLinkMic:NO videoLinkMic:videoLinkMic];
        }];
    }
}

- (void)streamerHomeViewDidMemberSheetDismiss:(PLVSAStreamerHomeView *)homeView {
    [self.homeView showMemberBadge:NO];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeResolutionType:(PLVResolutionType)type {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:type];
    [self.streamerPresenter setupStreamQuality:streamQuality];
}

- (void)streamerHomeViewDidTapBeautyButton:(PLVSAStreamerHomeView *)homeView {
    if (self.streamerPresenter.currentCameraOpen) {
        [self showBeautySheet:YES];
    } else {
        [PLVSAUtils showToastWithMessage:@"请开启摄像头后使用" inView:self.view];
    }
}

- (void)streamerHomeViewDidTapShareButton:(PLVSAStreamerHomeView *)homeView {
    [self.shareLiveSheet showInView:self.view];
}

- (PLVChannelLinkMicMediaType)streamerHomeViewCurrentChannelLinkMicMediaType:(PLVSAStreamerHomeView *)homeView {
    return self.streamerPresenter.channelLinkMicMediaType;
}

#pragma mark PLVSABeautySheetDelegate
- (void)beautySheet:(PLVSABeautySheet *)beautySheet didChangeOn:(BOOL)on {
    [self.streamerPresenter enableBeautyProcess:on];
}

- (void)beautySheet:(PLVSABeautySheet *)beautySheet didChangeShow:(BOOL)show {
    if (_settingView) { // 需要先判断是否已初始化
        [self.settingView showBeautySheet:show];
    }
    if (_homeView) { // 需要先判断是否已初始化
        [self.homeView showBeautySheet:show];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] &&
        !self.localUserScreenShareOpen &&
        !self.otherUserFullScreen) {
        self.currentCameraZoomRatio = [self.streamerPresenter getCameraZoomRatio];
    }
    return YES;
}

#pragma mark PLVShareLiveSheetDelegate

- (void)shareLiveSheetCopyLinkFinished:(PLVShareLiveSheet *)shareLiveSheet {
    [PLVSAUtils showToastWithMessage:@"复制成功" inView:self.view];
}

- (void)shareLiveSheet:(PLVShareLiveSheet *)shareLiveSheet savePictureSuccess:(BOOL)success {
    NSString *message = success ? @"图片已保存到相册" : @"保存失败";
    [PLVSAUtils showToastWithMessage:message inView:self.view];
}

@end
