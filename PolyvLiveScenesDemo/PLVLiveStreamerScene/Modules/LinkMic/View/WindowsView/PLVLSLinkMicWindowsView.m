//
//  PLVLSLinkMicWindowsView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicWindowsView.h"
#import "PLVLSLinkMicPreviewView.h"

#import "PLVLSUtils.h"
#import "PLVRoomDataManager.h"
#import "PLVLinkMicOnlineUser+LS.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSLinkMicWindowsView ()<
UICollectionViewDataSource,
UICollectionViewDelegate,
PLVLSLinkMicPreviewViewDelegate
>

#pragma mark 数据
@property (nonatomic, readonly) NSArray <PLVLinkMicOnlineUser *> * dataArray; // 只读，当前连麦在线用户数组
@property (nonatomic, copy) void (^collectionReloadBlock) (void);
@property (nonatomic, strong) NSIndexPath * showingExternalCellIndexPath; // 正在显示外部视图的Cell，所对应的下标
@property (nonatomic, copy) NSString * showingExternalCellLinkMicUserId;  // 正在显示外部视图的Cell，所对应的用户Id (将用于更新 showingExternalCellIndexPath 属性)
@property (nonatomic, copy) NSString * firstSiteLinkMicUserId; // 当前第一画面用户id(目前第一画面为主讲用户或者讲师)
@property (nonatomic, assign) NSInteger firstSiteUserIndex; // 第一画面用户数据对应的下标
@property (nonatomic, strong) PLVLSLinkMicWindowCell *externalCell; // 当前外部cell

#pragma mark UI
/// view hierarchy
///
/// (PLVLSLinkMicWindowsView) self
/// └── (UICollectionView) collectionView (lowest)
///     ├── (PLVLSLinkMicWindowCell) windowCell
///     ├── ...
///     └── (PLVLSLinkMicWindowCell) windowCell
@property (nonatomic, weak) UIView * externalView; // 外部视图 (正在被显示在 PLVLSLinkMicWindowsView 窗口列表中的外部视图；弱引用)
@property (nonatomic, readonly) UICollectionViewFlowLayout * collectionViewLayout; // 集合视图的布局
@property (nonatomic, strong) UICollectionView * collectionView;  // 背景视图 (负责承载 windowCell；负责展示 背景底色；具备宫格样式的改动潜能)
@property (nonatomic, strong) PLVLSLinkMicPreviewView * linkMicPreView; // 连麦预览图

@end

@implementation PLVLSLinkMicWindowsView

#pragma mark - [ Life Period ]
- (void)dealloc{
    PLV_LOG_INFO(PLVConsoleLogModuleTypeLinkMic,@"%s",__FUNCTION__);
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
    [self setupFirstSiteWindowCellWithUserId:self.firstSiteLinkMicUserId];

    if (!CGRectGetHeight(self.bounds) && finalCellNum > 0) {
        __weak typeof(self) weakSelf = self;
        self.collectionReloadBlock = ^{
            [weakSelf.collectionView reloadData];
        };
    }else{
        [self.collectionView reloadData];
    }
}

- (void)updateFirstSiteWindowCellWithUserId:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite {
    if (![PLVFdUtil checkStringUseable:linkMicUserId]) {
        return;
    }
    
    if (!toFirstSite) {
        if ([self.firstSiteLinkMicUserId isEqualToString:linkMicUserId]) {
            linkMicUserId = nil;
        } else {
            return;
        }
    }
    
    [self setupFirstSiteWindowCellWithUserId:linkMicUserId];
    [self.collectionView reloadData];
}

- (void)firstSiteWindowCellExchangeWithExternal:(UIView *)externalView {
    // 主副屏切换时会固定 同第一画面 视图切换
    NSInteger targetCellIndex = 0;
    PLVLinkMicOnlineUser * linkMicUserModel = [self onlineUserWithIndex:targetCellIndex];
    NSInteger cellNumber = [self.collectionView numberOfItemsInSection:0];
    self.showingExternalCellLinkMicUserId = linkMicUserModel.linkMicUserId;
    self.externalView = externalView;
    if (cellNumber > targetCellIndex) {
        NSIndexPath * targetCellIndexPath = [NSIndexPath indexPathForRow:targetCellIndex inSection:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadItemsAtIndexPaths:@[targetCellIndexPath]];
        });
    }
    [self callbackForShowFirstSiteUserOnExternal:linkMicUserModel];
}

- (void)rollbackFirstSiteWindowCellAndExternalView {
    NSIndexPath *oriIndexPath = self.showingExternalCellIndexPath;
    [self rollbackExternalView];
    [self rollbackLinkMicCanvasView:oriIndexPath];
}

- (void)updateLocalUserLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus {
    if (linkMicStatus == PLVLinkMicUserLinkMicStatus_Inviting) {
        self.linkMicPreView.isOnlyAudio = [PLVRoomDataManager sharedManager].roomData.isOnlyAudio;
        [self.linkMicPreView showLinkMicPreviewView:YES];
        UIView *superview = self.superview.superview;
        if (superview) {
            [superview addSubview:self.linkMicPreView];
            [superview bringSubviewToFront:self.linkMicPreView];
        }
    }
}

- (void)finishClass {
    [self.linkMicPreView showLinkMicPreviewView:NO];
}

- (void)updateAllCellLinkMicDuration {
    NSArray *cells = self.collectionView.visibleCells;
    for (PLVLSLinkMicWindowCell * cell in cells) {
        [cell updateLinkMicDuration:YES];
    }
    [self.externalCell updateLinkMicDuration:YES];
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

- (NSInteger)findCellIndexWithMainSpeakerUser{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        targetUserIndex = [self.delegate plvLSLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            return enumerateUser.isRealMainSpeaker;
        }];
    }
    return targetUserIndex;
}

/// 根据连麦列表视图下标 获取在线用户model [经过业务逻辑处理 与 dataArray 数据并不对应]
- (PLVLinkMicOnlineUser *)onlineUserWithIndex:(NSInteger)targetIndex {
    if (self.firstSiteUserIndex > -1) {
        if (targetIndex == 0) {
            targetIndex = self.firstSiteUserIndex;
        } else if (targetIndex <= self.firstSiteUserIndex){
            targetIndex --;
        }
    }
    
    return [self readUserModelFromDataArray:targetIndex];
}

- (PLVLSLinkMicWindowCell *)getWindowCellWithIndex:(NSInteger)cellIndex{
    PLVLSLinkMicWindowCell * cell;
    if (cellIndex >= 0) { cell = (PLVLSLinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:0]]; }
    if (!cell) { PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLCLinkMicWindowsView - cell find failed"); }
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
    __weak typeof(self) weakSelf = self;
    PLVLSLinkMicCanvasView * canvasView = didLeftLinkMicUser.canvasView;
    NSString * didLeftLinkMicUserId = didLeftLinkMicUser.linkMicUserId;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([didLeftLinkMicUserId isEqualToString:weakSelf.showingExternalCellLinkMicUserId]) {
            /// 此连麦用户对应的rtc小窗，正在展示外部视图，需回滚恢复至原位
            [weakSelf rollbackExternalView];
        }
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

// 设置第一画面相关数据
- (void)setupFirstSiteWindowCellWithUserId:(NSString *)linkMicUserId {
    NSInteger linkMicUserIndex = [self findCellIndexWithUserId:linkMicUserId];
    PLVLinkMicOnlineUser *firstSiteUserModel;
    if (![PLVFdUtil checkStringUseable:linkMicUserId] || linkMicUserIndex < 0) {
        linkMicUserIndex = [self findCellIndexWithMainSpeakerUser];
    }
    firstSiteUserModel = [self readUserModelFromDataArray:linkMicUserIndex];
    self.firstSiteLinkMicUserId = firstSiteUserModel.linkMicUserId;
    self.firstSiteUserIndex = linkMicUserIndex;

    if (!firstSiteUserModel) {
        firstSiteUserModel = self.dataArray.firstObject;
    }
    
    if ([PLVFdUtil checkStringUseable:self.showingExternalCellLinkMicUserId]) {
        // 替换外部展示的第一画面
        self.showingExternalCellLinkMicUserId = firstSiteUserModel.linkMicUserId;
        [self callbackForShowFirstSiteUserOnExternal:firstSiteUserModel];
    }
}

- (void)rollbackExternalView {
    // 告知外部对象，进行视图位置回退、恢复
    if (self.externalView) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:rollbackExternalView:)]) {
            [self.delegate plvLSLinkMicWindowsView:self rollbackExternalView:self.externalView];
        }
        self.showingExternalCellIndexPath = nil;
        self.showingExternalCellLinkMicUserId = nil;
        self.externalView = nil;
    }
}

- (void)rollbackLinkMicCanvasView:(NSIndexPath *)oriIndexPath{
    PLVLinkMicOnlineUser *oriUserModel = [self onlineUserWithIndex:oriIndexPath.row];
    if (oriUserModel){
        // 将播放画布视图恢复至默认位置
        PLVLSLinkMicWindowCell * showingExternalCell = (PLVLSLinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:oriIndexPath];
        [showingExternalCell switchToShowRtcContentView:oriUserModel.canvasView];
    } else {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLSLinkMicWindowsView - rollbackLinkMicCanvasView failed, oriIndexPath %@ can't get userModel",oriIndexPath);
    }
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
        
        NSString * identifier = [NSString stringWithFormat:@"PLVLSLinkMicWindowCellID"];
        [_collectionView registerClass:[PLVLSLinkMicWindowCell class] forCellWithReuseIdentifier:identifier];
    }
    return _collectionView;
}

- (UICollectionViewFlowLayout *)collectionViewLayout{
    return ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout);
}

- (PLVLSLinkMicPreviewView *)linkMicPreView {
    if(!_linkMicPreView) {
        _linkMicPreView = [[PLVLSLinkMicPreviewView alloc] init];
        _linkMicPreView.delegate = self;
    }
    return _linkMicPreView;
}

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray{
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsViewGetCurrentUserModelArray:)]) {
        return [self.delegate plvLSLinkMicWindowsViewGetCurrentUserModelArray:self];
    }
    return nil;
}

- (PLVLinkMicOnlineUser *)findLocalOnlineUser{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        targetUserIndex = [self.delegate plvLSLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            if (enumerateUser.localUser) { return YES; }
            return NO;
        }];
    }
    return [self readUserModelFromDataArray:targetUserIndex];
}

#pragma mark Callback

- (void)callbackForShowFirstSiteUserOnExternal:(PLVLinkMicOnlineUser *)linkMicUser{
    PLVLSLinkMicWindowCell *externalCell = [[PLVLSLinkMicWindowCell alloc] init];
    [self checkUserModelAndSetupLinkMicCanvasView:linkMicUser];
    [externalCell setModel:linkMicUser];
    [externalCell switchToShowRtcContentView:linkMicUser.canvasView];
    [externalCell updateLinkMicDuration:linkMicUser.userType != PLVRoomUserTypeTeacher && [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher];
    self.externalCell = externalCell;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:showFirstSiteWindowCellOnExternal:)]) {
        [self.delegate plvLSLinkMicWindowsView:self showFirstSiteWindowCellOnExternal:externalCell];
    }
}

- (void)callbackForAcceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:acceptLinkMicInvitation:timeoutCancel:)]) {
        [self.delegate plvLSLinkMicWindowsView:self acceptLinkMicInvitation:accept timeoutCancel:timeoutCancel];
    }
}

#pragma mark - [ Delegate ]
#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger dataNum = self.dataArray.count;
    return dataNum;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    BOOL thisCellShowingExternalView = NO;
    PLVLinkMicOnlineUser * linkMicUserModel = [self onlineUserWithIndex:indexPath.row];
    if (!linkMicUserModel) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLCLinkMicWindowsView - cellForItemAtIndexPath for %@ error",indexPath);
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVLSLinkMicWindowCellID" forIndexPath:indexPath];
    }
    
    [self checkUserModelAndSetupLinkMicCanvasView:linkMicUserModel];
    [self setupUserModelWillDeallocBlock:linkMicUserModel];
    
    // 若两值一致，则表示此 Cell 将需要展示外部视图，此时应更新 showingExternalCellIndexPath
    if ([self.showingExternalCellLinkMicUserId isEqualToString:linkMicUserModel.linkMicUserId]) {
        self.showingExternalCellIndexPath = indexPath;
        thisCellShowingExternalView = YES;
    }
    
    PLVLSLinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVLSLinkMicWindowCellID" forIndexPath:indexPath];
    [cell setModel:linkMicUserModel];
    
    // 在 [selModel:showingExternalCell:] 调用完毕后，再次将所需视图，加载在对应Cell上
    if (thisCellShowingExternalView) {
        /// 显示 外部视图
        [cell switchToShowExternalContentView:self.externalView];
    }else{
        /// 显示 rtc画布视图
        [cell switchToShowRtcContentView:linkMicUserModel.canvasView];
    }

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
        itemSize = CGSizeMake(160.0,90.0);
    }
    return itemSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (!indexPath) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLSLinkMicWindowsView - didSelectItemAtIndexPath error, indexPath:%@ illegal",indexPath);
        return;
    }
    
    PLVLinkMicOnlineUser * currentTapUserModel = [self readUserModelFromDataArray:indexPath.row];
    if (!currentTapUserModel) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLSLinkMicWindowsView - didSelectItemAtIndexPath error, indexPath:%@ can't get userModel",indexPath);
        return;
    }
}

#pragma mark PLVLSLinkMicPreviewViewDelegate
- (void)plvLSLinkMicPreviewViewAcceptLinkMicInvitation:(PLVLSLinkMicPreviewView *)linkMicPreView {
    PLVLinkMicOnlineUser *localUser = [self findLocalOnlineUser];
    [localUser wantOpenUserMic:self.linkMicPreView.micOpen];
    [localUser wantOpenUserCamera:self.linkMicPreView.cameraOpen];
    [self callbackForAcceptLinkMicInvitation:YES timeoutCancel:NO];
}

- (void)plvLSLinkMicPreviewView:(PLVLSLinkMicPreviewView *)linkMicPreView cancelLinkMicInvitationReason:(PLVLSCancelLinkMicInvitationReason)reason {
    [self callbackForAcceptLinkMicInvitation:NO timeoutCancel:reason == PLVLSCancelLinkMicInvitationReason_Timeout];
}

- (void)plvLSLinkMicPreviewView:(PLVLSLinkMicPreviewView *)linkMicPreView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLSLinkMicWindowsView:inviteLinkMicTTL:)]) {
        [self.delegate plvLSLinkMicWindowsView:self inviteLinkMicTTL:callback];
    }
}

@end
