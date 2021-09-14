//
//  PLVSAChatroomListView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChatroomListView.h"

/// UI
#import "PLVSASpeakMessageCell.h"
#import "PLVSAImageMessageCell.h"
#import "PLVSAImageEmotionMessageCell.h"
#import "PLVSAQuoteMessageCell.h"
#import "PLVSARewardMessageCell.h"

/// 数据
#import "PLVChatModel.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVSAChatroomViewModel.h"

/// 依赖库
#import <MJRefresh/MJRefresh.h>

#define KEYPATH_CONTENTSIZE @"contentSize"

@interface PLVSAChatroomListView ()<
UITableViewDelegate,
UITableViewDataSource
>

/// UI
@property (nonatomic, strong) UITableView *tableView; // 聊天列表
@property (nonatomic, strong) MJRefreshNormalHeader *refresher; // 列表顶部加载更多控件
@property (nonatomic, strong) CAGradientLayer *gradientLayer; // 顶部渐变透明遮罩

/// 数据
@property (nonatomic, assign) CGPoint lastContentOffset; // 聊天室列表上次滚动结束时的contentOffset
@property (nonatomic, assign) BOOL observingTableView; // 是否已对列表进行KVO，默认为NO

@end


@implementation PLVSAChatroomListView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.tableView];
        [self.layer setMask:self.gradientLayer];
        
        [self observeTableView];
    }
    return self;
}

- (void)dealloc {
    [self removeObserveTableView];
}

#pragma mark - [ Override ]

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

#pragma mark cell callback

- (void)resendSpeakMessage:(NSString *)message {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomListView:resendSpeakMessage:)]) {
        [self.delegate chatroomListView:self resendSpeakMessage:message];
    }
}

- (void)resendImageMessage:(NSString *)msgId image:(UIImage *)image{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomListView:resendImageMessage:image:)]) {
        [self.delegate chatroomListView:self resendImageMessage:msgId image:image];
    }
}

- (void)resendImageEmotionMessage:(NSString *)imageId imageUrl:(NSString *)imageUrl{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomListView:resendImageEmotionMessage:imageUrl:)]) {
        [self.delegate chatroomListView:self resendImageEmotionMessage:imageId imageUrl:imageUrl];
    }
}

- (void)resendReplyMessage:(NSString *)message replyModel:(PLVChatModel *)model{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomListView:resendReplyMessage:replyModel:)]) {
        [self.delegate chatroomListView:self resendReplyMessage:message replyModel:model];
    }
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

#pragma mark - Event

#pragma mark Action

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVSAChatroomViewModel sharedViewModel] loadHistory];
}

#pragma mark - Delegate

#pragma mark UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[PLVSAChatroomViewModel sharedViewModel] chatArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVSAChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    
    if ([PLVSASpeakMessageCell isModelValid:model]) {
        static NSString *speakMessageCellIdentify = @"PLVSASpeakMessageCell";
        PLVSASpeakMessageCell *cell = (PLVSASpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSASpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendHandler:^(NSString * _Nonnull message) {
            [weakSelf resendSpeakMessage:message];
        }];
        
        return cell;
    } else if ([PLVSAImageMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVSAImageMessageCell";
        PLVSAImageMessageCell *cell = (PLVSAImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSAImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendImageHandler:^(NSString * _Nonnull msgID, UIImage * _Nonnull image) {
            [weakSelf resendImageMessage:msgID image:image];
        }];
        
        return cell;
    } else if ([PLVSAImageEmotionMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVSAImageEmotionMessageCell";
        PLVSAImageEmotionMessageCell *cell = (PLVSAImageEmotionMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSAImageEmotionMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendImageEmotionHandler:^(NSString * _Nonnull imageId, NSString * _Nonnull imageUrl) {
            [weakSelf resendImageEmotionMessage:imageId imageUrl:imageUrl];
        }];
        
        return cell;
    } else if ([PLVSAQuoteMessageCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVSAQuoteMessageCell";
        PLVSAQuoteMessageCell *cell = (PLVSAQuoteMessageCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSAQuoteMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendReplyHandler:^(NSString * _Nonnull message, PLVChatModel * _Nonnull model) {
            [weakSelf resendReplyMessage:message replyModel:model];
        }];
        return cell;
    } else if ([PLVSARewardMessageCell isModelValid:model]) {
        static NSString *rewardMessageCellIdentify = @"PLVSARewardMessageCell";
        PLVSARewardMessageCell *cell = (PLVSARewardMessageCell *)[tableView dequeueReusableCellWithIdentifier:rewardMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSARewardMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rewardMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    
        return cell;
    } else {
        return [UITableViewCell new];
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight =  44.0;
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVSAChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    if ([PLVSASpeakMessageCell isModelValid:model]) {
        cellHeight = [PLVSASpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVSAImageMessageCell isModelValid:model]) {
        cellHeight = [PLVSAImageMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVSAImageEmotionMessageCell isModelValid:model]) {
        cellHeight = [PLVSAImageEmotionMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVSAQuoteMessageCell isModelValid:model]) {
        cellHeight = [PLVSAQuoteMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    } else if ([PLVSARewardMessageCell isModelValid:model]) {
        cellHeight = [PLVSARewardMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
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

@end
