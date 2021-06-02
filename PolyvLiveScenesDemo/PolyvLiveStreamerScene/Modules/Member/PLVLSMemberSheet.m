//
//  PLVLSMemberSheet.m
//  PolyvLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/29.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLSMemberSheet.h"

/// 工具
#import "PLVLSUtils.h"

/// UI
#import "PLVLSMemberCell.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVMemberPresenter.h"
#import "PLVChatUser.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVChatroomManager.h>
#import <PolyvFoundationSDK/PLVColorUtil.h>


@interface PLVLSMemberSheet ()<
PLVMemberPresenterProtocol,
PLVLSMemberCellProtocol,
UITableViewDelegate,
UITableViewDataSource
>

/// 模块
@property (nonatomic, strong) PLVMemberPresenter *presenter;

/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UIButton *leaveMicButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UIView *titleLine;
@property (nonatomic, strong) UITableView *tableView;

/// 数据
@property (nonatomic, copy) NSArray *userArray;
@property (nonatomic, assign) BOOL tableViewEditing; // 列表是否处于左滑中状态
@property (nonatomic, assign) BOOL delayReload; // 是否在左滑时遇到列表刷新通知
@property (nonatomic, assign) CGFloat sheetWidth; // 父类数据
@property (nonatomic, assign) BOOL showLeftDragAnimation; // 显示左滑动画
@end

@implementation PLVLSMemberSheet

@synthesize sheetWidth = _sheetWidth;

#pragma mark - Life Cycle

- (instancetype)init {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    self = [super initWithSheetWidth:screenWidth * 0.52];
    if (self) {
        [self.presenter start];
        
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.countLabel];
        [self.contentView addSubview:self.leaveMicButton];
        [self.contentView addSubview:self.muteButton];
        [self.contentView addSubview:self.titleLine];
        [self.contentView addSubview:self.tableView];
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

- (void)dealloc {
    [_presenter stop];
}

#pragma mark - Override
- (void)showInView:(UIView *)parentView{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.sheetWidth = screenWidth * 0.52;
    [super showInView:parentView]; /// TODO: 改造初始化该类的过程
}

#pragma mark - Getter & Setter

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

- (PLVMemberPresenter *)presenter {
    if (!_presenter) {
        _presenter = [[PLVMemberPresenter alloc] init];
        _presenter.delegate = self;
    }
    return _presenter;
}

#pragma mark - Action

- (void)leaveMicButtonAction {
    if ([self.delegate respondsToSelector:@selector(memberSheet_didTapCloseAllUserLinkMicChangeBlock:)]) {
        [self.delegate memberSheet_didTapCloseAllUserLinkMicChangeBlock:^(BOOL needChange) {
        }];
    }
}

- (void)muteButtonAction {
    if ([self.delegate respondsToSelector:@selector(memberSheet_didTapMuteAllUserMic:changeBlock:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate memberSheet_didTapMuteAllUserMic:!self.muteButton.selected changeBlock:^(BOOL needChange) {
            if (needChange) {
                weakSelf.muteButton.selected = !weakSelf.muteButton.selected;
            }
        }];
    }
}

#pragma mark - Public
- (void)refreshUserListWithLinkMicWaitUserArray:(NSArray *)linkMicWaitUserArray{
    [self.presenter refreshUserListWithLinkMicWaitUserArray:linkMicWaitUserArray];
}

- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray *)linkMicOnlineUserArray{
    [self.presenter refreshUserListWithLinkMicOnlineUserArray:linkMicOnlineUserArray];
}

#pragma mark - Private

- (void)updateMemberCount {
    self.countLabel.text = [NSString stringWithFormat:@"(%zd人)", self.presenter.userCount];
}

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

- (BOOL)isGeneralUserType:(PLVRoomUserType)userType {
    // 普通观众
    return !(userType == PLVRoomUserTypeGuest ||
            userType == PLVRoomUserTypeManager ||
            userType == PLVRoomUserTypeTeacher ||
            userType == PLVRoomUserTypeAssistant);
}

#pragma mark - PLVMemberPresenterProtocol

- (void)userListChanged {
    self.userArray = [self.presenter userList];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMemberCount];
        
        if (self.tableViewEditing) {
            self.delayReload = YES;
        } else {
            [self.tableView reloadData];
        }
    });
}

#pragma mark - PLVLSMemberCell Protocol

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
        [self.presenter banUserWithUserId:user.userId banned:banned];
    }
}

- (void)memberCell_didTapKickWithUer:(PLVChatUser *)user {
    BOOL success = [[PLVChatroomManager sharedManager] sendKickMessageWithUserId:user.userId];
    if (success) {
        [self.presenter removeUserWithUserId:user.userId];
    }
}

#pragma mark -  UITableViewDelegate & DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.userArray count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self.userArray count]) {
        return [PLVLSMemberCell new];
    }
    
    static NSString *cellIdentifier = @"kMemberCellIdentifier";
    PLVLSMemberCell *cell = (PLVLSMemberCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVLSMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    PLVChatUser *user = self.userArray[indexPath.row];
    [cell updateUser:user];
    
    // 第一个普通观众显示左滑动画
    if (!self.showLeftDragAnimation &&
        [self isGeneralUserType:user.userType]) {
        self.showLeftDragAnimation = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [cell showLeftDragAnimation];
        });
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.tableViewEditing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVLSMemberCellNotification object:nil];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.tableViewEditing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVLSMemberCellNotification object:nil];
    }
}

@end
