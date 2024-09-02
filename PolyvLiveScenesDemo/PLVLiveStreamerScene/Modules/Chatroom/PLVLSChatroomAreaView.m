//
//  PLVLSChatroomAreaView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSChatroomAreaView.h"

/// 模块
#import "PLVLSChatroomViewModel.h"
#import "PLVRoomDataManager.h"

// UI
#import "PLVLSNewMessageView.h"
#import "PLVLSChatroomToolbar.h"
#import "PLVLSChatroomListView.h"
#import "PLVLSSendMessageView.h"
#import "PLVLSRemindChatroomSheet.h"

// 工具类
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

static NSTimeInterval remindMessageTimerInterval = 30.0;

@interface PLVLSChatroomAreaView ()<
PLVLSChatroomViewModelProtocol
>

/// UI
@property (nonatomic, strong) PLVLSSendMessageView *sendMsgView; // 发送消息输入框视图
@property (nonatomic, strong) PLVLSChatroomListView *chatroomListView;
@property (nonatomic, strong) PLVLSNewMessageView *receiveNewMessageView;
@property (nonatomic, strong) PLVLSChatroomToolbar *toolbarView;
@property (nonatomic, strong) UIView *leftToolView;
@property (nonatomic, strong) UIButton *hideListViewButton;
@property (nonatomic, strong) UIButton *remindButton;
@property (nonatomic, strong) UIView *remindBadgeView;
@property (nonatomic, strong) PLVLSRemindChatroomSheet *remindSheet;

/// 数据
@property (nonatomic, assign) NSUInteger newMessageCount; // 未读消息条数
@property (nonatomic, assign) NSUInteger remindNewMessageCount; // 提醒消息未读消息条数，用于隐藏聊天时提示
@property (nonatomic, assign) BOOL documentFullScreen; // 文档是否为全屏

#pragma mark 定时器
@property (nonatomic, strong) NSTimer *remindMessageTimer; // 提醒消息定时器，隐藏聊天时时启动监听是否需要显示’未读提醒消息条数‘

@end

@implementation PLVLSChatroomAreaView {
    dispatch_queue_t chatroomViewModelDelegateQueue;
}

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.chatroomListView];
        [self addSubview:self.leftToolView];
        [self addSubview:self.toolbarView];
        
        [self.leftToolView addSubview:self.hideListViewButton];
        [self.leftToolView addSubview:self.remindButton];
        
        [self.chatroomListView addSubview:self.receiveNewMessageView];
        
        chatroomViewModelDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        [[PLVLSChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:chatroomViewModelDelegateQueue];
        
        // 提前初始化 sendMsgView，避免弹出时才初始化导致卡顿
        [self sendMsgView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat normalPadding = isPad ? 12 : 8;
    CGFloat btnWidth = 32;

    CGFloat areaViewWidth = [UIScreen mainScreen].bounds.size.width * 0.34; // 支持小屏后，聊天室区域保持宽度34%不变
    CGFloat areaViewHeight = self.bounds.size.height;
    self.chatroomListView.frame = CGRectMake(normalPadding, 0, areaViewWidth - normalPadding, areaViewHeight - btnWidth - 8 * 2);
    
    BOOL remindEnabled = [PLVRoomDataManager sharedManager].roomData.menuInfo.remindEnabled;
    CGFloat leftWidth = btnWidth * (remindEnabled ? 2 : 1);
    self.leftToolView.frame = CGRectMake(normalPadding, areaViewHeight - normalPadding - btnWidth, leftWidth, btnWidth);
    self.hideListViewButton.frame = CGRectMake(0, 0, btnWidth, btnWidth);
    if (remindEnabled) {
        self.remindButton.hidden = NO;
        self.remindButton.frame = CGRectMake(btnWidth, 0, btnWidth, btnWidth);
        self.remindBadgeView.frame = CGRectMake(btnWidth - 6 * 2, 6, 6, 6);
    } else {
        self.remindButton.hidden = YES;
        self.remindButton.frame = CGRectZero;
        self.remindBadgeView.frame = CGRectZero;
    }
    
    //根据频道是否是音频模式而导致布局不同
    if ([PLVRoomDataManager sharedManager].roomData.isOnlyAudio) {
        self.toolbarView.frame = CGRectMake(CGRectGetMaxX(self.leftToolView.frame) + 12, CGRectGetMinY(self.leftToolView.frame), 180, btnWidth);
    } else {
        self.toolbarView.frame = CGRectMake(CGRectGetMaxX(self.leftToolView.frame) + 12, CGRectGetMinY(self.leftToolView.frame), 252, btnWidth);
    }
    self.receiveNewMessageView.frame = CGRectMake(0, self.chatroomListView.frame.size.height - 28, 86, 28);
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 1.判断当前控件能否接收事件
    if (self.userInteractionEnabled == NO || self.hidden == YES || self.alpha <= 0.01) {return nil;}
    // 2. 判断点在不在当前控件
    if ([self pointInside:point withEvent:event] == NO) {return nil;}
    
    // 3.从后往前遍历自己的子控件
    NSInteger subViewCoutn = self.subviews.count;
    for (NSInteger i = subViewCoutn - 1; i >= 0; i--) {
        UIView *childView = self.subviews[i];
        CGPoint childP = [self convertPoint:point toView:childView];
        UIView *fitView = [childView hitTest:childP withEvent:event];
        if (fitView) {
            return fitView;
        }
    }

    return nil;
}

#pragma mark - Public Method

- (void)microphoneButtonOpen:(BOOL)open{
    [self.toolbarView microphoneButtonOpen:open];
}

- (void)cameraButtonOpen:(BOOL)open{
    [self.toolbarView cameraButtonOpen:open];
}

- (void)cameraSwitchButtonFront:(BOOL)front{
    [self.toolbarView cameraSwitchButtonFront:front];
}

- (void)startClass:(BOOL)start {
    [self.chatroomListView startClass:start];
}

- (void)setNetState:(NSInteger)netState {
    self.remindSheet.netState = netState;
}

- (void)logout {
    [self stopRemindMessageTimer];
    [[PLVLSChatroomViewModel sharedViewModel] removeAllDelegates];
}

- (void)documentChangeFullScreen:(BOOL)fullScreen {
    self.documentFullScreen = fullScreen;
    if (fullScreen &&
        [PLVRoomDataManager sharedManager].roomData.menuInfo.remindEnabled &&
        !_remindMessageTimer.isValid) {
        [self startRemindMessageTimer];
    }
}

- (void)cancleTopPinMessage {
    BOOL success = [[PLVLSChatroomViewModel sharedViewModel] sendPinMessageWithMsgId:nil toTop:NO];
    if (!success) {
        plv_dispatch_main_async_safe((^{
            NSString *message = [NSString stringWithFormat:@"%@%@", PLVLocalizedString(@"下墙"), PLVLocalizedString(@"消息发送失败")];
            [PLVLSUtils showToastWithMessage:message inView:[PLVLSUtils sharedUtils].homeVC.view afterDelay:3];
        }))
    }
}

#pragma mark - Setter

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (hidden) {
        [self.toolbarView hideButton];
    }
}

#pragma mark - Getter

- (PLVLSSendMessageView *)sendMsgView {
    if (!_sendMsgView) {
        _sendMsgView = [[PLVLSSendMessageView alloc] init];
    }
    return _sendMsgView;
}

- (PLVLSChatroomListView *)chatroomListView {
    if (!_chatroomListView) {
        _chatroomListView = [[PLVLSChatroomListView alloc] init];
        
        __weak typeof(self) weakSelf = self;
        _chatroomListView.didScrollTableViewUp = ^{
            [weakSelf clearNewMessageCount];
        };
        _chatroomListView.didTapReplyMenuItem = ^(PLVChatModel * _Nonnull model) {
            [weakSelf.sendMsgView showWithChatModel:model];
        };
    }
    return _chatroomListView;
}

- (PLVLSNewMessageView *)receiveNewMessageView {
    if (!_receiveNewMessageView) {
        _receiveNewMessageView = [[PLVLSNewMessageView alloc] init];
        [_receiveNewMessageView updateMessageCount:0];
        
        __weak typeof(self) weakSelf = self;
        _receiveNewMessageView.didTapNewMessageView = ^{
            [weakSelf clearNewMessageCount];
            [weakSelf.chatroomListView scrollsToBottom:YES];
        };
    }
    return _receiveNewMessageView;
}

- (UIButton *)hideListViewButton {
    if (!_hideListViewButton) {
        _hideListViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_show_btn"];
        UIImage *selectedImage = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_hide_btn"];
        [_hideListViewButton setImage:normalImage forState:UIControlStateNormal];
        [_hideListViewButton setImage:selectedImage forState:UIControlStateSelected];
        [_hideListViewButton addTarget:self action:@selector(hideListViewButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hideListViewButton;
}

- (UIButton *)remindButton {
    if (!_remindButton) {
        _remindButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_remind_entrance"];
        [_remindButton setImage:normalImage forState:UIControlStateNormal];
        [_remindButton addTarget:self action:@selector(remindButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_remindButton addSubview:self.remindBadgeView];
        _remindButton.hidden = YES;
    }
    return _remindButton;
}

- (UIView *)remindBadgeView {
    if (!_remindBadgeView) {
        _remindBadgeView = [[UIView alloc] init];
        _remindBadgeView.backgroundColor = [PLVColorUtil colorFromHexString:@"#FF6363"];
        _remindBadgeView.layer.cornerRadius = 3;
        _remindBadgeView.layer.masksToBounds = YES;
        _remindBadgeView.hidden = YES;
    }
    return _remindBadgeView;
}

- (UIView *)leftToolView {
    if (!_leftToolView) {
        _leftToolView = [[UIView alloc] init];
        _leftToolView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.4];
        _leftToolView.layer.cornerRadius = 16;
    }
    return _leftToolView;
}

- (PLVLSChatroomToolbar *)toolbarView {
    if (!_toolbarView) {
        _toolbarView = [[PLVLSChatroomToolbar alloc] init];
        
        __weak typeof(self) weakSelf = self;
        _toolbarView.didTapMicrophoneButton = ^(BOOL open) {
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(chatroomAreaView_didTapMicrophoneButton:)]) {
                [weakSelf.delegate chatroomAreaView_didTapMicrophoneButton:open];
            }
        };
        _toolbarView.didTapCameraButton = ^(BOOL open) {
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(chatroomAreaView_didTapCameraButton:)]) {
                [weakSelf.delegate chatroomAreaView_didTapCameraButton:open];
            }
        };
        _toolbarView.didTapCameraSwitchButton = ^{
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(chatroomAreaView_didTapCameraSwitchButton)]) {
                [weakSelf.delegate chatroomAreaView_didTapCameraSwitchButton];
            }
        };
        _toolbarView.didTapSendMessageButton = ^{
            [weakSelf.sendMsgView show];
        };
    }
    return _toolbarView;
}

- (PLVLSRemindChatroomSheet *)remindSheet {
    if (!_remindSheet) {
        _remindSheet = [[PLVLSRemindChatroomSheet alloc] initWithSheetWidth:[UIScreen mainScreen].bounds.size.width * 425 / 812];
    }
    return _remindSheet;
}

#pragma mark - Action

- (void)hideListViewButtonAction {
    self.remindNewMessageCount = 0; // 置空 提醒消息未读消息条数
    self.hideListViewButton.selected = !self.hideListViewButton.selected;
    self.chatroomListView.hidden = self.hideListViewButton.selected;
    if ([PLVRoomDataManager sharedManager].roomData.menuInfo.remindEnabled &&
        self.hideListViewButton.selected &&
        !_remindMessageTimer.isValid) {
        [self startRemindMessageTimer];
    } else {
        [self stopRemindMessageTimer];
    }
}

- (void)remindButtonAction {
    self.remindNewMessageCount = 0; // 置空 提醒消息未读消息条数
    self.remindBadgeView.hidden = YES;
    [self.remindSheet showInView:[PLVLSUtils sharedUtils].homeVC.view];
}

- (void)remindMessageTimerEvent:(NSTimer *)timer {
    // 公屏&私聊聊天室隐藏且存在未读私聊消息时，提醒用户查看
    if ([PLVRoomDataManager sharedManager].roomData.menuInfo.remindEnabled &&
        self.remindNewMessageCount > 0 &&
        ((!_remindSheet.superview &&
        self.chatroomListView.hidden) || self.documentFullScreen)) {
        NSString *message = [NSString stringWithFormat:PLVLocalizedString(@"您当前有%lu条私聊消息，请及时查看"), (unsigned long)self.remindNewMessageCount];
        [PLVLSUtils showToastWithMessage:message inView:[PLVLSUtils sharedUtils].homeVC.view afterDelay:5];
    }
}

#pragma mark - Private Method

- (void)addNewMessageCount {
    self.newMessageCount ++;
    [self.receiveNewMessageView updateMessageCount:self.newMessageCount];
}

- (void)clearNewMessageCount {
    if (self.newMessageCount == 0) {
        return ;
    }
    self.newMessageCount = 0;
    [self.receiveNewMessageView updateMessageCount:0];
}

- (void)handleReceiveRemindMessages {
    if ([PLVRoomDataManager sharedManager].roomData.menuInfo.remindEnabled &&
        !_remindSheet.superview) { // 开启提醒消息&提醒消息聊天室未显示
        self.remindBadgeView.hidden = NO; // 显示红点
        
        if (self.chatroomListView.hidden ||
            self.documentFullScreen) { // 公屏聊天室已隐藏/文档已全屏
            self.remindNewMessageCount += 1;
        } else {
            self.remindNewMessageCount = 0;
        }
    }
}

#pragma mark Timer

- (void)startRemindMessageTimer {
    self.remindMessageTimer = [NSTimer scheduledTimerWithTimeInterval:remindMessageTimerInterval target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(remindMessageTimerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.remindMessageTimer forMode:NSRunLoopCommonModes];
    [self.remindMessageTimer fire];
}

- (void)stopRemindMessageTimer {
    [_remindMessageTimer invalidate];
    _remindMessageTimer = nil;
}

#pragma mark - PLVLSChatroomViewModel Protocol

- (void)chatroomViewModel_didSendMessage {
    plv_dispatch_main_async_safe(^{
        [self.chatroomListView didSendMessage];
        [self clearNewMessageCount];
    })
}

- (void)chatroomViewModel_didSendProhibitMessage {
    plv_dispatch_main_async_safe(^{
        [self.chatroomListView didSendMessage];
        [self clearNewMessageCount];
    })
}

- (void)chatroomViewModel_didReceiveMessages {
    plv_dispatch_main_async_safe(^{
        BOOL isBottom = [self.chatroomListView didReceiveMessages];
        if (isBottom) { // tableview显示在最底部
            [self clearNewMessageCount];
        } else {
            // 统计未读消息数
            [self addNewMessageCount];
        }
    })
}

- (void)chatroomViewModel_didReceiveRemindMessages {
    plv_dispatch_main_async_safe(^{
        [self handleReceiveRemindMessages];
    })
}

- (void)chatroomViewModel_didMessageDeleted {
    plv_dispatch_main_async_safe(^{
        [self.chatroomListView didMessageDeleted];
    })
}

- (void)chatroomViewModel_didMessageCountLimitedAutoDeleted {
    plv_dispatch_main_async_safe(^{
        [self.chatroomListView didMessageCountLimitedAutoDeleted];
    })
}

- (void)chatroomViewModel_loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    plv_dispatch_main_async_safe(^{
        [self.chatroomListView loadHistorySuccess:noMore firstTime:first];
    })
}

- (void)chatroomViewModel_loadHistoryFailure {
    plv_dispatch_main_async_safe(^{
        [self.chatroomListView loadHistoryFailure];
    })
}

- (void)chatroomViewModel_loadImageEmotionSuccess:(NSArray<NSDictionary *> *)dictArray {
    //图片表情资源加载成功
    plv_dispatch_main_async_safe(^{
        self.sendMsgView.imageEmotionArray = dictArray;
    })
}

- (void)chatroomViewModel_loadImageEmotionFailure {
    plv_dispatch_main_async_safe(^{
        [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"图片表情资源加载失败")];
    })
}

@end
