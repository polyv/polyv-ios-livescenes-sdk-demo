//
//  PLVDownloadPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/6/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVDownloadPresenter.h"

@interface PLVDownloadPresenter ()

@end

@implementation PLVDownloadPresenter

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - [ Private Method ]

/// 配置用户Id（不同用户的下载文件将分开存放管理；不配置该值，下载模块将无法使用；重复配置该Id，将切换数据库及下载文件路径）
- (void)setupDownloadViewerId:(NSString *)viewerId {
    [[PLVDownloadPathManager shareManager] setupDownloadViewerId:viewerId];
}

#pragma mark 下载任务
- (PLVDownloadPlaybackTaskInfo *)checkAndGetPlaybackTaskInfoWithFileId:(NSString *)fileId {
    PLVDownloadPlaybackTaskInfo *taskInfo = [[PLVDownloadDatabaseManager shareManager] checkAndGetPlaybackTaskInfoWithFileId:fileId];
    return taskInfo;
}

- (void)enqueueDownloadQueueWithPlaybackPlayerModel:(PLVPlaybackVideoInfoModel *)playerModel
                                         completion:(void (^)(NSError *error))completion {
    [PLVPlaybackCacheManager enqueueDownloadQueueWithPlaybackPlayerModel:playerModel completion:completion];
}

- (NSArray *)totalPlaybackTaskInfoArray {
    return [PLVDownloadDatabaseManager shareManager].totalPlaybackTaskInfoArray;
}

- (NSArray<PLVDownloadPlaybackTaskInfo *> *)completedPlaybackTaskInfoArray {
    return [PLVDownloadDatabaseManager shareManager].completedPlaybackTaskInfoArray;
}

- (NSArray<PLVDownloadPlaybackTaskInfo *> *)unfinishedPlaybackTaskInfoArray {
    return [PLVDownloadDatabaseManager shareManager].unfinishedPlaybackTaskInfoArray;
}

#pragma mark 下载控制
- (void)startDownloadWith:(PLVDownloadTaskInfo *)taskInfo {
    [[PLVDownloadManager shareManager] startDownloadWith:taskInfo];
}

- (void)stopDownloadWith:(PLVDownloadTaskInfo *)taskInfo {
    [[PLVDownloadManager shareManager] stopDownloadWith:taskInfo];
}

- (void)deleteDownloadTaskWith:(PLVDownloadTaskInfo *)taskInfo {
    [[PLVDownloadManager shareManager] deleteDownloadTaskWith:taskInfo];
}

#pragma mark 多接收方事件
- (void)addTaskInfoArrayRefreshBlock:(PLVDownloadDatabaseTaskInfoArrayRefreshBlock)block key:(NSString *)blockKey {
    [[PLVDownloadDatabaseManager shareManager] addTaskInfoArrayRefreshBlock:block key:blockKey];
}

- (void)removeTaskInfoArrayRefreshBlockWithKey:(NSString *)blockKey {
    [[PLVDownloadDatabaseManager shareManager] removeTaskInfoArrayRefreshBlockWithKey:blockKey];
}

@end
