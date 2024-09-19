//
//  PLVLCOnlineListViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/3.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCOnlineListViewController.h"
#import "PLVLCOnlineListViewCell.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static const CGFloat kPLVLCOnlineListCellHeight = 52.0;

@interface PLVLCOnlineListViewController () <UITableViewDelegate,UITableViewDataSource>

/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *ruleButton;
@property (nonatomic, strong) UITableView *tableView;

/// 功能
@property (nonatomic, strong) NSTimer *timer;

/// 数据
@property (nonatomic, strong) NSArray <PLVChatUser *> *userList; // 增加本地用户的列表
@property (nonatomic, assign) NSTimeInterval lastUpdateTime; // 上次更新在线列表的时间
@property (nonatomic, strong) PLVChatUser *localUser;

@end

@implementation PLVLCOnlineListViewController

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userList = @[self.localUser];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.ruleButton];
    [self.view addSubview:self.tableView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat margin = 16;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat titleHeight = 20;

    CGFloat titleWidth = [self.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT,titleHeight)].width;
    self.titleLabel.frame = CGRectMake(margin, margin, titleWidth, titleHeight);
    CGFloat ruleButtonWidth = [self.ruleButton.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT,titleHeight)].width;
    self.ruleButton.frame = CGRectMake(width - margin - ruleButtonWidth, margin, ruleButtonWidth, titleHeight);
    self.tableView.frame = CGRectMake(0, kPLVLCOnlineListCellHeight, width, height - kPLVLCOnlineListCellHeight - P_SafeAreaBottomEdgeInsets());
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshUserList];
    [self startTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopTimer];
}

#pragma mark - Public

- (void)updateOnlineList:(NSArray<PLVChatUser *> *)onlineList {
    if (!self.timer) {
        return;
    }
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

#pragma mark - Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"成员信息");
        _titleLabel.textColor = PLV_UIColorFromRGBA(@"FFFFFF", 0.6);
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:14];
    }
    return _titleLabel;;
}

- (UIButton *)ruleButton {
    if (!_ruleButton) {
        _ruleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_ruleButton setTitle:PLVLocalizedString(@"规则") forState:UIControlStateNormal];
        [_ruleButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF", 0.6) forState:UIControlStateNormal];
        _ruleButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:14];
        [_ruleButton addTarget:self action:@selector(ruleButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _ruleButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = PLV_UIColorFromRGB(@"#202127");
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, CGFLOAT_MIN)];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCOnlineListViewControllerNeedUpdateOnlineList:)]) {
        [self.delegate plvLCOnlineListViewControllerNeedUpdateOnlineList:self];
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
        [self.delegate respondsToSelector:@selector(plvLCOnlineListViewControllerWannaShowRule:)]){
        [self.delegate plvLCOnlineListViewControllerWannaShowRule:self];
    }
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCOnlineListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVLCOnlineListViewCell" forIndexPath:indexPath];
    PLVChatUser *user = self.userList[indexPath.row];
    [cell updateUser:user];
    cell.backgroundColor = self.tableView.backgroundColor;
    return cell;
}

#pragma mark - UITableView Delegat

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kPLVLCOnlineListCellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 37)];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.text = PLVLocalizedString(@"最多支持查看200人");
    footerLabel.textColor = PLV_UIColorFromRGBA(@"FFFFFF", 0.4);
    footerLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:12];
    return footerLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return self.userList.count > 20 ? 37 : CGFLOAT_MIN; // 设置页脚的高度，20人以上才显示
}

@end
