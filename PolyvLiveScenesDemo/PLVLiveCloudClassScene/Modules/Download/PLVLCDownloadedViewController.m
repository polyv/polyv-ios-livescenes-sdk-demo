//
//  PLVLCDownloadedViewController.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadedViewController.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVLCDownloadedCell.h"
#import "PLVLCDownloadViewModel.h"

@interface PLVLCDownloadedViewController ()<
UITableViewDataSource,
UITableViewDelegate
>

/// UI
@property (nonatomic, strong) UITableView *tableView;

/// 数据
@property (nonatomic, strong) PLVLCDownloadViewModel *viewModel;

@end

@implementation PLVLCDownloadedViewController

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
    [self.viewModel setRefreshDownloadedListBlock:^{
        [weakSelf.tableView reloadData];
    }];
    [self.viewModel loadDataWithType:PLVLCDownloadListDataTypeDownloaded];
}

#pragma mark - [ Delegate ]

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel dataCountWithType:PLVLCDownloadListDataTypeDownloaded];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    PLVLCDownloadedCell *cell = (PLVLCDownloadedCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PLVLCDownloadedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    __weak typeof(self) weakSelf = self;
    PLVDownloadPlaybackTaskInfo *model = [self.viewModel downloadModelAtIndex:indexPath.row withType:PLVLCDownloadListDataTypeDownloaded];
    [cell configModel:model];
    [cell setClickDeleteButtonBlock:^{
        [weakSelf.viewModel deleteDownloadTaskAtIndex:indexPath.row withType:PLVLCDownloadListDataTypeDownloaded];
    }];
    return cell;
}

#pragma mark - UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVDownloadPlaybackTaskInfo *model = [self.viewModel downloadModelAtIndex:indexPath.row withType:PLVLCDownloadListDataTypeDownloaded];
    return [PLVLCDownloadedCell cellHeightWithModel:model.title cellWidth:CGRectGetWidth(self.tableView.frame)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel selectDownloadListAtIndex:indexPath.row withType:PLVLCDownloadListDataTypeDownloaded];
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
