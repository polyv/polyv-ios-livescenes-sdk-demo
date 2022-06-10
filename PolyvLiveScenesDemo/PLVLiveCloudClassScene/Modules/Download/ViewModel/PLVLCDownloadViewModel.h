//
//  PLVLCDownloadViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/31.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVDownloadPlaybackTaskInfo.h>
#import "PLVLCDownloadListViewController.h"
#import "PLVDownloadPresenter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVLCDownloadListDataType) {
    PLVLCDownloadListDataTypeDownloading = 0,   //!< 下载中的数据
    PLVLCDownloadListDataTypeDownloaded         //!< 已下载的数据
};

@interface PLVLCDownloadViewModel : NSObject

#pragma mark - [ 属性 ]

@property (nonatomic, weak) PLVLCDownloadListViewController *viewProxy;

/// 刷新下载中列表的block
@property (nonatomic, copy) void (^refreshDownloadingListBlock)(void);

/// 刷新已下载列表的block
@property (nonatomic, copy) void (^refreshDownloadedListBlock)(void);

/// 从离线缓存列表退出释放block所在的控制器
@property (nonatomic, copy) void (^exitViewControllerFromDownlaodListBlock)(void);

/// 从离线缓存列表 删除暂存视频的下载任务后，更新信息到播放器
@property (nonatomic, copy) void (^refreshWatchPlayerAfterDeleteTaskInfoBlock)(NSString *deleteFileId);

#pragma mark - [ 方法 ]

/// 单例方法
+ (instancetype)sharedViewModel;

/// 创建成员模块presenter
- (void)setup;

/// 配置用户Id（不同用户的下载文件将分开存放管理；不配置该值，下载模块将无法使用；重复配置该Id，将切换数据库及下载文件路径）
- (void)setupDownloadViewerId:(NSString *)viewerId;

- (void)clear;

#pragma mark 列表方法
/// 加载数据
- (void)loadDataWithType:(PLVLCDownloadListDataType)listDataType;

/// 页面数据总数
- (NSInteger)dataCountWithType:(PLVLCDownloadListDataType)listDataType;

/// 返回第 index 个数据的数据模型
- (PLVDownloadPlaybackTaskInfo *)downloadModelAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType;

/// 点击下载列表第 index 个数据
- (void)selectDownloadListAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType;

/// 开启列表中第 index 个数据的下载
- (void)startDownloadTaskAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType;

/// 停止列表中第 index 个数据的下载
- (void)stopDownloadTaskAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType;

/// 删除列表中第 index 个下载任务数据
- (void)deleteDownloadTaskAtIndex:(NSInteger)index withType:(PLVLCDownloadListDataType)listDataType;

#pragma mark 观察方法
/// 设置下载任务数组变化的观察者
/// @param observer 观察者名字
- (void)setUpDownloadTaskInfoArrayRefreshObserver:(NSString *)observer;

/// 移除下载任务数组变化的观察者
/// @param observer 观察者名字
- (void)removeDownloadTaskInfoArrayRefreshObserver:(NSString *)observer;

#pragma mark 下载任务操作方法
/// 判断一个回放，是否已存在下载记录（不考虑下载状态）
/// @param fileId 回放视频Id，fileId
- (PLVDownloadPlaybackTaskInfo *)checkAndGetPlaybackTaskInfoWithFileId:(NSString *)fileId;

/// 添加 PLVPlaybackVideoInfoModel 至下载队列（添加完后会自动开始下载）
- (void)enqueueDownloadQueueWithPlaybackPlayerModel:(PLVPlaybackVideoInfoModel *)playerModel
                                         completion:(void (^)(NSError *error))completion;

/// 开始下载一个下载任务
/// @param taskInfo 下载任务
- (void)startDownloadWith:(PLVDownloadTaskInfo *)taskInfo;

@end

NS_ASSUME_NONNULL_END
