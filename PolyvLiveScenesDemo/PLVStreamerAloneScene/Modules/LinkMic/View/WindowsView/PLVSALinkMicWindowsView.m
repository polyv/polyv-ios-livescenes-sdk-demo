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
#import "PLVSALinkMicPreviewView.h"

// 模块
#import "PLVLinkMicOnlineUser+SA.h"
#import "PLVSAUtils.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

typedef NS_ENUM(NSInteger, PLVSALinkMicLayoutMode) {
    PLVSALinkMicLayoutModeTiled = 0, //平铺模式
    PLVSALinkMicLayoutModeSpeaker = 1 //主讲模式
};

//连麦窗口宽高比例 横屏 3:2 竖屏2:3
static CGFloat PLVSALinkMicCellAspectRatio = 1.5;
static NSString *kCellIdentifier = @"PLVSALinkMicWindowCellID";
static NSString *kFullScreenOpenCountKey = @"PLVSAFullScreenOpenCount";
static NSString *kFullScreenCloseCountKey = @"PLVSAFullScreenCloseCount";
static NSString *kPLVSALMKEYPATH_CONTENTSIZE = @"contentSize";

@interface PLVSALinkMicWindowsView ()<
UICollectionViewDataSource,
UICollectionViewDelegate,
PLVSALinkMicWindowCellDelegate,
PLVSALinkMicPreviewViewDelegate
>

#pragma mark 数据
@property (nonatomic, assign) NSUInteger linkMicUserCount; //连麦用户数量
@property (nonatomic, strong, readonly) PLVLinkMicOnlineUser *localOnlineUser; // 只读，本地用户
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> *dataArray; // 只读，当前连麦在线用户数组
@property (nonatomic, assign) PLVSALinkMicLayoutMode linkMicLayoutMode; //当前连麦布局模式 (默认为平铺模式)
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;
@property (nonatomic, copy) NSString *currentSpeakerLinkMicUserId; //当前显示主讲用户的连麦id[布局模式切换时缓存此id]
@property (nonatomic, assign) NSInteger currentSpeakerUserIndex; // 当前主讲用户在数据中的下标
@property (nonatomic, copy) NSString *fullScreenUserId; // 全屏用户的Id
@property (nonatomic, assign) BOOL delayDisplayToast; // 是否需要延迟显示toast
@property (nonatomic, assign) BOOL observingCollectionView;

#pragma mark UI
/// view hierarchy
///
/// (PLVSALinkMicWindowsView) self
///    ├─  (UICollectionView) collectionView
///    ├─  (PLVSALinkMicSpeakerPlaceholderView) speakerPlaceholderView
///    └─  (PLVSALinkMicWindowsSpeakerView) speakerView
@property (nonatomic, strong) PLVSALinkMicGuideView *linkMicGuideView; // 连麦新手引导
@property (nonatomic, strong) UIView *collectionBackgroundView; // 连麦窗口背景视图
@property (nonatomic, strong) UICollectionView *collectionView; // 连麦窗口集合视图
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *collectionViewLayout; // 集合视图的布局
@property (nonatomic, strong) PLVSALinkMicWindowsSpeakerView *speakerView; // 主讲模式下的第一画面
@property (nonatomic, strong) PLVSALinkMicSpeakerPlaceholderView *speakerPlaceholderView; // 嘉宾角色登录时 主播的占位图
@property (nonatomic, strong) UILabel *linkMicStatusLabel;       // 连麦状态文本框 (负责展示 连麦状态)
@property (nonatomic, strong) PLVSALinkMicWindowCell *fullScreenCell; // 全屏视图
@property (nonatomic, strong) PLVSALinkMicPreviewView *linkMicPreView; // 连麦预览视图
@property (nonatomic, strong) UIView *fullScreenContentView; // 全屏展示视图的容器

@end

@implementation PLVSALinkMicWindowsView

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    [self removeObserveCollectionView];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.linkMicLayoutMode = PLVSALinkMicLayoutModeTiled;
        [self showToastWithFullScreen:YES reset:YES];
        [self setupUI];
        [self observeCollectionView];
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
    
    [self setupFirstSiteCanvasViewWithUserId:self.currentSpeakerLinkMicUserId];

    [self.collectionView reloadData];
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showGuideView];
        });
    }
}

- (void)updateFirstSiteCanvasViewWithUserId:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite {
    if (![PLVFdUtil checkStringUseable:linkMicUserId]) {
        return;
    }
    
    if (!toFirstSite) {
        if ([self.currentSpeakerLinkMicUserId isEqualToString:linkMicUserId]) {
            linkMicUserId = nil;
        } else {
            return;
        }
    }
    
    [self setupFirstSiteCanvasViewWithUserId:linkMicUserId];
    if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker) {
        [self updateSpeakerViewForLinkMicUserId:self.currentSpeakerLinkMicUserId];
    }
    [self.collectionView reloadData];
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

- (void)fullScreenLinkMicUser:(PLVLinkMicOnlineUser *)onlineUser {
    [self fullScreenViewOnlineUser:onlineUser didFullScreen:YES];
}

- (void)finishClass {
    [self.linkMicPreView showLinkMicPreviewView:NO];
}

#pragma mark - [ Private Method ]

/// 根据连麦列表视图下标 获取在线用户model [经过业务逻辑处理 与 dataArray 数据并不对应]
- (PLVLinkMicOnlineUser *)onlineUserWithIndex:(NSInteger)targetIndex {
    if (self.linkMicUserCount == 1 && targetIndex == 0 && [self isLocalUserPreviewView]) {
        return self.localOnlineUser;
    }
    targetIndex = [self indexWithTargetIndex:targetIndex isRealIndex:YES];
    return [self readUserModelFromDataArray:targetIndex];
}

/// 通过目标 targetIndex 转换为需要使用的下标
/// isReal YES 将cell的下标 转换为在dataArray 数据中对应需要显示的坐标；
/// isReal NO 将dataArray 数据中对应的下标转换为cell的下标
- (NSInteger)indexWithTargetIndex:(NSInteger)targetIndex isRealIndex:(BOOL)isReal {
    if (self.currentSpeakerUserIndex > -1) {
        if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker) {
            if (targetIndex >= self.currentSpeakerUserIndex && self.linkMicUserCount != 1) {
                isReal ? targetIndex++ : targetIndex--;
            }
        } else {
            if (isReal) {
                if (targetIndex == 0) {
                    targetIndex = self.currentSpeakerUserIndex;
                } else if (targetIndex <= self.currentSpeakerUserIndex){
                    targetIndex-- ;
                }
            } else {
                if (targetIndex == self.currentSpeakerUserIndex) {
                    targetIndex = 0;
                } else if (targetIndex < self.currentSpeakerUserIndex){
                    targetIndex++;
                }
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

- (PLVSALinkMicWindowCell *)getWindowCellWithIndex:(NSInteger)cellIndex{
    PLVSALinkMicWindowCell * cell;
    if (cellIndex >= 0) { cell = (PLVSALinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:0]]; }
    if (!cell) { PLV_LOG_ERROR(PLVConsoleLogModuleTypeLinkMic,@"PLVLCLinkMicWindowsView - cell find failed"); }
    return cell;
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

/// 设置连麦用户model的’即将销毁Block‘，用于在连麦用户退出时及时回收资源
- (void)setupWillDeallocBlockWithOnlineUser:(PLVLinkMicOnlineUser *)aOnlineUser {
    __weak typeof(self) weakSelf = self;
    aOnlineUser.willDeallocBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        PLVSALinkMicCanvasView *canvasView = onlineUser.canvasView;
        NSString * didLeftLinkMicUserId = onlineUser.linkMicUserId;
        dispatch_async(dispatch_get_main_queue(), ^{ // 回收资源
            if ([didLeftLinkMicUserId isEqualToString:weakSelf.currentSpeakerLinkMicUserId]) {
                /// 连麦用户销毁时，清理第一画面视图资源
                [weakSelf cleanSpeakerView];
            }
            if ([didLeftLinkMicUserId isEqualToString:weakSelf.fullScreenUserId]) {
                /// 连麦用户销毁时，并且此用户全屏则需要 关闭全屏
                [weakSelf fullScreenViewOnlineUser:nil didFullScreen:NO];
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
    
    self.currentSpeakerUserIndex = -1;
    NSInteger indexRow = [self findCellIndexWithUserId:linkMicUserId];
    PLVLinkMicOnlineUser *firstSiteOnlineUser = [self onlineUserWithIndex:indexRow];
    if (firstSiteOnlineUser) {
        self.currentSpeakerLinkMicUserId = linkMicUserId;
        self.currentSpeakerUserIndex = indexRow;
        [self setupLinkMicCanvasViewWithOnlineUser:firstSiteOnlineUser];
        [self setupWillDeallocBlockWithOnlineUser:firstSiteOnlineUser];
        [self.speakerView showSpeakerViewWithUserModel:firstSiteOnlineUser delegate:self];
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
        self.collectionBackgroundView.frame = self.bounds;
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
        self.collectionBackgroundView.frame = CGRectMake(CGRectGetMaxX(self.speakerPlaceholderView.frame), CGRectGetMinY(self.speakerPlaceholderView.frame), placeholderViewWidth, placeholderViewHeight);
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
            if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker) { //主讲模式
                collectionViewX = windowsViewWidth * 0.75;
                collectionViewWidth = windowsViewWidth * 0.25;
                CGFloat speakerViewWidth = windowsViewWidth - collectionViewWidth;
                CGFloat speakerViewHeight = isPad ? speakerViewWidth * 1.4 :  speakerViewWidth * PLVSALinkMicCellAspectRatio;
                self.speakerView.frame = CGRectMake(0, collectionViewY, speakerViewWidth, speakerViewHeight);
            }
        }
        self.collectionBackgroundView.frame = CGRectMake(collectionViewX, collectionViewY, floor(collectionViewWidth), floor(collectionViewHeight));
    }
    self.collectionView.frame = self.collectionBackgroundView.bounds;
    self.collectionView.contentOffset = CGPointZero;
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:YES];
}

- (void)fullScreenViewOnlineUser:(PLVLinkMicOnlineUser *)onlineUser didFullScreen:(BOOL)fullScreen {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicWindowsView:onlineUser:isFullScreen:)]) {
        [self.delegate linkMicWindowsView:self onlineUser:onlineUser isFullScreen:fullScreen];
    }
    
    PLVSALinkMicWindowCell *collectionViewCell;
    NSInteger indexRow = [self findCellIndexWithUserId:onlineUser.userId];
    if (indexRow > -1) {
        // 主讲模式下，indexPath 会有改变
        if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker && [self.currentSpeakerLinkMicUserId isEqualToString:onlineUser.userId] && self.linkMicUserCount != 1) {
            collectionViewCell = self.speakerView.linkMicWindowCell;
        } else {
            indexRow = [self indexWithTargetIndex:indexRow isRealIndex:NO];
            collectionViewCell = [self getWindowCellWithIndex:indexRow];
        }
    }

    if (!fullScreen) { // 取消全屏
        if (collectionViewCell) { // 恢复 Cell 数据
            BOOL hideCanvasView = [self isLocalUserPreviewView];
            [collectionViewCell setUserModel:onlineUser hideCanvasViewWhenCameraClose:hideCanvasView];
        }
        
        [self.fullScreenCell.contentView removeFromSuperview];
        self.fullScreenContentView.hidden = YES;
        self.fullScreenCell.delegate = nil;
        self.fullScreenCell = nil;
        self.fullScreenUserId = nil;
        [self showToastWithFullScreen:NO reset:NO];
    } else if (fullScreen && !self.fullScreenCell && indexRow > -1) { // 开启全屏
        [collectionViewCell setUserModel:[PLVLinkMicOnlineUser new] hideCanvasViewWhenCameraClose:NO];
        // 创建全屏视图
        self.fullScreenCell = [[PLVSALinkMicWindowCell alloc] init];
        self.fullScreenCell.delegate = self;
        self.fullScreenCell.frame = self.bounds;
        self.fullScreenContentView.hidden = NO;
        [self.fullScreenContentView addSubview:self.fullScreenCell.contentView];
        [self.fullScreenCell setUserModel:onlineUser hideCanvasViewWhenCameraClose:NO];
        [self.fullScreenCell setNeedsLayout];
        [self.fullScreenCell layoutIfNeeded];
        self.fullScreenUserId = onlineUser.linkMicUserId;
        [self showToastWithFullScreen:YES reset:NO];
    }
    
    // 全屏时需要隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:fullScreen];
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
}

- (void)updateAllCellLinkMicDuration {
    NSArray *cells = self.collectionView.visibleCells;
    for (PLVSALinkMicWindowCell * cell in cells) {
        [cell updateLinkMicDuration:YES];
    }
    [self.fullScreenCell updateLinkMicDuration:YES];
    [self.speakerView.linkMicWindowCell updateLinkMicDuration:YES];
}

#pragma mark Initialize

- (void)setupUI {
    [self addSubview:self.collectionBackgroundView];
    [self addSubview:self.speakerView];
    [self addSubview:self.speakerPlaceholderView];
    [self.collectionBackgroundView addSubview:self.collectionView];
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

- (UIView *)collectionBackgroundView {
    if (!_collectionBackgroundView) {
        _collectionBackgroundView = [[UIView alloc] init];
    }
    return _collectionBackgroundView;
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

- (PLVSALinkMicPreviewView *)linkMicPreView {
    if(!_linkMicPreView) {
        _linkMicPreView = [[PLVSALinkMicPreviewView alloc] init];
        _linkMicPreView.delegate = self;
    }
    return _linkMicPreView;
}

- (UIView *)fullScreenContentView {
    if(!_fullScreenContentView) {
        _fullScreenContentView = [[UIView alloc] init];
        _fullScreenContentView.hidden = YES;
    }
    return _fullScreenContentView;
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

/// 讲师、助教、管理员、嘉宾可以 点击查看 连麦用户
- (BOOL)canCheckLinkMicUser {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager ||
        userType == PLVRoomUserTypeGuest) {
        return YES;
    } else {
        return NO;
    }
}

/// 全屏或者关闭全屏后 Toast 提示
/// @param fullScreen 是否全屏
/// @param reset 是否重置统计数量
- (void)showToastWithFullScreen:(BOOL)fullScreen reset:(BOOL)reset {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (reset) {
        [userDefaults setInteger:0 forKey:kFullScreenOpenCountKey];
        [userDefaults setInteger:0 forKey:kFullScreenCloseCountKey];
        return;
    }
    
    NSString *fullScreenCountKey = fullScreen ? kFullScreenCloseCountKey : kFullScreenOpenCountKey;
    NSInteger fullScreenCount = [userDefaults integerForKey:fullScreenCountKey];
    NSInteger maxCount = fullScreen ? 1 : 0;
    NSString *message = fullScreen ? PLVLocalizedString(@"双击退出全屏") : PLVLocalizedString(@"双击窗口放大");
    if (fullScreenCount > maxCount) {
        return;
    }
    
    fullScreenCount += 1;
    [userDefaults setInteger:fullScreenCount forKey:fullScreenCountKey];
    [userDefaults synchronize];
    
    if (self.delayDisplayToast) {
        self.delayDisplayToast = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [PLVSAUtils showToastInHomeVCWithMessage:message];
        });
    } else {
        [PLVSAUtils showToastInHomeVCWithMessage:message];
    }
}

#pragma mark Callback
- (void)callbackForAcceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvSALinkMicWindowsView:acceptLinkMicInvitation:timeoutCancel:)]) {
        [self.delegate plvSALinkMicWindowsView:self acceptLinkMicInvitation:accept timeoutCancel:timeoutCancel];
    }
}

#pragma mark - KVO
- (void)observeCollectionView {
    if (!self.observingCollectionView) {
        self.observingCollectionView = YES;
        [self.collectionView addObserver:self forKeyPath:kPLVSALMKEYPATH_CONTENTSIZE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveCollectionView {
    if (self.observingCollectionView) {
        self.observingCollectionView = NO;
        [self.collectionView removeObserver:self forKeyPath:kPLVSALMKEYPATH_CONTENTSIZE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:UICollectionView.class] && [keyPath isEqualToString:kPLVSALMKEYPATH_CONTENTSIZE]) {
        CGFloat contentHeight = self.collectionView.contentSize.height;
        if (contentHeight < CGRectGetHeight(self.collectionBackgroundView.bounds) && self.linkMicLayoutMode == PLVSALinkMicLayoutModeTiled) {
            [UIView animateWithDuration:0.2 animations:^{
                CGFloat relativeScreenOriginY = (PLVScreenHeight - contentHeight)/2 - CGRectGetMinY(self.collectionBackgroundView.frame);
                CGRect newFrame = CGRectMake(0, MAX(0, relativeScreenOriginY), CGRectGetWidth(self.collectionBackgroundView.bounds), contentHeight);
                self.collectionView.frame = newFrame;
            }];
        } else if (CGRectGetHeight(self.collectionBackgroundView.bounds) > 0) {
            self.collectionView.scrollEnabled = YES;
            self.collectionView.frame = self.collectionBackgroundView.bounds;
        }
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
    PLVLinkMicOnlineUser *onlineUser = [self onlineUserWithIndex:indexPath.row];
    if (!onlineUser) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    }
    [self setupLinkMicCanvasViewWithOnlineUser:onlineUser];
    [self setupWillDeallocBlockWithOnlineUser:onlineUser];
    
    PLVSALinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    if (![onlineUser.linkMicUserId isEqualToString:self.fullScreenUserId]) {
        // 设备检测页，不显示昵称且关闭摄像头时不显示canvasView
        BOOL hideCanvasView = [self isLocalUserPreviewView];
        [cell setUserModel:onlineUser hideCanvasViewWhenCameraClose:hideCanvasView];
    }
    
    return cell;
}

#pragma mark UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat collectionViewWidth = self.collectionBackgroundView.bounds.size.width;
    CGFloat collectionViewHeigth = self.collectionBackgroundView.bounds.size.height;
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

#pragma mark PLVSALinkMicWindowCellDelegate

- (void)linkMicWindowCellDidSelectCell:(PLVSALinkMicWindowCell *)collectionViewCell {
    if (![self canCheckLinkMicUser]) {
        return;
    }

    NSIndexPath *indexPath = [self.collectionView indexPathForCell:collectionViewCell];
    PLVLinkMicOnlineUser *onlineUser = indexPath ? [self onlineUserWithIndex:indexPath.row] : nil;
    if (self.linkMicLayoutMode == PLVSALinkMicLayoutModeSpeaker && !onlineUser && [collectionViewCell isEqual:self.speakerView.linkMicWindowCell]) {
        onlineUser = [self readUserModelFromDataArray:self.currentSpeakerUserIndex];
    }
    
    if (!onlineUser || (onlineUser.localUser && onlineUser.userType == PLVSocketUserTypeTeacher)) {
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(linkMicWindowsView:didSelectOnlineUser:)]) {
        [self.delegate linkMicWindowsView:self didSelectOnlineUser:onlineUser];
    }
}

- (void)linkMicWindowCell:(PLVSALinkMicWindowCell *)collectionViewCell linkMicUser:(PLVLinkMicOnlineUser *)onlineUser didFullScreen:(BOOL)fullScreen {
    [self fullScreenViewOnlineUser:onlineUser didFullScreen:fullScreen];
}

- (void)linkMicWindowCell:(PLVSALinkMicWindowCell *)collectionViewCell didScreenShareForRemoteUser:(PLVLinkMicOnlineUser *)onlineUser {
    // 远端用户 屏幕共享 开启关闭 状态改变
    NSString *message = nil;
    if (onlineUser.userType == PLVRoomUserTypeTeacher) {
        message = onlineUser.currentScreenShareOpen ? PLVLocalizedString(@"主持人开始共享") : PLVLocalizedString(@"主持人结束共享");
    } else if (onlineUser.userType == PLVSocketUserTypeGuest) {
        message = onlineUser.currentScreenShareOpen ? [NSString stringWithFormat:PLVLocalizedString(@"%@开始共享"),onlineUser.nickname] : [NSString stringWithFormat:PLVLocalizedString(@"%@结束共享"),onlineUser.nickname];
    }
    
    self.delayDisplayToast = YES;
    [self fullScreenViewOnlineUser:onlineUser didFullScreen:onlineUser.currentScreenShareOpen];
    [PLVSAUtils showToastInHomeVCWithMessage:message];
}

- (void)linkMicWindowCellDidClickStopScreenSharing:(PLVSALinkMicWindowCell *)collectionViewCell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicWindowsViewDidClickStopScreenSharing:)]) {
        [self.delegate linkMicWindowsViewDidClickStopScreenSharing:self];
    }
}

#pragma mark PLVSALinkMicPreviewViewDelegate
- (void)plvSALinkMicPreviewViewAcceptLinkMicInvitation:(PLVSALinkMicPreviewView *)linkMicPreView {
    [self.localOnlineUser wantOpenUserMic:self.linkMicPreView.micOpen];
    [self.localOnlineUser wantOpenUserCamera:self.linkMicPreView.cameraOpen];
    [self callbackForAcceptLinkMicInvitation:YES timeoutCancel:NO];
}

- (void)plvSALinkMicPreviewView:(PLVSALinkMicPreviewView *)linkMicPreView cancelLinkMicInvitationReason:(PLVSACancelLinkMicInvitationReason)reason {
    [self callbackForAcceptLinkMicInvitation:NO timeoutCancel:reason == PLVSACancelLinkMicInvitationReason_Timeout];
}

- (void)plvSALinkMicPreviewView:(PLVSALinkMicPreviewView *)linkMicPreView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvSALinkMicWindowsView:inviteLinkMicTTL:)]) {
        [self.delegate plvSALinkMicWindowsView:self inviteLinkMicTTL:callback];
    }
}

@end
