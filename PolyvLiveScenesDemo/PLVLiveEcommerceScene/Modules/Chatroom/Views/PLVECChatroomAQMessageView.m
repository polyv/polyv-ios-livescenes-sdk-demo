//
//  PLVECChatroomAQMessageView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/8.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECChatroomAQMessageView.h"
#import "PLVECChatroomViewModel.h"
#import "PLVECChatroomPlaybackViewModel.h"
#import "PLVECChatCell.h"
#import "PLVECAskQuestionChatCell.h"
#import "PLVECNewMessageView.h"
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVToast.h"
#import "PLVRoomDataManager.h"
#import <MJRefresh/MJRefresh.h>

static NSString *const PLVECKEYPATH_AQ_CONTENTSIZE = @"contentSize";

@interface PLVECChatroomAQMessageView ()<
UITableViewDelegate,
UITableViewDataSource,
PLVECChatroomViewModelProtocol
>

#pragma mark 数据
/// 数据源数目
@property (nonatomic, strong, readonly) NSArray *dataArray;
@property (nonatomic, assign) BOOL observingTableView;

#pragma mark UI
@property (nonatomic, strong) UIView *tableViewBackgroundView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *askQuestionButton;
// 渐变蒙层
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
/// 新消息提示条幅
@property (nonatomic, strong) PLVECNewMessageView *receiveNewMessageView;

@end

@implementation PLVECChatroomAQMessageView

#pragma mark - [ Life Cycle ]
- (void)dealloc {
    [self removeObserveTableView];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.tableViewBackgroundView];
        [self addSubview:self.askQuestionButton];
        [self.tableViewBackgroundView addSubview:self.tableView];
        [self.tableViewBackgroundView addSubview:self.receiveNewMessageView];
        self.tableViewBackgroundView.layer.mask = self.gradientLayer;

        [[PLVECChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[PLVECChatroomViewModel sharedViewModel] createAnswerChatModel];
        [self observeTableView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize buttonSize = [self.askQuestionButton sizeThatFits:CGSizeMake(MAXFLOAT, 28)];
    self.askQuestionButton.frame = CGRectMake(0, 0, buttonSize.width + 18, 28);
    self.tableViewBackgroundView.frame = CGRectMake(0, 28 + 6, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - CGRectGetMaxY(self.askQuestionButton.frame) - 6);
    self.tableView.frame = self.tableViewBackgroundView.bounds;
    self.gradientLayer.frame = self.tableViewBackgroundView.bounds;
    self.receiveNewMessageView.frame = CGRectMake(0, CGRectGetHeight(self.tableViewBackgroundView.frame) - 25, 86, 25);
}

#pragma mark - [ Public Method ]

#pragma mark - [ Private Methods ]
- (void)scrollsToBottom {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    offsetY = MAX(0, offsetY);
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:YES];
}

#pragma mark Getter
- (NSArray *)dataArray {
    NSArray *dataArray = [PLVECChatroomViewModel sharedViewModel].privateChatArray;
    return dataArray;
}

- (UIView *)tableViewBackgroundView {
    if (!_tableViewBackgroundView) {
        _tableViewBackgroundView = [[UIView alloc] init];
    }
    return _tableViewBackgroundView;
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

- (UIButton *)askQuestionButton {
    if (!_askQuestionButton) {
        _askQuestionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _askQuestionButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#333333" alpha:0.6];
        _askQuestionButton.layer.cornerRadius = 14.0f;
        _askQuestionButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_askQuestionButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFFFF"] forState:UIControlStateNormal];
        [_askQuestionButton setTitle:PLVLocalizedString(@"提问频道") forState:UIControlStateNormal];
        [_askQuestionButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 3, 0, -3)];
        UIImage *askQuestionImage = [PLVECUtils imageForWatchResource:@"plvec_chatroom_message_askquestion_icon"];
        [_askQuestionButton setImage:askQuestionImage forState:UIControlStateNormal];
        _askQuestionButton.userInteractionEnabled = NO;
    }
    return _askQuestionButton;
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

#pragma mark - KVO
- (void)observeTableView {
    if (!self.observingTableView) {
        self.observingTableView = YES;
        [self.tableView addObserver:self forKeyPath:PLVECKEYPATH_AQ_CONTENTSIZE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveTableView {
    if (self.observingTableView) {
        self.observingTableView = NO;
        [self.tableView removeObserver:self forKeyPath:PLVECKEYPATH_AQ_CONTENTSIZE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:UITableView.class] && [keyPath isEqualToString:PLVECKEYPATH_AQ_CONTENTSIZE]) {
        CGFloat contentHeight = self.tableView.contentSize.height;
        if (contentHeight < CGRectGetHeight(self.tableViewBackgroundView.bounds)) {
            [UIView animateWithDuration:0.2 animations:^{
                CGRect newFrame = CGRectMake(0, CGRectGetHeight (self.tableViewBackgroundView.bounds)-contentHeight, CGRectGetWidth(self.tableViewBackgroundView.bounds), contentHeight);
                self.tableView.frame = newFrame;
            }];
        } else if (CGRectGetHeight(self.tableViewBackgroundView.bounds) > 0) {
            self.tableView.scrollEnabled = YES;
            self.tableView.frame = self.tableViewBackgroundView.bounds;
            [self removeObserveTableView];
        }
    }
}

#pragma mark - PLVLCChatroomViewModelProtocol
- (void)chatroomManager_didSendQuestionMessage {
    [self.tableView reloadData];
    [self scrollsToBottom];
}

- (void)chatroomManager_didReceiveAnswerMessage {
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
    
    if (isBottom || self.tableView.bounds.size.height == 0) { // tableview显示在最底部
        [self.receiveNewMessageView hidden];
        [self scrollsToBottom];
    } else {
        // 显示未读消息提示
        [self.receiveNewMessageView show];
    }
}

- (void)chatroomManager_loadQuestionHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
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

- (void)chatroomManager_loadQuestionHistoryFailure {
    [self.tableView.mj_header endRefreshing];
    [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"提问历史记录获取失败") detail:@"" view:self];
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.dataArray.count) {
        return [UITableViewCell new];
    }
    
    PLVChatModel *model = self.dataArray[indexPath.row];
    if ([PLVECChatCell isModelValid:model]) {
        static NSString *normalCellIdentify = @"AQNormalCellIdentify";
        PLVECChatCell *cell = (PLVECChatCell *)[tableView dequeueReusableCellWithIdentifier:normalCellIdentify];
        if (!cell) {
            cell = [[PLVECChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:normalCellIdentify];
            cell.quoteReplyEnabled = NO;
        }
        [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if([PLVECAskQuestionChatCell isModelValid:model]) {
        static NSString *cellIdentify = @"PLVECAskQuestionChatCell";
        PLVECAskQuestionChatCell *cell = (PLVECAskQuestionChatCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
        if (!cell) {
            cell = [[PLVECAskQuestionChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
        }
        [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
        return cell;
    } else {
        static NSString *cellIdentify = @"AQCellIdentify";
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
        }
        return cell;
    }
}

#pragma mark - UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.dataArray.count) {
        return 0.0;
    }
    
    CGFloat cellHeight = 0.0;
    PLVChatModel *model = self.dataArray[indexPath.row];
    if ([PLVECChatCell isModelValid:model]) {
        cellHeight = [PLVECChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVECAskQuestionChatCell isModelValid:model]) {
        cellHeight = [PLVECAskQuestionChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else {
        cellHeight = 0.0;
    }
    return cellHeight;
}

#pragma mark - Action
- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVECChatroomViewModel sharedViewModel] loadQuestionHistory];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isKindOfClass:UITableView.class]) {
        CGFloat height = scrollView.frame.size.height;
        CGFloat contentOffsetY = scrollView.contentOffset.y;
        CGFloat bottomOffset = scrollView.contentSize.height - contentOffsetY;
        if (bottomOffset <= height) {
            // 在最底部
            [self.receiveNewMessageView hidden];
        }
    }
}

@end
