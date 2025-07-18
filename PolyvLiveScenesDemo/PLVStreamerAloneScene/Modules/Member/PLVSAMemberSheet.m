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
// 通用UI组件
#import "PLVLiveSearchBar.h"
#import "PLVLiveEmptyView.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxHeightScale = 0.72;
static CGFloat kMinHeightScale = 0.60;
static CGFloat kMidWidthtScale = 0.49;

@interface PLVSAMemberSheet ()<
UITableViewDelegate,
UITableViewDataSource,
PLVSAMemberCellDelegate,
PLVLiveSearchBarDelegate
>
/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) PLVLiveSearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PLVLiveEmptyView *emptyView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

/// 数据
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList;
@property (nonatomic, assign) NSInteger userCount;
@property (nonatomic, assign) NSInteger onlineCount;
@property (nonatomic, assign) BOOL showingPopup;
@property (nonatomic, assign) BOOL startClass; // 是否开始上课
@property (nonatomic, assign) BOOL enableLinkMic; // 是否开启连麦

/// 搜索相关
@property (nonatomic, copy) NSString *currentSearchKeyword;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, strong) NSArray<PLVChatUser *> *searchResults;

@end

@implementation PLVSAMemberSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount {
    CGFloat screenHeight = MAX(PLVScreenHeight, PLVScreenWidth);
    self = [super initWithSheetHeight:kMinHeightScale * screenHeight sheetLandscapeWidth:kMidWidthtScale * screenHeight];
    if (self) {
        self.userList = userList;
        self.userCount = userCount;
        
        // 初始化搜索相关属性
        self.currentSearchKeyword = @"";
        self.isSearching = NO;
        self.searchResults = @[];
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat titleLabelLeft = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 56 : 32;

    self.headerView.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, 67);
    
    // 搜索框位置
    CGFloat searchBarY = 67;
    CGFloat searchBarHeight = 44;
    self.searchBar.frame = CGRectMake(16, searchBarY, self.contentView.bounds.size.width - 32, searchBarHeight);
    
    // 表格位置
    CGFloat tableViewY = searchBarY + searchBarHeight + 8;
    CGFloat tableViewHeight = self.contentView.bounds.size.height - tableViewY;
    self.tableView.frame = CGRectMake(0, tableViewY, self.contentView.bounds.size.width, tableViewHeight);
    
    self.titleLabel.frame = CGRectMake(titleLabelLeft, 32, self.headerView.frame.size.width - titleLabelLeft * 2, 20);
    
    // 空状态视图居中显示
    self.emptyView.frame = CGRectMake(0, tableViewY, self.contentView.bounds.size.width, tableViewHeight);
    
    // 加载指示器居中显示
    self.loadingIndicator.frame = CGRectMake((self.contentView.bounds.size.width - 20) / 2, 
                                            (self.contentView.bounds.size.height - 20) / 2, 
                                            20, 20);
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

- (void)updateSearchState:(BOOL)isSearching {
    self.isSearching = isSearching;
    [self updateUIForSearchState:isSearching];
}

- (void)updateSearchResults:(NSArray<PLVChatUser *> *)results {
    self.searchResults = results ?: @[];
    [self refreshMemberList];
}

#pragma mark - [ Override Method ]

- (void)dismiss {
    // 重置搜索状态
    [self resetSearchState];
    
    // 调用父类的dismiss方法
    [super dismiss];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.headerView];
    [self.contentView addSubview:self.searchBar];
    [self.contentView addSubview:self.tableView];
    [self.contentView addSubview:self.emptyView];
    [self.contentView addSubview:self.loadingIndicator];
    [self.headerView addSubview:self.titleLabel];
    
    // 初始隐藏空状态视图和加载指示器
    self.emptyView.hidden = YES;
    self.loadingIndicator.hidden = YES;
}

- (void)updateUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setOnlineUserCount:self.userCount];
        [self updateSheetHight];
        [self refreshMemberList];
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
        NSArray *displayMembers = [self getDisplayMembers];
        CGFloat cellHeight = [PLVSAMemberCell cellHeight];
        CGFloat screenHeight = PLVScreenHeight;
        CGFloat mSheetHeight = cellHeight * [displayMembers count] + self.headerView.bounds.size.height + self.searchBar.bounds.size.height + 8 + [PLVSAUtils sharedUtils].areaInsets.bottom;
        mSheetHeight = MAX(kMinHeightScale * screenHeight, MIN(kMaxHeightScale * screenHeight, mSheetHeight));
        self.sheetHight = mSheetHeight;
    }
}

- (void)refreshMemberList {
    [self.tableView reloadData];
    [self updateEmptyStateVisibility];
}

- (void)updateEmptyStateVisibility {
    NSArray *displayMembers = [self getDisplayMembers];
    
    if (displayMembers.count == 0 && [PLVFdUtil checkStringUseable:self.currentSearchKeyword]) {
        self.emptyView.hidden = NO;
        [self.emptyView setSearchNoResultStateWithText:PLVLocalizedString(@"未找到相关成员")];
    } else {
        self.emptyView.hidden = YES;
    }
}

- (void)updateUIForSearchState:(BOOL)isSearching {
    if (isSearching) {
        [self.loadingIndicator startAnimating];
        self.loadingIndicator.hidden = NO;
        self.emptyView.hidden = YES;
    } else {
        [self.loadingIndicator stopAnimating];
        self.loadingIndicator.hidden = YES;
        [self updateEmptyStateVisibility];
    }
}

- (NSArray<PLVChatUser *> *)getDisplayMembers {
    if ([PLVFdUtil checkStringUseable:self.currentSearchKeyword]) {
        return self.searchResults ?: @[];
    } else {
        return self.userList ?: @[];
    }
}

- (void)resetSearchState {
    // 重置搜索相关属性
    self.currentSearchKeyword = @"";
    self.isSearching = NO;
    self.searchResults = @[];
    
    // 清空搜索框
    [self.searchBar clearSearchText];
    
    // 刷新UI显示全部用户列表
    [self refreshMemberList];
    
    // 通知代理搜索已取消
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(memberSheetDidCancelSearch:)]) {
        [self.searchDelegate memberSheetDidCancelSearch:self];
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

- (PLVLiveSearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[PLVLiveSearchBar alloc] init];
        _searchBar.delegate = self;
        _searchBar.placeholder = PLVLocalizedString(@"搜索成员");
    }
    return _searchBar;
}

- (PLVLiveEmptyView *)emptyView {
    if (!_emptyView) {
        _emptyView = [[PLVLiveEmptyView alloc] init];
    }
    return _emptyView;
}

- (UIActivityIndicatorView *)loadingIndicator {
    if (!_loadingIndicator) {
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _loadingIndicator.hidesWhenStopped = YES;
    }
    return _loadingIndicator;
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
    NSArray *displayMembers = [self getDisplayMembers];
    return [displayMembers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *displayMembers = [self getDisplayMembers];
    if (indexPath.row >= [displayMembers count]) {
        return [PLVSAMemberCell new];
    }
    
    static NSString *cellIdentifier = @"PLVSAMemberCellIdentifier";
    PLVSAMemberCell *cell = (PLVSAMemberCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVSAMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    PLVChatUser *user = displayMembers[indexPath.row];
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

#pragma mark PLVLiveSearchBarDelegate

- (void)searchBar:(PLVLiveSearchBar *)searchBar didChangeSearchText:(NSString *)searchText {
    self.currentSearchKeyword = searchText;
    
    if ([PLVFdUtil checkStringUseable:searchText]) {
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(memberSheet:didStartSearchWithKeyword:)]) {
            [self.searchDelegate memberSheet:self didStartSearchWithKeyword:searchText];
        }
    } else {
        // 搜索文本为空时，清空搜索结果并显示全部用户列表
        self.searchResults = @[];
        [self refreshMemberList];
        
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(memberSheetDidCancelSearch:)]) {
            [self.searchDelegate memberSheetDidCancelSearch:self];
        }
    }
}

- (void)searchBarDidBeginEditing:(PLVLiveSearchBar *)searchBar {
    // 搜索框开始编辑
}

- (void)searchBarDidEndEditing:(PLVLiveSearchBar *)searchBar {
    // 搜索框结束编辑
}

- (void)searchBarDidTapClearButton:(PLVLiveSearchBar *)searchBar {
    // 清空搜索结果并显示全部用户列表
    self.searchResults = @[];
    [self refreshMemberList];
    
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(memberSheetDidCancelSearch:)]) {
        [self.searchDelegate memberSheetDidCancelSearch:self];
    }
}

@end
