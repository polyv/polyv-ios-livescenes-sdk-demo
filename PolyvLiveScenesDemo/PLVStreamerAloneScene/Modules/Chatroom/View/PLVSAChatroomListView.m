//
//  PLVSAChatroomListView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChatroomListView.h"

// 工具
#import "PLVSAUtils.h"
#import "PLVLiveToast.h"
#import "PLVMultiLanguageManager.h"

/// UI
#import "PLVSASpeakMessageCell.h"
#import "PLVSAImageMessageCell.h"
#import "PLVSAImageEmotionMessageCell.h"
#import "PLVSAQuoteMessageCell.h"
#import "PLVSARewardMessageCell.h"
#import "PLVSALongContentMessageCell.h"

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
@property (nonatomic, assign, readonly) BOOL allowPinMessage; // 是否允许评论上墙功能

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
    [PLVSAChatroomViewModel sharedViewModel].tableViewWidth = self.tableView.frame.size.width;
}

#pragma mark - [ Public Method ]

- (void)didSendMessage {
    [self.tableView reloadData];
    [self scrollsToBottom:NO];
}

- (BOOL)didReceiveMessages {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    
    if (isBottom) { // tableview显示在最底部
        [self scrollsToBottom:NO];
    }
    return isBottom;
}

- (void)didMessageDeleted {
    [self.tableView reloadData];
}

- (void)didMessageCountLimitedAutoDeleted {
    [self.tableView reloadData];
    if (!self.refresher.superview) {
        self.tableView.mj_header = self.refresher;
    }
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

// 点击超长文本消息(超过200字符）的【复制】按钮时调用
- (void)pasteFullContentWithModel:(PLVChatModel *)model {
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        [[PLVSAChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
            if (content) {
                model.overLenContent = content;
                [UIPasteboard generalPasteboard].string = content;
                [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:[PLVSAUtils sharedUtils].homeVC.view afterDelay:3.0];
            }
        }];
    } else {
        NSString *pasteString = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (pasteString) {
            [UIPasteboard generalPasteboard].string = pasteString;
            [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:[PLVSAUtils sharedUtils].homeVC.view afterDelay:3.0];
        }
    }
}

// 点击超长文本消息(超过500字符）的【更多】按钮时调用
- (void)alertToShowFullContentWithModel:(PLVChatModel *)model {
    __weak typeof(self) weakSelf = self;
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        [[PLVSAChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
            if (content) {
                model.overLenContent = content;
                [weakSelf notifyDelegateToAlertChatModel:model];
            }
        }];
    } else {
        NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (content) {
            [self notifyDelegateToAlertChatModel:model];
        }
    }
}

- (void)notifyDelegateToAlertChatModel:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomListView:alertLongContentMessage:)]) {
        [self.delegate chatroomListView:self alertLongContentMessage:model];
    }
}

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

- (BOOL)allowPinMessage {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.menuInfo.pinMsgEnabled) {
        if (roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ||
            roomData.roomUser.viewerType == PLVRoomUserTypeAssistant) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)allowBanUser {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    // 只有讲师和助教可以禁言用户
    if (roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ||
        roomData.roomUser.viewerType == PLVRoomUserTypeAssistant) {
        return YES;
    }
    return NO;
}

- (BOOL)allowKickUser {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    // 只有讲师和助教可以踢出用户
    if (roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ||
        roomData.roomUser.viewerType == PLVRoomUserTypeAssistant) {
        return YES;
    }
    return NO;
}

- (BOOL)canManageUser:(PLVChatUser *)user {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    // 不能对自己操作
    if ([user.userId isEqualToString:roomData.roomUser.viewerId]) {
        return NO;
    }
    // 不能对讲师、助教、管理员、嘉宾操作
    if (user.userType == PLVRoomUserTypeTeacher ||
        user.userType == PLVRoomUserTypeAssistant ||
        user.userType == PLVRoomUserTypeManager ||
        user.userType == PLVRoomUserTypeGuest) {
        return NO;
    }
    return YES;
}

#pragma mark Setter

- (void)setCloseGiftEffects:(BOOL)closeGiftEffects {
    _closeGiftEffects = closeGiftEffects;
    [self.tableView reloadData];
}

#pragma mark cell callback

- (void)resendSpeakMessage:(PLVChatModel *)model {
    BOOL success = [[PLVSAChatroomViewModel sharedViewModel] resendSpeakMessage:model replyChatModel:model.replyMessage];
    if (!success) {
        [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"消息发送失败")];
    }
}

- (void)resendImageMessage:(PLVChatModel *)model {
    BOOL success = [[PLVSAChatroomViewModel sharedViewModel] resendImageMessage:model];
    if (!success) {
        [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"消息发送失败")];
    }
}

- (void)resendImageEmotionMessage:(PLVChatModel *)model {
    BOOL success = [[PLVSAChatroomViewModel sharedViewModel] resendImageEmotionMessage:model];
    if (!success) {
        [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"消息发送失败")];
    }
}

- (void)didTapReplyMenuItem:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomListView:didTapReplyMenuItem:)]) {
        [self.delegate chatroomListView:self didTapReplyMenuItem:model];
    }
}

- (void)didTapPinMessageMenuItem:(PLVChatModel *)model {
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(chatroomListView:didTapPinMessageMenuItem:)]) {
        [self.delegate chatroomListView:self didTapPinMessageMenuItem:model];
    }
}

- (void)didTapBanUserMenuItem:(PLVChatModel *)model {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomListView:didTapBanUserMenuItem:)]) {
        [self.delegate chatroomListView:self didTapBanUserMenuItem:model];
    }
}

- (void)didTapKickUserMenuItem:(PLVChatModel *)model {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroomListView:didTapKickUserMenuItem:)]) {
        [self.delegate chatroomListView:self didTapKickUserMenuItem:model];
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
    return self.closeGiftEffects ? [[[PLVSAChatroomViewModel sharedViewModel] chatArrayWithoutReward] count] : [[[PLVSAChatroomViewModel sharedViewModel] chatArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.closeGiftEffects) {
        if (indexPath.row >= [PLVSAChatroomViewModel sharedViewModel].chatArrayWithoutReward.count) {
            return [UITableViewCell new];
        }
    } else if (indexPath.row >= [PLVSAChatroomViewModel sharedViewModel].chatArray.count) {
        return [UITableViewCell new];
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = self.closeGiftEffects ? [[PLVSAChatroomViewModel sharedViewModel].chatArrayWithoutReward objectAtIndex:indexPath.row] : [[PLVSAChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    
    if ([PLVSASpeakMessageCell isModelValid:model]) {
        static NSString *speakMessageCellIdentify = @"PLVSASpeakMessageCell";
        PLVSASpeakMessageCell *cell = (PLVSASpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSASpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        cell.allowPinMessage = self.allowPinMessage;
        cell.allowBanUser = self.allowBanUser && [self canManageUser:model.user];
        cell.allowKickUser = self.allowKickUser && [self canManageUser:model.user];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendSpeakMessage:model];
        }];
        
        [cell setPinMessageHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapPinMessageMenuItem:model];
        }];
        
        [cell setBanUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapBanUserMenuItem:model];
        }];
        
        [cell setKickUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapKickUserMenuItem:model];
        }];
        
        return cell;
    } else if ([PLVSALongContentMessageCell isModelValid:model]) {
        static NSString *LongContentMessageCell = @"LongContentMessageCell";
        PLVSALongContentMessageCell *cell = (PLVSALongContentMessageCell *)[tableView dequeueReusableCellWithIdentifier:LongContentMessageCell];
        if (!cell) {
            cell = [[PLVSALongContentMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LongContentMessageCell];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        cell.allowPinMessage = self.allowPinMessage;
        cell.allowBanUser = self.allowBanUser && [self canManageUser:model.user];
        cell.allowKickUser = self.allowKickUser && [self canManageUser:model.user];
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        [cell setResendHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendSpeakMessage:model];
        }];
        [cell setCopButtonHandler:^{
            [weakSelf pasteFullContentWithModel:model];
        }];
        [cell setFoldButtonHandler:^{
            [weakSelf alertToShowFullContentWithModel:model];
        }];
        [cell setPinMessageHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapPinMessageMenuItem:model];
        }];
        [cell setBanUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapBanUserMenuItem:model];
        }];
        [cell setKickUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapKickUserMenuItem:model];
        }];
        return cell;
    } else if ([PLVSAImageMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVSAImageMessageCell";
        PLVSAImageMessageCell *cell = (PLVSAImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSAImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        cell.allowBanUser = self.allowBanUser && [self canManageUser:model.user];
        cell.allowKickUser = self.allowKickUser && [self canManageUser:model.user];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendImageHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendImageMessage:model];
        }];
        
        [cell setBanUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapBanUserMenuItem:model];
        }];
        
        [cell setKickUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapKickUserMenuItem:model];
        }];
        
        return cell;
    } else if ([PLVSAImageEmotionMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVSAImageEmotionMessageCell";
        PLVSAImageEmotionMessageCell *cell = (PLVSAImageEmotionMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSAImageEmotionMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        cell.allowBanUser = self.allowBanUser && [self canManageUser:model.user];
        cell.allowKickUser = self.allowKickUser && [self canManageUser:model.user];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendImageEmotionHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendImageEmotionMessage:model];
        }];
        
        [cell setBanUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapBanUserMenuItem:model];
        }];
        
        [cell setKickUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapKickUserMenuItem:model];
        }];
        
        return cell;
    } else if ([PLVSAQuoteMessageCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVSAQuoteMessageCell";
        PLVSAQuoteMessageCell *cell = (PLVSAQuoteMessageCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVSAQuoteMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        cell.allowPinMessage = self.allowPinMessage;
        cell.allowBanUser = self.allowBanUser && [self canManageUser:model.user];
        cell.allowKickUser = self.allowKickUser && [self canManageUser:model.user];
        
        __weak typeof(self) weakSelf = self;
        [cell setReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        
        [cell setDismissHandler:^{
            [weakSelf.tableView reloadData];
        }];
        
        [cell setResendReplyHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf resendSpeakMessage:model];
        }];
        
        [cell setPinMessageHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapPinMessageMenuItem:model];
        }];
        
        [cell setBanUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapBanUserMenuItem:model];
        }];
        
        [cell setKickUserHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapKickUserMenuItem:model];
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
    if (self.closeGiftEffects) {
        if (indexPath.row >= [PLVSAChatroomViewModel sharedViewModel].chatArrayWithoutReward.count) {
            return 0.0;
        }
    } else if (indexPath.row >= [PLVSAChatroomViewModel sharedViewModel].chatArray.count) {
        return 0.0;
    }
    
    CGFloat cellHeight =  44.0;
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
   PLVChatModel *model = self.closeGiftEffects ? [[PLVSAChatroomViewModel sharedViewModel].chatArrayWithoutReward objectAtIndex:indexPath.row] : [[PLVSAChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    if ([PLVSASpeakMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVSASpeakMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVSALongContentMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVSALongContentMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVSAImageMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVSAImageMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVSAImageEmotionMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVSAImageEmotionMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVSAQuoteMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVSAQuoteMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVSARewardMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVSARewardMessageCell cellHeightWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
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
