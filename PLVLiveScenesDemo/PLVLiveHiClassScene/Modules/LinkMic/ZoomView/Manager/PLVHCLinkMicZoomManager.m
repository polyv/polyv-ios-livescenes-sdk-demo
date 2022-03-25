//
//  PLVHCLinkMicZoomManager.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/17.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicZoomManager.h"
// 模块
#import "PLVRoomDataManager.h"
#import "PLVHCLinkMicZoomModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVHCLinkMicZoomManager()<
PLVSocketManagerProtocol
>

@property (nonatomic, assign) NSInteger windowMaxIndex; // 当前窗口最大下标，初始化为999，每次操作update一次窗口都需要+1

@property (nonatomic, assign) BOOL isMaxZoomNum;

@property (nonatomic, strong) NSMutableArray <PLVHCLinkMicZoomModel *> *zoomModelArrayM; // 当前在放大区域的窗口模型
@property (nonatomic, assign, getter=isTeacher) BOOL teacher; // 当前身份是否为讲师

@end

@implementation PLVHCLinkMicZoomManager {
    /// 操作数组的信号量，防止多线程读写数组
    dispatch_semaphore_t _zoomModelLock;
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static PLVHCLinkMicZoomManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[PLVHCLinkMicZoomManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)setup {
    // 初始化信号量
    _zoomModelLock = dispatch_semaphore_create(1);
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    // 初始化数组，预设初始容量
    self.zoomModelArrayM = [NSMutableArray arrayWithCapacity:kPLVHCLinkMicZoomMAXNum];
    // 初始化数据
    self.windowMaxIndex = 999;
}

- (void)clear {
    self.zoomModelArrayM = [NSMutableArray array];
    [[PLVSocketManager sharedManager] removeDelegate:self];
}

- (void)startGroup {
    [self removeAllZoomModel];
}

- (void)leaveGroupRoomWithAckData:(NSDictionary *)ackData {
    [self handleLeaveGroupEventWithDict:ackData];
}

- (void)linkMicUserWillDealloc:(NSString *)userId {
    if (!self.isTeacher) {
        return;
    }
    
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    if (![self isInZoomWithUserId:userId]) {
        return;
    }
    
    PLVHCLinkMicZoomModel *model = [PLVHCLinkMicZoomModel createOutZoomModelWithUserId:userId];
    BOOL success = [self sendZoomRemoveWithModel:model];
    if (success) { // 移除窗口成功 移除缓存
        [self removeZoomModel:model];
    }
}

- (BOOL)zoomWithModel:(PLVHCLinkMicZoomModel *)model {
    if (!self.isTeacher) {
        return NO;
    }
    
    if (self.zoomModelArrayM.count >= kPLVHCLinkMicZoomMAXNum) {
        NSLog(@"-[PLVHCLinkMicZoomManager zoomWithModel:] 最多支持放大%d摄像头", kPLVHCLinkMicZoomMAXNum);
        return NO;
    }
    
    if (![PLVFdUtil checkStringUseable:model.userId]) {
        return NO;
    }
    // index 设为当前最大值+1
    self.windowMaxIndex += 1;
    model.index = self.windowMaxIndex;

    if (![self isInZoomWithUserId:model.userId]) { // 第一次加入，缓存数据
        [self addZoomModel:model];
    }
    
    return [self sendZoomUpdateWithModel:model];
}

- (BOOL)zoomOutWithModel:(PLVHCLinkMicZoomModel *)model {
    if (!self.isTeacher) {
        return NO;
    }
    
    BOOL success = [self sendZoomRemoveWithModel:model];
    if (success) { // 移除窗口成功 移除缓存
        [self removeZoomModel:model];
    }
    return success;
}

- (BOOL)zoomOutAll {
    if (!self.isTeacher) {
        return NO;
    }
    
    BOOL success = YES;
    NSArray *tempArray = [self.zoomModelArrayM copy];
    for (PLVHCLinkMicZoomModel *model in tempArray) {
        success =  success && [self zoomOutWithModel:model]; // 需要全部成功才会设置YES;
    }
    return success;
}

- (BOOL)isInZoomWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return NO;
    }
    
    __block BOOL isInZoom = NO;
    NSArray *tempArray = [self.zoomModelArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([PLVFdUtil checkStringUseable:obj.userId] &&
            [obj.userId isEqualToString:userId]) {
            isInZoom = YES;
            *stop = YES;
        }
    }];
    return isInZoom;
}

- (BOOL)isMaxZoomNum {
    return self.zoomModelArrayM.count >= kPLVHCLinkMicZoomMAXNum;
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (BOOL)isTeacher {
    return [PLVSocketManager sharedManager].userType == PLVSocketUserTypeTeacher;
}

#pragma mark 发送socket消息

/// 发送窗口update
/// @param model 窗口模型
- (BOOL)sendZoomUpdateWithModel:(PLVHCLinkMicZoomModel *)model {
    if (!model) {
        return NO;
    }
    
    NSDictionary *dict = [model modelToDictionaryByUpdate];
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        return NO;
    }
    
    return [[PLVSocketManager sharedManager] emitEvent:@"changeMicSite" content:dict];
}

/// 发送窗口remove
/// @param model 窗口模型
- (BOOL)sendZoomRemoveWithModel:(PLVHCLinkMicZoomModel *)model {
    if (!model) {
        return NO;
    }
    
    NSDictionary *dict = [model modelToDictionaryByRemove];
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        return NO;
    }
    
    return [[PLVSocketManager sharedManager] emitEvent:@"changeMicSite" content:dict];
}

#pragma mark 处理socket回调

/// 处理OnSliceId 回调
/// @param dict 回调数据
- (void)handleOnSliceIdEventWithDict:(NSDictionary *)dict {
    NSDictionary *dataDict = PLV_SafeDictionaryForDictKey(dict, @"data");
    NSString *micSite = PLV_SafeStringForDictKey(dataDict, @"micSite");
    NSDictionary *micSiteDict = [self convertJsonStirngToNSDictionary:micSite];
    [self handleMicSiteDataWithDict:micSiteDict];
}

/// 处理离开分组 回调
/// @param dict 回调数据
- (void)handleLeaveGroupEventWithDict:(NSDictionary *)dict {
    NSDictionary *dataDict = PLV_SafeDictionaryForDictKey(dict, @"roomsStatus");
    NSString *micSite = PLV_SafeStringForDictKey(dataDict, @"micSite");
    NSDictionary *micSiteDict = [self convertJsonStirngToNSDictionary:micSite];
    [self handleMicSiteDataWithDict:micSiteDict];
}

/// 处理micSite数据
/// @param micSiteDict micSite数据
- (void)handleMicSiteDataWithDict:(NSDictionary *)micSiteDict {
    if (micSiteDict &&
        [micSiteDict isKindOfClass:[NSDictionary class]]) {
        NSArray *array = [self sortMicSiteArray:[micSiteDict allValues]];
        NSArray *zoomModelTempArray = [self.zoomModelArrayM copy];
        for (PLVHCLinkMicZoomModel *model in zoomModelTempArray) {
            BOOL exist = NO;
            for (NSDictionary *dict in array) {
                if([PLVFdUtil checkDictionaryUseable:dict]){
                    PLVHCLinkMicZoomModel *tempModel = [PLVHCLinkMicZoomModel modelWithJsonDic:dict];
                    if ([tempModel.userId isEqualToString:model.userId]) {
                        exist = YES;
                    }
                }
            }
            if (!exist) { // 将不存在的模型移除
                [self removeZoomModel:model];
            }
        }
        
        self.zoomModelArrayM = [NSMutableArray arrayWithCapacity:kPLVHCLinkMicZoomMAXNum]; // 清除本地数据，重新加入，以防具体属性的更新
        for (NSDictionary *dict in array) {
            if([PLVFdUtil checkDictionaryUseable:dict]){
                PLVHCLinkMicZoomModel *model = [PLVHCLinkMicZoomModel modelWithJsonDic:dict];
                [self addZoomModel:model];
                // 响应当前的连麦放大视图数据
                [self notifyListenerDidUpdateZoomWithModel:model];
            }
        }
    }
}

#pragma mark 管理窗口数据

- (void)addZoomModel:(PLVHCLinkMicZoomModel *)model {
    if (model) {
        dispatch_semaphore_wait(_zoomModelLock, DISPATCH_TIME_FOREVER);
        // 已存在，更新内部数据
        if ([self isInZoomWithUserId:model.userId]) {
            [self updateModel:model];
        } else {
            // 不存在，添加
            if (self.zoomModelArrayM.count >= kPLVHCLinkMicZoomMAXNum) { // 是否已超出数量限制
                NSLog(@"-[PLVHCLinkMicZoomManager addZoomModel:] 最多支持放大%d摄像头", kPLVHCLinkMicZoomMAXNum);
            } else{
                [self.zoomModelArrayM addObject:model];
            }
        }
        dispatch_semaphore_signal(_zoomModelLock);
    }
}

/// 将窗口模型数据移除
/// @param model 模型
- (void)removeZoomModel:(PLVHCLinkMicZoomModel *)model {
    if (!model) {
        return;
    }
    
    dispatch_semaphore_wait(_zoomModelLock, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [self.zoomModelArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([PLVFdUtil checkStringUseable:obj.userId] &&
            [obj.userId isEqualToString:model.userId]) {
            [self.zoomModelArrayM removeObject:obj];
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_zoomModelLock);
    
    [self notifyListenerDidRemoveZoomWithModel:model];
}

// 移除全部放大区域数据，不需要发送socket消息（目前移动端讲师没有开启分组功能，所以学生端不需要发送socket）
- (void)removeAllZoomModel {
    dispatch_semaphore_wait(_zoomModelLock, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [self.zoomModelArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.zoomModelArrayM removeObject:obj];
        [self notifyListenerDidRemoveZoomWithModel:obj];
    }];
    dispatch_semaphore_signal(_zoomModelLock);
}

#pragma mark 工具

- (BOOL)isExist:(PLVHCLinkMicZoomModel *)model {
    if (!model) {
        return NO;
    }
    
    dispatch_semaphore_wait(_zoomModelLock, DISPATCH_TIME_FOREVER);
    __block BOOL isExist = NO;
    NSArray *tempArray = [self.zoomModelArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == model) {
            isExist = YES;
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_zoomModelLock);
    return isExist;
}

/// 将 JSON 数据转化为字典或数组
- (NSDictionary *)convertJsonStirngToNSDictionary:(NSString *)jsonStirng{
    if (![PLVFdUtil checkStringUseable:jsonStirng]) {
        return nil;
    }
    
    NSError *error;
    NSData *jsonData = [jsonStirng dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error]; // NSJSONReadingAllowFragments：兼容所有的json格式
    if (error) {
        return nil;
    }
    return dict;
}

- (void)updateModel:(PLVHCLinkMicZoomModel *)model {
    if (!model) {
        return;
    }
    NSArray *tempArray = [self.zoomModelArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([PLVFdUtil checkStringUseable:obj.userId] &&
            [obj.userId isEqualToString:model.userId]) {
            [obj updateWithModel:model];
            *stop = YES;
        }
    }];
}

/// 对数组 micSiteDict 进行排序,index越大越靠后,已达到在图层最上部的效果
- (NSArray *)sortMicSiteArray:(NSArray *)micSiteArray {
    dispatch_semaphore_wait(_zoomModelLock, DISPATCH_TIME_FOREVER);
    NSArray *sortedArray = [micSiteArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSDictionary *dict1 = (NSDictionary *)obj1;
        NSDictionary *dict2 = (NSDictionary *)obj2;
        NSInteger index1 = PLV_SafeIntegerForDictKey(dict1, @"index");
        NSInteger index2 = PLV_SafeIntegerForDictKey(dict2, @"index");
        if (index1 < index2) {
            return NSOrderedAscending;
        }
        if (index1 > index2) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    dispatch_semaphore_signal(_zoomModelLock);
    return sortedArray;
}

#pragma mark 发送PLVHCLinkMicZoomManagerDelegate协议方法

- (void)notifyListenerDidUpdateZoomWithModel:(PLVHCLinkMicZoomModel *)model {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(linkMicZoomManager:didUpdateZoomWithModel:)]) {
            [self.delegate linkMicZoomManager:self didUpdateZoomWithModel:model];
        }
    })
}

- (void)notifyListenerDidRemoveZoomWithModel:(PLVHCLinkMicZoomModel *)model {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(linkMicZoomManager:didRemoveZoomWithModel:)]) {
            [self.delegate linkMicZoomManager:self didRemoveZoomWithModel:model];
        }
    })
}

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didReceiveEvent:(NSString *)event subEvent:(NSString *)subEvent json:(NSString *)jsonString jsonObject:(id)object {
    
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([event isEqualToString:@"changeMicSite"]) { // 连麦放大视图事件
        if ([subEvent isEqualToString:@"update"]) { // 讲师放大摄像头画面，或更新画面尺寸位置
            if (self.isTeacher) { // 讲师无需处理update事件（因为这个事件就是讲师发出的）
                return;
            }
            PLVHCLinkMicZoomModel *model = [PLVHCLinkMicZoomModel modelWithJsonDic:jsonDict];
            [self addZoomModel:model];
            [self notifyListenerDidUpdateZoomWithModel:model];
        } else if ([subEvent isEqualToString:@"remove"]) { // 摄像头画面移回连麦区域、已下麦
            PLVHCLinkMicZoomModel *model = [PLVHCLinkMicZoomModel modelWithJsonDic:jsonDict];
            [self removeZoomModel:model];
        }
    }
}

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([subEvent isEqualToString:@"onSliceID"]) {
        [self handleOnSliceIdEventWithDict:jsonDict];
    }
}

@end
