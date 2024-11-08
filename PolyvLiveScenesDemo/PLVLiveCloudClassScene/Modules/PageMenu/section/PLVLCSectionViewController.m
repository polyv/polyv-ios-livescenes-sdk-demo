//
//  PLVLCSectionViewController.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/6.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCSectionViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVLCSectionViewCell.h"

@interface PLVLCSectionViewController ()<
UITableViewDelegate,
UITableViewDataSource,
PLVRoomDataManagerProtocol
>

@property (nonatomic, strong) NSArray<PLVLivePlaybackSectionModel *> *sections;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) NSInteger currentPlayIndex;

@end

@implementation PLVLCSectionViewController

#pragma mark - Life Cycle

- (void)dealloc {
    [self stopTimer];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self requestData];
        self.view = self.tableView;
        self.currentTime = 0;
        self.currentPlayIndex = 0;
        [self starTimer];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Getter & Setter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = PLV_UIColorFromRGB(@"#141518");
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = PLV_UIColorFromRGB(@"#000000");
        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.tableFooterView = [UIView new];
        _tableView.tableHeaderView = [UIView new];
        
        [_tableView registerClass:[PLVLCSectionViewCell class] forCellReuseIdentifier:@"PLVLCSectionViewCell"];
    }
    return _tableView;
}

#pragma mark - Private Method

- (void)requestData {
    __weak typeof(self) weakSelf = self;
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    if ((roomData.recordEnable || roomData.menuInfo.materialLibraryEnabled) && [PLVFdUtil checkStringUseable:roomData.playbackVideoInfo.fileId]) {
        [PLVLiveVideoAPI requestLiveRecordSectionListWithChannelId:roomData.channelId fileId:roomData.playbackVideoInfo.fileId appId:liveConfig.appId appSecret:liveConfig.appSecret completion:^(NSArray<PLVLivePlaybackSectionModel *> * _Nonnull sectionList, NSError * _Nullable error) {
            if (!error) {
                weakSelf.sections = [sectionList copy];
                [PLVRoomDataManager sharedManager].roomData.sectionList = sectionList;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }];
    } else if ([PLVFdUtil checkStringUseable:roomData.playbackVideoInfo.videoId]) {
        [PLVLiveVideoAPI requestLivePlaybackSectionListWithChannelId:roomData.channelId videoId:roomData.playbackVideoInfo.videoId appId:liveConfig.appId appSecret:liveConfig.appSecret completion:^(NSArray * _Nonnull sectionList, NSError * _Nonnull error) {
            if (!error) {
                weakSelf.sections = [sectionList copy];
                [PLVRoomDataManager sharedManager].roomData.sectionList = sectionList;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }];
    }
}

- (void)starTimer {
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(getPlayerCurrentTime) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)getPlayerCurrentTime {
    if (self.delegate && [self.delegate respondsToSelector:(@selector(plvLCSectionViewGetPlayerCurrentTime:))]) {
        self.currentTime = [self.delegate plvLCSectionViewGetPlayerCurrentTime:self];
    }

    NSInteger nextIndex = self.currentPlayIndex + 1;
    // 当为最后一个章节且时间大于最后一个章节的起始时间，则返回
    if (nextIndex == [self.sections count] && self.currentTime > self.sections[self.currentPlayIndex].timeStamp) {
        return;
    }
    
    // 不为最后一个章节时，遍历章节数据，得到当前时间所在章节
    for (int i = 0; i < [self.sections count]; i++) {
        nextIndex = i;
        if (i == [self.sections count] - 1) {
            break;
        }
        if ((self.currentTime >= self.sections[i].timeStamp && self.currentTime < self.sections[i+1].timeStamp)) {
            break;
        }
    }
    if (nextIndex != self.currentPlayIndex) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:nextIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.currentPlayIndex = nextIndex;
    }
}

- (void)selectSectionAtIndexPath:(NSInteger)index {
    if (index == self.currentPlayIndex) {
        return;
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCSectionView:seekTime:)]) {
            [self.delegate plvLCSectionView:self seekTime:self.sections[index].timeStamp];
        }
    }
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.sections) {
        return 0;
    }
    return [self.sections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.sections.count <= indexPath.row) { // 数据保护
        return [PLVLCSectionViewCell new];
    }
    
    PLVLCSectionViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVLCSectionViewCell" forIndexPath:indexPath];
    cell.section = self.sections[indexPath.row];
    cell.backgroundColor = self.tableView.backgroundColor;
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectSectionAtIndexPath:indexPath.row];
}

#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didVidChanged:(NSString *)vid {
    [self requestData];
}

@end
