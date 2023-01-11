//
//  PLVSAChatroomAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChatroomAreaView.h"

// 工具类
#import "PLVSAUtils.h"

// UI
#import "PLVSANewMessgaeTipView.h"
#import "PLVSAChatroomListView.h"
#import "PLVSASendMessageView.h"
#import "PLVSAChatroomWelcomView.h"
#import "PLVSAChatroomGiftView.h"

/// 模块
#import "PLVSAChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import "PLVChatModel.h"

@interface PLVSAChatroomAreaView ()<
PLVSAChatroomViewModelDelegate,
PLVSAChatroomListViewDelegate
>

/// view hierarchy
///
/// (UIView) superview
///  └── (PLVSAChatroomAreaView) self (lowest)
///    ├── (PLVSAChatroomWelcomView) welcomView
///    ├── (PLVSAChatroomGiftView) giftView
///    ├── (PLVSAChatroomListView) chatroomListView
///         ├── (PLVSANewMessgaeTipView) receiveNewMessageView
///    ├── (PLVSASendMessageView) sendMsgView
///
/// UI

@property (nonatomic, strong) PLVSAChatroomWelcomView *welcomView; // 新用户进入欢迎视图
@property (nonatomic, strong) PLVSAChatroomGiftView *giftView;  // 礼物视图

@property (nonatomic, strong) PLVSAChatroomListView *chatroomListView; // 聊天室列表
@property (nonatomic, strong) PLVSASendMessageView *sendMsgView; // 发送消息输入框视图
@property (nonatomic, strong) PLVSANewMessgaeTipView *receiveNewMessageView; // 新消息提示视图


/// 数据
@property (nonatomic, assign) NSUInteger newMessageCount; // 未读消息条数
@property (nonatomic, assign) CGRect originWelcomViewFrame; // 新用户进入欢迎视图原frame

@end

@implementation PLVSAChatroomAreaView

@synthesize closeRoom = _closeRoom;

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.chatroomListView];
       
        [self.chatroomListView addSubview:self.receiveNewMessageView];
        
        [self addSubview:self.welcomView];
        
        [PLVSAChatroomViewModel sharedViewModel].delegate = self;
        
        // 提前初始化 sendMsgView，避免弹出时才初始化导致卡顿
        [self sendMsgView];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat areaViewWidth = self.bounds.size.width;
    CGFloat areaViewHeight = self.bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL landscape = [PLVSAUtils sharedUtils].landscape;
    
    CGFloat chatroomListViewLeft = isPad ? 24 : (landscape ? 36 : 8);
    self.chatroomListView.frame = CGRectMake(chatroomListViewLeft, 0, areaViewWidth - chatroomListViewLeft, areaViewHeight);
    self.receiveNewMessageView.frame = CGRectMake(0, self.chatroomListView.frame.size.height - 28, 86, 24);
    
    self.welcomView.frame = CGRectMake(0, MAX(CGRectGetMinY(self.chatroomListView.frame)-22-15 , 0), 258, 22);
    
    _giftView.frame = CGRectMake(0, CGRectGetMinY(self.welcomView.frame)- 40 - 15, 270, 40);
}

#pragma mark - [ Public Method ]

#pragma mark - [ Private Method ]

- (void)addNewMessageCount {
    self.newMessageCount ++;
    [self.receiveNewMessageView updateMeesageCount:self.newMessageCount];
}

- (void)clearNewMessageCount {
    self.newMessageCount = 0;
    [self.receiveNewMessageView updateMeesageCount:0];
}

#pragma mark Getter

- (PLVSASendMessageView *)sendMsgView {
    if (!_sendMsgView) {
        _sendMsgView = [[PLVSASendMessageView alloc] init];
        _sendMsgView.imageEmotionArray = [PLVSAChatroomViewModel sharedViewModel].imageEmotionArray;
    }
    return _sendMsgView;
}

- (PLVSAChatroomListView *)chatroomListView {
    if (!_chatroomListView) {
        _chatroomListView = [[PLVSAChatroomListView alloc] init];
        _chatroomListView.delegate = self;
    }
    return _chatroomListView;
}

- (PLVSANewMessgaeTipView *)receiveNewMessageView {
    if (!_receiveNewMessageView) {
        _receiveNewMessageView = [[PLVSANewMessgaeTipView alloc] init];
        [_receiveNewMessageView updateMeesageCount:0];
        
        __weak typeof(self) weakSelf = self;
        _receiveNewMessageView.didTapNewMessageView = ^{
            [weakSelf clearNewMessageCount];
            [weakSelf.chatroomListView scrollsToBottom:YES];
        };
    }
    return _receiveNewMessageView;
}

- (PLVSAChatroomWelcomView *)welcomView {
    if (!_welcomView) {
        _welcomView = [[PLVSAChatroomWelcomView alloc] init];
        _welcomView.hidden = YES;
    }
    return _welcomView;
}

- (PLVSAChatroomGiftView *)giftView {
    if (!_giftView) {
        _giftView = [[PLVSAChatroomGiftView alloc] init];
        [self addSubview:_giftView];
    }
    return _giftView;
}

- (BOOL)closeRoom {
    return [PLVChatroomManager sharedManager].closeRoom;
}

#pragma mark Setter

- (void)setCloseRoom:(BOOL)closeRoom {
    _closeRoom = closeRoom;
    
    // 与socket最真实状态校验，更新UI，防止误操作
    if ([PLVChatroomManager sharedManager].closeRoom == closeRoom) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(chatroomAreaView:DidChangeCloseRoom:)]) {
            [self.delegate chatroomAreaView:self DidChangeCloseRoom:[PLVChatroomManager sharedManager].closeRoom];
        }
        return;
    }
    BOOL sendSuccess = [[PLVChatroomManager sharedManager] sendCloseRoom:closeRoom];
    if (sendSuccess) {
        NSString *string = _closeRoom ? @"已开启全体禁言" : @"已解除全体禁言";
        [PLVSAUtils showToastInHomeVCWithMessage:string];
    }
}

#pragma mark 显示欢迎语

- (void)showWelcomeWithMessage:(NSString *)welcomeMessage {
    if (!self.welcomView.hidden) {
        [self shutdownWelcomView];
    }
    
    self.welcomView.hidden = NO;
    
    CGFloat duration = 2.0;
    self.welcomView.messageLabel.text = welcomeMessage;
    [UIView animateWithDuration:1.0 animations:^{
       CGRect newFrame = self.welcomView.frame;
       newFrame.origin.x = 0;
       self.welcomView.frame = newFrame;
    }];

    SEL shutdownWelcomView = @selector(shutdownWelcomView);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:shutdownWelcomView object:nil];
    [self performSelector:shutdownWelcomView withObject:nil afterDelay:duration];
}

- (void)shutdownWelcomView {
    self.welcomView.hidden = YES;
    self.welcomView.frame = self.originWelcomViewFrame;
}

#pragma mark - Event

#pragma mark - Delegate
#pragma mark PLVSAChatroomViewModel Protocol

- (void)chatroomViewModelDidSendMessage:(PLVSAChatroomViewModel *)viewModel {
    [self.chatroomListView didSendMessage];
    [self clearNewMessageCount];
    
    if ([PLVSAChatroomViewModel sharedViewModel].chatArray.count > 10) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomAreaView_showSlideRightView)]) {
            [self.delegate chatroomAreaView_showSlideRightView];
        }
    }
}

- (void)chatroomViewModelDidResendMessage:(PLVSAChatroomViewModel *)viewModel {
    [self.chatroomListView didSendMessage];
    [self clearNewMessageCount];
}

- (void)chatroomViewModelDidSendProhibitMessgae:(PLVSAChatroomViewModel *)viewModel {
    [self.chatroomListView didSendMessage];
    [self clearNewMessageCount];
}

- (void)chatroomViewModelDidReceiveMessages:(PLVSAChatroomViewModel *)viewModel {
    BOOL isBottom = [self.chatroomListView didReceiveMessages];
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
    if ([PLVSAChatroomViewModel sharedViewModel].chatArray.count > 10) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomAreaView_showSlideRightView)]) {
            [self.delegate chatroomAreaView_showSlideRightView];
        }
    }

}

- (void)chatroomViewModelDidMessageDeleted:(PLVSAChatroomViewModel *)viewModel {
    [self.chatroomListView didMessageDeleted];
}

- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    [self.chatroomListView loadHistorySuccess:noMore firstTime:first];
}

- (void)chatroomViewModelLoadHistoryFailure:(PLVSAChatroomViewModel *)viewModel {
    [self.chatroomListView loadHistoryFailure];;
}

- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel loginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray {
    NSString *string = @"";
    if (!userArray) {
        string = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerName;
    }
    
    if (userArray && [userArray count] > 0) {
        if ([userArray count] >= 10) {
            NSMutableString *mutableString = [[NSMutableString alloc] init];
            for (int i = 0; i < 3; i++) {
                PLVChatUser *user = userArray[i];
                if (user.userName && user.userName.length > 0) {
                    [mutableString appendFormat:@"%@、", user.userName];
                }
            }
            if (mutableString.length > 1) {
                string = [[mutableString copy] substringToIndex:mutableString.length - 1];
                string = [NSString stringWithFormat:@"%@等%zd人", string, [userArray count]];
            }
        } else {
            PLVChatUser *user = userArray[0];
            string = user.userName;
        }
    }
    
    if (string.length > 0) {
        NSString *welcomeMessage = [NSString stringWithFormat:@"欢迎 %@ 进入直播间", string];
        [self showWelcomeWithMessage:welcomeMessage];
    }
}

- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel giftNickName:(nonnull NSString *)nickName giftImageUrl:(nonnull NSString *)giftImageUrl giftNum:(NSInteger)giftNum giftContent:(nonnull NSString *)giftContent {
    [self.giftView showGiftAnimation:nickName giftImageUrl:giftImageUrl giftNum:giftNum giftContent:giftContent];
}

- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel giftNickName:(NSString *)nickName cashGiftContent:(NSString *)cashGiftContent {
    [self.giftView showGiftAnimation:nickName cashGiftContent:cashGiftContent];
}

- (void)chatroomViewModel_loadImageEmotionSuccess:(NSArray<NSDictionary *> *)dictArray {
    self.sendMsgView.imageEmotionArray = dictArray;
}

- (void)chatroomViewModel_loadImageEmotionFailure {
    [PLVSAUtils showToastInHomeVCWithMessage:@"图片表情资源加载失败"];
}

#pragma mark PLVSAChatroomListViewDelegate

- (void)chatroomListViewDidScrollTableViewUp:(PLVSAChatroomListView *)listView {
    [self clearNewMessageCount];
}

- (void)chatroomListView:(PLVSAChatroomListView *)listView didTapReplyMenuItem:(PLVChatModel *)model {
    [self.sendMsgView showWithChatModel:model];
}

- (void)chatroomListView:(PLVSAChatroomListView *)listView alertLongContentMessage:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomAreaView:alertLongContentMessage:)]) {
        [self.delegate chatroomAreaView:self alertLongContentMessage:model];
    }
}

@end
