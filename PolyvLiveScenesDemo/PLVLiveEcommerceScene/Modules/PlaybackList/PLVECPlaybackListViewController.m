//
//  PLVECPlaybackListViewController.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECPlaybackListViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVECPlaybackListCell.h"
#import "PLVECPlaybackListView.h"
#import "PLVECUtils.h"
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>
#import <MJRefresh/MJRefresh.h>

static NSString * PLVECPlaybackListCellId = @"PLVECPlaybackListCellId";


@interface PLVECPlaybackListViewController ()
<
UIGestureRecognizerDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource,
PLVRoomDataManagerProtocol
>

@property (nonatomic, strong) PLVECPlaybackListView *playbackListView;
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout * collectionViewLayout; // 集合视图的布局
@property (nonatomic, assign, readonly) CGSize cellSize;
@property (nonatomic, strong, readonly) NSArray <PLVPlaybackVideoModel *> *dataArray;
@property (nonatomic, assign) NSInteger selectCellIndex;
@property (nonatomic, assign) NSInteger nextPageNumber;


@end

@implementation PLVECPlaybackListViewController

#pragma mark - [ Life Period ]

- (instancetype) init {
    if (self = [super init]) {
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([PLVECUtils sharedUtils].landscape) {
        self.playbackListView.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - 375, 0, 375, CGRectGetMaxY(self.view.bounds));
    } else {
        CGFloat height = 410 + P_SafeAreaBottomEdgeInsets();
        self.playbackListView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
    }
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self.view addSubview:self.playbackListView];
    
    // 添加点击关闭按钮关闭页面回调
    __weak typeof(self) weakSelf = self;
    self.playbackListView.closeButtonActionBlock = ^(PLVECBottomView * _Nonnull view) {
        [weakSelf tapAction:nil];
    };
    
    // 添加单击关闭页面手势
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    [tapGestureRecognizer addTarget:self action:@selector(tapAction:)];
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)loadDataWithPageNumber:(NSUInteger)pageNumber {
    [self loadDataWithPageNumber:pageNumber pageSize:10];
}
- (void)loadDataWithPageNumber:(NSUInteger)pageNumber pageSize:(NSUInteger)pageSize {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    __weak typeof(self) weakSelf = self;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    NSString *listType = roomData.vodList ? @"vod" : @"playback";
    [PLVLiveVideoAPI requestPlaybackList:roomData.channelId listType:listType page:pageNumber pageSize:pageSize appId:liveConfig.appId appSecret:liveConfig.appSecret completion:^(PLVPlaybackListModel * _Nonnull playbackList, NSError * _Nonnull error) {
        if (!error && playbackList) {
            if (!playbackList.firstPage) {
                NSMutableArray<PLVPlaybackVideoModel *> *tempDataArray = [weakSelf.dataArray mutableCopy];
                [tempDataArray addObjectsFromArray:playbackList.contents];
                playbackList.contents = tempDataArray;
            }
            weakSelf.playbackListView.collectionView.mj_footer.hidden = playbackList.lastPage;
            [PLVRoomDataManager sharedManager].roomData.playbackList = playbackList;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.playbackListView.collectionView reloadData];
        });
    }];
}

#pragma mark Getter

- (PLVECPlaybackListView *)playbackListView {
    if (!_playbackListView) {
        CGFloat height = 410 + P_SafeAreaBottomEdgeInsets();
        CGRect frame = CGRectMake(0, CGRectGetHeight(self.view.bounds)-height- P_SafeAreaTopEdgeInsets(),
                                              CGRectGetWidth(self.view.bounds), height);
        _playbackListView = [[PLVECPlaybackListView alloc] initWithFrame:frame];
        _playbackListView.dataSource = self;
        _playbackListView.delegate = self;
        
        __weak typeof(self) weakSelf = self;
        MJRefreshNormalHeader *mjHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            [weakSelf loadDataWithPageNumber:0 pageSize:weakSelf.nextPageNumber * 10];
            [weakSelf.playbackListView.collectionView.mj_header endRefreshing];
        }];
        mjHeader.lastUpdatedTimeLabel.hidden = YES;
        mjHeader.stateLabel.hidden = YES;
        [mjHeader.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        _playbackListView.collectionView.mj_header = mjHeader;
        
        MJRefreshAutoNormalFooter *mjFooter = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            [weakSelf loadDataWithPageNumber:weakSelf.nextPageNumber];
            [weakSelf.playbackListView.collectionView.mj_footer endRefreshing];
        }];
        mjFooter.stateLabel.hidden = YES;
        [mjFooter.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        _playbackListView.collectionView.mj_footer = mjFooter;
    }
    return _playbackListView;
}

- (UICollectionViewFlowLayout *)collectionViewLayout{
    return ((UICollectionViewFlowLayout *)_playbackListView.collectionView.collectionViewLayout);
}

- (CGSize)cellSize {
    CGSize defaultSize = CGSizeMake(164, 140);
    CGFloat collectionViewWidth = self.playbackListView.collectionView.bounds.size.width;
    
    UICollectionViewFlowLayout *cvfLayout = (UICollectionViewFlowLayout *)self.playbackListView.collectionView.collectionViewLayout;
    
    CGFloat itemWidth = (collectionViewWidth - self.playbackListView.collectionView.contentInset.left - self.playbackListView.collectionView.contentInset.right - cvfLayout.minimumInteritemSpacing) / 2;
        
    defaultSize = CGSizeMake(itemWidth, itemWidth * defaultSize.height / defaultSize.width);
    return defaultSize;
}

- (NSArray<PLVPlaybackVideoModel *> *)dataArray{
    NSArray *dataArray = [PLVRoomDataManager sharedManager].roomData.playbackList.contents;
    return dataArray;
}

- (NSInteger)nextPageNumber {
    return [PLVRoomDataManager sharedManager].roomData.playbackList.nextPageNumber;
}

#pragma mark - Action

- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - [ Delegate ]

#pragma mark UIGestureRecognizerDelegate

-(BOOL) gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    return touch.view == self.view; // 设置往期列表View不响应手势
}
#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return  self.dataArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    PLVPlaybackVideoModel * videoModel = [self.dataArray objectAtIndex:indexPath.row];
    
    PLVECPlaybackListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PLVECPlaybackListCellId forIndexPath:indexPath];
    [cell setModel:videoModel];
    if ([[PLVRoomDataManager sharedManager].roomData.vid isEqualToString:self.dataArray[indexPath.row].videoPoolId]) {
        self.selectCellIndex = indexPath.row;
        cell.selected = YES;
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    return cell;
}

#pragma mark UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.item;
    
    if (index == self.selectCellIndex) {
        return;
    }
    
    _selectCellIndex = index;
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVPlaybackVideoModel *videoModel = self.dataArray[index];
    roomData.videoId = videoModel.videoId;
    roomData.vid = videoModel.videoPoolId;
    roomData.playbackSessionId = videoModel.channelSessionId;
}

#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didVidChanged:(NSString *)vid {
    for (int i = 0; i < [self.dataArray count]; i++) {
        if ([vid isEqualToString:self.dataArray[i].videoPoolId]) {
            [self.playbackListView.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            self.selectCellIndex = i;
            break;
        }
    }
}

@end
