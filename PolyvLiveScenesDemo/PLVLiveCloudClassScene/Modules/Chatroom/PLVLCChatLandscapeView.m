//
//  PLVLCChatLandscapeView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/31.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCChatLandscapeView.h"
#import "PLVRoomDataManager.h"
#import "PLVLCLandscapeNewMessageView.h"
#import "PLVLCUtils.h"
#import "PLVLCChatroomViewModel.h"
#import "PLVLCLandscapeRedpackMessageCell.h"
#import "PLVLCLandscapeLongContentCell.h"
#import "PLVLCLandscapeSpeakCell.h"
#import "PLVLCLandscapeImageCell.h"
#import "PLVLCLandscapeImageEmotionCell.h"
#import "PLVLCLandscapeQuoteCell.h"
#import "PLVLCLandscapeFileCell.h"
#import "PLVLCChatroomPlaybackViewModel.h"
#import "PLVLiveToast.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <MJRefresh/MJRefresh.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

#define KEYPATH_CONTENTSIZE @"contentSize"

@interface PLVLCChatLandscapeView ()<
PLVLCChatroomViewModelProtocol,
PLVLCChatroomPlaybackViewModelDelegate,
UITableViewDelegate,
UITableViewDataSource
>

/// 聊天列表
@property (nonatomic, strong) UITableView *tableView;
/// 聊天室列表上次滚动结束时的contentOffset
@property (nonatomic, assign) CGPoint lastContentOffset;
/// 聊天室列表顶部加载更多控件
@property (nonatomic, strong) MJRefreshNormalHeader *refresher;
/// 新消息提示视图
@property (nonatomic, strong) PLVLCLandscapeNewMessageView *receiveNewMessageView;
/// 未读消息条数
@property (nonatomic, assign) NSUInteger newMessageCount;

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, assign) BOOL observingTableView;
/// 聊天室是否处于聊天回放状态，默认为NO
@property (nonatomic, assign) BOOL playbackEnable;
/// 弱引用首页持有的聊天回放viewModel
@property (nonatomic, weak) PLVLCChatroomPlaybackViewModel *playbackViewModel;

@end

@implementation PLVLCChatLandscapeView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addOrientationObserver];
        
        [self addSubview:self.tableView];
        [self addSubview:self.receiveNewMessageView];
        
        [self.layer setMask:self.gradientLayer];
        
        self.observingTableView = NO;
        [self observeTableView];
        
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.playbackEnable = roomData.menuInfo.chatInputDisable && roomData.videoType == PLVChannelVideoType_Playback;
        if (!self.playbackEnable) {
            [[PLVLCChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        }
    }
    return self;
}

- (void)layoutSubviews {
    self.gradientLayer.frame = self.bounds;
    
    CGFloat contentHeight = self.tableView.contentSize.height;
    if (contentHeight < CGRectGetHeight(self.bounds)) {
        CGRect newFrame = CGRectMake(0, self.bounds.size.height - contentHeight, self.bounds.size.width, contentHeight);
        self.tableView.frame = newFrame;
        [self scrollsToBottom:NO];
        self.tableView.scrollEnabled = NO;
    } else if (CGRectGetHeight(self.bounds) > 0) {
        self.tableView.frame = self.bounds;
        self.tableView.scrollEnabled = YES;
    }
    
    [PLVLCChatroomViewModel sharedViewModel].tableViewWidthForH = self.tableView.frame.size.width;
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (!fullScreen) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    if (self.receiveNewMessageView.frame.origin.y == 0) {
        CGFloat originY = self.bounds.size.height - 25;
        self.receiveNewMessageView.frame = CGRectMake(0, originY, 86, 25);
    }
}

- (void)dealloc {
    [self removeOrientationObserver];
    [self removeObserveTableView];
}

#pragma mark - Getter & Setter

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0 alpha:0].CGColor, (__bridge id)[UIColor colorWithWhite:0 alpha:0.7].CGColor, (__bridge id)[UIColor colorWithWhite:0 alpha:1].CGColor];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(0, 1);
        _gradientLayer.locations = @[@(0), @(0.1f), @(0.15f)];
    }
    return _gradientLayer;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.scrollEnabled = NO;
        _tableView.allowsSelection = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.mj_header = self.refresher;
        // 系统自带的加载控件（横屏聊天室会因为位置不够无法触发）
//        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
//        [refreshControl addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventValueChanged];
//        [_tableView addSubview:refreshControl];
    }
    return _tableView;
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

- (PLVLCLandscapeNewMessageView *)receiveNewMessageView {
    if (!_receiveNewMessageView) {
        _receiveNewMessageView = [[PLVLCLandscapeNewMessageView alloc] init];
        _receiveNewMessageView.hidden = YES;
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(readNewMessageAction)];
        [_receiveNewMessageView addGestureRecognizer:gesture];
    }
    return _receiveNewMessageView;
}

#pragma mark - Action

- (void)readNewMessageAction { // 点击底部未读消息条幅时触发
    [self clearNewMessageCount];
    [self scrollsToBottom:YES];
}

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    if (self.playbackEnable) {
        [self.playbackViewModel loadMoreMessages];
    } else {
        [[PLVLCChatroomViewModel sharedViewModel] loadHistory];
    }
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
        if (CGRectEqualToRect(self.bounds, CGRectZero)) {
            return;
        }
        CGFloat contentHeight = self.tableView.contentSize.height;
        if (contentHeight < CGRectGetHeight(self.bounds)) {
            [UIView animateWithDuration:0.2 animations:^{
                CGRect newFrame = CGRectMake(0, self.bounds.size.height - contentHeight, self.bounds.size.width, contentHeight);
                self.tableView.frame = newFrame;
                [self scrollsToBottom:NO];
                self.tableView.scrollEnabled = NO;
                [self scrollViewDidScroll:self.tableView];
            }];
        } else if (CGRectGetHeight(self.bounds) > 0) {
            self.tableView.frame = self.bounds;
            self.tableView.scrollEnabled = YES;        }
    }
}

#pragma mark - NSNotification

- (void)addOrientationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)removeOrientationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        [self scrollsToBottom:NO];
    }
}

#pragma mark - Public Method

- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel {
    self.playbackViewModel = playbackViewModel;
    [self.playbackViewModel addUIDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)updateChatTableView {
    [self.tableView reloadData];
}

#pragma mark - Private Method

- (void)scrollsToBottom:(BOOL)animated {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    if (offsetY < 0.0) {
        offsetY = 0.0;
    }
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:animated];
}

- (void)addNewMessageCount {
    self.newMessageCount ++;
    [self.receiveNewMessageView updateMeesageCount:self.newMessageCount];
    [self.receiveNewMessageView show];
}

- (void)clearNewMessageCount {
    if (self.newMessageCount == 0) {
        return ;
    }
    self.newMessageCount = 0;
    [self.receiveNewMessageView hidden];
}

// 数据源数目
- (NSInteger)dataCount {
    NSInteger count = 0;
    if (self.playbackEnable) {
        count = [self.playbackViewModel.chatArray count];
    } else {
        count = [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count];
    }
    return count;
}

// 根据indexPath得到数据模型
- (PLVChatModel *)modelAtIndexPath:(NSIndexPath *)indexPath {
    PLVChatModel *model = nil;
    if (self.playbackEnable) {
        model = self.playbackViewModel.chatArray[indexPath.row];
    } else {
        if ([PLVLCChatroomViewModel sharedViewModel].chatArray.count > indexPath.row) {
            model = [[PLVLCChatroomViewModel sharedViewModel] chatArray][indexPath.row];
        }
    }
    return model;
}

// 点击超长文本消息(超过200字符）的【复制】按钮时调用
- (void)pasteFullContentWithModel:(PLVChatModel *)model {
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        if (!self.playbackEnable) { // 重放时接口返回的消息包含全部文本，不存在超长问题
            [[PLVLCChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
                if (content) {
                    model.overLenContent = content;
                    [UIPasteboard generalPasteboard].string = content;
                    [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.superview afterDelay:3.0];
                }
            }];
        }
    } else {
        NSString *pasteString = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (pasteString) {
            [UIPasteboard generalPasteboard].string = pasteString;
            [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.superview afterDelay:3.0];
        }
    }
}

// 点击超长文本消息(超过500字符）的【更多】按钮时调用
- (void)alertToShowFullContentWithModel:(PLVChatModel *)model {
    __weak typeof(self) weakSelf = self;
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        if (!self.playbackEnable) { // 重放时接口返回的消息包含全部文本，不存在超长问题
            [[PLVLCChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
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
        [self.delegate respondsToSelector:@selector(chatLandscapeView:alertLongContentMessage:)]) {
        [self.delegate chatLandscapeView:self alertLongContentMessage:model];
    }
}

- (void)notifyDelegateToReplyChatModel:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatLandscapeView:didTapReplyMessage:)]) {
        [self.delegate chatLandscapeView:self didTapReplyMessage:model];
    }
}

- (void)didTapRedpackModel:(PLVChatModel *)model {
    [[PLVLCChatroomViewModel sharedViewModel] checkRedpackStateWithChatModel:model];
}

- (void)trackLogAction {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (!fullScreen) {
        return;
    }
    
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.tableView.indexPathsForVisibleRows.count];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
        if (cellRect.origin.y + 28.0 >= self.tableView.contentOffset.y &&
            cellRect.origin.y + cellRect.size.height - 28.0 <= self.tableView.contentOffset.y + self.tableView.frame.size.height) {
            PLVChatModel *model = [self modelAtIndexPath:indexPath];
            if ([PLVLCLandscapeRedpackMessageCell isModelValid:model]) {
                id message = model.message;
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

#pragma mark - PLVLCChatroomViewModelProtocol

- (void)chatroomManager_didSendMessage:(PLVChatModel *)model {
    [self.tableView reloadData];
    [self scrollsToBottom:YES];
    [self clearNewMessageCount];
}

- (void)chatroomManager_didReceiveMessages:(NSArray <PLVChatModel *> *)modelArray {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
        [self scrollsToBottom:YES];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
}

- (void)chatroomManager_didMessageDeleted {
    [self.tableView reloadData];
}

- (void)chatroomManager_didMessageCountLimitedAutoDeleted {
    [self.tableView reloadData];
    if (!self.refresher.superview) {
        self.tableView.mj_header = self.refresher;
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
        [self scrollsToBottom:NO];
    } else {
        [self.tableView scrollsToTop];
    }
}

- (void)chatroomManager_loadHistoryFailure {
    [self.refresher endRefreshing];
}

- (void)chatroomManager_didRedpackStateChanged {
    [self.tableView reloadData];
}

#pragma mark - PLVLCChatroomPlaybackViewModelDelegate

- (void)clearMessageForPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.tableView reloadData];
}

- (void)didReceiveNewMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
        [self scrollsToBottom:YES];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
}

- (void)didMessagesRefreshedForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.tableView reloadData];
    [self clearNewMessageCount];
    [self scrollsToBottom:YES];
}

- (void)didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.refresher endRefreshing];
    [self.tableView reloadData];
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
    
    __weak typeof(self) weakSelf = self;
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    BOOL quoteReplyEnabled = [PLVRoomDataManager sharedManager].roomData.menuInfo.quoteReplyEnabled;
    PLVChatModel *model = [self modelAtIndexPath:indexPath];
    
    if ([PLVLCLandscapeSpeakCell isModelValid:model]) {
        static NSString *speakMessageCellIdentify = @"PLVLCLandscapeSpeakCell";
        PLVLCLandscapeSpeakCell *cell = (PLVLCLandscapeSpeakCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeSpeakCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf notifyDelegateToReplyChatModel:model];
        }];
        return cell;
    } else if ([PLVLCLandscapeLongContentCell isModelValid:model]) {
        static NSString *LongContentMessageCellIdentify = @"PLVLCLongContentMessageCell";
        PLVLCLandscapeLongContentCell *cell = (PLVLCLandscapeLongContentCell *)[tableView dequeueReusableCellWithIdentifier:LongContentMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeLongContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LongContentMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf notifyDelegateToReplyChatModel:model];
        }];
        [cell setCopButtonHandler:^{
            [weakSelf pasteFullContentWithModel:model];
        }];
        [cell setFoldButtonHandler:^{
            [weakSelf alertToShowFullContentWithModel:model];
        }];
        return cell;
    } else if ([PLVLCLandscapeImageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCLandscapeImageCell";
        PLVLCLandscapeImageCell *cell = (PLVLCLandscapeImageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf notifyDelegateToReplyChatModel:model];
        }];
        return cell;
    } else if ([PLVLCLandscapeImageEmotionCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCLandscapeImageEmotionCell";
        PLVLCLandscapeImageEmotionCell *cell = (PLVLCLandscapeImageEmotionCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeImageEmotionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf notifyDelegateToReplyChatModel:model];
        }];
        return cell;
    } else if ([PLVLCLandscapeQuoteCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVLCLandscapeQuoteCell";
        PLVLCLandscapeQuoteCell *cell = (PLVLCLandscapeQuoteCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeQuoteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf notifyDelegateToReplyChatModel:model];
        }];
        return cell;
    } if ([PLVLCLandscapeFileCell isModelValid:model]) {
        static NSString *filekMessageCellIdentify = @"PLVLCLandscapeFileCell";
        PLVLCLandscapeFileCell *cell = (PLVLCLandscapeFileCell *)[tableView dequeueReusableCellWithIdentifier:filekMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeFileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:filekMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } if ([PLVLCLandscapeRedpackMessageCell isModelValid:model]) {
        static NSString *redpackMessageCellIdentify = @"PLVLCLandscapeRedpackMessageCell";
        PLVLCLandscapeRedpackMessageCell *cell = (PLVLCLandscapeRedpackMessageCell *)[tableView dequeueReusableCellWithIdentifier:redpackMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeRedpackMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:redpackMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setRedpackTapHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapRedpackModel:model];
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
    
    CGFloat cellHeight = 0;
    
    PLVChatModel *model = [self modelAtIndexPath:indexPath];
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if ([PLVLCLandscapeSpeakCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLCLandscapeSpeakCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLCLandscapeLongContentCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLCLandscapeLongContentCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLCLandscapeImageCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLCLandscapeImageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLCLandscapeImageEmotionCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLCLandscapeImageEmotionCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLCLandscapeQuoteCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLCLandscapeQuoteCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLCLandscapeFileCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLCLandscapeFileCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight =  model.cellHeightForH;
    } else if ([PLVLCLandscapeRedpackMessageCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLCLandscapeRedpackMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    }
    
    return cellHeight;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL up = scrollView.contentOffset.y < self.lastContentOffset.y;
    if (self.lastContentOffset.y <= 0 && scrollView.contentOffset.y <= 0) {
        up = YES;
    }
    self.lastContentOffset = scrollView.contentOffset;
    if (!up) {
        [self clearNewMessageCount];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackLogAction) object:nil];
    [self performSelector:@selector(trackLogAction) withObject:nil afterDelay:1];
}

@end
