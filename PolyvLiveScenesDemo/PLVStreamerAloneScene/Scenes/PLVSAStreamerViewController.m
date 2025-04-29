//
//  PLVSAStreamerViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStreamerViewController.h"
#import <UIKit/UIKit.h>

// 工具类
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVBroadcastNotificationsManager.h"
#import "PLVSAScreenShareCustomPictureInPictureManager.h"

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
#import "PLVStickerCanvas.h"
#import "PLVSAScreenSharePipCustomView.h"
#import "PLVVirtualBackgroudSheet.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVSAChatroomViewModel.h"
#import "PLVMemberPresenter.h"
#import "PLVStreamerPresenter.h"
#import "PLVBeautyViewModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <Photos/Photos.h>
#import "PLVImagePickerViewController.h"

static NSString *kPLVSAUserDefaultsUserStreamInfo = @"kPLVSAUserDefaultsUserStreamInfo";
static NSString *const PLVSABroadcastStartedNotification = @"PLVLiveBroadcastStartedNotification";
static NSString *const kPLVSASettingMixLayoutKey = @"kPLVSASettingMixLayoutKey";
static NSString *const KPLVSANoiseCancellationLevelKey = @"KPLVSANoiseCancellationLevelKey";
static NSString *const KPLVSAExternalDeviceEnabledKey = @"KPLVSAExternalDeviceEnabledKey";

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
PLVShareLiveSheetDelegate,
PLVStickerCanvasDelegate,
UINavigationControllerDelegate,
PLVSAScreenShareCustomPictureInPictureManagerDelegate,
PLVVirtualBackgroudSheetDelegate
>

#pragma mark 模块
@property (nonatomic, strong) PLVStreamerPresenter *streamerPresenter;
@property (nonatomic, strong) PLVMemberPresenter *memberPresenter;
@property (nonatomic, strong) UIView *screenShareCustomPipDisplayView;

@property (nonatomic, strong) PLVSAScreenShareCustomPictureInPictureManager *screenShareCustomPIPManager API_AVAILABLE(ios(15.0));

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
///                 └── (PLVStickerCanvas) stickerCanvas
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
@property (nonatomic, strong) PLVStickerCanvas *stickerCanvas; // 贴图组件
@property (nonatomic, strong) PLVVirtualBackgroudSheet *aiMattingSheet; // AI抠像组件
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture; //缩放手势
@property (nonatomic, strong) PLVBroadcastNotificationsManager *broadcastNotification; // 屏幕共享广播的通知

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
@property (nonatomic, assign) BOOL isInBackground; // 是否位于后台

@end

@implementation PLVSAStreamerViewController

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置对语言场景
        [[PLVMultiLanguageManager sharedManager] setupLocalizedLiveScene:PLVMultiLanguageLiveSceneSA channelId:self.channelId language:nil];
        
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
    [self setupNotification];
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
    
    if (_stickerCanvas){
        CGRect newFrame = self.view.bounds;
        if ( !CGRectEqualToRect(newFrame, _stickerCanvas.frame)){
            // 横竖屏 清空水印
            [self.streamerPresenter setStickerImage:nil];
            _stickerCanvas.frame = newFrame;
        }
    }
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
    if (@available(iOS 15.0, *)) {
        self.screenShareCustomPIPManager = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
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
    NSString *typeTitle = videoLinkMic ? PLVLocalizedString(@"视频") : PLVLocalizedString(@"语音");
    NSString *suceessTitle = start ? [NSString stringWithFormat:PLVLocalizedString(@"已开启%@连麦，观众可以申请连麦"), typeTitle] : PLVLocalizedString(@"已挂断所有连麦");
    NSString *failTitle = start ? [NSString stringWithFormat:PLVLocalizedString(@"开启%@连麦失败，请稍后再试"), typeTitle] : [NSString stringWithFormat:PLVLocalizedString(@"关闭%@连麦失败，请稍后再试"), typeTitle];
    
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

/// 保存当前选择的混流布局到本地
- (void)saveSelectedMixLayoutType:(PLVMixLayoutType)mixLayoutType {
    NSString *mixLayoutKey = [NSString stringWithFormat:@"%@_%@", kPLVSASettingMixLayoutKey, self.channelId];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)mixLayoutType] forKey:mixLayoutKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/// 读取本地混流布局配置
- (PLVMixLayoutType)getLocalMixLayoutType {
    // 如果本地有记录优先读取
    NSString *mixLayoutKey = [NSString stringWithFormat:@"%@_%@", kPLVSASettingMixLayoutKey, self.channelId];
    NSString *saveMixLayoutTypeString = [[NSUserDefaults standardUserDefaults] objectForKey:mixLayoutKey];
    if ([PLVFdUtil checkStringUseable:saveMixLayoutTypeString] && [PLVRoomDataManager sharedManager].roomData.showMixLayoutButtonEnabled) {
        PLVMixLayoutType saveMixLayout = saveMixLayoutTypeString.integerValue;
        if (saveMixLayout >= 1 && saveMixLayout <=3) {
            return saveMixLayout;
        }
    }
    // 默认混流配置
    return [PLVRoomDataManager sharedManager].roomData.defaultMixLayoutType;
}

/// 保存当前选择的降噪模式到本地
- (void)saveSelectedNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)level {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)level] forKey:KPLVSANoiseCancellationLevelKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
/// 读取本地降噪模式
- (PLVBLinkMicNoiseCancellationLevel)getLocalNoiseCancellationLevel {
    // 如果本地有记录优先读取
    NSString *saveNoiseCancellationLevelString = [[NSUserDefaults standardUserDefaults] objectForKey:KPLVSANoiseCancellationLevelKey];
    if ([PLVFdUtil checkStringUseable:saveNoiseCancellationLevelString]) {
        PLVBLinkMicNoiseCancellationLevel saveNoiseCancellationLevel = saveNoiseCancellationLevelString.integerValue;
        if (saveNoiseCancellationLevel >= 1 && saveNoiseCancellationLevel <= 2) {
            return saveNoiseCancellationLevel;
        }
    }
    // 默认降噪模式
    return PLVBLinkMicNoiseCancellationLevelAggressive;
}

/// 保存当前选择的外接设备开关到本地
- (void)saveSelectedExternalDeviceEnabled:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",enabled ? @"Y": @"N"] forKey:KPLVSAExternalDeviceEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
/// 读取本地外接设备开关
- (BOOL)getLocalExternalDeviceEnabled {
    // 如果本地有记录优先读取
    NSString *saveExternalDeviceEnabledString = [[NSUserDefaults standardUserDefaults] objectForKey:KPLVSAExternalDeviceEnabledKey];
    if ([PLVFdUtil checkStringUseable:saveExternalDeviceEnabledString] &&
        [saveExternalDeviceEnabledString isEqualToString:@"Y"]) {
        return YES;
    }
    // 默认外接设备关闭
    return NO;
}

- (void)updateScreenShareCustomManagerState {
    if (@available(iOS 15.0, *)) {
        if (self.localUserScreenShareOpen && [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled) {
            if (!self.screenShareCustomPIPManager) {
                self.screenShareCustomPIPManager = [[PLVSAScreenShareCustomPictureInPictureManager alloc] initWithDisplaySuperview:self.screenShareCustomPipDisplayView];
                self.screenShareCustomPIPManager.delegate = self;
            }
            [self.screenShareCustomPIPManager startPictureInPictureSource];
            self.screenShareCustomPIPManager.autoEnterPictureInPicture = self.localUserScreenShareOpen && [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled;
        } else {
            if (self.isInBackground) {
                return;
            }
            self.screenShareCustomPIPManager = nil;
        }
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
                [PLVSAUtils showToastWithMessage:[NSString stringWithFormat:PLVLocalizedString(@"上课错误 %d"),resultCode] inView:weakSelf.view];
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
    if (@available(iOS 15.0, *)) {
        self.screenShareCustomPipDisplayView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, 400, 58)];
        [self.view addSubview:self.screenShareCustomPipDisplayView];
    }
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
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    
    // 设置麦克风、摄像头默认配置
    self.streamerPresenter.micDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultFront = !roomData.appDefaultPureViewEnabled;
    
    self.streamerPresenter.previewType = PLVStreamerPresenterPreviewType_UserArray;
    if ([PLVFdUtil checkStringUseable:self.settingView.defaultQualityLevel]) {
        [self.streamerPresenter setupStreamQualityLevel:self.settingView.defaultQualityLevel];
    } else {
        [self.streamerPresenter setupStreamQuality:[PLVRoomData streamQualityWithResolutionType:roomData.defaultResolution]];
    }
    [self.streamerPresenter setLinkMicNewStrategyEnabled:roomData.linkmicNewStrategyEnabled interactNumLimit:roomData.interactNumLimit defaultChannelLinkMicMediaType:roomData.defaultChannelLinkMicMediaType];
    [self.streamerPresenter setupStreamScale:PLVBLinkMicStreamScale9_16];
    [self.streamerPresenter setupLocalVideoPreviewSameAsRemoteWatch:YES];
    PLVMixLayoutType localMixLayout = [self getLocalMixLayoutType];
    PLVRTCStreamerMixLayoutType type = [PLVRoomData streamerMixLayoutTypeWithMixLayoutType:localMixLayout];
    [self.streamerPresenter setupMixLayoutType:type];
    [self saveSelectedMixLayoutType:localMixLayout];
    [self.streamerPresenter setDefaultVideoQosPreference:roomData.pushQualityPreference];
    
    // 初始化美颜
    [self.streamerPresenter initBeauty];
    
    // 设置默认开播流比例
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        [self setupLiveroomStreamScale];
    }
    // 设置默认开播方向
    if (roomData.appDefaultLandScapeEnabled) {
        [self.settingView changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
    }
    
    // 同步降噪等级
    PLVBLinkMicNoiseCancellationLevel noiseCancellationLevel = [self getLocalNoiseCancellationLevel];
    [self.streamerPresenter setupNoiseCancellationLevel:noiseCancellationLevel];
    [self.settingView synchNoiseCancellationLevel:self.streamerPresenter.noiseCancellationLevel];
    [self saveSelectedNoiseCancellationLevel:self.streamerPresenter.noiseCancellationLevel];
    
    // 同步外接设备
    BOOL externalDeviceEnabled = [self getLocalExternalDeviceEnabled];
    [self.streamerPresenter enableExternalDevice:externalDeviceEnabled];
    [self.settingView synchExternalDeviceEnabled:self.streamerPresenter.localExternalDeviceEnabled];
    [self saveSelectedExternalDeviceEnabled:self.streamerPresenter.localExternalDeviceEnabled];
    
    // 屏幕共享初始化
    if (@available(iOS 15.0, *)) {
        self.screenShareCustomPIPManager = [[PLVSAScreenShareCustomPictureInPictureManager alloc] initWithDisplaySuperview:self.screenShareCustomPipDisplayView];
        self.screenShareCustomPIPManager.delegate = self;
    }
    
    self.viewState = PLVSAStreamerViewStateBeforeSteam;
}

- (void)setupNotification {
    self.broadcastNotification = [[PLVBroadcastNotificationsManager alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.broadcastNotification listenForMessageWithIdentifier:PLVSABroadcastStartedNotification listener:^{
        if (@available(iOS 11.0, *)) {
            if (weakSelf.viewerType == PLVRoomUserTypeTeacher || weakSelf.streamerPresenter.localOnlineUser.isRealMainSpeaker) {
                [weakSelf.streamerPresenter openLocalUserScreenShare:YES];
                [weakSelf.homeView changeScreenShareButtonSelectedState:YES];
            }
        }
    }];
    if (@available(iOS 15.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
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
        // 直播准备
        [self.view addSubview:self.countDownView];
        [self.countDownView startCountDown];
    } else if (self.viewState == PLVSAStreamerViewStateSteaming) {
        // 直播中
        [self setupHomeView];
        [self.view addSubview:self.homeView];
        // 更新连麦列表
        [self.linkMicAreaView reloadLinkMicUserWindows];
    } else if (self.viewState == PLVSAStreamerViewStateFinishSteam) {
        // 直播结束
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
    // 添加贴图图层
    if (self.stickerCanvas){
        [self.homeView addStickerCanvasView:self.stickerCanvas editMode:NO];
    }
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
            [PLVSAUtils showAlertWithTitle:PLVLocalizedString(@"音视频权限申请")
                                   Message:PLVLocalizedString(@"请前往“设置-隐私”开启权限")
                         cancelActionTitle:PLVLocalizedString(@"取消")
                         cancelActionBlock:nil
                        confirmActionTitle:PLVLocalizedString(@"设置") confirmActionBlock:^{
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
        [PLVSAUtils showAlertWithMessage:PLVLocalizedString(@"监测到您的上次直播中途离开，是否继续?") cancelActionTitle:PLVLocalizedString(@"结束直播") cancelActionBlock:^{
            /// 重置值、结束服务器中该频道上课状态
            [PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving = NO;
            [weakSelf.streamerPresenter finishClass];
        } confirmActionTitle:PLVLocalizedString(@"继续直播") confirmActionBlock:^{
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
       if (self.streamerPresenter.networkQuality == PLVBRTCNetworkQuality_Down) {
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
            [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"处理中...") inView:self.view afterDelay:waitTime];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf tryStartClassRetryCount:retryCount];
            });
        }else{
            [PLVSAUtils showAlertWithMessage:PLVLocalizedString(@"网络当前不佳，请稍后再试") cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"知道了") confirmActionBlock:nil];
        }
    }
}

- (void)startClass { // 在此处理推流正式开始的UI更新
    [self.homeView startClass:YES];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.linkmicNewStrategyEnabled && self.viewerType == PLVRoomUserTypeTeacher && roomData.interactNumLimit > 0) {
        __weak typeof(self) weakSelf = self;
        [self.streamerPresenter changeLinkMicMediaType:self.streamerPresenter.channelLinkMicMediaType != PLVChannelLinkMicMediaType_Video allowRaiseHand:self.streamerPresenter.channelLinkMicOpen emitCompleteBlock:^(BOOL emitSuccess) {
            [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
        }];
    }
}

#pragma mark finishClass（直播推流结束时调用）

- (void)finishClass {
    plv_dispatch_main_async_safe(^{
        if (self.viewerType == PLVRoomUserTypeGuest) {
            [self.streamerPresenter finishClass];
            [self.linkMicAreaView finishClass];
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
        [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"美颜未准备就绪，请退出重新登录")];
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

#pragma mark 前后台

- (void)handleEnterForeground {
    if (self.isInBackground) {
        self.isInBackground = NO;
        if (@available(iOS 15.0, *)) {
            BOOL pictureInPictureActive = self.screenShareCustomPIPManager && self.screenShareCustomPIPManager.pictureInPictureActive;
            BOOL shouldStartPictureInPicture = self.localUserScreenShareOpen && [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled;
            if (self.screenShareCustomPIPManager && !self.screenShareCustomPIPManager.pictureInPictureActive && shouldStartPictureInPicture) { // 回到前台 如果小窗未启动 且屏幕共享+桌面消息开，需要关掉桌面消息，销毁小窗控制器 当重启桌面消息再重建小窗控制器
                self.screenShareCustomPIPManager = nil;
                [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled = NO;
                [self.homeView updateDesktopChatEnable:NO];
            } else if (pictureInPictureActive && shouldStartPictureInPicture) {
                [self.screenShareCustomPIPManager stopPictureInPicture];
            } else if (pictureInPictureActive && !shouldStartPictureInPicture) { // 回到前台如果小窗启动，且屏幕共享关掉，需关闭小窗
                self.screenShareCustomPIPManager = nil;
            }
            if (self.screenShareCustomPIPManager) {
                self.screenShareCustomPIPManager.autoEnterPictureInPicture = self.localUserScreenShareOpen && [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled;
            }
        }
    }
}

- (void)handleEnterBackground {
    self.isInBackground = YES;
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

- (NSArray *)currentWaitUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter{
    return self.streamerPresenter.waitUserArray;
}

#pragma mark PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString { // 登录成功
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
        [self finishClass]; // 讲师被踢出后立即结束当前课程
        plv_dispatch_main_async_safe(^{
            [PLVSAUtils showAlertWithMessage:PLVLocalizedString(@"当前直播间已被禁止直播") cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
                [weakSelf logout];
            }];
        })
    } else if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin) &&
        error.localizedDescription) {
        plv_dispatch_main_async_safe(^{
            [PLVSAUtils showAlertWithMessage:error.localizedDescription cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
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
            [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"聊天室重连中") inView:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"聊天室重连成功") inView:self.view];
            })
        }
    }
}

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([event isEqualToString:@"speak"]) {
        if ([subEvent isEqualToString:@"TO_TOP"] || [subEvent isEqualToString:@"CANCEL_TOP"]) {
            BOOL show = [subEvent isEqualToString:@"TO_TOP"];
            PLVSpeakTopMessage *message = [[PLVSpeakTopMessage alloc] initWithDictionary:jsonDict];
            plv_dispatch_main_async_safe(^{
                [self.homeView showPinMessagePopupView:show message:message];
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
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter networkQualityDidChanged:(PLVBRTCNetworkQuality)networkQuality {
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

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter rtcStatistics:(PLVRTCStatistics *)statistics {
    [self.homeView updateStatistics:statistics];
    
    if (presenter.videoQosPreference == PLVBRTCVideoQosPreferenceClear && statistics.upLoss > 30) {
        [self.homeView showBadNetworkTipsView];
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

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserLinkMicStatusChanged:(PLVLinkMicUserLinkMicStatus)linkMicStatus {
    if (linkMicStatus == PLVLinkMicUserLinkMicStatus_Inviting) {
        [self.homeView dismissBottomSheet];
    }
    [self.linkMicAreaView updateLocalUserLinkMicStatus:linkMicStatus];
}

/// ’RTC房间在线用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
linkMicOnlineUserListRefresh:(NSArray <PLVLinkMicOnlineUser *>*)onlineUserArray {
    [self.linkMicAreaView reloadLinkMicUserWindows];
    [self.memberPresenter refreshUserListWithLinkMicOnlineUserArray:onlineUserArray];
    [self.homeView updateHomeViewOnlineUserCount:onlineUserArray.count];
    
    // 连麦状态中，隐藏贴图组件
    BOOL isInLinkMic = (onlineUserArray.count > 1);
    self.stickerCanvas.hidden = isInLinkMic;
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
            message = PLVLocalizedString(@"你已移除主讲权限，屏幕共享已结束");
            [self.streamerPresenter.localOnlineUser wantOpenScreenShare:NO];
        } else {
            message = PLVLocalizedString(@"已移交主讲权限");
        }
    } else if (onlineUser.localUser) {
        if (authSpeaker) {
           message = PLVLocalizedString(@"你已被授予主讲权限");
        } else if (self.streamerPresenter.localOnlineUser.currentScreenShareOpen) {
            message = PLVLocalizedString(@"你已被移除主讲权限，屏幕共享已结束");
            [self.streamerPresenter.localOnlineUser wantOpenScreenShare:NO];
        } else {
            message = PLVLocalizedString(@"你已被移除主讲权限");
        }
    } else {
        if (authSpeaker) {
            message = [NSString stringWithFormat:PLVLocalizedString(@"%@ 成为主讲人"), onlineUser.nickname];
        } else {
            message = [NSString stringWithFormat:PLVLocalizedString(@"%@ 的主讲权限已被移除"), onlineUser.nickname];
        }
    }
    [PLVSAUtils showToastWithMessage:message inView:self.view];
    [onlineUser updateUserIsGuestTransferPermission:NO];
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter wantForceCloseOnlineUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser lastFailed:(BOOL)lastFailed {
    if (!lastFailed) {
        [PLVSAUtils showAlertWithTitle:@"" Message:[NSString stringWithFormat:PLVLocalizedString(@"【%@】因网络不稳定，导致下麦失败，可采用强制下麦，用户会自动重新进入房间、也可再次发起正常下麦"), onlineUser.nickname] cancelActionTitle:PLVLocalizedString(@"正常下麦") cancelActionBlock:^{
            [onlineUser wantCloseUserLinkMic];
        }  confirmActionTitle:PLVLocalizedString(@"强制下麦") confirmActionBlock:^{
            [onlineUser wantForceCloseUserLinkMic:!lastFailed];
        }];
    } else {
        [PLVSAUtils showAlertWithTitle:@"" Message:[NSString stringWithFormat:PLVLocalizedString(@"【%@】因网络不稳定，强制下麦失败，可再次尝试 强制下麦"), onlineUser.nickname] cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"强制下麦") confirmActionBlock:^{
            [onlineUser wantForceCloseUserLinkMic:!lastFailed];
        }];
    }
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
        [PLVSAUtils showAlertWithMessage:PLVLocalizedString(@"网络断开，已停止直播，请更换网络后重试") cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:nil confirmActionBlock:nil];
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

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter updateMixLayoutDidOccurError:(PLVRTCStreamerMixLayoutType)type {
    [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"网络异常，请恢复网络后重试") inView:[PLVSAUtils sharedUtils].homeVC.view];
    PLVMixLayoutType currentType = [PLVRoomData mixLayoutTypeWithStreamerMixLayoutType:type];
    [self.settingView.mixLayoutSheet updateMixLayoutType:currentType];
    [self.homeView.mixLayoutSheet updateMixLayoutType:currentType];
    [self saveSelectedMixLayoutType:currentType];
}

/// 已挂断 某位远端用户的连麦 事件回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
   didCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser {
    NSString * nickName = onlineUser.nickname;
    if (nickName.length > 12) {
        nickName = [NSString stringWithFormat:@"%@...",[nickName substringToIndex:12]];
    }
    NSString * message = [NSString stringWithFormat:PLVLocalizedString(@"已挂断%@的连麦"),nickName];
    [PLVSAUtils showToastWithMessage:message inView:self.view];
}

/// 本地用户的 ’麦克风开关状态‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
     localUserMicOpenChanged:(BOOL)currentMicOpen {
    if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [PLVSAUtils showToastWithMessage:(currentMicOpen ? PLVLocalizedString(@"已开启麦克风") : PLVLocalizedString(@"已关闭麦克风")) inView:self.view];
    }
    self.showMicTipsTimeInterval = 0;
    [self.homeView setCurrentMicOpen:currentMicOpen];
}

/// 本地用户的 ’摄像头是否应该显示值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
localUserCameraShouldShowChanged:(BOOL)currentCameraShouldShow {
    if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [PLVSAUtils showToastWithMessage:(currentCameraShouldShow ? PLVLocalizedString(@"已开启摄像头") : PLVLocalizedString(@"已关闭摄像头")) inView:self.view];
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
        NSString *message = currentScreenShareOpen ? PLVLocalizedString(@"其他人现在可以看到你的屏幕") : PLVLocalizedString(@"共享已结束");
        [PLVSAUtils showToastWithMessage:message inView:self.view];
    }
    [self.homeView changeScreenShareButtonSelectedState:currentScreenShareOpen];
    [self updateScreenShareCustomManagerState];
    
    // 屏幕共享开启、关闭 对应隐藏贴图视图
    self.stickerCanvas.hidden = currentScreenShareOpen;
}

/// 远程用户的  ’屏幕共享开关状态‘  发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUser:(PLVLinkMicOnlineUser *)onlineUser screenShareOpenChanged:(BOOL)screenShareOpen {

}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter waitLinkMicUser:(nonnull PLVLinkMicWaitUser *)waitUser joinAnswer:(BOOL)isAccept {
    if (waitUser && !isAccept) {
        NSString *message = [NSString stringWithFormat:PLVLocalizedString(@"%@没有接受你的邀请"), waitUser.nickname];
        [PLVSAUtils showToastWithMessage:message inView:self.view];
    }
}

- (void)plvStreamerPresenterLocalUserLeaveRTCChannelByServerComplete:(PLVStreamerPresenter *)presenter {
    [PLVSAUtils showToastWithCountMessage:PLVLocalizedString(@"网络加载有误，即将重新进入直播间") inView:self.view afterCountdown:3 finishHandler:^{
        if ([self.delegate respondsToSelector:@selector(saStreamerViewControllerGuestNeedReLogin:)]) {
            [self.delegate saStreamerViewControllerGuestNeedReLogin:self];
        }
    }];
}

/// 推流管理器 ‘发生错误’ 回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
               didOccurError:(NSError *)error
               fullErrorCode:(NSString *)fullErrorCodeString {
    NSString * message = @"";
    if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedEmitFailed) {
        message = PLVLocalizedString(@"上课错误");
    }else if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedNetError){
        message = PLVLocalizedString(@"推流请求错误，请退出重新登录");
    }else if (error.code == PLVStreamerPresenterErrorCode_UpdateRTCTokenFailedNetError){
        message = PLVLocalizedString(@"更新Token错误");
    }else if (error.code == PLVStreamerPresenterErrorCode_RTCManagerError){
        message = PLVLocalizedString(@"RTC内部错误");
    }else if (error.code == PLVStreamerPresenterErrorCode_RTCManagerErrorStartAudioFailed){
        message = PLVLocalizedString(@"RTC内部错误，启动音频模块失败，请退出重新登录");
    }else if (error.code == PLVStreamerPresenterErrorCode_EndClassFailedNetFailed){
        message = PLVLocalizedString(@"下课错误，请直接退出上课页");
    }else if (error.code >= PLVStreamerPresenterErrorCode_AnswerInvitationFailedStatusIllegal && error.code <= PLVStreamerPresenterErrorCode_AnswerInvitationFailedLinkMicLimited){
        message = (error.code == PLVStreamerPresenterErrorCode_AnswerInvitationFailedLinkMicLimited) ? PLVLocalizedString(@"上麦失败，当前上麦人数已达最大人数") : PLVLocalizedString(@"上麦失败");
    }else if (error.code == PLVStreamerPresenterErrorCode_UnknownError){
        message = PLVLocalizedString(@"未知错误");
    }else if (error.code == PLVStreamerPresenterErrorCode_NoError){
        message = PLVLocalizedString(@"错误");
    }
    message = [message stringByAppendingFormat:@" code:%@",fullErrorCodeString];
    
    if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedEmitFailed) {
        [PLVSAUtils showAlertWithMessage:[NSString stringWithFormat:PLVLocalizedString(@"检测到%@，是否结束直播"), message] cancelActionTitle:PLVLocalizedString(@"继续直播") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"结束直播") confirmActionBlock:^{
            [self logout];
        }];
    } else {
        [PLVSAUtils showToastWithMessage:message inView:self.view afterDelay:3];
    }
}

/// 本地用户 麦克风音量大小检测
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserVoiceValue:(CGFloat)localVoiceValue receivedLocalAudibleVoice:(BOOL)voiceAudible {
    if (!self.streamerPresenter.currentMicOpen && localVoiceValue >= 0.4) {
        NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
        if (currentTimeInterval - self.showMicTipsTimeInterval > 180) {
            [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"您已静音，请开启麦克风后发言") inView:self.view];
            self.showMicTipsTimeInterval = [[NSDate date] timeIntervalSince1970];
        }
    }
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter beautyDidInitWithResult:(int)result {
    if (result == 0) {
        // 配置美颜
        PLVBeautyManager *beautyManager = [self.streamerPresenter shareBeautyManager];
        // 设置美颜sdk 类型
        if ([PLVRoomDataManager sharedManager].roomData.appBeautyEnabled){
            [[PLVBeautyViewModel sharedViewModel] startBeautyWithManager:beautyManager sdkType:PLVBeautySDKTypeProfessional];
        }
        else if ([PLVRoomDataManager sharedManager].roomData.lightBeautyEnabled){
            [[PLVBeautyViewModel sharedViewModel] startBeautyWithManager:beautyManager sdkType:PLVBeautySDKTypeLight];
        }
    } else {
        [PLVSAUtils showToastInHomeVCWithMessage:[NSString stringWithFormat:PLVLocalizedString(@"美颜初始化失败 %d 请重进直播间"), result]];
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

- (void)plvSALinkMicAreaView:(PLVSALinkMicAreaView *)areaView acceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel {
    [self.streamerPresenter localUserAcceptLinkMicInvitation:accept timeoutCancel:timeoutCancel];
}

- (void)plvSALinkMicAreaView:(PLVSALinkMicAreaView *)areaView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback {
    [self.streamerPresenter requestLocalUserInviteLinkMicTTLCallback:callback];
}

#pragma mark PLVSAStreamerSettingViewDelegate

- (void)streamerSettingViewBackButtonClick {
    [self logout];
}

- (void)streamerSettingViewStartButtonClickWithResolutionType:(PLVResolutionType)type {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:type];
    PLVBLinkMicStreamScale currentStreamScale =[PLVSAUtils sharedUtils].isLandscape ? self.streamScale : PLVBLinkMicStreamScale9_16;
    [self.streamerPresenter setupStreamScale:currentStreamScale];
    if ([PLVFdUtil checkStringUseable:self.settingView.defaultQualityLevel]) {
        [self.streamerPresenter setupStreamQualityLevel:self.streamerPresenter.streamQualityLevel];
    } else {
        [self.streamerPresenter setupStreamQuality:streamQuality];
    }
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

- (void)streamerSettingViewBitRateSheetDidSelectStreamQualityLevel:(NSString *)streamQualityLevel {
    [self.streamerPresenter setupStreamQualityLevel:streamQualityLevel];
}

- (void)streamerSettingViewDidClickBeautyButton:(PLVSAStreamerSettingView *)streamerSettingView {
    if (self.streamerPresenter.currentCameraOpen) {
        [self showBeautySheet:YES];
    } else {
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"请开启摄像头后使用") inView:self.view];
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

- (void)streamerSettingViewMixLayoutButtonClickWithMixLayoutType:(PLVMixLayoutType)type {
    PLVRTCStreamerMixLayoutType mixLayoutType = [PLVRoomData streamerMixLayoutTypeWithMixLayoutType:type];
    [self.streamerPresenter setupMixLayoutType:mixLayoutType];
    [self saveSelectedMixLayoutType:type];
}

- (void)streamerSettingViewTopSettingButtonClickWithNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel {
    [self.streamerPresenter setupNoiseCancellationLevel:noiseCancellationLevel];
    [self.settingView synchNoiseCancellationLevel:self.streamerPresenter.noiseCancellationLevel];
    [self saveSelectedNoiseCancellationLevel:self.streamerPresenter.noiseCancellationLevel];
}

- (void)streamerSettingViewExternalDeviceButtonClickWithExternalDeviceEnabled:(BOOL)enabled {
    if (enabled) {
        __weak typeof(self) weakSelf = self;
        [PLVSAUtils showAlertWithTitle:PLVLocalizedString(@"温馨提示") Message:PLVLocalizedString(@"注意：媒体音量下，使用手机应用所产生提示音、音视频声音也将被采集并直播出去，请谨慎开启！") cancelActionTitle:PLVLocalizedString(@"不开启") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确认开启") confirmActionBlock:^{
            [weakSelf.streamerPresenter enableExternalDevice:enabled];
            [weakSelf.settingView synchExternalDeviceEnabled:self.streamerPresenter.localExternalDeviceEnabled];
            [weakSelf saveSelectedNoiseCancellationLevel:self.streamerPresenter.localExternalDeviceEnabled];
            [weakSelf.settingView externalDeviceSwitchSheetViewDismiss];
        }];
    } else {
        [self.streamerPresenter enableExternalDevice:enabled];
        [self.settingView synchExternalDeviceEnabled:self.streamerPresenter.localExternalDeviceEnabled];
        [self saveSelectedNoiseCancellationLevel:self.streamerPresenter.localExternalDeviceEnabled];
    }
}

- (void)streamerSettingViewDidClickStickerButton:(PLVSAStreamerSettingView *)streamerSettingView {
    if (self.streamerPresenter.currentCameraOpen) {
        // 检查相册权限
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showImagePicker];
                    });
                }
            }];
        } else if (status == PHAuthorizationStatusAuthorized) {
            [self showImagePicker];
        } else {
            // 无权限时提示用户
            [PLVSAUtils showAlertWithTitle:PLVLocalizedString(@"相册权限申请")
                                 Message:PLVLocalizedString(@"请前往“设置-隐私”开启权限")
                       cancelActionTitle:PLVLocalizedString(@"取消")
                       cancelActionBlock:nil
                      confirmActionTitle:PLVLocalizedString(@"设置")
                      confirmActionBlock:^{
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
    } else {
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"请开启摄像头后使用") inView:self.view];
    }
}

// 显示图片选择器
- (void)showImagePicker {
    PLVImagePickerViewController *imagePickerVC = [[PLVImagePickerViewController alloc] initWithColumnNumber:4];
    imagePickerVC.allowPickingOriginalPhoto = YES;
    imagePickerVC.allowPickingVideo = NO;
    imagePickerVC.allowTakePicture = NO;
    imagePickerVC.allowTakeVideo = NO;
    imagePickerVC.maxImagesCount = 10;
    __weak typeof(self) weakSelf = self;
    
    if (self.stickerCanvas.curImageCount > 0){
        imagePickerVC.maxImagesCount = 10 - self.stickerCanvas.curImageCount ;
    }
    [imagePickerVC setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        //实现图片选择回调
        if (photos.count > 0) {
            // 不使用懒加载初始化
            if (!weakSelf.stickerCanvas){
                
                weakSelf.stickerCanvas = [[PLVStickerCanvas alloc] init];
                weakSelf.stickerCanvas.delegate = self;
            }
            [self.view insertSubview:weakSelf.stickerCanvas aboveSubview:self.settingView];
            weakSelf.stickerCanvas.frame = self.view.bounds;
            [weakSelf.stickerCanvas layoutIfNeeded];
            
            [weakSelf.stickerCanvas showCanvasWithImages:photos];
        }
    }];
     
    [imagePickerVC setImagePickerControllerDidCancelHandle:^{
        //实现图片选择取消回调
    }];
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)streamerSettingViewDidClickVirtualBackgroundButton:(PLVSAStreamerSettingView *)streamerSettingView {
    [self showAIMattingSheet];
}

/// AI 抠像设置面板弹出
- (void)showAIMattingSheet{
    if (self.streamerPresenter.currentCameraOpen) {
        // 实现虚拟背景功能
        NSInteger width = self.view.bounds.size.width;
        NSInteger height = width;
        BOOL isFullscreen = [UIScreen mainScreen].bounds.size.width >  [UIScreen mainScreen].bounds.size.height;
        if (isFullscreen){
            width = [UIScreen mainScreen].bounds.size.height;
            height = width;
        }
        if (!self.aiMattingSheet){
            self.aiMattingSheet = [[PLVVirtualBackgroudSheet alloc] initWithSheetHeight:width sheetLandscapeWidth:height];
            self.aiMattingSheet.delegate = self;
        }
        [self.aiMattingSheet showInView:self.view];
        
    } else {
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"请开启摄像头后使用") inView:self.view];
    }
}

#pragma mark PLVSAStreamerHomeViewProtocol

- (void)bandUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId banned:(BOOL)banned {
    [self.memberPresenter banUserWithUserId:userId banned:banned];
}

- (void)kickUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId {
    [self.memberPresenter kickUserWithUserId:userId];
}

- (void)inviteUserJoinLinkMicInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUser:(PLVLinkMicWaitUser *)user {
    [self.streamerPresenter inviteRemoteUserJoinLinkMic:user emitCompleteBlock:nil];
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
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"屏幕共享需讲师授权") inView:self.view];
        [self.homeView changeScreenShareButtonSelectedState:NO];
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        if (screenShareOpen) {
            [self.homeView changeScreenShareButtonSelectedState:NO];
            if (@available(iOS 15.0, *)) { // 提前启动避免秒切后台无法启动浮窗
                if (!self.screenShareCustomPIPManager) {
                    self.screenShareCustomPIPManager = [[PLVSAScreenShareCustomPictureInPictureManager alloc] initWithDisplaySuperview:self.screenShareCustomPipDisplayView];
                    self.screenShareCustomPIPManager.delegate = self;
                }
            }
            if (@available(iOS 12.0, *)) {
                [[PLVBroadcastExtensionLauncher sharedInstance] launch];
            } else {
                NSString *message = PLVLocalizedString(@"请到控制中心，长按录制按钮，选择 POLYV屏幕共享 打开录制");
                [PLVSAUtils showAlertWithMessage:message cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"我知道了") confirmActionBlock:nil];
            }
        } else {
            [self.streamerPresenter openLocalUserScreenShare:screenShareOpen];
        }
     } else {
         if (screenShareOpen) {
             [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"屏幕共享功能需要iOS11以上系统支持") inView:self.view];
             [self.homeView changeScreenShareButtonSelectedState:!screenShareOpen];
         }
     }
}

- (PLVResolutionType)streamerHomeViewCurrentQuality:(PLVSAStreamerHomeView *)homeView {
    PLVResolutionType resolutionType = [PLVRoomData resolutionTypeWithStreamQuality:self.streamerPresenter.streamQuality];
    return resolutionType;
}

- (NSString *)streamerHomeViewCurrentStreamQualityLevel:(PLVSAStreamerHomeView *)homeView {
    return self.streamerPresenter.streamQualityLevel;
}

- (PLVMixLayoutType)streamerHomeViewCurrentMixLayoutType:(PLVSAStreamerHomeView *)homeView {
    PLVMixLayoutType mixLayoutType = [PLVRoomData mixLayoutTypeWithStreamerMixLayoutType:self.streamerPresenter.mixLayoutType];
    return mixLayoutType;
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
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"尚未开通，请联系管理员") inView:self.view];
        [self.homeView setLinkMicButtonSelected:NO];
        return;
    }
    
    if (!self.streamerPresenter.channelLinkMicOpen) {
        [self startLinkMic:YES videoLinkMic:videoLinkMic];
    } else {
        __weak typeof(self) weakSelf = self;
        NSString *title = self.streamerPresenter.channelLinkMicMediaType == PLVChannelLinkMicMediaType_Audio ? PLVLocalizedString(@"确定关闭语音连麦吗？") : PLVLocalizedString(@"确定关闭视频连麦吗？");
        [PLVSAUtils showAlertWithTitle:title Message:PLVLocalizedString(@"关闭后将挂断进行中的所有连麦") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:^{
            [weakSelf.homeView setLinkMicButtonSelected:YES];
        } confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
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

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeStreamQualityLevel:(NSString *)streamQualityLevel {
    [self.streamerPresenter setupStreamQualityLevel:streamQualityLevel];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeMixLayoutType:(PLVMixLayoutType)type {
    PLVRTCStreamerMixLayoutType streamerMixLayout = [PLVRoomData streamerMixLayoutTypeWithMixLayoutType:type];
    [self.streamerPresenter setupMixLayoutType:streamerMixLayout];
    [self saveSelectedMixLayoutType:type];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference {
    [self.streamerPresenter setupVideoQosPreference:videoQosPreference];
}

- (PLVBRTCVideoQosPreference)streamerHomeViewCurrentVideoQosPreference:(PLVSAStreamerHomeView *)homeView {
    return self.streamerPresenter.videoQosPreference;
}

- (void)streamerHomeViewDidTapBeautyButton:(PLVSAStreamerHomeView *)homeView {
    if (self.streamerPresenter.currentCameraOpen) {
        [self showBeautySheet:YES];
    } else {
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"请开启摄像头后使用") inView:self.view];
    }
}

- (void)streamerHomeViewDidTapShareButton:(PLVSAStreamerHomeView *)homeView {
    [self.shareLiveSheet showInView:self.view];
}

- (PLVChannelLinkMicMediaType)streamerHomeViewCurrentChannelLinkMicMediaType:(PLVSAStreamerHomeView *)homeView {
    return self.streamerPresenter.channelLinkMicMediaType;
}

- (void)streamerHomeViewDidAllowRaiseHandButton:(PLVSAStreamerHomeView *)homeView wannaChangeAllowRaiseHand:(BOOL)allowRaiseHand {
    if ([PLVReachability reachabilityForInternetConnection].currentReachabilityStatus == PLVNotReachable) {
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"当前网络信号弱，开启失败，请检查网络！") inView:self.homeView];
        return;
    }
    
    if (![PLVRoomDataManager sharedManager].roomData.linkmicNewStrategyEnabled) {
        return;
    }
    
    NSString * successTitle = allowRaiseHand ? PLVLocalizedString(@"已开启观众连麦") : PLVLocalizedString(@"已关闭观众连麦");
    NSString * failTitle = allowRaiseHand ? PLVLocalizedString(@"开启观众连麦失败，请稍后再试") : PLVLocalizedString(@"关闭观众连麦失败，请稍后再试");
    __weak typeof(self) weakSelf = self;
    
    [self.streamerPresenter allowRaiseHand:allowRaiseHand emitCompleteBlock:^(BOOL emitSuccess) {
        plv_dispatch_main_async_safe(^{
            if (emitSuccess) {
                [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                [PLVSAUtils showToastInHomeVCWithMessage:successTitle];
                [weakSelf.homeView changeAllowRaiseHandButtonSelectedState:allowRaiseHand];
            }else{
                [PLVSAUtils showToastInHomeVCWithMessage:failTitle];
            }
        })
    }];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView wannaChangeLinkMicType:(BOOL)linkMicOnAudio {
    __weak typeof(self) weakSelf = self;
    
    if (self.streamerPresenter.onlineUserArray.count > 1) {
        [PLVSAUtils showAlertWithTitle:PLVLocalizedString(@"提示") Message:PLVLocalizedString(@"当前有用户在连麦，无法切换连麦方式，若要切换，需将麦上用户全部下麦，确认切换连麦方式吗？") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"切换并下麦所有用户") confirmActionBlock:^{
            [weakSelf.streamerPresenter removeAllAudiences];
            [weakSelf.streamerPresenter changeLinkMicMediaType:linkMicOnAudio allowRaiseHand:weakSelf.streamerPresenter.channelLinkMicOpen emitCompleteBlock:^(BOOL emitSuccess) {
                if (emitSuccess) {
                    [weakSelf.homeView updateHomeViewLinkMicType:linkMicOnAudio];
                    [weakSelf.homeView changeAllowRaiseHandButtonSelectedState:weakSelf.streamerPresenter.channelLinkMicOpen];
                    [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                }
            }];
        }];
    } else {
        [self.streamerPresenter removeAllAudiences];
        [self.streamerPresenter changeLinkMicMediaType:linkMicOnAudio allowRaiseHand:self.streamerPresenter.channelLinkMicOpen emitCompleteBlock:^(BOOL emitSuccess) {
            if (emitSuccess) {
                [weakSelf.homeView updateHomeViewLinkMicType:linkMicOnAudio];
                [weakSelf.homeView changeAllowRaiseHandButtonSelectedState:weakSelf.streamerPresenter.channelLinkMicOpen];
                [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
            }
        }];
    }
}

- (void)streamerHomeViewDidTapRemoveAllAudiencesButton:(PLVSAStreamerHomeView *)homeView {
    __weak typeof(self) weakSelf = self;
    [PLVSAUtils showAlertWithTitle:PLVLocalizedString(@"提示") Message:PLVLocalizedString(@"确认下麦所有连麦观众吗？") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确认") confirmActionBlock:^{
        [weakSelf.streamerPresenter removeAllAudiences];
    }];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeDesktopChatEnable:(BOOL)desktopChatEnable {
    [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled = desktopChatEnable;
    [self updateScreenShareCustomManagerState];
}

/// 贴图按钮点击
- (void)streamerHomeViewDidTapStickerButton:(PLVSAStreamerHomeView *)homeView{
    [self showImagePicker];
}

/// 虚拟背景按钮点击
- (void)streamerHomeViewDidTapAiMattingButton:(PLVSAStreamerHomeView *)homeView {
    [self showAIMattingSheet];
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
    [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.view];
}

- (void)shareLiveSheet:(PLVShareLiveSheet *)shareLiveSheet savePictureSuccess:(BOOL)success {
    NSString *message = success ? PLVLocalizedString(@"图片已保存到相册") : PLVLocalizedString(@"保存失败");
    [PLVSAUtils showToastWithMessage:message inView:self.view];
}

#pragma mark -- PLVStickerCanvasDelegate
- (void)stickerCanvasExitEditMode:(PLVStickerCanvas *)stickerCanvas{
    // 退出贴图编辑模式
    self.stickerCanvas.enableEdit = NO;

    UIImage *image = [self.stickerCanvas generateImageWithTransparentBackground];
    // 将图片传递给Streampresent 管理
    [self.streamerPresenter setStickerImage:image];
    
    if (_viewState == PLVSAStreamerViewStateBeforeSteam){
        [self.view insertSubview:self.stickerCanvas belowSubview:self.settingView];
    }
    else if (_viewState == PLVSAStreamerViewStateBeginSteam){
        
    }
    else if (_viewState == PLVSAStreamerViewStateSteaming){
        // 直播中
        [self.homeView addStickerCanvasView:self.stickerCanvas editMode:NO];
    }
    else if (_viewState == PLVSAStreamerViewStateFinishSteam){
        
    }
}

- (void)stickerCanvasEnterEditMode:(PLVStickerCanvas *)stickerCanvas{
    // 进入贴图编辑模式
    self.stickerCanvas.enableEdit = YES;
    if (_viewState == PLVSAStreamerViewStateBeforeSteam){
        [self.view insertSubview:self.stickerCanvas aboveSubview:self.settingView];
    }
    else if (_viewState == PLVSAStreamerViewStateBeginSteam){
        
    }
    else if (_viewState == PLVSAStreamerViewStateSteaming){
        [self.homeView addStickerCanvasView:self.stickerCanvas editMode:YES];
    }
    else if (_viewState == PLVSAStreamerViewStateFinishSteam){
        
    }
}

#pragma mark PLVSAScreenShareCustomPictureInPictureManagerDelegate

- (void)PLVSAScreenShareCustomPictureInPictureManager_needUpdateContent {
    [self.screenShareCustomPIPManager updateContent:self.homeView.currentNewMessage networkState:self.streamerPresenter.networkQuality];
}

#pragma mark PLVVirtualBackgroudSheetDelegate
- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet matType:(PLVVirtualBackgroudMatType)matType image:(UIImage *)matBgImage{
    switch (matType) {
        case PLVVirtualBackgroudMatTypeNone:
            [self.streamerPresenter setAIMattingMode:PLVBLinkMicAIMattingModeNone image:matBgImage];
            break;
        case PLVVirtualBackgroudMatTypeBlur:
            [self.streamerPresenter setAIMattingMode:PLVBLinkMicAIMattingModeBlue image:matBgImage];
            break;
        case PLVVirtualBackgroudMatTypeCustomImage:
            [self.streamerPresenter setAIMattingMode:PLVBLinkMicAIMattingModeCustomImage image:matBgImage];
            break;
        default:
            break;
    }
}

@end

