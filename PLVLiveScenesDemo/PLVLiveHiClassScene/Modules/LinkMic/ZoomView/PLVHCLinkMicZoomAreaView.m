//
//  PLVHCLinkMicZoomAreaView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicZoomAreaView.h"

// UI
#import "PLVHCLinkMicZoomItemContainer.h"
#import "PLVHCLinkMicItemView.h"

// 模块
#import "PLVLinkMicOnlineUser.h"
#import "PLVLinkMicOnlineUser+HC.h"
#import "PLVHCLinkMicZoomModel.h"
#import "PLVRoomDataManager.h"

@interface PLVHCLinkMicZoomAreaView(){
    dispatch_semaphore_t _zoomAreaViewLock;
}

#pragma mark 数据
@property (nonatomic, strong) NSMutableArray <PLVHCLinkMicZoomItemContainer *> *itemArrayM; // 窗口数组

@end

@implementation PLVHCLinkMicZoomAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _zoomAreaViewLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isKindOfClass:[self class]]) { // 自己本身不触发交互
        return nil;
    }
    return view;
}

#pragma mark - [ Public Method ]

- (void)refreshLinkMicItemView:(PLVHCLinkMicItemView *)linkMicItemView {
    if ([self isInZoomViewWithUserId:linkMicItemView.userModel.userId]) { // 判断是否已显示
        [self updateItemView:linkMicItemView userId:linkMicItemView.userModel.userId];
    }
}

- (void)reloadLinkMicUserZoom {
    NSArray *tempArray = [[PLVHCLinkMicZoomManager sharedInstance].zoomModelArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self updateZoomWithModel:obj];
    }];
}

- (void)changeFullScreen:(BOOL)fullScreen {
    NSArray *tempArray = [[PLVHCLinkMicZoomManager sharedInstance].zoomModelArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 讲师需要根据自己当前的的视图大小，更新每一个放大视图的数据
        if ([PLVHCLinkMicZoomManager sharedInstance].isTeacher) {
            CGFloat scaleLeft = obj.left / obj.parentWidth;
            CGFloat scaleTop = obj.top / obj.parentHeight;
            CGFloat scaleWidth = obj.width / obj.parentWidth;
            CGFloat scaleHeight = obj.height / obj.parentHeight;
            
            obj.parentWidth = self.bounds.size.width;
            obj.parentHeight = self.bounds.size.height;
            obj.left = obj.parentWidth * scaleLeft;
            obj.top = obj.parentHeight * scaleTop;
            obj.width = obj.parentWidth * scaleWidth;
            obj.height = obj.parentHeight * scaleHeight;
            // 发送socket消息
            [[PLVHCLinkMicZoomManager sharedInstance] zoomWithModel:obj];
        }
        // 更新本地UI
        [self updateZoomWithModel:obj];
    }];
}

- (void)removeLocalPreviewZoom {
    dispatch_semaphore_wait(_zoomAreaViewLock, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [self.itemArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomItemContainer *itemContainer, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.itemArrayM removeObject:itemContainer];
            plv_dispatch_main_async_safe(^{
                [itemContainer removeFromSuperview];
            })
    }];
    dispatch_semaphore_signal(_zoomAreaViewLock);
}

- (void)displayExternalView:(UIView *)externalView userId:(NSString *)userId{
    if (![PLVHCLinkMicZoomManager sharedInstance].isTeacher) {
        return;
    }
    
    if ([self isInZoomViewWithUserId:userId]) {
        return;
    }
    
    PLVHCLinkMicZoomModel *model = [PLVHCLinkMicZoomModel createZoomModelWithUserId:userId parentSize:self.bounds.size];
    if (!model) {
        return;
    }
    
    [self zoomWithModel:model externalView:externalView];
}

- (void)removeExternalView:(UIView *)externalView userId:(NSString *)userId {
    if (![PLVHCLinkMicZoomManager sharedInstance].isTeacher) {
        return;
    }
    
    if (![self isInZoomViewWithUserId:userId]) {
        return;
    }
    
    PLVHCLinkMicZoomModel *model = [self findZoomModelWithUserId:userId];
    if (!model) {
        return;
    }
    
    BOOL success = [[PLVHCLinkMicZoomManager sharedInstance] zoomOutWithModel:model];
    if (success) {
        [self removeLinkMicItemViewWithZoomModel:model];
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (NSMutableArray<PLVHCLinkMicZoomItemContainer *> *)itemArrayM {
    if (!_itemArrayM) {
        _itemArrayM = [NSMutableArray array];
    }
    return _itemArrayM;
}

- (PLVHCLinkMicZoomItemContainer *)createItemContainerWithModel:(PLVHCLinkMicZoomModel *)zoomModel{
    PLVHCLinkMicZoomItemContainer *item = [[PLVHCLinkMicZoomItemContainer alloc] initWithFrame:[self frameConversionWithZoomModel:zoomModel]];
    [item setupZoomModel:zoomModel];
    __weak typeof(self) weakSelf = self;
    item.tapActionBlock = ^(PLVLinkMicOnlineUser * _Nullable data) {
        if (weakSelf.delegate &&
            [weakSelf.delegate respondsToSelector:@selector(linkMicZoomAreaView:didTapActionWithUserData:)]) {
            [self.delegate linkMicZoomAreaView:self didTapActionWithUserData:data];
        }
    };
    
    item.moveActionBlock = ^(PLVHCLinkMicZoomModel * _Nonnull zoomModel) {
        [weakSelf updateZoomItemContainerFrameWithZoomModel:zoomModel];
        [[PLVHCLinkMicZoomManager sharedInstance] zoomWithModel:zoomModel];
    };
    
    item.zoomActionBlock = ^(PLVHCLinkMicZoomModel * _Nonnull zoomModel) {
        [weakSelf updateZoomItemContainerFrameWithZoomModel:zoomModel];
        [[PLVHCLinkMicZoomManager sharedInstance] zoomWithModel:zoomModel];
    };
    return item;
}

#pragma mark 更新、移除放大窗口

- (void)updateZoomWithModel:(PLVHCLinkMicZoomModel *)model {
    NSString *userId = model.userId;
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    [self setupInLinkMicZoom:YES userId:userId];
    [self updateAreaViewFrameWithZoomModel:model];
    
    // 已有两个以上的窗口 且 当前窗口已添加 需要排序
    if (self.itemArrayM.count >=2 &&
        [self isInZoomViewWithUserId:userId]) {
        NSArray <PLVHCLinkMicZoomItemContainer *>*tempArray = [self sortMicSiteArray:[self.itemArrayM copy]];
        if ([PLVFdUtil checkArrayUseable:tempArray]) {
            [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomItemContainer *item, NSUInteger idx, BOOL * _Nonnull stop) {
                [self showLinkMicItemViewToZoomWithZoomModel:item.zoomModel];
            }];
        }
    } else {
        [self showLinkMicItemViewToZoomWithZoomModel:model];
    }
}

- (void)removeZoomWithModel:(PLVHCLinkMicZoomModel *)model {
    NSString *userId = model.userId;
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    [self setupInLinkMicZoom:NO userId:userId];
    [self removeLinkMicItemViewWithZoomModel:model];
}

#pragma mark 工具

// 坐标转化，按比例转化
- (CGRect)frameConversionWithZoomModel:(PLVHCLinkMicZoomModel *)zoomModel {
    CGSize selfSize = self.bounds.size;
    CGFloat width = zoomModel.width;
    CGFloat parentWidth = zoomModel.parentWidth;
    CGFloat scale = width / parentWidth; // 此视图宽度在讲师端宽度的占比
    CGFloat scaleH = zoomModel.height / zoomModel.parentHeight; // 此视图宽度在讲师端高度的占比
    CGFloat whScale = 16.0 / 9.0; // 注意：数据使用浮点型
    
    CGFloat itemWidth = selfSize.width * scale; // 等比例缩放
    CGFloat itemHeight = itemWidth / whScale;
    
    if (itemHeight > selfSize.height) { // 最大高度为视图高度
        itemHeight = selfSize.height;
        itemWidth = itemHeight * whScale;
    }
    
    if (itemWidth > selfSize.width) { // 最大宽度为视图宽度
        itemWidth = selfSize.width;
        itemHeight = itemWidth / whScale;
    }
    
    if (itemHeight / selfSize.height > scaleH) { // 如果高度占比超出了讲师端
        itemHeight = selfSize.height * scaleH;
        itemWidth = itemHeight * whScale;
    }
    
    scale = zoomModel.left / parentWidth;
    CGFloat itemLeft = scale * selfSize.width;
    if (itemLeft + itemWidth >= selfSize.width) { // 防止超出父视图
        itemLeft = selfSize.width - itemWidth;
    }
    
    scale = zoomModel.top / zoomModel.parentHeight;
    CGFloat itemTop = scale * selfSize.height;
    if (itemTop + itemHeight >= selfSize.height) { // 防止超出父视图
        itemTop = selfSize.height - itemHeight;
    }
    return CGRectMake(itemLeft, itemTop, itemWidth, itemHeight);
}

// 根据'讲师端放大区域宽高比' 更新本地放大区域宽高
- (void)updateAreaViewFrameWithZoomModel:(PLVHCLinkMicZoomModel *)zoomModel {
    CGFloat scale = zoomModel.parentWidth / zoomModel.parentHeight; // 讲师端放大区域宽高比
    CGSize selfSize = self.originalSize;
    CGFloat propHeight = selfSize.width / scale;
    CGFloat propWidth = selfSize.height * scale;
    if (propHeight >= selfSize.height) {
        propHeight = selfSize.height;
    } else {
        propWidth = selfSize.width;
    }
    
    if (!CGSizeEqualToSize(selfSize, CGSizeMake(roundf(propWidth), roundf(propHeight)))) { //避免重复更新
        plv_dispatch_main_async_safe(^{
            self.frame = CGRectMake(0, 0, roundf(propWidth), roundf(propHeight));
        })
    }
}

- (void)setupInLinkMicZoom:(BOOL)inLinkMicZoom userId:(NSString *)userId {
    // 当前连麦列表
    NSArray *userArray = nil;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(linkMicZoomAreaViewGetCurrentUserModelArray:)]) {
        userArray = [self.delegate linkMicZoomAreaViewGetCurrentUserModelArray:self];
    }
    
    if (![PLVFdUtil checkArrayUseable:userArray]) {
        return;
    }
    
    [userArray enumerateObjectsUsingBlock:^(PLVLinkMicOnlineUser *user, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([user.userId isEqualToString:userId]) {
            user.inLinkMicZoom = inLinkMicZoom;
            *stop = YES;
        }
    }];
    
    // 刷新 连麦窗口列表
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(linkMicZoomAreaViewDidReLoadLinkMicUserWindows:)]) {
            [self.delegate linkMicZoomAreaViewDidReLoadLinkMicUserWindows:self];
        }
    })
}

- (BOOL)isInZoomViewWithUserId:(NSString *)userId {
    PLVHCLinkMicZoomModel *zoomModel = [[PLVHCLinkMicZoomModel alloc]init];
    zoomModel.windowId = [zoomModel windowIdWithUserId:userId];
    return [self isInZoomView:zoomModel];
}

- (BOOL)isInZoomView:(PLVHCLinkMicZoomModel *)zoomModel {
    dispatch_semaphore_wait(_zoomAreaViewLock, DISPATCH_TIME_FOREVER);
    __block BOOL isInZoomView = NO;
    NSArray *tempArray = [self.itemArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomItemContainer *itemContainer, NSUInteger idx, BOOL * _Nonnull stop) {
        PLVHCLinkMicZoomModel *tempModel = itemContainer.zoomModel;
        if (tempModel &&
            [tempModel.windowId isEqualToString:zoomModel.windowId]) {
            isInZoomView = YES;
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_zoomAreaViewLock);
    return isInZoomView;
}

/// 通过用户Id找到放大模型
/// @param userId 用户Id
- (PLVHCLinkMicZoomModel *)findZoomModelWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    
    dispatch_semaphore_wait(_zoomAreaViewLock, DISPATCH_TIME_FOREVER);
    __block PLVHCLinkMicZoomModel *localZoomModel = nil;
    NSArray *tempArray = [self.itemArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomItemContainer *itemContainer, NSUInteger idx, BOOL * _Nonnull stop) {
        PLVHCLinkMicZoomModel *tempModel = itemContainer.zoomModel;
        if (tempModel &&
            [tempModel.userId isEqualToString:userId]) {
            localZoomModel = tempModel;
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_zoomAreaViewLock);
    return localZoomModel;
}

/// 【讲师】将窗口添加到连麦放大视图区域或将窗口移动、放大
- (void)zoomWithModel:(PLVHCLinkMicZoomModel *)model externalView:(UIView *)externalView{
    [self setupInLinkMicZoom:YES userId:model.userId]; // 表示在放大区域
    
    PLVHCLinkMicZoomItemContainer *itemContainer = [self createItemContainerWithModel:model];
    [itemContainer displayExternalView:externalView];
    [self addSubview:itemContainer];
    [self.itemArrayM addObject:itemContainer]; // 缓存数据
    
    // 发送socket
    BOOL success = [[PLVHCLinkMicZoomManager sharedInstance] zoomWithModel:model];
    if (!success) { // 发送失败，恢复窗口到连麦列表
        [self setupInLinkMicZoom:NO userId:model.userId];
        [self removeLinkMicItemViewWithZoomModel:model];
    }
}

/// 更新 连麦视图
/// @param itemView 连麦视图
/// @param userId 用户Id
- (void)updateItemView:(PLVHCLinkMicItemView *)itemView userId:(NSString *)userId {
    dispatch_semaphore_wait(_zoomAreaViewLock, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [self.itemArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomItemContainer *itemContainer, NSUInteger idx, BOOL * _Nonnull stop) {
        PLVHCLinkMicZoomModel *tempModel = itemContainer.zoomModel;
        if (tempModel &&
            [tempModel.userId isEqualToString:userId]) {
            plv_dispatch_main_async_safe(^{
                [itemContainer displayExternalView:itemView];
            })
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_zoomAreaViewLock);
}

/// 更新放大窗口视图frame
/// @param zoomModel 窗口数据模型
- (void)updateZoomItemContainerFrameWithZoomModel:(PLVHCLinkMicZoomModel *)zoomModel {
    dispatch_semaphore_wait(_zoomAreaViewLock, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [self.itemArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomItemContainer *itemContainer, NSUInteger idx, BOOL * _Nonnull stop) {
        PLVHCLinkMicZoomModel *tempModel = itemContainer.zoomModel;
        if (tempModel &&
            [tempModel.windowId isEqualToString:zoomModel.windowId]) {
            [tempModel updateWithModel:zoomModel];
            plv_dispatch_main_async_safe(^{
                itemContainer.frame = [self frameConversionWithZoomModel:zoomModel];
                [itemContainer setNeedsLayout];
                [itemContainer layoutIfNeeded];
                [self bringSubviewToFront:itemContainer]; // 置于视图最顶部
            })
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_zoomAreaViewLock);
}

/// 将连麦画面从放大区域移除
/// @param zoomModel 数据模型
- (BOOL)removeLinkMicItemViewWithZoomModel:(PLVHCLinkMicZoomModel *)zoomModel {
    __block BOOL success = NO;
    dispatch_semaphore_wait(_zoomAreaViewLock, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [self.itemArrayM copy];
    [tempArray enumerateObjectsUsingBlock:^(PLVHCLinkMicZoomItemContainer *itemContainer, NSUInteger idx, BOOL * _Nonnull stop) {
        PLVHCLinkMicZoomModel *tempModel = itemContainer.zoomModel;
        if (tempModel &&
            [tempModel.windowId isEqualToString:zoomModel.windowId]) {
            [self.itemArrayM removeObject:itemContainer];
            plv_dispatch_main_async_safe(^{
                [itemContainer removeFromSuperview];
            })
            success = YES;
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_zoomAreaViewLock);
    return success;
}

/// 将连麦画面移到放大区域
/// @param zoomModel 数据模型
- (void)showLinkMicItemViewToZoomWithZoomModel:(PLVHCLinkMicZoomModel *)zoomModel {
    if ([self isInZoomView:zoomModel]) { // 已显示在放大区域 更新frame、视图层级
        [self updateZoomItemContainerFrameWithZoomModel:zoomModel];
    } else { // 未显示 创建视图并添加到放大区域
        // 获取连麦画面
        if (!self.delegate ||
            ![self.delegate respondsToSelector:@selector(linkMicZoomAreaView:getLinkMicItemViewWithUserId:)]) {
            return;
        }
        
        UIView *itemView = [self.delegate linkMicZoomAreaView:self getLinkMicItemViewWithUserId:zoomModel.userId];
        if (!itemView) {
            return;
        }
        
        PLVHCLinkMicZoomItemContainer *itemContainer = [self createItemContainerWithModel:zoomModel];
        [itemContainer displayExternalView:itemView];
        [self addSubview:itemContainer];
        [self.itemArrayM addObject:itemContainer]; // 缓存数据
    }
}

/// 对数组 micSiteDict 进行排序,index越大越靠后,已达到在图层最上部的效果
- (NSArray *)sortMicSiteArray:(NSArray *)micSiteArray {
    dispatch_semaphore_wait(_zoomAreaViewLock, DISPATCH_TIME_FOREVER);
    NSArray *sortedArray = [micSiteArray sortedArrayUsingComparator:^NSComparisonResult(PLVHCLinkMicZoomItemContainer *obj1, PLVHCLinkMicZoomItemContainer *obj2) {
        NSInteger index1 = obj1.zoomModel.index;
        NSInteger index2 = obj2.zoomModel.index;
        if (index1 < index2) {
            return NSOrderedAscending;
        }
        if (index1 > index2) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    dispatch_semaphore_signal(_zoomAreaViewLock);
    return sortedArray;
}

#pragma mark PLVHCLinkMicZoomManagerDelegate

- (void)linkMicZoomManager:(PLVHCLinkMicZoomManager *)linkMicZoomManager didUpdateZoomWithModel:(PLVHCLinkMicZoomModel *)model {
    [self updateZoomWithModel:model];
}

- (void)linkMicZoomManager:(PLVHCLinkMicZoomManager *)linkMicZoomManager didRemoveZoomWithModel:(PLVHCLinkMicZoomModel *)model {
    [self removeZoomWithModel:model];
}


@end
