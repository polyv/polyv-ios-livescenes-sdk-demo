//
//  PLVCastDeviceViewController.m
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCastDeviceViewController.h"
#import "PLVCastCoreManager.h"
#import "PLVNetworkDetactor.h"
#import "PLVCastDeviceCell.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import "PLVMultiLanguageManager.h"

@interface PLVCastDeviceViewController ()<
UITableViewDelegate,
UITableViewDataSource,
PLVCastDeviceSearchDelegate
>

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *seperator;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIImageView *animateImageView;

@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIButton *retryButton;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray <PLVCastServiceModel *>*devices;
@property (nonatomic, assign, getter=isSearching) BOOL searching;

@property (nonatomic, strong) UIImageView *bottomImageView;
@property (nonatomic, strong) PLVNetworkDetactor *networkDetactor; // 网络检测实例对象

@end

@implementation PLVCastDeviceViewController

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.networkDetactor = [[PLVNetworkDetactor alloc] init];
        [self startObserverNetwork];
    }
    return self;
}

- (void)dealloc {
    [self stopObserverNetwork];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [PLVCastCoreManager sharedManager].deviceDelegate = self;
    [[PLVCastCoreManager sharedManager] startSearchService];
}
     
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [[PLVCastCoreManager sharedManager] stopSearchService];
    [PLVCastCoreManager sharedManager].deviceDelegate = nil;
}

- (void)viewWillLayoutSubviews {
    [self updateUI];
}

#pragma mark - Initialize

- (void)createUI {
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomImageView];
    [self.view addSubview:self.centerView];
    [self.view addSubview:self.tableView];

    [self.topView addSubview:self.seperator];
    [self.topView addSubview:self.backButton];
    [self.topView addSubview:self.titleLabel];
    [self.topView addSubview:self.tipsLabel];
    [self.topView addSubview:self.refreshButton];
    [self.topView addSubview:self.animateImageView];

    [self.centerView addSubview:self.emptyImageView];
    [self.centerView addSubview:self.emptyLabel];
    [self.centerView addSubview:self.retryButton];
}

- (void)updateUI {
    CGFloat topPadding = 0.0;
    if (PLV_iOSVERSION_Available_11_0) {
        topPadding = self.view.safeAreaInsets.top;
    }
    self.topView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 81.5 + topPadding);

    self.seperator.frame = CGRectMake(0, CGRectGetHeight(self.topView.frame) - 1.5, CGRectGetWidth(self.view.frame), 1.5);

    self.backButton.frame = CGRectMake(2.5, topPadding, 44, 44);

    self.titleLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - 50) / 2, CGRectGetMidY(self.backButton.frame) - 8, 50, 16);

    self.tipsLabel.frame = CGRectMake(15, CGRectGetHeight(self.topView.frame) - 14 - 9, 200, 14);

    self.refreshButton.frame = CGRectMake(CGRectGetWidth(self.topView.frame) - 25.5 - 30, CGRectGetHeight(self.topView.frame) - 30 - 6, 30, 30);

    self.animateImageView.frame = self.refreshButton.frame;

    self.bottomImageView.frame = CGRectMake(0, CGRectGetHeight(self.view.frame) - 104.5, 125, 104.5);

    self.centerView.frame = CGRectMake(CGRectGetMidX(self.view.frame) - 250 / 2, CGRectGetMidY(self.view.frame) - 228 / 2, 250, 228);

    self.emptyImageView.frame = CGRectMake((CGRectGetWidth(self.centerView.frame) - 250) / 2, 0, 250, 133);

    self.emptyLabel.frame = CGRectMake(0, 153.5, CGRectGetWidth(self.centerView.frame), 18);

    self.retryButton.frame = CGRectMake((CGRectGetWidth(self.centerView.frame) - 160) / 2, CGRectGetHeight(self.centerView.frame) - 40, 160, 40);

    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.topView.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.topView.frame));
}

#pragma mark - Getter & Setter

- (void)setSearching:(BOOL)searching {
    _searching = searching;
    if (_searching) {
        self.tipsLabel.text = PLVLocalizedString(@"正在搜索可投屏设备...");
        self.centerView.hidden = YES;
        self.tableView.hidden = NO;
        [self.animateImageView startAnimating];
    } else {
        self.tipsLabel.text = (self.devices.count != 0) ? PLVLocalizedString(@"已找到以下设备") : PLVLocalizedString(@"未发现可投屏设备");
        self.centerView.hidden = (self.devices.count != 0);
        self.tableView.hidden = !self.centerView.hidden;
        [self.animateImageView stopAnimating];
    }
}

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [UIColor whiteColor];
    }
    return _topView;
}

- (UIView *)seperator {
    if (!_seperator) {
        _seperator = [[UIView alloc] init];
        _seperator.backgroundColor = [PLVColorUtil colorFromHexString:@"#e5e5e5"];
    }
    return _seperator;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_blue_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = PLVLocalizedString(@"投电视");
    }
    return _titleLabel;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.font = [UIFont systemFontOfSize:13];
        _tipsLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _tipsLabel.text = PLVLocalizedString(@"未发现可投屏设备");
    }
    return _tipsLabel;
}

- (UIButton *)refreshButton {
    if (!_refreshButton) {
        _refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_refreshButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_refresh"] forState:UIControlStateNormal];
        [_refreshButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_refresh"] forState:UIControlStateHighlighted];
        [_refreshButton addTarget:self action:@selector(refreshButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _refreshButton;
}

- (UIImageView *)animateImageView {
    if (!_animateImageView) {
        NSMutableArray *muArray = [[NSMutableArray alloc] init];
        for (int i = 1; i <= 36; i++) {
            NSString *imageName = [NSString stringWithFormat:@"refresh_gif/plv_cast_refreshing-%d", i];
            UIImage *image = [PLVLCUtils imageForCastResource:imageName];
            [muArray addObject:image];
        }
        
        _animateImageView = [[UIImageView alloc] init];
        _animateImageView.animationImages = [muArray copy];
        _animateImageView.animationDuration = 1.5f;
        _animateImageView.animationRepeatCount = 0;
    }
    return _animateImageView;
}

- (UIImageView *)bottomImageView {
    if (!_bottomImageView) {
        _bottomImageView = [[UIImageView alloc] init];
        _bottomImageView.image = [PLVLCUtils imageForCastResource:@"plv_cast_device_bg"];
    }
    return _bottomImageView;
}

- (UIView *)centerView {
    if (!_centerView) {
        _centerView = [[UIView alloc] init];
    }
    return _centerView;
}

- (UIImageView *)emptyImageView {
    if (!_emptyImageView) {
        _emptyImageView = [[UIImageView alloc] init];
        _emptyImageView.image = [PLVLCUtils imageForCastResource:@"plv_cast_empty_bg"];
    }
    return _emptyImageView;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.font = [UIFont systemFontOfSize:16];
        _emptyLabel.textColor = [UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:0.66];
        _emptyLabel.text = PLVLocalizedString(@"未发现到可投屏设备，请重试...");
    }
    return _emptyLabel;
}

- (UIButton *)retryButton {
    if (!_retryButton) {
        _retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _retryButton.layer.cornerRadius = 40/2.0;
        [_retryButton setTitle:PLVLocalizedString(@"重试") forState:UIControlStateNormal];
        [_retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _retryButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#56ACE9"];
        _retryButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_retryButton addTarget:self action:@selector(retryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _retryButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGFloat topHeight = 128.5;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight, screenSize.width, screenSize.height - topHeight) style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [UIView new];
        _tableView.rowHeight = [PLVCastDeviceCell cellHeight];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

#pragma mark - Action

- (void)backButtonAction:(id)sender {
    if (self.navigationController){
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)refreshButtonAction:(id)sender {
    if (self.isSearching) {
        return;
    }
    [[PLVCastCoreManager sharedManager] startSearchService];
}

- (void)retryButtonAction:(id)sender {
    if (self.isSearching) {
        return;
    }
    [[PLVCastCoreManager sharedManager] startSearchService];
}

#pragma mark - Notification

- (void)startObserverNetwork {
    [self.networkDetactor startListenNetworkChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkStatusChanged:)
                                                 name:PLVWifiChangedNotification
                                               object:nil];
}

- (void)stopObserverNetwork {
    [self.networkDetactor stopListenNetworkChanged];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)networkStatusChanged:(NSNotification *)notif {
    BOOL isWifi = [self.networkDetactor isWIFIReachable];
    if (isWifi) { // WiFi 可用
        [[PLVCastCoreManager sharedManager] startSearchService];
    } else { // WiFi 不可用
        [[PLVCastCoreManager sharedManager] stopSearchService];
        
        self.centerView.hidden = NO;
        self.devices = @[];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableView Delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.devices count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [PLVCastDeviceCell cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    PLVCastDeviceCell *cell = (PLVCastDeviceCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVCastDeviceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    PLVCastServiceModel *model = self.devices[indexPath.row];
    [cell setDevice:model.deviceName connected:model.isConnecting];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PLVCastServiceModel *model = self.devices[indexPath.row];
    if (self.selectConnectDeviceHandler) {
        self.selectConnectDeviceHandler(model.deviceName);
    }
    if (self.navigationController){
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - PLVCastDeviceSearch Delegate

// 设备搜索发现设备回调
- (void)castManagerFindServices:(NSArray <PLVCastServiceModel *>*)servicesArray {
    self.emptyLabel.text = PLVLocalizedString(@"未发现到可投屏设备，请重试...");
    [self.retryButton setTitle:PLVLocalizedString(@"重试") forState:UIControlStateNormal];
    self.centerView.hidden = (servicesArray.count != 0);
    self.devices = [servicesArray copy];
    [self.tableView reloadData];
}

// 设备搜索状态变更回调
- (void)castManagerSearchStateChanged:(BOOL)start {
    self.searching = start;
}

@end
