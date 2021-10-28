//
//  PLVHCHiClassViewController.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/22.
//  Copyright © 2021 polyv. All rights reserved.
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
#import "PLVHCDocumentMinimumSheet.h"
#import "PLVHCBrushToolBarView.h"
#import "PLVHCBrushToolSelectSheet.h"
#import "PLVHCBrushColorSelectSheet.h"
#import "PLVHCGrantCupView.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVHCChatroomViewModel.h"
#import "PLVHCMemberViewModel.h"
#import "PLVHCDocumentMinimumModel.h"
#import "PLVDocumentModel.h"
#import "PLVRoomDataManager.h"
#import "PLVHCPermissionEvent.h"
#import "PLVHCLiveroomViewModel.h"
#import "PLVMultiRoleLinkMicPresenter.h"
#import "PLVDocumentConvertManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>


static NSString *const kPLVHCNavigationControllerName = @"PLVHCNavigationController"; // 导航控制器名称
static NSString *const kPLVHCChooseRoleVCName = @"PLVHCChooseRoleViewController"; // 角色选择页控制器名称
static NSString *const kPLVHCChooseLessonVCName = @"PLVHCChooseLessonViewController"; // 课节选择页控制器名称
static NSString *const kStudentCourseOrLessonLoginVCName = @"PLVHCStudentCourseOrLessonLoginViewController"; //学生课程号或者课节号登录控制器名称
static NSString *const kPLVHCTeacherLoginClassName = @"PLVHCTeacherLoginManager"; //讲师登录管理类名称

@interface PLVHCHiClassViewController ()<
PLVRoomDataManagerProtocol,
PLVMultiRoleLinkMicPresenterDelegate,
PLVSocketManagerProtocol, // socket回调
PLVHCHiClassSettingViewDelegate, // 设备设置视图回调
PLVHCToolbarAreaViewDelegate, // 状态栏区域视图回调
PLVHCSettingSheetDelegate, // 设备弹层视图回调
PLVHCDocumentSheetDelegate, // 文档管理弹层视图回调
PLVHCDocumentMinimumSheetDelegate, // 文档最小化弹层视图回调
PLVHCDocumentAreaViewDelegate, // PPT/白板区域视图回调
PLVHCBrushToolbarViewDelegate, // 画笔工具视图回调
PLVHCBrushToolSelectSheetDelegate, // 工具选择器视图回调
PLVHCBrushColorSelectSheetDelegate, // 颜色选择器视图回调
PLVHCPermissionEventDelegate, // TEACHER_SET_PERMISSION 事件管理器回调
PLVHCLiveroomViewModelDelegate, //教室上下课流程类的回调
PLVHCMemberSheetDelegate, //成员管理操作的回调
PLVHCLinkMicAreaViewDelegate, //连麦区域回调
PLVHCStatusbarAreaViewDelegate, //状态栏区域事件回调
PLVHCChatroomSheetDelegate // 聊天室视图回调
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
@property (nonatomic, strong) PLVHCDocumentMinimumSheet *documentMinimumSheet; // 文档最小化弹层
@property (nonatomic, strong) PLVHCBrushToolBarView *brushToolBarView; // 画笔工具视图
@property (nonatomic, strong) PLVHCBrushToolSelectSheet *brushToolSelectSheet; // 画笔工具选择弹层
@property (nonatomic, strong) PLVHCBrushColorSelectSheet *brushColorSelectSheet; // 画笔颜色选择弹层
@property (nonatomic, strong) PLVHCGrantCupView *grantCupView; // 授予学生奖杯视图
@property (nonatomic, strong) UIButton *resetZoomButton; // 重置画板缩放比例

#pragma mark 状态
@property (nonatomic, assign, getter=isFullscreen) BOOL fullscreen; // 是否处于文档区域全屏状态，默认为NO
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中

@property (nonatomic, assign, getter=isShowToast) BOOL showToast; // 设置面板是否允许弹出toast
@property (nonatomic, assign, getter=isHideDevicePreview) BOOL hideDevicePreview; // 是否隐藏设备预览页
@property (nonatomic, assign) PLVRoomUserType viewerType; //用户类型/角色

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
        self.viewerType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        [PLVHCUtils sharedUtils].homeVC = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0x13/255.0 green:0x14/255.0 blue:0x15/255.0 alpha:1];
    
    [self setupUI];
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
    NSInteger linkNumber = [PLVRoomDataManager sharedManager].roomData.lessonInfo.linkNumber;
    CGFloat linkMicAreaViewHeight = linkNumber > 6 ? 85 : 60;
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
    _settingSheet.frame = CGRectMake(screenSize.width - sheetEdgeInsetsRight - 203, screenSize.height - 255 - 17 - edgeInsets.bottom, 203, 255);
    
    // 成员弹层，顶部距离连麦区域8.5，底部距离（7.5 + 底部安全区域高度）
    CGFloat memberSheetOriginY = documentY + 8.5;
    CGFloat memberSheetWidth = 656.0 / 812.0 * screenSize.width;
    _memberSheet.frame = CGRectMake(screenSize.width - sheetEdgeInsetsRight - memberSheetWidth, memberSheetOriginY, memberSheetWidth, screenSize.height - memberSheetOriginY - 7.5 - edgeInsets.bottom);
    
    // PPT/白板区域视图
    // PPT/白板区域高度：屏幕高度-顶部距离-底部安全距离-8
    CGFloat documentViewHeight = screenSize.height - documentY - edgeInsets.bottom - 8;
    // PPT/白板区域宽度：固定为高度的2.2倍，并且不超过最多可用宽度sheetMaxWidth-8
    CGFloat documentAreaViewWidth = MIN(documentViewHeight * 2.2, sheetMaxWidth - 8);
    self.documentAreaView.frame = CGRectMake(screenSize.width - sheetEdgeInsetsRight - documentAreaViewWidth, documentY, documentAreaViewWidth, documentViewHeight);
    
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
    
    // 画笔工具视图，内部自适应，(宽度：动态按钮宽度+ 右边间距，高度固定36)
    _brushToolBarView.screenSafeWidth = sheetMaxWidth;
    
    // 画笔工具选择弹层，总共7(讲师)、6(学生)种工具，每个工具固定大小为36*44,间距8*数量 + 左右间距4
    CGFloat brushToolCount = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ? 7 : 6;
    CGSize brushToolSelectViewSize = CGSizeMake( 4 * 2 + 36 * brushToolCount + 8 * (brushToolCount - 1), 44);
    CGFloat brushToolSelectViewX = sheetMaxWidth - brushToolSelectViewSize.width + edgeInsets.left;
    CGFloat brushToolSelectViewY = CGRectGetMinY(_brushToolBarView.frame) - brushToolSelectViewSize.height - 14; // 与画笔工具视图间距14，显示在其上面
    _brushToolSelectSheet.frame = CGRectMake(brushToolSelectViewX, brushToolSelectViewY, brushToolSelectViewSize.width, brushToolSelectViewSize.height);
    
    // 画笔颜色选择弹层，总共6种颜色，左间距4 + 每个颜色固定大小为36*44 + 间距8*5 + 右间距4
    CGSize brushColorSelectViewSize = CGSizeMake(4 + 36 * 6 + 8 * 5 + 4, 44);
    CGFloat brushColorSelectViewX = sheetMaxWidth - brushColorSelectViewSize.width + edgeInsets.left;
    CGFloat brushColorSelectViewY = CGRectGetMinY(_brushToolBarView.frame) - brushColorSelectViewSize.height - 14; // 与画笔工具视图间距14，显示在其上面
    _brushColorSelectSheet.frame = CGRectMake(brushColorSelectViewX, brushColorSelectViewY, brushColorSelectViewSize.width, brushColorSelectViewSize.height);
    
    // 重置画板缩放比例
    // 根据是否全屏算出位置Y
    CGFloat resetZoomY = self.isFullscreen ? CGRectGetMaxY(self.statusbarAreaView.frame) : CGRectGetMaxY(self.linkMicAreaView.frame);
    resetZoomY += 12; // 顶部间隔12
    _resetZoomButton.frame = CGRectMake(MAX(edgeInsets.left, 36), resetZoomY, 116, 36);
    
}

#pragma mark - [ Override ]

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeLeft;
}

#pragma mark - [ Private Method ]

- (void)setupModule {
    [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 启动聊天室管理器
    [[PLVHCChatroomViewModel sharedViewModel] setup];
    // 初始化成员模块，开始获取成员列表数据并开启自动更新
    [[PLVHCMemberViewModel sharedViewModel] setup];
            
    // 初始化连麦模块
    self.linkMicPresenter = [[PLVMultiRoleLinkMicPresenter alloc] init];
    self.linkMicPresenter.delegate = self;
    
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 启动TEACHER_SET_PERMISSION 事件管理器
    [PLVHCPermissionEvent sharedInstance].delegate = self;
    [[PLVHCPermissionEvent sharedInstance] setup];
    
    //教室上下课流程类的代理
    [[PLVHCLiveroomViewModel sharedViewModel] setup];
    [PLVHCLiveroomViewModel sharedViewModel].delegate = self;
}

/// 登出操作
- (void)logout {
    [PLVRoomLoginClient logout];
    [[PLVHCChatroomViewModel sharedViewModel] clear];
    [[PLVSocketManager sharedManager] logout];
    [[PLVHCMemberViewModel sharedViewModel] clear];
    [[PLVHCPermissionEvent sharedInstance] clear];
    [self.toolbarAreaView clear];
    [[PLVDocumentUploadClient sharedClient] stopAllUpload]; // 停止一切上传任务
    [[PLVDocumentConvertManager sharedManager] clear]; // 清空文档转码轮询队列
    //退出教室
    [[PLVHCLiveroomViewModel sharedViewModel] clear];
    [self logoutPopViewController];
}

- (void)startClass {
    // 开始上课才开始获取成员列表
    [[PLVHCMemberViewModel sharedViewModel] start];
    
    // 设置上课状态
    [self.statusbarAreaView startClass];
    [self.toolbarAreaView startClass];
    [self.chatroomSheet startClass];
    [self.linkMicPresenter joinRTCChannel];
}

- (void)finishClass {
    // 下课停止定时获取成员列表数据
    [[PLVHCMemberViewModel sharedViewModel] stop];
    
    //设置下课状态
    [self.linkMicPresenter leaveRTCChannel];
    [self.statusbarAreaView finishClass];
    [self.toolbarAreaView finishClass];
    [self.chatroomSheet finishClass];
    
    // 清除学生自己的画笔权限
    [self removeSelfPaintBrushAuth];
}

- (void)enterClassroom {
    [self setupModule];
    [self removeSettingView];
    [[PLVHCLiveroomViewModel sharedViewModel] enterClassroom];
}

- (void)logoutPopViewController {
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        Class PLVHCTeacherLoginManager = NSClassFromString(kPLVHCTeacherLoginClassName);
        if (PLVHCTeacherLoginManager) {
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
    } else {
        BOOL haveNextClass = [PLVHCLiveroomViewModel sharedViewModel].haveNextClass;
        NSString *viewControllerName = haveNextClass ? kPLVHCChooseLessonVCName : kStudentCourseOrLessonLoginVCName;
        [self logoutPopToViewController:viewControllerName];
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
        UIWindow *window = [self getCurrentWindow];
        [UIView transitionWithView:window duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            BOOL oldState = [UIView areAnimationsEnabled];
            [UIView setAnimationsEnabled:NO];
            window.rootViewController = navController;
            [UIView setAnimationsEnabled:oldState];
        } completion:nil];
    }
}

- (UIWindow *)getCurrentWindow {
    if ([UIApplication sharedApplication].delegate.window) {
        return [UIApplication sharedApplication].delegate.window;
    } else {
        if (@available(iOS 13.0, *)) { // iOS 13.0+
            NSArray *array = [[[UIApplication sharedApplication] connectedScenes] allObjects];
            UIWindowScene *windowScene = (UIWindowScene *)array[0];
            UIWindow *window = [windowScene valueForKeyPath:@"delegate.window"];
            if (!window) {
                window = [UIApplication sharedApplication].windows.firstObject;
            }
            return window;
        } else {
            return [UIApplication sharedApplication].keyWindow;
        }
    }
}

#pragma mark Initialize

- (void)setupUI {
    [self.view addSubview:self.linkMicAreaView];
    [self.view insertSubview:self.documentAreaView aboveSubview:self.linkMicAreaView];
    [self.view insertSubview:self.toolbarAreaView aboveSubview:self.documentAreaView];
    [self.view insertSubview:self.statusbarAreaView aboveSubview:self.toolbarAreaView];
    [self.view insertSubview:self.resetZoomButton aboveSubview:self.statusbarAreaView];
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
        _statusbarAreaView.delegate = self;
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

- (PLVHCBrushToolBarView *)brushToolBarView {
    if (!_brushToolBarView) {
        _brushToolBarView = [[PLVHCBrushToolBarView alloc] init];
        _brushToolBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _brushToolBarView.delegate = self;
    }
    return _brushToolBarView;
}

- (PLVHCBrushToolSelectSheet *)brushToolSelectSheet {
    if (!_brushToolSelectSheet) {
        _brushToolSelectSheet = [[PLVHCBrushToolSelectSheet alloc] init];
        _brushToolSelectSheet.delegate = self;
    }
    return _brushToolSelectSheet;
}

- (PLVHCBrushColorSelectSheet *)brushColorSelectSheet {
    if (!_brushColorSelectSheet) {
        _brushColorSelectSheet = [[PLVHCBrushColorSelectSheet alloc] init];
        _brushColorSelectSheet.delegate = self;
    }
    return _brushColorSelectSheet;
}

- (PLVHCDocumentMinimumSheet *)documentMinimumSheet {
    if (!_documentMinimumSheet) {
        _documentMinimumSheet = [[PLVHCDocumentMinimumSheet alloc] init];
        _documentMinimumSheet.delegate = self;
    }
    return _documentMinimumSheet;
}

- (PLVHCGrantCupView *)grantCupView {
    if (!_grantCupView) {
        _grantCupView = [[PLVHCGrantCupView alloc] init];
    }
    return _grantCupView;
}

- (UIButton *)resetZoomButton {
    if(!_resetZoomButton) {
        _resetZoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resetZoomButton.hidden = YES;
        _resetZoomButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#242940" alpha:0.9];
        _resetZoomButton.layer.cornerRadius = 18;
        _resetZoomButton.layer.masksToBounds = YES;
        [_resetZoomButton setImage:[PLVHCUtils imageForDocumentResource:@"plvhc_doc_btn_resetzoom"] forState:UIControlStateNormal];
        [_resetZoomButton setTitle:@"默认尺寸" forState:UIControlStateNormal];
        [_resetZoomButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _resetZoomButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_resetZoomButton addTarget:self action:@selector(resetZoomButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
        
    }
    return _resetZoomButton;
}

#pragma mark Show/Hide Subview

- (void)removeSettingView {
    [self.settingView removeFromSuperview];
    [self.settingView clear];
    [self.linkMicAreaView linkMicAreaViewStartRunning];
    [self.settingSheet synchronizeConfig:self.settingView.configDict];
    self.showToast = YES;
    self.settingView = nil;
    [self showBrushToolbarView:YES];
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

- (void)showBrushToolbarView:(BOOL)show {
    if (show &&
        self.brushToolBarView.haveBrushPermission) {
        [self.brushToolBarView showInView:self.view];
    } else {
        if (_brushToolBarView) {
            [self.brushToolBarView dismiss];
        }
        if (_brushToolSelectSheet) {
            [self.brushToolSelectSheet dismiss];
        }
        if (_brushColorSelectSheet) {
            [self.brushColorSelectSheet dismiss];
        }
    }
}

- (void)showDocumentMinimumSheet:(BOOL)show {
    if (show) {
        [self.documentMinimumSheet showInView:self.view];
    } else {
        if (_documentMinimumSheet) {
            [self.documentMinimumSheet dismiss];
        }
    }
}

- (void)showResetZoomButton:(BOOL)show {
    self.resetZoomButton.hidden = !show;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)resetZoomButtonAction {
    [self.documentAreaView resetZoom];
}

#pragma mark - [ Delegate ]

#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didHiClassTeacherRelogin:(NSString *)msg {
    __weak typeof(self) weakSelf = self;
    [PLVFdUtil showAlertWithTitle:nil message:msg viewController:self cancelActionTitle:@"确定" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:^(UIAlertAction * _Nonnull action) {
        [weakSelf logout];
    } confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:nil];
}

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
    [[PLVHCLiveroomViewModel sharedViewModel] remindStudentInvitedJoinLinkMic];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
        linkMicUserArrayChanged:(NSArray <PLVLinkMicOnlineUser *>*)linkMicUserArray {
    // 刷新连麦窗口 UI
    [self.linkMicAreaView reloadLinkMicUserWindows];
    // 刷新成员列表数据
    [[PLVHCMemberViewModel sharedViewModel] refreshUserListWithLinkMicOnlineUserArray:linkMicUserArray];
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
    [[PLVHCPermissionEvent sharedInstance] sendGrantCupMessageWithUserId:grantUser.linkMicUserId];
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter didTeacherScreenStreamRenderdIn:(UIView *)screenStreamView {
    [self.documentAreaView addSubview:screenStreamView];
    screenStreamView.frame = self.documentAreaView.bounds;
    screenStreamView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter didTeacherScreenStreamRemovedIn:(UIView *)screenStreamView {
    [screenStreamView removeFromSuperview];
}

#pragma mark PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString { // 登陆成功
    [PLVHCUtils showToastInWindowWithMessage:@"聊天室登录成功"];
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin ||
        error.code == PLVSocketLoginErrorCodeKick) &&
        error.localizedDescription) {
        __weak typeof(self) weakSelf = self;
        [PLVFdUtil showAlertWithTitle:nil message:error.localizedDescription viewController:self cancelActionTitle:@"确定" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:^(UIAlertAction * _Nonnull action) {
            [weakSelf logout];
        } confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:nil];
    }
}

- (void)socketMananger_didConnectStatusChange:(PLVSocketConnectStatus)connectStatus {
    if (connectStatus == PLVSocketConnectStatusReconnect) {
        self.socketReconnecting = YES;
        [PLVHCUtils showToastInWindowWithMessage:@"聊天室重连中"];
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            [PLVHCUtils showToastInWindowWithMessage:@"聊天室重连成功"];
        }
    }
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
    if (starClass) { //开始上课
        [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {
            if (granted) { // 再次确保有【麦克风&摄像头】权限
                [weakSelf.toolbarAreaView setClassButtonEnable:NO];
                [[PLVHCLiveroomViewModel sharedViewModel] startClass];
            } else { // 触发无摄像头麦克风权限回调通知UI
                NSString *msg = [NSString stringWithFormat:@"需要获取您的音视频权限，请前往设置"];
                [PLVAuthorizationManager showAlertWithTitle:@"提示" message:msg viewController:weakSelf];
            }
        }];
    } else { //结束课程
        [[PLVHCLiveroomViewModel sharedViewModel] finishClassIsForced:NO];
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
    [[PLVHCPermissionEvent sharedInstance] sendRaiseHandMessageWithUserId:userId];
}

#pragma mark PLVHCSettingSheetDelegate

- (void)didChangeMicrophoneSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet enable:(BOOL)enable {
    [self.linkMicPresenter openLocalUserMic:enable];
    if (self.isShowToast) {
        if (enable) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenMic message:@"已开启麦克风"];
        } else {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseMic message:@"已关闭麦克风"];
        }
    }
    [self.linkMicAreaView linkMicAreaViewEnableLocalMic:enable];
}

- (void)didChangeCameraSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet enable:(BOOL)enable {
    [self.linkMicPresenter openLocalUserCamera:enable];
    if (self.isShowToast) {
        if (enable) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenCamera message:@"已开启摄像头"];
        } else {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseCamera message:@"已关闭摄像头"];
        }
    }
    [self.linkMicAreaView linkMicAreaViewEnableLocalCamera:enable];
}

- (void)didChangeCameraDirectionSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet front:(BOOL)isFront {
    [self.linkMicPresenter switchLocalUserCamera:isFront];
    [self.linkMicAreaView linkMicAreaViewSwitchLocalCameraFront:isFront];
}

- (void)didChangeFullScreenSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet fullScreen:(BOOL)fullScreen {
    self.fullscreen = fullScreen;
    self.linkMicAreaView.hidden = fullScreen; // 全屏模式下隐藏连麦窗口
    [self.view setNeedsLayout];
    NSString *fullScreenMessage = fullScreen ? @"已开启全屏模式" : @"退出全屏模式";
    [PLVHCUtils showToastInWindowWithMessage:fullScreenMessage];
}

- (void)didTapLogoutButtonInSettingSheet:(PLVHCSettingSheet *)settingSheet {
    [[PLVHCLiveroomViewModel sharedViewModel] exitClassroom];
}

#pragma mark PLVHCDocumentSheetDelegate

- (void)documentSheet:(PLVHCDocumentSheet *)documentSheet didSelectModel:(nonnull PLVDocumentModel *)model {
    if (self.documentMinimumSheet.isMaxMinimumNum) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_DocumentCountOver message:@"只支持同时打开5个文件"];
    } else {
        [self.documentAreaView openPptWithAutoId:model.autoId];
        [self.toolbarAreaView clearAllButtonSelected];
    }
}

#pragma mark PLVHCDocumentMinimumSheetDelegate

- (void)documentMinimumSheet:(PLVHCDocumentMinimumSheet *)documentMinimumSheet didCloseItemModel:(PLVHCDocumentMinimumModel *)model {
    [self.documentAreaView operateContainerWithContainerId:model.containerId close:YES];
}

- (void)documentMinimumSheet:(PLVHCDocumentMinimumSheet *)documentMinimumSheet didSelectItemModel:(PLVHCDocumentMinimumModel *)model {
    [self.documentAreaView operateContainerWithContainerId:model.containerId close:NO];
}

#pragma mark PLVHCDocumentAreaViewDelegate

- (void)documentAreaViewDidFinishLoading:(PLVHCDocumentAreaView *)documentAreaView {
    if (_settingView) { // 防止画笔工具显示在设置页面上
        return;
    }
    [self showBrushToolbarView:YES];
}

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshBrushPermission:(BOOL)permission userId:(nonnull NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]){
        return;
    }
    
    if ([[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId isEqualToString:userId]) { // 自己
        self.brushToolBarView.haveBrushPermission = permission;
        [self showBrushToolbarView:permission];
        
        if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
            NSString *message = permission ? @"老师已授予你画笔权限" : @"老师已回收你的画笔权限";
            PLVHCToastType type = permission ? PLVHCToastTypeIcon_AuthBrush : PLVHCToastTypeIcon_CancelAuthBrush;
            [PLVHCUtils showToastWithType:type message:message];
        }
    } else { // 其他人
        
    }
    
    [self.linkMicPresenter updateUserBrushAuthWithUserId:userId auth:permission];
}

/// 清除学生自己的画笔权限
- (void)removeSelfPaintBrushAuth {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType  == PLVRoomUserTypeTeacher) {
        return;
    }
    
    [self.documentAreaView removeSelfPaintBrushAuth];
}

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshBrushToolStatusWithJsonDict:(NSDictionary *)jsonDict {
    [self.brushToolBarView updateBrushToolStatusWithDict:jsonDict];
}

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshPptContainerTotal:(NSInteger)total {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        [self.documentMinimumSheet refreshPptContainerTotal:total];
    }
}

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshMinimizeContainerDataArray:(nonnull NSArray<PLVHCDocumentMinimumModel *> *)dataArray {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        [self showDocumentMinimumSheet:dataArray.count > 0];
        [self.documentMinimumSheet refreshMinimizeContainerDataArray:dataArray];
    }
}

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didChangeApplianceType:(PLVContainerApplianceType)applianceType {
    [self.brushToolSelectSheet updateBrushToolApplianceType:applianceType];
}

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didChangeStrokeHexColor:(NSString *)strokeHexColor {
    [self.brushToolBarView updateSelectColor:strokeHexColor];
    [self.brushColorSelectSheet updateSelectColor:strokeHexColor];
}

- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didChangeResetZoomButtonShow:(BOOL)show {
    [self showResetZoomButton:show];
}

#pragma mark PLVHCBrushToolbarViewDelegate

- (void)brushToolBarViewDidTapDeleteButton:(PLVHCBrushToolBarView *)brushToolBarView {
    [self.documentAreaView doDelete];
}

- (void)brushToolBarViewDidTapRevokeButton:(PLVHCBrushToolBarView *)brushToolBarView {
    [self.documentAreaView doUndo];
}

- (void)brushToolBarViewDidTapColorButton:(PLVHCBrushToolBarView *)brushToolBarView {
    if (self.brushColorSelectSheet.superview) {
        [self.brushColorSelectSheet dismiss];
    } else {
        [self.brushToolSelectSheet dismiss];
        [self.brushColorSelectSheet showInView:self.view];
    }
}

- (void)brushToolBarViewDidTapToolButton:(PLVHCBrushToolBarView *)brushToolBarView {
    if (self.brushToolSelectSheet.superview) {
        [self.brushToolSelectSheet dismiss];
    } else {
        [self.brushColorSelectSheet dismiss];
        [self.brushToolSelectSheet showInView:self.view];
    }
}

#pragma mark  PLVHCBrushToolSelectSheetDelegate

- (void)brushToolSelectSheet:(PLVHCBrushToolSelectSheet *)brushToolSelectSheet didSelectToolType:(PLVHCBrushToolType)toolType selectImage:(UIImage *)selectImage localTouch:(BOOL)localTouch{
    [self.brushToolBarView updateSelectToolType:toolType selectImage:selectImage];
    if (localTouch) { // 本地点击才需要发送JS事件
        [self.documentAreaView updateSelectToolType:toolType];
    }
}

#pragma mark  PLVHCBrushColorSelectSheetDelegate

- (void)brushColorSelectSheet:(PLVHCBrushColorSelectSheet *)brushColorSelectSheet didSelectColor:(NSString *)color localTouch:(BOOL)localTouch{
    [self.brushToolBarView updateSelectColor:color];
    if (localTouch) { // 本地点击才需要发送JS事件
        [self.documentAreaView updateSelectColor:color];
    }
}

#pragma mark PLVHCPermissionEventDelegate

- (void)permissionEvent:(PLVHCPermissionEvent *)permissionEvent didGrantCupWithUserId:(NSString *)userId {
    NSString *nickname = [self.linkMicPresenter nicknameAndUpdateUserGrantCupCountWithUserId:userId];
    [self.grantCupView showInView:self.view nickName:nickname];
}

- (void)permissionEvent:(PLVHCPermissionEvent *)permissionEvent didChangeRaiseHandStatus:(BOOL)raiseHandStatus userId:(NSString *)userId raiseHandCount:(NSInteger)raiseHandCount{
    [self.toolbarAreaView toolbarAreaViewRaiseHand:raiseHandStatus userId:userId count:raiseHandCount];
    [self.memberSheet handUpWithUserId:userId count:raiseHandCount handUp:raiseHandStatus];
}

#pragma mark PLVHCLiveroomViewModelDelegate

- (void)liveroomViewModelStartClass:(PLVHCLiveroomViewModel *)viewModel success:(BOOL)success {
    [self.toolbarAreaView setClassButtonEnable:YES];
    if (success) { //开始上课
        [self startClass];
        [PLVHCUtils showToastInWindowWithMessage:@"课程开始"];
    }
}

- (void)liveroomViewModelFinishClass:(PLVHCLiveroomViewModel *)viewModel success:(BOOL)success {
    [self.toolbarAreaView setClassButtonEnable:YES];
    if (success) {//下课
        [self finishClass];
    }
}

- (void)liveroomViewModelReadyExitClassroom:(PLVHCLiveroomViewModel *)viewModel {
    [self logout];
}

- (void)liveroomViewModelDelayInClass:(PLVHCLiveroomViewModel *)viewModel {
    [self.statusbarAreaView delayStartClass];
}

- (void)liveroomViewModelStudentAnswerJoinLinkMic:(PLVHCLiveroomViewModel *)viewModel {
    [self.linkMicPresenter answerForJoinResponse];
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

- (void)closeAllLinkMicUserInMemberSheet:(PLVHCMemberSheet *)memberSheet {
    BOOL success = [self.linkMicPresenter closeAllLinkMicUser];
    if (success) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_AllStepDown message:@"已全体下台"];
    }
}

- (void)muteAllLinkMicUserMicInMemberSheet:(PLVHCMemberSheet *)memberSheet
                                      mute:(BOOL)mute {
    [self.linkMicPresenter muteAllLinkMicUserMicrophone:mute];
    if (mute) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_MicAllAanned message:@"已全体禁麦"];
    } else {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenMic message:@"已取消全体禁麦"];
    }
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

- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView enableLocalMic:(BOOL)enable {
    [self.settingSheet microphoneSwitchChange:enable];
}

- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView enableLocalCamera:(BOOL)enable {
    [self.settingSheet cameraSwitchChange:enable];
}

- (void)plvHCLinkMicAreaView:(PLVHCLinkMicAreaView *)linkMicAreaView switchLocalCameraFront:(BOOL)switchFront {
    [self.settingSheet cameraDirectionChange:switchFront];
}

#pragma mark PLVHCStatusbarAreaViewDelegate

- (void)statusbarAreaViewDidForcedFinishClass:(PLVHCStatusbarAreaView *)areaView {
    [[PLVHCLiveroomViewModel sharedViewModel] finishClassIsForced:YES];
}

#pragma mark PLVHCChatroomSheetDelegate

- (void)chatroomSheet:(PLVHCChatroomSheet *)chatroomSheet didChangeNewMessageCount:(NSUInteger)newMessageCount {
    if (newMessageCount > 0) {
        [self.toolbarAreaView toolbarAreaViewReceiveNewMessage];
    }
}

@end
