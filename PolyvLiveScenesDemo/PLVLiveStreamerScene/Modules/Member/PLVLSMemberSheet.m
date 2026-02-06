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
#import "PLVMultiLanguageManager.h"

/// UI
#import "PLVLSMemberCell.h"
#import "PLVLSSipView.h"
// 通用UI组件
#import "PLVLiveSearchBar.h"
#import "PLVLiveEmptyView.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVChatUser.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static const CGFloat kSearchBarHeight = 36.0;
static const CGFloat kSearchBarMargin = 16.0;

@interface PLVLSMemberSheet ()<
PLVLSMemberCellDelegate,
PLVLSSipViewDelegate,
UITableViewDelegate,
UITableViewDataSource,
PLVLiveSearchBarDelegate
>

/// UI
@property (nonatomic, strong) UIButton *memberButton;
@property (nonatomic, strong) UIButton *leaveMicButton;
@property (nonatomic, strong) UIButton *linkMicSettingButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UIView *titleLine;
@property (nonatomic, strong) PLVLiveSearchBar *searchBar;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PLVLiveEmptyView *emptyView;
@property (nonatomic, strong) PLVLSSipView *sipView;
@property (nonatomic, strong) UIButton *sipMemberButton;
@property (nonatomic, strong) UIView *moveLine;
@property (nonatomic, strong) UIView *sipMemberButtonRedDot;

/// 数据
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList;
@property (nonatomic, strong) NSArray <PLVChatUser *> *searchResults;
@property (nonatomic, assign) NSInteger userCount;
@property (nonatomic, assign) NSInteger onlineCount;
@property (nonatomic, assign) BOOL tableViewEditing; // 列表是否处于左滑中状态
@property (nonatomic, assign) BOOL delayReload; // 是否在左滑时遇到列表刷新通知
@property (nonatomic, assign) BOOL showLeftDragAnimation; // 显示左滑动画
@property (nonatomic, assign) BOOL isRealMainSpeaker; // 本地用户是否是主讲
@property (nonatomic, assign) BOOL startClass; // 是否开始上课
@property (nonatomic, assign) BOOL enableLinkMic; // 是否开启连麦
@property (nonatomic, assign) BOOL isSearching; // 是否正在搜索
@property (nonatomic, copy) NSString *currentSearchText; // 当前搜索文本
@property (nonatomic, assign) BOOL isRealFirstScreen;

@end

@implementation PLVLSMemberSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat scale = isPad ? 0.43 : 0.52;
    self = [super initWithSheetWidth:screenWidth * scale];
    if (self) {
        self.userList = userList;
        self.userCount = userCount;
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat titleLabelTop = 14;
    CGFloat countLabelTop = 17;
    CGFloat buttonTop = 11;
    CGFloat titleLineTop = 44;
    CGFloat buttonMargin = 4;

    if (isPad) {
        titleLabelTop += PLVLSUtils.safeTopPad;
        countLabelTop += PLVLSUtils.safeTopPad;
        buttonTop += PLVLSUtils.safeTopPad;
        titleLineTop += PLVLSUtils.safeTopPad;
        buttonMargin = 12;
    }
    
    CGFloat memberButtonWidth = [self.memberButton sizeThatFits:CGSizeMake(MAXFLOAT, 22)].width + 2;
    self.memberButton.frame = CGRectMake(16, titleLabelTop, memberButtonWidth, 22);
    
    CGFloat buttonWidth = 88.0;
    if (self.bounds.size.width <= 667) {  // iphone小屏适配
        buttonWidth = 66.0 - (self.bounds.size.width/667);
    }
    // 安全侧边距兜底：若取值过小（如部分刘海屏横屏返回 0/极小），强制使用 44pt
    CGFloat safeSidePad = PLVLSUtils.safeSidePad;
    if (safeSidePad <= 16) {
        safeSidePad = 44;
    }
    
    CGFloat buttonOriginX = self.sheetWidth - safeSidePad - buttonWidth * 2 - buttonMargin;
    if ([PLVRoomDataManager sharedManager].roomData.linkmicNewStrategyEnabled &&  [PLVRoomDataManager sharedManager].roomData.interactNumLimit > 0) {
        buttonOriginX = buttonOriginX - buttonWidth - buttonMargin;
    }
    
    self.leaveMicButton.frame = CGRectMake(buttonOriginX, buttonTop, buttonWidth, 28);
    self.muteButton.frame = CGRectMake(buttonOriginX + buttonWidth + buttonMargin, buttonTop, buttonWidth, 28);
    self.linkMicSettingButton.frame = CGRectMake(buttonOriginX + buttonWidth * 2 + buttonMargin * 2, buttonTop, buttonWidth, 28);
    self.titleLine.frame = CGRectMake(16, titleLineTop, self.sheetWidth - 16 - safeSidePad, 1);
    
    // 搜索容器视图
    CGFloat searchContainerY = CGRectGetMaxY(self.titleLine.frame);
    CGFloat searchContainerHeight = kSearchBarHeight + kSearchBarMargin * 2;
    self.searchContainerView.frame = CGRectMake(16, searchContainerY, CGRectGetWidth(self.titleLine.frame), searchContainerHeight);
    
    // 搜索框
    self.searchBar.frame = CGRectMake(0, kSearchBarMargin, CGRectGetWidth(self.searchContainerView.frame), kSearchBarHeight);
    
    // 表格视图
    CGFloat tableViewOriginY = searchContainerY + searchContainerHeight;
    self.tableView.frame = CGRectMake(16, tableViewOriginY, CGRectGetWidth(self.titleLine.frame), self.bounds.size.height - tableViewOriginY);
    self.sipView.frame = CGRectMake(0, CGRectGetMinY(self.tableView.frame), CGRectGetWidth(self.tableView.frame) + 16, CGRectGetHeight(self.tableView.frame));
    
    // 空状态视图居中显示
    self.emptyView.frame = CGRectMake(0, tableViewOriginY, self.contentView.bounds.size.width, self.bounds.size.height - tableViewOriginY);
        
    self.sipMemberButton.frame = CGRectMake(CGRectGetMaxX(self.memberButton.frame) + 24, CGRectGetMinY(self.memberButton.frame), 85, 22);
    self.sipMemberButtonRedDot.frame = CGRectMake(CGRectGetWidth(self.sipMemberButton.frame) - 2 - 6, 4, 6, 6);
    if (self.sipView.hidden || ![PLVRoomDataManager sharedManager].roomData.sipEnabled) {
        self.moveLine.frame = CGRectMake(CGRectGetMinX(self.titleLine.frame) + 16, titleLineTop - 2, 32, 2);
    } else {
        self.moveLine.frame = CGRectMake(CGRectGetMidX(self.sipMemberButton.frame) - 16, titleLineTop - 2, 32, 2);
    }
}

#pragma mark - [ Public Method ]

- (void)updateUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount onlineCount:(NSInteger)onlineCount {
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

- (void)updateLocalUserSpeakerAuth:(BOOL)auth {
    self.isRealMainSpeaker = auth;
    [self.tableView reloadData];
}

- (void)enableAudioVideoLinkMic:(BOOL)enable {
    self.enableLinkMic = enable;
    [self.tableView reloadData];
}

- (void)showNewIncomingTelegramView {
    [self.sipView showNewIncomingTelegramView];
}

- (void)setSearching:(BOOL)isSearching {
    _isSearching = isSearching;
    [self updateUI];
}

- (void)updateSearchResults:(NSArray<PLVChatUser *> *)searchResults {
    self.searchResults = searchResults;
    [self.tableView reloadData];
}

#pragma mark - [ Override Method ]

- (void)dismiss {
    // 重置搜索状态
    [self resetSearchState];
    
    // 调用父类的dismiss方法
    [super dismiss];
}

#pragma mark - [ Private Method ]

- (void)resetSearchState {
    self.isSearching = NO;
    self.searchResults = nil;
    self.currentSearchText = @"";
    [self.searchBar clearSearchText];
    
    // 调用取消搜索代理方法
    if ([self.delegate respondsToSelector:@selector(memberSheetDidCancelSearch:)]) {
        [self.delegate memberSheetDidCancelSearch:self];
    }
    
    [self updateUI];
}

- (void)setupUI {
    [self.contentView addSubview:self.memberButton];
    [self.contentView addSubview:self.leaveMicButton];
    if ([PLVRoomDataManager sharedManager].roomData.linkmicNewStrategyEnabled && [PLVRoomDataManager sharedManager].roomData.interactNumLimit > 0) {
        [self.contentView addSubview:self.linkMicSettingButton];
    }
    [self.contentView addSubview:self.muteButton];
    [self.contentView addSubview:self.titleLine];
    [self.contentView addSubview:self.searchContainerView];
    [self.contentView addSubview:self.tableView];
    if ([PLVRoomDataManager sharedManager].roomData.sipEnabled) {
        [self.contentView addSubview:self.sipView];
        [self.contentView addSubview:self.sipMemberButton];
        [self.sipMemberButton addSubview:self.sipMemberButtonRedDot];
    }
    [self.contentView addSubview:self.moveLine];
    [self.searchContainerView addSubview:self.searchBar];
    [self.contentView addSubview:self.emptyView];
}

- (void)updateUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *text = [NSString stringWithFormat:PLVLocalizedString(@"成员(%zd)"), self.userCount];
        [self memberButtonSetAttributedTitleWithTextString:text];
        CGFloat memberButtonWidth = [self.memberButton sizeThatFits:CGSizeMake(MAXFLOAT, 22)].width + 2;
        self.memberButton.frame = CGRectMake(16, self.memberButton.frame.origin.y, memberButtonWidth, 22);
        self.sipMemberButton.frame = CGRectMake(CGRectGetMaxX(self.memberButton.frame) + 24, CGRectGetMinY(self.memberButton.frame), 85, 22);

        if (self.tableViewEditing) {
            self.delayReload = YES;
        } else {
            [self.tableView reloadData];
        }
        
        // 更新空状态视图显示
        [self updateEmptyStateVisibility];
    });
}

- (void)updateEmptyStateVisibility {
    NSArray *displayMembers = [self currentDisplayList];
    
    if (displayMembers.count == 0 && [PLVFdUtil checkStringUseable:self.currentSearchText]) {
        [self.emptyView setSearchNoResultStateWithText:PLVLocalizedString(@"未找到相关成员")];
        self.emptyView.hidden = NO;
        self.tableView.hidden = YES;
    } else {
        self.emptyView.hidden = YES;
        self.tableView.hidden = NO;
    }
}

- (NSArray<PLVChatUser *> *)currentDisplayList {
    // 根据搜索文本是否存在来判断显示哪个列表
    if ([PLVFdUtil checkStringUseable:self.currentSearchText]) {
        return self.searchResults ?: @[];
    } else {
        return self.userList;
    }
}

#pragma mark Getter & Setter

- (UIView *)searchContainerView {
    if (!_searchContainerView) {
        _searchContainerView = [[UIView alloc] init];
        _searchContainerView.backgroundColor = [UIColor clearColor];
    }
    return _searchContainerView;
}

- (PLVLiveSearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[PLVLiveSearchBar alloc] initWithFrame:CGRectZero];
        _searchBar.delegate = self;
        _searchBar.placeholder = PLVLocalizedString(@"搜索成员");
    }
    return _searchBar;
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
        NSString *normalTitle = PLVLocalizedString(@"观众下麦");
        normalTitle = [normalTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        [_leaveMicButton setTitle:normalTitle forState:UIControlStateNormal];
        [_leaveMicButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateNormal];
        [_leaveMicButton addTarget:self action:@selector(leaveMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _leaveMicButton.hidden = ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) ? NO : YES;
        _leaveMicButton.enabled = NO;
    }
    return _leaveMicButton;
}

- (void)moveLineMoveHorizontallyToX:(CGFloat)x {
    __weak typeof(self) weakSelf = self;
    CGPoint point = self.moveLine.frame.origin;
    CGSize size = self.moveLine.frame.size;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        weakSelf.moveLine.frame = CGRectMake(x, point.y, size.width, size.height);
    } completion:^(BOOL finished) {
    }];
}

- (void)memberButtonSetAttributedTitleWithTextString:(NSString *)text {
    UIColor *titleColor = PLV_UIColorFromRGB(@"#f0f1f5");
    UIColor *countColor = PLV_UIColorFromRGB(@"#cfd1d6");
    NSDictionary *titleAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:16],
                                          NSForegroundColorAttributeName:titleColor};
    NSDictionary *countAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                          NSForegroundColorAttributeName:countColor};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttributes:titleAttributes range:NSMakeRange(0, text.length)];
    [attributedString addAttributes:countAttributes range:NSMakeRange(2, text.length - 2)];
    [_memberButton setAttributedTitle:attributedString forState:UIControlStateNormal];
}

#pragma mark Getter & Setter

- (UIButton *)memberButton {
    if (!_memberButton) {
        _memberButton = [[UIButton alloc] init];
        [_memberButton addTarget:self action:@selector(memberButtonAction) forControlEvents:UIControlEventTouchUpInside];
        NSString *text = [NSString stringWithFormat:PLVLocalizedString(@"成员(%zd)"), self.userCount];
        [self memberButtonSetAttributedTitleWithTextString:text];
    }
    return _memberButton;
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
        [_muteButton setTitle:PLVLocalizedString(@"全员静音") forState:UIControlStateNormal];
        [_muteButton setTitle:PLVLocalizedString(@"取消全员静音") forState:UIControlStateSelected];
        [_muteButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateNormal];
        [_muteButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateSelected];
        [_muteButton addTarget:self action:@selector(muteButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _muteButton.hidden = ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) ? NO : YES;
    }
    return _muteButton;
}

- (UIButton *)linkMicSettingButton {
    if (!_linkMicSettingButton) {
        NSString *colorHex = @"#4399ff";
        _linkMicSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _linkMicSettingButton.layer.borderWidth = 1;
        _linkMicSettingButton.layer.cornerRadius = 14;
        _linkMicSettingButton.layer.borderColor = [PLVColorUtil colorFromHexString:colorHex].CGColor;
        _linkMicSettingButton.layer.masksToBounds = YES;
        _linkMicSettingButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_linkMicSettingButton setTitle:PLVLocalizedString(@"连麦设置") forState:UIControlStateNormal];
        [_linkMicSettingButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateNormal];
        [_linkMicSettingButton setTitleColor:[PLVColorUtil colorFromHexString:colorHex] forState:UIControlStateSelected];
        [_linkMicSettingButton addTarget:self action:@selector(linkMicSettingButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _linkMicSettingButton.hidden = ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) ? NO : YES;
    }
    return _linkMicSettingButton;
}


- (UIButton *)sipMemberButton {
    if (!_sipMemberButton) {
        _sipMemberButton = [[UIButton alloc] init];
        _sipMemberButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_sipMemberButton setTitle:PLVLocalizedString(@"电话连麦") forState:UIControlStateNormal];
        [_sipMemberButton setTitleColor:PLV_UIColorFromRGB(@"#CFD1D6") forState:UIControlStateNormal];
        [_sipMemberButton addTarget:self action:@selector(sipButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sipMemberButton;
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

- (PLVLiveEmptyView *)emptyView {
    if (!_emptyView) {
        _emptyView = [[PLVLiveEmptyView alloc] init];
        _emptyView.hidden = YES;
    }
    return _emptyView;
}

- (PLVLSSipView *)sipView {
    if (!_sipView) {
        _sipView = [[PLVLSSipView alloc] init];
        _sipView.hidden = YES;
        _sipView.delegate = self;
    }
    return _sipView;
}

- (UIView *)moveLine {
    if (!_moveLine) {
        _moveLine = [[UIView alloc] init];
        _moveLine.backgroundColor = PLV_UIColorFromRGB(@"#F0F1F5");
    }
    return _moveLine;
}

- (UIView *)sipMemberButtonRedDot {
    if (!_sipMemberButtonRedDot) {
        _sipMemberButtonRedDot = [[UIView alloc] init];
        _sipMemberButtonRedDot.backgroundColor = PLV_UIColorFromRGB(@"#FF6363");
        _sipMemberButtonRedDot.layer.masksToBounds = YES;
        _sipMemberButtonRedDot.layer.cornerRadius = 3;
        _sipMemberButtonRedDot.hidden = YES;
    }
    return _sipMemberButtonRedDot;
}

- (void)setRemoveAllAudiencesButtonEnable:(BOOL)removeAllAudiencesButtonEnable {
    _removeAllAudiencesButtonEnable = removeAllAudiencesButtonEnable;
    if (removeAllAudiencesButtonEnable != self.leaveMicButton.enabled) {
        self.leaveMicButton.enabled = removeAllAudiencesButtonEnable;
    }
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

- (void)linkMicSettingButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapLinkMicSettingInMemberSheet:)]) {
        [self.delegate didTapLinkMicSettingInMemberSheet:self];
    }
}

- (void)memberButtonAction {
    if (self.memberButton.selected) {
//        return;
    }
    
    self.memberButton.selected = !self.sipMemberButton.selected;
    self.tableView.hidden = NO;
    self.sipView.hidden = YES;
    CGFloat x = CGRectGetMidX(self.memberButton.frame) - CGRectGetWidth(self.moveLine.frame) / 2;
    [self moveLineMoveHorizontallyToX:x];
}

- (void)sipButtonAction {
    if (self.sipMemberButton) {
//        return;
    }
    
    self.sipMemberButton.selected = !self.memberButton.selected;
    self.sipMemberButtonRedDot.hidden = YES;
    self.tableView.hidden = YES;
    self.sipView.hidden = NO;
    CGFloat x = CGRectGetMidX(self.sipMemberButton.frame) - CGRectGetWidth(self.moveLine.frame) / 2;
    [self moveLineMoveHorizontallyToX:x];
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

- (void)memberCell_didTapBan:(BOOL)banned withUser:(PLVChatUser *)user {
    BOOL success = [[PLVChatroomManager sharedManager] sendBandMessage:banned bannedUserId:user.userId];
    if (success) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(banUsersInMemberSheet:userId:banned:)]) {
            [self.delegate banUsersInMemberSheet:self userId:user.userId banned:banned];
        }
    }
}

- (void)memberCell_didTapKickWithUser:(PLVChatUser *)user {
    BOOL success = [[PLVChatroomManager sharedManager] sendKickMessageWithUserId:user.userId];
    if (success) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(kickUsersInMemberSheet:userId:)]) {
            [self.delegate kickUsersInMemberSheet:self userId:user.userId];
        }
    }
}

- (void)memberCell_inviteUserJoinLinkMic:(PLVChatUser *)user {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inviteUserJoinLinkMicInMemberSheet:chatUser:)]) {
        [self.delegate inviteUserJoinLinkMicInMemberSheet:self chatUser:user];
    }
}

- (BOOL)allowLinkMicInCell:(PLVLSMemberCell *)cell {
    NSInteger maxLinkMicCount = [PLVRoomDataManager sharedManager].roomData.interactNumLimit;
    BOOL allowLinkmic = self.onlineCount <= maxLinkMicCount;
    return allowLinkmic;
}

- (BOOL)localUserIsRealMainSpeakerInCell:(PLVLSMemberCell *)cell {
    return self.isRealMainSpeaker;
}

- (BOOL)localUserIsRealFirstSiteInCell:(PLVLSMemberCell *)cell {
    return self.isRealFirstScreen;
}
    
#pragma mark PLVLSSipViewDelegate

- (void)newCallingInSipView:(PLVLSSipView *)sipView{
    if (self.sipView.hidden) {
        self.sipMemberButtonRedDot.hidden = NO;
    }
    if (!self.superview) {
        if (self.delegate  && [self.delegate respondsToSelector:@selector(sipUserListDidChangedInMemberSheet:)]) {
            [self.delegate sipUserListDidChangedInMemberSheet:self];
        }
    }
}

- (BOOL)startClassInCell:(PLVLSMemberCell *)cell {
    return self.startClass;
}

- (BOOL)enableAudioVideoLinkMicInCell:(PLVLSMemberCell *)cell {
    return self.enableLinkMic;
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self currentDisplayList] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *displayList = [self currentDisplayList];
    if (indexPath.row >= [displayList count]) {
        return [PLVLSMemberCell new];
    }
    
    static NSString *cellIdentifier = @"kMemberCellIdentifier";
    PLVLSMemberCell *cell = (PLVLSMemberCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVLSMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    PLVChatUser *user = displayList[indexPath.row];
    [cell updateUser:user];
    BOOL isLoginUser = [self isLoginUser:user.userId];
    if (isLoginUser && !self.mediaGranted) {
        [cell closeLinkmicAndCamera];
    }
    
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

#pragma mark PLVLiveSearchBarDelegate

- (void)searchBar:(PLVLiveSearchBar *)searchBar didChangeSearchText:(NSString *)searchText {
    self.currentSearchText = searchText;
    // 根据搜索文本是否存在来设置搜索状态
    self.isSearching = [PLVFdUtil checkStringUseable:searchText];
    
    if ([self.delegate respondsToSelector:@selector(memberSheet:didChangeSearchText:)]) {
        [self.delegate memberSheet:self didChangeSearchText:searchText];
    }
    
    [self updateUI];
}

- (void)searchBarDidBeginEditing:(PLVLiveSearchBar *)searchBar {
    // 搜索框开始编辑时的处理
}

- (void)searchBarDidEndEditing:(PLVLiveSearchBar *)searchBar {
    // 搜索框结束编辑时的处理
    // 如果搜索文本为空，则取消搜索
    if (![PLVFdUtil checkStringUseable:self.currentSearchText]) {
        if ([self.delegate respondsToSelector:@selector(memberSheetDidCancelSearch:)]) {
            [self.delegate memberSheetDidCancelSearch:self];
        }
    }
}

- (void)searchBarDidTapClearButton:(PLVLiveSearchBar *)searchBar {
    self.currentSearchText = @"";
    self.isSearching = NO;
    self.searchResults = nil;
    
    // 调用取消搜索代理方法
    if ([self.delegate respondsToSelector:@selector(memberSheetDidCancelSearch:)]) {
        [self.delegate memberSheetDidCancelSearch:self];
    }
    
    [self updateUI];
}

@end
