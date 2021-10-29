//
//  PLVHCChatroomListView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCChatroomListView.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCSpeakMessageCell.h"
#import "PLVHCImageMessageCell.h"
#import "PLVHCQuoteMessageCell.h"
#import "PLVHCCloseRoomMessageCell.h"
#import "PLVHCChatroomPlaceholderView.h"

// 数据
#import "PLVChatModel.h"

// 模块
#import "PLVRoomDataManager.h"
#import "PLVHCChatroomViewModel.h"

// 依赖库
#import <MJRefresh/MJRefresh.h>

@interface PLVHCChatroomListView()<
UITableViewDelegate,
UITableViewDataSource
>

#pragma mark UI
@property (nonatomic, strong) UITableView *tableView; // 聊天列表
@property (nonatomic, strong) MJRefreshNormalHeader *refresher; // 列表顶部加载更多控件
@property (nonatomic, strong) PLVHCChatroomPlaceholderView *placeholderView; // 未开始上课占位图

#pragma mark 数据
@property (nonatomic, assign) CGPoint lastContentOffset; // 聊天室列表上次滚动结束时的contentOffset
@property (nonatomic, assign) BOOL observingTableView; // 是否已对列表进行KVO，默认为NO
@property (nonatomic, assign) BOOL noMore; // 没有更多数据，隐藏下拉刷新、关闭滑动
@property (nonatomic, assign) BOOL deviceOrientationDidChange; // 设备旋转，刷新tableview
@end

#pragma mark KVO Key

#define KEYPATH_CONTENTSIZE @"contentSize"

@implementation PLVHCChatroomListView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.tableView];
        
        [self addSubview:self.placeholderView];
        
        [self observeTableView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationDidChange)
                             name:UIDeviceOrientationDidChangeNotification
                                                       object:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserveTableView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    CGFloat contentHeight = self.tableView.contentSize.height;
    if (contentHeight < CGRectGetHeight(self.bounds)) {
        CGRect newFrame = CGRectMake(0, self.bounds.size.height - contentHeight, self.bounds.size.width, contentHeight);
        self.tableView.frame = newFrame;
        [self scrollsToBottom:NO];
        self.tableView.scrollEnabled = !self.noMore;
    } else if (CGRectGetHeight(self.bounds) > 0) {
        self.tableView.frame = self.bounds;
        self.tableView.scrollEnabled = YES;
    }
    
    if (self.deviceOrientationDidChange) {
        self.deviceOrientationDidChange = NO;
        [self.tableView reloadData];
        [self scrollsToBottom:NO];
    }
    _placeholderView.frame = self.bounds;
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
    self.noMore = noMore;
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

- (void)startClass {
    // 移除占位图
    if (_placeholderView) {
        [_placeholderView removeFromSuperview];
        _placeholderView = nil;
    }
    [self.tableView reloadData];
}

- (void)finishClass {
    [self addSubview:self.placeholderView];
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

- (PLVHCChatroomPlaceholderView *)placeholderView {
    if (!_placeholderView) {
        _placeholderView = [[PLVHCChatroomPlaceholderView alloc] init];
    }
    return _placeholderView;
}

#pragma mark cell callback

- (void)resendSpeakMessage:(PLVChatModel *)model {
    if (![self netCan]) {
        model.msgState = PLVChatMsgStateFail;
        [PLVHCUtils showToastInWindowWithMessage:@"当前网络不可用，请检查网络设置"];
        return;
    }
    [[PLVHCChatroomViewModel sharedViewModel] resendSpeakMessage:model replyChatModel:model.replyMessage];
}

- (void)resendImageMessage:(PLVChatModel *)model{
    if (![self netCan]) {
        model.msgState = (PLVChatMsgState)PLVImageMessageSendStateFailed;
        [PLVHCUtils showToastInWindowWithMessage:@"当前网络不可用，请检查网络设置"];
        return;
    }
    [[PLVHCChatroomViewModel sharedViewModel] resendImageMessage:model];
}

- (void)didTapReplyMenuItem:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomListView:didTapReplyMenuItem:)]) {
        [self.delegate chatroomListView:self didTapReplyMenuItem:model];
    }
}

#pragma mark scrollView callback

- (void)didScrollViewUp {
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(chatroomListViewDidScrollTableViewUp:)]) {
        [self.delegate chatroomListViewDidScrollTableViewUp:self];
    }
}

#pragma mark 屏幕旋转

- (void)onDeviceOrientationDidChange {
    self.deviceOrientationDidChange = YES;
}

#pragma mark 网络是否可用
- (BOOL)netCan{
    return self.netState > 0 && self.netState < 4;
}

- (UITableViewCell *)createDefaultCellWithTableview:(UITableView *)tableView {
    static NSString *cellIdentify = @"cellIdentify";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    return cell;
}

#pragma mark - Event

#pragma mark Action

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVHCChatroomViewModel sharedViewModel] loadHistory];
}

#pragma mark - [ Delegate ] 

#pragma mark UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[PLVHCChatroomViewModel sharedViewModel] chatArray].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [PLVHCChatroomViewModel sharedViewModel].chatArray.count) {
        return [self createDefaultCellWithTableview:tableView];
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVHCChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    
    if ([PLVHCSpeakMessageCell isModelValid:model] &&
        [PLVHCSpeakMessageCell reuseIdentifierWithUser:model.user]) {
        
        NSString *speakMessageCellIdentify = [PLVHCSpeakMessageCell reuseIdentifierWithUser:model.user];
        PLVHCSpeakMessageCell *cell = (PLVHCSpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVHCSpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setProhibitWordTipdismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendSpeakMessage:model];
        }];
        
        return cell;
    } else if ([PLVHCImageMessageCell isModelValid:model] &&
               [PLVHCImageMessageCell reuseIdentifierWithUser:model.user]) {
        
        NSString *imageMessageCellIdentify = [PLVHCImageMessageCell reuseIdentifierWithUser:model.user];
        PLVHCImageMessageCell *cell = (PLVHCImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVHCImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setProhibitWordTipdismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendImageHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendImageMessage:model];
        }];
        
        return cell;
    } else if ([PLVHCQuoteMessageCell isModelValid:model] &&
               [PLVHCQuoteMessageCell reuseIdentifierWithUser:model.user]) {
        
        NSString *quoteMessageCellIdentify = [PLVHCQuoteMessageCell reuseIdentifierWithUser:model.user];
        PLVHCQuoteMessageCell *cell = (PLVHCQuoteMessageCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVHCQuoteMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setProhibitWordTipdismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendSpeakMessage:model];
        }];
        return cell;
    } else if ([PLVHCCloseRoomMessageCell isModelValid:model] &&
               [PLVHCCloseRoomMessageCell reuseIdentifierWithUser:model.user]) {
        NSString *closeRoomMessageCellIdentify = [PLVHCCloseRoomMessageCell reuseIdentifierWithUser:model.user];
        PLVHCCloseRoomMessageCell *cell = (PLVHCCloseRoomMessageCell *)[tableView dequeueReusableCellWithIdentifier:closeRoomMessageCellIdentify];
        if (!cell) {
            cell = [[PLVHCCloseRoomMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:closeRoomMessageCellIdentify];
        }
        [cell updateWithModel:model];
    
        return cell;
    } else {
        return [self createDefaultCellWithTableview:tableView];
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight = 0;
    if (indexPath.row >= [PLVHCChatroomViewModel sharedViewModel].chatArray.count) {
        return cellHeight;
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVHCChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    if ([PLVHCSpeakMessageCell isModelValid:model]) {
        cellHeight = [PLVHCSpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVHCImageMessageCell isModelValid:model]) {
        cellHeight = [PLVHCImageMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVHCQuoteMessageCell isModelValid:model]) {
        cellHeight = [PLVHCQuoteMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVHCCloseRoomMessageCell isModelValid:model]) {
        cellHeight = [PLVHCCloseRoomMessageCell cellHeightWithModel:model];
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
        [self didScrollViewUp];
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
                self.tableView.frame = self.bounds;
                self.tableView.scrollEnabled = !self.noMore;
            }];
        } else if (CGRectGetHeight(self.bounds) > 0) {
            self.tableView.frame = self.bounds;
            self.tableView.scrollEnabled = YES;
        }
    }
    
}


@end
