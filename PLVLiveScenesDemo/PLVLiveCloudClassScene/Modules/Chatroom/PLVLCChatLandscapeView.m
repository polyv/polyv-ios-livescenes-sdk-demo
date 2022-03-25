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
#import "PLVLCLandscapeSpeakCell.h"
#import "PLVLCLandscapeImageCell.h"
#import "PLVLCLandscapeImageEmotionCell.h"
#import "PLVLCLandscapeQuoteCell.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <MJRefresh/MJRefresh.h>

#define KEYPATH_CONTENTSIZE @"contentSize"

@interface PLVLCChatLandscapeView ()<
PLVLCChatroomViewModelProtocol,
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
        
        [[PLVLCChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
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
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (!fullScreen) {
        return;
    }
    
    [self.tableView reloadData];
    
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
    [[PLVLCChatroomViewModel sharedViewModel] loadHistory];
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
    self.newMessageCount = 0;
    [self.receiveNewMessageView hidden];
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

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count]) {
        return [UITableViewCell new];
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    
    if ([PLVLCLandscapeSpeakCell isModelValid:model]) {
        static NSString *speakMessageCellIdentify = @"PLVLCLandscapeSpeakCell";
        PLVLCLandscapeSpeakCell *cell = (PLVLCLandscapeSpeakCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeSpeakCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCLandscapeImageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCLandscapeImageCell";
        PLVLCLandscapeImageCell *cell = (PLVLCLandscapeImageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCLandscapeImageEmotionCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCLandscapeImageEmotionCell";
        PLVLCLandscapeImageEmotionCell *cell = (PLVLCLandscapeImageEmotionCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeImageEmotionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCLandscapeQuoteCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVLCLandscapeQuoteCell";
        PLVLCLandscapeQuoteCell *cell = (PLVLCLandscapeQuoteCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLandscapeQuoteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
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
    if (indexPath.row >= [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count]) {
        return 0;
    }
    
    CGFloat cellHeight = 44.0;
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    if ([PLVLCLandscapeSpeakCell isModelValid:model]) {
        cellHeight = [PLVLCLandscapeSpeakCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCLandscapeImageCell isModelValid:model]) {
        cellHeight = [PLVLCLandscapeImageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCLandscapeImageEmotionCell isModelValid:model]) {
        cellHeight = [PLVLCLandscapeImageEmotionCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCLandscapeQuoteCell isModelValid:model]) {
        cellHeight = [PLVLCLandscapeQuoteCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else {
        cellHeight = 0;
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
}

@end
