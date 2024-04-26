//
//  PLVLSRemindChatroomListView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSRemindChatroomListView.h"

///工具
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

/// UI
#import "PLVLSRemindSpeakMessageCell.h"
#import "PLVLSRemindImageMessageCell.h"

/// 数据
#import "PLVChatModel.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVLSChatroomViewModel.h"

/// 依赖库
#import <MJRefresh/MJRefresh.h>

#define KEYPATH_CONTENTSIZE @"contentSize"

@interface PLVLSRemindChatroomListView()<
UITableViewDelegate,
UITableViewDataSource
>

/// UI
@property (nonatomic, strong) UITableView *tableView; // 聊天列表
@property (nonatomic, strong) MJRefreshNormalHeader *refresher; // 列表顶部加载更多控件

/// 数据
@property (nonatomic, assign) CGPoint lastContentOffset; // 聊天室列表上次滚动结束时的contentOffset
@property (nonatomic, assign) BOOL observingTableView; // 是否已对列表进行KVO，默认为NO

@end

@implementation PLVLSRemindChatroomListView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.tableView];
        
        [self observeTableView];
    }
    return self;
}

- (void)layoutSubviews {
    
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
}

- (void)dealloc {
    [self removeObserveTableView];
}

#pragma mark - [ Public Method ]

- (void)didSendMessage {
    [self.tableView reloadData];
    [self scrollsToBottom:YES];
}

- (BOOL)didReceiveMessages {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    
    if (isBottom) { // tableview显示在最底部
        [self scrollsToBottom:YES];
    }
    return isBottom;
}

- (void)didMessageDeleted {
    [self.tableView reloadData];
}

- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
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

- (void)loadHistoryFailure {
    [self.refresher endRefreshing];
}

- (void)scrollsToBottom:(BOOL)animated {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    if (offsetY < 0.0) {
        offsetY = 0.0;
    }
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:animated];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

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

#pragma mark 工具

- (UITableViewCell *)createDefaultCellWithTableview:(UITableView *)tableView {
    static NSString *cellIdentify = @"cellIdentify";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    return cell;
}

#pragma mark 网络是否可用
- (BOOL)netCan{
    return self.netState > 0 && self.netState < 4;
}

#pragma mark cell callback
- (void)resendSpeakMessage:(PLVChatModel *)model {
    if (![self netCan]) {
        model.msgState = PLVChatMsgStateFail;
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"请检查网络设置") inView:[PLVLSUtils sharedUtils].homeVC.view];
        return;
    }
    [[PLVLSChatroomViewModel sharedViewModel] resendRemindSpeakMessage:model];
}

- (void)resendImageMessage:(PLVChatModel *)model {
    if (![self netCan]) {
        model.msgState = PLVChatMsgStateFail;
        [PLVLSUtils showToastWithMessage:PLVLocalizedString(@"请检查网络设置") inView:[PLVLSUtils sharedUtils].homeVC.view];
        return;
    }
    [[PLVLSChatroomViewModel sharedViewModel] resendRemindImageMessage:model];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVLSChatroomViewModel sharedViewModel] loadRemindHistory];
}

#pragma mark - [ KVO ]

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
            self.tableView.scrollEnabled = YES;
        }
    }
}

#pragma mark - [ Delegate ]
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[PLVLSChatroomViewModel sharedViewModel] chatRemindArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [PLVLSChatroomViewModel sharedViewModel].chatRemindArray.count) {
        return [self createDefaultCellWithTableview:tableView];
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLSChatroomViewModel sharedViewModel].chatRemindArray objectAtIndex:indexPath.row];
    NSString *previousUserId = nil;
    if (indexPath.row > 0) {
        PLVChatModel *tempModel = [[PLVLSChatroomViewModel sharedViewModel].chatRemindArray objectAtIndex:indexPath.row - 1];
        previousUserId = tempModel.user.userId;
    }
    
    if ([PLVLSRemindSpeakMessageCell isModelValid:model] &&
        [PLVLSRemindSpeakMessageCell reuseIdentifierWithUser:model.user]) {
        
        NSString *speakMessageCellIdentify = [PLVLSRemindSpeakMessageCell reuseIdentifierWithUser:model.user];
        PLVLSRemindSpeakMessageCell *cell = (PLVLSRemindSpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLSRemindSpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
        }
        
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width previousUserId:previousUserId];
        
        __weak typeof(self) weakSelf = self;
        
        [cell setProhibitWordTipDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendSpeakMessage:model];
        }];
        
        return cell;
    } else if ([PLVLSRemindImageMessageCell isModelValid:model] &&
               [PLVLSRemindImageMessageCell reuseIdentifierWithUser:model.user]) {
        
        NSString *imageMessageCellIdentify = [PLVLSRemindImageMessageCell reuseIdentifierWithUser:model.user];
        PLVLSRemindImageMessageCell *cell = (PLVLSRemindImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLSRemindImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width previousUserId:previousUserId];
        
        __weak typeof(self) weakSelf = self;
        [cell setProhibitWordTipDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendImageHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendImageMessage:model];
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

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight = 0;
    if (indexPath.row >= [PLVLSChatroomViewModel sharedViewModel].chatRemindArray.count) {
        return cellHeight;
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLSChatroomViewModel sharedViewModel].chatRemindArray objectAtIndex:indexPath.row];
    NSString *previousUserId = nil;
    if (indexPath.row > 0) {
        PLVChatModel *model = [[PLVLSChatroomViewModel sharedViewModel].chatRemindArray objectAtIndex:indexPath.row - 1];
        previousUserId = model.user.userId;
    }
    if ([PLVLSRemindSpeakMessageCell isModelValid:model]) {
        cellHeight = [PLVLSRemindSpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width previousUserId:previousUserId];
    } else if ([PLVLSRemindImageMessageCell isModelValid:model]) {
        cellHeight = [PLVLSRemindImageMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width previousUserId:previousUserId];
    } else {
        cellHeight = 0;
    }
    
    return cellHeight;
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat twoScreenHeight = scrollView.frame.size.height * 2;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    BOOL up = contentOffsetY < self.lastContentOffset.y;
    
    if (self.lastContentOffset.y <= 0 && scrollView.contentOffset.y <= 0) {
        up = YES;
    }
    
    self.lastContentOffset = scrollView.contentOffset;
    if (!up && self.didScrollTableViewUp) {
        self.didScrollTableViewUp();
    }
    
    if (contentHeight - contentOffsetY >= twoScreenHeight &&
        self.didScrollTableViewTwoScreens) {
        self.didScrollTableViewTwoScreens();
    }
}

@end
