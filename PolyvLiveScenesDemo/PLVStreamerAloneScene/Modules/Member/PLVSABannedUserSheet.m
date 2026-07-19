//
//  PLVSABannedUserSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Codex on 2026/7/8.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVSABannedUserSheet.h"

// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

// 通用UI组件
#import "PLVLiveEmptyView.h"

// 模块
#import "PLVChatUser.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

typedef NS_ENUM(NSUInteger, PLVSABannedUserSheetTab) {
    PLVSABannedUserSheetTabKicked = 0,
    PLVSABannedUserSheetTabBanned
};

@interface PLVSABannedUserCell : UITableViewCell

@property (nonatomic, copy) void(^actionBlock)(PLVChatUser *user);

- (void)updateUser:(PLVChatUser *)user actionTitle:(NSString *)actionTitle;
+ (CGFloat)cellHeight;

@end

@interface PLVSABannedUserCell ()

@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UILabel *userIdLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) PLVChatUser *user;

@end

@implementation PLVSABannedUserCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self.contentView addSubview:self.nickNameLabel];
        [self.contentView addSubview:self.userIdLabel];
        [self.contentView addSubview:self.actionButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    self.actionButton.frame = CGRectMake(width - 8 - 92, 19, 92, 34);

    CGFloat textX = 8;
    CGFloat textWidth = CGRectGetMinX(self.actionButton.frame) - textX - 12;
    self.nickNameLabel.frame = CGRectMake(textX, 17, MAX(0, textWidth), 18);
    self.userIdLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.nickNameLabel.frame) + 4, MAX(0, textWidth), 16);
}

#pragma mark - Public

- (void)updateUser:(PLVChatUser *)user actionTitle:(NSString *)actionTitle {
    self.user = user;

    NSString *userId = [PLVFdUtil checkStringUseable:user.userId] ? user.userId : @"";
    self.nickNameLabel.text = [PLVFdUtil checkStringUseable:user.userName] ? user.userName : userId;
    self.userIdLabel.text = [NSString stringWithFormat:@"ID：%@", userId];
    [self.actionButton setTitle:actionTitle forState:UIControlStateNormal];
    [self setNeedsLayout];
}

+ (CGFloat)cellHeight {
    return 72.0;
}

#pragma mark - Action

- (void)actionButtonAction {
    if (self.actionBlock) {
        self.actionBlock(self.user);
    }
}

#pragma mark - Getter

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:15];
        _nickNameLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _nickNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nickNameLabel;
}

- (UILabel *)userIdLabel {
    if (!_userIdLabel) {
        _userIdLabel = [[UILabel alloc] init];
        _userIdLabel.font = [UIFont systemFontOfSize:12];
        _userIdLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6);
        _userIdLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _userIdLabel;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _actionButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _actionButton.layer.cornerRadius = 17;
        _actionButton.layer.borderWidth = 1;
        _actionButton.layer.borderColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.2).CGColor;
        _actionButton.layer.masksToBounds = YES;
        [_actionButton setTitleColor:PLV_UIColorFromRGBA(@"#F0F1F5", 0.6) forState:UIControlStateNormal];
        [_actionButton addTarget:self action:@selector(actionButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionButton;
}

@end

@interface PLVSABannedUserSheet ()<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIButton *kickedButton;
@property (nonatomic, strong) UIButton *bannedButton;
@property (nonatomic, strong) UIView *moveLine;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PLVLiveEmptyView *emptyView;
@property (nonatomic, strong) NSArray<PLVChatUser *> *kickedUserList;
@property (nonatomic, strong) NSArray<PLVChatUser *> *bannedUserList;
@property (nonatomic, strong) NSArray<PLVChatUser *> *pendingKickedUserList;
@property (nonatomic, strong) NSArray<PLVChatUser *> *pendingBannedUserList;
@property (nonatomic, strong) NSMutableSet<NSString *> *releasedUserKeys;
@property (nonatomic, assign) PLVSABannedUserSheetTab currentTab;
@property (nonatomic, assign) BOOL hasPendingUserList;

@end

@implementation PLVSABannedUserSheet

#pragma mark - Life Cycle

- (instancetype)initWithKickedUserList:(NSArray<PLVChatUser *> *)kickedUserList
                        bannedUserList:(NSArray<PLVChatUser *> *)bannedUserList {
    CGFloat screenHeight = MAX(PLVScreenHeight, PLVScreenWidth);
    CGFloat screenWidth = MIN(PLVScreenHeight, PLVScreenWidth);
    self = [super initWithSheetHeight:screenWidth sheetLandscapeWidth:0.44 * screenHeight];
    if (self) {
        self.kickedUserList = kickedUserList ?: @[];
        self.bannedUserList = bannedUserList ?: @[];
        self.currentTab = PLVSABannedUserSheetTabKicked;

        [self.contentView addSubview:self.kickedButton];
        [self.contentView addSubview:self.bannedButton];
        [self.contentView addSubview:self.moveLine];
        [self.contentView addSubview:self.hintLabel];
        [self.contentView addSubview:self.tableView];
        [self.contentView addSubview:self.emptyView];
        [self updateUI];
    }
    return self;
}

- (void)showInView:(UIView *)parentView {
    [self.releasedUserKeys removeAllObjects];
    [self applyPendingUserListIfNeeded];
    [self updateUI];
    [super showInView:parentView];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat tabWidth = 68;
    CGFloat tabGroupX = MAX(16, (contentViewWidth - tabWidth * 2) / 2.0);

    CGFloat tabY = 16;
    self.kickedButton.frame = CGRectMake(tabGroupX, tabY, tabWidth, 36);
    self.bannedButton.frame = CGRectMake(CGRectGetMaxX(self.kickedButton.frame), tabY, tabWidth, 36);

    UIButton *selectedButton = self.currentTab == PLVSABannedUserSheetTabKicked ? self.kickedButton : self.bannedButton;
    self.moveLine.frame = CGRectMake(CGRectGetMidX(selectedButton.frame) - 9, CGRectGetMaxY(self.kickedButton.frame), 18, 2);
    self.hintLabel.frame = CGRectMake(16, CGRectGetMaxY(self.moveLine.frame) + 18, MAX(0, contentViewWidth - 32), 32);

    CGFloat tableViewY = CGRectGetMaxY(self.hintLabel.frame) + 8;
    CGFloat tableViewHeight = self.contentView.bounds.size.height - tableViewY - 12;
    self.tableView.frame = CGRectMake(16, tableViewY, MAX(0, contentViewWidth - 32), tableViewHeight);
    self.emptyView.frame = CGRectMake(0, tableViewY, contentViewWidth, tableViewHeight);
}

#pragma mark - Public

- (void)updateKickedUserList:(NSArray<PLVChatUser *> *)kickedUserList
              bannedUserList:(NSArray<PLVChatUser *> *)bannedUserList {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateKickedUserList:kickedUserList bannedUserList:bannedUserList];
        });
        return;
    }

    self.pendingKickedUserList = kickedUserList ?: @[];
    self.pendingBannedUserList = bannedUserList ?: @[];
    self.hasPendingUserList = YES;
    if (self.superview) {
        return;
    }

    [self.releasedUserKeys removeAllObjects];
    [self applyPendingUserListIfNeeded];
    [self updateUI];
}

- (void)updateKickedUser:(PLVChatUser *)user released:(BOOL)released {
    [self updateUser:user released:released tab:PLVSABannedUserSheetTabKicked];
}

- (void)updateBannedUser:(PLVChatUser *)user released:(BOOL)released {
    [self updateUser:user released:released tab:PLVSABannedUserSheetTabBanned];
}

#pragma mark - Private

- (NSArray<PLVChatUser *> *)currentDisplayList {
    return self.currentTab == PLVSABannedUserSheetTabKicked ? self.kickedUserList : self.bannedUserList;
}

- (void)applyPendingUserListIfNeeded {
    if (!self.hasPendingUserList) {
        return;
    }
    self.kickedUserList = self.pendingKickedUserList ?: @[];
    self.bannedUserList = self.pendingBannedUserList ?: @[];
    self.hasPendingUserList = NO;
}

- (NSString *)releasedUserKeyForUser:(PLVChatUser *)user tab:(PLVSABannedUserSheetTab)tab {
    NSString *userId = [PLVFdUtil checkStringUseable:user.userId] ? user.userId : @"";
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    return [NSString stringWithFormat:@"%lu_%@", (unsigned long)tab, userId];
}

- (BOOL)isUserReleased:(PLVChatUser *)user tab:(PLVSABannedUserSheetTab)tab {
    NSString *userKey = [self releasedUserKeyForUser:user tab:tab];
    return [PLVFdUtil checkStringUseable:userKey] && [self.releasedUserKeys containsObject:userKey];
}

- (void)updateUser:(PLVChatUser *)user released:(BOOL)released tab:(PLVSABannedUserSheetTab)tab {
    NSString *userKey = [self releasedUserKeyForUser:user tab:tab];
    if (![PLVFdUtil checkStringUseable:userKey]) {
        return;
    }

    if (released) {
        [self.releasedUserKeys addObject:userKey];
    } else {
        [self.releasedUserKeys removeObject:userKey];
    }
    [self updatePendingUser:user released:released tab:tab];

    if (self.currentTab != tab) {
        return;
    }

    NSUInteger row = [self indexOfUser:user inList:[self currentDisplayList]];
    if (row != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (NSUInteger)indexOfUser:(PLVChatUser *)user inList:(NSArray<PLVChatUser *> *)userList {
    NSString *userId = [PLVFdUtil checkStringUseable:user.userId] ? user.userId : @"";
    if (![PLVFdUtil checkStringUseable:userId]) {
        return NSNotFound;
    }

    __block NSUInteger targetIndex = NSNotFound;
    [userList enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            targetIndex = idx;
            *stop = YES;
        }
    }];
    return targetIndex;
}

- (void)updatePendingUser:(PLVChatUser *)user released:(BOOL)released tab:(PLVSABannedUserSheetTab)tab {
    if (!self.hasPendingUserList) {
        self.pendingKickedUserList = self.kickedUserList ?: @[];
        self.pendingBannedUserList = self.bannedUserList ?: @[];
        self.hasPendingUserList = YES;
    }

    NSArray<PLVChatUser *> *sourceList = tab == PLVSABannedUserSheetTabKicked ? self.pendingKickedUserList : self.pendingBannedUserList;
    NSMutableArray<PLVChatUser *> *mutableList = [NSMutableArray arrayWithArray:sourceList ?: @[]];
    NSUInteger row = [self indexOfUser:user inList:mutableList];
    if (released) {
        if (row != NSNotFound) {
            [mutableList removeObjectAtIndex:row];
        }
    } else if (row == NSNotFound) {
        [mutableList addObject:user];
    }

    if (tab == PLVSABannedUserSheetTabKicked) {
        self.pendingKickedUserList = [mutableList copy];
    } else {
        self.pendingBannedUserList = [mutableList copy];
    }
}

- (NSString *)actionTitleForUser:(PLVChatUser *)user {
    BOOL released = [self isUserReleased:user tab:self.currentTab];
    if (self.currentTab == PLVSABannedUserSheetTabKicked) {
        return released ? PLVLocalizedString(@"踢出") : PLVLocalizedString(@"取消踢出");
    }
    return released ? PLVLocalizedString(@"禁言") : PLVLocalizedString(@"取消禁言");
}

- (void)updateUI {
    self.kickedButton.selected = self.currentTab == PLVSABannedUserSheetTabKicked;
    self.bannedButton.selected = self.currentTab == PLVSABannedUserSheetTabBanned;
    self.kickedButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:self.kickedButton.selected ? UIFontWeightSemibold : UIFontWeightRegular];
    self.bannedButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:self.bannedButton.selected ? UIFontWeightSemibold : UIFontWeightRegular];
    self.hintLabel.text = self.currentTab == PLVSABannedUserSheetTabKicked ? PLVLocalizedString(@"已被踢出的用户") : PLVLocalizedString(@"已被禁言的用户");

    NSArray *displayList = [self currentDisplayList];
    self.emptyView.hidden = displayList.count > 0;
    self.tableView.hidden = displayList.count == 0;
    NSString *emptyText = self.currentTab == PLVSABannedUserSheetTabKicked ? PLVLocalizedString(@"暂无踢出用户") : PLVLocalizedString(@"暂无禁言用户");
    [self.emptyView setEmptyStateWithIcon:[self emptyIcon] text:emptyText];

    [self.tableView reloadData];
    [self setNeedsLayout];
}

- (void)switchToTab:(PLVSABannedUserSheetTab)tab {
    if (self.currentTab == tab) {
        return;
    }
    self.currentTab = tab;
    [self.releasedUserKeys removeAllObjects];
    [self applyPendingUserListIfNeeded];
    [self updateUI];
}

- (UIImage *)emptyIcon {
    CGSize size = CGSizeMake(60, 60);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor *color = PLV_UIColorFromRGBA(@"#F0F1F5", 0.28);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextStrokeEllipseInRect(context, CGRectMake(18, 10, 24, 24));
    CGContextMoveToPoint(context, 10, 52);
    CGContextAddCurveToPoint(context, 12, 40, 48, 40, 50, 52);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, 16, 16);
    CGContextAddLineToPoint(context, 44, 44);
    CGContextStrokePath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Action

- (void)kickedButtonAction {
    [self switchToTab:PLVSABannedUserSheetTabKicked];
}

- (void)bannedButtonAction {
    [self switchToTab:PLVSABannedUserSheetTabBanned];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self currentDisplayList] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<PLVChatUser *> *displayList = [self currentDisplayList];
    if (indexPath.row >= displayList.count) {
        return [PLVSABannedUserCell new];
    }

    static NSString *cellIdentifier = @"PLVSABannedUserCell";
    PLVSABannedUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVSABannedUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    PLVChatUser *user = displayList[indexPath.row];
    NSString *actionTitle = [self actionTitleForUser:user];
    [cell updateUser:user actionTitle:actionTitle];

    __weak typeof(self) weakSelf = self;
    cell.actionBlock = ^(PLVChatUser *actionUser) {
        if (weakSelf.currentTab == PLVSABannedUserSheetTabKicked) {
            if ([weakSelf isUserReleased:actionUser tab:PLVSABannedUserSheetTabKicked] &&
                [weakSelf.delegate respondsToSelector:@selector(bannedUserSheet:kickUser:)]) {
                [weakSelf.delegate bannedUserSheet:weakSelf kickUser:actionUser];
            } else if ([weakSelf.delegate respondsToSelector:@selector(bannedUserSheet:recoverKickedUser:)]) {
                [weakSelf.delegate bannedUserSheet:weakSelf recoverKickedUser:actionUser];
            }
        } else {
            if ([weakSelf isUserReleased:actionUser tab:PLVSABannedUserSheetTabBanned] &&
                [weakSelf.delegate respondsToSelector:@selector(bannedUserSheet:banUser:)]) {
                [weakSelf.delegate bannedUserSheet:weakSelf banUser:actionUser];
            } else if ([weakSelf.delegate respondsToSelector:@selector(bannedUserSheet:cancelBanUser:)]) {
                [weakSelf.delegate bannedUserSheet:weakSelf cancelBanUser:actionUser];
            }
        }
    };

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Getter

- (UIButton *)kickedButton {
    if (!_kickedButton) {
        _kickedButton = [self tabButtonWithTitle:PLVLocalizedString(@"踢出")];
        [_kickedButton addTarget:self action:@selector(kickedButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _kickedButton;
}

- (UIButton *)bannedButton {
    if (!_bannedButton) {
        _bannedButton = [self tabButtonWithTitle:PLVLocalizedString(@"禁言")];
        [_bannedButton addTarget:self action:@selector(bannedButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bannedButton;
}

- (UIButton *)tabButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF", 0.6) forState:UIControlStateNormal];
    [button setTitleColor:PLV_UIColorFromRGB(@"#FFFFFF") forState:UIControlStateSelected];
    return button;
}

- (UILabel *)hintLabel {
    if (!_hintLabel) {
        _hintLabel = [[UILabel alloc] init];
        _hintLabel.font = [UIFont systemFontOfSize:12];
        _hintLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6);
    }
    return _hintLabel;
}

- (UIView *)moveLine {
    if (!_moveLine) {
        _moveLine = [[UIView alloc] init];
        _moveLine.backgroundColor = PLV_UIColorFromRGB(@"#3F76FF");
    }
    return _moveLine;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = [PLVSABannedUserCell cellHeight];
        _tableView.rowHeight = [PLVSABannedUserCell cellHeight];
        _tableView.tableFooterView = [UIView new];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (PLVLiveEmptyView *)emptyView {
    if (!_emptyView) {
        _emptyView = [[PLVLiveEmptyView alloc] init];
        _emptyView.iconSize = 60;
        _emptyView.iconTextSpacing = 16;
        _emptyView.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.4);
        _emptyView.textFont = [UIFont systemFontOfSize:14];
        _emptyView.hidden = YES;
    }
    return _emptyView;
}

- (NSMutableSet<NSString *> *)releasedUserKeys {
    if (!_releasedUserKeys) {
        _releasedUserKeys = [NSMutableSet set];
    }
    return _releasedUserKeys;
}

@end
