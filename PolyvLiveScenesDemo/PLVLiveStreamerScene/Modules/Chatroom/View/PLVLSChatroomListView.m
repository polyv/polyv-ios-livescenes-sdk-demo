//
//  PLVLSChatroomListView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/16.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSChatroomListView.h"

/// UI
#import "PLVLSSpeakMessageCell.h"
#import "PLVLSImageMessageCell.h"
#import "PLVLSQuoteMessageCell.h"
#import "PLVLSImageEmotionMessageCell.h"
#import "PLVLSLongContentMessageCell.h"
#import "PLVLSLongContentMessageSheet.h"

/// 数据
#import "PLVChatModel.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVLSChatroomViewModel.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVToast.h"

/// 依赖库
#import <MJRefresh/MJRefresh.h>

#define KEYPATH_CONTENTSIZE @"contentSize"

@interface PLVLSChatroomListView ()<
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

@implementation PLVLSChatroomListView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.tableView];
        [self.layer setMask:self.gradientLayer];
        
        [self observeTableView];
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
    [PLVLSChatroomViewModel sharedViewModel].tableViewWidth = self.tableView.frame.size.width;
}

- (void)dealloc {
    [self removeObserveTableView];
}

#pragma mark - Getter

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

#pragma mark - Action

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVLSChatroomViewModel sharedViewModel] loadHistory];
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

#pragma mark cell方法
- (UITableViewCell *)createDefaultCellWithTableview:(UITableView *)tableView {
    static NSString *cellIdentify = @"cellIdentify";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    return cell;
}

- (void)refreshCellWithIndex:(NSIndexPath *)indexPath {
    [self.tableView reloadData];
    if (indexPath.row >= [PLVLSChatroomViewModel sharedViewModel].chatArray.count - 2) { // 最后两行需要将tableView滑动到底部
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scrollsToBottom:NO];
        });
    }
}

#pragma mark - Public Method

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

#pragma mark - Private Method

// 点击超长文本消息(超过200字符）的【复制】按钮时调用
- (void)pasteFullContentWithModel:(PLVChatModel *)model {
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        [[PLVLSChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
            if (content) {
                model.overLenContent = content;
                [UIPasteboard generalPasteboard].string = content;
                [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:[PLVLSUtils sharedUtils].homeVC.view afterDelay:3.0];
            }
        }];
    } else {
        NSString *pasteString = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (pasteString) {
            [UIPasteboard generalPasteboard].string = pasteString;
            [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:[PLVLSUtils sharedUtils].homeVC.view afterDelay:3.0];
        }
    }
}

// 点击超长文本消息(超过500字符）的【更多】按钮时调用
- (void)requestFullContentWithModel:(PLVChatModel *)model {
    __weak typeof(self) weakSelf = self;
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        [[PLVLSChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
            if (content) {
                model.overLenContent = content;
                [weakSelf alertToShowFullContentWithModel:model];
            }
        }];

    } else {
        NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (content) {
            [self alertToShowFullContentWithModel:model];
        }
    }
}

// 弹窗显示全部文本
- (void)alertToShowFullContentWithModel:(PLVChatModel *)model {
    PLVLSLongContentMessageSheet *messageSheet = [[PLVLSLongContentMessageSheet alloc] initWithChatModel:model];
    [messageSheet showInView:[PLVLSUtils sharedUtils].homeVC.view];
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[PLVLSChatroomViewModel sharedViewModel] chatArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [PLVLSChatroomViewModel sharedViewModel].chatArray.count) {
        return [self createDefaultCellWithTableview:tableView];
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLSChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    
    if ([PLVLSSpeakMessageCell isModelValid:model]) {
        static NSString *speakMessageCellIdentify = @"PLVLSSpeakMessageCell";
        PLVLSSpeakMessageCell *cell = (PLVLSSpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLSSpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            if (weakSelf.didTapReplyMenuItem) {
                weakSelf.didTapReplyMenuItem(model);
            }
        }];
        
        [cell setProhibitWordShowHandler:^{
            [weakSelf refreshCellWithIndex:indexPath];
        }];
        
        [cell setProhibitWordDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        return cell;
    } else if ([PLVLSLongContentMessageCell isModelValid:model]) {
        static NSString *LongContentMessageCell = @"LongContentMessageCell";
        PLVLSLongContentMessageCell *cell = (PLVLSLongContentMessageCell *)[tableView dequeueReusableCellWithIdentifier:LongContentMessageCell];
        if (!cell) {
            cell = [[PLVLSLongContentMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LongContentMessageCell];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            if (weakSelf.didTapReplyMenuItem) {
                weakSelf.didTapReplyMenuItem(model);
            }
        }];
        [cell setProhibitWordShowHandler:^{
            [weakSelf refreshCellWithIndex:indexPath];
        }];
        
        [cell setProhibitWordDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        [cell setCopButtonHandler:^{
            [weakSelf pasteFullContentWithModel:model];
        }];
        [cell setFoldButtonHandler:^{
            [weakSelf requestFullContentWithModel:model];
        }];
        return cell;
    } else if ([PLVLSImageMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLSImageMessageCell";
        PLVLSImageMessageCell *cell = (PLVLSImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLSImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            if (weakSelf.didTapReplyMenuItem) {
                weakSelf.didTapReplyMenuItem(model);
            }
        }];
        
        [cell setProhibitWordShowHandler:^{
            [weakSelf refreshCellWithIndex:indexPath];
        }];
        
        [cell setProhibitWordDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        return cell;
    } else if ([PLVLSImageEmotionMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLSImageEmotionMessageCell";
        PLVLSImageEmotionMessageCell *cell = (PLVLSImageEmotionMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLSImageEmotionMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            if (weakSelf.didTapReplyMenuItem) {
                weakSelf.didTapReplyMenuItem(model);
            }
        }];
        
        [cell setProhibitWordShowHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setProhibitWordDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        return cell;
    } else if ([PLVLSQuoteMessageCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVLSQuoteMessageCell";
        PLVLSQuoteMessageCell *cell = (PLVLSQuoteMessageCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLSQuoteMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            if (weakSelf.didTapReplyMenuItem) {
                weakSelf.didTapReplyMenuItem(model);
            }
        }];
        
        [cell setProhibitWordShowHandler:^{
            [weakSelf refreshCellWithIndex:indexPath];
        }];
        
        [cell setProhibitWordDismissHandler:^{
            [weakSelf.tableView reloadData];
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
    if (indexPath.row >= [PLVLSChatroomViewModel sharedViewModel].chatArray.count) {
        return 0.0;
    }
    
    CGFloat cellHeight =  44.0;
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLSChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    if ([PLVLSSpeakMessageCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLSSpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLSLongContentMessageCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLSLongContentMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLSImageMessageCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLSImageMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLSImageEmotionMessageCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLSImageEmotionMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else if ([PLVLSQuoteMessageCell isModelValid:model]) {
        if (model.cellHeightForH == 0.0) {
            model.cellHeightForH = [PLVLSQuoteMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForH;
    } else {
        cellHeight = 0.0;
    }
    
    return cellHeight;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL up = scrollView.contentOffset.y < self.lastContentOffset.y;
    if (self.lastContentOffset.y <= 0 && scrollView.contentOffset.y <= 0) {
        up = YES;
    }
    
    self.lastContentOffset = scrollView.contentOffset;
    if (!up && self.didScrollTableViewUp) {
        self.didScrollTableViewUp();
    }
}

@end
