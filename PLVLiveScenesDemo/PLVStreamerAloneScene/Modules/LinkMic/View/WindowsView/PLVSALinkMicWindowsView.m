//
//  PLVSALinkMicWindowsView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicWindowsView.h"
#import "PLVSALinkMicCanvasView.h"
#import "PLVSALinkMicWindowCell.h"
#import "PLVLinkMicOnlineUser+SA.h"
#import "PLVSAUtils.h"
#import "PLVRoomDataManager.h"

static NSString *kCellIdentifier = @"PLVSALinkMicWindowCellID";

@interface PLVSALinkMicWindowsView ()<
UICollectionViewDataSource,
UICollectionViewDelegate
>

#pragma mark 数据
@property (nonatomic, assign) NSUInteger showLinkMicUserCount;
@property (nonatomic, strong, readonly) PLVLinkMicOnlineUser *localOnlineUser; // 只读，本地用户
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> *dataArray; // 只读，当前连麦在线用户数组

#pragma mark UI
/// view hierarchy
///
/// (PLVSALinkMicWindowsView) self
///    └─ (UICollectionView) collectionView (lowest)
@property (nonatomic, strong) UICollectionView *collectionView;  // 连麦窗口集合视图
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *collectionViewLayout; // 集合视图的布局

@end

@implementation PLVSALinkMicWindowsView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.showLinkMicUserCount <= 1) {
        self.collectionView.frame = self.bounds;
    } else {
        CGFloat top = [PLVSAUtils sharedUtils].areaInsets.top;
        self.collectionView.frame = CGRectMake(0, top + 78, self.bounds.size.width, 280);
    }
    
    self.collectionView.contentOffset = CGPointZero;
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:YES];
}

#pragma mark - [ Public Method ]

- (void)reloadLinkMicUserWindows {
    NSUInteger count = MIN(self.dataArray.count, 2);
    if (self.showLinkMicUserCount != count) {
        self.showLinkMicUserCount = count;
        [self setNeedsLayout];
    }
    [self.collectionView reloadData];
}

#pragma mark - [ Private Method ]

/// 根据下标值获取对应连麦用户model
- (PLVLinkMicOnlineUser *)onlineUserWithIndex:(NSInteger)index {
    PLVLinkMicOnlineUser *onlineUser = nil;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserInLinkMicWindowsView:withTargetIndex:)]) {
        onlineUser = [self.delegate onlineUserInLinkMicWindowsView:self withTargetIndex:index];
    }
    return onlineUser;
}

/// 若连麦用户Model未有连麦rtc画布视图，则此时需创建并交由连麦用户Model进行管理
- (void)setupLinkMicCanvasViewWithOnlineUser:(PLVLinkMicOnlineUser *)aOnlineUser {
    if (!aOnlineUser.canvasView) {
        PLVSALinkMicCanvasView *canvasView = [[PLVSALinkMicCanvasView alloc] init];
        [canvasView addRTCView:aOnlineUser.rtcView];
        aOnlineUser.canvasView = canvasView;
    }
}

// 设置连麦用户model的’即将销毁Block‘，用于在连麦用户退出时及时回收资源
- (void)setupWillDeallocBlockWithOnlineUser:(PLVLinkMicOnlineUser *)aOnlineUser {
    aOnlineUser.willDeallocBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        PLVSALinkMicCanvasView *canvasView = onlineUser.canvasView;
        dispatch_async(dispatch_get_main_queue(), ^{ // 回收资源
            [canvasView removeRTCView];
            [canvasView removeFromSuperview];
        });
    };
}

#pragma mark Initialize

- (void)setupUI {
    [self addSubview:self.collectionView];
}

#pragma mark Getter & Setter

- (PLVLinkMicOnlineUser *)localOnlineUser {
    if (self.delegate) {
        return [self.delegate localUserInLinkMicWindowsView:self];
    } else {
        return nil;
    }
}

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray {
    if (self.delegate) {
        return [self.delegate currentOnlineUserListInLinkMicWindowsView:self];
    } else {
        return nil;
    }
}

- (UICollectionViewFlowLayout *)collectionViewLayout {
    return ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout);
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
        _collectionView.scrollEnabled = NO;
        
        [_collectionView registerClass:[PLVSALinkMicWindowCell class] forCellWithReuseIdentifier:kCellIdentifier];
    }
    return _collectionView;
}

#pragma mark 工具
- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

#pragma mark - [ Delegate ]

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger dataArrayCount = self.dataArray.count;
    self.showLinkMicUserCount = MAX(1, MIN(dataArrayCount, 2));
    return self.showLinkMicUserCount;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLinkMicOnlineUser *onlineUser = nil;
    if (indexPath.row == 0) { // 讲师个人RTC流窗口
        onlineUser = self.localOnlineUser;
    } else {
        onlineUser = [self onlineUserWithIndex:indexPath.row];
    }
    if (!onlineUser) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    }
    [self setupLinkMicCanvasViewWithOnlineUser:onlineUser];
    [self setupWillDeallocBlockWithOnlineUser:onlineUser];
    
    PLVSALinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    // 未连麦时，关闭摄像头不显示canvasView
    [cell setUserModel:onlineUser hideCanvasViewWhenCameraClose:self.showLinkMicUserCount == 1];
    return cell;
}

#pragma mark UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.showLinkMicUserCount <= 1) {
        return self.bounds.size;
    } else {
        return CGSizeMake(self.bounds.size.width / 2.0, 280);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return;
    }
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(linkMicWindowsView:didSelectOnlineUser:)]) {
        PLVLinkMicOnlineUser *onlineUser = [self onlineUserWithIndex:indexPath.row];  
        [self.delegate linkMicWindowsView:self didSelectOnlineUser:onlineUser];
    }
}

@end
