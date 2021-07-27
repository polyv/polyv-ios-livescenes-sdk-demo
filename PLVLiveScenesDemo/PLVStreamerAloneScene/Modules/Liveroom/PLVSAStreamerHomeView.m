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
#import "PLVSALinkMicGuiedView.h"
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
///    │     ├── (UIView) homePageView
///    │     │    ├── (PLVSAStatusbarAreaView) statusbarAreaView
///    │     │    ├── (PLVSAToolbarAreaView) toolbarAreaView
///    │     │    ├── (PLVSAChatroomAreaView) chatroomAreaView
///    │     │    ├── (PLVSASlideRightTipsView) slideRightTipsView
///    │     │    ├── (PLVSACameraAndMicphoneStateView) cameraAndMicphoneStateView
///    │     │    └── (PLVSALinkMicGuiedView) linkMicGuiedView
///    │     └── (PLVSALinkMicTipView) linkMicTipView
///    └── (UIButton) closeButton(highest)


@property (nonatomic, weak) PLVSALinkMicWindowsView *linkMicWindowsView; // 实际由主页linkMicAreaView持有的连麦窗口视图
@property (nonatomic, strong) UIButton *closeButton; // 关闭直播间按钮
@property (nonatomic, strong) UIScrollView *scrollView; // 底部滑动视图
@property (nonatomic, strong) UIView *homePageView; // 背景蒙版视图
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
@property (nonatomic, strong) PLVSALinkMicGuiedView *linkMicGuiedView; // 连麦新手引导

/// 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *localOnlineUser; // 本地用户模型，使用弱引用
@property (nonatomic, assign) BOOL showLinkMicGuiedView; // 是否显示连麦新手引导
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList;
@property (nonatomic, assign) NSInteger userCount;

@end

@implementation PLVSAStreamerHomeView


#pragma mark - [ Life Cycle ]

- (instancetype)initWithLocalOnlineUser:(PLVLinkMicOnlineUser *)localOnlineUser
                     linkMicWindowsView:(PLVSALinkMicWindowsView *)linkMicWindowsView {
    self = [super init];
    if (self) {
        [self setupLocalOnlineUser:localOnlineUser];
        
        [self setupUIWithLinkMicWindowsView:linkMicWindowsView];
        
        self.showLinkMicGuiedView = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    
    CGFloat right = [PLVSAUtils sharedUtils].areaInsets.right;
    CGFloat top = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    
    self.closeButton.frame = CGRectMake(selfSize.width - 44 - right - 2, top + 2, 44, 44);
    
    BOOL first = CGRectEqualToRect(self.scrollView.frame, CGRectZero);
    self.scrollView.frame = self.bounds;
    self.scrollView.contentSize = CGSizeMake(selfSize.width * 2, selfSize.height);
    
    self.linkMicTipView.frame = CGRectMake(selfSize.width - 214, selfSize.height - bottom - 32 - 20, 214, 32);
    
    CGRect pageRect = self.scrollView.bounds;
    pageRect.origin.x = self.scrollView.bounds.size.width;
    self.homePageView.frame = pageRect;
    
    if (first) {
        self.scrollView.contentOffset = CGPointMake(selfSize.width, 0);
        self.linkMicWindowsView.frame = pageRect;
    } else {
        CGRect linkMicWindowFrame = self.linkMicWindowsView.frame;
        linkMicWindowFrame.origin.x = self.scrollView.contentOffset.x;
        self.linkMicWindowsView.frame = linkMicWindowFrame;
    }
    
    self.statusbarAreaView.frame = CGRectMake(0, top, selfSize.width, 72);
    self.cameraAndMicphoneStateView.frame = CGRectMake(0, CGRectGetMaxY(self.statusbarAreaView.frame) + 5, selfSize.width, 36);
    self.toolbarAreaView.frame = CGRectMake(0, selfSize.height - bottom - 60, selfSize.width, 60);
    self.chatroomAreaView.frame = CGRectMake(0, CGRectGetMinY(self.toolbarAreaView.frame) - selfSize.height * 0.28, selfSize.width * 0.65, selfSize.height * 0.28);
    self.slideRightTipsView.frame = self.bounds;
    
    CGFloat linkMicWindowHeight = 280;
    CGFloat linkMicWindowY = 78;
    self.linkMicGuiedView.frame = CGRectMake(selfSize.width - 173 - 15, top + linkMicWindowY + linkMicWindowHeight + 8, 173, 50);
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
}

- (void)setPushStreamDuration:(NSTimeInterval)duration {
    self.statusbarAreaView.duration = duration;
}

- (void)setNetworkQuality:(PLVBLinkMicNetworkQuality)netState {
    self.statusbarAreaView.netState = (PLVSAStatusBarNetworkQuality)netState;
    self.chatroomAreaView.netState = (NSInteger)netState;
    self.toolbarAreaView.netState = (NSInteger)netState;
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
    [self.toolbarAreaView showMemberBadge:show];
}

- (void)ShowNewWaitUserAdded {
    CGRect frame = self.linkMicTipView.frame;
    CGSize selfSize = self.bounds.size;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    if (self.scrollView.contentOffset.x == 0) {
        frame.origin.x = selfSize.width - frame.size.width - 8;
        frame.origin.y = selfSize.height - bottom  - 20 - frame.size.height ;
    } else {
        frame.origin.x = selfSize.width *2 - frame.size.width - 8;
        frame.origin.y = CGRectGetMinY(self.toolbarAreaView.frame) - frame.size.height - 16;
    }
    
    self.linkMicTipView.frame = frame;
    [self.linkMicTipView show];
}

- (void)showOrHiddenLinMicGuied:(NSInteger)onlineUserCount{
    // 显示新手引导
    if (self.showLinkMicGuiedView && onlineUserCount >1) {
        self.showLinkMicGuiedView = NO;
        [self.linkMicGuiedView showLinMicGuied:YES];
    } else {
        [self.linkMicGuiedView showLinMicGuied:NO];
    }
}

- (void)changeFlashButtonSelectedState:(BOOL)selectedState{
    [self.moreInfoSheet changeFlashButtonSelectedState:selectedState];
}

#pragma mark - [ Private Method ]

- (void)setupUIWithLinkMicWindowsView:(PLVSALinkMicWindowsView *)linkMicWindowsView {
    self.linkMicWindowsView = linkMicWindowsView;
    
    [self addSubview:self.scrollView];
    [self insertSubview:self.closeButton aboveSubview:self.scrollView];

    // 迁移连麦窗口到homeView上
    [self.linkMicWindowsView removeFromSuperview];
    [self.scrollView insertSubview:self.linkMicWindowsView atIndex:0];
    
    [self.scrollView addSubview:self.homePageView];
    [self.scrollView addSubview:self.linkMicTipView];
    
    [self.homePageView addSubview:self.statusbarAreaView];
    [self.homePageView addSubview:self.toolbarAreaView];
    [self.homePageView addSubview:self.chatroomAreaView];
    [self.homePageView addSubview:self.slideRightTipsView];
    [self.homePageView addSubview:self.cameraAndMicphoneStateView];
    [self.homePageView addSubview:self.linkMicGuiedView];
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
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewCurrentQuality:)]) {
        self.moreInfoSheet.streamQuality = [self.delegate streamerHomeViewCurrentQuality:self];
    }
    
}

#pragma mark Getter & Setter

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
        CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.285;
        _channelInfoSheet = [[PLVSAChannelInfoSheet alloc] initWithSheetHeight:sheetHeight];
    }
    return _channelInfoSheet;
}

- (PLVSAMoreInfoSheet *)moreInfoSheet {
    if (!_moreInfoSheet) {
        CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.34;
        _moreInfoSheet = [[PLVSAMoreInfoSheet alloc] initWithSheetHeight:sheetHeight];
        _moreInfoSheet.delegate = self;
    }
    return _moreInfoSheet;
}

- (PLVSABitRateSheet *)bitRateSheet {
    if (!_bitRateSheet) {
        CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.285;
        _bitRateSheet = [[PLVSABitRateSheet alloc] initWithSheetHeight:sheetHeight];
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

- (PLVSALinkMicGuiedView *)linkMicGuiedView {
    if (!_linkMicGuiedView) {
        _linkMicGuiedView = [[PLVSALinkMicGuiedView alloc] init];
        _linkMicGuiedView.hidden = YES;
    }
    return _linkMicGuiedView;
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
