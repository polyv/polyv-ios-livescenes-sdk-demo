//
//  PLVLCOnlineListSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/9.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCOnlineListSheet.h"
#import "PLVLCOnlineListViewCell.h"
#import "PLVLCUtils.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static const CGFloat kPLVLCOnlineListSheetCellHeight = 52.0;

@interface PLVLCOnlineListSheet () <UITableViewDelegate,UITableViewDataSource>

// UI
@property (nonatomic, strong) UILabel *titleLabel; // 基础功能标题
@property (nonatomic, strong) UIButton *ruleButton;
@property (nonatomic, strong) UITableView *tableView;

/// 功能
@property (nonatomic, strong) NSTimer *timer;

/// 数据
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList; // 增加本地用户的列表
@property (nonatomic, assign) NSTimeInterval lastUpdateTime; // 上次更新在线列表的时间
@property (nonatomic, strong) PLVChatUser *localUser;

@end

@implementation PLVLCOnlineListSheet

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (instancetype)init {
    CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGFloat minWH = MIN([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGFloat sheetHeight = maxWH - minWH * 9 / 16 - [PLVLCUtils sharedUtils].areaInsets.top;
    CGFloat sheetLandscapeWidth = minWH;
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self setup];
        [self initUI];
    }
    return self;
}

- (void)setup {
    self.userList = @[self.localUser];
}

- (void)initUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.ruleButton];
    [self.contentView addSubview:self.tableView];
}

#pragma mark - Public

- (void)updateOnlineList:(NSArray<PLVChatUser *> *)onlineList {
    if ([PLVFdUtil checkArrayUseable:onlineList]) {
        NSMutableArray *users = [NSMutableArray array];
        for (PLVChatUser *user in onlineList) {
            [users addObject:user];
        }
        if ([PLVFdUtil checkArrayUseable:users]) {
            self.userList = [NSArray arrayWithArray:users];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat margin =  isPad ? 32 : 16;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    CGFloat titleHeight = 20;
    
    CGFloat titleWidth = [self.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT,titleHeight)].width;
    self.titleLabel.frame = CGRectMake((contentViewWidth - titleWidth) / 2, margin, titleWidth, titleHeight);
    CGFloat ruleButtonWidth = [self.ruleButton.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT,titleHeight)].width;
    self.ruleButton.frame = CGRectMake(contentViewWidth - margin - ruleButtonWidth, margin, ruleButtonWidth, titleHeight);
    self.tableView.frame = CGRectMake(0, kPLVLCOnlineListSheetCellHeight, contentViewWidth, contentViewHeight - kPLVLCOnlineListSheetCellHeight - P_SafeAreaBottomEdgeInsets());
}

- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
    
    [self refreshUserList];
    [self startTimer];
}

- (void)dismiss {
    [super dismiss];
    
    [self stopTimer];
}

- (void)deviceOrientationDidChange {
    [super deviceOrientationDidChange];
    [self dismiss];
}

#pragma mark - Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"在线成员");
        _titleLabel.textColor = PLV_UIColorFromRGBA(@"#000000", 0.8);
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:16];
    }
    return _titleLabel;;
}

- (UIButton *)ruleButton {
    if (!_ruleButton) {
        _ruleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_ruleButton setTitle:PLVLocalizedString(@"规则") forState:UIControlStateNormal];
        [_ruleButton setTitleColor:PLV_UIColorFromRGBA(@"#000000", 0.6) forState:UIControlStateNormal];
        _ruleButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:14];
        [_ruleButton addTarget:self action:@selector(ruleButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _ruleButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, CGFLOAT_MIN)];
        [_tableView registerClass:[PLVLCOnlineListViewCell class] forCellReuseIdentifier:@"PLVLCOnlineListViewCell"];
        _tableView.allowsSelection = NO; // 禁止选中
    }
    return _tableView;
}

#pragma mark - Private Method

#pragma mark 用户列表

- (PLVChatUser *)localUser {
    if (!_localUser) {
        _localUser = [[PLVChatUser alloc] init];
        PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        _localUser.userId = roomUser.viewerId;
        _localUser.userName = roomUser.viewerName;
        _localUser.avatarUrl = roomUser.viewerAvatar;
        _localUser.userType = roomUser.viewerType;
        _localUser.actor = roomUser.actor;
    }
    return _localUser;
}

- (void)refreshUserList {
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdateTime < 60) { // 1分钟内不刷新接口
        return;
    }
    
    self.lastUpdateTime = [[NSDate date] timeIntervalSince1970];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCOnlineListSheetNeedUpdateOnlineList:)]) {
        [self.delegate plvLCOnlineListSheetNeedUpdateOnlineList:self];
    }
}

#pragma mark Timer

- (void)startTimer {
    [self stopTimer]; // 防止重复启动
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                         target:self
                                                       selector:@selector(refreshUserList)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - Action

- (void)ruleButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCOnlineListSheetWannaShowRule:)]){
        [self.delegate plvLCOnlineListSheetWannaShowRule:self];
    }
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCOnlineListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVLCOnlineListViewCell" forIndexPath:indexPath];
    PLVChatUser *user = self.userList[indexPath.row];
    [cell updateUser:user isLandscape:YES];
    cell.backgroundColor = self.tableView.backgroundColor;
    return cell;
}

#pragma mark - UITableView Delegat

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kPLVLCOnlineListSheetCellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 37)];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.text = PLVLocalizedString(@"最多支持查看200人");
    footerLabel.textColor = PLV_UIColorFromRGBA(@"#000000", 0.6);
    footerLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:12];
    return footerLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return self.userList.count > 20 ? 37 : CGFLOAT_MIN; // 设置页脚的高度，20人以上才显示
}

@end
