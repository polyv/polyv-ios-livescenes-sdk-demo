//
//  PLVHCDocumentListViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCDocumentListViewModel.h"

// 工具
#import "PLVHCUtils.h"

// 模块
#import "PLVDocumentModel.h"
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVModel/PLVModel.h>

typedef NS_ENUM(NSInteger, PLVHCDocumentDataType) {
    PLVHCDocumentDataTypeUnUpload = 0,
    PLVHCDocumentDataTypeUnConvert,
    PLVHCDocumentDataTypeNormal
};

@interface PLVHCDocumentListViewModel () <
PLVDocumentUploadResultDelegate,
PLVDocumentConvertManagerDelegate
>

@property (nonatomic, copy) NSMutableDictionary <NSString *, NSString *> *errorMsgDict;

@property (nonatomic, copy) NSMutableArray <PLVDocumentUploadModel *> *unUploadArray;

@property (nonatomic, copy) NSMutableArray <PLVDocumentUploadModel *> *unConvertArray;

@property (nonatomic, copy) NSMutableArray <PLVDocumentModel *> *normalArray;

@end

@implementation PLVHCDocumentListViewModel


#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        _errorMsgDict = [[NSMutableDictionary alloc] init];
        _unUploadArray = [[NSMutableArray alloc] init];
        _unConvertArray = [[NSMutableArray alloc] init];
        _normalArray = [[NSMutableArray alloc] init];
        
        [PLVDocumentUploadClient sharedClient].resultDelegate = self;
        [PLVDocumentConvertManager sharedManager].delegate = self;
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)loadData {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentListViewModelWillStartLoading:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentListViewModelWillStartLoading:self];
        })
    }
    
    [self updateUploadData];
    [self updateUnConvertArray];
    
    __weak typeof(self) weakSelf = self;
    [self updateNormalArrayWithCompletion:^(NSArray<NSDictionary *> *responseArray, NSError *error) {
        [[PLVDocumentConvertManager sharedManager] checkupConvertArrayFromNormalList:weakSelf.normalArray];
        [weakSelf dataUpdateNotify];
        
        BOOL success = (responseArray && !error);
        if (weakSelf.delegate &&
            [weakSelf.delegate respondsToSelector:@selector(documentListViewModel:didFinishLoading:error:)]) {
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate documentListViewModel:self didFinishLoading:success error:error];
            })
        }
        
    }];
}

- (NSInteger)dataCount {
    NSInteger count = [self.unUploadArray count] + [self.unConvertArray count] + [self.normalArray count];
    return count;
}

- (id)documetModelAtIndex:(NSInteger)index {
    NSInteger realIndex = index - 1;
    if (realIndex < 0 || realIndex >= [self dataCount]) {
        return nil;
    }
    
    PLVHCDocumentDataType dataType = [self dataTyeWithRealIndex:realIndex];
    NSInteger arrayIndex = [self getArrayIndexWithDataType:dataType realIndex:realIndex];
    if (dataType == PLVHCDocumentDataTypeUnUpload) {
        PLVDocumentUploadModel *model = self.unUploadArray[arrayIndex];
        return model;
    } else if (dataType == PLVHCDocumentDataTypeUnConvert) {
        PLVDocumentUploadModel *model = self.unConvertArray[arrayIndex];
        return model;
    } else if (dataType == PLVHCDocumentDataTypeNormal && arrayIndex != -1) {
        PLVDocumentModel *model = self.normalArray[arrayIndex];
        return model;
    }
    return nil;
}

- (BOOL)selectEnableAtIndex:(NSInteger)index {
    if (index <= 0) {
        return NO;
    }
    NSInteger realIndex = index - 1;
    PLVHCDocumentDataType dataType = [self dataTyeWithRealIndex:realIndex];
    return dataType == PLVHCDocumentDataTypeNormal;
}

- (BOOL)selectAtIndex:(NSInteger)index {
    NSInteger realIndex = index - 1;
    if (realIndex < 0 || realIndex >= [self dataCount]) {
        return NO;
    }
    
    id model = [self documetModelAtIndex:index];
    if (model && [model isKindOfClass:[PLVDocumentModel class]]) {
        return YES;
    }
    
    return NO;
}

- (void)deleteDocumentWithIndex:(NSInteger)index clearConvertFailureFile:(BOOL)clearConvertFailureFile completion:(void (^)(void))completion failure:(void (^)(NSError * _Nonnull))failure {
    NSInteger deletingIndex = index;

    if (deletingIndex <= 0 ||
        deletingIndex > [self dataCount]) {
        return;
    }
    
    NSInteger realDeletingIndex = deletingIndex - 1;
    PLVHCDocumentDataType dataType = [self dataTyeWithRealIndex:realDeletingIndex];
    NSInteger arrayIndex = [self getArrayIndexWithDataType:dataType realIndex:realDeletingIndex];
    
    if (dataType == PLVHCDocumentDataTypeUnUpload) {
        PLVDocumentUploadModel *model = self.unUploadArray[arrayIndex];
        [[PLVDocumentUploadClient sharedClient] removeUploadWithFileId:model.fileId];
        
        [self.unUploadArray removeObject:model];
        [self deleteModelSuccess:YES error:nil];
    } else if(dataType == PLVHCDocumentDataTypeUnConvert ||
              dataType == PLVHCDocumentDataTypeNormal) {
        static BOOL loading;
        if (loading) {
            return;
        }
        loading = YES;

        realDeletingIndex -= [self.unUploadArray count] + [self.unConvertArray count];
        NSString *fileId = nil;
        NSString *fileName = nil;
        if (dataType == PLVHCDocumentDataTypeUnConvert) {
            PLVDocumentUploadModel *model = self.unConvertArray[arrayIndex];
            fileId = model.fileId;
            fileName = model.fileName;
        } else {
            PLVDocumentModel *model = self.normalArray[arrayIndex];
            fileId = model.fileId;
            fileName = model.fileName;
        }
        
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        NSString *channelId = roomData.channelId;

        __weak typeof(self) weakSelf = self;
        [PLVLiveVideoAPI deleteDocumentWithChannelId:channelId fileId:fileId completion:^{
            if (dataType == PLVHCDocumentDataTypeUnConvert) {
                PLVDocumentUploadModel *model = weakSelf.unConvertArray[arrayIndex];
                [[PLVDocumentConvertManager sharedManager] removeModel:model];
               
                // 转码失败的文档，有可能需要重新上传，需要保留沙盒文件
                if (clearConvertFailureFile ||
                    model.status != PLVDocumentUploadStatusConvertFailure) {
                    [[PLVDocumentUploadClient sharedClient] deleteFileWithFileName:model.fileName];
                }
                [weakSelf.unConvertArray removeObject:model];
            } else {
                PLVDocumentModel *model = self.normalArray[arrayIndex];
                [weakSelf.normalArray removeObject:model];
                [[PLVDocumentUploadClient sharedClient] deleteFileWithFileName:model.fileName];
            }
            
            [weakSelf deleteModelSuccess:YES error:nil];
            loading = NO;
            
            completion ? completion() : nil;
        } failure:^(NSError * _Nonnull error) {
            [weakSelf deleteModelSuccess:NO error:error];
            loading = NO;
            
            failure ? failure(error) : nil;
        }];
    }
}

- (NSString *)errorMsgWithFileId:(NSString *)fileId {
    return self.errorMsgDict[fileId];
}

#pragma mark - [ Private Method ]

- (void)updateUnUploadArray {
    [self.unUploadArray removeAllObjects];
    NSArray *sdkUploadArray = [[PLVDocumentUploadClient sharedClient].uploadArray copy];
   
    for (PLVDocumentUploadModel *model in sdkUploadArray) {
        [self.unUploadArray insertObject:model atIndex:0];
    }
}

- (void)updateUnConvertArray {
    [self.unConvertArray removeAllObjects];
     NSArray *copyArray = [[PLVDocumentConvertManager sharedManager].convertArray copy];
    
     for (PLVDocumentUploadModel *model in copyArray) {
         [self.unConvertArray insertObject:model atIndex:0];
     }
}

- (void)updateNormalArray {
    [self.normalArray removeAllObjects];
}

- (void)updateNormalArrayWithCompletion:(void (^)(NSArray<NSDictionary *> *responseArray, NSError *error))completion {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestDocumentListWithLessonId:[PLVRoomDataManager sharedManager].roomData.lessonInfo.lessonId completion:^(NSArray<NSDictionary *> * _Nonnull responseArray) {
        // 清除本地数据
        [weakSelf updateNormalArray];
        for (NSDictionary *dict in responseArray) {
            if (![PLVFdUtil checkDictionaryUseable:dict]) {
                return;
            }
            NSString *status = PLV_SafeStringForDictKey(dict, @"status");
            if (![PLVFdUtil checkStringUseable:status]) {
                return;
            }
            if ([status isEqualToString:@"normal"]) {
                PLVDocumentModel *documentModel = [PLVDocumentModel plv_modelWithJSON:dict];
                [weakSelf.normalArray addObject:documentModel];
                
                // 处理离线转码成功未删除的沙盒文档
                [[PLVDocumentUploadClient sharedClient] deleteFileWithFileName:documentModel.fileName];
                
            }
        }
        if (completion) {
            completion(responseArray, nil);
        }
    } failure:^(NSError * _Nonnull error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)deleteModelSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [self dataUpdateNotify];
    } else {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(documentListViewModel:didDeleteDataFail:)]) {
            plv_dispatch_main_async_safe(^{
                [self.delegate documentListViewModel:self didDeleteDataFail:error];
            })
        }
    }
}

- (void)dataUpdateNotify {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentListViewModelDataUpdate:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentListViewModelDataUpdate:self];
        })
    }
}

#pragma mark Upload

/// 指定 fileId 任务恢复“上传中”或“上传失败”状态
- (void)uploadRebootSuccess:(BOOL)success fileId:(NSString *)fileId {
    PLVDocumentUploadModel *model = nil;
    [self isModelExistInUnploadArray:fileId model:&model];
    if (model == nil) {
        return;
    }
    
    model.status = success ? PLVDocumentUploadStatusUploading : PLVDocumentUploadStatusFailure;
}

/// 指定 fileId 模型是否存在未上传队列中
- (BOOL)isModelExistInUnploadArray:(NSString *)fileId model:(PLVDocumentUploadModel **)aModel {
    for (PLVDocumentUploadModel *model in self.unUploadArray) {
        if ([model.fileId isEqualToString:fileId]) {
            if (aModel) {
                *aModel = model;
            }
            return YES;
        }
    }
    return NO;
}

#pragma mark Convert

/// 指定 fileId 任务恢复“上传中”或“上传失败”状态
- (void)convertFailureWithFileId:(NSString *)fileId errorMsg:(NSString *)errorMsg {
    PLVDocumentUploadModel *model = nil;
    [self isModelExistInUnconvertArray:fileId model:&model];
    if (model == nil) {
        return;
    }
    
    model.status = PLVDocumentUploadStatusConvertFailure;
    self.errorMsgDict[fileId] = errorMsg;
}

/// 指定 fileId 模型是否存在队列中
- (BOOL)isModelExistInUnconvertArray:(NSString *)fileId model:(PLVDocumentUploadModel **)aModel {
    for (PLVDocumentUploadModel *model in self.unConvertArray) {
        if ([model.fileId isEqualToString:fileId]) {
            if (aModel) {
                *aModel = model;
            }
            return YES;;
        }
    }
    return NO;
}

#pragma mark Utils

- (PLVHCDocumentDataType)dataTyeWithRealIndex:(NSInteger)index {
    if (index < [self.unUploadArray count]) {
        return PLVHCDocumentDataTypeUnUpload;
    }
    
    index -= [self.unUploadArray count];
    if (index < [self.unConvertArray count]) {
        return PLVHCDocumentDataTypeUnConvert;
    }
    
    return PLVHCDocumentDataTypeNormal;
}

- (NSInteger)getArrayIndexWithDataType:(PLVHCDocumentDataType)dataType realIndex:(NSInteger)realIndex {
    if (dataType == PLVHCDocumentDataTypeUnUpload) {
        return realIndex;;
    }
    
    if (dataType == PLVHCDocumentDataTypeUnConvert) {
        NSInteger arrayIndex = realIndex - [self.unUploadArray count];
        return arrayIndex;
    }
    
    NSInteger arrayIndex = realIndex - [self.unUploadArray count] - [self.unConvertArray count];
    if (arrayIndex < [self.normalArray count]) {
        return arrayIndex;
    }
    
    return 0;
}

#pragma mark - [ Delegate ]

#pragma mark PLVSDocumentUploadResultDelegate

- (void)uploadStartWithModel:(PLVDocumentUploadModel *)model {
    [self.unUploadArray insertObject:model atIndex:0];
    [self dataUpdateNotify];
}

- (void)uploadRestartSuccess:(BOOL)success model:(PLVDocumentUploadModel *)model {
        [self uploadRebootSuccess:success fileId:model.fileId];
        [self dataUpdateNotify];
}

- (void)uploadRetrySuccess:(BOOL)success model:(PLVDocumentUploadModel *)model {
    if (success) {
        [self uploadRebootSuccess:success fileId:model.fileId];
        [self dataUpdateNotify];
    }
}

- (void)uploadSuccess:(BOOL)success model:(PLVDocumentUploadModel *)model {
    if (success) {
        [[PLVDocumentConvertManager sharedManager] addModel:model];
        [self.unConvertArray addObject:model];
        [self.unUploadArray removeObject:model];
        
        // 上传(续传)成功后删除本地数据
        PLVDocumentUploadModel *tempModel = nil;
        [self isModelExistInUnploadArray:model.fileId model:&tempModel];
        if (tempModel) {
            [self.unUploadArray removeObject:tempModel];
        }
    } else {
        [self uploadRebootSuccess:NO fileId:model.fileId];
    }
    
    [self dataUpdateNotify];
    
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {
            NSString *message = [NSString stringWithFormat:@"文档上传%@", success ? @"成功" : @"失败"];
            [PLVHCUtils showToastInWindowWithMessage:message];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = [NSString stringWithFormat:@"文档上传%@", success ? @"成功" : @"失败"];
            [PLVHCUtils showToastInWindowWithMessage:message];
        });
    }
}

- (void)updateUploadData {
    [self updateUnUploadArray];
    [self dataUpdateNotify];
}

#pragma mark PLVDocumentConvertManagerDelegate

- (void)convertFailure:(NSArray<NSDictionary *> *)responseArray {
    for (NSDictionary *data in responseArray) {
        NSString *fileId = data[@"fileId"];
        NSString *errorMsg = data[@"errorMsg"];
        [self convertFailureWithFileId:fileId errorMsg:errorMsg];
    }
    [self dataUpdateNotify];
}

- (void)convertComplete {
    [self loadData];
}

@end
