//
//  PLVLSConvertStatusRequester.m
//  PLVCloudClassStreamerSDK
//
//  Created by MissYasiky on 2020/4/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVDocumentConvertRequester.h"
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"
#import <PLVLiveScenesSDK/PLVLiveVideoAPI.h>
#import <PLVLiveScenesSDK/PLVDocumentUploadModel.h>

NSString *PLVDocumentConvertNormalNotification = @"PLVDocumentConvertNormalNotification";
NSString *PLVDocumentConvertFailureNotification = @"PLVDocumentConvertFailureNotification";

@interface PLVDocumentConvertRequester ()

@property (nonatomic, assign) BOOL first;

@end

@implementation PLVDocumentConvertRequester

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _first = YES;
        [self request];
    }
    return self;
}

#pragma mark - Private

- (void)request {
    NSInteger delay = self.first ? 0 : 5;
    self.first = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf askForConvertStatus];
    });
}

- (void)askForConvertStatus {
    NSString *fileIds = [self getFileIdsString];
    if (fileIds.length == 0) {
        [self request];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void (^SuccessBlock) (NSArray<NSDictionary *> * _Nonnull responseArray) = ^(NSArray<NSDictionary *> * _Nonnull responseArray){
        if (responseArray &&
            [responseArray isKindOfClass:[NSArray class]] &&
            [responseArray count] > 0) {
            [weakSelf processResponseArray:responseArray];
        }

        [weakSelf request];
    };
    
    if ([PLVRoomDataManager sharedManager].roomData.inHiClassScene) { // 互动学堂 场景
        NSString *lessonId = [PLVHiClassManager sharedManager].lessonId;
        NSString *courseCode = [PLVHiClassManager sharedManager].courseCode;
        BOOL isTeacher = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
        [PLVLiveVideoAPI getDocumentConvertStatusWithLessonId:lessonId fileId:fileIds courseCode:courseCode teacher:isTeacher completion:SuccessBlock  failure:^(NSError * _Nonnull error) {
            [weakSelf request];
        }];
    } else { // 手机开播(三分屏) 场景
        NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
        [PLVLiveVideoAPI getDocumentConvertStatusWithChannelId:channelId fileId:fileIds completion:SuccessBlock failure:^(NSError * _Nonnull error) {
            [weakSelf request];
        }];
    }
    
    
}

- (NSString *)getFileIdsString {
    NSArray *copyArray = [[PLVDocumentConvertManager sharedManager].convertArray copy];
    NSMutableString *muString = [[NSMutableString alloc] init];
    for (PLVDocumentUploadModel *model in copyArray) {
        if (model.status < PLVDocumentUploadStatusConvertFailure) {
            [muString appendString:model.fileId];
            [muString appendString:@","];
        }
    }
    NSString *fileIds = @"";
    if (muString.length > 0) {
        fileIds = [muString substringToIndex:(muString.length - 1)];
    }
    return fileIds;
}

- (void)processResponseArray:(NSArray <NSDictionary *> *)responseArray {
    NSMutableArray *failDataArray = [[NSMutableArray alloc] init];
    NSMutableArray *normalDataArray = [[NSMutableArray alloc] init];
    
    for (NSDictionary *data in responseArray) {
        NSString *convertStatus = data[@"convertStatus"];
        if ([convertStatus isEqualToString:@"failConvert"]) { // 转码失败
            [failDataArray addObject:data];
        } else if ([convertStatus isEqualToString:@"normal"]) {
            [normalDataArray addObject:data];
        }
    }
    
    if ([failDataArray count] > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVDocumentConvertFailureNotification object:[failDataArray copy] userInfo:nil];
    }
    
    if ([normalDataArray count] > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVDocumentConvertNormalNotification object:[normalDataArray copy] userInfo:nil];
    }
}

@end
