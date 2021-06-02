//
//  PLVLSDocumentListViewModel.h
//  PLVCloudClassStreamerModul
//  文档列表页 PLVSDocumentListViewController 的 viewModel
//
//  Created by MissYasiky on 2019/10/14.
//  Copyright © 2019 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @note 此回调在主线程触发
@protocol PLVSDocumentListProtocol <NSObject>

@optional

/// 即将加载页面数据时触发
- (void)documentListViewModel_startLoading;

/// 加载页面数据结束时触发
/// @param success YES-调用接口成功 NO-调用接口失败
/// @param error 失败错误码
- (void)documentListViewModel_finishLoading:(BOOL)success error:(NSError * _Nullable)error;

/// 删除数据数据失败时触发
- (void)documentListViewModel_deleteDataFail:(NSError *)error;

/// 数据发生变化时触发
- (void)documentListViewModel_dataUpdate;

@end

@interface PLVLSDocumentListViewModel : NSObject

/// viewModel 对 viewController 的弱引用
@property (nonatomic, weak) id<PLVSDocumentListProtocol> viewProxy;

/// 即将删除的数据下标
@property (nonatomic, assign) NSInteger deletingIndex;

/// 被选中的文档索引
@property (nonatomic, assign, readonly) NSInteger selectedIndex;

/// 被选中的文档 autoId
@property (nonatomic, assign, readonly) NSInteger selectedAutoId;

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

/// 删除下标为 deletingIndex 的数据
- (void)deleteDocumentAtDeletingIndex;

/// 获取对应文档转码失败原因
- (NSString *)errorMsgWithFileId:(NSString *)fileId;

@end

NS_ASSUME_NONNULL_END
