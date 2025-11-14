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
#import "PLVLiveToast.h"
#import "PLVMultiLanguageManager.h"

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
#import "PLVSALongContentMessageSheet.h"
#import "PLVSAManageCommoditySheet.h"
#import "PLVSABadNetworkTipsView.h"
#import "PLVSASwitchSuccessTipsView.h"
#import "PLVSABadNetworkSwitchSheet.h"
#import "PLVSAMixLayoutSheet.h"
#import "PLVSALinkMicSettingSheet.h"
#import "PLVStreamerPopoverView.h"
#import "PLVPinMessagePopupView.h"
#import "PLVSADesktopChatSettingSheet.h"
#import "PLVStickerCanvas.h"
#import "PLVSAAICardWidgetView.h"
#import "PLVSAAICardView.h"

// 模块
#import "PLVChatModel.h"
#import "PLVRoomDataManager.h"
#import "PLVLinkMicOnlineUser.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSString * const kUserDefaultShowedSlideRightTips = @"UserDefaultShowedSlideRightTips";
static NSInteger kPLVSALinkMicRequestExpiredTime = 30; // 连麦邀请等待时间(秒)

@interface PLVSAStreamerHomeView ()<
UIScrollViewDelegate,
PLVSABitRateSheetDelegate,
PLVSAChatroomAreaViewDelegate,
PLVAStatusbarAreaViewDelegate,
PLVSAToolbarAreaViewDelegate,
PLVSAMoreInfoSheetDelegate,
PLVSAMemberSheetDelegate,
PLVSAMemberSheetSearchDelegate,
PLVSALinkMicTipViewDelegate,
PLVSAMixLayoutSheetDelegate,
PLVSABadNetworkSwitchSheetDelegate,
PLVSALinkMicSettingSheetDelegate,
PLVSADesktopChatSettingSheetDelegate,
PLVSAManageCommoditySheetDelegate,
PLVSAAICardWidgetViewDelegate,
PLVSAAICardViewDelegate
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
///    ├── (UIButton) closeButton
///    └── (PLVStreamerPopoverView) popoverView(highest)
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
@property (nonatomic, strong) PLVSAManageCommoditySheet *commoditySheet; // 商品库弹层
@property (nonatomic, strong) PLVSABadNetworkSwitchSheet *badNetworkSwitchSheet; // 弱网处理弹层
@property (nonatomic, strong) PLVSAMixLayoutSheet *mixLayoutSheet; // 连麦布局选择面板
@property (nonatomic, strong) PLVSALinkMicSettingSheet *linkMicSettingSheet; // 连麦设置选择面板
@property (nonatomic, strong) PLVSADesktopChatSettingSheet *desktopChatSettingSheet; // 桌面消息设置选择面板
@property (nonatomic, strong) PLVSALinkMicTipView *linkMicTipView; // 连麦提示视图
@property (nonatomic, strong) PLVSACameraAndMicphoneStateView *cameraAndMicphoneStateView; // 摄像头与麦克风状态视图
@property (nonatomic, strong) PLVSALinkMicLayoutSwitchGuideView *layoutSwitchGuideView; // 布局切换新手引导
@property (nonatomic, strong) PLVSABadNetworkTipsView *badNetworkTipsView; // 网络较差提示切换【流畅模式】气泡
@property (nonatomic, strong) PLVSASwitchSuccessTipsView *switchSuccessTipsView; // 切换【流畅模式】成功提示气泡
@property (nonatomic, strong) PLVPinMessagePopupView *pinMsgPopupView; // 评论上墙视图
@property (nonatomic, strong) PLVStreamerPopoverView *popoverView; // 浮动区域
@property (nonatomic, strong) UIView *networkDisconnectMaskView; // 网络断开遮罩
@property (nonatomic, strong) UIImageView *networkDisconnectImageView; // 网络断开提示图片
@property (nonatomic, strong) UILabel *networkDisconnectLabel; // 网络断开提示
@property (nonatomic, strong) PLVSAAICardWidgetView *aiCardWidgetView; // AI 手卡挂件
@property (nonatomic, strong) PLVSAAICardView *aiCardView; // AI 手卡浮窗视图

/// 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *localOnlineUser; // 本地用户模型，使用弱引用
@property (nonatomic, assign) BOOL hadShowedLayoutSwitchGuide; // 是否显示过布局切换新手引导
@property (nonatomic, assign) BOOL showingLayoutSwitchGuide; // 是否正在显示布局切换新手引导
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList;
@property (nonatomic, assign) NSInteger userCount;
@property (nonatomic, strong) NSTimer *requestLinkMicTimer; // 申请连麦计时器
@property (nonatomic, assign) NSTimeInterval requestLinkMicLimitTs; // 请求连麦的限制时间
@property (nonatomic, assign, readonly) BOOL isGuest; // 是否为嘉宾
@property (nonatomic, assign, readonly) BOOL isGuestManualLinkMic; // 本地嘉宾手动连麦模式

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
        [self updateToolbarLinkMicButtonStatus:PLVSAToolbarLinkMicButtonStatus_NotLive];
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
    self.popoverView.frame = self.bounds;
    
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
   
    self.linkMicWindowsView.fullScreenContentView.frame = self.bounds;
    self.statusbarAreaView.frame = CGRectMake(left, top, selfSize.width - left - right, 72);
    self.cameraAndMicphoneStateView.frame = CGRectMake(left, CGRectGetMaxY(self.statusbarAreaView.frame) + cameraAndMicphoneStateViewTop, selfSize.width - left - right, 36);
    
    CGFloat aiCardWidgetMarginTop = 16;
    CGFloat aiCardWidgetY;
    if (self.cameraAndMicphoneStateView.hidden) {
        aiCardWidgetY = CGRectGetMaxY(self.statusbarAreaView.frame) + aiCardWidgetMarginTop;
    } else {
        aiCardWidgetY = CGRectGetMaxY(self.cameraAndMicphoneStateView.frame) + aiCardWidgetMarginTop;
    }
    self.aiCardWidgetView.frame = CGRectMake(left + toolbarViewMarginRight, aiCardWidgetY, self.aiCardWidgetView.widgetSize.width, self.aiCardWidgetView.widgetSize.height);
    
    self.toolbarAreaView.frame = CGRectMake(left, selfSize.height - bottom - toolbarAreaViewHeight, selfSize.width - left - right, toolbarAreaViewHeight);
   
    CGFloat chatroomWidth = selfSize.width * chatroomWidthScale;
    CGFloat chatroomHeight = selfSize.height * chatroomHeightScale;
    self.chatroomAreaView.frame = CGRectMake(left, CGRectGetMinY(self.toolbarAreaView.frame) - chatroomHeight, chatroomWidth, chatroomHeight);
    self.slideRightTipsView.frame = self.bounds;
    CGRect buttonRelativeFrame = [self.toolbarAreaView convertRect:self.toolbarAreaView.layoutSwitchButton.frame toView:self.homePageView];
    self.layoutSwitchGuideView.frame = CGRectMake(CGRectGetMidX(buttonRelativeFrame) - self.layoutSwitchGuideView.viewSize.width * 0.65, CGRectGetMinY(self.toolbarAreaView.frame) - self.layoutSwitchGuideView.viewSize.height, self.layoutSwitchGuideView.viewSize.width,  self.layoutSwitchGuideView.viewSize.height);
    
    UIView *teacherNameButton = (UIView *)self.statusbarAreaView.teacherNameButton;
    CGRect teacherNameRect = [self convertRect:teacherNameButton.frame toView:self.homePageView];
    CGFloat behindTeacherName = self.statusbarAreaView.frame.origin.x + CGRectGetMaxX(teacherNameRect) + 8.0;
    CGFloat belowTeacherName = self.statusbarAreaView.frame.origin.y + CGRectGetMaxY(teacherNameRect) + 8.0;
    CGFloat belowCameraAndMicphoneStateView = CGRectGetMaxY(self.cameraAndMicphoneStateView.frame) + 12.0;
    CGFloat originX = 0;
    CGFloat originY = 0;
    
    if (_badNetworkTipsView && _badNetworkTipsView.showing) {
        CGFloat width = self.badNetworkTipsView.viewSize.width;
        CGFloat height = self.badNetworkTipsView.viewSize.height;
        CGFloat center = self.homePageView.bounds.size.width / 2.0 - width / 2.0;
        if (isLandscape) {
            originX = MAX(behindTeacherName, center);
            originY = self.statusbarAreaView.frame.origin.y + teacherNameRect.origin.y;
        } else {
            originX = center;
            originY = self.cameraAndMicphoneStateView.hidden ? belowTeacherName : belowCameraAndMicphoneStateView;
        }
        
        self.badNetworkTipsView.frame = CGRectMake(originX, originY, width, height);
    } else if (_switchSuccessTipsView && _switchSuccessTipsView.showing) {
        CGFloat width = self.switchSuccessTipsView.tipsViewWidth;
        CGFloat height = kPLVSASwitchSuccessTipsViewHeight;
        CGFloat center = self.homePageView.bounds.size.width / 2.0 - width / 2.0;
        if (isLandscape) {
            originX = MAX(behindTeacherName, center);
            originY = self.statusbarAreaView.frame.origin.y + teacherNameRect.origin.y;
        } else {
            originX = center;
            originY = self.cameraAndMicphoneStateView.hidden ? belowTeacherName : belowCameraAndMicphoneStateView;
        }
        
        self.switchSuccessTipsView.frame = CGRectMake(originX, originY, width, height);
    }
    
    self.pinMsgPopupView.frame = CGRectMake((self.homePageView.bounds.size.width - 320)/2, (isLandscape ? 65 : 132), 320, 66);
    
    self.networkDisconnectMaskView.frame = self.bounds;
    self.networkDisconnectImageView.frame = CGRectMake((self.bounds.size.width - 56) / 2, (self.bounds.size.height - 87) / 2, 56, 56);
    self.networkDisconnectLabel.frame = CGRectMake(left, CGRectGetMaxY(self.networkDisconnectImageView.frame) + 8, self.bounds.size.width - left *2, 23);
    
    // AI 手卡浮窗视图布局
    // 位置 X, Y 与 aiCardWidgetView 保持一致
    CGFloat aiCardViewX = CGRectGetMinX(self.aiCardWidgetView.frame);
    CGFloat aiCardViewY = CGRectGetMinY(self.aiCardWidgetView.frame);
    // 宽度：屏幕宽度 - left - right
    CGFloat aiCardViewWidth = self.bounds.size.width - left - right - 2 * toolbarViewMarginRight;
    // 高度：竖屏 0.2734，横屏 0.3
    CGFloat aiCardHeightScale = isLandscape ? 0.3 : 0.2734;
    CGFloat aiCardViewHeight = self.bounds.size.height * aiCardHeightScale;
    
    self.aiCardView.frame = CGRectMake(aiCardViewX, aiCardViewY, aiCardViewWidth, aiCardViewHeight);
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
    [self.memberSheet startClass:start];
    [self.pinMsgPopupView updatePopupViewWithMessage:nil];
    PLVSAToolbarLinkMicButtonStatus linkMicbButtonStatus = start ? PLVSAToolbarLinkMicButtonStatus_Default : PLVSAToolbarLinkMicButtonStatus_NotLive;
    [self updateToolbarLinkMicButtonStatus:linkMicbButtonStatus];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.linkmicNewStrategyEnabled && roomData.roomUser.viewerType == PLVRoomUserTypeTeacher && roomData.interactNumLimit > 0) {
        [self.memberSheet enableAudioVideoLinkMic:start];
    } else if (start) {
        [self.toolbarAreaView autoOpenMicLinkIfNeed];
    }
}

- (void)setPushStreamDuration:(NSTimeInterval)duration {
    self.statusbarAreaView.duration = duration;
    if (!self.isGuest) {
        [self.linkMicWindowsView updateAllCellLinkMicDuration];
    }
}

- (void)setNetworkQuality:(PLVBRTCNetworkQuality)netState {
    self.statusbarAreaView.netState = (PLVSAStatusBarNetworkQuality)netState;
    UIView *signalButton = (UIView *)self.statusbarAreaView.signalButton;
    if (netState == PLVBRTCNetworkQuality_Down) {
        if (self.networkDisconnectMaskView.hidden) {
            self.networkDisconnectMaskView.hidden = NO;
        }
        
        if (signalButton.superview != self.networkDisconnectMaskView) {
            CGRect signalButtonRect = [signalButton convertRect:signalButton.bounds toView:self.networkDisconnectMaskView];
            [signalButton removeFromSuperview];
            [self.networkDisconnectMaskView addSubview:signalButton];
            signalButton.frame = signalButtonRect;
        }
    } else if (!self.networkDisconnectMaskView.hidden) {
        self.networkDisconnectMaskView.hidden = YES;
        [signalButton removeFromSuperview];
        [self.statusbarAreaView addSubview:signalButton];
    }
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
    [self.memberSheet enableAudioVideoLinkMic:selected];
}

- (void)showMemberBadge:(BOOL)show {
    if ([self canManagerLinkMic]) {
        [self.statusbarAreaView showMemberBadge:show];
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
    CGFloat right = [PLVSAUtils sharedUtils].areaInsets.right + padding;
    
    UIView *memberButton = (UIView *)self.statusbarAreaView.memberButton;
    CGRect memberButtonRect = [self convertRect:memberButton.frame toView:self.homePageView];
    if (self.scrollView.contentOffset.x == 0) {
        frame.origin.x = CGRectGetMidX(memberButtonRect) - frame.size.width / 2 + right / 2;
    } else {
        frame.origin.x = selfSize.width + CGRectGetMidX(memberButtonRect) - frame.size.width / 2 + right / 2;
    }
    frame.origin.y = self.statusbarAreaView.frame.origin.y + CGRectGetMaxY(memberButtonRect) + 6;
    
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
    self.moreInfoSheet.removeAllAudiencesEnable = onlineUserCount > 1;
    
    // 更新贴图按钮状态 连麦时不支持贴图选择
    self.moreInfoSheet.stickerEnable = (onlineUserCount <= 1);
}

- (void)changeFlashButtonSelectedState:(BOOL)selectedState{
    [self.moreInfoSheet changeFlashButtonSelectedState:selectedState];
}

- (void)changeScreenShareButtonSelectedState:(BOOL)selectedState{
    [self.moreInfoSheet changeScreenShareButtonSelectedState:selectedState];
    
    // 屏幕共享时不支持贴图选择
    self.moreInfoSheet.stickerEnable = !selectedState;
}

- (void)changeAllowRaiseHandButtonSelectedState:(BOOL)selectedState {
    [self.moreInfoSheet changeAllowRaiseHandButtonSelectedState:selectedState];
}

- (void)updateHomeViewLinkMicType:(BOOL)linkMicOnAudio {
    [self.linkMicSettingSheet updateLinkMicType:linkMicOnAudio];
}

- (void)showBeautySheet:(BOOL)show {
    self.closeButton.hidden = show;
    self.homePageView.hidden = show;
}

- (void)updateStatistics:(PLVRTCStatistics *)statistics {
    [self.statusbarAreaView updateRTT:statistics.rtt upLoss:statistics.upLoss downLoss:statistics.downLoss];
}

- (void)dismissBottomSheet {
    [self.memberSheet dismiss];
    [self.channelInfoSheet dismiss];
    [self.moreInfoSheet dismiss];
    [self.bitRateSheet dismiss];
    [self.commoditySheet dismiss];
}

- (void)showBadNetworkTipsView {
    [self.badNetworkTipsView showAtView:self.homePageView aboveSubview:self.statusbarAreaView];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)showPinMessagePopupView:(BOOL)show message:(PLVSpeakTopMessage *)message {
    [self.pinMsgPopupView updatePopupViewWithMessage:message];
}

- (NSAttributedString *)currentNewMessage {
    return self.chatroomAreaView.currentNewMessage;
}

- (void)addStickerCanvasView:(PLVStickerCanvas *)stickerView editMode:(BOOL)editMode{
    if (editMode){
        // 最上层图层
        [self addSubview:stickerView];
        [self bringSubviewToFront:stickerView];
    }
    else{
        // 本地RTC 渲染图层上面
        [self.linkMicWindowsView insertSubview:stickerView atIndex:1];
    }
}

- (void)updateDesktopChatEnable:(BOOL)enable {
    self.desktopChatSettingSheet.desktopChatEnable = enable;
}

#pragma mark - [ Private Method ]

- (void)setupUIWithLinkMicWindowsView:(PLVSALinkMicWindowsView *)linkMicWindowsView {
    self.linkMicWindowsView = linkMicWindowsView;
    
    [self addSubview:self.scrollView];
    [self insertSubview:self.networkDisconnectMaskView aboveSubview:self.scrollView];
    [self insertSubview:self.closeButton aboveSubview:self.networkDisconnectMaskView];
    [self insertSubview:self.popoverView aboveSubview:self.closeButton]; /// 保证高于 closeButton
    [self insertSubview:self.linkMicWindowsView.fullScreenContentView aboveSubview:self.closeButton];
    
    [self.networkDisconnectMaskView addSubview:self.networkDisconnectLabel];
    [self.networkDisconnectMaskView addSubview:self.networkDisconnectImageView];

    // 迁移连麦窗口到homeView上
    [self.linkMicWindowsView removeFromSuperview];
    [self.scrollView insertSubview:self.linkMicWindowsView atIndex:0];
    
    [self.linkMicWindowsView addSubview:self.shadowMaskView];
    [self.scrollView addSubview:self.homePageView];
    [self.scrollView addSubview:self.linkMicTipView];
    
    [self.homePageView addSubview:self.statusbarAreaView];
    [self.homePageView addSubview:self.toolbarAreaView];
    [self.homePageView addSubview:self.chatroomAreaView];
    [self.homePageView addSubview:self.pinMsgPopupView];
    [self.homePageView addSubview:self.slideRightTipsView];
    [self.homePageView addSubview:self.cameraAndMicphoneStateView];
    [self.homePageView addSubview:self.aiCardWidgetView];
    [self.homePageView addSubview:self.aiCardView];
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
    
    [self.localOnlineUser addCurrentStatusVoiceChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        PLVSAToolbarLinkMicButtonStatus linkMicbButtonStatus = onlineUser.currentStatusVoice ? PLVSAToolbarLinkMicButtonStatus_Joined : PLVSAToolbarLinkMicButtonStatus_Default;
        [weakSelf updateToolbarLinkMicButtonStatus:linkMicbButtonStatus];
    } blockKey:self];
    
    self.localOnlineUser.linkMicStatusBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        PLVSAToolbarLinkMicButtonStatus linkMicbButtonStatus = PLVSAToolbarLinkMicButtonStatus_Default;
        if (onlineUser.linkMicStatus == PLVLinkMicUserLinkMicStatus_Joined) {
            linkMicbButtonStatus = PLVSAToolbarLinkMicButtonStatus_Joined;
        } else if (onlineUser.linkMicStatus == PLVLinkMicUserLinkMicStatus_HandUp) {
            linkMicbButtonStatus = PLVSAToolbarLinkMicButtonStatus_HandUp;
        }
        [weakSelf updateToolbarLinkMicButtonStatus:linkMicbButtonStatus];
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
        if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
            self.moreInfoSheet.streamQualityLevel = [self.delegate streamerHomeViewCurrentStreamQualityLevel:self];
        } else {
            self.moreInfoSheet.streamQuality = [self.delegate streamerHomeViewCurrentQuality:self];
        }
    }
}

- (void)showLayoutSwitchGuideWithUserCount:(NSInteger)userCount {
    if (self.isGuest || userCount < 2) {
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

- (void)linkMicButtonSelected:(BOOL)selected videoLinkMic:(BOOL)videoLinkMic {
    BOOL channelLinkMicOpen = NO;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewChannelLinkMicOpen:)]) {
        channelLinkMicOpen = [self.delegate streamerHomeViewChannelLinkMicOpen:self];
    }
    //判断连麦按钮状态是否与实际连麦与否的情况相符，若符合，正常操作连麦/结束连麦，若不符，直接调用homeView接口修改linkMic按钮状态
    // 当前连麦按钮显示已连麦时的校验
    if (selected &&
        !channelLinkMicOpen) { // 实际上未连麦但UI显示已连麦
        [self setLinkMicButtonSelected:NO];
        return;
    }
    // 当前连麦按钮显示未连麦时的校验
    if (!selected &&
        channelLinkMicOpen) { // 实际上已连麦但UI显示未连麦
        [self setLinkMicButtonSelected:YES];
        return;
    }
    
    if (selected) { // 隐藏 有新用户正在申请连麦提示视图
        [self.linkMicTipView dismiss];
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapLinkMicButton:linkMicButtonSelected:videoLinkMic:)]) {
        [self.delegate streamerHomeViewDidTapLinkMicButton:self linkMicButtonSelected:selected videoLinkMic:videoLinkMic];
    }
}

- (void)guestLinMicButtonAction {
    if (self.toolbarAreaView.linkMicButtonStatus == PLVSAToolbarLinkMicButtonStatus_NotLive) {
        [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"上课前无法发起连麦")];
    } else if (self.toolbarAreaView.linkMicButtonStatus == PLVSAToolbarLinkMicButtonStatus_HandUp) {
        __weak typeof(self) weakSelf = self;
        [PLVSAUtils showAlertWithMessage:PLVLocalizedString(@"等待接听中，是否取消") cancelActionTitle:PLVLocalizedString(@"否") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"是") confirmActionBlock:^{
            [weakSelf.localOnlineUser wantUserRequestJoinLinkMic:NO];
            [weakSelf updateToolbarLinkMicButtonStatus:PLVSAToolbarLinkMicButtonStatus_Default];
        }];
    } else if (self.toolbarAreaView.linkMicButtonStatus == PLVSAToolbarLinkMicButtonStatus_Joined) {
        __weak typeof(self) weakSelf = self;
        [PLVSAUtils showAlertWithMessage:PLVLocalizedString(@"确定结束连麦吗？") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
            [weakSelf.localOnlineUser wantCloseUserLinkMic];
            [weakSelf updateToolbarLinkMicButtonStatus:PLVSAToolbarLinkMicButtonStatus_Default];
        }];
    } else if (self.toolbarAreaView.linkMicButtonStatus == PLVSAToolbarLinkMicButtonStatus_Default) {
        [self.localOnlineUser wantUserRequestJoinLinkMic:YES];
        [self updateToolbarLinkMicButtonStatus:PLVSAToolbarLinkMicButtonStatus_HandUp];
    }
}

// 更新连麦按钮状态 手动上麦嘉宾有效
- (void)updateToolbarLinkMicButtonStatus:(PLVSAToolbarLinkMicButtonStatus)status {
    if (self.isGuest && self.isGuestManualLinkMic) {
        if (status == PLVSAToolbarLinkMicButtonStatus_HandUp) {
            [self createRequestLinkMicTimer];
        } else {
            [self destroyRequestLinkMicTimer];
        }
        [self.toolbarAreaView updateLinkMicButtonStatus:status];
    }
}

- (void)createRequestLinkMicTimer {
    if (_requestLinkMicTimer) {
        [self destroyRequestLinkMicTimer];
    }
    self.requestLinkMicLimitTs = kPLVSALinkMicRequestExpiredTime;
    _requestLinkMicTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(requestLinkMicTimerAction) userInfo:nil repeats:YES];
}

- (void)destroyRequestLinkMicTimer {
    if (_requestLinkMicTimer) {
        [_requestLinkMicTimer invalidate];
        _requestLinkMicTimer = nil;
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
        __weak typeof(self) weakSelf = self;
        _slideRightTipsView.closeButtonHandler = ^{
            weakSelf.scrollView.scrollEnabled = YES;
            [weakSelf.slideRightTipsView removeFromSuperview];
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
        _moreInfoSheet = [[PLVSAMoreInfoSheet alloc] init];
        _moreInfoSheet.delegate = self;
    }
    return _moreInfoSheet;
}

- (PLVSABitRateSheet *)bitRateSheet {
    if (!_bitRateSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        BOOL isStreamTemplateEnabled = [PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled;
        CGFloat heightScale = isPad ? 0.233 : (isStreamTemplateEnabled ? 0.50 : 0.285);
        CGFloat widthScale = isStreamTemplateEnabled ? 0.40 : 0.23;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _bitRateSheet = [[PLVSABitRateSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _bitRateSheet.delegate = self;
        PLVResolutionType type = [self.delegate streamerHomeViewCurrentQuality:self];
        NSString *qualityLevel = [self.delegate streamerHomeViewCurrentStreamQualityLevel:self];
        [_bitRateSheet setupBitRateOptionsWithCurrentBitRate:type streamQualityLevel:qualityLevel];
    }
    return _bitRateSheet;
}

- (PLVSAMemberSheet *)memberSheet {
    if (!_memberSheet) {
        _memberSheet = [[PLVSAMemberSheet alloc] initWithUserList:self.userList userCount:self.userCount];
        _memberSheet.delegate = self;
        _memberSheet.searchDelegate = self;
        
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

- (PLVSAManageCommoditySheet *)commoditySheet {
    if (!_commoditySheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = 0.6;
        CGFloat widthScale = 0.46;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat deviceWidth = MIN([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = isPad ? (maxWH * widthScale) : deviceWidth;
        _commoditySheet = [[PLVSAManageCommoditySheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _commoditySheet.delegate = self;
        [_commoditySheet setSheetCornerRadius:0.0f];
    }
    return _commoditySheet;
}

- (PLVSABadNetworkSwitchSheet *)badNetworkSwitchSheet {
    if (!_badNetworkSwitchSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.250 : 0.36;
        CGFloat widthScale = 0.37;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = MAX(maxWH * heightScale, 279);
        CGFloat sheetLandscapeWidth = MAX(maxWH * widthScale, 375);
        _badNetworkSwitchSheet = [[PLVSABadNetworkSwitchSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _badNetworkSwitchSheet.delegate = self;
    }
    return _badNetworkSwitchSheet;
}

- (PLVSAMixLayoutSheet *)mixLayoutSheet {
    if (!_mixLayoutSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.43 : 0.52;
        CGFloat widthScale = 0.44;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _mixLayoutSheet = [[PLVSAMixLayoutSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _mixLayoutSheet.delegate = self;
        PLVMixLayoutType type = [self.delegate streamerHomeViewCurrentMixLayoutType:self];
        PLVMixLayoutBackgroundColor colorType = [self.delegate streamerHomeViewCurrentMixLayoutBackgroundColor:self];
        [_mixLayoutSheet setupOptionsWithCurrentMixLayoutType:type currentBackgroundColor:colorType];
    }
    return _mixLayoutSheet;
}

- (PLVSALinkMicSettingSheet *)linkMicSettingSheet {
    if (!_linkMicSettingSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.43 : 0.52;
        CGFloat widthScale = 0.44;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _linkMicSettingSheet = [[PLVSALinkMicSettingSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        [_linkMicSettingSheet updateLinkMicType:[PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType != PLVChannelLinkMicMediaType_Video];
        _linkMicSettingSheet.delegate = self;
    }
    return _linkMicSettingSheet;
}

- (PLVSADesktopChatSettingSheet *)desktopChatSettingSheet {
    if (!_desktopChatSettingSheet) {
        CGFloat heightScale = 0.266;
        CGFloat widthScale = 0.44;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _desktopChatSettingSheet = [[PLVSADesktopChatSettingSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _desktopChatSettingSheet.delegate = self;
    }
    return _desktopChatSettingSheet;
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

- (PLVPinMessagePopupView *)pinMsgPopupView {
    if (!_pinMsgPopupView) {
        _pinMsgPopupView = [[PLVPinMessagePopupView alloc] init];
        PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        _pinMsgPopupView.canPinMessage = (userType == PLVRoomUserTypeTeacher || userType == PLVRoomUserTypeAssistant);
        _pinMsgPopupView.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _pinMsgPopupView.cancelTopActionBlock = ^(PLVSpeakTopMessage * _Nonnull message) {
            [weakSelf.chatroomAreaView sendCancelTopPinMessage:message.msgId];
        };
    }
    return _pinMsgPopupView;
}

- (PLVStreamerPopoverView *)popoverView {
    if (!_popoverView) {
        _popoverView = [[PLVStreamerPopoverView alloc] init];
    }
    return _popoverView;
}

- (PLVChannelLinkMicMediaType)currentChannelLinkMicMediaType {
    PLVChannelLinkMicMediaType type = PLVChannelLinkMicMediaType_Unknown;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewCurrentChannelLinkMicMediaType:)]) {
        type = [self.delegate streamerHomeViewCurrentChannelLinkMicMediaType:self];
    }
    return type;
}

- (BOOL)isGuest {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    return userType == PLVRoomUserTypeGuest;;
}

- (BOOL)isGuestManualLinkMic {
    return self.isGuest && [PLVRoomDataManager sharedManager].roomData.channelGuestManualJoinLinkMic;
}

- (PLVSABadNetworkTipsView *)badNetworkTipsView {
    if (!_badNetworkTipsView) {
        _badNetworkTipsView = [[PLVSABadNetworkTipsView alloc] init];
        __weak typeof(self) weakSelf = self;
        [_badNetworkTipsView setSwitchButtonActionBlock:^{
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(streamerHomeView:didChangeVideoQosPreference:)]){
                [weakSelf.delegate streamerHomeView:weakSelf didChangeVideoQosPreference:PLVBRTCVideoQosPreferenceSmooth];
            }
            
            [weakSelf.switchSuccessTipsView showAtView:weakSelf.homePageView aboveSubview:weakSelf.statusbarAreaView];
            
            [weakSelf setNeedsLayout];
            [weakSelf layoutIfNeeded];
        }];
    }
    return _badNetworkTipsView;
}

- (PLVSASwitchSuccessTipsView *)switchSuccessTipsView {
    if (!_switchSuccessTipsView) {
        _switchSuccessTipsView = [[PLVSASwitchSuccessTipsView alloc] init];
    }
    return _switchSuccessTipsView;
}

- (UIView *)networkDisconnectMaskView {
    if (!_networkDisconnectMaskView) {
        _networkDisconnectMaskView = [[UIView alloc] init];
        _networkDisconnectMaskView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.6);
        _networkDisconnectMaskView.hidden = YES;
    }
    return _networkDisconnectMaskView;
}

- (UIImageView *)networkDisconnectImageView {
    if (!_networkDisconnectImageView) {
        _networkDisconnectImageView = [[UIImageView alloc] initWithImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_error"]];
    }
    return _networkDisconnectImageView;
}

- (UILabel *)networkDisconnectLabel {
    if (!_networkDisconnectLabel) {
        _networkDisconnectLabel = [[UILabel alloc] init];
        _networkDisconnectLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _networkDisconnectLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];
        _networkDisconnectLabel.text = PLVLocalizedString(@"网络断开，直播已暂停");
        _networkDisconnectLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _networkDisconnectLabel;
}

- (PLVSAAICardWidgetView *)aiCardWidgetView {
    if (!_aiCardWidgetView) {
        _aiCardWidgetView = [[PLVSAAICardWidgetView alloc] init];
        _aiCardWidgetView.delegate = self;
    }
    return _aiCardWidgetView;
}

- (PLVSAAICardView *)aiCardView {
    if (!_aiCardView) {
        _aiCardView = [[PLVSAAICardView alloc] init];
        _aiCardView.delegate = self;
    }
    return _aiCardView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeButtonAction:(id)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapCloseButton:)]){
        [self.delegate streamerHomeViewDidTapCloseButton:self];
    }
}

#pragma mark Timer
- (void)requestLinkMicTimerAction {
    self.requestLinkMicLimitTs -= 1;
    if (self.requestLinkMicLimitTs <= 0) {
        [self.localOnlineUser wantUserRequestJoinLinkMic:NO];
        [self updateToolbarLinkMicButtonStatus:PLVSAToolbarLinkMicButtonStatus_Default];
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

- (void)statusbarAreaViewDidTapMemberButton:(PLVSAStatusbarAreaView *)statusBarAreaView {
    if (![PLVRoomDataManager sharedManager].roomData.appStartMemberListEnabled) {
        return;
    }
    [self.memberSheet showInView:self];
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

- (void)toolbarAreaViewDidTapCommodityButton:(PLVSAToolbarAreaView *)toolbarAreaView {
    [self.commoditySheet showInView:self];
}

- (void)toolbarAreaViewDidTapLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected {
    if (self.isGuest) { // 嘉宾用户
        [self guestLinMicButtonAction];
    } else {
        [self linkMicButtonSelected:selected videoLinkMic:[self currentChannelLinkMicMediaType] == PLVChannelLinkMicMediaType_Video];
    }
}

- (void)toolbarAreaViewDidTapVideoLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected {
    [self linkMicButtonSelected:selected videoLinkMic:YES];
}

- (void)toolbarAreaViewDidTapAudioLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected {
    [self linkMicButtonSelected:selected videoLinkMic:NO];
}

- (void)toolbarAreaViewDidTapVideoMaterialButton:(PLVSAToolbarAreaView *)toolbarAreaView {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapVideoMaterialButton:)]) {
        [self.delegate streamerHomeViewDidTapVideoMaterialButton:self];
    }
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
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeScreenShareOpen:)]) {
        [self.delegate streamerHomeView:self didChangeScreenShareOpen:screenShareOpen];
    }
}

- (void)moreInfoSheetDidTapDesktopChatButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    [self.desktopChatSettingSheet showInView:self];
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCloseRoom:(BOOL)closeRoom {
    self.chatroomAreaView.closeRoom = closeRoom;
}

- (void)moreInfoSheetDidTapBeautyButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapBeautyButton:)]) {
        [self.delegate streamerHomeViewDidTapBeautyButton:self];
    }
}

- (void)moreInfoSheetDidTapShareButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapShareButton:)]) {
        [self.delegate streamerHomeViewDidTapShareButton:self];
    }
}

- (void)moreInfoSheetDidTapBadNetworkButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewCurrentVideoQosPreference:)]) {
        PLVBRTCVideoQosPreference videoQosPreference =[self.delegate streamerHomeViewCurrentVideoQosPreference:self];
        [self.badNetworkSwitchSheet showInView:self currentVideoQosPreference:videoQosPreference];
    }
}

- (void)moreInfoSheetDidTapMixLayoutButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    [self.mixLayoutSheet showInView:self];
}

- (void)moreInfoSheetDidTapAllowRaiseHandButton:(PLVSAMoreInfoSheet *)moreInfoSheet wannaChangeAllowRaiseHand:(BOOL)allowRaiseHand {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeViewDidAllowRaiseHandButton:wannaChangeAllowRaiseHand:)]) {
        [self.delegate streamerHomeViewDidAllowRaiseHandButton:self wannaChangeAllowRaiseHand:allowRaiseHand];
    }
}

- (void)moreInfoSheetDidTapLinkMicSettingButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    [self.linkMicSettingSheet showInView:self];
}

- (void)moreInfoSheetDidTapRemoveAllAudiencesButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapRemoveAllAudiencesButton:)]) {
        [self.delegate streamerHomeViewDidTapRemoveAllAudiencesButton:self];
    }
}

- (void)moreInfoSheetDidTapSignInButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    [self.popoverView.interactView openInteractViewWithEventName:@"SHOW_SIGN"];
}

/// 点击 贴纸按钮 触发回调
- (void)moreInfoSheetDidTapStickerButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapStickerButton:)]) {
        [self.delegate streamerHomeViewDidTapStickerButton:self];
    }
}

/// 点击 视频贴纸按钮 触发回调
- (void)moreInfoSheetDidTapStickerVideoButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapStickerVideoButton:)]) {
        [self.delegate streamerHomeViewDidTapStickerVideoButton:self];
    }
}

/// 点击 AI抠像 按钮 触发回调
- (void)moreInfoSheetDidTapAiMattingButton:(PLVSAMoreInfoSheet *)moreInfoSheet {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeViewDidTapAiMattingButton:)]) {
        [self.delegate streamerHomeViewDidTapAiMattingButton:self];
    }
}

- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didCloseGiftEffects:(BOOL)closeGiftEffects {
    self.chatroomAreaView.closeGiftEffects = closeGiftEffects;
}

- (void)moreInfoSheetDidChangeCloseGiftReward:(PLVSAMoreInfoSheet *)moreInfoSheet {
    [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"开启/关闭打赏设置后，观众需刷新页面或重进直播间")];
}

#pragma mark PLVSABitRateSheetDelegate

- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet bitRateButtonClickWithBitRate:(PLVResolutionType)bitRate {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeResolutionType:)]) {
        [self.delegate streamerHomeView:self didChangeResolutionType:bitRate];
        self.moreInfoSheet.streamQuality = bitRate;
    }
}

- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet didSelectStreamQualityLevel:(NSString *)streamQualityLevel {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeStreamQualityLevel:)]) {
        [self.delegate streamerHomeView:self didChangeStreamQualityLevel:streamQualityLevel];
        self.moreInfoSheet.streamQualityLevel = streamQualityLevel;
    }
}

#pragma mark PLVSABadNetworkSwitchSheetDelegate

- (void)switchSheet:(PLVSABadNetworkSwitchSheet *)switchSheet didChangedVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference {
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
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeVideoQosPreference:)]){
        [self.delegate streamerHomeView:self didChangeVideoQosPreference:videoQosPreference];
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

- (void)chatroomAreaView:(PLVSAChatroomAreaView *)chatroomAreaView alertLongContentMessage:(PLVChatModel *)model {
    NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
    if (content) {
        PLVSALongContentMessageSheet *messageSheet = [[PLVSALongContentMessageSheet alloc] initWithChatModel:model];
        [messageSheet showInView:self];
    }
}

- (void)chatroomAreaView_updateCommodityModel:(PLVCommodityModel *)commodityModel {
    [self.aiCardView updateWithCommodityModel:commodityModel];
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

- (void)inviteUserJoinLinkMicInMemberSheet:(PLVSAMemberSheet *)memberSheet chatUser:(PLVChatUser *)user {
    PLVLinkMicWaitUser *waitUser = user.waitUser;
    if (!waitUser) {
        waitUser = [PLVLinkMicWaitUser modelWithChatUser:user];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(inviteUserJoinLinkMicInStreamerHomeView:withUser:)]) {
        [self.delegate inviteUserJoinLinkMicInStreamerHomeView:self withUser:waitUser];
    }
}

#pragma mark PLVSALinkMicTipViewDelegate
- (void)linkMicTipViewDidTapCheckButton:(PLVSALinkMicTipView *)linkMicTipView {
    [self.linkMicTipView dismiss];
    // 回到第二屏
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.bounds.size.width, 0)];
    if (![PLVRoomDataManager sharedManager].roomData.appStartMemberListEnabled) {
        return;
    }
    // 显示成员列表
    [self.memberSheet showInView:self];
}

#pragma mark PLVSAMixLayoutSheetDelegate

- (void)plvsaMixLayoutSheet:(PLVSAMixLayoutSheet *)mixLayoutSheet mixLayoutButtonClickWithMixLayoutType:(PLVMixLayoutType)type {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeMixLayoutType:)]) {
        [self.delegate streamerHomeView:self didChangeMixLayoutType:type];
    }
}

- (void)plvsaMixLayoutSheet:(PLVSAMixLayoutSheet *)mixLayoutSheet didSelectBackgroundColor:(PLVMixLayoutBackgroundColor)colorType {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeMixLayoutBackgroundColor:)]) {
        [self.delegate streamerHomeView:self didChangeMixLayoutBackgroundColor:colorType];
    }
}

#pragma mark PLVSALinkMicSettingSheetDelegate

- (void)plvsaLinkMicSettingSheet_wannaChangeLinkMicType:(BOOL)linkMicOnAudio {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeView:wannaChangeLinkMicType:)]) {
        [self.delegate streamerHomeView:self wannaChangeLinkMicType:linkMicOnAudio];
    }
}

#pragma mark PLVSADesktopChatSettingSheetDelegate

- (void)desktopChatSettingSheet:(PLVSADesktopChatSettingSheet *)sheet didChangeDesktopChatEnable:(BOOL)desktopChatEnable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeView:didChangeDesktopChatEnable:)]) {
        [self.delegate streamerHomeView:self didChangeDesktopChatEnable:desktopChatEnable];
    }
}

#pragma mark PLVSAMemberSheetSearchDelegate

- (void)memberSheet:(PLVSAMemberSheet *)memberSheet didStartSearchWithKeyword:(NSString *)keyword {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeView:didStartSearchWithKeyword:)]) {
        [self.delegate streamerHomeView:self didStartSearchWithKeyword:keyword];
    }
}

- (void)memberSheetDidCancelSearch:(PLVSAMemberSheet *)memberSheet {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeViewDidCancelSearch:)]) {
        [self.delegate streamerHomeViewDidCancelSearch:self];
    }
}

- (void)memberSheet:(PLVSAMemberSheet *)memberSheet didChangeSearchState:(BOOL)isSearching {
    [memberSheet updateSearchState:isSearching];
}

- (void)memberSheet:(PLVSAMemberSheet *)memberSheet didUpdateSearchResults:(NSArray<PLVChatUser *> *)results {
    [memberSheet updateSearchResults:results];
}

#pragma mark PLVSAManageCommoditySheetDelegate

- (NSString *)plvSAManageCommoditySheetCurrentStreamState {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeViewCurrentStreamState:)]) {
        return [self.delegate streamerHomeViewCurrentStreamState:self];
    } else {
        return @"";
    }
}

#pragma mark - 搜索相关方法

/// 开始搜索
/// @param keyword 搜索关键词
- (void)startSearchWithKeyword:(NSString *)keyword {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeView:didStartSearchWithKeyword:)]) {
        [self.delegate streamerHomeView:self didStartSearchWithKeyword:keyword];
    }
}

/// 取消搜索
- (void)cancelSearch {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerHomeViewDidCancelSearch:)]) {
        [self.delegate streamerHomeViewDidCancelSearch:self];
    }
}

/// 更新搜索状态
/// @param isSearching 是否正在搜索
- (void)updateSearchState:(BOOL)isSearching {
    if (self.memberSheet && self.memberSheet.searchDelegate && 
        [self.memberSheet.searchDelegate respondsToSelector:@selector(memberSheet:didChangeSearchState:)]) {
        [self.memberSheet.searchDelegate memberSheet:self.memberSheet didChangeSearchState:isSearching];
    }
}

/// 更新搜索结果
/// @param results 搜索结果
- (void)updateSearchResults:(NSArray<PLVChatUser *> *)results {
    if (self.memberSheet && self.memberSheet.searchDelegate && 
        [self.memberSheet.searchDelegate respondsToSelector:@selector(memberSheet:didUpdateSearchResults:)]) {
        [self.memberSheet.searchDelegate memberSheet:self.memberSheet didUpdateSearchResults:results];
    }
}

#pragma mark PLVSAAICardWidgetViewDelegate

- (void)aiCardWidgetViewDidClickAction:(PLVSAAICardWidgetView *)aiCardWidgetView {
    [self.aiCardView show:YES];
}

#pragma mark PLVSAAICardViewDelegate

- (void)aiCardView:(PLVSAAICardView *)aiCardView widgetStatusNeedChange:(BOOL)show {
    self.aiCardWidgetView.hidden = !show;
}

@end
