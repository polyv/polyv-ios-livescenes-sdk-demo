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

// UI
#import "PLVLSNewMessageView.h"
#import "PLVLSChatroomToolbar.h"
#import "PLVLSChatroomListView.h"
#import "PLVLSSendMessageView.h"

// 工具类
#import "PLVLSUtils.h"

@interface PLVLSChatroomAreaView ()<
PLVLSChatroomViewModelProtocol
>

/// UI
@property (nonatomic, strong) PLVLSSendMessageView *sendMsgView; // 发送消息输入框视图
@property (nonatomic, strong) PLVLSChatroomListView *chatroomListView;
@property (nonatomic, strong) PLVLSNewMessageView *receiveNewMessageView;
@property (nonatomic, strong) UIButton *hideListViewButton;
@property (nonatomic, strong) PLVLSChatroomToolbar *toolbarView;

/// 数据
@property (nonatomic, assign) NSUInteger newMessageCount; // 未读消息条数

@end

@implementation PLVLSChatroomAreaView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.chatroomListView];
        [self addSubview:self.hideListViewButton];
        [self addSubview:self.toolbarView];
        
        [self.chatroomListView addSubview:self.receiveNewMessageView];
        
        [PLVLSChatroomViewModel sharedViewModel].delegate = self;
        
        // 提前初始化 sendMsgView，避免弹出时才初始化导致卡顿
        [self sendMsgView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat areaViewWidth = self.bounds.size.width;
    CGFloat areaViewHeight = self.bounds.size.height;
    self.chatroomListView.frame = CGRectMake(8, 0, areaViewWidth - 8, areaViewHeight - 36 - 8 * 2);
    self.hideListViewButton.frame = CGRectMake(8, areaViewHeight - 8 - 36, 36, 36);
    self.toolbarView.frame = CGRectMake(CGRectGetMaxX(self.hideListViewButton.frame) + 12, CGRectGetMinY(self.hideListViewButton.frame), 252, 36);
    
    self.receiveNewMessageView.frame = CGRectMake(0, self.chatroomListView.frame.size.height - 28, 86, 28);
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
        [_receiveNewMessageView updateMeesageCount:0];
        
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

#pragma mark - Action

- (void)hideListViewButtonAction {
    self.hideListViewButton.selected = !self.hideListViewButton.selected;
    self.chatroomListView.hidden = self.hideListViewButton.selected;
}

#pragma mark - Private Method

- (void)addNewMessageCount {
    self.newMessageCount ++;
    [self.receiveNewMessageView updateMeesageCount:self.newMessageCount];
}

- (void)clearNewMessageCount {
    self.newMessageCount = 0;
    [self.receiveNewMessageView updateMeesageCount:0];
}

#pragma mark - PLVLSChatroomViewModel Protocol

- (void)chatroomViewModel_didSendMessage {
    [self.chatroomListView didSendMessage];
    [self clearNewMessageCount];
}

- (void)chatroomViewModel_didReceiveMessages {
    BOOL isBottom = [self.chatroomListView didReceiveMessages];
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
}

- (void)chatroomViewModel_didMessageDeleted {
    [self.chatroomListView didMessageDeleted];
}

- (void)chatroomViewModel_loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    [self.chatroomListView loadHistorySuccess:noMore firstTime:first];
}

- (void)chatroomViewModel_loadHistoryFailure {
    [self.chatroomListView loadHistoryFailure];;
}

- (void)chatroomViewModel_loadEmotionSuccess {
    //图片表情资源加载成功
    self.sendMsgView.imageEmotionArray = [PLVLSChatroomViewModel sharedViewModel].imageEmotionArray;
}

@end
