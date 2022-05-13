//
//  PLVSAStreamerHomeView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStreamerHomeView.h"

// 工具类
#import "PLVSAUtils.h"

// UI
#import "PLVSAShadowMaskView.h"
#import "PLVSAToolbarAreaView.h"
#import "PLVSAChatroomAreaView.h"
#import "PLVSAChannelInfoSheet.h"
#import "PLVSAMoreInfoSheet.h"
#import "PLVSASlideRightTipsView.h"
#import "PLVSABitRateSheet.h"
#import "PLVSAStatusbarAreaView.h"
#import "PLVSAMemberSheet.h"
#import "PLVSALinkMicTipView.h"
#import "PLVSACameraAndMicphoneStateView.h"
#import "PLVSALinkMicLayoutSwitchGuideView.h"
#import "PLVSALinkMicWindowsView.h"

// 模块
#import "PLVRoomDataManager.h"
#import "PLVLinkMicOnlineUser.h"

static NSString * const kUserDefaultShowedSlideRightTips = @"UserDefaultShowedSlideRightTips";

@interface PLVSAStreamerHomeView ()<
UIScrollViewDelegate,
PLVSABitRateSheetDelegate,
PLVSAChatroomAreaViewDelegate,
PLVAStatusbarAreaViewDelegate,
PLVSAToolbarAreaViewDelegate,
PLVSAMoreInfoSheetDelegate,
PLVSABitRateSheetDelegate,
PLVSAMemberSheetDelegate,
PLVSALinkMicTipViewDelegate
>
/// view hierarchy
///
/// (UIView) superview
///  └── (PLVSAStreamerHomeView) self (lowest)
///    ├── (UIScrollView) scrollView
///    │     ├── (PLVSALinkMicWindowsView) linkMicWindowsView
///    │     │    ├── (PLVSAShadowMaskView) shadowMaskView
///    │     ├── (UIView) homePageView
///    │     │    ├── (PLVSAStatusbarAreaView) statusbarAreaView
///    │     │    ├── (PLVSAToolbarAreaView) toolbarAreaView
///    │     │    ├── (PLVSAChatroomAreaView) chatroomAreaView
///    │     │    ├── (PLVSASlideRightTipsView) slideRightTipsView
///    │     │    └── (PLVSACameraAndMicphoneStateView) cameraAndMicphoneStateView
///    │     └── (PLVSALinkMicTipView) linkMicTipView
///    └── (UIButton) closeButton(highest)
@property (nonatomic, weak) PLVSALinkMicWindowsView *linkMicWindowsView; // 实际由主页linkMicAreaView持有的连麦窗口视图
@property (nonatomic, strong) UIButton *closeButton; // 关闭直播间按钮
@property (nonatomic, strong) UIScrollView *scrollView; // 底部滑动视图
@property (nonatomic, strong) UIView *homePageView; // 背景蒙版视图
@property (nonatomic, strong) PLVSAShadowMaskView *shadowMaskView; // 渐变遮罩视图
@property (nonatomic, strong) PLVSASlideRightTipsView *slideRightTipsView; // 右滑清屏新手引导视图
@property (nonatomic, strong) PLVSAStatusbarAreaView *statusbarAreaView; //顶部状态栏视图
@property (nonatomic, strong) PLVSAToolbarAreaView *toolbarAreaView; // 底部工具类视图
@property (nonatomic, strong) PLVSAChatroomAreaView *chatroomAreaView; // 聊天室视图
@property (nonatomic, strong) PLVSAChannelInfoSheet *channelInfoSheet; // 直播信息弹层
@property (nonatomic, strong) PLVSAMoreInfoSheet *moreInfoSheet; // 更多信息弹层
@property (nonatomic, strong) PLVSABitRateSheet *bitRateSheet; // 清晰度选择面板
@property (nonatomic, strong) PLVSAMemberSheet *memberSheet; // 成员列表弹层
@property (nonatomic, strong) PLVSALinkMicTipView *linkMicTipView; // 连麦提示视图
@property (nonatomic, strong) PLVSACameraAndMicphoneStateView *cameraAndMicphoneStateView; // 摄像头与麦克风状态视图
@property (nonatomic, strong) PLVSALinkMicLayoutSwitchGuideView *layoutSwitchGuideView; // 布局切换新手引导

/// 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *localOnlineUser; // 本地用户模型，使用弱引用
@property (nonatomic, assign) BOOL hadShowedLayoutSwitchGuide; // 是否显示过布局切换新手引导
@property (nonatomic, assign) BOOL showingLayoutSwitchGuide; // 是否正在显示布局切换新手引导
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList;
@property (nonatomic, assign) NSInteger userCount;

@end

@implementation PLVSAStreamerHomeView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithLocalOnlineUser:(PLVLinkMicOnlineUser *)localOnlineUser
                     linkMicWindowsView:(PLVSALinkMicWindowsView *)linkMicWindowsView {
    self = [super init];
    if (self) {
        self.hadShowedLayoutSwitchGuide = NO;
        self.showingLayoutSwitchGuide = NO;
        [self setupLocalOnlineUser:localOnlineUser];
        [self setupUIWithLinkMicWindowsView:linkMicWindowsView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    
    CGFloat left = [PLVSAUtils sharedUtils].areaInsets.left;
    CGFloat right = [PLVSAUtils sharedUtils].areaInsets.right;
    CGFloat top = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat marginTop = isLandscape ? 16 : 2;
    CGFloat marginLeft = isLandscape ? 36 : 2;
    CGFloat toolbarAreaViewHeight = isLandscape ? 56 : 60;
    CGFloat chatroomWidthScale = (isLandscape ? 0.3 : 0.65);
    CGFloat chatroomHeightScale = (isLandscape ? 0.42 : 0.28);
    CGFloat linkMicWindowHeight = (isLandscape ? (self.bounds.size.height - top - 52 - 44 - bottom) : 280);
    CGFloat cameraAndMicphoneStateViewTop = 5;
    CGFloat linkMicWindowY = (isLandscape ? 44 : 78);
    CGFloat toolbarViewMarginRight = isLandscape ? 36 : 8;
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    if (isPad) {
        marginTop = 12;
        marginLeft = 18;
        toolbarViewMarginRight = 24;
        toolbarAreaViewHeight = 72;
        chatroomWidthScale = 0.41;
        chatroomHeightScale = 0.24;
        cameraAndMicphoneStateViewTop = 20;
        linkMicWindowHeight = 0.74 * self.bounds.size.width;
        linkMicWindowY = 92;
        if (isLandscape) {
            linkMicWindowHeight = self.bounds.size.height / 2.0;
            linkMicWindowY = self.bounds.size.height / 4.0 - top;
        }
    }
    
    CGFloat closeButtonWitdh = isLandscape ? 32 : 44;
    self.closeButton.frame = CGRectMake(selfSize.width - closeButtonWitdh - right - marginLeft, top + marginTop, closeButtonWitdh, closeButtonWitdh);
    
    BOOL first = CGRectEqualToRect(self.scrollView.frame, CGRectZero);
    self.scrollView.frame = self.bounds;
    self.scrollView.contentSize = CGSizeMake(selfSize.width * 2, selfSize.height);
    self.shadowMaskView.frame = self.bounds;
    
    // 实际显示时，会在ShowNewWaitUserAdded方法内，根据当前在第几屏更新x、y
    CGFloat linkMicTipRightPadding = isLandscape ? 32 : 8;
    self.linkMicTipView.frame = CGRectMake(selfSize.width - 214 - linkMicTipRightPadding - right , selfSize.height - bottom - 32 - 20, 214, 32);
    
    CGRect pageRect = self.scrollView.bounds;
    pageRect.origin.x = self.scrollView.bounds.size.width;
    self.homePageView.frame = pageRect;
    
    self.scrollView.contentOffset = CGPointMake(selfSize.width, 0);
    if (first) {
        self.linkMicWindowsView.frame = pageRect;
    } else {
        CGRect linkMicWindowFrame = pageRect;
        linkMicWindowFrame.origin.x = self.scrollView.contentOffset.x;
        self.linkMicWindowsView.frame = linkMicWindowFrame;
    }
   
    self.statusbarAreaView.frame = CGRectMake(left, top, selfSize.width - left - right, 72);
    self.cameraAndMicphoneStateView.frame = CGRectMake(left, CGRectGetMaxY(self.statusbarAreaView.frame) + cameraAndMicphoneStateViewTop, selfSize.width - left - right, 36);
    self.toolbarAreaView.frame = CGRectMake(left, selfSize.height - bottom - toolbarAreaViewHeight, selfSize.width - left - right, toolbarAreaViewHeight);
   
    CGFloat chatroomWidth = selfSize.width * chatroomWidthScale;
    CGFloat chatroomHeight = selfSize.height * chatroomHeightScale;
    self.chatroomAreaView.frame = CGRectMake(left, CGRectGetMinY(self.toolbarAreaView.frame) - chatroomHeight, chatroomWidth, chatroomHeight);
    self.slideRightTipsView.frame = self.bounds;
    self.layoutSwitchGuideView.frame = CGRectMake(selfSize.width - toolbarViewMarginRight - 36 * 4 - 12 * 3 - 50 - right, CGRectGetMinY(self.toolbarAreaView.frame) - 62, 107, 62);
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (NSInteger i = self.subviews.count - 1; i >= 0; i--) { // 从后往前遍历自己的子控件，将事件传递给子控件
        UIView *childView = self.subviews[i];
        CGPoint childPoint = [self convertPoint:point toView:childView]; // 把当前控件上的坐标系转换成子控件上的坐标系
        UIView *fitView = [childView hitTest:childPoint withEvent:event];
        if (fitView == self.homePageView) { // homePageView会阻挡底下了连麦视图的手势，所以绕过homePageView把响应链交给底下的连麦视图
            for (NSInteger j = self.linkMicWindowsView.subviews.count - 1; j >= 0; j--) {
                UIView *grandChildren = self.linkMicWindowsView.subviews[j];
                CGPoint grandChildrenPoint = [self convertPoint:point toView:grandChildren];
                fitView = [grandChildren hitTest:grandChildrenPoint withEvent:event];
                if (fitView) {
                    return fitView;
                }
            }
        }
        if (fitView) { // 寻找到响应事件的子控件
            return fitView;
        }
    }
    // 循环结束,表示没有比自己更合适的view
    return self;
}

#pragma mark - [ Public Method ]

- (void)startClass:(BOOL)start {
    [self.statusbarAreaView startClass:start];
    [self.moreInfoSheet startClass:start];
}

- (void)setPushStreamDuration:(NSTimeInterval)duration {
    self.statusbarAreaView.duration = duration;
}

- (void)setNetworkQuality:(PLVBLinkMicNetworkQuality)netState {
    self.statusbarAreaView.netState = (PLVSAStatusBarNetworkQuality)netState;
}

- (void)updateUserList:(NSArray <PLVChatUser *> *)userList
             userCount:(NSInteger)userCount
           onlineCount:(NSInteger)onlineCount {
    self.statusbarAreaView.onlineNum = userCount;
    
    self.userList = userList;
    self.userCount = userCount;
    [_memberSheet updateUserList:userList userCount:userCount onlineCount:onlineCount];
    
}

- (void)setLocalMicVolume:(CGFloat)micVolume {
    self.statusbarAreaView.localMicVolume = micVolume;
}

- (void)setCurrentMicOpen:(BOOL)micOpen {
    self.statusbarAreaView.currentMicOpen = micOpen;
}

- (void)setLinkMicButtonSelected:(BOOL)selected {
    self.toolbarAreaView.channelLinkMicOpen = selected;
}

- (void)showMemberBadge:(BOOL)show {
    if ([self canManagerLinkMic]) {
        [self.toolbarAreaView showMemberBadge:show];
    }
}

- (void)showNewWaitUserAdded {
    if (![self canManagerLinkMic]) {
        return;
    }
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat padding = isPad ? 24 : ([PLVSAUtils sharedUtils].isLandscape ? 36 : 8);
    CGRect frame = self.linkMicTipView.frame;
    CGSize selfSize = self.bounds.size;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    CGFloat right = [PLVSAUtils sharedUtils].areaInsets.right + padding;
    if (self.scrollView.contentOffset.x == 0) {
        frame.origin.x = selfSize.width - frame.size.width - right;
        frame.origin.y = selfSize.height - bottom  - 20 - frame.size.height ;
    } else {
        frame.origin.x = selfSize.width *2 - frame.size.width - right;
        frame.origin.y = CGRectGetMinY(self.toolbarAreaView.frame) - frame.size.height - 16;
    }
    
    self.linkMicTipView.frame = frame;
    [self.linkMicTipView show];
}

- (void)addExternalLinkMicGuideView:(UIView *)guideView {
    [self.homePageView addSubview:guideView];
}

- (void)updateHomeViewOnlineUserCount:(NSInteger)onlineUserCount {
    [self.toolbarAreaView updateOnlineUserCount:onlineUserCount];
    // 显示布局切换新手引导，当前连麦人数大于1时显示视图
    [self showLayoutSwitchGuideWithUserCount:onlineUserCount];
}

- (void)changeFlashButtonSelectedState:(BOOL)selectedState{
    [self.moreInfoSheet changeFlashButtonSelectedState:selectedState];
}

- (void)changeScreenShareButtonSelectedState:(BOOL)selectedState{
    [self.moreInfoSheet changeScreenShareButtonSelectedState:selectedState];
}

#pragma mark - [ Private Method ]

- (void)setupUIWithLinkMicWindowsView:(PLVSALinkMicWindowsView *)linkMicWindowsView {
    self.linkMicWindowsView = linkMicWindowsView;
    
    [self addSubview:self.scrollView];
    [self insertSubview:self.closeButton aboveSubview:self.scrollView];

    // 迁移连麦窗口到homeView上
    [self.linkMicWindowsView removeFromSuperview];
    [self.scrollView insertSubview:self.linkMicWindowsView atIndex:0];
    
    [self.linkMicWindowsView addSubview:self.shadowMaskView];
    [self.scrollView addSubview:self.homePageView];
    [self.scrollView addSubview:self.linkMicTipView];
    
    [self.homePageView addSubview:self.statusbarAreaView];
    [self.homePageView addSubview:self.toolbarAreaView];
    [self.homePageView addSubview:self.chatroomAreaView];
    [self.homePageView addSubview:self.slideRightTipsView];
    [self.homePageView addSubview:self.cameraAndMicphoneStateView];
    [self.homePageView addSubview:self.layoutSwitchGuideView];
}

- (void)setupLocalOnlineUser:(PLVLinkMicOnlineUser *)localOnlineUser {
    self.localOnlineUser = localOnlineUser;
    
    [self.cameraAndMicphoneStateView updateCameraOpen:localOnlineUser.currentCameraOpen micphoneOpen:localOnlineUser.currentMicOpen];
    
    __weak typeof(self) weakSelf = self;
    self.localOnlineUser.volumeChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [weakSelf setLocalMicVolume:onlineUser.currentVolume];
    };
    
    self.localOnlineUser.cameraOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        weakSelf.moreInfoSheet.currentCameraOpen = onlineUser.currentCameraOpen;
        [weakSelf.cameraAndMicphoneStateView updateCameraOpen:onlineUser.currentCameraOpen micphoneOpen:onlineUser.currentMicOpen];
    };
    
    self.localOnlineUser.micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        weakSelf.moreInfoSheet.currentMicOpen = onlineUser.currentMicOpen;
        [weakSelf.cameraAndMicphoneStateView updateCameraOpen:onlineUser.currentCameraOpen micphoneOpen:onlineUser.currentMicOpen];
    };
}

/// 设置更多弹窗数据
- (void)setupMoreInfoSheetData {
    // 初始化
    self.moreInfoSheet.currentCameraOpen = self.localOnlineUser.currentCameraOpen;
    self.moreInfoSheet.currentMicOpen = self.localOnlineUser.currentMicOpen;
    self.moreInfoSheet.currentCameraFront = self.localOnlineUser.currentCameraFront;
    self.moreInfoSheet.closeRoom = self.chatroomAreaView.closeRoom;
    self.moreInfoSheet.currentCameraMirror = self.localOnlineUser.localVideoMirrorMode == PLVBRTCVideoMirrorMode_Auto;
    [self.moreInfoSheet changeScreenShareButtonSelectedState:self.localOnlineUser.currentScreenShareOpen];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewCurrentQuality:)]) {
        self.moreInfoSheet.streamQuality = [self.delegate streamerHomeViewCurrentQuality:self];
    }
}

- (void)showLayoutSwitchGuideWithUserCount:(NSInteger)userCount {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeGuest || userCount < 2) {
        self.showingLayoutSwitchGuide = NO;
        [self.layoutSwitchGuideView showLinkMicLayoutSwitchGuide:NO];
        return;
    }
    
    if (self.hadShowedLayoutSwitchGuide &&
        !self.showingLayoutSwitchGuide) {
        return;
    }
    
    self.hadShowedLayoutSwitchGuide = YES;
    self.showingLayoutSwitchGuide = YES;
    [self.layoutSwitchGuideView showLinkMicLayoutSwitchGuide:YES];
}

/// 讲师、助教、管理员可以管理连麦操作
- (BOOL)canManagerLinkMic {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark Getter & Setter

- (PLVSAShadowMaskView *)shadowMaskView {
    if (!_shadowMaskView) {
        _shadowMaskView = [[PLVSAShadowMaskView alloc] init];
    }
    return _shadowMaskView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_close"];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _scrollView;
}

- (UIView *)homePageView {
    if (!_homePageView) {
        _homePageView = [[UIView alloc] init];
    }
    return _homePageView;
}

- (PLVSASlideRightTipsView *)slideRightTipsView {
    if (!_slideRightTipsView) {
        _slideRightTipsView = [[PLVSASlideRightTipsView alloc] init];
        _slideRightTipsView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.5);
        _slideRightTipsView.hidden = YES;
        __block typeof(self) blockSelf = self;
        _slideRightTipsView.closeButtonHandler = ^{
            [blockSelf->_slideRightTipsView removeFromSuperview];
            blockSelf.scrollView.scrollEnabled = YES;
        };
    }
    return _slideRightTipsView;
}

- (PLVSAStatusbarAreaView *)statusbarAreaView {
    if (!_statusbarAreaView) {
        _statusbarAreaView = [[PLVSAStatusbarAreaView alloc] init];
        _statusbarAreaView.delegate = self;
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        _statusbarAreaView.teacherName = roomData.roomUser.viewerName;
    }
    return _statusbarAreaView;
}

- (PLVSAToolbarAreaView *)toolbarAreaView {
    if (!_toolbarAreaView) {
        _toolbarAreaView = [[PLVSAToolbarAreaView alloc] init];
        _toolbarAreaView.delegate = self;
    }
    return _toolbarAreaView;
}

- (PLVSAChatroomAreaView *)chatroomAreaView {
    if (!_chatroomAreaView) {
        _chatroomAreaView = [[PLVSAChatroomAreaView alloc] init];
        _chatroomAreaView.delegate = self;
    }
    return _chatroomAreaView;
}

- (PLVSAChannelInfoSheet *)channelInfoSheet {
    if (!_channelInfoSheet) {
        CGFloat heightScale = 0.285;
        CGFloat widthScale = 0.318;
        heightScale = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 0.301 : heightScale;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        
        _channelInfoSheet = [[PLVSAChannelInfoSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    }
    return _channelInfoSheet;
}

- (PLVSAMoreInfoSheet *)moreInfoSheet {
    if (!_moreInfoSheet) {
        CGFloat heightScale = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 0.246 : 0.34;
        CGFloat widthScale = 0.37;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        
        _moreInfoSheet = [[PLVSAMoreInfoSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _moreInfoSheet.delegate = self;
    }
    return _moreInfoSheet;
}

- (PLVSABitRateSheet *)bitRateSheet {
    if (!_bitRateSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.233 : 0.285;
        CGFloat widthScale = 0.23;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _bitRateSheet = [[PLVSABitRateSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _bitRateSheet.delegate = self;
        PLVResolutionType type = [self.delegate streamerHomeViewCurrentQuality:self];
        [_bitRateSheet setupBitRateOptionsWithCurrentBitRate:type];
    }
    return _bitRateSheet;
}

- (PLVSAMemberSheet *)memberSheet {
    if (!_memberSheet) {
        _memberSheet = [[PLVSAMemberSheet alloc] initWithUserList:self.userList userCount:self.userCount];
        _memberSheet.delegate = self;
        
        __weak typeof(self) weakSelf = self;
        _memberSheet.didCloseSheet = ^{
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(streamerHomeViewDidMemberSheetDismiss:)]) {
                [weakSelf.delegate streamerHomeViewDidMemberSheetDismiss:weakSelf];
            }
        };
    }
    return _memberSheet;
}

- (PLVSALinkMicTipView *)linkMicTipView {
    if (!_linkMicTipView) {
        _linkMicTipView = [[PLVSALinkMicTipView alloc] init];
        _linkMicTipView.delegate = self;
        _linkMicTipView.alpha = 0.0;
    }
    return _linkMicTipView;
}

- (PLVSACameraAndMicphoneStateView *)cameraAndMicphoneStateView {
    if (!_cameraAndMicphoneStateView) {
        _cameraAndMicphoneStateView = [[PLVSACameraAndMicphoneStateView alloc] init];
    }
    return _cameraAndMicphoneStateView;
}

- (PLVSALinkMicLayoutSwitchGuideView *)layoutSwitchGuideView {
    if (!_layoutSwitchGuideView) {
        _layoutSwitchGuideView = [[PLVSALinkMicLayoutSwitchGuideView alloc] init];
        _layoutSwitchGuideView.hidden = YES;
    }
    return _layoutSwitchGuideView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeButtonAction:(id)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapCloseButton:)]){
        [self.delegate streamerHomeViewDidTapCloseButton:self];
    }
}

#pragma mark - Delegate

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect linkMicWindowFrame = self.linkMicWindowsView.frame;
    linkMicWindowFrame.origin.x = scrollView.contentOffset.x;
    self.linkMicWindowsView.frame = linkMicWindowFrame;
}

#pragma mark PLVAStatusbarAreaViewDelegate

- (void)statusbarAreaViewDidTapChannelInfoButton:(PLVSAStatusbarAreaView *)statusBarAreaView {
    [self.channelInfoSheet updateChannelInfoWithData:[PLVRoomDataManager sharedManager].roomData];
    [self.channelInfoSheet showInView:self];
}

#pragma mark PLVSAToolbarAreaViewDelegate

- (void)toolbarAreaViewDidLinkMicLayoutSwitchButton:(PLVSAToolbarAreaView *)toolbarAreaView layoutSwitchButtonSelected:(BOOL)selected {
    [self.linkMicWindowsView switchLinkMicWindowsLayoutSpeakerMode:selected linkMicWindowMainSpeaker:nil];
    [self showLayoutSwitchGuideWithUserCount:0];
}

- (void)toolbarAreaViewDidTapMoreButton:(PLVSAToolbarAreaView *)toolbarAreaView {
    [self setupMoreInfoSheetData];
    [self.moreInfoSheet showInView:self];
}

- (void)toolbarAreaViewDidTapLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected {
    
    BOOL channelLinkMicOpen = NO;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewChannelLinkMicOpen:)]) {
        [self.delegate streamerHomeViewChannelLinkMicOpen:self];
    }
    //判断连麦按钮状态是否与实际连麦与否的情况相符，若符合，正常操作连麦/结束连麦，若不符，直接调用homeView接口修改linkMic按钮状态
    // 当前连麦按钮显示已连麦时的校验
    if (selected &&
        channelLinkMicOpen) {
        [self setLinkMicButtonSelected:NO];
        return;
    }
    // 当前连麦按钮显示未连麦时的校验
    if (!selected &&
        channelLinkMicOpen) {
        [self setLinkMicButtonSelected:YES];
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapLinkMicButton:linkMicButtonSelected:)]) {
        [self.delegate streamerHomeViewDidTapLinkMicButton:self linkMicButtonSelected:selected];
    }
}

- (void)toolbarAreaViewDidTapMemberButton:(PLVSAToolbarAreaView *)toolbarAreaView {
    [self.memberSheet showInView:self];
}

#pragma mark PLVSAMoreInfoSheetDelegate

- (void)moreInfoSheetDidTapCameraBitRateButton:(PLVSAMoreInfoSheet *)moreInfoSheet{
    [self.bitRateSheet showInView:self];
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeMicOpen:(BOOL)micOpen {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeMicOpen:)]) {
        [self.delegate streamerHomeView:self didChangeMicOpen:micOpen];
    }
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCameraOpen:(BOOL)cameraOpen {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeCameraOpen:)]) {
        [self.delegate streamerHomeView:self didChangeCameraOpen:cameraOpen];
    }
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCameraFront:(BOOL)cameraFront {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidChangeCameraFront:)]) {
        [self.delegate streamerHomeViewDidChangeCameraFront:self];
    }
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeFlashOpen:(BOOL)flashOpen{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeFlashOpen:)]) {
        [self.delegate streamerHomeView:self didChangeFlashOpen:flashOpen];
    }
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeMirrorOpen:(BOOL)mirrorOpen {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeMirrorOpen:)]) {
        [self.delegate streamerHomeView:self didChangeMirrorOpen:mirrorOpen];
    }
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeScreenShareOpen:(BOOL)screenShareOpen {
    if (screenShareOpen && !self.localOnlineUser.currentCameraOpen) {
        [self.moreInfoSheet changeScreenShareButtonSelectedState:NO];
        [PLVSAUtils showToastInHomeVCWithMessage:@"请先打开摄像头"];
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeScreenShareOpen:)]) {
        [self.delegate streamerHomeView:self didChangeScreenShareOpen:screenShareOpen];
    }
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCloseRoom:(BOOL)closeRoom {
    self.chatroomAreaView.closeRoom = closeRoom;
}

#pragma mark PLVSABitRateSheetDelegate

- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet bitRateButtonClickWithBitRate:(PLVResolutionType)bitRate {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeResolutionType:)]) {
        [self.delegate streamerHomeView:self didChangeResolutionType:bitRate];
        self.moreInfoSheet.streamQuality = bitRate;
    }
}

#pragma mark PLVSAChatroomAreaViewDelegate

- (void)chatroomAreaView_showSlideRightView {
    BOOL showedSlideRightTipsView = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultShowedSlideRightTips];
    if (!showedSlideRightTipsView) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserDefaultShowedSlideRightTips];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.slideRightTipsView.hidden = NO;
        self.scrollView.scrollEnabled = NO;
    }
}

- (void)chatroomAreaView:(PLVSAChatroomAreaView *)chatroomAreaView DidChangeCloseRoom:(BOOL)closeRoom {
    self.moreInfoSheet.closeRoom = closeRoom;
}

#pragma mark PLVSAMemberSheetDelegate

- (void)bandUsersInMemberSheet:(PLVSAMemberSheet *)memberSheet withUserId:(NSString *)userId banned:(BOOL)banned {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(bandUsersInStreamerHomeView:withUserId:banned:)]) {
        [self.delegate bandUsersInStreamerHomeView:self withUserId:userId banned:banned];
    }
}

- (void)kickUsersInMemberSheet:(PLVSAMemberSheet *)memberSheet withUserId:(NSString *)userId {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(kickUsersInStreamerHomeView:withUserId:)]) {
        [self.delegate kickUsersInStreamerHomeView:self withUserId:userId];
    }
}

#pragma mark PLVSALinkMicTipViewDelegate
- (void)linkMicTipViewDidTapCheckButton:(PLVSALinkMicTipView *)linkMicTipView {
    [self.linkMicTipView dissmiss];
    // 回到第二屏
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.bounds.size.width, 0)];
    // 显示成员列表
    [self.memberSheet showInView:self];
}
@end
