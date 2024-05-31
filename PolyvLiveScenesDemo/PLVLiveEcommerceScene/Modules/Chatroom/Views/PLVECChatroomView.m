//
//  PLVChatroomView.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECChatroomView.h"
#import "PLVECWelcomView.h"
#import "PLVECChatroomMessageView.h"
#import "PLVECKeyboardToolView.h"
#import "PLVECUtils.h"
#import "PLVECChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLiveToast.h"
#import "PLVRewardDisplayManager.h"
#import "PLVECChatroomPlaybackViewModel.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVECChatroomView () <
PLVECChatroomViewModelProtocol,
PLVECChatroomPlaybackDelegate,
PLVECChatroomPlaybackViewModelDelegate,
PLVECKeyboardToolViewDelegate,
PLVECChatroomMessageViewDelegate
>

/// 聊天列表
@property (nonatomic, strong) PLVECChatroomMessageView *messageView;
/// 打赏成功提示条幅
@property (nonatomic, strong) PLVRewardDisplayManager *rewardDisplayManager;
/// 条幅视图
@property (nonatomic, strong) UIView *rewardDisplayView;
/// 聊天室工具栏
@property (nonatomic, strong) PLVECKeyboardToolView *keyboardToolView;
@property (nonatomic, strong) PLVECWelcomView *welcomView;
@property (nonatomic, strong) UIImageView *receiveAQMessageImgView;
@property (nonatomic, assign) CGRect originWelcomViewFrame;
/// 聊天室是否处于聊天回放状态，默认为NO
@property (nonatomic, assign) BOOL playbackEnable;
/// 聊天重放viewModel
@property (nonatomic, strong) PLVECChatroomPlaybackViewModel *playbackViewModel;
/// 当前视频类型
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType;
/// 输入框的Y坐标
@property (nonatomic, assign, readonly) CGFloat textViewAreaRectY;
/// 是否启用提问功能
@property (nonatomic, assign) BOOL enableQuiz;

@end

@implementation PLVECChatroomView

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [self initWithFrame:CGRectZero];
    if (self) {
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.playbackEnable = roomData.menuInfo.chatInputDisable && roomData.videoType == PLVChannelVideoType_Playback;
        
        if (self.videoType == PLVChannelVideoType_Live) { // 直播一定会显示聊天室
            [[PLVECChatroomViewModel sharedViewModel] setup];
            [[PLVECChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        } else { // 回放时只有chatInputDisable为YES时会显示聊天室
            [[PLVECChatroomViewModel sharedViewModel] setup];
        }
        
        self.backgroundColor = UIColor.clearColor;
        self.enableQuiz = NO;
        self.welcomView = [[PLVECWelcomView alloc] init];
        self.welcomView.hidden = YES;
        [self addSubview:self.welcomView];
        [self addSubview:self.rewardDisplayView];
        [self addSubview:self.messageView];
        
        if (self.videoType == PLVChannelVideoType_Live) { // 聊天重放时聊天室不允许发消息
            for (PLVLiveVideoChannelMenu *menu in roomData.menuInfo.channelMenus) {
                if ([menu.menuType isEqualToString:@"quiz"]) {
                    self.enableQuiz = YES;
                    break;
                }
            }
            
            [self.keyboardToolView addTextViewToParentView:self];
            self.keyboardToolView.enableAskQuestion = self.enableQuiz;
            if (self.enableQuiz) {
                [self addSubview:self.receiveAQMessageImgView];
            }
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat tableViewHeight = [PLVECUtils sharedUtils].isLandscape ? self.bounds.size.height * 0.4 :217;
    CGRect keyboardViewRect= CGRectMake(15, self.textViewAreaRectY, 165, 32);
    [self.keyboardToolView updateTextViewFrame:keyboardViewRect];
    self.receiveAQMessageImgView.frame = CGRectMake(CGRectGetMaxX(self.keyboardToolView.inactivatedTextAreaView.frame) - 22, CGRectGetMinY(self.keyboardToolView.inactivatedTextAreaView.frame) - 8, 38, 14);
    if (!self.keyboardToolView.keyboardActivated) {
        self.messageView.frame = CGRectMake(15, self.textViewAreaRectY - tableViewHeight - 10, 280, tableViewHeight);
    }
    self.welcomView.frame = CGRectMake(-258, CGRectGetMinY(self.messageView.frame)-22-15, 258, 22);
    self.originWelcomViewFrame = self.welcomView.frame;
    self.rewardDisplayView.frame = CGRectMake(0, CGRectGetMidY(self.bounds) - 150/2, MIN(PLVScreenWidth, PLVScreenHeight), CGRectGetHeight(self.bounds) - CGRectGetMidY(self.bounds) + 150/2);
}

#pragma mark - Getter
- (PLVECKeyboardToolView *)keyboardToolView {
    if (!_keyboardToolView) {
        _keyboardToolView = [[PLVECKeyboardToolView alloc] init];
        _keyboardToolView.delegate = self;
    }
    return _keyboardToolView;
}

- (PLVRewardDisplayManager *)rewardDisplayManager{
    if (!_rewardDisplayManager) {
        _rewardDisplayManager = [[PLVRewardDisplayManager alloc] initWithLiveType:PLVRewardDisplayManagerTypeEC];
        _rewardDisplayManager.superView = self.rewardDisplayView;
    }
    return _rewardDisplayManager;
}

- (UIView *)rewardDisplayView {
    if (!_rewardDisplayView) {
        _rewardDisplayView = [[UIView alloc]init];
        _rewardDisplayView.backgroundColor = [UIColor clearColor];
        _rewardDisplayView.userInteractionEnabled = NO;
    }
    return _rewardDisplayView;
}

- (PLVECChatroomMessageView *)messageView {
    if (!_messageView) {
        _messageView = [[PLVECChatroomMessageView alloc]init];
        _messageView.delegate = self;
    }
    return _messageView;
}

- (UIImageView *)receiveAQMessageImgView {
    if (!_receiveAQMessageImgView) {
        _receiveAQMessageImgView = [[UIImageView alloc] init];
        _receiveAQMessageImgView.image = [PLVECUtils imageForWatchResource:@"plv_chatroom_receive_askquestion_icon"];
        UILabel *messageLabel = [[UILabel alloc] init];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.frame = CGRectMake(0, 0, 38, 14);
        messageLabel.font = [UIFont systemFontOfSize:8];
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.text = PLVLocalizedString(@"新消息");
        [_receiveAQMessageImgView addSubview:messageLabel];
        _receiveAQMessageImgView.hidden = YES;
    }
    return _receiveAQMessageImgView;
}

- (PLVChannelVideoType)videoType {
    return [PLVRoomDataManager sharedManager].roomData.videoType;
}

- (CGFloat)textViewAreaRectY {
    return CGRectGetHeight(self.bounds)- 15 - 32;
}

#pragma mark - Public Method

- (void)updateDuration:(NSTimeInterval)duration {
    [self.playbackViewModel updateDuration:duration];
}

- (void)playbackTimeChanged {
    [self.playbackViewModel playbakTimeChanged];
}

- (void)playbackVideoInfoDidUpdated {
    // 清理上一场的数据
    [self.playbackViewModel clear];
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (self.videoType == PLVChannelVideoType_Playback && roomData.menuInfo.chatInputDisable && roomData.playbackSessionId) {
        self.playbackViewModel = [[PLVECChatroomPlaybackViewModel alloc] initWithChannelId:roomData.channelId sessionId:roomData.playbackSessionId videoId:roomData.playbackVideoInfo.fileId];
        self.playbackViewModel.delegate = self;
        [self.playbackViewModel addUIDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.messageView updatePlaybackViewModel:self.playbackViewModel];
    }
}

#pragma mark - Private Method

#pragma mark - PLVECChatroomViewModelProtocol
- (void)chatroomManager_didReceiveAnswerMessage {
    if (self.keyboardToolView.keyboardToolMode == PLVECKeyboardToolModeNormal) {
        BOOL hiddenMessageImgView = NO;
        NSArray *dataArray = [PLVECChatroomViewModel sharedViewModel].privateChatArray;
        // 私聊消息 如果第一条为自己创建的本地消息
        if ([PLVFdUtil checkArrayUseable:dataArray] && dataArray.count == 1) {
            PLVChatModel *firstChatModel = dataArray.firstObject;
            if (![PLVFdUtil checkStringUseable:firstChatModel.user.userId]) {
                hiddenMessageImgView = YES;
            }
        }

        self.receiveAQMessageImgView.hidden = hiddenMessageImgView;
    }
}

- (void)chatroomManager_rewardSuccess:(NSDictionary *)modelDict {
    NSInteger num = [modelDict[@"goodNum"] integerValue];
    NSString *unick = modelDict[@"unick"];
    PLVRewardGoodsModel *model = [PLVRewardGoodsModel modelWithSocketObject:modelDict];
    [self.rewardDisplayManager addGoodsShowWithModel:model goodsNum:num personName:unick];
}

- (void)chatroomManager_loadRewardEnable:(BOOL)rewardEnable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray *_Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomView_loadRewardEnable:payWay:rewardModelArray:pointUnit:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate chatroomView_loadRewardEnable:rewardEnable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
        });
    }
}

- (void)chatroomManager_showDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomView_showDelayRedpackWithType:delayTime:)]) {
        [self.delegate chatroomView_showDelayRedpackWithType:type delayTime:delayTime];
    }
}

- (void)chatroomManager_hideDelayRedpack {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomView_hideDelayRedpack)]) {
        [self.delegate chatroomView_hideDelayRedpack];
    }
}

- (void)chatroomManager_didLoginRestrict {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomView_didLoginRestrict)]) {
        [self.delegate chatroomView_didLoginRestrict];
    }
}

- (void)chatroomManager_closeRoom:(BOOL)closeRoom {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.keyboardToolView.enabledKeyboardTool = !closeRoom;
        [self.keyboardToolView changePlaceholderText:closeRoom ? PLVLocalizedString(@"聊天室已关闭") : PLVLocalizedString(@"聊点什么吧~")];
    });
}

- (void)chatroomManager_focusMode:(BOOL)focusMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.keyboardToolView.enabledKeyboardTool = !focusMode;
        [self.keyboardToolView changePlaceholderText:focusMode ? PLVLocalizedString(@"当前为专注模式") : PLVLocalizedString(@"聊点什么吧~")];
    });
}

- (void)chatroomManager_checkRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomView_checkRedpackStateResult:chatModel:)]) {
        [self.delegate chatroomView_checkRedpackStateResult:state chatModel:model];
    }
}

#pragma mark - PLVECChatroomPlaybackDelegate
- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomView_currentPlaybackTime)]) {
        return [self.delegate chatroomView_currentPlaybackTime];
    }
    
    return 0;
}

#pragma mark - PLVECChatroomPlaybackViewModelDelegate
- (void)loadMessageInfoSuccess:(BOOL)success playbackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    NSString *content = success ? PLVLocalizedString(@"聊天室重放功能已开启，将会显示历史消息") : PLVLocalizedString(@"回放消息正在准备中，可稍等刷新查看");
    [PLVLiveToast showToastWithMessage:content inView:self afterDelay:5.0];
}

#pragma mark 显示欢迎语
- (void)chatroomManager_loginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray {
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
                string = [NSString stringWithFormat:PLVLocalizedString(@"%@等%zd人"), string, [userArray count]];
            }
        } else {
            PLVChatUser *user = userArray[0];
            string = user.userName;
        }
    }
    
    if (string.length > 0) {
        NSString *welcomeMessage = [NSString stringWithFormat:PLVLocalizedString(@"欢迎 %@ 进入直播间"), string];
        [self showWelcomeWithMessage:welcomeMessage];
    }
}

- (void)showWelcomeWithMessage:(NSString *)welcomeMessage {
    if (!self.welcomView.hidden) {
        [self shutdownWelcomView];
    }
    
    self.welcomView.hidden = NO;
    
    CGFloat duration = 2.0;
    self.welcomView.messageLB.text = welcomeMessage;
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

#pragma mark - Private
#pragma mark - PLVECKeyboardToolViewDelegate
- (void)keyboardToolView:(PLVECKeyboardToolView *)toolView popBoard:(BOOL)show {
    CGRect messageViewFrame = self.messageView.frame;
    if (show) {
        messageViewFrame.origin.y = self.keyboardToolView.activatedKeyboardToolRectY - CGRectGetHeight(messageViewFrame) - [PLVECUtils sharedUtils].areaInsets.top - 10;
    } else {
        messageViewFrame.origin.y = self.textViewAreaRectY- CGRectGetHeight(messageViewFrame) - 15;
    }
    [UIView animateWithDuration:0.1 animations:^{
        self.messageView.frame = messageViewFrame;
    }];
}

- (void)keyboardToolView:(PLVECKeyboardToolView *)toolView sendText:(NSString *)text replyModel:(PLVChatModel *)replyModel {
    if (![PLVFdUtil checkStringUseable:text]) {
        return;
    }
    
    if (self.keyboardToolView.keyboardToolMode == PLVECKeyboardToolModeNormal) {
        BOOL success = [[PLVECChatroomViewModel sharedViewModel] sendSpeakMessage:text replyChatModel:replyModel];
        if (!success) {
            [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"消息发送失败") detail:@"" view:self];
        }
    } else if (self.keyboardToolView.keyboardToolMode == PLVECKeyboardToolModeAskQuestion) {
        BOOL success = [[PLVECChatroomViewModel sharedViewModel] sendQuesstionMessage:text];
        if (!success) {
            [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"消息发送失败") detail:@"" view:self];
        }
    }
}

- (void)keyboardToolView:(PLVECKeyboardToolView *)toolView keyboardToolModeChanged:(PLVECKeyboardToolMode)mode {
    if (mode == PLVECKeyboardToolModeNormal &&
        self.messageView.messageViewType != PLVECChatroomMessageViewTypeNormal) {
        [self.messageView switchMessageViewType:PLVECChatroomMessageViewTypeNormal];
    } else if (mode == PLVECKeyboardToolModeAskQuestion &&
               self.messageView.messageViewType != PLVECChatroomMessageViewTypeAskQuestion) {
        [self.messageView switchMessageViewType:PLVECChatroomMessageViewTypeAskQuestion];
    }
    self.receiveAQMessageImgView.hidden = YES;
}

#pragma mark - PLVECChatroomMessageViewDelegate
    
- (void)chatroomMessageView:(PLVECChatroomMessageView *)messageView replyChatModel:(PLVChatModel *)replyModel {
    [self.keyboardToolView replyChatModel:replyModel];
}

- (void)chatroomMessageView:(PLVECChatroomMessageView *)messageView messageViewTypeChanged:(PLVECChatroomMessageViewType)type {
    if (type == PLVECChatroomMessageViewTypeNormal && self.keyboardToolView.keyboardToolMode != PLVECKeyboardToolModeNormal) {
        [self.keyboardToolView switchKeyboardToolMode:PLVECKeyboardToolModeNormal];
    } else if (type == PLVECChatroomMessageViewTypeAskQuestion && self.keyboardToolView.keyboardToolMode != PLVECKeyboardToolModeAskQuestion) {
        [self.keyboardToolView switchKeyboardToolMode:PLVECKeyboardToolModeAskQuestion];
    }
    self.receiveAQMessageImgView.hidden = YES;
}

- (void)chatroomMessageView:(PLVECChatroomMessageView *)messageView alertLongContentMessage:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomView_alertLongContentMessage:)]) {
        [self.delegate chatroomView_alertLongContentMessage:model];
    }
}

@end
