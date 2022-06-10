//
//  PLVLCDownloadingViewController.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadingViewController.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCDownloadingCell.h"
#import "PLVLCDownloadViewModel.h"

@interface PLVLCDownloadingViewController ()<
UITableViewDataSource,
UITableViewDelegate
>

/// UI
@property (nonatomic, strong) UITableView *tableView;

/// 数据
@property (nonatomic, strong) PLVLCDownloadViewModel *viewModel;

@end

@implementation PLVLCDownloadingViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
    [self.view addSubview:self.tableView];
    
    [self setupViewModel];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)dealloc {
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
}

#pragma mark - [ Private ]

- (void)setupViewModel {
    self.viewModel = [PLVLCDownloadViewModel sharedViewModel];
    __weak typeof(self) weakSelf = self;
    [self.viewModel setRefreshDownloadingListBlock:^{
        [weakSelf.tableView reloadData];
    }];
    [self.viewModel loadDataWithType:PLVLCDownloadListDataTypeDownloading];
}

/// 点击cell中按钮
/// @param type 0： 删除 1： 下载  2：暂停
/// @param index cell的row
- (void)clickCellButtonWithType:(NSInteger)type atIndex:(NSInteger)index {
    if (type == 0) {
        [self.viewModel deleteDownloadTaskAtIndex:index withType:PLVLCDownloadListDataTypeDownloading];
    }
    else if (type == 1) {
        [self.viewModel startDownloadTaskAtIndex:index withType:PLVLCDownloadListDataTypeDownloading];
    }
    else if (type == 2) {
        [self.viewModel stopDownloadTaskAtIndex:index withType:PLVLCDownloadListDataTypeDownloading];
    }

}

#pragma mark - [ Delegate ]

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel dataCountWithType:PLVLCDownloadListDataTypeDownloading];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    PLVLCDownloadingCell *cell = (PLVLCDownloadingCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVLCDownloadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    __weak typeof(self) weakSelf = self;
    PLVDownloadPlaybackTaskInfo *model = [self.viewModel downloadModelAtIndex:indexPath.row withType:PLVLCDownloadListDataTypeDownloading];
    [cell configModel:model];
    [cell setClickButtonBlock:^(NSInteger type) {
        [weakSelf clickCellButtonWithType:type atIndex:indexPath.row];
    }];
    return cell;
}

#pragma mark - UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVDownloadPlaybackTaskInfo *model = [self.viewModel downloadModelAtIndex:indexPath.row withType:PLVLCDownloadListDataTypeDownloading];
    return [PLVLCDownloadingCell cellHeightWithModel:model.title cellWidth:CGRectGetWidth(self.tableView.frame)];
}

#pragma mark - [ Loadlazy ]

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
        _tableView.tableFooterView = [UIView new];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

@end
