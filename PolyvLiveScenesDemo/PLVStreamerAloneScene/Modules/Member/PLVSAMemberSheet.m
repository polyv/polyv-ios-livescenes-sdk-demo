//
//  PLVSAMemberSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAMemberSheet.h"
#import "PLVSAMemberCell.h"
#import "PLVSAMemberPopup.h"
#import "PLVChatUser.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
// 模块
#import "PLVRoomDataManager.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxHeightScale = 0.72;
static CGFloat kMinHeightScale = 0.42;
static CGFloat kMidWidthtScale = 0.49;

@interface PLVSAMemberSheet ()<
UITableViewDelegate,
UITableViewDataSource,
PLVSAMemberCellDelegate
>
/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UITableView *tableView;

/// 数据
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList;
@property (nonatomic, assign) NSInteger userCount;
@property (nonatomic, assign) NSInteger onlineCount;
@property (nonatomic, assign) BOOL showingPopup;
@property (nonatomic, assign) BOOL startClass; // 是否开始上课
@property (nonatomic, assign) BOOL enableLinkMic; // 是否开启连麦

@end

@implementation PLVSAMemberSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount {
    CGFloat screenHeight = MAX(PLVScreenHeight, PLVScreenWidth);
    self = [super initWithSheetHeight:kMinHeightScale * screenHeight sheetLandscapeWidth:kMidWidthtScale * screenHeight];
    if (self) {
        self.userList = userList;
        self.userCount = userCount;
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat titleLabelLeft = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 56 : 32;

    self.headerView.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, 67);
    self.tableView.frame = CGRectMake(0, 67, self.contentView.bounds.size.width, self.contentView.bounds.size.height - 67);
    self.titleLabel.frame = CGRectMake(titleLabelLeft, 32, self.headerView.frame.size.width - titleLabelLeft * 2, 20);
}

#pragma mark - [ Public Method ]

- (void)updateUserList:(NSArray <PLVChatUser *> *)userList
             userCount:(NSInteger)userCount
           onlineCount:(NSInteger)onlineCount {
    self.userList = userList;
    self.userCount = userCount;
    self.onlineCount = onlineCount;
    [self updateUI];
}

- (void)startClass:(BOOL)start {
    _startClass = start;
    if (!start) {
        [self enableAudioVideoLinkMic:NO];
    }
    [self.tableView reloadData];
}

- (void)enableAudioVideoLinkMic:(BOOL)enable {
    _enableLinkMic = enable;
    [self.tableView reloadData];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.headerView];
    [self.contentView addSubview:self.tableView];
    [self.headerView addSubview:self.titleLabel];
}

- (void)updateUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setOnlineUserCount:self.userCount];
        [self updateSheetHight];
        [self.tableView reloadData];
    });
}

- (void)setOnlineUserCount:(NSInteger)count {
    if (count >= 0) {
        self.titleLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"在线人数（%zd）"), count];
    } else {
        self.titleLabel.text = PLVLocalizedString(@"在线人数（）");
    }
}

- (void)updateSheetHight {
    if ([PLVSAUtils sharedUtils].landscape) {
        self.sheetHight = PLVScreenHeight;
    } else {
        CGFloat cellHeight = [PLVSAMemberCell cellHeight];
        CGFloat screenHeight = PLVScreenHeight;
        CGFloat mSheetHeight = cellHeight * [self.userList count] + self.headerView.bounds.size.height + [PLVSAUtils sharedUtils].areaInsets.bottom;
        mSheetHeight = MAX(kMinHeightScale * screenHeight, MIN(kMaxHeightScale * screenHeight, mSheetHeight));
        self.sheetHight = mSheetHeight;
    }
}

#pragma mark Getter & Setter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = [PLVSAMemberCell cellHeight];
        _tableView.rowHeight = [PLVSAMemberCell cellHeight];
        _tableView.tableFooterView = [UIView new];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _tableView;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
    }
    return _headerView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        [self setOnlineUserCount:self.userCount];
    }
    return _titleLabel;
}

#pragma mark Chatroom

- (void)banUserWitUserId:(NSString *)userId userName:(NSString *)userName banned:(BOOL)banned {
    __weak typeof(self) weakSelf = self;
    if (banned) {
        NSString *title = [NSString stringWithFormat:PLVLocalizedString(@"确定禁言%@吗？"), userName];
        [PLVSAUtils showAlertWithTitle:title cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
            BOOL success = [[PLVChatroomManager sharedManager] sendBandMessage:YES bannedUserId:userId];
            if (success) {
                if (weakSelf.delegate &&
                    [weakSelf.delegate respondsToSelector:@selector(bandUsersInMemberSheet:withUserId:banned:)]) {
                    [weakSelf.delegate bandUsersInMemberSheet:weakSelf withUserId:userId banned:YES];
                }
            }
        }];
    } else {
        BOOL success = [[PLVChatroomManager sharedManager] sendBandMessage:NO bannedUserId:userId];
        if (success) {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(bandUsersInMemberSheet:withUserId:banned:)]) {
                [self.delegate bandUsersInMemberSheet:self withUserId:userId banned:NO];
            }
        }
    }
}

- (void)kickUserWitUserId:(NSString *)userId userName:(NSString *)userName {
    __weak typeof(self) weakSelf = self;
    NSString *title = [NSString stringWithFormat:PLVLocalizedString(@"确定踢出%@吗？"), userName];
    [PLVSAUtils showAlertWithTitle:title Message:PLVLocalizedString(@"踢出后24小时内无法进入") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
        BOOL success = [[PLVChatroomManager sharedManager] sendKickMessageWithUserId:userId];
        if (success) {
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(kickUsersInMemberSheet:withUserId:)]) {
                [weakSelf.delegate kickUsersInMemberSheet:weakSelf withUserId:userId];
            }
        }
    }];
}

- (void)authUserSpeakerWithUser:(PLVChatUser *)user auth:(BOOL)auth {
    PLVLinkMicOnlineUser *speakerUser = nil;
    if (auth) {
        for (int i = 0; i < self.userList.count; i++) {
            PLVChatUser *chatUser = self.userList[i];
            if (chatUser.onlineUser.isRealMainSpeaker) {
                speakerUser = chatUser.onlineUser;
                break;
            }
        }
    }
    
    if ((auth && speakerUser) ||
        (!auth && user.onlineUser.currentScreenShareOpen)) {
        NSString *titlePrefix = auth ? PLVLocalizedString(@"确定授予ta") : PLVLocalizedString(@"确定移除ta的");
        NSString *message = auth ? PLVLocalizedString(@"当前已有主讲人，确定后将替换为新的主讲人") : PLVLocalizedString(@"移除后主讲人的屏幕共享将会自动结束");
        NSString *alertTitle = [NSString stringWithFormat:PLVLocalizedString(@"%@主讲权限吗？"), titlePrefix];
        [PLVSAUtils showAlertWithTitle:alertTitle Message:message cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
            [user.onlineUser wantAuthUserSpeaker:auth];
        }];
    } else {
        [user.onlineUser wantAuthUserSpeaker:auth];
    }
}

#pragma mark - [ Delegate ]

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.userList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self.userList count]) {
        return [PLVSAMemberCell new];
    }
    
    static NSString *cellIdentifier = @"PLVSAMemberCellIdentifier";
    PLVSAMemberCell *cell = (PLVSAMemberCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVSAMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    PLVChatUser *user = self.userList[indexPath.row];
    [cell updateUser:user];
    return cell;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [PLVSAMemberCell cellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [PLVSAMemberCell cellHeight];
}

#pragma mark  PLVSAMemberCellDelegate

- (void)didTapMoreButtonInCell:(PLVSAMemberCell *)cell chatUser:(PLVChatUser *)chatUser {
    if (self.showingPopup) {
        return;
    }
    self.showingPopup = YES;
    
    CGRect cellRect = [self.tableView convertRect:cell.frame toView:self.contentView];
    cellRect = [self.contentView convertRect:cellRect toView:self];
    CGFloat centerY = cellRect.origin.y + cellRect.size.height / 2.0;
    
    PLVSAMemberPopup *popup = [[PLVSAMemberPopup alloc] initWithChatUser:chatUser centerYPoint:centerY];
    __weak typeof(self) weakSelf = self;
    popup.kickUserBlock = ^(NSString * _Nonnull userId, NSString * _Nonnull userName) {
        [weakSelf kickUserWitUserId:userId userName:userName];
    };
    popup.bandUserBlock = ^(NSString * _Nonnull userId, NSString * _Nonnull userName, BOOL banned) {
        [weakSelf banUserWitUserId:userId userName:userName banned:banned];
    };
    popup.authUserBlock = ^(PLVChatUser * _Nonnull user, BOOL auth) {
        [weakSelf authUserSpeakerWithUser:user auth:auth];
    };
    popup.didDismissBlock = ^{
        weakSelf.showingPopup = NO;
    };
    [popup showAtView:self];
}

- (BOOL)allowLinkMicInCell:(PLVSAMemberCell *)cell {
    NSInteger maxLinkMicCount = [PLVRoomDataManager sharedManager].roomData.interactNumLimit;
    BOOL allowLinkmic = self.onlineCount <= maxLinkMicCount;
    return allowLinkmic;
}

- (void)didInviteUserJoinLinkMicInCell:(PLVChatUser *)user {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inviteUserJoinLinkMicInMemberSheet:chatUser:)]) {
        [self.delegate inviteUserJoinLinkMicInMemberSheet:self chatUser:user];
    }
}

- (BOOL)startClassInCell:(PLVSAMemberCell *)cell {
    return self.startClass;
}

- (BOOL)enableAudioVideoLinkMicInCell:(PLVSAMemberCell *)cell {
    return self.enableLinkMic;
}

@end
