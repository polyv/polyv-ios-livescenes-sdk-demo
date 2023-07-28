//
//  PLVECLinkMicWindowsView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECLinkMicWindowsView.h"
#import "PLVECLinkMicCanvasView.h"
#import "PLVECLinkMicWindowCell.h"
#import "PLVECLinkMicWindowsSpeakerView.h"
#import "PLVLinkMicOnlineUser+EC.h"
#import "PLVRoomDataManager.h"
#import "PLVECUtils.h"

typedef NS_ENUM(NSInteger, PLVECLinkMicLayoutMode) {
    PLVECLinkMicLayoutModeTiled = 0, //平铺模式
    PLVECLinkMicLayoutModeSpeaker = 1 //主讲模式
};

//连麦窗口宽高比例 横屏 3:2 竖屏2:3
static CGFloat PLVECLinkMicCellAspectRatio = 1.5;
static NSString *kCellIdentifier = @"PLVECLinkMicWindowCellID";

@interface PLVECLinkMicWindowsView ()<
UICollectionViewDataSource,
UICollectionViewDelegate
>

#pragma mark 数据
@property (nonatomic, assign) NSUInteger linkMicUserCount; //连麦用户数量
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> *dataArray; // 只读，当前连麦在线用户数组
@property (nonatomic, assign) PLVECLinkMicLayoutMode linkMicLayoutMode; //当前连麦布局模式 (默认为平铺模式)
@property (nonatomic, copy) NSString *currentSpeakerLinkMicUserId; //当前显示主讲用户的连麦id[布局模式切换时缓存此id]
@property (nonatomic, assign) NSInteger currentSpeakerUserIndex; // 当前主讲用户在数据中的下标
@property (nonatomic, assign) BOOL externalNoDelayPaused;   // 外部的 ‘无延迟播放’ 是否已暂停

#pragma mark UI
/// view hierarchy
///
/// (PLVECLinkMicWindowsView) self
///    ├─  (UICollectionView) collectionView
///    └─  (PLVECLinkMicWindowsSpeakerView) speakerView
@property (nonatomic, strong) UICollectionView *collectionView; // 连麦窗口集合视图
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *collectionViewLayout; // 集合视图的布局
@property (nonatomic, strong) PLVECLinkMicWindowsSpeakerView *speakerView; // 主讲模式下的第一画面
@property (nonatomic, weak) UIView *firstSiteCanvasView; // 连麦第一画面Canvas视图
@property (nonatomic, strong) UILabel *linkMicStatusLabel;       // 连麦状态文本框 (负责展示 连麦状态)

@end

@implementation PLVECLinkMicWindowsView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.collectionView];
        [self addSubview:self.speakerView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.safeAreaInsets;
    }
    CGFloat top = safeAreaInsets.top;
    CGFloat bottom = safeAreaInsets.bottom;
    CGFloat left = 0;
    CGFloat right = 0;
    CGFloat windowsViewWidth = self.bounds.size.width;
    CGFloat windowsViewHeight = self.bounds.size.height;
    CGFloat collectionViewX = left;
    CGFloat collectionViewY = top;

    if (self.linkMicUserCount <= 1) { //连麦人数1人以下,且不需要显示讲师讲师占位图
        self.collectionView.frame = self.bounds;
    } else {
        CGFloat collectionViewWidth = windowsViewWidth - collectionViewX - right;
        CGFloat collectionViewHeight = windowsViewHeight - collectionViewY - bottom;
        
        collectionViewY = top + (isPad ? 92 : 78);
        collectionViewHeight = windowsViewHeight - collectionViewY - bottom;
        if (self.linkMicLayoutMode == PLVECLinkMicLayoutModeTiled) { //平铺模式
            if (self.linkMicUserCount <= 4) {
                collectionViewHeight = MIN(collectionViewWidth * PLVECLinkMicCellAspectRatio, collectionViewHeight);
            }
        } else { //主讲模式
            collectionViewX = windowsViewWidth * 0.75;
            collectionViewWidth = windowsViewWidth * 0.25;
            CGFloat speakerViewWidth = windowsViewWidth - collectionViewWidth;
            CGFloat speakerViewHeight = isPad ? speakerViewWidth * 1.4 :  speakerViewWidth * PLVECLinkMicCellAspectRatio;
            self.speakerView.frame = CGRectMake(0, collectionViewY, speakerViewWidth, speakerViewHeight);
        }
        
        self.collectionView.frame = CGRectMake(collectionViewX, collectionViewY, floor(collectionViewWidth), floor(collectionViewHeight));
    }
    self.collectionView.contentOffset = CGPointZero;
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:YES];
}

#pragma mark - [ Public Method ]

- (void)reloadLinkMicUserWindows {
    NSUInteger count = self.dataArray.count;
    if (self.linkMicUserCount != count ) {
        self.linkMicUserCount = count;
        [self setNeedsLayout];
    }
    if (self.linkMicLayoutMode == PLVECLinkMicLayoutModeSpeaker) {
        [self updateSpeakerView];
    }
    
    [self setupFirstSiteCanvasViewWithUserId:self.currentSpeakerLinkMicUserId];

    [self.collectionView reloadData];
}

- (void)refreshAllLinkMicCanvasPauseImageView:(BOOL)noDelayPaused {
    _externalNoDelayPaused = noDelayPaused;
    for (PLVLinkMicOnlineUser * onlineUser in self.dataArray) {
        [onlineUser.canvasView pauseWatchNoDelayImageViewShow:noDelayPaused];
    }
}

- (void)updateFirstSiteCanvasViewWithUserId:(NSString *)linkMicUserId {
    if (![PLVFdUtil checkStringUseable:linkMicUserId]) {
        return;
    }
 
    [self setupFirstSiteCanvasViewWithUserId:linkMicUserId];
    if (self.linkMicLayoutMode == PLVECLinkMicLayoutModeSpeaker) {
        [self updateSpeakerView];
    }
    [self.collectionView reloadData];
}

- (void)switchLinkMicWindowsLayoutSpeakerMode:(BOOL)speakerMode {
    PLVECLinkMicLayoutMode layoutMode = speakerMode ? PLVECLinkMicLayoutModeSpeaker : PLVECLinkMicLayoutModeTiled;
    if (layoutMode == PLVECLinkMicLayoutModeSpeaker) {
        [self updateSpeakerView];
    } else {
        [self cleanSpeakerView];
    }
    if (self.linkMicLayoutMode != layoutMode) {
        self.linkMicLayoutMode = layoutMode;
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    [self.collectionView reloadData];
}

#pragma mark - [ Private Method ]

/// 根据连麦列表视图下标 获取在线用户model [经过业务逻辑处理 与 dataArray 数据并不对应]
- (PLVLinkMicOnlineUser *)onlineUserWithIndex:(NSInteger)targetIndex {
    NSInteger index = [self indexWithTargetIndex:targetIndex];
    return [self readUserModelFromDataArray:index];
}

/// 将cell的下标 转换为在dataArray 数据中对应需要显示的坐标
- (NSInteger)indexWithTargetIndex:(NSInteger)targetIndex {
    if (self.currentSpeakerUserIndex > -1) {
        if (self.linkMicLayoutMode == PLVECLinkMicLayoutModeSpeaker) {
            if (targetIndex >= self.currentSpeakerUserIndex && self.linkMicUserCount != 1) {
                targetIndex++;
            }
        }
    }
    return targetIndex;
}

/// 从 dataArray 的对应 targetIndex 获取在线用户
- (PLVLinkMicOnlineUser *)readUserModelFromDataArray:(NSInteger)targetIndex{
    PLVLinkMicOnlineUser *onlineUser;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserInLinkMicWindowsView:withTargetIndex:)]) {
        onlineUser = [self.delegate onlineUserInLinkMicWindowsView:self withTargetIndex:targetIndex];
    }
    return onlineUser;
}

- (NSInteger)findCellIndexWithUserId:(NSString *)userId{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(onlineUserIndexInLinkMicWindowsView:filterBlock:)]) {
        targetUserIndex = [self.delegate onlineUserIndexInLinkMicWindowsView:self filterBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            if ([enumerateUser.linkMicUserId isEqualToString:userId] || [enumerateUser.userId isEqualToString:userId]) { return YES; }
            return NO;
        }];
    }
    return targetUserIndex;
}

- (NSInteger)findCellIndexWithMainSpeakerUser{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(onlineUserIndexInLinkMicWindowsView:filterBlock:)]) {
        targetUserIndex = [self.delegate onlineUserIndexInLinkMicWindowsView:self filterBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            return enumerateUser.isRealMainSpeaker;
        }];
    }
    return targetUserIndex;
}

- (PLVECLinkMicWindowCell *)getWindowCellWithIndex:(NSInteger)cellIndex{
    PLVECLinkMicWindowCell * cell;
    if (cellIndex >= 0) {
        cell = (PLVECLinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:0]];
    }
    return cell;
}

/// 若连麦用户Model未有连麦rtc画布视图，则此时需创建并交由连麦用户Model进行管理
- (void)setupLinkMicCanvasViewWithOnlineUser:(PLVLinkMicOnlineUser *)aOnlineUser {
    if (!aOnlineUser.canvasView) {
        PLVECLinkMicCanvasView *canvasView = [[PLVECLinkMicCanvasView alloc] init];
        [canvasView addRTCView:aOnlineUser.rtcView];
        [canvasView pauseWatchNoDelayImageViewShow:self.externalNoDelayPaused];
        aOnlineUser.canvasView = canvasView;
        aOnlineUser.networkQualityChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if (onlineUser.canvasView) {
                [onlineUser.canvasView updateNetworkQualityImageViewWithStatus:onlineUser.currentNetworkQuality];
            }
        };
    }
}

/// 设置连麦用户model的’即将销毁Block‘，用于在连麦用户退出时及时回收资源
- (void)setupWillDeallocBlockWithOnlineUser:(PLVLinkMicOnlineUser *)aOnlineUser {
    __weak typeof(self) weakSelf = self;
    aOnlineUser.willDeallocBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        PLVECLinkMicCanvasView *canvasView = onlineUser.canvasView;
        NSString * didLeftLinkMicUserId = onlineUser.linkMicUserId;
        dispatch_async(dispatch_get_main_queue(), ^{ // 回收资源
            if ([didLeftLinkMicUserId isEqualToString:weakSelf.currentSpeakerLinkMicUserId]) {
                /// 连麦用户销毁时，清理第一画面视图资源
                [weakSelf cleanSpeakerView];
            }
            [canvasView removeRTCView];
            [canvasView removeFromSuperview];
        });
    };
}

- (void)updateSpeakerView {
    if (self.linkMicUserCount <= 1) {
        [self cleanSpeakerView];
        return;
    }
    
    NSString *linkMicUserId = self.currentSpeakerLinkMicUserId;
    if (![PLVFdUtil checkStringUseable:linkMicUserId]) { //当linkMicUserId为空时设置连麦在线用户数组第一个用户为主讲用户
        PLVLinkMicOnlineUser *firstOnlineUser = self.dataArray.firstObject;
        linkMicUserId = firstOnlineUser.linkMicUserId;
    }
    
    self.currentSpeakerUserIndex = -1;
    NSInteger indexRow = [self findCellIndexWithUserId:linkMicUserId];
    PLVLinkMicOnlineUser *firstSiteOnlineUser = [self onlineUserWithIndex:indexRow];
    if (firstSiteOnlineUser) {
        self.currentSpeakerLinkMicUserId = linkMicUserId;
        self.currentSpeakerUserIndex = indexRow;
        [self setupLinkMicCanvasViewWithOnlineUser:firstSiteOnlineUser];
        [self setupWillDeallocBlockWithOnlineUser:firstSiteOnlineUser];
        [self.speakerView showSpeakerViewWithUserModel:firstSiteOnlineUser];
    }
}

- (void)cleanSpeakerView {
    [self.speakerView hideSpeakerView];
}

// 设置第一画面相关数据
- (void)setupFirstSiteCanvasViewWithUserId:(NSString *)linkMicUserId {
    NSInteger linkMicUserIndex = [self findCellIndexWithUserId:linkMicUserId];
    PLVLinkMicOnlineUser *firstSiteUserModel;
    if (![PLVFdUtil checkStringUseable:linkMicUserId] || linkMicUserIndex < 0) {
        linkMicUserIndex = [self findCellIndexWithMainSpeakerUser];
    }
    firstSiteUserModel = [self readUserModelFromDataArray:linkMicUserIndex];
    self.currentSpeakerLinkMicUserId = firstSiteUserModel.linkMicUserId;
    self.currentSpeakerUserIndex = linkMicUserIndex;
    [self setupLinkMicCanvasViewWithOnlineUser:firstSiteUserModel];
    [self setupWillDeallocBlockWithOnlineUser:firstSiteUserModel];
    self.firstSiteCanvasView = firstSiteUserModel.canvasView;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(currentFirstSiteCanvasViewChangedInLinkMicWindowsView:)]) {
        [self.delegate currentFirstSiteCanvasViewChangedInLinkMicWindowsView:self];
    }
}

#pragma mark Getter & Setter

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray {
    if (self.delegate) {
        return [self.delegate currentOnlineUserListInLinkMicWindowsView:self];
    } else {
        return nil;
    }
}

- (UICollectionViewFlowLayout *)collectionViewLayout {
    return ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout);
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        layout.headerReferenceSize = CGSizeZero;
        layout.footerReferenceSize = CGSizeZero;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        [_collectionView registerClass:[PLVECLinkMicWindowCell class] forCellWithReuseIdentifier:kCellIdentifier];
    }
    return _collectionView;
}

- (PLVECLinkMicWindowsSpeakerView *)speakerView {
    if (!_speakerView) {
        _speakerView = [[PLVECLinkMicWindowsSpeakerView alloc] init];
    }
    return _speakerView;
}

#pragma mark - [ Delegate ]

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger dataNum = self.linkMicUserCount;
    if (self.linkMicLayoutMode == PLVECLinkMicLayoutModeSpeaker) {
        NSInteger finalCellNum = (dataNum - 1) <= 0 ? 1 : (dataNum - 1);
        return finalCellNum; /// 主讲模式下，主讲用户不需在连麦窗口列表中显示窗口
    }
    return dataNum;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLinkMicOnlineUser *onlineUser = [self onlineUserWithIndex:indexPath.row];
    if (!onlineUser) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    }
    [self setupLinkMicCanvasViewWithOnlineUser:onlineUser];
    [self setupWillDeallocBlockWithOnlineUser:onlineUser];
    
    PLVECLinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    // 连麦人数为1时不显示占位图的情况下，不显示昵称且关闭摄像头时不显示canvasView
    BOOL hideCanvasView = (self.linkMicUserCount == 1);
    [cell setUserModel:onlineUser hideCanvasViewWhenCameraClose:hideCanvasView];
    
    if (onlineUser.isRealMainSpeaker) {
        self.firstSiteCanvasView = onlineUser.canvasView;
    }
    
    return cell;
}

#pragma mark UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat collectionViewWidth = self.collectionView.bounds.size.width;
    CGFloat collectionViewHeigth = self.collectionView.bounds.size.height;
    CGFloat collectionCellWidth = collectionViewWidth;
    CGFloat collectionCellHeigth = collectionViewHeigth;
    if (self.linkMicUserCount <= 1) {
        return CGSizeMake(collectionCellWidth, collectionCellHeigth);
    }
    
    if (self.linkMicLayoutMode == PLVECLinkMicLayoutModeTiled) {
        if ((isPad && self.linkMicUserCount <= 2) ||
            (!isPad && self.linkMicUserCount <= 4)) {
            collectionCellWidth = collectionViewWidth / 2;
        } else {
            collectionCellWidth = collectionViewWidth / 3;
        }
    }
    collectionCellHeigth = collectionCellWidth * PLVECLinkMicCellAspectRatio;
    
    return CGSizeMake(collectionCellWidth, collectionCellHeigth);
}

@end
