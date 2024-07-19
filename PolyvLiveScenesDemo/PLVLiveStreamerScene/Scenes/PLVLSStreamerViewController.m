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
#import "PLVMultiLanguageManager.h"

// UI
#import "PLVLSChannelInfoSheet.h"
#import "PLVLSResolutionSheet.h"
#import "PLVLSStatusAreaView.h"
#import "PLVLSDocumentAreaView.h"
#import "PLVLSCountDownView.h"
#import "PLVLSChatroomAreaView.h"
#import "PLVLSMemberSheet.h"
#import "PLVLSLinkMicAreaView.h"
#import "PLVLSBeautySheet.h"
#import "PLVLSMoreInfoSheet.h"
#import "PLVShareLiveSheet.h"
#import "PLVLSBadNetworkTipsView.h"
#import "PLVLSSwitchSuccessTipsView.h"
#import "PLVLSBadNetworkSwitchSheet.h"
#import "PLVLSMixLayoutSheet.h"
#import "PLVLSLinkMicSettingSheet.h"
#import "PLVLSLinkMicUpdateTipsView.h"
#import "PLVStreamerPopoverView.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"
#import "PLVLSChatroomViewModel.h"
#import "PLVStreamerPresenter.h"
#import "PLVMemberPresenter.h"
#import "PLVBeautyViewModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const kPLVLSSettingMixLayoutKey = @"kPLVLSSettingMixLayoutKey";

@interface PLVLSStreamerViewController ()<
PLVSocketManagerProtocol,
PLVRoomDataManagerProtocol,
PLVLSResolutionSheetDelegate,
PLVLSStatusAreaViewProtocol,
PLVLSDocumentAreaViewDelegate,
PLVLSChatroomAreaViewProtocol,
PLVLSMemberSheetDelegate,
PLVLSLinkMicAreaViewDelegate,
PLVStreamerPresenterDelegate,
PLVMemberPresenterDelegate,
PLVLSBeautySheetDelegate,
PLVLSMoreInfoSheetDelegate,
PLVShareLiveSheetDelegate,
PLVLSBadNetworkSwitchSheetDelegate,
PLVLSMixLayoutSheetDelegate,
PLVLSLinkMicSettingSheetDelegate
>

#pragma mark 功能
@property (nonatomic, strong) PLVStreamerPresenter *streamerPresenter;
@property (nonatomic, strong) PLVMemberPresenter *memberPresenter;
@property (nonatomic, copy) void (^tryStartClassBlock) (void); // 用于无法立刻’尝试开始上课‘，后续需自动’尝试开始‘上课的场景；执行优先级低于 [tryResumeClassBlock]
@property (nonatomic, copy) void (^tryResumeClassBlock) (void); // 用于在合适的时机，进行’恢复直播‘处理；执行优先级高于 [tryStartClassBlock]

#pragma mark UI
@property (nonatomic, assign, getter=isFullscreen) BOOL fullscreen; // 是否处于文档区域全屏状态，默认为NO
@property (nonatomic, strong) PLVLSStatusAreaView *statusAreaView;  // 顶部状态栏区域
@property (nonatomic, strong) PLVLSDocumentAreaView *documentAreaView;   // 左侧白板&PPT区域
@property (nonatomic, strong) PLVLSChatroomAreaView *chatroomAreaView;   // 左下角聊天室区域
@property (nonatomic, strong) PLVLSLinkMicAreaView *linkMicAreaView;
@property (nonatomic, strong) PLVLSChannelInfoSheet *channelInfoSheet;
@property (nonatomic, strong) PLVLSResolutionSheet *settingSheet;
@property (nonatomic, strong) PLVLSMemberSheet *memberSheet;
@property (nonatomic, strong) PLVLSCountDownView *coutBackView; // 开始上课时的倒数蒙层
@property (nonatomic, strong) PLVLSBeautySheet *beautySheet; // 美颜设置弹层
@property (nonatomic, strong) PLVLSMoreInfoSheet *moreInfoSheet; // 更多弹层
@property (nonatomic, strong) PLVShareLiveSheet *shareLiveSheet; // 分享直播弹层
@property (nonatomic, strong) PLVLSBadNetworkSwitchSheet *badNetworkSwitchSheet; // 弱网处理弹层
@property (nonatomic, strong) PLVLSBadNetworkTipsView *badNetworkTipsView; // 网络较差提示切换【流畅模式】气泡
@property (nonatomic, strong) PLVLSSwitchSuccessTipsView *switchSuccessTipsView; // 切换【流畅模式】成功提示气泡
@property (nonatomic, strong) PLVLSMixLayoutSheet *mixLayoutSheet; // 混流布局弹层
@property (nonatomic, strong) PLVLSLinkMicSettingSheet *linkMicSettingSheet; // 连麦设置弹层
@property (nonatomic, strong) PLVLSLinkMicUpdateTipsView *linkMicUpdateTipsView;
@property (nonatomic, strong) PLVStreamerPopoverView *popoverView; // 浮动区域

#pragma mark 数据
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中
@property (nonatomic, assign, readonly) BOOL isOnlyAudio; // 当前频道是否为音频模式
@property (nonatomic, assign) NSTimeInterval showMicTipsTimeInterval; // 显示'请打开麦克风提示'时的时间戳
@property (nonatomic, assign) BOOL chatroomAreaViewOriginalShow; // chatroomAreaView原本的显示状态
@property (nonatomic, assign) BOOL allowRaiseHand; // 缓存上课前的举手按钮，默认是NO
@property (nonatomic, assign) PLVChannelLinkMicMediaType linkMicMediaTypeCache; // 缓存上课前的连麦类型，

@end

@implementation PLVLSStreamerViewController

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置对语言场景
        [[PLVMultiLanguageManager sharedManager] setupLocalizedLiveScene:PLVMultiLanguageLiveSceneLS channelId:[PLVRoomDataManager sharedManager].roomData.channelId language:nil];
        
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // 启动聊天室管理器
        [[PLVLSChatroomViewModel sharedViewModel] setup];
        
        // 开启提醒消息，请求提醒消息历史记录
        if ([PLVRoomDataManager sharedManager].roomData.menuInfo.remindEnabled) {
            [[PLVLSChatroomViewModel sharedViewModel] loadRemindHistory];
        }
        
        // 监听socket消息
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [PLVLSUtils sharedUtils].homeVC = self;
        
        self.linkMicMediaTypeCache = [PLVRoomDataManager sharedManager].roomData.defaultChannelLinkMicMediaType;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:1];
    
    [self setupUI];
    [self setupModule];
    [self preapareStartClass];
    if ([PLVRoomDataManager sharedManager].roomData .linkmicNewStrategyEnabled && self.viewerType == PLVRoomUserTypeTeacher && [PLVRoomDataManager sharedManager].roomData.interactNumLimit > 0) {
        self.linkMicUpdateTipsView.hidden = NO;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self getEdgeInset];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;

    // 状态栏高度固定44，宽度需减去两倍左右安全区域
    CGFloat statusAreaViewTop = isPad ? PLVLSUtils.safeTopPad : 0;
    self.statusAreaView.frame = CGRectMake(PLVLSUtils.safeSidePad, statusAreaViewTop, screenSize.width - PLVLSUtils.safeSidePad * 2, 44);
    
    // 文档区域宽高默认16:9，剩余的空间给推流区域，推流区域的宽度必须大于138，如果小于138，减少文档区域的宽度
    // 文档区域与推流区域间距为8
    CGFloat ducomentViewHeight = screenSize.height - CGRectGetMaxY(self.statusAreaView.frame) - PLVLSUtils.safeBottomPad;
    CGFloat documentAreaViewWidth = ducomentViewHeight * 16.0 / 9.0;
    CGFloat linkMicAreaViewLeftPadding = 8;
    CGFloat linkMicAreaViewWidth = screenSize.width - PLVLSUtils.safeSidePad * 2 - documentAreaViewWidth - linkMicAreaViewLeftPadding;
    CGFloat linkMicAreaViewMinWidth = isPad ? 160 : 138;
    if (linkMicAreaViewWidth < linkMicAreaViewMinWidth) {
        linkMicAreaViewWidth = linkMicAreaViewMinWidth;
        documentAreaViewWidth = screenSize.width - PLVLSUtils.safeSidePad * 2 - linkMicAreaViewWidth - linkMicAreaViewLeftPadding;
    }
    self.documentAreaView.frame = CGRectMake(PLVLSUtils.safeSidePad, CGRectGetMaxY(self.statusAreaView.frame), documentAreaViewWidth, ducomentViewHeight);
    
    self.linkMicAreaView.frame = CGRectMake(CGRectGetMaxX(self.documentAreaView.frame) + linkMicAreaViewLeftPadding, CGRectGetMaxY(self.statusAreaView.frame), linkMicAreaViewWidth, ducomentViewHeight);
        
    // 设置聊天室宽高
    CGFloat chatroomAreaViewWidth = documentAreaViewWidth - 32 - linkMicAreaViewLeftPadding * 2; // 适配小屏输入框无法响应点击事件，chatroomAreaView内部适配聊天宽度
    CGFloat chatroomAreaViewHeigh = [UIScreen mainScreen].bounds.size.height * (isPad ? 0.28 : 0.42) + 44;
    
    self.chatroomAreaView.frame = CGRectMake(PLVLSUtils.safeSidePad, screenSize.height - PLVLSUtils.safeBottomPad - chatroomAreaViewHeigh, chatroomAreaViewWidth, chatroomAreaViewHeigh);
    CGRect buttonRelativeFrame = [self.statusAreaView convertRect:self.statusAreaView.linkmicButton.frame toView:self.view];
    self.linkMicUpdateTipsView.frame = CGRectMake(CGRectGetMidX(buttonRelativeFrame) - self.linkMicUpdateTipsView.viewSize.width / 2, CGRectGetMaxY(buttonRelativeFrame), self.linkMicUpdateTipsView.viewSize.width,  self.linkMicUpdateTipsView.viewSize.height);
    
    if (self.isFullscreen) {
        self.documentAreaView.frame = self.view.bounds;
    }
    
    if (_channelInfoSheet) {
        CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.75;
        [_channelInfoSheet refreshWithSheetHeight:sheetHeight];
    }
    
    if (_memberSheet) {
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat scale = isPad ? 0.43 : 0.52;
        [_memberSheet refreshWithSheetWidth:screenWidth * scale];
    }
    
    if (_settingSheet) {
        CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
        [_settingSheet refreshWithSheetWidth:sheetWidth];
    }
    
    if (_coutBackView) {
        _coutBackView.frame = self.view.bounds;
    }
    
    if (_badNetworkTipsView && _badNetworkTipsView.showing) {
        CGFloat width = self.badNetworkTipsView.tipsViewWidth;
        CGFloat height = kPLVLSBadNetworkTipsViewHeight;
        self.badNetworkTipsView.frame = CGRectMake(self.documentAreaView.center.x - width/2.0, self.documentAreaView.frame.origin.y + 10, width, height);
        [self.view insertSubview:self.badNetworkTipsView aboveSubview:self.documentAreaView];
    } else if (_switchSuccessTipsView && _switchSuccessTipsView.showing) {
        CGFloat width = self.switchSuccessTipsView.tipsViewWidth;
        CGFloat height = kPLVLSSwitchSuccessTipsViewHeight;
        self.switchSuccessTipsView.frame = CGRectMake(self.documentAreaView.center.x - width/2.0, self.documentAreaView.frame.origin.y + 10, width, height);
        [self.view insertSubview:self.switchSuccessTipsView aboveSubview:self.documentAreaView];
    }
    
    if(_mixLayoutSheet) {
        CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
        [_mixLayoutSheet refreshWithSheetWidth:sheetWidth];
    }
    self.popoverView.frame = self.view.bounds;
}

#pragma mark - Initialize

- (void)setupUI {
    // 非全屏状态下，documentAreaView 在最底部，需最先添加进去
    [self.view addSubview:self.documentAreaView];
    [self.view addSubview:self.linkMicAreaView];
    [self.view addSubview:self.chatroomAreaView];
    // 非全屏状态下，顶部 statusAreaView 必须在最顶端，需最后添加进去
    [self.view addSubview:self.statusAreaView];
    [self.view addSubview:self.linkMicUpdateTipsView];
    // 屏蔽签到功能 
    // [self.view addSubview:self.popoverView];

    // 初始化
    [self.settingSheet initView]; /// 仅用于初始化
    [self.moreInfoSheet initView];
    [self.mixLayoutSheet initView];
    
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
    self.streamerPresenter.cameraDefaultOpen = self.isOnlyAudio ? NO : YES;
    self.streamerPresenter.cameraDefaultFront = YES;
    
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
        NSString *streamQualityLevel = self.settingSheet.defaultQualityLevel;
        [self.streamerPresenter setupStreamQualityLevel:streamQualityLevel];
    } else {
        PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:self.settingSheet.resolution];
        [self.streamerPresenter setupStreamQuality:streamQuality];
    }
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [self.streamerPresenter setLinkMicNewStrategyEnabled:roomData.linkmicNewStrategyEnabled interactNumLimit:roomData.interactNumLimit defaultChannelLinkMicMediaType:roomData.defaultChannelLinkMicMediaType];
    [self.streamerPresenter setDefaultVideoQosPreference:roomData.pushQualityPreference];
    PLVRTCStreamerMixLayoutType type = [PLVRoomData streamerMixLayoutTypeWithMixLayoutType:[self getLocalMixLayoutType]];
    [self.streamerPresenter setupMixLayoutType:type];
    
    self.memberPresenter = [[PLVMemberPresenter alloc] init];
    self.memberPresenter.delegate = self;
    [self.memberPresenter start];// 开始获取成员列表数据并开启自动更新
    
    // 初始化美颜
    [self.streamerPresenter initBeauty];
}

- (void)getEdgeInset {
    if (PLVLSUtils.safeBottomPad > 0 && PLVLSUtils.safeSidePad > 0 && PLVLSUtils.safeTopPad > 0) {
        return;
    }
    
    // 在 -viewWillLayoutSubviews 方法里设置 UI 是为了正确获取安全区域
    CGFloat safeSidePad = 0;
    CGFloat safeBottomPad = 0;
    CGFloat safeTopPad = 0;
    if (@available(iOS 11, *)) {
        safeSidePad = MAX(self.view.safeAreaInsets.left, self.view.safeAreaInsets.right);
        safeBottomPad = self.view.safeAreaInsets.bottom;
        safeTopPad = self.view.safeAreaInsets.top;
    }
    PLVLSUtils.safeSidePad = safeSidePad < 16 ? 16 : safeSidePad;
    PLVLSUtils.safeBottomPad = safeBottomPad < 10 ? 10 : safeBottomPad;
    PLVLSUtils.safeTopPad = safeTopPad < 10 ? 10 : safeTopPad;
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

- (PLVLSResolutionSheet *)settingSheet {
    if (!_settingSheet) {
        CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
        _settingSheet = [[PLVLSResolutionSheet alloc] initWithSheetWidth:sheetWidth];
        _settingSheet.delegate = self;
    }
    return _settingSheet;
}

- (PLVLSMemberSheet *)memberSheet {
    if (!_memberSheet) {
        _memberSheet = [[PLVLSMemberSheet alloc] initWithUserList:[self.memberPresenter userList] userCount:self.memberPresenter.userCount];
        _memberSheet.delegate = self;
        __weak typeof(self) weakSelf = self;
        [_memberSheet setSideSheetDismissBlock:^{
            [weakSelf.statusAreaView changeMemberButtonSelectedState:NO];
        }];
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

- (BOOL)isOnlyAudio {
    return [PLVRoomDataManager sharedManager].roomData.isOnlyAudio;
}

- (PLVLSBeautySheet *)beautySheet {
    if (!_beautySheet) {
        _beautySheet = [[PLVLSBeautySheet alloc] initWithSheetHeight:172 showSlider:NO];
        _beautySheet.delegate = self;
    }
    return _beautySheet;
}

- (PLVLSMoreInfoSheet *)moreInfoSheet {
    if (!_moreInfoSheet) {
        CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
        _moreInfoSheet = [[PLVLSMoreInfoSheet alloc] initWithSheetWidth:sheetWidth];
        _moreInfoSheet.delegate = self;
    }
    return _moreInfoSheet;
}

- (PLVShareLiveSheet *)shareLiveSheet {
    if (!_shareLiveSheet) {
        _shareLiveSheet = [[PLVShareLiveSheet alloc] initWithType:PLVShareLiveSheetSceneTypeLS];
        _shareLiveSheet.delegate = self;
    }
    return _shareLiveSheet;
}

- (PLVLSBadNetworkTipsView *)badNetworkTipsView {
    if (!_badNetworkTipsView) {
        _badNetworkTipsView = [[PLVLSBadNetworkTipsView alloc] init];
        __weak typeof(self) weakSelf = self;
        [_badNetworkTipsView setSwitchButtonActionBlock:^{
            [weakSelf.streamerPresenter setupVideoQosPreference:PLVBRTCVideoQosPreferenceSmooth];
//            [weakSelf.switchSuccessTipsView showAtView:weakSelf.view aboveSubview:weakSelf.documentAreaView];
            [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"已切换到流畅模式") inView:weakSelf.view];
        }];
    }
    return _badNetworkTipsView;
}

- (PLVLSSwitchSuccessTipsView *)switchSuccessTipsView {
    if (!_switchSuccessTipsView) {
        _switchSuccessTipsView = [[PLVLSSwitchSuccessTipsView alloc] init];
    }
    return _switchSuccessTipsView;
}

- (PLVLSBadNetworkSwitchSheet *)badNetworkSwitchSheet {
    if (!_badNetworkSwitchSheet) {
        _badNetworkSwitchSheet = [[PLVLSBadNetworkSwitchSheet alloc] init];
        _badNetworkSwitchSheet.delegate = self;
    }
    return _badNetworkSwitchSheet;
}

- (PLVLSMixLayoutSheet *)mixLayoutSheet {
    if (!_mixLayoutSheet) {
        CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
        _mixLayoutSheet = [[PLVLSMixLayoutSheet alloc] initWithSheetWidth:sheetWidth];
        [_mixLayoutSheet setupMixLayoutTypeOptionsWithCurrentMixLayoutType:[self getLocalMixLayoutType]];
        _mixLayoutSheet.delegate = self;
    }
    return _mixLayoutSheet;
}

- (PLVLSLinkMicSettingSheet *)linkMicSettingSheet {
    if (!_linkMicSettingSheet) {
        CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
        _linkMicSettingSheet = [[PLVLSLinkMicSettingSheet alloc] initWithSheetWidth:sheetWidth];
        [_linkMicSettingSheet updateLinkMicType:[PLVRoomDataManager sharedManager].roomData.defaultChannelLinkMicMediaType != PLVChannelLinkMicMediaType_Video];
        _linkMicSettingSheet.delegate = self;
    }
    return _linkMicSettingSheet;
}

- (PLVLSLinkMicUpdateTipsView *)linkMicUpdateTipsView {
    if (!_linkMicUpdateTipsView) {
        _linkMicUpdateTipsView = [[PLVLSLinkMicUpdateTipsView alloc] init];
        _linkMicUpdateTipsView.hidden = YES;
    }
    return _linkMicUpdateTipsView;
}

- (PLVStreamerPopoverView *)popoverView {
    if (!_popoverView) {
        _popoverView = [[PLVStreamerPopoverView alloc] init];
    }
    return _popoverView;
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
    [self.streamerPresenter enableBeautyProcess:NO]; // 关闭美颜管理器
    [[PLVBeautyViewModel sharedViewModel] clear]; // 美颜资源释放、状态位清零
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.streamerPresenter.classStarted ? 0.5 : 0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[PLVSocketManager sharedManager] logout];
    });
    
    [self.chatroomAreaView logout];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 保存当前选择的混流布局到本地
- (void)saveSelectedMixLayoutType:(PLVMixLayoutType)mixLayoutType {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)mixLayoutType] forKey:kPLVLSSettingMixLayoutKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/// 读取本地混流布局配置
- (PLVMixLayoutType)getLocalMixLayoutType {
    NSString *saveMixLayoutTypeString = [[NSUserDefaults standardUserDefaults] objectForKey:kPLVLSSettingMixLayoutKey];
    if ([PLVFdUtil checkStringUseable:saveMixLayoutTypeString]) {
        PLVMixLayoutType saveMixLayout = saveMixLayoutTypeString.integerValue;
        if (saveMixLayout >= 1 && saveMixLayout <=3) {
            return saveMixLayout;
        }
    }
    return PLVMixLayoutType_MainSpeaker; // 默认混流布局为主讲模式
}

#pragma mark - Start Class

- (void)preapareStartClass {
    __weak typeof(self) weakSelf = self;
    [self.streamerPresenter prepareLocalMicCameraPreviewCompletion:^(BOOL granted, BOOL prepareSuccess) {
        if (prepareSuccess) {
            [weakSelf.streamerPresenter setupLocalPreviewWithCanvaView:nil setupCompletion:^(BOOL setupResult) {
                if (setupResult) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(700 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                        [weakSelf.streamerPresenter startLocalMicCameraPreviewByDefault];
                    });
                    
                    /// 确认是否需要‘恢复直播’
                    [weakSelf tryResumeClass];
                    
                    // 开启RTC图像数据回调给美颜处理
                    [weakSelf.streamerPresenter enableBeautyProcess:[PLVBeautyViewModel sharedViewModel].beautyIsOpen];
                }
            }];
        }
   
        if (!granted) {
            [PLVLSUtils showAlertWithTitle:PLVLocalizedString(@"音视频权限申请")
                                   message:PLVLocalizedString(@"请前往“设置-隐私”开启权限")
                         cancelActionTitle:PLVLocalizedString(@"取消")
                         cancelActionBlock:nil
                        confirmActionTitle:PLVLocalizedString(@"前往设置") confirmActionBlock:^{
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
            }];
            [weakSelf.chatroomAreaView microphoneButtonOpen:NO];
            [weakSelf.chatroomAreaView cameraButtonOpen:NO];
        }
        weakSelf.memberSheet.mediaGranted = granted;
    }];
}

- (void)tryResumeClass {
    /// 判断是否需要‘恢复直播’
    if ([PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            /// 弹出提示
            [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"检测到之前异常退出，是否恢复直播") cancelActionTitle:PLVLocalizedString(@"结束直播") cancelActionBlock:^{
                /// 重置值、结束服务器中该频道上课状态
                [PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving = NO;
                [weakSelf.streamerPresenter finishClass];
            } confirmActionTitle:PLVLocalizedString(@"恢复直播") confirmActionBlock:^{
                /// 加入RTC房间、配置加入成功后的自动处理逻辑
                [weakSelf.streamerPresenter joinRTCChannel];
                weakSelf.tryResumeClassBlock = ^{
                    [weakSelf tryStartClassRetryCount:0 callCompletion:nil];
                    [weakSelf.documentAreaView synchronizeDocumentData];
                };
            }];
        })
    }
}

/// 尝试开始上课
///
/// @note 若上课条件不符，将可能上课失败；并根据已重试次数，进行自动重试；
///
/// @param retryCount 已重试次数 (传值 0 表示首次调用)
/// @param callCompletion 调用结束回调 (负责告知最终是否 ‘尝试上课’ 成功)
- (void)tryStartClassRetryCount:(NSInteger)retryCount callCompletion:(nullable void (^)(BOOL tryStartClassSuccess))callCompletion{
    BOOL needRetry = NO;
    __weak typeof(self) weakSelf = self;
    if (self.streamerPresenter.micCameraGranted &&
        self.streamerPresenter.inRTCRoom) {
        if (self.streamerPresenter.networkQuality == PLVBLinkMicNetworkQualityDown) {
            needRetry = YES;
        }else{
            /// 开始上课倒数
            [self.coutBackView startCountDownOnView:self.view];
            if (callCompletion) { callCompletion(YES); }
        }
    }else{
        if (!self.streamerPresenter.micCameraGranted) {
            /// 重新‘准备上课’
            [self preapareStartClass];
        } else if(!self.streamerPresenter.inRTCRoom) {
            /// 重新‘加入RTC房间‘
            [self.streamerPresenter joinRTCChannel];
            self.tryStartClassBlock = ^{
                [weakSelf tryStartClassRetryCount:0 callCompletion:nil];
            };
        }
        if (callCompletion) { callCompletion(NO); }
    }
        
    if (needRetry) {
        /// 需要重试
        if (retryCount >= 0 && retryCount < 3) {
            retryCount++;
            NSInteger waitTime = (1.5 * retryCount);
            [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"处理中...") inView:self.view afterDelay:waitTime];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf tryStartClassRetryCount:retryCount callCompletion:callCompletion];
            });
        }else{
            [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"网络当前不佳，请稍后再试") cancelActionTitle:PLVLocalizedString(@"知道了") cancelActionBlock:nil confirmActionTitle:nil confirmActionBlock:nil];
            if (callCompletion) { callCompletion(NO); }
        }
    }
}

- (void)startClass:(NSDictionary *)startClassInfoDict {
    [self.statusAreaView startPushButtonEnable:YES];
    [self.statusAreaView startClass:YES];
    [self.documentAreaView startClass:startClassInfoDict];
    [self.memberSheet startClass:YES];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    __weak typeof(self) weakSelf = self;
    if (roomData.linkmicNewStrategyEnabled && self.viewerType == PLVRoomUserTypeTeacher && roomData.interactNumLimit > 0) {
        // 允许邀请连麦
        [self.memberSheet enableAudioVideoLinkMic:YES];
        [self.streamerPresenter changeLinkMicMediaType:self.linkMicMediaTypeCache != PLVChannelLinkMicMediaType_Video allowRaiseHand:self.allowRaiseHand emitCompleteBlock:^(BOOL emitSuccess) {
            if (!emitSuccess) {
                [weakSelf.statusAreaView changeLinkmicButtonSelectedState:NO];
            }
            [self.linkMicSettingSheet updateLinkMicType:weakSelf.streamerPresenter.channelLinkMicMediaType != PLVChannelLinkMicMediaType_Video];
            [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
        }];
    }
}

- (void)finishClass {
    [self.statusAreaView startPushButtonEnable:YES];
    [self.statusAreaView startClass:NO];
    [self.streamerPresenter finishClass];
    [self.documentAreaView finishClass];
    [self.memberSheet startClass:NO];
    [self.memberSheet enableAudioVideoLinkMic:NO];
    
    if (self.viewerType == PLVSocketUserTypeGuest) { // 嘉宾登录 下课后重置为未非全屏
        self.fullscreen = NO;
        [self documentFullscreen:self.fullscreen];
        [self.linkMicAreaView finishClass];
    }
}

#pragma mark socket 数据解析

/// 讲师关闭、打开聊天室
- (void)closeRoomEvent:(NSDictionary *)jsonDict {
    NSDictionary *value = PLV_SafeDictionaryForDictKey(jsonDict, @"value");
    BOOL closeRoom = PLV_SafeBoolForDictKey(value, @"closed");
    NSString *string = closeRoom ? PLVLocalizedString(@"聊天室已经关闭") : PLVLocalizedString(@"聊天室已经打开");
    plv_dispatch_main_async_safe(^{
        [PLVLSUtils showToastInHomeVCWithMessage:string];
    })
}

#pragma mark 美颜
- (void)showBeautySheet:(BOOL)show {
    if (![PLVBeautyViewModel sharedViewModel].beautyIsReady) {
        [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"美颜未准备就绪，请退出重新登录")];
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

#pragma mark - PLVRoomDataManager Protocol

- (void)roomDataManager_didMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    // 此时更新频道信息弹层数据不能使用self，会过早触发弹层初始化，导致弹层高度计算错误
    [_channelInfoSheet updateChannelInfoWithData:menuInfo];
}

- (void)roomDataManager_didSipPasswordChanged:(NSString *)sipPassword {
    PLVLiveVideoChannelMenuInfo *menuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    [self.channelInfoSheet updateChannelInfoWithData:menuInfo];
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
    [self.moreInfoSheet showInView:self.view];
}

- (void)statusAreaView_didTapShareButton {
    
}

- (BOOL)statusAreaView_didTapStartPushOrStopPushButton:(BOOL)start {
    __weak typeof(self) weakSelf = self;
    if (start) {
        [self tryStartClassRetryCount:0 callCompletion:^(BOOL tryStartClassSuccess) {
            [weakSelf.statusAreaView startPushButtonEnable:!tryStartClassSuccess];
        }];
        return YES; /// 先行禁用，由 [tryStartClassRetryCount:callCompletion:] 方法Block，进行最终的状态更新
    } else {
        [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"点击下课将结束直播，确认下课吗？") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"下课") confirmActionBlock:^{
            [weakSelf finishClass];
        }];
        return NO;
    }
}

- (BOOL)statusAreaView_didTapVideoLinkMicButton:(BOOL)start{
    if (!self.streamerPresenter.pushStreamStarted) {
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"请先上课再开始连麦") inView:self.view];
        return NO;
    }else{
        if ([PLVRoomDataManager sharedManager].roomData.interactNumLimit == 0) {
            [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"尚未开通，请联系管理员") inView:self.view];
            return NO;
        }
        
        NSString * suceessTitle = start ? PLVLocalizedString(@"已开启视频连麦") : PLVLocalizedString(@"已关闭视频连麦");
        NSString * failTitle = start ? PLVLocalizedString(@"开启视频连麦失败，请稍后再试") : PLVLocalizedString(@"关闭视频连麦失败，请稍后再试");
        __weak typeof(self) weakSelf = self;
        [self.streamerPresenter openVideoLinkMic:start emitCompleteBlock:^(BOOL emitSuccess) {
            plv_dispatch_main_async_safe(^{
                if (emitSuccess) {
                    [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                    [weakSelf.memberSheet enableAudioVideoLinkMic:start];
                    [PLVLSUtils showToastWithMessage:suceessTitle inView:weakSelf.view];
                    [weakSelf.statusAreaView changeLinkmicButtonSelectedState:start];
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
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"请先上课再开始连麦") inView:self.view];
        return NO;
    }else{
        if ([PLVRoomDataManager sharedManager].roomData.interactNumLimit == 0) {
            [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"尚未开通，请联系管理员") inView:self.view];
            return NO;
        }
        
        NSString * suceessTitle = start ? PLVLocalizedString(@"已开启音频连麦") : PLVLocalizedString(@"已关闭音频连麦");
        NSString * failTitle = start ? PLVLocalizedString(@"开启音频连麦失败，请稍后再试") : PLVLocalizedString(@"关闭音频连麦失败，请稍后再试");
        __weak typeof(self) weakSelf = self;
        [self.streamerPresenter openAudioLinkMic:start emitCompleteBlock:^(BOOL emitSuccess) {
            plv_dispatch_main_async_safe(^{
                if (emitSuccess) {
                    [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                    [weakSelf.memberSheet enableAudioVideoLinkMic:start];
                    [PLVLSUtils showToastWithMessage:suceessTitle inView:weakSelf.view];
                    [weakSelf.statusAreaView changeLinkmicButtonSelectedState:start];
                }else{
                    [PLVLSUtils showToastWithMessage:failTitle inView:weakSelf.view];
                }
            })
        }];
        return YES;
    }
}

- (void)statusAreaView_didTapAudienceRaiseHandButton:(BOOL)start {
    if ([PLVRoomDataManager sharedManager].roomData.interactNumLimit == 0) {
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"尚未开通，请联系管理员") inView:self.view];
        return;
    }
    
    if (!self.streamerPresenter.pushStreamStarted) {
        self.allowRaiseHand = start;
        [self.statusAreaView changeLinkmicButtonSelectedState:start];
        return;
    }
    // 开播后再检查开启是否失败
    if ([PLVReachability reachabilityForInternetConnection].currentReachabilityStatus == PLVNotReachable) {
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"当前网络信号弱，开启失败，请检查网络！") inView:self.view];
        return;
    }
    
    if (![PLVRoomDataManager sharedManager].roomData.linkmicNewStrategyEnabled) {
        return;
    }
    
    NSString * suceessTitle = start ? PLVLocalizedString(@"已开启观众连麦") : PLVLocalizedString(@"已关闭观众连麦");
    NSString * failTitle = start ? PLVLocalizedString(@"开启观众连麦失败，请稍后再试") : PLVLocalizedString(@"关闭观众连麦失败，请稍后再试");
    __weak typeof(self) weakSelf = self;
    
    [self.streamerPresenter allowRaiseHand:start emitCompleteBlock:^(BOOL emitSuccess) {
        plv_dispatch_main_async_safe(^{
            if (emitSuccess) {
                [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                [PLVLSUtils showToastWithMessage:suceessTitle inView:weakSelf.view];
                [weakSelf.statusAreaView changeLinkmicButtonSelectedState:start];
                weakSelf.allowRaiseHand = start;
            }else{
                [PLVLSUtils showToastWithMessage:failTitle inView:weakSelf.view];
            }
        })
    }];
}

- (PLVLSStatusBarControls)statusAreaView_selectControlsInDemand{
    if (self.viewerType == PLVRoomUserTypeGuest) {
        PLVChannelLiveStreamState streamState = self.streamerPresenter.currentStreamState;
        PLVLSStatusBarControls barControls;
        if(streamState == PLVChannelLiveStreamState_Live){
            barControls = PLVLSStatusBarControls_ChannelInfo | PLVLSStatusBarControls_TimeLabel | PLVLSStatusBarControls_SignalButton | PLVLSStatusBarControls_MemberButton | PLVLSStatusBarControls_SettingButton | PLVLSStatusBarControls_WhiteboardButton | PLVLSStatusBarControls_DocumentButton;
        }else{
            barControls = PLVLSStatusBarControls_ChannelInfo | PLVLSStatusBarControls_SignalButton | PLVLSStatusBarControls_MemberButton | PLVLSStatusBarControls_SettingButton | PLVLSStatusBarControls_WhiteboardButton | PLVLSStatusBarControls_DocumentButton;
        }
        if ([PLVRoomDataManager sharedManager].roomData.channelGuestManualJoinLinkMic) {
            barControls =  barControls | PLVLSStatusBarControls_LinkmicButton;
        }
        return barControls;
    }
    return PLVLSStatusBarControls_All;
}

- (void)statusAreaView_didRequestJoinLinkMic:(BOOL)requestJoin {
    [self.streamerPresenter.localOnlineUser wantUserRequestJoinLinkMic:requestJoin];
}

- (void)statusAreaView_didTapCloseLinkMicButton {
    [self.streamerPresenter closeLocalUserLinkMicEmitCompleteBlock:nil];
}

#pragma mark - PLVLSResolutionSheetDelegate

- (void)settingSheet_didChangeResolution:(PLVResolutionType)resolution {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:resolution];
    [self.streamerPresenter setupStreamQuality:streamQuality];
}

- (void)settingSheet_didSelectStreamQualityLevel:(NSString *)streamQualityLevel {
    [self.streamerPresenter setupStreamQualityLevel:streamQualityLevel];
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
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"请先上课") inView:self.view];
        if (changeBlock) { changeBlock(NO); }
    }else{
        __weak typeof(self) weakSelf = self;
        [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"确认下麦所有连麦观众吗？？") cancelActionTitle:PLVLocalizedString(@"按错了") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
            BOOL success = [weakSelf.streamerPresenter removeAllAudiences];
            if (success) {
                [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"已下麦观众") inView:weakSelf.view];
            }
            if (changeBlock) { changeBlock(YES); }
        }];
    }
}

- (void)didTapMuteAllUserMicInMemberSheet:(PLVLSMemberSheet *)memberSheet
                                     mute:(BOOL)mute
                              changeBlock:(void(^)(BOOL needChange))changeBlock {
    if (!self.streamerPresenter.pushStreamStarted) {
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"请先上课") inView:self.view];
        if (changeBlock) { changeBlock(NO); }
    }else{
        NSString * title = mute ? PLVLocalizedString(@"确认全员静音？") : PLVLocalizedString(@"确认取消全员静音？");
        NSString * toastTitle = mute ? PLVLocalizedString(@"已全员静音") : PLVLocalizedString(@"已取消全员静音");
        __weak typeof(self) weakSelf = self;
        [PLVLSUtils showAlertWithMessage:title cancelActionTitle:PLVLocalizedString(@"按错了") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
            [weakSelf.streamerPresenter muteAllLinkMicUserMic:mute];
            [PLVLSUtils showToastWithMessage:toastTitle inView:weakSelf.view];
            if (changeBlock) { changeBlock(YES); }
        }];
    }
}

- (void)didTapLinkMicSettingInMemberSheet:(PLVLSMemberSheet *)memberSheet {
    [self.linkMicSettingSheet showInView:self.view];
}

- (void)banUsersInMemberSheet:(PLVLSMemberSheet *)memberSheet
                       userId:(NSString *)userId
                       banned:(BOOL)banned {
    [self.memberPresenter banUserWithUserId:userId banned:banned];
}

- (void)kickUsersInMemberSheet:(PLVLSMemberSheet *)memberSheet
                        userId:(NSString *)userId {
    [self.memberPresenter kickUserWithUserId:userId];
}

- (void)inviteUserJoinLinkMicInMemberSheet:(PLVLSMemberSheet *)memberSheet chatUser:(PLVChatUser *)user {
    PLVLinkMicWaitUser *waitUser = user.waitUser;
    if (!waitUser) {
        waitUser = [PLVLinkMicWaitUser modelWithChatUser:user];
    }
    [self.streamerPresenter inviteRemoteUserJoinLinkMic:waitUser emitCompleteBlock:nil];
}

- (void)sipUserListDidChangedInMemberSheet:(PLVLSMemberSheet *)memberSheet {
    [self.statusAreaView hasNewMember];
}

#pragma mark - PLVSDocumentAreaView Delegate

- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView openBrush:(BOOL)isOpen {
    self.chatroomAreaView.hidden = isOpen; // 打开画笔隐藏聊天区域
}

- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView changeFullScreen:(BOOL)isFullScreen {
    self.fullscreen = isFullScreen;
    [self documentFullscreen:self.fullscreen];
    [self.chatroomAreaView documentChangeFullScreen:self.fullscreen];
}

- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView didShowWhiteboardOrDocument:(BOOL)whiteboard {
    [self.statusAreaView syncSelectedWhiteboardOrDocument:whiteboard];
}

- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView pptView:(UIView *)pptView changePPTPositionToMain:(BOOL)pptToMain syncRemoteUser:(BOOL)needSync {
    if (pptToMain) {
        [self.linkMicAreaView rollbackFirstSiteWindowCellAndExternalView];
    } else {
        [self.linkMicAreaView firstSiteWindowCellExchangeWithExternal:pptView];
    }
    if (needSync) {
        [self.streamerPresenter.localOnlineUser wantChangeUserPPTToMain:pptToMain];
    }
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString { // 登录成功
    if (![PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving) {
        /// 正常场景下（即非异常退出而临时断流的场景）则正常加入RTC房间
        /// 原因：异常退出场景下，加入RTC房间的操作，应延后至用户确认“是否恢复直播”后
        [self.streamerPresenter joinRTCChannel];
    }
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    if (error.code == PLVSocketLoginErrorCodeKick) {
        if (self.streamerPresenter.classStarted) {
            [self finishClass]; // 讲师被踢出后立即结束当前课程
        }
        plv_dispatch_main_async_safe(^{
            [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"当前直播间已被禁止直播") cancelActionTitle:PLVLocalizedString(@"确定") cancelActionBlock:^{
                [weakSelf logout];
            } confirmActionTitle:nil confirmActionBlock:nil];
        })
    } else if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin) &&
        error.localizedDescription) {
        plv_dispatch_main_async_safe(^{
            [PLVLSUtils showAlertWithMessage:error.localizedDescription cancelActionTitle:PLVLocalizedString(@"确定") cancelActionBlock:^{
                [weakSelf logout];
            } confirmActionTitle:nil confirmActionBlock:nil];
        })
        
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
            [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"聊天室重连中") inView:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"聊天室重连成功") inView:self.view];
            })
        }
    }
    self.chatroomAreaView.netState = connectStatus;
}

#pragma mark PLVMemberPresenterDelegate

- (void)userListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    [_memberSheet updateUserList:[self.memberPresenter userList] userCount:self.memberPresenter.userCount onlineCount:self.streamerPresenter.onlineUserArray.count];
}

- (NSArray *)currentOnlineUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter{
    return self.streamerPresenter.onlineUserArray;
}

- (NSArray *)currentWaitUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter{
    return self.streamerPresenter.waitUserArray;
}

#pragma mark - PLVStreamerPresenterDelegate

/// ‘房间加入状态’ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRtcRoomJoinStatus:(PLVStreamerPresenterRoomJoinStatus)currentRtcRoomJoinStatus inRTCRoomChanged:(BOOL)inRTCRoomChanged inRTCRoom:(BOOL)inRTCRoom{
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
                [self startClass:nil];
            }else{
                [self finishClass];
            }
        }
    }
}

/// ‘网络状态’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter networkQualityDidChanged:(PLVBRTCNetworkQuality)networkQuality {
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

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter rtcStatistics:(PLVRTCStatistics *)statistics {
    [self.statusAreaView updateStatistics:statistics];
    
    if (presenter.videoQosPreference == PLVBRTCVideoQosPreferenceClear && statistics.upLoss > 30) {
        [self.badNetworkTipsView showAtView:self.view aboveSubview:self.documentAreaView];
    }
}

/// ’等待连麦用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicWaitUserListRefresh:(NSArray <PLVLinkMicWaitUser *>*)waitUserArray newWaitUserAdded:(BOOL)newWaitUserAdded{
    if (newWaitUserAdded) {
        [self.statusAreaView receivedNewJoinLinkMicRequest];
    }
    [self.memberPresenter refreshUserListWithLinkMicWaitUserArray:waitUserArray];
}

/// ’连麦用户连麦状态‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserLinkMicStatusChanged:(PLVLinkMicUserLinkMicStatus)linkMicStatus{
    if (linkMicStatus == PLVLinkMicUserLinkMicStatus_Inviting) {
        [self.memberSheet dismiss];
        [self.channelInfoSheet dismiss];
        [self.settingSheet dismiss];
        [self.beautySheet dismiss];
        [self.moreInfoSheet dismiss];
        [self.shareLiveSheet dismiss];
        [self.badNetworkSwitchSheet dismiss];
    }
    [self.statusAreaView updateStatusViewLinkMicStatus:linkMicStatus];
    [self.linkMicAreaView updateLocalUserLinkMicStatus:linkMicStatus];
}

/// ’RTC房间在线用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray <PLVLinkMicOnlineUser *>*)onlineUserArray{
    [self.linkMicAreaView reloadLinkMicUserWindows];
    [self.memberPresenter refreshUserListWithLinkMicOnlineUserArray:onlineUserArray];
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
           linkMicOnlineUser:(PLVLinkMicOnlineUser *)onlineUser
                 authSpeaker:(BOOL)authSpeaker {
    if (onlineUser.localUser) {
        NSString *message = authSpeaker ? PLVLocalizedString(@"已授予主讲权限") : PLVLocalizedString(@"已收回主讲权限");
        message = onlineUser.isGuestTransferPermission ? PLVLocalizedString(@"已移交主讲权限") : message;
        [PLVLSUtils showToastWithMessage:message inView:self.view];
        [onlineUser updateUserIsGuestTransferPermission:NO];
        [self.documentAreaView updateDocumentSpeakerAuth:authSpeaker];
        /// 本地嘉宾用户获得主讲权限后，也会获得画笔功能权限
        [self.documentAreaView updateDocumentBrushAuth:authSpeaker];
        [self.statusAreaView updateDocumentSpeakerAuth:authSpeaker];
        [self.memberSheet updateLocalUserSpeakerAuth:authSpeaker];
        if (!authSpeaker) {
            [self.documentAreaView dismissDocument];
        }
    }

    [self.linkMicAreaView updateFirstSiteWindowCellWithUserId:onlineUser.linkMicUserId toFirstSite:onlineUser.isRealMainSpeaker];
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter wantForceCloseOnlineUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser lastFailed:(BOOL)lastFailed {
    if (!lastFailed) {
        [PLVLSUtils showAlertWithTitle:PLVLocalizedString(@"下麦提醒") message:[NSString stringWithFormat:PLVLocalizedString(@"【%@】因网络不稳定，导致下麦失败，可采用强制下麦，用户会自动重新进入房间、也可再次发起正常下麦"), onlineUser.nickname] cancelActionTitle:PLVLocalizedString(@"正常下麦") cancelActionBlock:^{
            [onlineUser wantCloseUserLinkMic];
        }  confirmActionTitle:PLVLocalizedString(@"强制下麦") confirmActionBlock:^{
            [onlineUser wantForceCloseUserLinkMic:!lastFailed];
        }];
    } else {
        [PLVLSUtils showAlertWithTitle:PLVLocalizedString(@"下麦提醒") message:[NSString stringWithFormat:PLVLocalizedString(@"【%@】因网络不稳定，强制下麦失败，可再次尝试 强制下麦"), onlineUser.nickname] cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"强制下麦") confirmActionBlock:^{
            [onlineUser wantForceCloseUserLinkMic:!lastFailed];
        }];
    }
}

/// ‘是否推流已开始’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter pushStreamStartedDidChanged:(BOOL)pushStreamStarted{
}

/// ’已有效推流时长‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentPushStreamValidDuration:(NSTimeInterval)pushStreamValidDuration{
    self.statusAreaView.duration = pushStreamValidDuration;
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        [self.linkMicAreaView updateUsersLinkMicDuration];
    }
}

/// 当前 ’单次重连时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentReconnectingThisTimeDuration:(NSInteger)reconnectingThisTimeDuration{
    if (reconnectingThisTimeDuration == 20) {
        [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"网络断开，已停止直播，请更换网络后重试") cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:nil confirmActionBlock:nil];
    }
}

/// 当前远端 ’已推流时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRemotePushDuration:(NSTimeInterval)currentRemotePushDuration{
    self.statusAreaView.duration = currentRemotePushDuration;
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter updateMixLayoutDidOccurError:(PLVRTCStreamerMixLayoutType)type {
    [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"网络异常，请恢复网络后重试") inView:[PLVLSUtils sharedUtils].homeVC.view];
    PLVMixLayoutType currentType = [PLVRoomData mixLayoutTypeWithStreamerMixLayoutType:type];
    [self.mixLayoutSheet updateMixLayoutType:currentType];
    [self saveSelectedMixLayoutType:currentType];
}
/// sessionId 场次Id发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter sessionIdDidChanged:(NSString *)sessionId{
    [PLVRoomDataManager sharedManager].roomData.sessionId = sessionId;
}

/// ‘是否上课已开始’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter classStartedDidChanged:(BOOL)classStarted startClassInfoDict:(NSDictionary *)startClassInfoDict{
    [PLVRoomDataManager sharedManager].roomData.startTimestamp = presenter.startPushStreamTimestamp;
    [PLVRoomDataManager sharedManager].roomData.liveDuration = presenter.pushStreamValidDuration;
    [[PLVRoomDataManager sharedManager].roomData updateSipInfo];
    if (classStarted) {
        [self startClass:startClassInfoDict];
        self.showMicTipsTimeInterval = 0;
    }
}

/// 已挂断 某位远端用户的连麦 事件回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser{
    NSString * nickName = onlineUser.nickname;
    if (nickName.length > 12) {
        nickName = [NSString stringWithFormat:@"%@...",[nickName substringToIndex:12]];
    }
    NSString * message = [NSString stringWithFormat:PLVLocalizedString(@"已挂断%@的连麦"),nickName];
    [PLVLSUtils showToastWithMessage:message inView:self.view];
}

/// 需向外部获取文档的当前信息 事件回调
- (NSDictionary *)plvStreamerPresenterGetDocumentCurrentInfoDict:(PLVStreamerPresenter *)presenter{
    return [self.documentAreaView getCurrentDocumentInfoDict];
}

/// 本地用户的 ’麦克风开关状态‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserMicOpenChanged:(BOOL)currentMicOpen{
    [self.chatroomAreaView microphoneButtonOpen:currentMicOpen];
    self.showMicTipsTimeInterval = 0;
    [PLVLSUtils showToastWithMessage:(currentMicOpen ? PLVLocalizedString(@"已开启麦克风") : PLVLocalizedString(@"已关闭麦克风")) inView:self.view];
}

/// 本地用户的 ’摄像头是否应该显示值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraShouldShowChanged:(BOOL)currentCameraShouldShow{
    [self.chatroomAreaView cameraButtonOpen:currentCameraShouldShow];
    [PLVLSUtils showToastWithMessage:(currentCameraShouldShow ? PLVLocalizedString(@"已开启摄像头") : PLVLocalizedString(@"已关闭摄像头")) inView:self.view];
}

/// 本地用户的 ’摄像头前后置状态值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraFrontChanged:(BOOL)currentCameraFront{
    if (self.isOnlyAudio) return;
    [self.chatroomAreaView cameraSwitchButtonFront:currentCameraFront];
    [PLVLSUtils showToastWithMessage:(currentCameraFront ? PLVLocalizedString(@"摄像头已前置") : PLVLocalizedString(@"摄像头已后置")) inView:self.view];
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter waitLinkMicUser:(nonnull PLVLinkMicWaitUser *)waitUser joinAnswer:(BOOL)isAccept {
    if (waitUser && !isAccept) {
        NSString *message = [NSString stringWithFormat:PLVLocalizedString(@"%@没有接受你的邀请"), waitUser.nickname];
        [PLVLSUtils showToastWithMessage:message inView:self.view];
    }
}

- (void)plvStreamerPresenterLocalUserLeaveRTCChannelByServerComplete:(PLVStreamerPresenter *)presenter {
    [PLVLSUtils showToastWithCountMessage:PLVLocalizedString(@"网络加载有误，即将重新进入直播间") inView:self.view afterCountdown:3 finishHandler:^{
        if (self.viewerType == PLVSocketUserTypeGuest) {
            if ([self.delegate respondsToSelector:@selector(lsStreamerViewControllerGuestNeedReLogin:)]) {
                [self.delegate lsStreamerViewControllerGuestNeedReLogin:self];
            }
        }
    }];
}

/// 推流管理器 ‘发生错误’ 回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didOccurError:(NSError *)error fullErrorCode:(NSString *)fullErrorCodeString {
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
        [PLVLSUtils showAlertWithMessage:[NSString stringWithFormat:PLVLocalizedString(@"检测到%@，是否结束直播"), message] cancelActionTitle:PLVLocalizedString(@"继续直播") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"结束直播") confirmActionBlock:^{
            [self logout];
        }];
    } else {
        [PLVLSUtils showToastWithMessage:message inView:self.view afterDelay:3];
    }
}

/// 本地用户 麦克风音量大小检测
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserVoiceValue:(CGFloat)localVoiceValue receivedLocalAudibleVoice:(BOOL)voiceAudible {
    if (!self.streamerPresenter.currentMicOpen && localVoiceValue >= 0.4) {
        NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
        if (currentTimeInterval - self.showMicTipsTimeInterval > 180) {
            [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"您已静音，请开启麦克风后发言") inView:self.view];
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
        [PLVLSUtils showToastInHomeVCWithMessage:[NSString stringWithFormat:PLVLocalizedString(@"美颜初始化失败 %d 请重进直播间"), result]];
    }
}

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter beautyProcessDidOccurError:(NSError *)error {
    if (error) {
        NSString *errorDes = error.userInfo[NSLocalizedDescriptionKey];
        [PLVLSUtils showToastInHomeVCWithMessage:errorDes];
    }
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

- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView showFirstSiteWindowCellOnExternal:(UIView *)windowCell {
    [self.documentAreaView displayExternalView:windowCell];
}

- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView rollbackExternalView:(UIView *)externalView {
    [self.documentAreaView displayExternalView:externalView];
}

- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView acceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel {
    [self.streamerPresenter localUserAcceptLinkMicInvitation:accept timeoutCancel:timeoutCancel];
}

- (void)plvLSLinkMicAreaView:(PLVLSLinkMicAreaView *)linkMicAreaView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback {
    [self.streamerPresenter requestLocalUserInviteLinkMicTTLCallback:callback];
}

#pragma mark PLVLSBeautySheetDelegate
- (void)beautySheet:(PLVLSBeautySheet *)beautySheet didChangeOn:(BOOL)on {
    [self.streamerPresenter enableBeautyProcess:on];
}

- (void)beautySheet:(PLVLSBeautySheet *)beautySheet didChangeShow:(BOOL)show {
    if (show) {
        self.chatroomAreaViewOriginalShow = self.chatroomAreaView.hidden;
        self.chatroomAreaView.hidden  = show;
    }else {
        self.chatroomAreaView.hidden  = self.chatroomAreaViewOriginalShow;
    }
    
    [self.documentAreaView documentToolViewShow:show];
}

#pragma mark PLVLSMoreInfoSheetDelegate
- (void)moreInfoSheetDidTapBeautyButton:(PLVLSMoreInfoSheet *)moreInfoSheet {
    if (self.streamerPresenter.currentCameraOpen) {
        [self showBeautySheet:YES];
    } else {
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"请开启摄像头后使用") inView:self.view];
    }
}

- (void)moreInfoSheetDidTapResolutionButton:(PLVLSMoreInfoSheet *)moreInfoSheet {
    [self.settingSheet showInView:self.view];
}

- (void)moreInfoSheetDidTapShareButton:(PLVLSMoreInfoSheet *)moreInfoSheet {
    [self.shareLiveSheet showInView:self.view];
}

- (void)moreInfoSheetDidTapLogoutButton:(PLVLSMoreInfoSheet *)moreInfoSheet {
    [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"确认结束直播吗？") cancelActionTitle:PLVLocalizedString(@"按错了") cancelActionBlock:nil  confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
        [self logout];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)moreInfoSheetDidBadNetworkButton:(PLVLSMoreInfoSheet *)moreInfoSheet {
    [self.badNetworkSwitchSheet showInView:self.view currentVideoQosPreference:self.streamerPresenter.videoQosPreference];
}

- (void)moreInfoSheetDidTapMixLayoutButton:(PLVLSMoreInfoSheet *)moreInfoSheet {
    [self.mixLayoutSheet showInView:self.view];
}

- (void)moreInfoSheetDidTapSignInButton:(PLVLSMoreInfoSheet *)moreInfoSheet {
    [self.popoverView.interactView openInteractViewWithEventName:@"SHOW_SIGN"];
}

#pragma mark PLVShareLiveSheetDelegate

- (void)shareLiveSheetCopyLinkFinished:(PLVShareLiveSheet *)shareLiveSheet {
    [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.view];
}

- (void)shareLiveSheet:(PLVShareLiveSheet *)shareLiveSheet savePictureSuccess:(BOOL)success {
    NSString *message = success ? PLVLocalizedString(@"图片已保存到相册") : PLVLocalizedString(@"保存失败");
    [PLVLSUtils showToastWithMessage:message inView:self.view];
}

#pragma mark PLVLSBadNetworkSwitchSheetDelegate

- (void)switchSheet:(PLVLSBadNetworkSwitchSheet *)switchSheet didChangedVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference {
    if (videoQosPreference == PLVBRTCVideoQosPreferenceSmooth) {
        if (_badNetworkTipsView &&
            _badNetworkTipsView.showing) {
            [_badNetworkTipsView dismiss];
        }
    } else if (videoQosPreference == PLVBRTCVideoQosPreferenceClear) {
           if (_switchSuccessTipsView &&
               _switchSuccessTipsView.showing) {
               [_switchSuccessTipsView dismiss];
           }
    }
    
    [_badNetworkTipsView reset];
    [self.streamerPresenter setupVideoQosPreference:videoQosPreference];
}

#pragma mark  PLVLSMixLayoutSheetDelegate

- (void)mixLayoutSheet_didChangeMixLayoutType:(PLVMixLayoutType)type {
    PLVRTCStreamerMixLayoutType mixLayoutType = [PLVRoomData streamerMixLayoutTypeWithMixLayoutType:type];
    [self.streamerPresenter setupMixLayoutType:mixLayoutType];
    [self saveSelectedMixLayoutType:type];
}

#pragma mark PLVLSLinkMicSettingSheetDelegate

- (void)plvlsLinkMicSettingSheet_wannaChangeLinkMicType:(BOOL)linkMicOnAudio {
    if (!self.streamerPresenter.pushStreamStarted) {
        // 缓存当前的连麦类型并配置，直接改变连麦设置
        self.linkMicMediaTypeCache = linkMicOnAudio ? PLVChannelLinkMicMediaType_Audio : PLVChannelLinkMicMediaType_Video;
        [self.linkMicSettingSheet updateLinkMicType:linkMicOnAudio];
    }
    __weak typeof(self) weakSelf = self;
    
    if (self.streamerPresenter.onlineUserArray.count > 1) {
        [PLVLSUtils showAlertWithTitle2:PLVLocalizedString(@"提示") message:PLVLocalizedString(@"当前有用户在连麦，无法切换连麦方式，若要切换，需将麦上用户全部下麦，确认切换连麦方式吗？") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"切换并下麦所有用户") confirmActionBlock:^{
            [weakSelf.streamerPresenter removeAllAudiences];
            [weakSelf.streamerPresenter changeLinkMicMediaType:linkMicOnAudio allowRaiseHand:weakSelf.streamerPresenter.channelLinkMicOpen emitCompleteBlock:^(BOOL emitSuccess) {
                if (emitSuccess) {
                    [weakSelf.linkMicSettingSheet updateLinkMicType:linkMicOnAudio];
                    [weakSelf.statusAreaView changeLinkmicButtonSelectedState:weakSelf.streamerPresenter.channelLinkMicOpen];
                    [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
                }
            }];
        }];
    } else {
        [weakSelf.streamerPresenter removeAllAudiences];
        [self.streamerPresenter changeLinkMicMediaType:linkMicOnAudio allowRaiseHand:self.streamerPresenter.channelLinkMicOpen emitCompleteBlock:^(BOOL emitSuccess) {
            if (emitSuccess) {
                [weakSelf.linkMicSettingSheet updateLinkMicType:linkMicOnAudio];
                [weakSelf.statusAreaView changeLinkmicButtonSelectedState:weakSelf.streamerPresenter.channelLinkMicOpen];
                [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
            }
        }];
    }
}

@end
