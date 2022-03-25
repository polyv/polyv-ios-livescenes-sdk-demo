//
//  PLVLCPlaybackListViewController.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/11/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCPlaybackListViewController.h"
#import "PLVLCPlaybackListViewCell.h"
#import "PLVLCPlaybackListEmptyView.h"
#import "PLVRoomDataManager.h"
#import <MJRefresh/MJRefresh.h>

@interface PLVLCPlaybackListViewController () <UITableViewDelegate,UITableViewDataSource,PLVRoomDataManagerProtocol>

@property (nonatomic, strong) NSArray<PLVPlaybackVideoModel *> *playbackVideos;
@property (nonatomic, strong) PLVPlaybackListModel *playbackList;
@property (nonatomic, assign) NSInteger currentPlayIndex;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation PLVLCPlaybackListViewController

#pragma mark - Life Cycle

- (instancetype)initWithPlaybackList:(PLVPlaybackListModel *)playbackList {
    self = [super init];
    if (self) {
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        _playbackList = playbackList;
        _playbackVideos = [playbackList.contents copy];
        self.view = self.tableView;//解决滑不到底部的问题
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestData];
}

#pragma mark - Getter & Setter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = PLV_UIColorFromRGB(@"#202127");
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [UIView new];
        _tableView.tableHeaderView = [UIView new];
        
        __weak typeof(self) weakSelf = self;
        MJRefreshNormalHeader *mjHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            [weakSelf requestData];
            [weakSelf.tableView.mj_header endRefreshing];
        }];
        mjHeader.lastUpdatedTimeLabel.hidden = YES;
        mjHeader.stateLabel.hidden = YES;
        [mjHeader.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        
        _tableView.mj_header = mjHeader;
        [_tableView registerClass:[PLVLCPlaybackListViewCell class] forCellReuseIdentifier:@"PLVLCPlaybackListViewCell"];
    }
    return _tableView;
}

- (PLVLCPlaybackListEmptyView *)emptyView {
    PLVLCPlaybackListEmptyView *emptyView = [[PLVLCPlaybackListEmptyView alloc] initWithFrame:self.tableView.frame];
    return emptyView;
}

#pragma mark - Private Method

- (void)requestData {
    __weak typeof(self) weakSelf = self;
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    NSString *listType = roomData.vodList ? @"vod" : @"playback";
    [PLVLiveVideoAPI requestPlaybackList:roomData.channelId listType:listType page:1 pageSize:roomData.playbackList.totalItems appId:liveConfig.appId appSecret:liveConfig.appSecret completion:^(PLVPlaybackListModel * _Nonnull playbackList, NSError * _Nonnull error) {
        weakSelf.playbackVideos =  playbackList.contents;
         weakSelf.playbackList = playbackList;
        if (!error) {
            [PLVRoomDataManager sharedManager].roomData.playbackList = playbackList;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            weakSelf.tableView.backgroundView = weakSelf.playbackVideos.count ? nil : [weakSelf emptyView];
        });
    }];
}

- (void)selectPlaybackListAtIndexPath:(NSInteger)index {
    if (![self.playbackVideos[self.currentPlayIndex].videoPoolId isEqualToString: self.playbackVideos[index].videoPoolId]) {
        self.currentPlayIndex = index;
        [PLVRoomDataManager sharedManager].roomData.videoId = self.playbackVideos[index].videoId;
        [PLVRoomDataManager sharedManager].roomData.vid = self.playbackVideos[index].videoPoolId;
    }
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = self.playbackVideos.count;
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCPlaybackListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVLCPlaybackListViewCell" forIndexPath:indexPath];
    cell.playbackVideo = self.playbackVideos[indexPath.row];
    //默认选中状态
    if ([[PLVRoomDataManager sharedManager].roomData.vid isEqualToString:self.playbackVideos[indexPath.row].videoPoolId]) {
        self.currentPlayIndex = indexPath.row;
        [PLVRoomDataManager sharedManager].roomData.videoId = self.playbackVideos[indexPath.row].videoId;
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    };
    cell.backgroundColor = self.tableView.backgroundColor;
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 92;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectPlaybackListAtIndexPath:indexPath.row];
}

#pragma mark - PLVRoomDataManagerProtocol

- (void)roomDataManager_didVidChanged:(NSString *)vid {
    for (int i = 0; i < self.playbackList.totalItems; i++) {
        if (![self.playbackVideos count]) {
            break;
        }
        if ([vid isEqualToString:self.playbackVideos[i].videoPoolId]) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
            self.currentPlayIndex = i;
            break;
        }
    }
}

@end
