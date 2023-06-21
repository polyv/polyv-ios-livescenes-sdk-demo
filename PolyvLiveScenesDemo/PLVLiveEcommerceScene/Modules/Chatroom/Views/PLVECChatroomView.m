//
//  PLVChatroomView.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECChatroomView.h"
#import "PLVECRepliedMsgView.h"
#import "PLVECNewMessageView.h"
#import "PLVECWelcomView.h"
#import "PLVECChatCell.h"
#import "PLVECQuoteChatCell.h"
#import "PLVECLongContentChatCell.h"
#import "PLVECUtils.h"
#import "PLVECChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import "PLVToast.h"
#import <MJRefresh/MJRefresh.h>
#import "PLVRewardDisplayManager.h"
#import "PLVECChatroomPlaybackViewModel.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

#define TEXT_MAX_COUNT 200

#define KEYPATH_CONTENTSIZE @"contentSize"

@interface PLVECChatroomView () <
UITextViewDelegate,
UITableViewDelegate,
UITableViewDataSource,
PLVECChatroomViewModelProtocol,
PLVECChatroomPlaybackViewModelDelegate
>

/// 聊天列表
@property (nonatomic, strong) UITableView *tableView;
/// 聊天室列表顶部加载更多控件
@property (nonatomic, strong) MJRefreshNormalHeader *refresher;
/// 新消息提示条幅
@property (nonatomic, strong) PLVECNewMessageView *receiveNewMessageView;
/// 打赏成功提示条幅
@property (nonatomic, strong) PLVRewardDisplayManager *rewardDisplayManager;
/// 条幅视图
@property (nonatomic, strong) UIView *rewardDisplayView;

@property (nonatomic, strong) PLVECWelcomView *welcomView;
@property (nonatomic, assign) CGRect originWelcomViewFrame;

@property (nonatomic, strong) UIView *tableViewBackgroundView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL observingTableView;

@property (nonatomic, strong) UIView *textAreaView;
@property (nonatomic, strong) UILabel *placeholderLB;

@property (nonatomic, strong) UIView *tapView;
@property (nonatomic, strong) UITextView *textView;
/// 聊天室是否处于聊天回放状态，默认为NO
@property (nonatomic, assign) BOOL playbackEnable;
/// 聊天重放viewModel
@property (nonatomic, strong) PLVECChatroomPlaybackViewModel *playbackViewModel;
/// 当前视频类型
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType;
/// 显示被引用回复消息UI
@property (nonatomic, strong) PLVECRepliedMsgView * _Nullable replyModelView;

@end

@implementation PLVECChatroomView

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserveTableView];
}

- (instancetype)init {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.playbackEnable = roomData.menuInfo.chatInputDisable && roomData.videoType == PLVChannelVideoType_Playback;
        
        if (self.videoType == PLVChannelVideoType_Live) { // 直播一定会显示聊天室
            [[PLVECChatroomViewModel sharedViewModel] setup];
            [PLVECChatroomViewModel sharedViewModel].delegate = self;
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        } else { // 回放时只有chatInputDisable为YES时会显示聊天室
            [[PLVECChatroomViewModel sharedViewModel] setup];
        }
        
        self.observingTableView = NO;
        [self observeTableView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        
        self.welcomView = [[PLVECWelcomView alloc] init];
        self.welcomView.hidden = YES;
        [self addSubview:self.welcomView];
        [self addSubview:self.rewardDisplayView];
        
        // 渐变蒙层
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.startPoint = CGPointMake(0, 0);
        self.gradientLayer.endPoint = CGPointMake(0, 0.1);
        self.gradientLayer.colors = @[(__bridge id)[UIColor.clearColor colorWithAlphaComponent:0].CGColor, (__bridge id)[UIColor.clearColor colorWithAlphaComponent:1.0].CGColor];
        self.gradientLayer.locations = @[@(0), @(1.0)];
        self.gradientLayer.rasterizationScale = UIScreen.mainScreen.scale;
        
        self.tableViewBackgroundView = [[UIView alloc] init];
        [self addSubview:self.tableViewBackgroundView];
        self.tableViewBackgroundView.layer.mask = self.gradientLayer;
        
        self.tableView = [[UITableView alloc] init];
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.scrollEnabled = NO;
        self.tableView.allowsSelection =  NO;
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.showsHorizontalScrollIndicator = NO;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.estimatedRowHeight = 0;
        self.tableView.estimatedSectionFooterHeight = 0;
        self.tableView.estimatedSectionHeaderHeight = 0;
        self.tableView.mj_header = self.refresher;
        [self.tableViewBackgroundView addSubview:self.tableView];
        
        self.receiveNewMessageView = [[PLVECNewMessageView alloc] init];
        self.receiveNewMessageView.hidden = YES;
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(readNewMessageAction)];
        [self.receiveNewMessageView addGestureRecognizer:gesture];
        [self addSubview:self.receiveNewMessageView];
        
        if (self.videoType == PLVChannelVideoType_Live) { // 聊天重放时聊天室不允许发消息
            self.textAreaView = [[UIView alloc] init];
            self.textAreaView.layer.cornerRadius = 20.0;
            self.textAreaView.layer.masksToBounds = YES;
            self.textAreaView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
            [self addSubview:self.textAreaView];
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textAreaViewTapAction)];
            [self.textAreaView addGestureRecognizer:tapGesture];
            
            UIImageView *leftImgView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 16, 16)];
            leftImgView.image = [PLVECUtils imageForWatchResource:@"plv_chat_img"];
            [self.textAreaView addSubview:leftImgView];
            
            self.placeholderLB= [[UILabel alloc] initWithFrame:CGRectMake(30, 9, 130, 14)];
            self.placeholderLB.text = @"跟大家聊点什么吧～";
            self.placeholderLB.font = [UIFont systemFontOfSize:14];
            self.placeholderLB.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
            [self.textAreaView addSubview:self.placeholderLB];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat tableViewHeight = [PLVECUtils sharedUtils].isLandscape ? self.bounds.size.height * 0.4 :156;
    CGRect textAreaViewRect= CGRectMake(15, CGRectGetHeight(self.bounds)-15-32, 165, 32);
    self.textAreaView.frame = textAreaViewRect;
    self.tableViewBackgroundView.frame = CGRectMake(15, CGRectGetMinY(textAreaViewRect)-tableViewHeight-15, 234, tableViewHeight);
    self.tableView.frame = self.tableViewBackgroundView.bounds;
    self.gradientLayer.frame = self.tableViewBackgroundView.bounds;
    self.welcomView.frame = CGRectMake(-258, CGRectGetMinY(self.tableViewBackgroundView.frame)-22-15, 258, 22);
    self.originWelcomViewFrame = self.welcomView.frame;
    self.rewardDisplayView.frame = CGRectMake(0, CGRectGetMidY(self.bounds) - 150/2, MIN(PLVScreenWidth, PLVScreenHeight), CGRectGetHeight(self.bounds) - CGRectGetMidY(self.bounds) + 150/2);
    CGFloat tvbBottom = self.tableViewBackgroundView.frame.origin.y + tableViewHeight;
    self.receiveNewMessageView.frame = CGRectMake(15, tvbBottom - 24, 86, 24);
}

#pragma mark - Getter

- (UIView *)tapView {
    if (!_tapView) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        
        _tapView = [[UIView alloc] initWithFrame:window.bounds];
        _tapView.backgroundColor = [UIColor clearColor];
        [window addSubview:_tapView];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewAction)];
        [_tapView addGestureRecognizer:tapGesture];
    }
    return _tapView;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.frame = CGRectMake(0, CGRectGetHeight(self.tapView.bounds)-46, CGRectGetWidth(self.tapView.bounds), 46);
        _textView.delegate = self;
        _textView.textColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        _textView.textContainerInset = UIEdgeInsetsMake(10, 8, 10, 8);
        _textView.font = [UIFont systemFontOfSize:14.0];
        _textView.backgroundColor = UIColor.whiteColor;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.returnKeyType = UIReturnKeySend;
        [self.tapView addSubview:_textView];
    }
    return _textView;
}

- (MJRefreshNormalHeader *)refresher {
    if (!_refresher) {
        _refresher = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshAction:)];
        _refresher.lastUpdatedTimeLabel.hidden = YES;
        _refresher.stateLabel.hidden = YES;
        [_refresher.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    }
    return _refresher;
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

- (PLVChannelVideoType)videoType {
    return [PLVRoomDataManager sharedManager].roomData.videoType;
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
    }
}

#pragma mark - Private Method

// 数据源数目
- (NSInteger)dataCount {
    NSInteger count = 0;
    if (self.playbackEnable) {
        count = [self.playbackViewModel.chatArray count];
    } else {
        count = [[[PLVECChatroomViewModel sharedViewModel] chatArray] count];
    }
    return count;
}

// 根据indexPath得到数据模型
- (PLVChatModel *)modelAtIndexPath:(NSIndexPath *)indexPath {
    PLVChatModel *model = nil;
    if (self.playbackEnable && [PLVFdUtil checkArrayUseable:self.playbackViewModel.chatArray]) {
        model = self.playbackViewModel.chatArray[indexPath.row];
    } else if ([PLVFdUtil checkArrayUseable:[[PLVECChatroomViewModel sharedViewModel] chatArray]]) {
        model = [[PLVECChatroomViewModel sharedViewModel] chatArray][indexPath.row];
    }
    return model;
}

// 点击超长文本消息(超过200字符）的【复制】按钮时调用
- (void)pasteFullContentWithModel:(PLVChatModel *)model {
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        if (!self.playbackEnable) { // 重放时接口返回的消息包含全部文本，不存在超长问题
            [[PLVECChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
                if (content) {
                    model.overLenContent = content;
                    [UIPasteboard generalPasteboard].string = content;
                    [PLVToast showToastWithMessage:@"复制成功" inView:self.superview afterDelay:3.0];
                }
            }];
        }
    } else {
        NSString *pasteString = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (pasteString) {
            [UIPasteboard generalPasteboard].string = pasteString;
            [PLVToast showToastWithMessage:@"复制成功" inView:self.superview afterDelay:3.0];
        }
    }
}

// 点击超长文本消息(超过500字符）的【更多】按钮时调用
- (void)alertToShowFullContentWithModel:(PLVChatModel *)model {
    __weak typeof(self) weakSelf = self;
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        if (!self.playbackEnable) { // 重放时接口返回的消息包含全部文本，不存在超长问题
            [[PLVECChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
                if (content) {
                    model.overLenContent = content;
                    [weakSelf notifyDelegateToAlertChatModel:model];
                }
            }];
        }
    } else {
        NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (content) {
            [self notifyDelegateToAlertChatModel:model];
        }
    }
}

- (void)notifyDelegateToAlertChatModel:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomView_alertLongContentMessage:)]) {
        [self.delegate chatroomView_alertLongContentMessage:model];
    }
}

- (void)trackLogAction {
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.tableView.indexPathsForVisibleRows.count];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
        if (cellRect.origin.y + 28.0 >= self.tableView.contentOffset.y &&
            cellRect.origin.y + cellRect.size.height - 28.0 <= self.tableView.contentOffset.y + self.tableView.frame.size.height) {
            PLVChatModel *model = [self modelAtIndexPath:indexPath];
            id message = model.message;
            if (message &&
                [message isKindOfClass:[PLVRedpackMessage class]]) {
                PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)message;
                [muArray addObject:redpackMessage];
            }
        }
    }
    
    NSArray *currentVisibleRedpackMessages = [muArray copy];
    if ([currentVisibleRedpackMessages count] > 0) {
        [self trackLog:currentVisibleRedpackMessages];
    }
}

- (void)trackLog:(NSArray <PLVRedpackMessage *> *)redpackMessages {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:redpackMessages.count];
    for (PLVRedpackMessage *redpackMessage in redpackMessages) {
        NSString *repackTypeString = (redpackMessage.type == PLVRedpackMessageTypeAliPassword) ? @"alipay_password_official_normal" : @"";
        NSDictionary *eventInfo = @{
            @"repackType": repackTypeString,
            @"redpackId" : redpackMessage.redpackId,
            @"exposureTime" : @(lround(interval))
        };
        [muArray addObject:eventInfo];
    }
    
    [[PLVWLogReporterManager sharedManager] reportTrackWithEventId:@"user_read_redpack" eventType:@"show" specInformationArray:[muArray copy]];
}

#pragma mark - Action

- (void)textAreaViewTapAction {
    if (!self.textView.isFirstResponder) {
        self.textView.hidden = NO;
        [self.textView becomeFirstResponder];
    }
}

- (void)tapViewAction {
    [self.tapView setHidden:YES];
    [self.textView setHidden:YES];
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
    }
}

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    if (self.playbackEnable) {
        [self.playbackViewModel loadMoreMessages];
    } else {
        [[PLVECChatroomViewModel sharedViewModel] loadHistory];
    }
}

- (void)readNewMessageAction { // 点击底部未读消息条幅时触发
    [self.receiveNewMessageView hidden];
    [self scrollsToBottom];
}

#pragma mark - KVO

- (void)observeTableView {
    if (!self.observingTableView) {
        self.observingTableView = YES;
        [self.tableView addObserver:self forKeyPath:KEYPATH_CONTENTSIZE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveTableView {
    if (self.observingTableView) {
        self.observingTableView = NO;
        [self.tableView removeObserver:self forKeyPath:KEYPATH_CONTENTSIZE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:UITableView.class] && [keyPath isEqualToString:KEYPATH_CONTENTSIZE]) {
        CGFloat contentHeight = self.tableView.contentSize.height;
        if (contentHeight < CGRectGetHeight(self.tableViewBackgroundView.bounds)) {
            [UIView animateWithDuration:0.2 animations:^{
                CGRect newFrame = CGRectMake(0, CGRectGetHeight (self.tableViewBackgroundView.bounds)-contentHeight, CGRectGetWidth(self.tableViewBackgroundView.bounds), contentHeight);
                self.tableView.frame = newFrame;
                [self scrollViewDidScroll:self.tableView];
            }];
        } else if (CGRectGetHeight(self.tableViewBackgroundView.bounds) > 0) {
            self.tableView.scrollEnabled = YES;
            self.tableView.frame = self.tableViewBackgroundView.bounds;
            [self removeObserveTableView];
        }
    }
}

#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    if (!self.textView.isFirstResponder) {
        return;
    }
    
    [self followKeyboardAnimated:notification.userInfo show:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (!self.textView.isFirstResponder) {
        return;
    }
    
    [self followKeyboardAnimated:notification.userInfo show:NO];
}

#pragma mark - PLVECChatroomViewModelProtocol

- (void)chatroomManager_didSendMessage {
    [self.tableView reloadData];
    [self scrollsToBottom];
}

- (void)chatroomManager_didReceiveMessages {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    if (@available(iOS 13.0, *)) {
        [[UIMenuController sharedMenuController] hideMenu];
    } else {
        [[UIMenuController sharedMenuController]  setMenuVisible:NO];
    }
    
    if (isBottom) { // tableview显示在最底部
        [self.receiveNewMessageView hidden];
        [self scrollsToBottom];
    } else {
        // 显示未读消息提示
        [self.receiveNewMessageView show];
    }
}

- (void)chatroomManager_didMessageDeleted {
    [self.tableView reloadData];
    if (@available(iOS 13.0, *)) {
        [[UIMenuController sharedMenuController] hideMenu];
    } else {
        [[UIMenuController sharedMenuController]  setMenuVisible:NO];
    }
}

- (void)chatroomManager_didSendProhibitMessage {
    [self.tableView reloadData];
}

- (void)chatroomManager_loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    [self.refresher endRefreshing];
    [self.tableView reloadData];
    
    if (noMore) {
        [self.refresher removeFromSuperview];
    }
    if (first) {
        [self scrollsToBottom];
    } else {
        [self.tableView scrollsToTop];
    }
}

- (void)chatroomManager_loadHistoryFailure {
    [self.refresher endRefreshing];
    [PLVECUtils showHUDWithTitle:@"聊天记录获取失败" detail:@"" view:self];
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
        self.placeholderLB.text = closeRoom ? @"聊天室已关闭" : @"跟大家聊点什么吧～";
        for (UIGestureRecognizer *gestureRecognizer in self.textAreaView.gestureRecognizers) {
            gestureRecognizer.enabled = !closeRoom;
            [self tapViewAction];
        }
    });
}

- (void)chatroomManager_focusMode:(BOOL)focusMode {
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.placeholderLB.text = focusMode ? @"聊天室专注模式已开启" : @"跟大家聊点什么吧～";
        for (UIGestureRecognizer *gestureRecognizer in self.textAreaView.gestureRecognizers) {
            gestureRecognizer.enabled = !focusMode;
            [self tapViewAction];
        }
    });
}

- (void)chatroomManager_checkRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomView_checkRedpackStateResult:chatModel:)]) {
        [self.delegate chatroomView_checkRedpackStateResult:state chatModel:model];
    }
}

#pragma mark - PLVECChatroomPlaybackViewModelDelegate

- (void)clearMessageForPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    [self.tableView reloadData];
}

- (void)loadMessageInfoSuccess:(BOOL)success playbackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    NSString *content = success ? @"聊天室重放功能已开启，将会显示历史消息" : @"回放消息正在准备中，可稍等刷新查看";
    [PLVToast showToastWithMessage:content inView:self afterDelay:5.0];
}

- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomView_currentPlaybackTime)]) {
        return [self.delegate chatroomView_currentPlaybackTime];
    }
    
    return 0;
}

- (void)didReceiveNewMessagesForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    
    if (isBottom) { // tableview显示在最底部
        [self.receiveNewMessageView hidden];
        [self scrollsToBottom];
    } else {
        // 显示未读消息提示
        [self.receiveNewMessageView show];
    }
}

- (void)didMessagesRefreshedForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    [self.tableView reloadData];
    [self.receiveNewMessageView hidden];
    [self scrollsToBottom];
}

- (void)didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    [self.refresher endRefreshing];
    [self.tableView reloadData];
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

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self dataCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self dataCount]) {
        return [UITableViewCell new];
    }
    
    PLVChatModel *model = [self modelAtIndexPath:indexPath];
    BOOL quoteReplyEnabled = [PLVRoomDataManager sharedManager].roomData.menuInfo.quoteReplyEnabled && !self.playbackEnable;
    
    __weak typeof(self) weakSelf = self;
    if ([PLVECChatCell isModelValid:model]) {
        static NSString *normalCellIdentify = @"normalCellIdentify";
        PLVECChatCell *cell = (PLVECChatCell *)[tableView dequeueReusableCellWithIdentifier:normalCellIdentify];
        if (!cell) {
            cell = [[PLVECChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:normalCellIdentify];
            cell.quoteReplyEnabled = quoteReplyEnabled;
        }
        [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItemWithModel:model];
        }];
        [cell setRedpackTapHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapRedpackWithModel:model];
        }];
        return cell;
    } else if ([PLVECQuoteChatCell isModelValid:model]) {
        static NSString *quoteCellIdentify = @"quoteCellIdentify";
        PLVECQuoteChatCell *cell = (PLVECQuoteChatCell *)[tableView dequeueReusableCellWithIdentifier:quoteCellIdentify];
        if (!cell) {
            cell = [[PLVECQuoteChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteCellIdentify];
            cell.quoteReplyEnabled = quoteReplyEnabled;
        }
        [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItemWithModel:model];
        }];
        return cell;
    } else if ([PLVECLongContentChatCell isModelValid:model]) {
        static NSString *LongContentMessageCellIdentify = @"PLVLCLongContentMessageCell";
        PLVECLongContentChatCell *cell = (PLVECLongContentChatCell *)[tableView dequeueReusableCellWithIdentifier:LongContentMessageCellIdentify];
        if (!cell) {
            cell = [[PLVECLongContentChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LongContentMessageCellIdentify];
            cell.quoteReplyEnabled = quoteReplyEnabled;
        }
        [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItemWithModel:model];
        }];
        [cell setCopButtonHandler:^{
            [weakSelf pasteFullContentWithModel:model];
        }];
        [cell setFoldButtonHandler:^{
            [weakSelf alertToShowFullContentWithModel:model];
        }];
        return cell;
    } else {
        static NSString *cellIdentify = @"cellIdentify";
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
        }
        return cell;
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self dataCount]) {
        return 0;
    }
    
    PLVChatModel *model = [self modelAtIndexPath:indexPath];
    CGFloat cellHeight = 0;
    if ([PLVECChatCell isModelValid:model]) {
        cellHeight = [PLVECChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVECQuoteChatCell isModelValid:model]) {
        cellHeight = [PLVECQuoteChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVECLongContentChatCell isModelValid:model]) {
        cellHeight = [PLVECLongContentChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    }
    return cellHeight;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackLogAction) object:nil];
    [self performSelector:@selector(trackLogAction) withObject:nil afterDelay:1];
}

#pragma mark - Private

- (void)sendMessage {
    if (self.textView.text.length > 0) {
        PLVChatModel *replyModel = self.replyModelView.chatModel;
        BOOL success = [[PLVECChatroomViewModel sharedViewModel] sendSpeakMessage:self.textView.text replyChatModel:replyModel];
        if (!success) {
            [PLVECUtils showHUDWithTitle:@"消息发送失败" detail:@"" view:self];
        }
        self.textView.text = @"";
        
        [self tapViewAction];
    }
}

- (void)followKeyboardAnimated:(NSDictionary *)userInfo show:(BOOL)show {
    [self.tapView setHidden:!show];

    if (!show) {
        [self.replyModelView removeFromSuperview];
        self.replyModelView = nil;
    }
    
    CGRect keyBoardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    duration = MAX(0.3, duration);
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect newFrame = self.textView.frame;
        newFrame.origin.y = CGRectGetMinY(keyBoardFrame) - CGRectGetHeight(newFrame);
        self.textView.frame = newFrame;
        if (show) {
            CGRect replyViewRect = newFrame;
            replyViewRect.origin.y -= self.replyModelView.viewHeight;
            replyViewRect.size.height = self.replyModelView.viewHeight;
            self.replyModelView.frame = replyViewRect;
        }
    } completion:^(BOOL finished) {
        if (!show) {
            self.textView.hidden = YES;
        }
    }];
}

- (void)scrollsToBottom {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    offsetY = MAX(0, offsetY);
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:YES];
}

- (void)didTapReplyMenuItemWithModel:(PLVChatModel *)model {
    self.replyModelView = [[PLVECRepliedMsgView alloc] initWithChatModel:model];
    [self.tapView addSubview:self.replyModelView];
    
    CGRect rect = self.tapView.bounds;
    rect.origin.y = rect.size.height;
    rect.size.height = self.replyModelView.viewHeight;
    self.replyModelView.frame = rect;
    
    __weak typeof(self) weakSelf = self;
    [self.replyModelView setCloseButtonHandler:^{
        [weakSelf.replyModelView removeFromSuperview];
        weakSelf.replyModelView = nil;
    }];
    
    [self textAreaViewTapAction];
}

- (void)didTapRedpackWithModel:(PLVChatModel *)model {
    if (![model.message isKindOfClass:[PLVRedpackMessage class]]) {
        return;
    }
    [[PLVECChatroomViewModel sharedViewModel] checkRedpackStateWithChatModel:model];
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Prevent crashing undo bug
    if(range.location + range.length > textView.text.length) {
        return NO;
    }
    
    if ([text isEqualToString:@"\n"]) {
        [self sendMessage];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    NSString *toBeString = textView.text;
    UITextRange *selectedRange = [textView markedTextRange];
    UITextPosition *position = [textView positionFromPosition:selectedRange.start offset:0];
    
    if (!position){
        if (toBeString.length > 0) {
            if (toBeString.length > TEXT_MAX_COUNT) {
                textView.text = [toBeString substringToIndex:TEXT_MAX_COUNT];
            }
        }
    }
}

@end
