//
//  PLVHCDocumentListViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
// 文档列表页 PLVHCDocumentListView 的 viewModel

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCDocumentListViewModel;

/// @note 此回调在主线程触发
@protocol PLVHCDocumentListViewModelDelegate <NSObject>

@optional

/// 即将加载页面数据时触发
- (void)documentListViewModelWillStartLoading:(PLVHCDocumentListViewModel *)documentListViewModel;

/// 加载页面数据结束时触发
/// @param success YES-调用接口成功 NO-调用接口失败
/// @param error 失败错误码
- (void)documentListViewModel:(PLVHCDocumentListViewModel *)documentListViewModel didFinishLoading:(BOOL)success error:(NSError * _Nullable)error;

/// 删除数据数据失败时触发
- (void)documentListViewModel:(PLVHCDocumentListViewModel *)documentListViewModel didDeleteDataFail:(NSError *)error;

/// 数据发生变化时触发
- (void)documentListViewModelDataUpdate:(PLVHCDocumentListViewModel *)documentListViewModel;

@end

@interface PLVHCDocumentListViewModel : NSObject

/// 代理
@property (nonatomic, weak) id<PLVHCDocumentListViewModelDelegate> delegate;

/// 加载数据
- (void)loadData;

/// 页面数据总数
- (NSInteger)dataCount;

/// 返回第 index 个数据的数据模型
- (id)documetModelAtIndex:(NSInteger)index;

/// 选中下标为 index 的数据（未上传成功的文档不允许被选中）
/// @param index 选中下标
/// @return YES - 选中的文档为已上传成功的文档；NO - 索引出错或选中的为未成功上传的文档
- (BOOL)selectAtIndex:(NSInteger)index;

/// 删除文档
/// @param index 文档下标
/// @param completion 成功回调
/// @param clearConvertFailureFile 是否清除转码失败的沙盒文件(转码失败状态专用，其他状态默认删除沙盒文件) YES: 清除；NO:不清除
/// @param failure 失败回调
- (void)deleteDocumentWithIndex:(NSInteger)index clearConvertFailureFile:(BOOL)clearConvertFailureFile completion:(void (^)(void))completion failure:(void (^)(NSError *error))failure;

/// 获取对应文档转码失败原因
- (NSString *)errorMsgWithFileId:(NSString *)fileId;

@end

NS_ASSUME_NONNULL_END
