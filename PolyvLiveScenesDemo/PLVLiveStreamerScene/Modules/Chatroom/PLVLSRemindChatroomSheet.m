//
//  PLVLSRemindChatroomSheet.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/11.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSRemindChatroomSheet.h"
// 工具类
#import "PLVLSUtils.h"
// UI
#import "PLVLSRemindChatroomListView.h"
#import "PLVLSSendMessageView.h"
#import "PLVLSNewRemindMessageView.h"

// 模块
#import "PLVLSChatroomViewModel.h"
// 依赖库
#import <MJRefresh/MJRefresh.h>

@interface PLVLSRemindChatroomSheet()<
PLVLSChatroomViewModelProtocol
>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) PLVLSRemindChatroomListView *remindListView;
@property (nonatomic, strong) MJRefreshNormalHeader *refresher; // 列表顶部加载更多控件
@property (nonatomic, strong) UIButton *inputMsgButton;
@property (nonatomic, strong) PLVLSSendMessageView *sendMsgView; // 发送消息输入框视图
@property (nonatomic, strong) PLVLSNewRemindMessageView *receiveNewMessageView;

/// 数据
@property (nonatomic, assign) NSUInteger newMessageCount; // 未读消息条数

@end

@implementation PLVLSRemindChatroomSheet {
    dispatch_queue_t chatroomViewModelDelegateQueue;
}

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth {
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        chatroomViewModelDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        [[PLVLSChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:chatroomViewModelDelegateQueue];
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize selfSize = self.bounds.size;
    CGFloat top = PLVLSUtils.safeTopPad;
    CGFloat bottom = PLVLSUtils.safeBottomPad + 20;
    CGFloat left = 16;
    CGFloat width = self.sheetWidth - left * 2;
    self.titleLabel.frame = CGRectMake(left, top, width, 40);
    self.lineView.frame = CGRectMake(left, CGRectGetMaxY(self.titleLabel.frame), width, 1);
    self.inputMsgButton.frame = CGRectMake(left, selfSize.height - bottom - 36, width, 36);
    self.remindListView.frame = CGRectMake(left, CGRectGetMaxY(self.lineView.frame), width, selfSize.height - CGRectGetMaxY(self.lineView.frame) - bottom - 36 - 8);
    self.receiveNewMessageView.frame = CGRectMake(0, self.remindListView.frame.size.height - 28 - 8, 86, 28);
}

#pragma mark - [ Public Method ]
- (void)setNetState:(NSInteger)netState {
    _netState = netState;
    
    self.remindListView.netState = netState;
    [self updateInputButtonNetState:netState];
}

#pragma mark - [ Private Method ]
#pragma mark Getter
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"管理员私聊";
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];
        _titleLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _titleLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.1];
    }
    return _lineView;
}

- (PLVLSRemindChatroomListView *)remindListView {
    if (!_remindListView) {
        _remindListView = [[PLVLSRemindChatroomListView alloc] init];
        __weak typeof(self) weakSelf = self;
        _remindListView.didScrollTableViewUp = ^{
            [weakSelf clearNewMessageCount];
        };
        _remindListView.didScrollTableViewTwoScreens = ^{
            [weakSelf.receiveNewMessageView updateScrollMessage];
        };
    }
    return _remindListView;
}

- (MJRefreshNormalHeader *)refresher {
    if (!_refresher) {
        _refresher = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshAction:)];
        _refresher.lastUpdatedTimeLabel.hidden = YES;
        _refresher.stateLabel.hidden = YES;
        [_refresher.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    }
    return _refresher;
}

- (UIButton *)inputMsgButton {
    if (!_inputMsgButton) {
        _inputMsgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _inputMsgButton.backgroundColor = [UIColor colorWithRed:71/255.0 green:75/255.0 blue:87/255.0 alpha:1/1.0];
        [_inputMsgButton setImage:[PLVLSUtils imageForChatroomResource:@"plvls_chatroom_remind_input@2x"] forState:UIControlStateNormal];
        [_inputMsgButton setTitle:@"当前无网络，请设置网络再参与互动" forState:UIControlStateNormal];
        _inputMsgButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_inputMsgButton setTitleColor:[PLVColorUtil colorFromHexString:@"#878B93"] forState:UIControlStateNormal];
        _inputMsgButton.layer.cornerRadius = 16;
        _inputMsgButton.layer.masksToBounds = YES;
        _inputMsgButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _inputMsgButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _inputMsgButton.imageEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 0);
        _inputMsgButton.titleEdgeInsets = UIEdgeInsetsMake(0, 18, 0, 0);
        [_inputMsgButton addTarget:self action:@selector(inputMsgButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _inputMsgButton;
}

- (PLVLSSendMessageView *)sendMsgView {
    if (!_sendMsgView) {
        _sendMsgView = [[PLVLSSendMessageView alloc] initWithRemindMsg:YES];
    }
    return _sendMsgView;
}

- (PLVLSNewRemindMessageView *)receiveNewMessageView {
    if (!_receiveNewMessageView) {
        _receiveNewMessageView = [[PLVLSNewRemindMessageView alloc] init];
        [_receiveNewMessageView updateMessageCount:0];
        
        __weak typeof(self) weakSelf = self;
        _receiveNewMessageView.didTapNewMessageView = ^{
            [weakSelf clearNewMessageCount];
            [weakSelf.remindListView scrollsToBottom:YES];
        };
    }
    return _receiveNewMessageView;
}

#pragma mark Init
- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.remindListView];
    [self.contentView addSubview:self.inputMsgButton];
    [self.remindListView addSubview:self.receiveNewMessageView];
    
    [self sendMsgView];// 提前初始化 sendMsgView，避免弹出时才初始化导致卡顿
}

#pragma mark 未读消息提示
- (void)addNewMessageCount {
    self.newMessageCount ++;
    [self.receiveNewMessageView updateMessageCount:self.newMessageCount];
}

- (void)clearNewMessageCount {
    self.newMessageCount = 0;
    [self.receiveNewMessageView updateMessageCount:0];
}

#pragma mark 网络异常提示
- (void)updateInputButtonNetState:(NSInteger)netState {
    if ([self netCan]) {
        [self.inputMsgButton setTitle:@"有话要说..." forState:UIControlStateNormal];
    } else {
        [self.inputMsgButton setTitle:@"当前无网络，请设置网络再参与互动" forState:UIControlStateNormal];
    }
}

#pragma mark 网络是否可用
- (BOOL)netCan{
    return self.netState == 1;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVLSChatroomViewModel sharedViewModel] loadRemindHistory];
}

- (void)inputMsgButtonAction {
    if (![self netCan]) {
        [PLVLSUtils showToastWithMessage:@"请检查网络设置" inView:[PLVLSUtils sharedUtils].homeVC.view];
        return;
    }
    
    [self.sendMsgView show];
}

#pragma mark PLVLSChatroomViewModelProtocol

- (void)chatroomViewModel_didSendMessage {
    plv_dispatch_main_async_safe(^{
        [self.remindListView didSendMessage];
        [self clearNewMessageCount];
    })
}

- (void)chatroomViewModel_didSendProhibitMessage {
    plv_dispatch_main_async_safe(^{
        [self.remindListView didSendMessage];
        [self clearNewMessageCount];
    })
}

- (void)chatroomViewModel_didReceiveRemindMessages {
    plv_dispatch_main_async_safe(^{
        BOOL isBottom = [self.remindListView didReceiveMessages];
        if (isBottom) { // tableview显示在最底部
            [self clearNewMessageCount];
        } else { // 统计未读消息数
            [self addNewMessageCount];
        }
    })
}

- (void)chatroomViewModel_didMessageDeleted {
    plv_dispatch_main_async_safe(^{
        [self.remindListView didMessageDeleted];
    })
}

- (void)chatroomViewModel_loadRemindHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    plv_dispatch_main_async_safe(^{
        [self.remindListView loadHistorySuccess:noMore firstTime:first];
    })
}

- (void)chatroomViewModel_loadRemindHistoryFailure {
    plv_dispatch_main_async_safe(^{
        [self.remindListView loadHistoryFailure];
    })
}

@end
