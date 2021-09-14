//
//  PLVLSStreamerViewController.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/2/23.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSStreamerViewController.h"

// 工具类
#import "PLVLSUtils.h"

// UI
#import "PLVLSChannelInfoSheet.h"
#import "PLVLSSettingSheet.h"
#import "PLVLSStatusAreaView.h"
#import "PLVLSDocumentAreaView.h"
#import "PLVLSCountDownView.h"
#import "PLVLSChatroomAreaView.h"
#import "PLVLSMemberSheet.h"
#import "PLVLSLinkMicAreaView.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"
#import "PLVLSChatroomViewModel.h"
#import "PLVStreamerPresenter.h"
#import "PLVMemberPresenter.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSStreamerViewController ()<
PLVSocketManagerProtocol,
PLVRoomDataManagerProtocol,
PLVLSSettingSheetProtocol,
PLVLSStatusAreaViewProtocol,
PLVLSDocumentAreaViewDelegate,
PLVLSChatroomAreaViewProtocol,
PLVLSMemberSheetDelegate,
PLVLSLinkMicAreaViewDelegate,
PLVStreamerPresenterDelegate,
PLVMemberPresenterDelegate
>

#pragma mark 功能
@property (nonatomic, strong) PLVStreamerPresenter *streamerPresenter;
@property (nonatomic, strong) PLVMemberPresenter *memberPresenter;

#pragma mark UI
@property (nonatomic, assign, getter=isFullscreen) BOOL fullscreen; // 是否处于文档区域全屏状态，默认为NO
@property (nonatomic, strong) PLVLSStatusAreaView *statusAreaView;  // 顶部状态栏区域
@property (nonatomic, strong) PLVLSDocumentAreaView *documentAreaView;   // 左侧白板&PPT区域
@property (nonatomic, strong) PLVLSChatroomAreaView *chatroomAreaView;   // 左下角聊天室区域
@property (nonatomic, strong) PLVLSLinkMicAreaView *linkMicAreaView;
@property (nonatomic, strong) PLVLSChannelInfoSheet *channelInfoSheet;
@property (nonatomic, strong) PLVLSSettingSheet *settingSheet;
@property (nonatomic, strong) PLVLSMemberSheet *memberSheet;
@property (nonatomic, strong) PLVLSCountDownView *coutBackView; // 开始上课时的倒数蒙层

#pragma mark 数据
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中

@end

@implementation PLVLSStreamerViewController

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        PLVRoomUser *roomUser = roomData.roomUser;
        
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // 启动聊天室管理器
        [[PLVLSChatroomViewModel sharedViewModel] setup];
        
        // 监听socket消息
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [PLVLSUtils sharedUtils].homeVC = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:1];
    
    [self setupUI];
    [self setupModule];
    [self preapareStartClass];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self getEdgeInset];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    // 状态栏高度固定44，宽度需减去两倍左右安全区域
    self.statusAreaView.frame = CGRectMake(PLVLSUtils.safeSidePad, 0, screenSize.width - PLVLSUtils.safeSidePad * 2, 44);
    
    // 文档区域宽高默认16:9，剩余的空间给推流区域，推流区域的宽度必须大于138，如果小于138，减少文档区域的宽度
    // 文档区域与推流区域间距为8
    CGFloat ducomentViewHeight = screenSize.height - 44 - PLVLSUtils.safeBottomPad;
    CGFloat documentAreaViewWidth = ducomentViewHeight * 16.0 / 9.0;
    CGFloat linkMicAreaViewLeftPadding = 8;
    CGFloat linkMicAreaViewWidth = screenSize.width - PLVLSUtils.safeSidePad * 2 - documentAreaViewWidth - linkMicAreaViewLeftPadding;
    if (linkMicAreaViewWidth < 138) {
        linkMicAreaViewWidth = 138;
        documentAreaViewWidth = screenSize.width - PLVLSUtils.safeSidePad * 2 - 138 - 8;
    }
    self.documentAreaView.frame = CGRectMake(PLVLSUtils.safeSidePad, 44, documentAreaViewWidth, ducomentViewHeight);
    
    self.linkMicAreaView.frame = CGRectMake(CGRectGetMaxX(self.documentAreaView.frame) + linkMicAreaViewLeftPadding, CGRectGetMaxY(self.statusAreaView.frame), linkMicAreaViewWidth, ducomentViewHeight);
        
    // 聊天室宽高固定(308, 210)，左边与底部贴紧文档区域
    self.chatroomAreaView.frame = CGRectMake(PLVLSUtils.safeSidePad, screenSize.height - PLVLSUtils.safeBottomPad - 210, 308, 210);
    
    if (self.isFullscreen) {
        self.documentAreaView.frame = self.view.bounds;
    }
}

#pragma mark - Initialize

- (void)setupUI {
    // 非全屏状态下，documentAreaView 在最底部，需最先添加进去
    [self.view addSubview:self.documentAreaView];
    [self.view addSubview:self.linkMicAreaView];
    [self.view addSubview:self.chatroomAreaView];
    // 非全屏状态下，顶部 statusAreaView 必须在最顶端，需最后添加进去
    [self.view addSubview:self.statusAreaView];

    // 初始化
    [self.settingSheet showInView:nil]; /// 仅用于初始化
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.menuInfo) {
        [self roomDataManager_didMenuInfoChanged:roomData.menuInfo];
    }
}

- (void)setupModule{
    self.streamerPresenter = [[PLVStreamerPresenter alloc] init];
    self.streamerPresenter.delegate = self;
    self.streamerPresenter.preRenderContainer = self.linkMicAreaView;
    self.streamerPresenter.previewType = PLVStreamerPresenterPreviewType_UserArray;
    self.streamerPresenter.micDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultFront = YES;
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:self.settingSheet.resolution];
    [self.streamerPresenter setupStreamQuality:streamQuality];
    [self.streamerPresenter setupMixLayoutType:PLVRTCStreamerMixLayoutType_MainSpeaker];
    
    self.memberPresenter = [[PLVMemberPresenter alloc] init];
    self.memberPresenter.delegate = self;
    [self.memberPresenter start];// 开始获取成员列表数据并开启自动更新
}

- (void)getEdgeInset {
    if (PLVLSUtils.safeBottomPad > 0 && PLVLSUtils.safeSidePad > 0) {
        return;
    }
    
    // 在 -viewWillLayoutSubviews 方法里设置 UI 是为了正确获取安全区域
    CGFloat safeSidePad = 0;
    CGFloat safeBottomPad = 0;
    if (@available(iOS 11, *)) {
        safeSidePad = MAX(self.view.safeAreaInsets.left, self.view.safeAreaInsets.right);
        safeBottomPad = MAX(self.view.safeAreaInsets.top, self.view.safeAreaInsets.bottom);
    }
    PLVLSUtils.safeSidePad = safeSidePad < 16 ? 16 : safeSidePad;
    PLVLSUtils.safeBottomPad = safeBottomPad < 10 ? 10 : safeBottomPad;
}

#pragma mark - Override

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

#pragma mark - Getter

- (PLVLSChannelInfoSheet *)channelInfoSheet {
    if (!_channelInfoSheet) {
        CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.75;
        _channelInfoSheet = [[PLVLSChannelInfoSheet alloc] initWithSheetHeight:sheetHeight];
        
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        [_channelInfoSheet updateChannelInfoWithData:roomData.menuInfo];
    }
    return _channelInfoSheet;
}

- (PLVLSSettingSheet *)settingSheet {
    if (!_settingSheet) {
        CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
        _settingSheet = [[PLVLSSettingSheet alloc] initWithSheetWidth:sheetWidth];
        _settingSheet.delegate = self;
    }
    return _settingSheet;
}

- (PLVLSMemberSheet *)memberSheet {
    if (!_memberSheet) {
        _memberSheet = [[PLVLSMemberSheet alloc] initWithUserList:[self.memberPresenter userList] userCount:self.memberPresenter.userCount];
        _memberSheet.delegate = self;
    }
    return _memberSheet;
}

- (PLVLSStatusAreaView *)statusAreaView {
    if (!_statusAreaView) {
        _statusAreaView = [[PLVLSStatusAreaView alloc] init];
        _statusAreaView.delegate = self;
    }
    return _statusAreaView;
}

- (PLVLSDocumentAreaView *)documentAreaView {
    if (!_documentAreaView) {
        _documentAreaView = [[PLVLSDocumentAreaView alloc] init];
        _documentAreaView.delegate = self;
    }
    return _documentAreaView;
}

- (PLVLSLinkMicAreaView *)linkMicAreaView{
    if (!_linkMicAreaView) {
        _linkMicAreaView = [[PLVLSLinkMicAreaView alloc] init];
        _linkMicAreaView.delegate = self;
    }
    return _linkMicAreaView;
}

- (PLVLSChatroomAreaView *)chatroomAreaView {
    if (!_chatroomAreaView) {
        _chatroomAreaView = [[PLVLSChatroomAreaView alloc] init];
        _chatroomAreaView.delegate = self;
    }
    return _chatroomAreaView;
}

- (PLVLSCountDownView *)coutBackView {
    if (!_coutBackView) {
        _coutBackView = [[PLVLSCountDownView alloc] init];
        _coutBackView.frame = self.view.bounds;
        
        __weak typeof(self) weakSelf = self;
        _coutBackView.countDownCompletedBlock = ^{
            [weakSelf.streamerPresenter startClass];
        };
    }
    return _coutBackView;
}

- (PLVRoomUserType)viewerType{
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
}

#pragma mark - Private

- (void)documentFullscreen:(BOOL)fullscreen {
    if (fullscreen) {
        [self.view insertSubview:self.documentAreaView aboveSubview:self.statusAreaView];
    } else {
        [self.view insertSubview:self.documentAreaView atIndex:0];
    }
}

- (void)logout {
    if (self.streamerPresenter.classStarted) {
        [self finishClass]; // 结束当前课程
    }
    
    [PLVRoomLoginClient logout];
    [[PLVLSChatroomViewModel sharedViewModel] clear];
    [[PLVDocumentUploadClient sharedClient] stopAllUpload]; // 停止一切上传任务
    [[PLVDocumentConvertManager sharedManager] clear]; // 清空文档转码轮询队列
    [self.memberPresenter stop]; // 成员列表数据停止自动更新
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.streamerPresenter.classStarted ? 0.5 : 0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[PLVSocketManager sharedManager] logout];
    });
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Start Class

- (void)preapareStartClass {
    __weak typeof(self) weakSelf = self;
    [self.streamerPresenter prepareLocalMicCameraPreviewCompletion:^(BOOL granted, BOOL prepareSuccess) {
        if (prepareSuccess) {
            [weakSelf.streamerPresenter setupLocalPreviewWithCanvaView:nil setupCompletion:^(BOOL setupResult) {
                if (setupResult) {
                    [weakSelf.streamerPresenter startLocalMicCameraPreviewByDefault];
                }
            }];
        }
        if (!granted) {
            NSString *msg = [NSString stringWithFormat:@"需要获取您的音视频权限，请前往设置"];
            [PLVAuthorizationManager showAlertWithTitle:@"提示" message:msg viewController:weakSelf];
        }
    }];
}

- (BOOL)tryStartClass {
    if (self.streamerPresenter.micCameraGranted) {
        if (self.streamerPresenter.networkQuality == PLVBLinkMicNetworkQualityUnknown ||
            self.streamerPresenter.networkQuality >= PLVBLinkMicNetworkQualityBad) {
            /// 网络不佳提示
            NSString * message = (self.streamerPresenter.networkQuality == PLVBLinkMicNetworkQualityUnknown) ? @"网络检测中，请稍后再试" : @"网络不佳，请稍后再试";
            [PLVLSUtils showAlertWithMessage:message cancelActionTitle:@"知道了" cancelActionBlock:nil confirmActionTitle:nil confirmActionBlock:nil];
            return NO;
        } else {
            /// 开始上课倒数
            [self.coutBackView startCountDownOnView:self.view];
            return YES;
        }
    }else{
        [self preapareStartClass];
        return NO;
    }
}

- (void)startClass:(NSDictionary *)startClassInfoDict {
    [self.statusAreaView startPushButtonEnable:YES];
    [self.statusAreaView startClass:YES];
    [self.documentAreaView startClass:startClassInfoDict];
}

- (void)finishClass {
    [self.statusAreaView startPushButtonEnable:YES];
    [self.statusAreaView startClass:NO];
    [self.streamerPresenter finishClass];
    [self.documentAreaView finishClass];
    
    if (self.viewerType == PLVSocketUserTypeGuest) { // 嘉宾登录 下课后重置为未非全屏
        self.fullscreen = NO;
        [self documentFullscreen:self.fullscreen];
    }
}

#pragma mark socket 数据解析

/// 讲师关闭、打开聊天室
- (void)closeRoomEvent:(NSDictionary *)jsonDict {
    NSDictionary *value = PLV_SafeDictionaryForDictKey(jsonDict, @"value");
    BOOL closeRoom = PLV_SafeBoolForDictKey(value, @"closed");
    NSString *string = closeRoom ? @"聊天室已经关闭" : @"聊天室已经打开";
    plv_dispatch_main_async_safe(^{
        [PLVLSUtils showToastInHomeVCWithMessage:string];
    })
}

#pragma mark - PLVRoomDataManager Protocol

- (void)roomDataManager_didMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    // 此时更新频道信息弹层数据不能使用self，会过早触发弹层初始化，导致弹层高度计算错误
    [_channelInfoSheet updateChannelInfoWithData:menuInfo];
}

#pragma mark - PLVLSStatusAreaView Protocol

- (void)statusAreaView_didTapChannelInfoButton {
    [self.channelInfoSheet showInView:self.view];
}

- (void)statusAreaView_didTapWhiteboardOrDocumentButton:(BOOL)whiteboard {
    if (whiteboard) {
        [self.documentAreaView showWhiteboard];
    } else {
        [self.documentAreaView showDocument];
    }
}

- (void)statusAreaView_didTapMemberButton {
    [self.memberSheet showInView:self.view];
}

- (void)statusAreaView_didTapSettingButton {
    [self.settingSheet showInView:self.view];
}

- (void)statusAreaView_didTapShareButton {
    
}

- (BOOL)statusAreaView_didTapStartPushOrStopPushButton:(BOOL)start {
    if (start) {
        return [self tryStartClass];
    } else {
        __weak typeof(self) weakSelf = self;
        [PLVLSUtils showAlertWithMessage:@"点击下课将结束直播，确认下课吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"下课" confirmActionBlock:^{
            [weakSelf finishClass];
        }];
        return NO;
    }
}

- (BOOL)statusAreaView_didTapVideoLinkMicButton:(BOOL)start{
    if (!self.streamerPresenter.pushStreamStarted) {
        [PLVLSUtils showToastWithMessage:@"请先上课再开始连麦" inView:self.view];
        return NO;
    }else{
        if ([PLVRoomDataManager sharedManager].roomData.interactNumLimit == 0) {
            [PLVLSUtils showToastWithMessage:@"尚未开通，请联系管理员" inView:self.view];
            return NO;
        }
        
        NSString * suceessTitle = start ? @"已开启视频连麦" : @"已关闭视频连麦";
        NSString * failTitle = start ? @"开启视频连麦失败，请稍后再试" : @"关闭视频连麦失败，请稍后再试";
        __weak typeof(self) weakSelf = self;
        [self.streamerPresenter openVideoLinkMic:start emitCompleteBlock:^(BOOL emitSuccess) {
            plv_dispatch_main_async_safe(^{
                if (emitSuccess) {
                    [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                    [PLVLSUtils showToastWithMessage:suceessTitle inView:weakSelf.view];
                }else{
                    [PLVLSUtils showToastWithMessage:failTitle inView:weakSelf.view];
                }
            })
        }];
        return YES;
    }
}

- (BOOL)statusAreaView_didTapAudioLinkMicButton:(BOOL)start{
    if (!self.streamerPresenter.pushStreamStarted) {
        [PLVLSUtils showToastWithMessage:@"请先上课再开始连麦" inView:self.view];
        return NO;
    }else{
        if ([PLVRoomDataManager sharedManager].roomData.interactNumLimit == 0) {
            [PLVLSUtils showToastWithMessage:@"尚未开通，请联系管理员" inView:self.view];
            return NO;
        }
        
        NSString * suceessTitle = start ? @"已开启音频连麦" : @"已关闭音频连麦";
        NSString * failTitle = start ? @"开启音频连麦失败，请稍后再试" : @"关闭音频连麦失败，请稍后再试";
        __weak typeof(self) weakSelf = self;
        [self.streamerPresenter openAudioLinkMic:start emitCompleteBlock:^(BOOL emitSuccess) {
            plv_dispatch_main_async_safe(^{
                if (emitSuccess) {
                    [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                    [PLVLSUtils showToastWithMessage:suceessTitle inView:weakSelf.view];
                }else{
                    [PLVLSUtils showToastWithMessage:failTitle inView:weakSelf.view];
                }
            })
        }];
        return YES;
    }
}

- (PLVLSStatusBarControls)statusAreaView_selectControlsInDemand{
    if (self.viewerType == PLVRoomUserTypeGuest) {
        PLVChannelLiveStreamState streamState = self.streamerPresenter.currentStreamState;
        if(streamState == PLVChannelLiveStreamState_Live){
            return PLVLSStatusBarControls_ChannelInfo | PLVLSStatusBarControls_TimeLabel | PLVLSStatusBarControls_SignalButton | PLVLSStatusBarControls_MemberButton | PLVLSStatusBarControls_SettingButton;
        }else{
            return PLVLSStatusBarControls_ChannelInfo | PLVLSStatusBarControls_SignalButton | PLVLSStatusBarControls_MemberButton | PLVLSStatusBarControls_SettingButton;
        }
    }
    return PLVLSStatusBarControls_All;
}

#pragma mark - PLVLSSettingSheet Protocol

- (void)settingSheet_didTapLogoutButton {
    [PLVLSUtils showAlertWithMessage:@"确认结束直播吗？" cancelActionTitle:@"按错了" cancelActionBlock:nil  confirmActionTitle:@"确定" confirmActionBlock:^{
        [self logout];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)settingSheet_didChangeResolution:(PLVResolutionType)resolution {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:resolution];
    [self.streamerPresenter setupStreamQuality:streamQuality];
}

#pragma mark - PLVLSChatroomAreaView Protocol

- (void)chatroomAreaView_didTapMicrophoneButton:(BOOL)open {
    [self.streamerPresenter openLocalUserMic:open];
}

- (void)chatroomAreaView_didTapCameraButton:(BOOL)open {
    [self.streamerPresenter openLocalUserCamera:open];
}

- (void)chatroomAreaView_didTapCameraSwitchButton {
    [self.streamerPresenter switchLocalUserFrontCamera];
}

#pragma mark - PLVLSMemberSheetDelegate

- (void)didTapCloseAllUserLinkMicInMemberSheet:(PLVLSMemberSheet *)memberSheet
                                   changeBlock:(void(^ _Nullable)(BOOL needChange))changeBlock {
    if (!self.streamerPresenter.pushStreamStarted) {
        [PLVLSUtils showToastWithMessage:@"请先上课" inView:self.view];
        if (changeBlock) { changeBlock(NO); }
    }else{
        __weak typeof(self) weakSelf = self;
        [PLVLSUtils showAlertWithMessage:@"确认全体下麦？" cancelActionTitle:@"按错了" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
            [weakSelf.streamerPresenter closeAllLinkMicUser];
            [PLVLSUtils showToastWithMessage:@"已全体下麦" inView:weakSelf.view];
            if (changeBlock) { changeBlock(YES); }
        }];
    }
}

- (void)didTapMuteAllUserMicInMemberSheet:(PLVLSMemberSheet *)memberSheet
                                     mute:(BOOL)mute
                              changeBlock:(void(^)(BOOL needChange))changeBlock {
    if (!self.streamerPresenter.pushStreamStarted) {
        [PLVLSUtils showToastWithMessage:@"请先上课" inView:self.view];
        if (changeBlock) { changeBlock(NO); }
    }else{
        NSString * title = mute ? @"确认全体静音？" : @"确认取消全体静音？";
        NSString * toastTitle = mute ? @"已全体静音" : @"已取消全体静音";
        __weak typeof(self) weakSelf = self;
        [PLVLSUtils showAlertWithMessage:title cancelActionTitle:@"按错了" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
            [weakSelf.streamerPresenter muteAllLinkMicUserMic:mute];
            [PLVLSUtils showToastWithMessage:toastTitle inView:weakSelf.view];
            if (changeBlock) { changeBlock(YES); }
        }];
    }
}

- (void)banUsersInMemberSheet:(PLVLSMemberSheet *)memberSheet
                       userId:(NSString *)userId
                       banned:(BOOL)banned {
    [self.memberPresenter banUserWithUserId:userId banned:banned];
}

- (void)kickUsersInMemberSheet:(PLVLSMemberSheet *)memberSheet
                        userId:(NSString *)userId {
    [self.memberPresenter removeUserWithUserId:userId];
}

#pragma mark - PLVSDocumentAreaView Delegate

- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView openBrush:(BOOL)isOpen {
    self.chatroomAreaView.hidden = isOpen; // 打开画笔隐藏聊天区域
}

- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView changeFullScreen:(BOOL)isFullScreen {
    self.fullscreen = isFullScreen;
    [self documentFullscreen:self.fullscreen];
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString { // 登陆成功
    // 登陆成功
    [self.streamerPresenter joinRTCChannel];
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin ||
        error.code == PLVSocketLoginErrorCodeKick) &&
        error.localizedDescription) {
        [PLVLSUtils showAlertWithMessage:error.localizedDescription cancelActionTitle:@"确定" cancelActionBlock:^{
            [self logout];
        } confirmActionTitle:nil confirmActionBlock:nil];
    }
}

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([subEvent isEqualToString:@"CLOSEROOM"]) { // admin closes or opens the chatroom
        [self closeRoomEvent:jsonDict];
    }
}

- (void)socketMananger_didConnectStatusChange:(PLVSocketConnectStatus)connectStatus {
    if (connectStatus == PLVSocketConnectStatusReconnect) {
        self.socketReconnecting = YES;
        plv_dispatch_main_async_safe(^{
            [PLVLSUtils showToastWithMessage:@"聊天室重连中" inView:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVLSUtils showToastWithMessage:@"聊天室重连成功" inView:self.view];
            })
        }
    }
}

#pragma mark PLVMemberPresenterDelegate

- (void)userListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    [_memberSheet updateUserList:[self.memberPresenter userList] userCount:self.memberPresenter.userCount];
}

- (NSArray *)currentOnlineUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter{
    return self.streamerPresenter.onlineUserArray;
}

#pragma mark - PLVStreamerPresenterDelegate

/// ‘房间加入状态’ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRtcRoomJoinStatus:(PLVStreamerPresenterRoomJoinStatus)currentRtcRoomJoinStatus inRTCRoomChanged:(BOOL)inRTCRoomChanged inRTCRoom:(BOOL)inRTCRoom{
    if (inRTCRoomChanged) {
        if (self.viewerType == PLVRoomUserTypeGuest) {
            if (inRTCRoom) {
                [self startClass:nil];
            }else{
                [self finishClass];
            }
        }
    }
}

/// ‘网络状态’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter networkQualityDidChanged:(PLVBLinkMicNetworkQuality)networkQuality{
    PLVLSStatusBarNetworkQuality statusBarNetworkQuality = (PLVLSStatusBarNetworkQuality) networkQuality;
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
        self.statusAreaView.netState = statusBarNetworkQuality;
    }
}

/// ’等待连麦用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicWaitUserListRefresh:(NSArray <PLVLinkMicWaitUser *>*)waitUserArray newWaitUserAdded:(BOOL)newWaitUserAdded{
    if (newWaitUserAdded) {
        [self.statusAreaView receivedNewJoinLinkMicRequest];
    }
    [self.memberPresenter refreshUserListWithLinkMicWaitUserArray:waitUserArray];
}

/// ’RTC房间在线用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray <PLVLinkMicOnlineUser *>*)onlineUserArray{
    [self.linkMicAreaView reloadLinkMicUserWindows];
    [self.memberPresenter refreshUserListWithLinkMicOnlineUserArray:onlineUserArray];
}

/// ‘是否推流已开始’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter pushStreamStartedDidChanged:(BOOL)pushStreamStarted{
}

/// ’已有效推流时长‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentPushStreamValidDuration:(NSTimeInterval)pushStreamValidDuration{
    self.statusAreaView.duration = pushStreamValidDuration;
}

/// 当前 ’单次重连时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentReconnectingThisTimeDuration:(NSInteger)reconnectingThisTimeDuration{
    if (reconnectingThisTimeDuration == 20) {
        [PLVLSUtils showAlertWithMessage:@"网络断开，已停止直播，请更换网络后重试" cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:nil confirmActionBlock:nil];
    }
}

/// 当前远端 ’已推流时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRemotePushDuration:(NSTimeInterval)currentRemotePushDuration{
    self.statusAreaView.duration = currentRemotePushDuration;
}

/// sessionId 场次Id发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter sessionIdDidChanged:(NSString *)sessionId{
    [PLVRoomDataManager sharedManager].roomData.sessionId = sessionId;
}

/// ‘是否上课已开始’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter classStartedDidChanged:(BOOL)classStarted startClassInfoDict:(NSDictionary *)startClassInfoDict{
    [PLVRoomDataManager sharedManager].roomData.startTimestamp = presenter.startPushStreamTimestamp;
    [PLVRoomDataManager sharedManager].roomData.liveDuration = presenter.pushStreamValidDuration;
    if (classStarted) {
        [self startClass:startClassInfoDict];
    }
}

/// 已挂断 某位远端用户的连麦 事件回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser{
    NSString * nickName = onlineUser.nickname;
    if (nickName.length > 12) {
        nickName = [NSString stringWithFormat:@"%@...",[nickName substringToIndex:12]];
    }
    NSString * message = [NSString stringWithFormat:@"已挂断%@的连麦",nickName];
    [PLVLSUtils showToastWithMessage:message inView:self.view];
}

/// 需向外部获取文档的当前信息 事件回调
- (NSDictionary *)plvStreamerPresenterGetDocumentCurrentInfoDict:(PLVStreamerPresenter *)presenter{
    return [self.documentAreaView getCurrentDocumentInfoDict];
}

/// 本地用户的 ’麦克风开关状态‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserMicOpenChanged:(BOOL)currentMicOpen{
    [self.chatroomAreaView microphoneButtonOpen:currentMicOpen];
    [PLVLSUtils showToastWithMessage:(currentMicOpen ? @"已开启麦克风" : @"已关闭麦克风") inView:self.view];
}

/// 本地用户的 ’摄像头是否应该显示值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraShouldShowChanged:(BOOL)currentCameraShouldShow{
    [self.chatroomAreaView cameraButtonOpen:currentCameraShouldShow];
    [PLVLSUtils showToastWithMessage:(currentCameraShouldShow ? @"已开启摄像头" : @"已关闭摄像头") inView:self.view];
}

/// 本地用户的 ’摄像头前后置状态值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraFrontChanged:(BOOL)currentCameraFront{
    [self.chatroomAreaView cameraSwitchButtonFront:currentCameraFront];
    [PLVLSUtils showToastWithMessage:(currentCameraFront ? @"摄像头已前置" : @"摄像头已后置") inView:self.view];
}

/// 推流管理器 ‘发生错误’ 回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didOccurError:(NSError *)error fullErrorCode:(NSString *)fullErrorCodeString {
    NSString * message = @"";
    if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedEmitFailed) {
        message = @"上课错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedNetError){
        message = @"推流请求错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_UpdateRTCTokenFailedNetError){
        message = @"更新Token错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_UnknownError){
        message = @"未知错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_NoError){
        message = @"错误";
    }
    message = [message stringByAppendingFormat:@" code:%@",fullErrorCodeString];
        
    [PLVLSUtils showToastWithMessage:message inView:self.view];
}

#pragma mark - PLVLSLinkMicAreaViewDelegate
- (NSArray *)plvLSLinkMicAreaViewGetCurrentUserModelArray:(PLVLSLinkMicAreaView *)linkMicAreaView{
    return self.streamerPresenter.onlineUserArray;
}

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
- (NSInteger)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock{
    return [self.streamerPresenter findOnlineUserModelIndexWithFiltrateBlock:filtrateBlockBlock];
}

/// 连麦窗口列表视图 需要根据下标值获取对应用户
- (PLVLinkMicOnlineUser *)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex{
    return [self.streamerPresenter getOnlineUserModelFromOnlineUserArrayWithIndex:targetIndex];
}


@end
