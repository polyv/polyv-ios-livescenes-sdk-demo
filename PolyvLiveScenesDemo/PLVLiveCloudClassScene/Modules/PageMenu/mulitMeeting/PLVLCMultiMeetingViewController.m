//
//  PLVLCMultiMeetingViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/25.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCMultiMeetingViewController.h"
#import "PLVLCMultiMeetingViewCell.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import "PLVMultiMeetingManager.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static const CGFloat kPLVLCMultiMeetingViewCellHeight = 101;

@interface PLVLCMultiMeetingViewController () <UITableViewDelegate,UITableViewDataSource>

/// UI
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *headerLabel;

/// 功能
@property (nonatomic, strong) NSTimer *timer;

/// 数据
@property (nonatomic, strong) NSArray <PLVMultiMeetingModel *> *multiMeetings;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, assign) NSInteger currentPlayIndex;
@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *mainChannelId;

@end

@implementation PLVLCMultiMeetingViewController

#pragma mark - Life Cycle

- (void)dealloc {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentPlayIndex = 0;
        _lastUpdateTime = 0;
        _multiMeetings = @[];
        self.view = self.tableView;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshMultiMeetings];
    [self startTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopTimer];
}

#pragma mark - Getter & Setter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = PLV_UIColorFromRGB(@"#202127");
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, CGFLOAT_MIN)];
        [_tableView registerClass:[PLVLCMultiMeetingViewCell class] forCellReuseIdentifier:@"PLVLCMultiMeetingViewCell"];
    }
    return _tableView;
}

- (UILabel *)headerLabel {
    if (!_headerLabel) {
        _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.view.bounds.size.width - 16, 37)];
        _headerLabel.textAlignment = NSTextAlignmentLeft;
        _headerLabel.backgroundColor = [UIColor clearColor];
        _headerLabel.text = PLVLocalizedString(@"会场直播间");
        _headerLabel.textColor = PLV_UIColorFromRGBA(@"FFFFFF", 0.8);
        _headerLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
    }
    return _headerLabel;
}

- (NSString *)mainChannelId {
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.mainChannelId;
}

- (NSString *)channelId {
    return [PLVRoomDataManager sharedManager].roomData.channelId;
}

#pragma mark - Private Methods

- (NSArray <PLVMultiMeetingModel *>*) sortedMultiMeetings:(NSArray <PLVMultiMeetingModel *>*)multiMeetings {
    if (![PLVFdUtil checkArrayUseable:multiMeetings] || multiMeetings.count <= 1) {
        return multiMeetings;
    }
    
    PLVMultiMeetingModel *firstModel = (PLVMultiMeetingModel *)[multiMeetings firstObject]; //首个元素为主会场，不参与排序
    
    NSMutableArray<PLVMultiMeetingModel *> *sortableModels = [NSMutableArray arrayWithArray:[multiMeetings subarrayWithRange:NSMakeRange(1, multiMeetings.count - 1)]];
    NSArray<NSNumber *> *statusOrder = @[
           @(PLVMultiMeetingLiveStatus_Live),
           @(PLVMultiMeetingLiveStatus_UnStart),
           @(PLVMultiMeetingLiveStatus_Waiting),
           @(PLVMultiMeetingLiveStatus_Playback),
           @(PLVMultiMeetingLiveStatus_End)
       ];
    
    [sortableModels sortUsingComparator:^NSComparisonResult(PLVMultiMeetingModel *model1, PLVMultiMeetingModel *model2) {
            NSInteger index1 = [statusOrder indexOfObject:@(model1.liveStatusType)];
            NSInteger index2 = [statusOrder indexOfObject:@(model2.liveStatusType)];
            return [@(index1) compare:@(index2)];
        }];
    
    [sortableModels insertObject:firstModel atIndex:0];
    
    return [sortableModels copy];
}

- (void)refreshMultiMeetings {
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdateTime < 60) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    if (![PLVFdUtil checkArrayUseable:self.multiMeetings]) {
        [PLVLiveVideoAPI requestMultiMeetingListWithChannelId:self.channelId mainChannelId:self.mainChannelId pageNumber:1 pageSize:61 success:^(NSDictionary * _Nonnull multiMeetingList) {
            if ([PLVFdUtil checkDictionaryUseable:multiMeetingList]) {
                NSArray *channels = PLV_SafeArraryForDictKey(multiMeetingList, @"contents");
                NSMutableArray *multiMeetingModels = [NSMutableArray array];
                for (NSDictionary *dict in channels) {
                    PLVMultiMeetingModel *model = [[PLVMultiMeetingModel alloc] initWithDictionary:dict];
                    if (model) {
                        [multiMeetingModels addObject:model];
                    }
                }
                weakSelf.multiMeetings = [multiMeetingModels copy];
                [weakSelf.tableView reloadData];
            }
        } failure:nil];
    } else {
        [PLVLiveVideoAPI requestMultiMeetingLiveStatusWithMainChannelId:self.mainChannelId success:^(NSArray * _Nonnull multiMeetingLiveStatusList) {
            if (![PLVFdUtil checkArrayUseable:multiMeetingLiveStatusList]) {
                for (NSDictionary *dict in multiMeetingLiveStatusList) {
                    for (PLVMultiMeetingModel *model in weakSelf.multiMeetings) {
                        if ([model.channelId isEqualToString:PLV_SafeStringForDictKey(dict, @"channelId")]) {
                            model.liveStatus = PLV_SafeStringForDictKey(dict, @"liveStatus");
                            model.liveStatusDesc = PLV_SafeStringForDictKey(dict, @"liveStatusDesc");
                            break;
                        }
                    }
                }
                if ([[PLVRoomDataManager sharedManager].roomData.menuInfo.multiMeetingOrderType isEqualToString:@"liveStatus"]) {
                    // 按直播状态重新排序
                    weakSelf.multiMeetings = [weakSelf sortedMultiMeetings:weakSelf.multiMeetings];
                }
                [weakSelf.tableView reloadData];
            }
        } failure:nil];
    }
    
    self.lastUpdateTime = [[NSDate date] timeIntervalSince1970];
}

#pragma mark Timer

- (void)startTimer {
    [self stopTimer]; // 防止重复启动
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(refreshMultiMeetings) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.multiMeetings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCMultiMeetingViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVLCMultiMeetingViewCell" forIndexPath:indexPath];
    PLVMultiMeetingModel *model = self.multiMeetings[indexPath.row];
    if ([model.channelId isEqualToString:self.mainChannelId]) {
        model.multiMeetingName = [NSString stringWithFormat:@"[%@] %@",PLVLocalizedString(@"主会场"), model.multiMeetingName];
    }
    cell.model = model;
    // 默认选中状态
    if ([model.channelId isEqualToString:[PLVRoomDataManager sharedManager].roomData.channelId]) {
        self.currentPlayIndex = indexPath.row;
        self.headerLabel.text = [NSString stringWithFormat:@"%@ %ld/%ld", PLVLocalizedString(@"会场直播间"), (long)(indexPath.row + 1), self.multiMeetings.count];
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    return cell;
}

#pragma mark - UITableView Delegat

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kPLVLCMultiMeetingViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.row == self.currentPlayIndex) {
        return;
    } else {
        PLVMultiMeetingModel *model = self.multiMeetings[indexPath.row];
        if (![PLVFdUtil checkStringUseable:model.channelId]) {
            return;
        }
        [[PLVMultiMeetingManager sharedManager] jumpToMultiMeeting:model.channelId isPlayback:[model.liveStatus isEqualToString:@"playback"]];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 37)];
    [headerView addSubview:self.headerLabel];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 37;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 37)];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.text = PLVLocalizedString(@"没有更多了");
    footerLabel.textColor = PLV_UIColorFromRGBA(@"FFFFFF", 0.8);
    footerLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
    return footerLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 37;
}

@end
