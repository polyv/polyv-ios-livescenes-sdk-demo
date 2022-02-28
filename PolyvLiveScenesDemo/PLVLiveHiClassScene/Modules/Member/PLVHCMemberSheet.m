//
//  PLVHCMemberSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCMemberSheet.h"

/// UI
#import "PLVHCMemberSheetHeaderView.h"
#import "PLVHCMemberSheetEmptyView.h"
#import "PLVHCMemberSheetSelectView.h"
#import "PLVHCOnlineMemberCell.h"
#import "PLVHCKickedMemberCell.h"

/// 模块
#import "PLVChatUser.h"
#import "PLVHCMemberViewModel.h"
#import "PLVRoomDataManager.h"

/// 工具类
#import "PLVHCUtils.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCMemberSheet ()<
PLVHCMemberViewModelDelegate, // 成员模块回调
PLVHCMemberSheetSelectViewDelegate,
UITableViewDelegate,
UITableViewDataSource,
PLVHCOnlineMemberCellDelegate,
PLVHCKickedMemberCellDelegate
>

#pragma mark UI
@property (nonatomic, strong) PLVHCMemberSheetHeaderView *headerView; // 弹层顶部子视图
@property (nonatomic, strong) PLVHCMemberSheetEmptyView *emptyView; // 空白列表视图
@property (nonatomic, strong) PLVHCMemberSheetSelectView *selectView; // 数据切换视图
@property (nonatomic, strong) UITableView *tableView; // 数据列表

#pragma mark 数据
@property (nonatomic, strong, readonly) NSArray <PLVChatUser *> *userList; // 列表数据源
@property (nonatomic, assign) BOOL kickList; // 当前列表数据源 YES-移出学生 NO-在线学生，默认为NO

@end

@implementation PLVHCMemberSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#22273D"];
        self.layer.cornerRadius = 16;
        self.clipsToBounds = YES;
        
        [PLVHCMemberViewModel sharedViewModel].delegate = self;
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    self.headerView.frame = CGRectMake(0, 0, self.bounds.size.width, 64);
    self.tableView.frame = CGRectMake(0, 64, self.bounds.size.width, self.bounds.size.height - 64);
    self.emptyView.frame = self.tableView.frame;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)superView {
    [superView addSubview:self];
}

- (void)dismiss {
    if (self.headerView.changeListButton.selected) {
        [self changeListButtonAction];
    }
    [self removeFromSuperview];
}

- (void)setHandupLabelCount:(NSInteger)count {
    [self.headerView setHandupLabelCount:count];
}

- (void)linkMicUserJoinAnswer:(BOOL)success linkMicId:(NSString *)linkMicId {
    [self.userList enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:linkMicId]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            PLVHCOnlineMemberCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                [cell updateUserLinkMicAnswer:success];
            }
            *stop = YES;
        }
    }];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.headerView];
    [self addSubview:self.emptyView];
    [self addSubview:self.tableView];
    
    [self updateUserCount];
}

- (void)updateUI {
    [self updateUserCount];
    [self.tableView reloadData];
}

- (void)updateUserCount {
    PLVHCMemberViewModel *viewModel = [PLVHCMemberViewModel sharedViewModel];
    NSInteger count = self.kickList ? viewModel.kickedCount : viewModel.onlineCount;
    self.emptyView.hidden = count > 0;
    NSString *text = [NSString stringWithFormat:@"%@学生(%zd)", self.kickList ? @"移出" : @"在线", count];
    [self.headerView setTableTitle:text];
    [self.selectView updateWithOnlineUserCount:viewModel.onlineCount kickedUserCount:viewModel.kickedCount];
}

#pragma mark Getter & Setter

- (PLVHCMemberSheetHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[PLVHCMemberSheetHeaderView alloc] init];
        [_headerView setTableTitle:@"在线学生(0)"];
        [_headerView setHandupLabelCount:0];
        [_headerView.closeMicButton addTarget:self action:@selector(closeMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_headerView.leaveLinkMicButton addTarget:self action:@selector(leaveLinkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_headerView.changeListButton addTarget:self action:@selector(changeListButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _headerView;
}

- (PLVHCMemberSheetEmptyView *)emptyView {
    if (!_emptyView) {
        _emptyView = [[PLVHCMemberSheetEmptyView alloc] init];
        _emptyView.hidden = YES;
    }
    return _emptyView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 48.0;
        _tableView.rowHeight = 48.0;
        _tableView.tableFooterView = [UIView new];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (PLVHCMemberSheetSelectView *)selectView {
    if (!_selectView) {
        PLVHCMemberViewModel *viewModel = [PLVHCMemberViewModel sharedViewModel];
        _selectView = [[PLVHCMemberSheetSelectView alloc] initWithOnlineUserCount:viewModel.onlineCount kickedUserCount:viewModel.kickedCount];
        _selectView.delegate = self;
    }
    return _selectView;
}

- (NSArray <PLVChatUser *> *)userList {
    PLVHCMemberViewModel *viewModel = [PLVHCMemberViewModel sharedViewModel];
    return self.kickList ? viewModel.kickedUserArray : viewModel.onlineUserArray;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeMicButtonAction {
    self.headerView.closeMicButton.selected = !self.headerView.closeMicButton.isSelected;
    BOOL mute = self.headerView.closeMicButton.isSelected;
    if (mute) {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_MicAllAanned message:@"已全体禁麦"];
    } else {
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenMic message:@"已取消全体禁麦"];
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(muteAllLinkMicUserMicInMemberSheet:mute:)]) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            [weakSelf.delegate muteAllLinkMicUserMicInMemberSheet:weakSelf mute:mute];
        })
    }
}

- (void)leaveLinkMicButtonAction {
    __weak typeof(self) weakSelf = self;
    [PLVHCUtils showAlertWithTitle:@"学生下台" message:@"要将所有学生下台吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
        if (weakSelf.delegate &&
            [weakSelf.delegate respondsToSelector:@selector(closeAllLinkMicUserInMemberSheet:)]) {
            plv_dispatch_main_async_safe(^{
                BOOL success = [weakSelf.delegate closeAllLinkMicUserInMemberSheet:weakSelf];
                if (success) {
                    [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_AllStepDown message:@"已全体下台"];
                }
            })
        }
    }];
}

- (void)changeListButtonAction {
    self.headerView.changeListButton.selected = !self.headerView.changeListButton.selected;
    if (self.headerView.changeListButton.selected) {
        [self.selectView showInView:self];
    } else {
        [self.selectView dismiss];
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVHCMemberViewModelDelegate

- (void)onlineUserListChangedInMemberViewModel:(PLVHCMemberViewModel *)viewModel {
    [self updateUI];
}

- (void)kickedUserListChangedInMemberViewModel:(PLVHCMemberViewModel *)viewModel {
    [self updateUI];
}

- (void)raiseHandStatusChanged:(PLVHCMemberViewModel *)viewModel status:(BOOL)raiseHandStatus count:(NSInteger)raiseHandCount {
    [self setHandupLabelCount:raiseHandCount];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(raiseHandStatusChanged:status:count:)]) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            [weakSelf.delegate raiseHandStatusChanged:weakSelf status:raiseHandStatus count:raiseHandCount];
        })
    }
}

#pragma mark PLVHCMemberSheetSelectViewDelegate

- (void)selectButtonInSelectView:(PLVHCMemberSheetSelectView *)selectView atIndex:(NSInteger)index {
    BOOL changeData = (self.kickList && index == 0) || (!self.kickList && index == 1);
    if (changeData) {
        self.kickList = (index == 1);
        [self updateUI];
    }
    [self changeListButtonAction];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.userList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self.userList count]) {
        return [UITableViewCell new];
    }
    
    if (self.kickList) {
        static NSString *cellIdentifier = @"PLVHCMemberKickedCellIdentifier";
        PLVHCKickedMemberCell *cell = (PLVHCKickedMemberCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[PLVHCKickedMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.delegate = self;
        }
        PLVChatUser *user = self.userList[indexPath.row];
        [cell setChatUser:user even:(indexPath.row % 2 == 0)];
        return cell;
    } else {
        static NSString *cellIdentifier = @"PLVHCMemberOnlineCellIdentifier";
        PLVHCOnlineMemberCell *cell = (PLVHCOnlineMemberCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[PLVHCOnlineMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.delegate = self;
        }
        PLVChatUser *user = self.userList[indexPath.row];
        [cell setChatUser:user even:(indexPath.row % 2 == 0)];
        return cell;
    }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.kickList) {
        return [PLVHCKickedMemberCell cellHeight];
    } else {
        return [PLVHCOnlineMemberCell cellHeight];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.kickList) {
        return [PLVHCKickedMemberCell cellHeight];
    } else {
        return [PLVHCOnlineMemberCell cellHeight];
    }
}

#pragma mark PLVHCOnlineMemberCellDelegate

- (void)banUserInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell bannedUser:(PLVChatUser *)user banned:(BOOL)banned {
    NSString *alertTitle = banned ? @"禁言学生" : @"取消学生禁言";
    NSString *alertMessage = banned ? @"要将学生禁言吗？" : @"要取消学生禁言吗？";
    [PLVHCUtils showAlertWithTitle:alertTitle
                           message:alertMessage
                 cancelActionTitle:@"取消"
                 cancelActionBlock:nil
                confirmActionTitle:@"确定"
                confirmActionBlock:^{
        BOOL success = [[PLVChatroomManager sharedManager] sendBandMessage:banned bannedUserId:user.userId];
        if (success) {
            [[PLVHCMemberViewModel sharedViewModel] banUserWithUserId:user.userId banned:banned];
            if (banned) {
                [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_MuteOpen message:@"已对该学生开启禁言"];
            } else {
                [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_MuteClose message:@"已对该学生关闭禁言"];
            }
        }
    }];
}

- (void)kickUserInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell kickedUser:(PLVChatUser *)user {
    NSString *alertTitle = @"移出学生";
    NSString *alertMessage = @"要将学生移出教室吗？";
    [PLVHCUtils showAlertWithTitle:alertTitle
                           message:alertMessage
                 cancelActionTitle:@"取消"
                 cancelActionBlock:nil
                confirmActionTitle:@"确定"
                confirmActionBlock:^{
        BOOL success = [[PLVChatroomManager sharedManager] sendKickMessageWithUserId:user.userId];
        if (success) {
            [[PLVHCMemberViewModel sharedViewModel] kickUserWithUserId:user.userId];
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_StudentMoveOut message:@"已将学生移出教室"];
        }
    }];
}

- (void)linkMicInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell linkMicUser:(PLVChatUser *)user linkMic:(BOOL)linkMic {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inviteUserLinkMicInMemberSheet:linkMic:chatUser:)]) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            [weakSelf.delegate inviteUserLinkMicInMemberSheet:weakSelf linkMic:linkMic chatUser:user];
        })
    }
}

- (void)linkMicCompleteInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell linkMicUser:(PLVChatUser *)user {
    if (self.headerView.closeMicButton.isSelected &&
        user.onlineUser.currentMicOpen) {
        //如果是全员静音状态，则新上线用户需要关闭麦克风
        [user.onlineUser wantOpenUserMic:NO];
    }
}

- (BOOL)allowLinkMicInCell:(PLVHCOnlineMemberCell *)cell {
    __block NSInteger linkMinCount = 0;
    [self.userList enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.onlineUser) {  linkMinCount ++; }
    }];
    NSInteger maxLinkNumber = [PLVRoomDataManager sharedManager].roomData.linkNumber;
    return linkMinCount < maxLinkNumber ? YES : NO;//限制最大连麦数
}

#pragma mark PLVHCKickedMemberCellDelegate

- (void)unkickUserInKickedMemberCell:(PLVHCKickedMemberCell *)memberCell user:(PLVChatUser *)user {
    BOOL success = [[PLVChatroomManager sharedManager] sendUnkickMessageWithUserId:user.userId];
    if (success) {
        [[PLVHCMemberViewModel sharedViewModel] unkickUser:user];
    }
}

@end
