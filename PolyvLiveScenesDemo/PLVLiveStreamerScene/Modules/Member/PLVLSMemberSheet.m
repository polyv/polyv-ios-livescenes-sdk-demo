//
//  PLVLSMemberSheet.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/29.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSMemberSheet.h"

/// 工具
#import "PLVLSUtils.h"

/// UI
#import "PLVLSMemberCell.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVChatUser.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@interface PLVLSMemberSheet ()<
PLVLSMemberCellDelegate,
UITableViewDelegate,
UITableViewDataSource
>

/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UIButton *leaveMicButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UIView *titleLine;
@property (nonatomic, strong) UITableView *tableView;

/// 数据
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList;
@property (nonatomic, assign) NSInteger userCount;
@property (nonatomic, assign) BOOL tableViewEditing; // 列表是否处于左滑中状态
@property (nonatomic, assign) BOOL delayReload; // 是否在左滑时遇到列表刷新通知
@property (nonatomic, assign) BOOL showLeftDragAnimation; // 显示左滑动画
@end

@implementation PLVLSMemberSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    self = [super initWithSheetWidth:screenWidth * 0.52];
    if (self) {
        self.userList = userList;
        self.userCount = userCount;
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(16, 14, 70, 22);
    
    CGFloat buttonWidth = 88.0;
    if (self.bounds.size.width <= 667) {  // iphone小屏适配
        buttonWidth = 66.0 - (self.bounds.size.width/667);
    }
    CGFloat buttonOriginX = self.sheetWidth - PLVLSUtils.safeSidePad - buttonWidth * 2 - 4;
    
    self.countLabel.frame = CGRectMake(84, 17, buttonOriginX - 84 - 4, 17);
    self.leaveMicButton.frame = CGRectMake(buttonOriginX, 11, buttonWidth, 28);
    self.muteButton.frame = CGRectMake(buttonOriginX + buttonWidth + 4, 11, buttonWidth, 28);
    self.titleLine.frame = CGRectMake(16, 44, self.sheetWidth - 16 - PLVLSUtils.safeSidePad, 1);
    
    CGFloat tableViewOriginY = CGRectGetMaxY(self.titleLine.frame);
    self.tableView.frame = CGRectMake(16, tableViewOriginY, CGRectGetWidth(self.titleLine.frame), self.bounds.size.height - tableViewOriginY);
}

#pragma mark - [ Public Method ]

- (void)updateUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount {
    self.userList = userList;
    self.userCount = userCount;
    
    [self updateUI];
}

#pragma mark - [Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.countLabel];
    [self.contentView addSubview:self.leaveMicButton];
    [self.contentView addSubview:self.muteButton];
    [self.contentView addSubview:self.titleLine];
    [self.contentView addSubview:self.tableView];
}

- (void)updateUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.countLabel.text = [NSString stringWithFormat:@"(%zd人)", self.userCount];
        
        if (self.tableViewEditing) {
            self.delayReload = YES;
        } else {
            [self.tableView reloadData];
        }
    });
}

#pragma mark Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.text = @"成员列表";
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#f0f1f5"];
    }
    return _titleLabel;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:12];
        _countLabel.textColor = [PLVColorUtil colorFromHexString:@"#cfd1d6"];
        _countLabel.text = [NSString stringWithFormat:@"(%zd人)", self.userCount];
    }
    return _countLabel;
}

- (UIButton *)leaveMicButton {
    if (!_leaveMicButton) {
        NSString *colorHex = @"#4399ff";
        _leaveMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _leaveMicButton.layer.borderWidth = 1;
        _leaveMicButton.layer.cornerRadius = 14;
        _leaveMicButton.layer.borderColor = [PLVColorUtil colorFromHexString:colorHex].CGColor;
        _leaveMicButton.layer.masksToBounds = YES;
        _leaveMicButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_leaveMicButton setTitle:@"全体下麦" forState:UIControlStateNormal];
        [_leaveMicButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateNormal];
        [_leaveMicButton addTarget:self action:@selector(leaveMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _leaveMicButton.hidden = ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) ? NO : YES;
    }
    return _leaveMicButton;
}

- (UIButton *)muteButton {
    if (!_muteButton) {
        NSString *colorHex = @"#4399ff";
        _muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _muteButton.layer.borderWidth = 1;
        _muteButton.layer.cornerRadius = 14;
        _muteButton.layer.borderColor = [PLVColorUtil colorFromHexString:colorHex].CGColor;
        _muteButton.layer.masksToBounds = YES;
        _muteButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_muteButton setTitle:@"全体静音" forState:UIControlStateNormal];
        [_muteButton setTitle:@"取消全体静音" forState:UIControlStateSelected];
        [_muteButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateNormal];
        [_muteButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateSelected];
        [_muteButton addTarget:self action:@selector(muteButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _muteButton.hidden = ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) ? NO : YES;
    }
    return _muteButton;
}

- (UIView *)titleLine {
    if (!_titleLine) {
        _titleLine = [[UIView alloc] init];
        _titleLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#f0f1f5" alpha:0.1];
    }
    return _titleLine;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = [PLVLSMemberCell cellHeight];
        _tableView.rowHeight = [PLVLSMemberCell cellHeight];
        _tableView.tableFooterView = [UIView new];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

#pragma mark Utils

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)leaveMicButtonAction {
    if ([self.delegate respondsToSelector:@selector(didTapCloseAllUserLinkMicInMemberSheet:changeBlock:)]) {
        [self.delegate didTapCloseAllUserLinkMicInMemberSheet:self
                                                  changeBlock:nil];
    }
}

- (void)muteButtonAction {
    if ([self.delegate respondsToSelector:@selector(didTapMuteAllUserMicInMemberSheet:mute:changeBlock:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate didTapMuteAllUserMicInMemberSheet:self
                                                    mute:!self.muteButton.selected
                                             changeBlock:^(BOOL needChange) {
            if (needChange) {
                weakSelf.muteButton.selected = !weakSelf.muteButton.selected;
            }
        }];
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVLSMemberCellDelegate

- (void)memberCell_didEditing:(BOOL)editing {
    self.tableViewEditing = editing;
    
    if (!editing && self.delayReload) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.delayReload = NO;
            [self.tableView reloadData];
        });
    }
}

- (void)memberCell_didTapBan:(BOOL)banned withUer:(PLVChatUser *)user {
    BOOL success = [[PLVChatroomManager sharedManager] sendBandMessage:banned bannedUserId:user.userId];
    if (success) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(banUsersInMemberSheet:userId:banned:)]) {
            [self.delegate banUsersInMemberSheet:self userId:user.userId banned:banned];
        }
    }
}

- (void)memberCell_didTapKickWithUer:(PLVChatUser *)user {
    BOOL success = [[PLVChatroomManager sharedManager] sendKickMessageWithUserId:user.userId];
    if (success) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(kickUsersInMemberSheet:userId:)]) {
            [self.delegate kickUsersInMemberSheet:self userId:user.userId];
        }
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.userList count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self.userList count]) {
        return [PLVLSMemberCell new];
    }
    
    static NSString *cellIdentifier = @"kMemberCellIdentifier";
    PLVLSMemberCell *cell = (PLVLSMemberCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVLSMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    PLVChatUser *user = self.userList[indexPath.row];
    [cell updateUser:user];
    
    // 第一个普通观众显示左滑动画
    if (!self.showLeftDragAnimation &&
        [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType != PLVRoomUserTypeGuest &&
        !user.specialIdentity) {
        self.showLeftDragAnimation = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [cell showLeftDragAnimation];
        });
    }
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.tableViewEditing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVLSMemberCellNotification object:nil];
    }
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.tableViewEditing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVLSMemberCellNotification object:nil];
    }
}

@end
