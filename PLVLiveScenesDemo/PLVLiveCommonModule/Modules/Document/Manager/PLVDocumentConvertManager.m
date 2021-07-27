//
//  PLVLSConvertStatusManager.m
//  PLVCloudClassStreamerSDK
//
//  Created by MissYasiky on 2020/4/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVDocumentConvertManager.h"
#import "PLVDocumentConvertRequester.h"
#import "PLVRoomDataManager.h"
#import "PLVDocumentModel.h"
#import <PLVLiveScenesSDK/PLVDocumentUploadModel.h>

extern NSString *PLVDocumentConvertNormalNotification;
extern NSString *PLVDocumentConvertFailureNotification;

NSString *PLVDocumentConvertAnimateLossCacheKey = @"PLVDocumentConvertAnimateLossCacheKey";

@interface PLVDocumentConvertManager ()

@property (nonatomic, copy) NSMutableArray <PLVDocumentUploadModel *> *convertArray;

@property (nonatomic, strong) PLVDocumentConvertRequester *requester;

@end

@implementation PLVDocumentConvertManager

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _convertArray = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(convertStatusChangedNormal:) name:PLVDocumentConvertNormalNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(convertStatusChangedFailure:) name:PLVDocumentConvertFailureNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

+ (instancetype)sharedManager {
    static PLVDocumentConvertManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PLVDocumentConvertManager alloc] init];
    });
    return manager;
}

- (void)polling:(BOOL)start {
    if (start) {
        self.requester = [[PLVDocumentConvertRequester alloc] init];
    } else {
        self.requester = nil;
    }
}

- (void)addModel:(PLVDocumentUploadModel *)model {
    PLVDocumentUploadModel *existModel = [self modelWithFileId:model.fileId];
    if (existModel) {
        return;
    }
    
    model.status = PLVDocumentUploadStatusSuccess;
    [self.convertArray addObject:model];
}

- (void)removeModel:(PLVDocumentUploadModel *)model {
    [self.convertArray removeObject:model];
}

- (void)clear {
    [self polling:NO];
    [self.convertArray removeAllObjects];
}

- (void)checkupConvertArrayFromNormalList:(NSArray <PLVDocumentModel *> *)normalList {
    for (PLVDocumentModel *normalModel in normalList) {
        NSString *normalFileId = normalModel.fileId;
        PLVDocumentUploadModel *convertModel = [self modelWithFileId:normalFileId];
        if (convertModel) {
            [self removeModel:convertModel];
        }
    }
}

#pragma mark - Private

- (PLVDocumentUploadModel *)modelWithFileId:(NSString *)fileId {
    NSMutableArray *muArray = [self.convertArray copy];
    for (PLVDocumentUploadModel *model in muArray) {
        if ([model.fileId isEqualToString:fileId]) {
            return model;
        }
    }
    return nil;
}

#pragma mark - AnimateLoss

+ (BOOL)isAnimateLossWithFileId:(NSString *)fileId type:(NSString *)type {
    return ([fileId rangeOfString:@"animate"].location != NSNotFound && [type isEqualToString:@"common"]);
}

+ (void)addAnimateLossCacheWithFileId:(NSString *)fileId {
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    id cache = [[NSUserDefaults standardUserDefaults] objectForKey:PLVDocumentConvertAnimateLossCacheKey];
    NSDictionary *cacheDict = (NSDictionary *)cache;
    NSMutableDictionary *muDict = [[NSMutableDictionary alloc] init];
    if (cacheDict) {
        [muDict setDictionary:cacheDict];
    }
    NSArray *cacheArray = (NSArray *)muDict[channelId];
    NSMutableArray *muArray = [[NSMutableArray alloc] init];
    if (cacheArray && [cacheArray isKindOfClass:[NSArray class]]) {
        [muArray addObjectsFromArray:cacheArray];
    }
    [muArray addObject:fileId];
    [muDict setObject:[muArray copy] forKey:channelId];
    [[NSUserDefaults standardUserDefaults] setObject:[muDict copy] forKey:PLVDocumentConvertAnimateLossCacheKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)removeAnimateLossCacheWithFileId:(NSString *)fileId {
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    id cache = [[NSUserDefaults standardUserDefaults] objectForKey:PLVDocumentConvertAnimateLossCacheKey];
    NSDictionary *cacheDict = (NSDictionary *)cache;
    if (!cacheDict || ![cacheDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSMutableDictionary *muDict = [[NSMutableDictionary alloc] initWithDictionary:cacheDict];
    NSArray *cacheArray = (NSArray *)muDict[channelId];
    if (!cacheArray || ![cacheArray isKindOfClass:[NSArray class]] || [cacheArray count] == 0) {
        return;
    }
    
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithArray:cacheArray];
    for (int i = 0; i < [cacheArray count]; i++) {
        NSString *object = cacheArray[i];
        if ([object isEqualToString:fileId]) {
            [muArray removeObjectAtIndex:i];
            break;
        }
    }

    [muDict setObject:[muArray copy] forKey:channelId];
    [[NSUserDefaults standardUserDefaults] setObject:[muDict copy] forKey:PLVDocumentConvertAnimateLossCacheKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isAnimateLossFromCacheWithFileId:(NSString *)fileId {
    id cache = [[NSUserDefaults standardUserDefaults] objectForKey:PLVDocumentConvertAnimateLossCacheKey];
    NSDictionary *cacheDict = (NSDictionary *)cache;
    if (cacheDict == nil || ![cacheDict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;    NSArray *cacheArray = (NSArray *)cacheDict[channelId];
    if (cacheArray == nil || ![cacheArray isKindOfClass:[NSArray class]] || [cacheArray count] == 0) {
        return NO;
    }
    
    for (NSString *object in cacheArray) {
        if ([object isEqualToString:fileId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - NSNotification Related

- (void)convertStatusChangedNormal:(NSNotification *)notif {
    NSArray *dataArray = (NSArray *)notif.object;
    
    for (NSDictionary *data in dataArray) {
        NSString *fileId = data[@"fileId"];
        PLVDocumentUploadModel *model = [self modelWithFileId:fileId];
        [self removeModel:model];
        
        NSString *type = data[@"type"] ?: @"";
        BOOL isAnimateLoss = [PLVDocumentConvertManager isAnimateLossWithFileId:fileId type:type];
        if (isAnimateLoss) {
            [PLVDocumentConvertManager addAnimateLossCacheWithFileId:fileId];
        }
    }
    
    if (self.delegate) {
        [self.delegate convertComplete];
    }
}

- (void)convertStatusChangedFailure:(NSNotification *)notif {
    NSArray *dataArray = (NSArray *)notif.object;
    
    for (NSDictionary *data in dataArray) {
        NSString *fileId = data[@"fileId"];
        PLVDocumentUploadModel *model = [self modelWithFileId:fileId];
        model.status = PLVDocumentUploadStatusConvertFailure;
    }
    
    if (self.delegate) {
        NSArray *dataArray = (NSArray *)notif.object;
        [self.delegate convertFailure:dataArray];
    }
}

@end
