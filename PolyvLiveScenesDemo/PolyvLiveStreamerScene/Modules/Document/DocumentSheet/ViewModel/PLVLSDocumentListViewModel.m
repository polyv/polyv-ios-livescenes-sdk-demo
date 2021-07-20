//
//  PLVLSDocumentListViewModel.m
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2019/10/14.
//  Copyright © 2019 easefun. All rights reserved.
//

#import "PLVLSDocumentListViewModel.h"
#import "PLVDocumentModel.h"
#import "PLVLSUtils.h"
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVModel/PLVModel.h>

typedef NS_ENUM(NSInteger, PLVSDocumentDataType) {
    PLVSDocumentDataTypeUnUpload = 0,
    PLVSDocumentDataTypeUnConvert,
    PLVSDocumentDataTypeNormal
};

@interface PLVLSDocumentListViewModel () <
PLVDocumentUploadResultDelegate,
PLVDocumentConvertManagerDelegate
>

@property (nonatomic, copy) NSMutableDictionary <NSString *, NSString *> *errorMsgDict;

@property (nonatomic, copy) NSMutableArray <PLVDocumentUploadModel *> *unUploadArray;

@property (nonatomic, copy) NSMutableArray <PLVDocumentUploadModel *> *unConvertArray;

@property (nonatomic, copy) NSMutableArray <PLVDocumentModel *> *normalArray;

/// 被选中的文档索引
@property (nonatomic, assign) NSInteger selectedIndex;
/// 被选中的文档 autoId
@property (nonatomic, assign) NSInteger selectedAutoId;

@end

@implementation PLVLSDocumentListViewModel

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _errorMsgDict = [[NSMutableDictionary alloc] init];
        _unUploadArray = [[NSMutableArray alloc] init];
        _unConvertArray = [[NSMutableArray alloc] init];
        _normalArray = [[NSMutableArray alloc] init];
        _selectedIndex = -1;
        _deletingIndex = -1;
        [PLVDocumentUploadClient sharedClient].resultDelegate = self;
        [PLVDocumentConvertManager sharedManager].delegate = self;
    }
    return self;
}

#pragma mark - Getter & Setter

- (void)setDeletingIndex:(NSInteger)deletingIndex {
    NSInteger realIndex = deletingIndex - 1;
    if (realIndex < 0 || realIndex >= [self dataCount]) {
        return;
    }
    _deletingIndex = deletingIndex;
}

#pragma mark - Public

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    
    if (self.viewProxy &&
        [self.viewProxy respondsToSelector:@selector(documentListViewModel_startLoading)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.viewProxy documentListViewModel_startLoading];
        });
    }
    
    [self updateUnUploadArray];
    [self updateUnConvertArray];
    
    [self updateNormalArrayWithCompletion:^(NSArray<NSDictionary *> *responseArray, NSError *error) {
        [[PLVDocumentConvertManager sharedManager] checkupConvertArrayFromNormalList:weakSelf.normalArray];
        [weakSelf updateSelectedIndex];
        [weakSelf dataUpdateNotify];
        
        BOOL success = (responseArray && !error);
        if (weakSelf.viewProxy &&
            [weakSelf.viewProxy respondsToSelector:@selector(documentListViewModel_finishLoading:error:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.viewProxy documentListViewModel_finishLoading:success error:error];
            });
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
    
    PLVSDocumentDataType dataType = [self dataTyeWithRealIndex:realIndex];
    NSInteger arrayIndex = [self getArrayIndexWithDataType:dataType realIndex:realIndex];
    if (dataType == PLVSDocumentDataTypeUnUpload) {
        PLVDocumentUploadModel *model = self.unUploadArray[arrayIndex];
        return model;
    } else if (dataType == PLVSDocumentDataTypeUnConvert) {
        PLVDocumentUploadModel *model = self.unConvertArray[arrayIndex];
        return model;
    } else if (dataType == PLVSDocumentDataTypeNormal && arrayIndex != -1) {
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
    PLVSDocumentDataType dataType = [self dataTyeWithRealIndex:realIndex];
    return dataType == PLVSDocumentDataTypeNormal;
}

- (BOOL)selectAtIndex:(NSInteger)index {
    NSInteger realIndex = index - 1;
    if (realIndex < 0 || realIndex >= [self dataCount]) {
        return NO;
    }
    
    id model = [self documetModelAtIndex:index];
    if (model && [model isKindOfClass:[PLVDocumentModel class]]) {
        PLVDocumentModel *uploadedModel = (PLVDocumentModel *)model;
        self.selectedIndex = index;
        self.selectedAutoId = uploadedModel.autoId;
        return YES;
    }
    
    return NO;
}

- (void)deleteDocumentAtDeletingIndex {
    if (self.deletingIndex <= 0 || self.deletingIndex > [self dataCount] || self.deletingIndex == self.selectedIndex) {
        return;
    }
    
    NSInteger realDeletingIndex = self.deletingIndex - 1;
    PLVSDocumentDataType dataType = [self dataTyeWithRealIndex:realDeletingIndex];
    NSInteger arrayIndex = [self getArrayIndexWithDataType:dataType realIndex:realDeletingIndex];
    
    if (dataType == PLVSDocumentDataTypeUnUpload) {
        PLVDocumentUploadModel *model = self.unUploadArray[arrayIndex];
        [[PLVDocumentUploadClient sharedClient] removeUploadWithFileId:model.fileId];
        
        [self.unUploadArray removeObject:model];
        [self deleteModelSuccess:YES error:nil];
    } else {
        static BOOL loading;
        if (loading) {
            return;
        }
        loading = YES;

        realDeletingIndex -= [self.unUploadArray count] + [self.unConvertArray count];
        PLVDocumentModel *model = self.normalArray[arrayIndex];
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        NSString *channelId = roomData.channelId;

        __weak typeof(self) weakSelf = self;
        [PLVLiveVideoAPI deleteDocumentWithChannelId:channelId fileId:model.fileId completion:^{
            if (dataType == PLVSDocumentDataTypeUnConvert) {
                PLVDocumentUploadModel *model = weakSelf.unConvertArray[arrayIndex];
                [[PLVDocumentConvertManager sharedManager] removeModel:model];

                [weakSelf.unConvertArray removeObject:model];
            } else {
                [weakSelf.normalArray removeObject:model];
            }
            
            [weakSelf deleteModelSuccess:YES error:nil];
            loading = NO;
        } failure:^(NSError * _Nonnull error) {
            [weakSelf deleteModelSuccess:NO error:error];
            loading = NO;
        }];
    }
}

- (NSString *)errorMsgWithFileId:(NSString *)fileId {
    return self.errorMsgDict[fileId];
}

#pragma mark - Private

- (void)updateSelectedIndex {
    if (self.selectedAutoId <= 0) {
        self.selectedIndex = -1;
    }
    
    NSInteger arrayIndex = -1;
    for (int i = 0; i < [self.normalArray count]; i++) {
        PLVDocumentModel *model = self.normalArray[i];
        if (model.autoId == self.selectedAutoId) {
            arrayIndex = i;
            break;
        }
    }
    
    if (arrayIndex != -1) {
        NSInteger uiIndex = 1 + [self.unUploadArray count] + [self.unConvertArray count] + arrayIndex;
        self.selectedIndex = uiIndex;
    } else {
        self.selectedAutoId = 0;
        self.selectedIndex = -1;
    }
}

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

- (void)updateNormalArrayWithCompletion:(void (^)(NSArray<NSDictionary *> *responseArray, NSError *error))completion {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSString *channelId = roomData.channelId;
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestDocumentListWithChannelId:channelId completion:^(NSArray<NSDictionary *> * _Nonnull responseArray) {
        [weakSelf.normalArray removeAllObjects];
        for (NSDictionary *dict in responseArray) {
            if ([@"normal" isEqualToString:dict[@"status"]]) {
                PLVDocumentModel *documentModel = [PLVDocumentModel plv_modelWithJSON:dict];
                [weakSelf.normalArray addObject:documentModel];
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
    __weak typeof(self) weakSelf = self;
    if (success) {
        [self updateSelectedIndex];
        self.deletingIndex = -1;
        
        [self dataUpdateNotify];
    } else {
        if (self.viewProxy &&
            [self.viewProxy respondsToSelector:@selector(documentListViewModel_deleteDataFail:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.viewProxy documentListViewModel_deleteDataFail:error];
            });
        }
    }
}

/// 数据变化时在主线程触发回调'-documentListViewModel_dataUpdate'
- (void)dataUpdateNotify {
    if (self.viewProxy &&
        [self.viewProxy respondsToSelector:@selector(documentListViewModel_dataUpdate)]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.viewProxy documentListViewModel_dataUpdate];
        });
    }
}

#pragma mark - Private Upload

/// 指定 fileId 任务恢复“上传中”或“上传失败”状态
- (void)uploadRebootSuccess:(BOOL)success fileId:(NSString *)fileId {
    PLVDocumentUploadModel *model = nil;
    [self isModelExistInUnploadArray:fileId model:&model];
    if (model == nil) {
        return;
    }
    
    model.status = success ? PLVDocumentUploadStatusUploading : PLVDocumentUploadStatusFailure;
}

/// 指定 fileId 模型是否存在队列中
- (BOOL)isModelExistInUnploadArray:(NSString *)fileId model:(PLVDocumentUploadModel **)aModel {
    for (PLVDocumentUploadModel *model in self.unUploadArray) {
        if ([model.fileId isEqualToString:fileId]) {
            if (aModel) {
                *aModel = model;
            }
            return YES;;
        }
    }
    return NO;
}

#pragma mark - Private Convert

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

#pragma mark - Private Utils

- (PLVSDocumentDataType)dataTyeWithRealIndex:(NSInteger)index {
    if (index < [self.unUploadArray count]) {
        return PLVSDocumentDataTypeUnUpload;
    }
    
    index -= [self.unUploadArray count];
    if (index < [self.unConvertArray count]) {
        return PLVSDocumentDataTypeUnConvert;
    }
    
    return PLVSDocumentDataTypeNormal;
}

- (NSInteger)getArrayIndexWithDataType:(PLVSDocumentDataType)dataType realIndex:(NSInteger)realIndex {
    if (dataType == PLVSDocumentDataTypeUnUpload) {
        return realIndex;;
    }
    
    if (dataType == PLVSDocumentDataTypeUnConvert) {
        NSInteger arrayIndex = realIndex - [self.unUploadArray count];
        return arrayIndex;
    }
    
    NSInteger arrayIndex = realIndex - [self.unUploadArray count] - [self.unConvertArray count];
    if (arrayIndex < [self.normalArray count]) {
        return arrayIndex;
    }
    
    return 0;
}

#pragma mark - PLVSDocumentUploadResult Delegate

- (void)uploadStartWithModel:(PLVDocumentUploadModel *)model {
    [self.unUploadArray insertObject:model atIndex:0];
    [self updateSelectedIndex];
    [self dataUpdateNotify];
}

- (void)uploadRestartSuccess:(BOOL)success model:(PLVDocumentUploadModel *)model {
    if (success) {
        
    } else {
        [self uploadRebootSuccess:success fileId:model.fileId];
        [self dataUpdateNotify];
    }
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
    } else {
        [self uploadRebootSuccess:NO fileId:model.fileId];
    }
    
    [self dataUpdateNotify];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"文档上传%@", success ? @"成功" : @"失败"];
        [PLVLSUtils showToastInHomeVCWithMessage:message];
    });
}

- (void)updateUploadData {
    [self updateUnUploadArray];
    [self updateSelectedIndex];
    
    [self dataUpdateNotify];
}

#pragma mark - PLVLSConvertStatusManager Delegate

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
