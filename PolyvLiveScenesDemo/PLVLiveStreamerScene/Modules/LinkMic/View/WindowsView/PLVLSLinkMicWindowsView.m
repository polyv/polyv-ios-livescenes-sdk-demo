//
//  PLVLSLinkMicWindowsView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicWindowsView.h"

#import "PLVLSUtils.h"
#import "PLVLSLinkMicWindowCell.h"
#import "PLVLinkMicOnlineUser+LS.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSLinkMicWindowsView ()<
UICollectionViewDataSource,
UICollectionViewDelegate
>

#pragma mark 数据
@property (nonatomic, readonly) NSArray <PLVLinkMicOnlineUser *> * dataArray; // 只读，当前连麦在线用户数组
@property (nonatomic, copy) void (^collectionReloadBlock) (void);
@property (nonatomic, copy) NSString * currentMainSpeakerUserId;
@property (nonatomic, copy) NSString * manualSwitchMainSpeakerUserId; // 当前由用户触发的、切去主屏显示的、成为第一画面的用户连麦id

#pragma mark UI
@property (nonatomic, weak) UIView * externalView; // 外部视图 (正在被显示在 PLVLCLinkMicWindowsView 窗口列表中的外部视图；弱引用)
@property (nonatomic, readonly) UICollectionViewFlowLayout * collectionViewLayout; // 集合视图的布局

/// view hierarchy
///
/// (PLVLCLinkMicWindowsView) self
/// └── (UICollectionView) collectionView (lowest)
///     ├── (PLVLCLinkMicWindowCell) windowCell
///     ├── ...
///     └── (PLVLCLinkMicWindowCell) windowCell
@property (nonatomic, strong) UICollectionView * collectionView;  // 背景视图 (负责承载 windowCell；负责展示 背景底色；具备宫格样式的改动潜能)

@end

@implementation PLVLSLinkMicWindowsView

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    CGFloat selfWidth = CGRectGetWidth(self.bounds);
    CGFloat selfHeight = CGRectGetHeight(self.bounds);
    
    // 横屏
    self.collectionView.frame = CGRectMake(0, 0, selfWidth, selfHeight);
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.collectionViewLayout.minimumLineSpacing = 8;
        
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:YES];
    
    if (selfHeight > 0 && self.collectionReloadBlock) {
        self.collectionReloadBlock();
        self.collectionReloadBlock = nil;
    }
}

#pragma mark - [ Public Methods ]
- (void)reloadLinkMicUserWindows{
    NSInteger finalCellNum = self.dataArray.count;

    if (!CGRectGetHeight(self.bounds) && finalCellNum > 0) {
        __weak typeof(self) weakSelf = self;
        self.collectionReloadBlock = ^{
            [weakSelf.collectionView reloadData];
        };
    }else{
        [self.collectionView reloadData];
    }
    
    if ([PLVFdUtil checkArrayUseable:self.dataArray]) {
        self.currentMainSpeakerUserId = self.dataArray.firstObject.linkMicUserId;
    }else{
        self.currentMainSpeakerUserId = nil;
        self.manualSwitchMainSpeakerUserId = nil;
    }
}

#pragma mark - [ Private Methods ]
- (PLVLSLinkMicWindowCell *)findLocalUserCell{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        targetUserIndex = [self.delegate plvLSLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            if (enumerateUser.localUser) { return YES; }
            return NO;
        }];
    }
    return [self getWindowCellWithIndex:targetUserIndex];
}

- (PLVLSLinkMicWindowCell *)findCellWithUserId:(NSString *)userId{
    return [self getWindowCellWithIndex:[self findCellIndexWithUserId:userId]];
}

- (NSInteger)findCellIndexWithUserId:(NSString *)userId{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        targetUserIndex = [self.delegate plvLSLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            if ([enumerateUser.linkMicUserId isEqualToString:userId]) { return YES; }
            return NO;
        }];
    }
    return targetUserIndex;
}

- (PLVLSLinkMicWindowCell *)getWindowCellWithIndex:(NSInteger)cellIndex{
    PLVLSLinkMicWindowCell * cell;
    if (cellIndex >= 0) { cell = (PLVLSLinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:0]]; }
    if (!cell) { NSLog(@"PLVLCLinkMicWindowsView - cell find failed"); }
    return cell;
}

- (PLVLinkMicOnlineUser *)readUserModelFromDataArray:(NSInteger)targetIndex{
    PLVLinkMicOnlineUser * user;
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:getUserModelFromOnlineUserArrayWithIndex:)]) {
        user = [self.delegate plvLSLinkMicWindowsView:self getUserModelFromOnlineUserArrayWithIndex:targetIndex];
    }
    return user;
}

- (void)cleanLinkMicCellWithLinkMicUser:(PLVLinkMicOnlineUser *)didLeftLinkMicUser{
    PLVLSLinkMicCanvasView * canvasView = didLeftLinkMicUser.canvasView;
    dispatch_async(dispatch_get_main_queue(), ^{
        /// 回收资源
        [canvasView removeRTCView];
        [canvasView removeFromSuperview];
    });
}

// 若 连麦用户Model 未有 连麦rtc画布视图，则此时需创建并交由 连麦用户Model 进行管理
- (void)checkUserModelAndSetupLinkMicCanvasView:(PLVLinkMicOnlineUser *)linkMicUserModel{
    if (linkMicUserModel.canvasView == nil) {
        PLVLSLinkMicCanvasView * canvasView = [[PLVLSLinkMicCanvasView alloc] init];
        [canvasView addRTCView:linkMicUserModel.rtcView];
        linkMicUserModel.canvasView = canvasView;
    }
}

// 设置 连麦用户Model的 ’即将销毁Block‘ Block
// 用于在连麦用户退出时，及时回收资源
- (void)setupUserModelWillDeallocBlock:(PLVLinkMicOnlineUser *)linkMicUserModel{
    __weak typeof(self) weakSelf = self;
    linkMicUserModel.willDeallocBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [weakSelf cleanLinkMicCellWithLinkMicUser:onlineUser];
    };
}

#pragma mark UI
- (void)setupUI{
    // 添加 视图
    [self addSubview:self.collectionView];
}

#pragma mark Getter
- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
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
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.alwaysBounceVertical = NO;
        
        NSString * identifier = [NSString stringWithFormat:@"PLVLCLinkMicWindowCellID"];
        [_collectionView registerClass:[PLVLSLinkMicWindowCell class] forCellWithReuseIdentifier:identifier];
    }
    return _collectionView;
}

- (UICollectionViewFlowLayout *)collectionViewLayout{
    return ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout);
}

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray{
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsViewGetCurrentUserModelArray:)]) {
        return [self.delegate plvLSLinkMicWindowsViewGetCurrentUserModelArray:self];
    }
    return nil;
}

#pragma mark - [ Delegate ]
#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger dataNum = self.dataArray.count;
    return dataNum;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    PLVLinkMicOnlineUser * linkMicUserModel = [self readUserModelFromDataArray:indexPath.row];
    if (!linkMicUserModel) {
        NSLog(@"PLVLCLinkMicWindowsView - cellForItemAtIndexPath for %@ error",indexPath);
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVLCLinkMicWindowCellID" forIndexPath:indexPath];
    }
    
    [self checkUserModelAndSetupLinkMicCanvasView:linkMicUserModel];
    [self setupUserModelWillDeallocBlock:linkMicUserModel];
    
    PLVLSLinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVLCLinkMicWindowCellID" forIndexPath:indexPath];
    [cell setModel:linkMicUserModel];
    
    return cell;
}

#pragma mark UICollectionViewDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize itemSize;
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        // 横屏
        CGFloat scale = 160.0 / 90.0;
        itemSize = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds)/scale);
    }else{
        // 竖屏
        itemSize = CGSizeMake(125, CGRectGetHeight(self.bounds));
    }
    return itemSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (!indexPath) {
        NSLog(@"PLVLCLinkMicWindowsView - didSelectItemAtIndexPath error, indexPath:%@ illegal",indexPath);
        return;
    }
    
    PLVLinkMicOnlineUser * currentTapUserModel = [self readUserModelFromDataArray:indexPath.row];
    if (!currentTapUserModel) {
        NSLog(@"PLVLCLinkMicWindowsView - didSelectItemAtIndexPath error, indexPath:%@ can't get userModel",indexPath);
        return;
    }
}

@end
