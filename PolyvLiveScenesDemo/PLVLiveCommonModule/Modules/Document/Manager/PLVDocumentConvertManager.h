//
//  PLVLSConvertStatusManager.h
//  PLVCloudClassStreamerSDK
//
//  Created by MissYasiky on 2020/4/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVDocumentConvertAnimateLossCacheKey;

@class PLVDocumentModel, PLVDocumentUploadModel;

@protocol PLVDocumentConvertManagerDelegate <NSObject>

/// 转码失败时调用
- (void)convertFailure:(NSArray<NSDictionary *> *)responseArray;

/// 转码成功、动态丢失时调用
- (void)convertComplete;

@end

/// 文件转码状态轮询管理类
@interface PLVDocumentConvertManager : NSObject

@property (nonatomic, weak) id<PLVDocumentConvertManagerDelegate> delegate;

/// 轮询队列
@property (nonatomic, copy, readonly) NSMutableArray <PLVDocumentUploadModel *> *convertArray;

+ (instancetype)sharedManager;

/// 启动/关闭轮询
- (void)polling:(BOOL)start;

/// 添加轮询任务
- (void)addModel:(PLVDocumentUploadModel *)model;

/// 移除轮询任务
- (void)removeModel:(PLVDocumentUploadModel *)model;

/// 清空所有轮询任务
- (void)clear;

/// 转码队列（校正）去重
/// @param normalList 文档列表接口返回的 normal 数据类型
- (void)checkupConvertArrayFromNormalList:(NSArray <PLVDocumentModel *> *)normalList;

/// 移除动态丢失本地标记
+ (void)removeAnimateLossCacheWithFileId:(NSString *)fileId;

/// 判断某个文档是否转码动态丢失
+ (BOOL)isAnimateLossFromCacheWithFileId:(NSString *)fileId;

@end

NS_ASSUME_NONNULL_END
