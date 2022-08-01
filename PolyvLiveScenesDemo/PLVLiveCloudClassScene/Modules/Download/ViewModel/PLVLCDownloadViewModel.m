//
//  PLVLCDownloadViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/31.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadViewModel.h"
#import "PLVLCCloudClassViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVRoomLoginClient.h"

@interface PLVLCDownloadViewModel ()

/// 成员common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong) PLVDownloadPresenter *presenter;

@property (nonatomic, copy) NSMutableArray <PLVDownloadPlaybackTaskInfo *> *downloadingArray;
@property (nonatomic, copy) NSMutableArray <PLVDownloadPlaybackTaskInfo *> *downloadedArray;

@property (nonatomic, assign) BOOL pushingWatchViewController; // 是否正在跳转观看页
@property (nonatomic, copy) NSString *viewerId;
@property (nonatomic, copy) NSString *viewerName;
@property (nonatomic, copy) NSString *viewerAvatar;

@end

@implementation PLVLCDownloadViewModel

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        _downloadingArray = [NSMutableArray array];
        _downloadedArray = [NSMutableArray array];
    }
    return self;
}

#pragma mark - [ Public Method ]

/// 单例方法
+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVLCDownloadViewModel *viewModel;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (void)setup {
    // 初始化成员模块
    self.presenter = [[PLVDownloadPresenter alloc] init];
}

- (void)setupDownloadViewerId:(NSString *)viewerId {
    [self.presenter setupDownloadViewerId:viewerId];
}

- (void)clear {
    self.presenter = nil;
}

- (void)loadDataWithType:(PLVLCDownloadListDataType)listDataType {
    if (listDataType == PLVLCDownloadListDataTypeDownloading) {
        self.downloadingArray = [NSMutableArray arrayWithArray:[self.presenter unfinishedPlaybackTaskInfoArray]];
        
        if (self.refreshDownloadingListBlock) {
            self.refreshDownloadingListBlock();
        }
    }else {
        self.downloadedArray = [NSMutableArray arrayWithArray:[self.presenter completedPlaybackTaskInfoArray]];
        
        if (self.refreshDownloadedListBlock) {
            self.refreshDownloadedListBlock();
        }
    }
}

- (NSInteger)dataCountWithType:(PLVLCDownloadListDataType)listDataType {
    return listDataType == PLVLCDownloadListDataTypeDownloading ? self.downloadingArray.count : self.downloadedArray.count;
}

- (PLVDownloadPlaybackTaskInfo *)downloadModelAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType {
    if (index < 0 || index >= [self dataCountWithType:listDataType]) {
        return nil;
    }
    if (listDataType == PLVLCDownloadListDataTypeDownloading) {
        return self.downloadingArray[index];
    }else {
        return self.downloadedArray[index];
    }
}

/// 点击下载列表第 index 个数据
- (void)selectDownloadListAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType {
    if (listDataType == PLVLCDownloadListDataTypeDownloaded &&
        !self.pushingWatchViewController) {
        self.pushingWatchViewController = YES;
        // 保存原来的用户信息
        self.viewerId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
        self.viewerName = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerName;
        self.viewerAvatar = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerAvatar;
        
        // 先执行释放观看页逻辑
        if (self.exitViewControllerFromDownlaodListBlock) {
            self.exitViewControllerFromDownlaodListBlock();
        }
        
        if (self.viewProxy.navigationController &&
            [self.viewProxy.navigationController.viewControllers count] != 1) {
            //push方式的处理，kill掉观看页
            NSMutableArray *vcArray = [NSMutableArray arrayWithArray:self.viewProxy.navigationController.viewControllers];
            [vcArray removeObjectAtIndex:vcArray.count - 2];
            self.viewProxy.navigationController.viewControllers = (NSArray *)vcArray;
        }
        
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 然后执行从登录页进入新的观看页
            PLVDownloadPlaybackTaskInfo *taskInfo = [weakSelf downloadModelAtIndex:index withType:listDataType];

            if ([taskInfo.listType isEqualToString:@"record"]) {
                // 观看指定暂存视频
                [weakSelf loginRequestWithOfflineVid:@"" orRecordFileId:taskInfo.fileId channelId:taskInfo.channelId];
            }else {
                // 观看指定回放视频
                [weakSelf loginRequestWithOfflineVid:taskInfo.vid orRecordFileId:@"" channelId:taskInfo.channelId];
            }
        });
    }
}

- (void)startDownloadTaskAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType {
    PLVDownloadPlaybackTaskInfo *model = [self downloadModelAtIndex:index withType:listDataType];
    [self.presenter startDownloadWith:model];
}

- (void)stopDownloadTaskAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType {
    PLVDownloadPlaybackTaskInfo *model = [self downloadModelAtIndex:index withType:listDataType];
    [self.presenter stopDownloadWith:model];
}

- (void)deleteDownloadTaskAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType {
    PLVDownloadPlaybackTaskInfo *model = [self downloadModelAtIndex:index withType:listDataType];
    NSString *title = [NSString stringWithFormat:@"确认删除%@？", model.title];
    __weak typeof(self) weakSelf = self;
    [PLVFdUtil showAlertWithTitle:title message:nil viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:@"取消" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:@"确认" confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
        [weakSelf.presenter deleteDownloadTaskWith:model];
        [weakSelf loadDataWithType:listDataType];
        
        if (weakSelf.refreshWatchPlayerAfterDeleteTaskInfoBlock) {
            weakSelf.refreshWatchPlayerAfterDeleteTaskInfoBlock(model.fileId);
        }
    }];
}

- (void)setUpDownloadTaskInfoArrayRefreshObserver:(NSString *)observer {
    __weak typeof(self) weakSelf = self;
    [self.presenter addTaskInfoArrayRefreshBlock:^(PLVDownloadDatabaseManager * _Nonnull manager, PLVDownloadDatabaseTaskInfoArrayType arrayType) {
        if (arrayType == PLVDownloadDatabaseTaskInfoArray_UnfinishedPlayback) {
            [weakSelf loadDataWithType:PLVLCDownloadListDataTypeDownloading];
        }else if (arrayType == PLVDownloadDatabaseTaskInfoArray_CompletedPlayback) {
            [weakSelf loadDataWithType:PLVLCDownloadListDataTypeDownloaded];
        }
    } key:observer];
}

- (void)removeDownloadTaskInfoArrayRefreshObserver:(NSString *)observer {
    [self.presenter removeTaskInfoArrayRefreshBlockWithKey:observer];
}

/// 判断一个回放，是否已存在下载记录（不考虑下载状态）
/// @param fileId 回放视频Id，fileId
- (PLVDownloadPlaybackTaskInfo *)checkAndGetPlaybackTaskInfoWithFileId:(NSString *)fileId {
    return [self.presenter checkAndGetPlaybackTaskInfoWithFileId:fileId];
}

/// 添加 PLVPlaybackVideoInfoModel 至下载队列
- (void)enqueueDownloadQueueWithPlaybackPlayerModel:(PLVPlaybackVideoInfoModel *)playerModel
                                         completion:(void (^)(NSError *error))completion {
    [self.presenter enqueueDownloadQueueWithPlaybackPlayerModel:playerModel completion:completion];
}

- (void)startDownloadWith:(PLVDownloadTaskInfo *)taskInfo {
    [self.presenter startDownloadWith:taskInfo];
}

#pragma mark - [ Private Method ]

#pragma mark 登录进入云课堂观看页
/// 从离线缓存列表进入登录
/// @param vid 观看指定回放视频(同时指定优先观看vid)
/// @param recordFileId 观看指定暂存视频
- (void)loginRequestWithOfflineVid:(NSString *)vid orRecordFileId:(NSString *)recordFileId channelId:(NSString * _Nullable)channelId {
    __weak typeof(self) weakSelf = self;
    void(^successBlock)(void) = ^() { // 登录成功页面跳转回调
        PLVLCCloudClassViewController * cloudClassVC = [[PLVLCCloudClassViewController alloc] init];

        if (weakSelf.viewProxy.navigationController &&
            [weakSelf.viewProxy.navigationController.viewControllers count] != 1) {
            //push方式的处理，新观看页push进来
            [weakSelf.viewProxy.navigationController pushViewController:cloudClassVC animated:YES];
            
            //push方式的处理，kill掉下载列表页
            NSMutableArray *vcArray = [NSMutableArray arrayWithArray:cloudClassVC.navigationController.viewControllers];
            [vcArray removeObjectAtIndex:vcArray.count - 2];
            cloudClassVC.navigationController.viewControllers = (NSArray *)vcArray;
            
            weakSelf.pushingWatchViewController = NO;
            
        }else {
            // model方式的处理，连续dismiss 掉下载页、观看页，然后present新的观看页
            
            UIViewController *ingvc = self.viewProxy.navigationController.presentingViewController;
            [self.viewProxy.navigationController dismissViewControllerAnimated:NO completion:^{
                [ingvc dismissViewControllerAnimated:NO completion:^{
                    UIViewController *loginVC2 = [PLVFdUtil getCurrentViewController];
                    cloudClassVC.modalPresentationStyle = UIModalPresentationFullScreen;
                    [loginVC2 presentViewController:cloudClassVC animated:NO completion:^{
                        weakSelf.pushingWatchViewController = NO;
                    }];
                }];
            }];
        }
    };
    
    [self loginOfflineCloudClassPlaybackRoomWithChannelType:PLVChannelTypePPT | PLVChannelTypeAlone channelId:channelId vid:vid recordFileId:recordFileId successHandler:successBlock];
}

/// 云课堂场景-离线缓存直播回放
/// @param channelType 频道类型
/// @param vid 观看指定回放视频(同时指定优先观看vid)
/// @param fileId 观看指定暂存视频
- (void)loginOfflineCloudClassPlaybackRoomWithChannelType:(PLVChannelType)channelType
                                                channelId:(NSString * _Nullable)channelId
                                                      vid:(NSString * _Nullable)vid
                                             recordFileId:(NSString * _Nullable)fileId
                                           successHandler:(void (^)(void))successHandler {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self) weakSelf = self;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    [PLVRoomLoginClient loginOfflinePlaybackRoomWithChannelType:channelType
                                                      channelId:channelId
                                                        vodList:NO
                                                            vid:vid
                                                   recordFileId:fileId
                                                         userId:liveConfig.userId
                                                          appId:liveConfig.appId
                                                      appSecret:liveConfig.appSecret
                                                       roomUser:^(PLVRoomUser * _Nonnull roomUser) {
        // 用回原来的用户信息
        roomUser.viewerId = self.viewerId;
        roomUser.viewerName = self.viewerName;
        roomUser.viewerAvatar = self.viewerAvatar;
    } completion:^(PLVViewLogCustomParam * _Nonnull customParam) {
        [hud hideAnimated:YES];
        if (successHandler) {
            successHandler();
        }
    } failure:^(NSString * _Nonnull errorMessage) {
        [hud hideAnimated:YES];
        weakSelf.pushingWatchViewController = NO;
    }];
}

@end
