//
//  PLVECChatroomMessageView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/3.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECChatroomMessageView.h"
#import "PLVECChatroomViewModel.h"
#import "PLVECChatroomPlaybackViewModel.h"
#import "PLVECChatroomAQMessageView.h"
#import "PLVECChatCell.h"
#import "PLVECQuoteChatCell.h"
#import "PLVECLongContentChatCell.h"
#import "PLVECNewMessageView.h"
#import "PLVECUtils.h"
#import "PLVLiveToast.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <MJRefresh/MJRefresh.h>

static NSString *const PLVECKEYPATH_CONTENTSIZE = @"contentSize";
static CGFloat KPLVECPageControlWidth = 38.0;

@interface PLVECChatroomMessageView ()<
UITableViewDelegate,
UITableViewDataSource,
UIScrollViewDelegate,
PLVECChatroomViewModelProtocol,
PLVECChatroomPlaybackViewModelDelegate
>

#pragma mark 数据
/// 数据源数目
@property (nonatomic, assign, readonly) NSInteger dataCount;
/// 聊天室是否处于聊天回放状态，默认为NO
@property (nonatomic, assign) BOOL playbackEnable;
/// 聊天重放viewModel
@property (nonatomic, strong) PLVECChatroomPlaybackViewModel *playbackViewModel;
@property (nonatomic, assign) BOOL observingTableView;
@property (nonatomic, assign) PLVECChatroomMessageViewType messageViewType;
/// 是否启用提问功能
@property (nonatomic, assign) BOOL enableQuiz;

#pragma mark UI
@property (nonatomic, strong) UIView *tableViewBackgroundView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PLVECChatroomAQMessageView *privateChatMessageView;
@property (nonatomic, strong) PLVECNewMessageView *receiveNewMessageView;
@property (nonatomic, strong) UIView *pageControlView;
@property (nonatomic, strong) CALayer *leftBackgroundLayer;
@property (nonatomic, strong) CALayer *rightBackgroundLayer;
@property (nonatomic, strong) CALayer *leftFillLayer;
@property (nonatomic, strong) CALayer *rightFillLayer;

@end

@implementation PLVECChatroomMessageView

#pragma mark - [ Life Cycle ]
- (void)dealloc {
    [self removeObserveTableView];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.playbackEnable = roomData.menuInfo.chatInputDisable && roomData.videoType == PLVChannelVideoType_Playback;
        self.enableQuiz = NO;
        if (roomData.videoType == PLVChannelVideoType_Live) { // 直播一定会显示聊天室
            for (PLVLiveVideoChannelMenu *menu in roomData.menuInfo.channelMenus) {
                if ([menu.menuType isEqualToString:@"quiz"]) {
                    self.enableQuiz = YES;
                    break;
                }
            }
            [[PLVECChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        }
        
        [self addSubview:self.scrollView];
        [self.scrollView addSubview:self.tableViewBackgroundView];
        if (self.enableQuiz) {
            [self addSubview:self.pageControlView];
            [self.scrollView addSubview:self.privateChatMessageView];
            [self createPageControlView];
        }
        [self.tableViewBackgroundView addSubview:self.tableView];
        [self.tableViewBackgroundView addSubview:self.receiveNewMessageView];
        self.tableViewBackgroundView.layer.mask = self.gradientLayer;
        [self observeTableView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize scrollViewContentSize = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.scrollView.bounds));
    CGFloat scrollViewHeight = self.bounds.size.height;
    CGFloat scrollViewWidth = self.bounds.size.width;
    if (self.enableQuiz) {
        self.pageControlView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - 4, KPLVECPageControlWidth * 2 + 4, 4);
        scrollViewHeight -= (self.pageControlView.frame.size.height + 8);
        self.leftBackgroundLayer.frame = CGRectMake(0, 0, KPLVECPageControlWidth, CGRectGetHeight(self.pageControlView.bounds));
        self.rightBackgroundLayer.frame = CGRectMake(CGRectGetMaxX(self.leftBackgroundLayer.frame) + 4, 0, KPLVECPageControlWidth, CGRectGetHeight(self.pageControlView.bounds));
        [self updatePageControlFrame];
        self.privateChatMessageView.frame = CGRectMake(scrollViewWidth, 0, scrollViewWidth, scrollViewHeight);
        scrollViewContentSize = CGSizeMake(scrollViewWidth * 2, scrollViewHeight);
    }
    self.scrollView.frame = CGRectMake(0, 0, self.bounds.size.width, scrollViewHeight);
    self.tableViewBackgroundView.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    self.tableView.frame = self.tableViewBackgroundView.bounds;
    self.gradientLayer.frame = self.tableViewBackgroundView.bounds;
    self.scrollView.contentSize = scrollViewContentSize;
    self.receiveNewMessageView.frame = CGRectMake(0, CGRectGetHeight(self.tableViewBackgroundView.frame) - 25, 86, 25);
    [PLVECChatroomViewModel sharedViewModel].tableViewWidth = self.tableView.frame.size.width;
}

#pragma mark - [ Public Method ]

- (void)switchMessageViewType:(PLVECChatroomMessageViewType)type {
    _messageViewType = type;
    CGFloat contentOffsetX = (type == PLVECChatroomMessageViewTypeAskQuestion ? CGRectGetWidth(self.scrollView.bounds) : 0);
    [self.scrollView setContentOffset:CGPointMake(contentOffsetX, 0) animated:YES];
}

- (void)updatePlaybackViewModel:(PLVECChatroomPlaybackViewModel *)playbackViewModel {
    self.playbackViewModel = playbackViewModel;
    [self.playbackViewModel addUIDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark - [ Private Methods ]
- (void)createPageControlView {
    self.leftBackgroundLayer = [CALayer layer];
    self.leftBackgroundLayer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    self.leftBackgroundLayer.cornerRadius = 2.0;
    self.leftBackgroundLayer.masksToBounds = YES;

    self.rightBackgroundLayer = [CALayer layer];
    self.rightBackgroundLayer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    self.rightBackgroundLayer.cornerRadius = 2.0;
    self.rightBackgroundLayer.masksToBounds = YES;

    self.leftFillLayer = [CALayer layer];
    self.leftFillLayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.leftFillLayer.cornerRadius = 2.0;
    
    self.rightFillLayer = [CALayer layer];
    self.rightFillLayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.rightFillLayer.cornerRadius = 2.0;

    [self.pageControlView.layer addSublayer:self.leftBackgroundLayer];
    [self.pageControlView.layer addSublayer:self.rightBackgroundLayer];
    [self.leftBackgroundLayer addSublayer:self.leftFillLayer];
    [self.rightBackgroundLayer addSublayer:self.rightFillLayer];
}

// 点击超长文本消息(超过200字符）的【复制】按钮时调用
- (void)pasteFullContentWithModel:(PLVChatModel *)model {
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        if (!self.playbackEnable) { // 重放时接口返回的消息包含全部文本，不存在超长问题
            [[PLVECChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
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

- (void)didTapRedpackWithModel:(PLVChatModel *)model {
    if (![model.message isKindOfClass:[PLVRedpackMessage class]]) {
        return;
    }
    [[PLVECChatroomViewModel sharedViewModel] checkRedpackStateWithChatModel:model];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomMessageView:alertLongContentMessage:)]) {
        [self.delegate chatroomMessageView:self alertLongContentMessage:model];
    }
}

- (void)scrollsToBottom {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    offsetY = MAX(0, offsetY);
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:YES];
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

- (void)updatePageControlFrame {
    CGFloat contentOffsetX = self.scrollView.contentOffset.x;
    CGFloat scrollViewWidth = self.scrollView.bounds.size.width;
    if (contentOffsetX < 0 || contentOffsetX > scrollViewWidth || scrollViewWidth == 0) {
        return;
    }
    
    CGFloat scrollScale = contentOffsetX/scrollViewWidth;
    self.leftFillLayer.frame = CGRectMake(KPLVECPageControlWidth * scrollScale, 0, KPLVECPageControlWidth, CGRectGetHeight(self.pageControlView.bounds));
    self.rightFillLayer.frame = CGRectMake(KPLVECPageControlWidth * (scrollScale - 1), 0, KPLVECPageControlWidth, CGRectGetHeight(self.pageControlView.bounds));
}

#pragma mark Getter
- (UIView *)tableViewBackgroundView {
    if (!_tableViewBackgroundView) {
        _tableViewBackgroundView = [[UIView alloc] init];
    }
    return _tableViewBackgroundView;
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

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(0, 0.1);
        _gradientLayer.colors = @[(__bridge id)[UIColor.clearColor colorWithAlphaComponent:0].CGColor, (__bridge id)[UIColor.clearColor colorWithAlphaComponent:1.0].CGColor];
        _gradientLayer.locations = @[@(0), @(1.0)];
        _gradientLayer.rasterizationScale = UIScreen.mainScreen.scale;
    }
    return _gradientLayer;
}

- (PLVECNewMessageView *)receiveNewMessageView {
    if (!_receiveNewMessageView) {
        _receiveNewMessageView = [[PLVECNewMessageView alloc] init];
        _receiveNewMessageView.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _receiveNewMessageView.tapActionHandler = ^{
            [weakSelf scrollsToBottom];
        };
    }
    return _receiveNewMessageView;
}

- (UIView *)pageControlView {
    if (!_pageControlView) {
        _pageControlView = [[UIView alloc] init];
    }
    return _pageControlView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [self createTableView];
        MJRefreshNormalHeader *refreshHeader = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshAction:)];
        refreshHeader.lastUpdatedTimeLabel.hidden = YES;
        refreshHeader.stateLabel.hidden = YES;
        [refreshHeader.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        _tableView.mj_header = refreshHeader;
    }
    return _tableView;
}

- (PLVECChatroomAQMessageView *)privateChatMessageView {
    if (!_privateChatMessageView) {
        _privateChatMessageView = [[PLVECChatroomAQMessageView alloc] init];
    }
    return _privateChatMessageView;
}

- (UITableView *)createTableView {
    UITableView *tableView = [[UITableView alloc] init];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.allowsSelection =  NO;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.showsHorizontalScrollIndicator = NO;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.estimatedRowHeight = 0;
    tableView.estimatedSectionFooterHeight = 0;
    tableView.estimatedSectionHeaderHeight = 0;
    return tableView;
}

- (NSInteger)dataCount {
    NSInteger count = 0;
    if (self.playbackEnable) {
        count = [self.playbackViewModel.chatArray count];
    } else {
        count = [[[PLVECChatroomViewModel sharedViewModel] chatArray] count];
    }
    return count;
}


#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.dataCount) {
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
    if (indexPath.row >= self.dataCount) {
        return 0;
    }
    
    PLVChatModel *model = [self modelAtIndexPath:indexPath];
    CGFloat cellHeight = 0;
    if ([PLVECChatCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVECChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVECQuoteChatCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVECQuoteChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVECLongContentChatCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVECLongContentChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    }
    return cellHeight;
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

- (void)didTapReplyMenuItemWithModel:(PLVChatModel *)model {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomMessageView:replyChatModel:)]) {
        [self.delegate chatroomMessageView:self replyChatModel:model];
    }
}

#pragma mark - KVO
- (void)observeTableView {
    if (!self.observingTableView) {
        self.observingTableView = YES;
        [self.tableView addObserver:self forKeyPath:PLVECKEYPATH_CONTENTSIZE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveTableView {
    if (self.observingTableView) {
        self.observingTableView = NO;
        [self.tableView removeObserver:self forKeyPath:PLVECKEYPATH_CONTENTSIZE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:UITableView.class] && [keyPath isEqualToString:PLVECKEYPATH_CONTENTSIZE]) {
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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isKindOfClass:UITableView.class]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackLogAction) object:nil];
        [self performSelector:@selector(trackLogAction) withObject:nil afterDelay:1];

        CGFloat height = scrollView.frame.size.height;
        CGFloat contentOffsetY = scrollView.contentOffset.y;
        CGFloat bottomOffset = scrollView.contentSize.height - contentOffsetY;
        if (bottomOffset <= height) {
            // 在最底部
            [self.receiveNewMessageView hidden];
        }
  
        return;
    }

    [self updatePageControlFrame];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat scrollScale = scrollView.contentOffset.x/self.scrollView.bounds.size.width;
    if (scrollScale == 0) {
        self.messageViewType = PLVECChatroomMessageViewTypeNormal;
    } else if (scrollScale == 1) {
        self.messageViewType = PLVECChatroomMessageViewTypeAskQuestion;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomMessageView:messageViewTypeChanged:)]) {
        [self.delegate chatroomMessageView:self messageViewTypeChanged:self.messageViewType];
    }
}

#pragma mark - PLVECChatroomViewModelProtocol
#pragma mark 公聊
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

- (void)chatroomManager_didMessageCountLimitedAutoDeleted {
    [self.tableView reloadData];
    if (!self.tableView.mj_header.superview) {
        MJRefreshNormalHeader *refreshHeader = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshAction:)];
        refreshHeader.lastUpdatedTimeLabel.hidden = YES;
        refreshHeader.stateLabel.hidden = YES;
        [refreshHeader.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        self.tableView.mj_header = refreshHeader;
    }
}

- (void)chatroomManager_didSendProhibitMessage {
    [self.tableView reloadData];
}

- (void)chatroomManager_loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    [self.tableView.mj_header endRefreshing];
    [self.tableView reloadData];
    
    if (noMore) {
        [self.tableView.mj_header removeFromSuperview];
    }
    if (first) {
        [self scrollsToBottom];
    } else {
        [self.tableView scrollsToTop];
    }
}

- (void)chatroomManager_loadHistoryFailure {
    [self.tableView.mj_header endRefreshing];
    [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"聊天记录获取失败") detail:@"" view:self];
}

#pragma mark - PLVECChatroomPlaybackViewModelDelegate
- (void)clearMessageForPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel {
    [self.tableView reloadData];
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
    [self.tableView.mj_header endRefreshing];
    [self.tableView reloadData];
}

#pragma mark - Action
- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    if (self.playbackEnable) {
        [self.playbackViewModel loadMoreMessages];
    } else {
        [[PLVECChatroomViewModel sharedViewModel] loadHistory];
    }
}

@end
