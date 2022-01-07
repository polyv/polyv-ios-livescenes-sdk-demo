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
#import "PLVSALinkMicGuideView.h"
#import "PLVSALinkMicWindowsSpeakerView.h"
#import "PLVSALinkMicSpeakerPlaceholderView.h"

// 模块
#import "PLVLinkMicOnlineUser+SA.h"
#import "PLVSAUtils.h"
#import "PLVRoomDataManager.h"

typedef NS_ENUM(NSInteger, PLVSALinkMicLayoutMode) {
    PLVSALinkMicLayoutModeTiled = 0, //平铺模式
    PLVSALinkMicLayoutModeSpeaker = 1 //主讲模式
};

//连麦窗口宽高比例 横屏 3:2 竖屏2:3
static CGFloat PLVSALinkMicCellAspectRatio = 1.5;
static NSString *kCellIdentifier = @"PLVSALinkMicWindowCellID";

@interface PLVSALinkMicWindowsView ()<
UICollectionViewDataSource,
UICollectionViewDelegate
>

#pragma mark 数据
@property (nonatomic, assign) NSUInteger linkMicUserCount; //连麦用户数量
@property (nonatomic, strong, readonly) PLVLinkMicOnlineUser *localOnlineUser; // 只读，本地用户
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> *dataArray; // 只读，当前连麦在线用户数组
@property (nonatomic, assign) PLVSALinkMicLayoutMode linkMicLayoutMode; //当前连麦布局模式 (默认为平铺模式)
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;
@property (nonatomic, copy) NSString *currentSpeakerLinkMicUserId; //当前显示主讲用户的连麦id[布局模式切换时缓存此id]
@property (nonatomic, strong) NSIndexPath *showingSpeakerIndexPath; // 主讲显示的画面数据对应本应在collectionView的下标 (仅在讲师角色 PLVSALinkMicLayoutModeSpeaker下有效)

#pragma mark UI
/// view hierarchy
///
/// (PLVSALinkMicWindowsView) self
///    ├─  (UICollectionView) collectionView
///    ├─  (PLVSALinkMicSpeakerPlaceholderView) speakerPlaceholderView
///    └─  (PLVSALinkMicWindowsSpeakerView) speakerView
@property (nonatomic, strong) PLVSALinkMicGuideView *linkMicGuideView; // 连麦新手引导
@property (nonatomic, strong) UICollectionView *collectionView; // 连麦窗口集合视图
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *collectionViewLayout; // 集合视图的布局
@property (nonatomic, strong) PLVSALinkMicWindowsSpeakerView *speakerView; // 主讲模式下的第一画面
@property (nonatomic, strong) PLVSALinkMicSpeakerPlaceholderView *speakerPlaceholderView; // 嘉宾角色登录时 主播的占位图

@end

@implementation PLVSALinkMicWindowsView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.linkMicLayoutMode = PLVSALinkMicLayoutModeTiled;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateSubviewsLayout];
}

#pragma mark - [ Public Method ]

- (void)reloadLinkMicUserWindows {
    if ([self isLocalUserPreviewView]) { //登录后的设置预览页
        self.linkMicUserCount = MIN(1, self.dataArray.count);
        [self.collectionView reloadData];
        return;
    }
    
    NSUInteger count = MAX(1, self.dataArray.count);
    if (self.linkMicUserCount != count || self.linkMicUserCount == 1) {
        self.linkMicUserCount = count;
        [self setNeedsLayout];
    }
    if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker) {
        [self updateSpeakerViewForLinkMicUserId:self.currentSpeakerLinkMicUserId];
    }
    [self.collectionView reloadData];
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showGuideView];
        });
    }
}

- (void)switchLinkMicWindowsLayoutSpeakerMode:(BOOL)speakerMode linkMicWindowMainSpeaker:(NSString * _Nullable)linkMicUserId {
    PLVSALinkMicLayoutMode layoutMode = speakerMode ? PLVSALinkMicLayoutModeSpeaker : PLVSALinkMicLayoutModeTiled;
    if (layoutMode == PLVSALinkMicLayoutModeSpeaker) {
        [self updateSpeakerViewForLinkMicUserId:linkMicUserId];
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

/// 根据下标值获取对应连麦用户model
- (PLVLinkMicOnlineUser *)onlineUserWithIndex:(NSInteger)targetIndex {
    if (self.linkMicUserCount == 1 && targetIndex == 0 &&
        [self isLocalUserPreviewView]) {
        return self.localOnlineUser;
    }
    
    if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker &&
        self.showingSpeakerIndexPath &&
        targetIndex >= self.showingSpeakerIndexPath.row) {
        targetIndex ++;
    }
    PLVLinkMicOnlineUser *onlineUser = nil;
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
            if ([enumerateUser.linkMicUserId isEqualToString:userId]) { return YES; }
            return NO;
        }];
    }
    return targetUserIndex;
}

- (BOOL)isLocalUserPreviewView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(localUserPreviewViewInLinkMicWindowsView:)]) {
        return [self.delegate localUserPreviewViewInLinkMicWindowsView:self];
    }
    return NO;
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
    __weak typeof(self) weakSelf = self;
    aOnlineUser.willDeallocBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        PLVSALinkMicCanvasView *canvasView = onlineUser.canvasView;
        NSString * didLeftLinkMicUserId = onlineUser.linkMicUserId;
        dispatch_async(dispatch_get_main_queue(), ^{ // 回收资源
            if ([didLeftLinkMicUserId isEqualToString:weakSelf.currentSpeakerLinkMicUserId]) {
                /// 连麦用户退出时，清理第一画面视图资源
                [weakSelf cleanSpeakerView];
            }
            [canvasView removeRTCView];
            [canvasView removeFromSuperview];
        });
    };
}

- (void)updateSpeakerViewForLinkMicUserId:(NSString * _Nullable)linkMicUserId {
    if (self.linkMicUserCount <= 1) {
        [self cleanSpeakerView];
        return;
    }
    
    if (![PLVFdUtil checkStringUseable:linkMicUserId] &&
        ![PLVFdUtil checkStringUseable:self.currentSpeakerLinkMicUserId]) {
        //当linkMicUserId为空时设置连麦在线用户数组第一个用户为主讲用户
        PLVLinkMicOnlineUser *firstOnlineUser = self.dataArray.firstObject;
        linkMicUserId = firstOnlineUser.linkMicUserId;
    } else if (![PLVFdUtil checkStringUseable:linkMicUserId]) {
        linkMicUserId = self.currentSpeakerLinkMicUserId;
    }
    
    self.showingSpeakerIndexPath = nil;
    NSInteger indexRow = [self findCellIndexWithUserId:linkMicUserId];
    PLVLinkMicOnlineUser *firstSiteOnlineUser = [self onlineUserWithIndex:indexRow];
    if (firstSiteOnlineUser) {
        self.currentSpeakerLinkMicUserId = linkMicUserId;
        self.showingSpeakerIndexPath = [NSIndexPath indexPathForRow:indexRow inSection:0];
        [self setupLinkMicCanvasViewWithOnlineUser:firstSiteOnlineUser];
        [self setupWillDeallocBlockWithOnlineUser:firstSiteOnlineUser];
        [self.speakerView showSpeakerViewWithUserModel:firstSiteOnlineUser];
    }
}

- (void)showGuideView {
    if (self.linkMicUserCount <= 1) {
        [self.linkMicGuideView hideGuideView];
        return;
    }
    
    if (self.linkMicGuideView.hadShowedLinkMicGuide && !self.linkMicGuideView.showingLinkMicGuide) {
        return;
    }
    
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    CGRect cellRect = attributes.frame;
    UIView *homeVCView = [PLVSAUtils sharedUtils].homeVC.view;
    CGRect cellFrameInSuperview = [self.collectionView convertRect:cellRect toView:homeVCView];
    [self.linkMicGuideView updateGuideViewWithSuperview:homeVCView focusViewFrame:cellFrameInSuperview];
    if (!self.linkMicGuideView.superview) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicWindowsView:showGuideViewOnExternal:)]) {
            [self.delegate linkMicWindowsView:self showGuideViewOnExternal:self.linkMicGuideView];
        }
    }
}

- (void)cleanSpeakerView {
    [self.speakerView hideSpeakerView];
    self.showingSpeakerIndexPath = nil;
}

- (BOOL)showSpeakerPlaceholderView {
    if (self.viewerType == PLVRoomUserTypeGuest &&
        ![self isLocalUserPreviewView] &&
        ![self classStarted]) {
        return YES;
    }
    return NO;
}

- (BOOL)classStarted {
    if (self.delegate && [self.delegate respondsToSelector:@selector(classStartedInLinkMicWindowsView:)]) {
        return [self.delegate classStartedInLinkMicWindowsView:self];
    }
    return NO;
}

- (void)updateSubviewsLayout {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    CGFloat top = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    CGFloat left = [PLVSAUtils sharedUtils].areaInsets.left;
    CGFloat right = [PLVSAUtils sharedUtils].areaInsets.right;
    CGFloat windowsViewWidth = self.bounds.size.width;
    CGFloat windowsViewHeight = self.bounds.size.height;
    CGFloat collectionViewX = left;
    CGFloat collectionViewY = top;
    self.speakerPlaceholderView.hidden = YES;
    
    if (self.linkMicUserCount <= 1 && ![self showSpeakerPlaceholderView]) { //连麦人数1人以下,且不需要显示讲师讲师占位图
        self.collectionView.frame = self.bounds;
    } else if (self.linkMicUserCount <= 1 && [self showSpeakerPlaceholderView]) {
        //连麦人数1人以下,需要显示讲师讲师占位图
        CGFloat placeholderViewWidth = (windowsViewWidth - left - right)/2;
        CGFloat placeholderViewHeight = 0.0;
        if (isLandscape) { //横屏布局
            placeholderViewHeight = placeholderViewWidth / PLVSALinkMicCellAspectRatio;
            collectionViewY = (windowsViewHeight - placeholderViewHeight)/2;
        } else {
            collectionViewY = top + (isPad ? 92 : 78);
            placeholderViewHeight = placeholderViewWidth * PLVSALinkMicCellAspectRatio;
        }
        self.speakerPlaceholderView.hidden = NO;
        self.speakerPlaceholderView.frame = CGRectMake(collectionViewX, collectionViewY, placeholderViewWidth, placeholderViewHeight);
        self.collectionView.frame = CGRectMake(CGRectGetMaxX(self.speakerPlaceholderView.frame), CGRectGetMinY(self.speakerPlaceholderView.frame), placeholderViewWidth, placeholderViewHeight);
    } else {
        CGFloat collectionViewWidth = windowsViewWidth - collectionViewX - right;
        CGFloat collectionViewHeight = windowsViewHeight - collectionViewY - bottom;
        if (isLandscape) { //横屏布局
            if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeTiled) { //平铺模式
                if (self.linkMicUserCount == 2) {
                    collectionViewHeight = (collectionViewWidth/2) / PLVSALinkMicCellAspectRatio;
                    collectionViewY = (windowsViewHeight - collectionViewHeight)/2;
                } else if (self.linkMicUserCount <= 4) {
                    collectionViewWidth = MIN(collectionViewHeight * PLVSALinkMicCellAspectRatio, collectionViewWidth);
                    collectionViewX = (windowsViewWidth - collectionViewWidth)/2;
                }
            } else { //主讲模式
                CGFloat speakerViewWidth = collectionViewWidth * 0.7;
                collectionViewX = left + speakerViewWidth;
                collectionViewWidth = collectionViewWidth - speakerViewWidth;
                self.speakerView.frame = CGRectMake(left, collectionViewY, speakerViewWidth, collectionViewHeight);
            }
        } else { //竖屏布局
            collectionViewY = top + (isPad ? 92 : 78);
            collectionViewHeight = windowsViewHeight - collectionViewY - bottom;
            if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeTiled) { //平铺模式
                if (self.linkMicUserCount <= 4) {
                    collectionViewHeight = MIN(collectionViewWidth * PLVSALinkMicCellAspectRatio, collectionViewHeight);
                }
            } else { //主讲模式
                collectionViewX = windowsViewWidth * 0.75;
                collectionViewWidth = windowsViewWidth * 0.25;
                CGFloat speakerViewWidth = windowsViewWidth - collectionViewWidth;
                CGFloat speakerViewHeight = isPad ? speakerViewWidth * 1.4 :  speakerViewWidth * PLVSALinkMicCellAspectRatio;
                self.speakerView.frame = CGRectMake(0, collectionViewY, speakerViewWidth, speakerViewHeight);
            }
        }
        self.collectionView.frame = CGRectMake(collectionViewX, collectionViewY, floor(collectionViewWidth), floor(collectionViewHeight));
    }
    self.collectionView.contentOffset = CGPointZero;
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:YES];
}

#pragma mark Initialize

- (void)setupUI {
    [self addSubview:self.collectionView];
    [self addSubview:self.speakerView];
    [self addSubview:self.speakerPlaceholderView];
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
        
        [_collectionView registerClass:[PLVSALinkMicWindowCell class] forCellWithReuseIdentifier:kCellIdentifier];
    }
    return _collectionView;
}

- (PLVSALinkMicGuideView *)linkMicGuideView {
    if (!_linkMicGuideView) {
        _linkMicGuideView = [[PLVSALinkMicGuideView alloc] init];
        _linkMicGuideView.alpha = 0.0;
    }
    return _linkMicGuideView;
}

- (PLVSALinkMicWindowsSpeakerView *)speakerView {
    if (!_speakerView) {
        _speakerView = [[PLVSALinkMicWindowsSpeakerView alloc] init];
    }
    return _speakerView;
}

- (PLVSALinkMicSpeakerPlaceholderView *)speakerPlaceholderView {
    if (!_speakerPlaceholderView) {
        _speakerPlaceholderView = [[PLVSALinkMicSpeakerPlaceholderView alloc] init];
        _speakerPlaceholderView.hidden = YES;
    }
    return _speakerPlaceholderView;
}

- (PLVRoomUserType)viewerType{
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
}

#pragma mark 工具

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

/// 讲师、助教、管理员可以管理连麦操作
- (BOOL)canManagerLinkMic {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - [ Delegate ]

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger dataNum = self.linkMicUserCount;
    if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker) {
        NSInteger finalCellNum = (dataNum - 1) <= 0 ? 1 : (dataNum - 1);
        return finalCellNum; /// 主讲模式下，主讲用户不需在连麦窗口列表中显示窗口
    }
    return dataNum;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLinkMicOnlineUser *onlineUser = nil;
    onlineUser = [self onlineUserWithIndex:indexPath.row];
    if (!onlineUser) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    }
    [self setupLinkMicCanvasViewWithOnlineUser:onlineUser];
    [self setupWillDeallocBlockWithOnlineUser:onlineUser];
    
    PLVSALinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    // 设备检测页或者连麦人数为1时不显示占位图的情况下，不显示昵称且关闭摄像头时不显示canvasView
    BOOL hideCanvasView = [self isLocalUserPreviewView] || (self.linkMicUserCount == 1 && ![self showSpeakerPlaceholderView]);
    [cell setUserModel:onlineUser hideCanvasViewWhenCameraClose:hideCanvasView];
    return cell;
}

#pragma mark UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat collectionViewWidth = self.collectionView.bounds.size.width;
    CGFloat collectionViewHeigth = self.collectionView.bounds.size.height;
    CGFloat collectionCellWidth = collectionViewWidth;
    CGFloat collectionCellHeigth = collectionViewHeigth;
    if (self.linkMicUserCount <= 1) {
        return CGSizeMake(collectionCellWidth, collectionCellHeigth);
    }
    
    if (isLandscape) { //横屏布局
        if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeTiled) {
            if (self.linkMicUserCount <= 2) {
                collectionCellWidth = collectionViewWidth / 2;
            } else if (self.linkMicUserCount <= 4) {
                collectionCellWidth = collectionViewWidth / 2;
                collectionCellHeigth = collectionViewHeigth / 2;
            } else {
                collectionCellWidth = collectionViewWidth / 4;
                collectionCellHeigth = collectionCellWidth / PLVSALinkMicCellAspectRatio;
            }
        } else {
            collectionCellHeigth = collectionViewWidth / PLVSALinkMicCellAspectRatio;
        }
    } else { //竖屏布局
        if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeTiled) {
            if ((isPad && self.linkMicUserCount <= 2) ||
                (!isPad && self.linkMicUserCount <= 4)) {
                collectionCellWidth = collectionViewWidth / 2;
            } else {
                collectionCellWidth = collectionViewWidth / 3;
            }
        }
        collectionCellHeigth = collectionCellWidth * PLVSALinkMicCellAspectRatio;
    }
    return CGSizeMake(collectionCellWidth, collectionCellHeigth);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![self canManagerLinkMic]) {
        return;
    }
    
    PLVLinkMicOnlineUser *onlineUser = [self onlineUserWithIndex:indexPath.row];
    if (!onlineUser || onlineUser.localUser) {
        return;
    }
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(linkMicWindowsView:didSelectOnlineUser:)]) {
        [self.delegate linkMicWindowsView:self didSelectOnlineUser:onlineUser];
    }
}

@end
