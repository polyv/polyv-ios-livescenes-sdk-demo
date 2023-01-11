//
//  PLVHCHiClassViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/22.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCHiClassViewController.h"

// 工具类
#import "PLVHCUtils.h"

// UI
#import "PLVHCHiClassSettingView.h"
#import "PLVHCStatusbarAreaView.h"
#import "PLVHCLinkMicAreaView.h"
#import "PLVHCToolbarAreaView.h"
#import "PLVHCDocumentAreaView.h"
#import "PLVHCDocumentSheet.h"
#import "PLVHCMemberSheet.h"
#import "PLVHCChatroomSheet.h"
#import "PLVHCSettingSheet.h"
#import "PLVHCLinkMicZoomAreaView.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"
#import "PLVMultiRoleLinkMicPresenter.h"
#import "PLVHCChatroomViewModel.h"
#import "PLVHCMemberViewModel.h"
#import "PLVHCLiveroomViewModel.h"
#import "PLVHCLinkMicZoomManager.h"
#import "PLVCaptureDeviceManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>


static NSString *const kPLVHCNavigationControllerName = @"PLVHCNavigationController"; // 导航控制器名称
static NSString *const kPLVHCChooseRoleVCName = @"PLVHCChooseRoleViewController"; // 角色选择页控制器名称
static NSString *const kPLVHCChooseLessonVCName = @"PLVHCChooseLessonViewController"; // 课节选择页控制器名称
static NSString *const kStudentCourseOrLessonLoginVCName = @"PLVHCStudentCourseOrLessonLoginViewController"; //学生课程号或者课节号登录控制器名称
static NSString *const kPLVHCTeacherLoginClassName = @"PLVHCTeacherLoginManager"; //讲师登录管理类名称

@interface PLVHCHiClassViewController ()<
PLVMultiRoleLinkMicPresenterDelegate,
PLVCaptureDeviceManagerDelegate,
PLVHCHiClassSettingViewDelegate, // 设备设置视图回调
PLVHCToolbarAreaViewDelegate, // 状态栏区域视图回调
PLVHCSettingSheetDelegate, // 设备弹层视图回调
PLVHCDocumentSheetDelegate, // 文档管理弹层视图回调
PLVHCDocumentAreaViewDelegate, // PPT/白板区域视图回调
PLVHCLiveroomViewModelDelegate, //教室上下课流程类的回调
PLVHCMemberSheetDelegate, //成员管理操作的回调
PLVHCLinkMicAreaViewDelegate, //连麦区域回调
PLVHCChatroomSheetDelegate, // 聊天室视图回调
PLVHCLinkMicZoomAreaViewDelegate // 连麦放大视图回调
>

#pragma mark UI
/// view hierarchy
///
/// (UIView) self.view
///    ├─
///    └─ (PLVHCHiClassSettingView) settingView（highest）进入主页后的设备设置视图，设置后移除
///
@property (nonatomic, strong) PLVHCHiClassSettingView *settingView; // 进入主页后的设备设置视图
@property (nonatomic, strong) PLVHCStatusbarAreaView *statusbarAreaView; // 状态栏区域视图
@property (nonatomic, strong) PLVHCLinkMicAreaView *linkMicAreaView; // 连麦区域视图
@property (nonatomic, strong) PLVHCDocumentAreaView *documentAreaView; // PPT/白板区域视图
@property (nonatomic, strong) PLVHCToolbarAreaView *toolbarAreaView; // 工具栏区域视图
@property (nonatomic, strong) PLVHCSettingSheet *settingSheet; // 设置弹层
@property (nonatomic, strong) PLVHCChatroomSheet *chatroomSheet; // 聊天室弹层
@property (nonatomic, strong) PLVHCMemberSheet *memberSheet; // 成员列表弹层
@property (nonatomic, strong) PLVHCDocumentSheet *documentSheet; // 文档管理弹层
@property (nonatomic, strong) PLVHCLinkMicZoomAreaView *linkMicZoomAreaView; // 连麦放大区域

#pragma mark 状态
@property (nonatomic, assign, getter=isFullscreen) BOOL fullscreen; // 是否处于文档区域全屏状态，默认为NO
@property (nonatomic, assign, getter=isHideDevicePreview) BOOL hideDevicePreview; // 是否隐藏设备预览页
@property (nonatomic, assign) BOOL switchedFullscreen; // 已切换全屏状态

#pragma mark 模块
@property (nonatomic, strong) PLVMultiRoleLinkMicPresenter *linkMicPresenter;

@end

@implementation PLVHCHiClassViewController

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    return [self initWithHideDevicePreview:NO];
}

- (instancetype)initWithHideDevicePreview:(BOOL)hidden {
    self = [super init];
    if (self) {
        self.hideDevicePreview = hidden;
        [PLVHCUtils sharedUtils].homeVC = self;
        [[PLVHCUtils sharedUtils] setupInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0x13/255.0 green:0x14/255.0 blue:0x15/255.0 alpha:1];
    
    [PLVCaptureDeviceManager sharedManager].delegate = self;
    
    [self setupUI];
    // 注册屏幕旋转通知
    [self deviceOrientationDidChangeNotification];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self getEdgeInset];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGFloat edgeInsetsRight = MAX(edgeInsets.right, 36);
    
    // 设置视图
    _settingView.frame = self.view.bounds;
    
    // 状态栏高度固定24 + 顶部安全区域高度
    self.statusbarAreaView.frame = CGRectMake(0, 0, screenSize.width, 24 + edgeInsets.top);
    
    // 1v6人以下连麦，连麦区域高度固定60；1v7以上连麦，连麦区域高度固定85
    NSInteger linkNumber = [PLVRoomDataManager sharedManager].roomData.linkNumber;
    CGFloat linkMicAreaViewHeight = linkNumber > 6 ? 85 : 60;
    if ([PLVHCUtils sharedUtils].isPad) { // iPad适配
        linkMicAreaViewHeight = linkNumber > 6 ? 115.3 : 82;
    }
    self.linkMicAreaView.frame = CGRectMake(0, CGRectGetMaxY(self.statusbarAreaView.frame), screenSize.width, linkMicAreaViewHeight);
  
    // 工具栏
    CGFloat toolbarAreaViewWidth = 36 * 2 + 14;
    self.toolbarAreaView.frame = CGRectMake(screenSize.width - edgeInsetsRight - toolbarAreaViewWidth , CGRectGetMaxY(self.linkMicAreaView.frame), toolbarAreaViewWidth, screenSize.height - CGRectGetMaxY(self.linkMicAreaView.frame) - edgeInsets.bottom);
    
    // 根据是否全屏算出ppt/文档区域的位置Y，后面弹层需根据这个位置进行布局
    CGFloat documentY = self.isFullscreen ? CGRectGetMaxY(self.statusbarAreaView.frame) : CGRectGetMaxY(self.linkMicAreaView.frame);
    // 成员列表弹层、聊天室弹层、文档管理弹层、画笔工具视图、画笔工具选择弹层、画笔颜色选择弹层的右边距
    CGFloat sheetEdgeInsetsRight = edgeInsetsRight + 36 + 14;
    // 各个弹层最大宽度
    CGFloat sheetMaxWidth = screenSize.width - sheetEdgeInsetsRight - edgeInsets.left;
    
    // 设置弹层，宽固定203，高固定255，底部距离（17 + 底部安全区域高度）
    CGFloat settingSheetY = screenSize.height - 255 - 17 - edgeInsets.bottom;
    if ([PLVHCUtils sharedUtils].isPad) { // iPad适配
        settingSheetY = (CGRectGetHeight(self.toolbarAreaView.frame) - 255) / 2 + self.toolbarAreaView.frame.origin.y;
    }
    _settingSheet.frame = CGRectMake(screenSize.width - sheetEdgeInsetsRight - 203, settingSheetY, 203, 255);
    
    // 成员弹层，顶部距离连麦区域8.5，底部距离（7.5 + 底部安全区域高度）
    CGFloat memberSheetOriginY = documentY + 8.5;
    CGFloat memberSheetWidthScale = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ? (656.0 / 812.0) : (408.0 / 812.0);
    if ([PLVHCUtils sharedUtils].isPad) {
        memberSheetWidthScale = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ? (656.0 / 1024.0) : (408.0 / 1024.0);
    }
    CGFloat memberSheetWidth = memberSheetWidthScale * screenSize.width;
    _memberSheet.frame = CGRectMake(screenSize.width - sheetEdgeInsetsRight - memberSheetWidth, memberSheetOriginY, memberSheetWidth, screenSize.height - memberSheetOriginY - 7.5 - edgeInsets.bottom);
    
    // PPT/白板区域视图
    // PPT/白板区域高度：屏幕高度-顶部距离-底部安全距离
    CGFloat documentViewHeight = screenSize.height - documentY - edgeInsets.bottom;
    // PPT/白板区域宽度：屏幕宽度-左边安全距离-右边安全距离
    CGFloat documentAreaViewWidth = screenSize.width - edgeInsets.left - edgeInsetsRight;
    self.documentAreaView.frame = CGRectMake(edgeInsets.left, documentY, documentAreaViewWidth, documentViewHeight);
    [self.documentAreaView setNeedsLayout];
    [self.documentAreaView layoutIfNeeded];
    
    // 连麦悬浮窗区域, 与PPT/白板区域内部的WebView视图frame一致
    if (CGRectEqualToRect(CGRectZero, self.linkMicZoomAreaView.frame) ||
        self.switchedFullscreen) { // 初始化、切换全屏转态时赋值
        self.switchedFullscreen = NO;
        CGRect zoomAreaViewFrame = self.documentAreaView.containerView.frame;
        zoomAreaViewFrame = [self.documentAreaView convertRect:zoomAreaViewFrame toView:self.view]; // 将zoomAreaViewFrame坐标从self.documentAreaView的坐标 转成self.view的坐标
        self.linkMicZoomAreaView.frame = zoomAreaViewFrame;
        self.linkMicZoomAreaView.originalSize = zoomAreaViewFrame.size;
    }
    CGPoint zoomAreaCenter = self.documentAreaView.containerView.center;
    self.linkMicZoomAreaView.center = [self.documentAreaView convertPoint:zoomAreaCenter toView:self.view];
    // 文档管理弹层，宽度固定为屏幕80%，高度:PPT/白板区域高度 - 顶部间距8 - 底部间距8
    CGSize documentSheetSize = CGSizeMake(screenSize.width * 0.8,  documentViewHeight - 8 * 2);
    CGFloat documentSheetX = sheetMaxWidth - documentSheetSize.width + edgeInsets.left;
    CGFloat documentSheetY = documentY + 8;
    _documentSheet.frame = CGRectMake(documentSheetX, documentSheetY, documentSheetSize.width, documentSheetSize.height);
    
    // 聊天室弹层，宽度动态设置为屏幕31.1%、40%(老师登录&宽度<=667的小屏)，高度:PPT/白板区域高度 - 顶部间距10 - 底部间距8
    CGFloat chatroomWidthScale = 0.311;
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher &&
        [UIScreen mainScreen].bounds.size.width <= 667) { // 老师登录时适配小屏
        chatroomWidthScale = 0.40;
    }
    CGSize chatroomSize = CGSizeMake(screenSize.width * chatroomWidthScale, documentViewHeight - 10 - 8);
    CGFloat chatroomX = sheetMaxWidth - chatroomSize.width + edgeInsets.left;
    CGFloat chatroomY = documentY + 10;
    _chatroomSheet.frame = CGRectMake(chatroomX, chatroomY, chatroomSize.width, chatroomSize.height);
    
}

- (void)dealloc {
    [self removeNotification];
}

#pragma mark - [ Override ]

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [PLVHCUtils sharedUtils].interfaceOrientation; // 选图返回后-[PLVHCNavigationController preferredInterfaceOrientationForPresentation]会调用此方法
}

#pragma mark - [ Private Method ]

- (void)setupModule {
    // 启动聊天室管理器
    [[PLVHCChatroomViewModel sharedViewModel] setup];
    // 初始化成员模块，开始获取成员列表数据并开启自动更新
    [[PLVHCMemberViewModel sharedViewModel] setup];
            
    // 初始化连麦模块
    self.linkMicPresenter = [[PLVMultiRoleLinkMicPresenter alloc] init];
    self.linkMicPresenter.delegate = self;
    
    PLVCaptureDeviceManager *deviceManager = [PLVCaptureDeviceManager sharedManager];
    [self.linkMicPresenter openLocalUserMic:deviceManager.microOpen];
    [self.linkMicPresenter openLocalUserCamera:deviceManager.cameraOpen];
    [self.linkMicPresenter switchLocalUserCamera:deviceManager.cameraFront];
    
    // 教室上下课流程类的代理
    [[PLVHCLiveroomViewModel sharedViewModel] setup];
    [PLVHCLiveroomViewModel sharedViewModel].delegate = self;
    [[PLVHCLiveroomViewModel sharedViewModel] enterClassroom];
    
    // 启动连麦放大视图管理器
    [[PLVHCLinkMicZoomManager sharedInstance] setup];
    [PLVHCLinkMicZoomManager sharedInstance].delegate = self.linkMicZoomAreaView;

    // 1. 回收麦克风资源（只有设备检测页需要）
    [deviceManager releaseAudioResource];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass ||
        roomData.roomUser.viewerType != PLVRoomUserTypeTeacher) {
        // 2. 根据业务需要回收摄像头资源（只有讲师登陆未上课的课节需要持有摄像头资源）
        [deviceManager releaseVideoResource];
    }
}

/// 登出操作
- (void)logout {
    [PLVRoomLoginClient logout];
    [[PLVHCChatroomViewModel sharedViewModel] clear];
    [[PLVSocketManager sharedManager] logout];
    [[PLVHCMemberViewModel sharedViewModel] clear];
    [self.toolbarAreaView clear];
    [[PLVDocumentUploadClient sharedClient] stopAllUpload]; // 停止一切上传任务
    [[PLVDocumentConvertManager sharedManager] clear]; // 清空文档转码轮询队列
    //退出教室
    [[PLVHCLiveroomViewModel sharedViewModel] clear];

    // 清除连麦放大视图管理器数据
    [[PLVHCLinkMicZoomManager sharedInstance] clear];

    [[PLVCaptureDeviceManager sharedManager] releaseVideoResource];
    [[PLVCaptureDeviceManager sharedManager] releaseAudioResource];
}

- (void)startClass {
    [[PLVCaptureDeviceManager sharedManager] releaseVideoResource];
    [[PLVCaptureDeviceManager sharedManager] releaseAudioResource];
    
    // 开始上课才开始获取成员列表
    [[PLVHCMemberViewModel sharedViewModel] start];
    
    // 设置上课状态
    [self.statusbarAreaView updateState:PLVHiClassStatusbarStateInClass];
    [self.toolbarAreaView startClass];
    [self.chatroomSheet startClass];
    [self.linkMicPresenter joinRTCChannel];
    // 移除本地预览连麦放大窗口
    [self.linkMicZoomAreaView removeLocalPreviewZoom];
}

- (void)finishClass {
    [[PLVHCLinkMicZoomManager sharedInstance] zoomOutAll]; // 下课前移除所有放大区域视图
    // 下课停止定时获取成员列表数据
    [[PLVHCMemberViewModel sharedViewModel] stop];
    
    //设置下课状态
    [self.statusbarAreaView updateState:PLVHiClassStatusbarStateFinishClass];
    [self.toolbarAreaView finishClass];
    [self.chatroomSheet finishClass];
    [self.linkMicPresenter leaveRTCChannel];
    
    // 清除学生自己的画笔权限
    [self removeSelfPaintBrushAuth];
    
}

- (void)enterClassroom {
    [self setupModule];
    [self removeSettingView];
    [self.linkMicAreaView startPreview];
    [self.documentAreaView enterClassroom];
}

- (void)exitClassroom {
    Class PLVHCTeacherLoginManager = NSClassFromString(kPLVHCTeacherLoginClassName);
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher
        && PLVHCTeacherLoginManager) {
        SEL selector = NSSelectorFromString(@"teacherExitClassroomFromViewController:");
        IMP imp = [PLVHCTeacherLoginManager methodForSelector:selector];
        void (*func)(id, SEL, UIViewController *) = (void *)imp;
        func(PLVHCTeacherLoginManager, selector, self);
    } else {
        BOOL success = [self logoutPopToViewController:kPLVHCChooseLessonVCName];
        if (!success) {
            [self setupRootViewController];
        }
    }
}

- (void)exitClassroomToStudentLoginVC {
    BOOL success = [self logoutPopToViewController:kStudentCourseOrLessonLoginVCName];
    if (!success) {
        [self setupRootViewController];
    }
}

- (BOOL)logoutPopToViewController:(NSString * _Nullable)viewControllerName {
    __block UIViewController *toViewController = nil;
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull controller, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([controller isKindOfClass:NSClassFromString(viewControllerName)]) {
            toViewController = controller;
            *stop = YES;
        }
    }];
    if (toViewController) {
        [self.navigationController popToViewController:toViewController animated:YES];
        [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];
        return YES;
    }
    return NO;
}

- (void)setupRootViewController {
    Class PLVHCChooseRoleVC = NSClassFromString(kPLVHCChooseRoleVCName);
    Class PLVHCNavigationController = NSClassFromString(kPLVHCNavigationControllerName);
    if (PLVHCChooseRoleVC && PLVHCNavigationController) {
        UINavigationController *navController = [((UINavigationController *)[PLVHCNavigationController alloc]) initWithRootViewController:[PLVHCChooseRoleVC new]];
        navController.navigationBar.hidden = YES;
        UIWindow *window = [PLVHCUtils getCurrentWindow];
        [UIView transitionWithView:window duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            BOOL oldState = [UIView areAnimationsEnabled];
            [UIView setAnimationsEnabled:NO];
            window.rootViewController = navController;
            [UIView setAnimationsEnabled:oldState];
        } completion:nil];
    }
}

/// 清除学生自己的画笔权限
- (void)removeSelfPaintBrushAuth {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType  == PLVRoomUserTypeTeacher) {
        return;
    }
    [self.documentAreaView removeSelfPaintBrushAuth];
}

#pragma mark Initialize

- (void)setupUI {
    [self.view addSubview:self.linkMicAreaView];
    [self.view insertSubview:self.documentAreaView aboveSubview:self.linkMicAreaView];
    [self.view insertSubview:self.linkMicZoomAreaView aboveSubview:self.documentAreaView];
    [self.view insertSubview:self.toolbarAreaView aboveSubview:self.documentAreaView];
    [self.view insertSubview:self.statusbarAreaView aboveSubview:self.toolbarAreaView];
    [self.view addSubview:self.settingView]; // 初次进入主页，设置子视图一定要在最前方

    //判断是否需要隐藏设备预览页
    if (self.isHideDevicePreview) {
        [self enterClassroom];
    }
}

- (void)getEdgeInset {
    UIEdgeInsets areaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        areaInsets = self.view.safeAreaInsets;
    }
    if ([PLVHCUtils sharedUtils].hadSetAreaInsets &&
        UIEdgeInsetsEqualToEdgeInsets([PLVHCUtils sharedUtils].areaInsets, areaInsets)) {
        return;
    }
    
    [PLVHCUtils sharedUtils].hadSetAreaInsets = YES;
    [[PLVHCUtils sharedUtils] setupAreaInsets:areaInsets];
}

#pragma mark Getter & Setter

- (PLVHCHiClassSettingView *)settingView {
    if (!_settingView) {
        _settingView = [[PLVHCHiClassSettingView alloc] init];
        _settingView.delegate = self;
    }
    return _settingView;
}

- (PLVHCStatusbarAreaView *)statusbarAreaView {
    if (!_statusbarAreaView) {
        _statusbarAreaView = [[PLVHCStatusbarAreaView alloc] init];
        
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        [_statusbarAreaView setClassTitle:roomData.channelName];
        [_statusbarAreaView setLessonId:[PLVHiClassManager sharedManager].lessonId];
        
        PLVHiClassStatusbarState state = PLVHiClassStatusbarStateNotInClass;
        if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusNotInClass) { // 未上课
            if ([PLVFdUtil curTimeInterval] > [PLVHiClassManager sharedManager].lessonStartTime) { // 超时未上课
                state = PLVHiClassStatusbarStateDelayStartClass;
            }
        } else if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusFinishClass) { // 已结束
            state = PLVHiClassStatusbarStateFinishClass;
        }
        [_statusbarAreaView updateState:state];
    }
    return _statusbarAreaView;
}

- (PLVHCLinkMicAreaView *)linkMicAreaView {
    if (!_linkMicAreaView) {
        _linkMicAreaView = [[PLVHCLinkMicAreaView alloc] init];
        _linkMicAreaView.delegate = self;
    }
    return _linkMicAreaView;
}

- (PLVHCDocumentAreaView *)documentAreaView {
    if (!_documentAreaView) {
        _documentAreaView = [[PLVHCDocumentAreaView alloc] init];
        _documentAreaView.delegate = self;
    }
    return _documentAreaView;
}

- (PLVHCToolbarAreaView *)toolbarAreaView {
    if (!_toolbarAreaView) {
        _toolbarAreaView = [[PLVHCToolbarAreaView alloc] init];
        _toolbarAreaView.delegate = self;
    }
    return _toolbarAreaView;
}

- (PLVHCSettingSheet *)settingSheet {
    if (!_settingSheet) {
        _settingSheet = [[PLVHCSettingSheet alloc] init];
        _settingSheet.delegate = self;
    }
    return _settingSheet;
}

- (PLVHCChatroomSheet *)chatroomSheet {
    if (!_chatroomSheet) {
        _chatroomSheet = [[PLVHCChatroomSheet alloc] init];
        _chatroomSheet.delegate = self;
    }
    return _chatroomSheet;
}

- (PLVHCMemberSheet *)memberSheet {
    if (!_memberSheet) {
        _memberSheet = [[PLVHCMemberSheet alloc] init];
        _memberSheet.delegate = self;
    }
    return _memberSheet;
}

- (PLVHCDocumentSheet *)documentSheet {
    if (!_documentSheet) {
        _documentSheet = [[PLVHCDocumentSheet alloc] init];
        _documentSheet.delegate = self;
    }
    return _documentSheet;
}

- (PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView {
    if (!_linkMicZoomAreaView) {
        _linkMicZoomAreaView = [[PLVHCLinkMicZoomAreaView alloc] init];
        _linkMicZoomAreaView.delegate = self;
    }
    return _linkMicZoomAreaView;
}

#pragma mark Show/Hide Subview

- (void)removeSettingView {
    [self.settingView removeFromSuperview];
    self.settingView = nil;
    
    [self.settingSheet synchronizeConfig];
}

- (void)showDocumentSheet:(BOOL)show {
    if (show) {
        [self.documentSheet showInView:self.view];
    } else {
        if (_documentSheet) {
            [self.documentSheet dismiss];
        }
    }
}

- (void)showMemberSheet:(BOOL)show {
    if (show) {
        [self.memberSheet showInView:self.view];
    } else {
        if (_memberSheet) {
            [self.memberSheet dismiss];
        }
    }
}

- (void)showChatroomSheet:(BOOL)show {
    if (show) {
        [self.chatroomSheet showInView:self.view];
    } else {
        if (_chatroomSheet) {
            [self.chatroomSheet dismiss];
        }
    }
}

- (void)showSettingSheet:(BOOL)show {
    if (show) {
        [self.settingSheet showInView:self.view];
    } else {
        if (_settingSheet) {
            [self.settingSheet dismiss];
        }
    }
}
#pragma mark Notification

- (void)deviceOrientationDidChangeNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Event ]
#pragma mark UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChangeNotification:(NSNotification *)notify {
    UIInterfaceOrientation orientaion = [UIApplication sharedApplication].statusBarOrientation;
    [[PLVHCUtils sharedUtils] setupInterfaceOrientation:orientaion];
}

#pragma mark - [ Delegate ]

#pragma mark PLVMultiRoleLinkMicPresenterDelegate

- (void)multiRoleLinkMicPresenterJoinRTCChannelFailure:(PLVMultiRoleLinkMicPresenter *)presenter {
    [PLVHCUtils showToastInWindowWithMessage:@"加入频道失败"];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
          networkQualityChanged:(PLVBLinkMicNetworkQuality)networkQuality {
    [self.statusbarAreaView setNetworkQuality:networkQuality];
    _chatroomSheet.netState = networkQuality;
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserRttMS:(NSInteger)rtt {
    [self.statusbarAreaView setNetworkDelayTime:rtt];
}

- (NSArray <PLVChatUser *> *)onlineUserArrayForMultiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter {
    return [PLVHCMemberViewModel sharedViewModel].onlineUserArray;
}

- (PLVChatUser * _Nullable)onlineUserForMultiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter withUserId:(NSString *)userId {
    return [[PLVHCMemberViewModel sharedViewModel] userInListWithUserId:userId];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserMicOpenChanged:(BOOL)open {
    [self.settingSheet microphoneSwitchChange:open];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserCameraShouldShowChanged:(BOOL)show {
    [self.settingSheet cameraSwitchChange:show];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserCameraFrontChanged:(BOOL)front {
    [self.settingSheet cameraDirectionChange:front];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserLinkMicStatusChanged:(BOOL)linkMic {
    if (linkMic) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OnStage message:@"你已上台"];
    } else {
        [PLVHCUtils showToastInWindowWithMessage:@"你已被老师请下台"];
    }
}

- (void)multiRoleLinkMicPresenterNeedAnswerForJoinResponseEvent:(PLVMultiRoleLinkMicPresenter *)presenter {
    __weak typeof(self) weakSelf = self;
    [[PLVHCLiveroomViewModel sharedViewModel] remindStudentInvitedJoinLinkMicWithConfirmHandler:^{
        [weakSelf.linkMicPresenter answerForJoinResponse];
    }];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
        linkMicUserArrayChanged:(NSArray <PLVLinkMicOnlineUser *>*)linkMicUserArray {
    // 刷新连麦窗口 UI
    [self.linkMicAreaView reloadLinkMicUserWindows];
    // 刷新成员列表数据
    [[PLVHCMemberViewModel sharedViewModel] refreshUserListWithLinkMicOnlineUserArray:linkMicUserArray];
    
    // 刷新连麦放大视图 UI
    [self.linkMicZoomAreaView reloadLinkMicUserZoom];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
              didUserJoinAnswer:(BOOL)success
                      linkMicId:(NSString *)linkMicId {
    [self.memberSheet linkMicUserJoinAnswer:success linkMicId:linkMicId];
    if (success) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_StudentOnStage message:@"学生已上台"];
    }
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter didCloseUserLinkMic:(PLVLinkMicOnlineUser *)linkMicUser {
    [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_StudentStepDown message:@"学生已下台"];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser audioMuted:(BOOL)mute {
    if (mute) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseMic message:@"已关该学生闭麦克风"];
    } else {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenMic message:@"已开启该学生麦克风"];
    }
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser videoMuted:(BOOL)mute {
    if (mute) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseCamera message:@"已关闭该学生摄像头"];
    } else {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenCamera message:@"已开启该学生摄像头"];
    }
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter authBrushUser:(PLVLinkMicOnlineUser *)authUser authBrush:(BOOL)authBrush {
    if (authBrush) {
        [self.documentAreaView setPaintBrushAuthWithUserId:authUser.userId];
    } else {
        [self.documentAreaView removePaintBrushAuthWithUserId:authUser.userId];
    }
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter grantCupUser:(PLVLinkMicOnlineUser *)grantUser {
    if ([PLVFdUtil checkStringUseable:grantUser.linkMicUserId] &&
        [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        [[PLVSocketManager sharedManager] emitPermissionMessageWithUserId:grantUser.linkMicUserId type:PLVSocketPermissionTypeCup status:YES];
    }
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter didTeacherScreenStreamRenderdIn:(UIView *)screenStreamView {
    [self.documentAreaView addSubview:screenStreamView];
    screenStreamView.frame = self.documentAreaView.bounds;
    screenStreamView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter didTeacherScreenStreamRemovedIn:(UIView *)screenStreamView {
    [screenStreamView removeFromSuperview];
}

#pragma mark PLVCaptureDeviceManager Delegate

- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didAudioVolumeChanged:(CGFloat)volume {
    if (_settingView) {
        [self.settingView audioVolumeChanged:volume];
    }
}

- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didMicrophoneOpen:(BOOL)open {
    if (_settingSheet) {
        [self.settingSheet microphoneSwitchChange:open];
    }
    [self.linkMicAreaView enableLocalMic:open];
    [self.linkMicPresenter openLocalUserMic:open];
}

- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didCameraOpen:(BOOL)open {
    if (_settingSheet) {
        [self.settingSheet cameraSwitchChange:open];
    }
    [self.linkMicAreaView enableLocalCamera:open];
    [self.linkMicPresenter openLocalUserCamera:open];
}

- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didCameraSwitch:(BOOL)front {
    if (_settingSheet) {
        [self.settingSheet cameraDirectionChange:front];
    }
    [self.linkMicPresenter switchLocalUserCamera:front];
}

#pragma mark PLVHCHiClassSettingViewDelegate

- (void)didTapEnterClassButtonInSettingView:(PLVHCHiClassSettingView *)settingView {
    [self enterClassroom];
}

- (void)didTapBackButtonInSettingView:(PLVHCHiClassSettingView *)settingView {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)alreadyLinkMicLocalStudentInSettingSheet {
    //当前用户的id
    NSString *userId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
    PLVLinkMicOnlineUser *onlineUser = [self.linkMicPresenter linkMicUserWithLinkMicId:userId];
    return onlineUser ? YES : NO;
}

#pragma mark PLVHCToolbarAreaViewDelegate

- (void)toolbarAreaView_classButtonSelected:(PLVHCToolbarAreaView *)toolbarAreaView startClass:(BOOL)starClass {
    __weak typeof(self) weakSelf = self;
    if (starClass) { //开始上课, 再次确保有【麦克风&摄像头】权限
        [[PLVCaptureDeviceManager sharedManager] requestAuthorizationWithoutAlertWithType:PLVCaptureDeviceTypeCameraAndMicrophone completion:^(BOOL granted) {
            if (granted) {
                [weakSelf.toolbarAreaView setClassButtonEnable:NO];
                [[PLVHCLiveroomViewModel sharedViewModel] startClass];
            } else {
                [PLVHCUtils showAlertWithTitle:@"权限不足"
                                       message:@"你没开通访问麦克风或相机的权限，如要开通，请移步到设置进行开通"
                             cancelActionTitle:@"取消"
                             cancelActionBlock:nil
                            confirmActionTitle:@"设置"
                            confirmActionBlock:^{
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }];
            }
        }];
    } else { //结束课程
        [[PLVHCLiveroomViewModel sharedViewModel] finishClass];
    }
}

- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView documentButtonSelected:(BOOL)selected {
    [self showDocumentSheet:selected];
}

- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView memberButtonSelected:(BOOL)selected {
    [self showMemberSheet:selected];
}

- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView chatroomButtonSelected:(BOOL)selected {
    [self showChatroomSheet:selected];
}

- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView settingButtonSelected:(BOOL)selected {
    [self showSettingSheet:selected];
}

- (void)toolbarAreaView_handUpButtonSelected:(PLVHCToolbarAreaView *)toolbarAreaView
                                      userId:(NSString *)userId {
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    [[PLVSocketManager sharedManager] emitPermissionMessageWithUserId:roomUser.viewerId type:PLVSocketPermissionTypeRaiseHand status:YES];
}

- (void)toolbarAreaView_CallingTeacher:(PLVHCToolbarAreaView *)toolbarAreaView {
    BOOL succes = [[PLVHiClassManager sharedManager] requestHelp];
    if (succes) {
        [PLVHCHiClassToast showToastWithMessage:@"请求已发送"];
    } else { // 组长请求帮助 请求失败 恢复按钮状态为 未选中
        [self.toolbarAreaView setCallingTeacherButtonEnable:NO];
    }
}

- (void)toolbarAreaView_CancelCallingTeacher:(PLVHCToolbarAreaView *)toolbarAreaView{
    BOOL succes = [[PLVHiClassManager sharedManager] cancelRequestHelp];
    if (succes) {
        [PLVHCHiClassToast showToastWithMessage:@"请求已取消"];
    } else { // 组长取消请求帮助 请求失败 恢复按钮状态为 选中
        [self.toolbarAreaView setCallingTeacherButtonEnable:YES];
    }
}

#pragma mark PLVHCSettingSheetDelegate

- (void)didChangeFullScreenSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet fullScreen:(BOOL)fullScreen {
    self.fullscreen = fullScreen;
    self.switchedFullscreen = YES;
    self.linkMicAreaView.hidden = fullScreen; // 全屏模式下隐藏连麦窗口
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self.linkMicZoomAreaView changeFullScreen:fullScreen]; // 改变全屏状态
}

- (void)didTapLogoutButtonInSettingSheet:(PLVHCSettingSheet *)settingSheet {
    [[PLVHCLiveroomViewModel sharedViewModel] exitClassroom];
}

#pragma mark PLVHCDocumentSheetDelegate

- (BOOL)documentSheet:(PLVHCDocumentSheet *)documentSheet didSelectAutoId:(NSUInteger)autoId {
    BOOL allow = !self.documentAreaView.isMaxMinimumNum;
    if (allow) {
        [self.documentAreaView openPptWithAutoId:autoId];
        [self.toolbarAreaView clearAllButtonSelected];
    }
    return allow;
}


#pragma mark PLVHCDocumentAreaViewDelegate

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshBrushPermission:(BOOL)permission userId:(nonnull NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]){
        return;
    }
    [[PLVHCMemberViewModel sharedViewModel] brushPermissionWithUserId:userId auth:permission];
}

#pragma mark PLVHCLiveroomViewModelDelegate

- (void)liveroomViewModelStartClass:(PLVHCLiveroomViewModel *)viewModel {
    [self.toolbarAreaView setClassButtonEnable:YES];
    [self startClass];
}

- (void)liveroomViewModelFinishClass:(PLVHCLiveroomViewModel *)viewModel {
    [self.toolbarAreaView setClassButtonEnable:YES];
    [self finishClass];
}

- (void)liveroomViewModelDurationChanged:(PLVHCLiveroomViewModel *)viewModel duration:(NSInteger)duration {
    [self.statusbarAreaView updateDuration:duration];
    
    PLVHiClassStatus status = [PLVHiClassManager sharedManager].status;
    NSInteger lessonEndTime = [PLVHiClassManager sharedManager].lessonEndTime;
    if (status == PLVHiClassStatusInClass) {
        if ([PLVFdUtil curTimeInterval] > lessonEndTime) {
            [self.statusbarAreaView updateState:PLVHiClassStatusbarStateDelayFinishClass];
        }
    }
}

- (void)liveroomViewModelReadyExitClassroom:(PLVHCLiveroomViewModel *)viewModel {
    [self logout];
    [self exitClassroom];
}

- (void)liveroomViewModelReadyExitClassroomToStudentLogin:(PLVHCLiveroomViewModel *)viewModel {
    [self logout];
    [self exitClassroomToStudentLoginVC];
}

- (void)liveroomViewModelDelayInClass:(PLVHCLiveroomViewModel *)viewModel {
    [self.statusbarAreaView updateState:PLVHiClassStatusbarStateDelayStartClass];
}

- (void)liveroomViewModelDidJoinGroupSuccess:(PLVHCLiveroomViewModel *)viewModel ackData:(NSDictionary *)data {
    [self.documentAreaView switchRoomWithAckData:data datacallback:nil]; // 将'PPT/白板区'切换到分组房间
    [self.linkMicPresenter changeChannel]; // 切换RTC频道
    [[PLVHCMemberViewModel sharedViewModel] loadOnlineUserList]; // 重新加载在线成员数据
    [[PLVHCChatroomViewModel sharedViewModel] changeRoom]; // 切换聊天室房间
    [[PLVHCLinkMicZoomManager sharedInstance] startGroup]; // 加入分组
}

/// 进入分组后，获取到分组名称、组长ID、组长名称
- (void)liveroomViewModelDidGroupLeaderUpdate:(PLVHCLiveroomViewModel *)viewModel
                                    groupName:(NSString *)groupName
                                groupLeaderId:(NSString *)groupLeaderId
                              groupLeaderName:(NSString *)groupLeaderName {
    if ([PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 当前 组长是自己
        [self.documentAreaView setOrRemoveGroupLeader:YES]; // 设为组长
    } else { // 当前 组长是其他人
        [self.documentAreaView setOrRemoveGroupLeader:NO]; // 清除组长权限
    }
    
    [self.toolbarAreaView startGroup]; // 设置工具栏 开始分组视图
    
    NSString *title = [PLVRoomDataManager sharedManager].roomData.channelName;
    title = [PLVFdUtil checkStringUseable:title] ? title : @"";
    groupName = [PLVFdUtil checkStringUseable:groupName] ? groupName : @"";
    title = [NSString stringWithFormat:@"%@-%@", title, groupName];
    
    [self.statusbarAreaView setClassTitle:title]; // 更新状态栏标题
    
    [self.linkMicPresenter updateGroupLeader];
}

/// 结束分组
- (void)liveroomViewModelDidLeaveGroup:(PLVHCLiveroomViewModel *)viewModel ackData:(nonnull NSDictionary *)data {
    // 更新状态栏标题
    NSString *title = [PLVRoomDataManager sharedManager].roomData.channelName;
    [self.statusbarAreaView setClassTitle:title];
    
    [self.toolbarAreaView finishGroup]; // 设置工具栏 结束分组视图
    [self.documentAreaView setOrRemoveGroupLeader:NO]; // 清除组长权限工具
    [self.documentAreaView switchRoomWithAckData:data datacallback:nil];  // 将'PPT/白板区'切换回大房间（讲师的房间）
    [self.linkMicPresenter changeChannel]; // 切换RTC频道
    [[PLVHCMemberViewModel sharedViewModel] loadOnlineUserList]; // 重新加载在线成员数据
    [[PLVHCChatroomViewModel sharedViewModel] changeRoom]; // 切换聊天室房间
    [[PLVHCLinkMicZoomManager sharedInstance] leaveGroupRoomWithAckData:data]; // 从分组切换回大房间
}

- (void)liveroomViewModelDidCancelRequestHelp:(PLVHCLiveroomViewModel *)viewModel {
    [self.toolbarAreaView setCallingTeacherButtonEnable:NO];
}

#pragma mark PLVHCMemberSheetDelegate

- (void)inviteUserLinkMicInMemberSheet:(PLVHCMemberSheet *)memberSheet
                               linkMic:(BOOL)linkMic
                              chatUser:(PLVChatUser *)chatUser {
    if (linkMic) {
        [self.linkMicPresenter allowUserLinkMic:chatUser];
    } else {
        [self.linkMicPresenter closeUserLinkMic:chatUser.onlineUser];
    }
}

- (BOOL)closeAllLinkMicUserInMemberSheet:(PLVHCMemberSheet *)memberSheet {
    return [self.linkMicPresenter closeAllLinkMicUser];
}

- (void)muteAllLinkMicUserMicInMemberSheet:(PLVHCMemberSheet *)memberSheet
                                      mute:(BOOL)mute {
    [self.linkMicPresenter muteAllLinkMicUserMicrophone:mute];
}

- (void)raiseHandStatusChanged:(PLVHCMemberSheet *)memberSheet status:(BOOL)raiseHandStatus count:(NSInteger)raiseHandCount {
    [self.toolbarAreaView raiseHand:raiseHandStatus count:raiseHandCount];
}

#pragma mark PLVHCLinkMicAreaViewDelegate

- (NSArray *)plvHCLinkMicAreaViewGetCurrentUserModelArray:(PLVHCLinkMicAreaView *)linkMicAreaView {
    return self.linkMicPresenter.currentLinkMicUserArray;
}

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
- (NSInteger)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView findUserModelIndexWithFiltrateBlock:(BOOL (^)(PLVLinkMicOnlineUser * _Nonnull))filtrateBlockBlock {
    return [self.linkMicPresenter linkMicUserIndexWithFiltrateBlock:filtrateBlockBlock];
}

/// 连麦窗口列表视图 需要根据下标值获取对应用户
- (PLVLinkMicOnlineUser *)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex {
    return [self.linkMicPresenter linkMicUserWithIndex:targetIndex];
}

- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView didSwitchLinkMicWithExternalView:(UIView *)externalView userId:(nonnull NSString *)userId showInZoom:(BOOL)showInZoom {
    BOOL isSelf = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    if (showInZoom) {
        if (isSelf) {
            PLVResolutionType type =  [PLVRoomDataManager sharedManager].roomData.maxResolution;
            [self.linkMicPresenter setupStreamQuality:[PLVRoomData streamQualityWithResolutionType:type]]; // 显示在放大区域，推流分辨率设为最高分辨率
        }
        [self.linkMicZoomAreaView displayExternalView:externalView userId:userId];
    } else {
        if (isSelf) {
            [self.linkMicPresenter setupStreamQuality:PLVBLinkMicStreamQuality180P]; //从放大区域移除，推流分辨率设为180P
        }
        [self.linkMicZoomAreaView removeExternalView:externalView userId:userId];
    }
}

- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView didRefreshLinkMiItemView:(nonnull PLVHCLinkMicItemView *)linkMicItemView {
    [self.linkMicZoomAreaView refreshLinkMicItemView:linkMicItemView];
}

#pragma mark PLVHCChatroomSheetDelegate

- (void)chatroomSheet:(PLVHCChatroomSheet *)chatroomSheet didChangeNewMessageCount:(NSUInteger)newMessageCount {
    if (newMessageCount > 0) {
        [self.toolbarAreaView toolbarAreaViewReceiveNewMessage];
    }
}

#pragma mark PLVHCLinkMicZoomAreaViewDelegate

- (NSArray *)linkMicZoomAreaViewGetCurrentUserModelArray:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView {
    return self.linkMicPresenter.currentLinkMicUserArray;
}

- (void)linkMicZoomAreaView:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView didTapActionWithUserData:(PLVLinkMicOnlineUser * _Nullable)userData {
    if (!userData) { // 本地预览
        [self.linkMicAreaView showLocalSettingView];
    } else { // 连麦视图
        [self.linkMicAreaView showSettingViewWithUser:userData];
    }
}

- (void)linkMicZoomAreaViewDidReLoadLinkMicUserWindows:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView {
    [self.linkMicAreaView reloadLinkMicUserWindows];
}

- (UIView *)linkMicZoomAreaView:(PLVHCLinkMicZoomAreaView *)linkMicZoomAreaView getLinkMicItemViewWithUserId:(NSString *)userId {
    return [self.linkMicAreaView getLinkMicItemViewWithUserId:userId];
}

@end
