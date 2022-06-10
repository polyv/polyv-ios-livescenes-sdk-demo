//
//  PLVDownloadPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/6/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVDownloadPresenter : NSObject

/// 配置用户Id（不同用户的下载文件将分开存放管理；不配置该值，下载模块将无法使用；重复配置该Id，将切换数据库及下载文件路径）
- (void)setupDownloadViewerId:(NSString *)viewerId;

#pragma mark 下载任务
/// 判断一个回放，是否已存在下载记录（不考虑下载状态）
/// @param fileId 回放视频Id，fileId
- (PLVDownloadPlaybackTaskInfo *)checkAndGetPlaybackTaskInfoWithFileId:(NSString *)fileId;

/// 添加 PLVPlaybackVideoInfoModel 至下载队列
- (void)enqueueDownloadQueueWithPlaybackPlayerModel:(PLVPlaybackVideoInfoModel *)playerModel
                                         completion:(void (^)(NSError *error))completion;
/// 所有的回放下载任务 数组
- (NSArray <PLVDownloadPlaybackTaskInfo *> *)totalPlaybackTaskInfoArray;
/// 下载完成的回放下载 数组
- (NSArray <PLVDownloadPlaybackTaskInfo *> *)completedPlaybackTaskInfoArray;
/// 下载未完成的回放下载 数组
- (NSArray <PLVDownloadPlaybackTaskInfo *> *)unfinishedPlaybackTaskInfoArray;

#pragma mark 下载控制
/// 指定一个下载任务，开始下载
- (void)startDownloadWith:(PLVDownloadTaskInfo *)taskInfo;
/// 指定一个下载任务，暂停下载
- (void)stopDownloadWith:(PLVDownloadTaskInfo *)taskInfo;
/// 删除一个下载任务（将删除对应下载文件）
- (void)deleteDownloadTaskWith:(PLVDownloadTaskInfo *)taskInfo;

#pragma mark 多接收方事件

/// 添加一个Block接收 数组更新事件
/// @param block 事件回调
/// @param blockKey 回调Key（不同调用方，以此字符串来区分注册）
- (void)addTaskInfoArrayRefreshBlock:(PLVDownloadDatabaseTaskInfoArrayRefreshBlock)block key:(NSString *)blockKey;

/// 移除一个接收方 不再接收下载完成事件
/// @param blockKey 接收方，在添加事件接收时所填Key
- (void)removeTaskInfoArrayRefreshBlockWithKey:(NSString *)blockKey;

@end

NS_ASSUME_NONNULL_END
