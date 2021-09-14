//
//  PLVLCLinkMicWindowsView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLinkMicWindowsView.h"

#import "PLVLCUtils.h"
#import "PLVLCLinkMicWindowCell.h"
#import "PLVLinkMicOnlineUser+LC.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#define PLVColor_View_Black PLV_UIColorFromRGB(@"1A1B1F")

static NSString * PLVLCLinkMicWindowCellId = @"PLVLCLinkMicWindowCellId";

@interface PLVLCLinkMicWindowsView () <
UICollectionViewDataSource,
UICollectionViewDelegate
>

#pragma mark 状态
@property (nonatomic, assign) BOOL hadShowedGuide;  // 是否已展示过’左滑引导‘
@property (nonatomic, assign) BOOL guideShowing;    // 是否正在展示’左滑引导‘
@property (nonatomic, assign, readonly) PLVChannelLinkMicSceneType linkMicSceneType; /// 只读，当前频道连麦场景类型
@property (nonatomic, assign, readonly) BOOL showingExternalView;
@property (nonatomic, assign, readonly) BOOL mainSpeakerPPTOnMain;
@property (nonatomic, assign) BOOL hadAlignMainSpeakerSite; // 是否已对齐过主讲主副屏位置 (每次“从无用户到开始展示用户”，都需执行一次对齐)

#pragma mark 数据
@property (nonatomic, readonly) NSArray <PLVLinkMicOnlineUser *> * dataArray; // 只读，当前连麦在线用户数组
@property (nonatomic, strong) NSIndexPath * showingExternalCellIndexPath; // 正在显示外部视图的Cell，所对应的下标 (仅在 PLVChannelLinkMicSceneType_PPT_PureRtc 该连麦场景类型下允许有值)
@property (nonatomic, copy) NSString * showingExternalCellLinkMicUserId;  // 正在显示外部视图的Cell，所对应的用户Id (将用于更新 showingExternalCellIndexPath 属性，以保证 dataArray 刷新时其仍是正确的；仅在 PLVChannelLinkMicSceneType_PPT_PureRtc 该连麦场景类型下允许有值)
@property (nonatomic, copy) NSString * currentMainSpeakerUserId;
@property (nonatomic, assign) float lastOffsetX;    // collectionView 滑动上次停留的x点位置
@property (nonatomic, copy) NSString * manualSwitchMainSpeakerUserId; // 当前由用户触发的、切去主屏显示的、成为第一画面的用户连麦id
@property (nonatomic, copy) void (^collectionReloadBlock) (void);

#pragma mark UI
@property (nonatomic, weak) UIView * externalView; // 外部视图 (正在被显示在 PLVLCLinkMicWindowsView 窗口列表中的外部视图；弱引用)
@property (nonatomic, readonly) UICollectionViewFlowLayout * collectionViewLayout; // 集合视图的布局

/// view hierarchy
///
/// (PLVLCLinkMicWindowsView) self
/// ├── (UICollectionView) collectionView (lowest)
/// │   ├── (PLVLCLinkMicWindowCell) windowCell
/// │   ├── ...
/// │   └── (PLVLCLinkMicWindowCell) windowCell
/// │
/// └── (UIImageView) guideBackgroudView (top)
///     ├── (UIImageView) guideImageView
///     └── (UILabel) guideTextLabel
@property (nonatomic, strong) UICollectionView * collectionView;  // 背景视图 (负责承载 windowCell；负责展示 背景底色；具备宫格样式的改动潜能)
@property (nonatomic, strong) UIView * guideBackgroudView;        // 左滑引导背景视图
@property (nonatomic, strong) CAGradientLayer * guideShadowLayer; // 左滑引导渐变背景
@property (nonatomic, strong) UIImageView * guideImageView;       // 左滑引导箭头图标
@property (nonatomic, strong) UILabel * guideTextLabel;           // 左滑引导文本框

@end

@implementation PLVLCLinkMicWindowsView

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
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        // 横屏
        self.collectionView.frame = CGRectMake(8, 0, 150, selfHeight);
        self.collectionView.alwaysBounceHorizontal = NO;
        self.collectionView.alwaysBounceVertical = YES;
        
        self.collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.collectionViewLayout.minimumLineSpacing = 8;
        
        [self hideGuideView];
    }else{
        // 竖屏
        self.collectionView.frame = CGRectMake(0, 0, selfWidth, selfHeight);
        self.collectionView.alwaysBounceHorizontal = YES;
        self.collectionView.alwaysBounceVertical = NO;
        
        self.collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.collectionViewLayout.minimumLineSpacing = 0;
        
        [self showGuideView];
    }
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:YES];
    
    if (selfHeight > 0 && self.collectionReloadBlock) {
        self.collectionReloadBlock();
        self.collectionReloadBlock = nil;
    }
}

- (void)layoutGuideView{
    CGFloat selfWidth = CGRectGetWidth(self.bounds);
    CGFloat selfHeight = CGRectGetHeight(self.bounds);
    
    CGFloat guideBackgroudViewWidth = 188.0;
    self.guideBackgroudView.frame = CGRectMake(selfWidth - guideBackgroudViewWidth, 0, guideBackgroudViewWidth, selfHeight);
    self.guideShadowLayer.frame = self.guideBackgroudView.bounds;
    
    CGFloat guideImageViewScale = 31.37 / 19.0;
    CGFloat guideImageViewHeight = 19.0 / 70.0 * selfHeight;
    CGFloat guideImageViewWidth = guideImageViewHeight * guideImageViewScale;
    CGFloat guideImageViewY = 16.0 / 70.0 * selfHeight;
    self.guideImageView.frame = CGRectMake(guideBackgroudViewWidth - 40 - guideImageViewWidth, guideImageViewY, guideImageViewWidth, guideImageViewHeight);
    
    CGFloat guideTextLabelWidth = 92.0;
    self.guideTextLabel.frame = CGRectMake(CGRectGetMidX(self.guideImageView.frame) - guideTextLabelWidth / 2.0, CGRectGetMaxY(self.guideImageView.frame) + 6.0, guideTextLabelWidth, 16.0);
}


#pragma mark - [ Public Methods ]
- (void)reloadLinkMicUserWindowsWithCompleteBlock:(void (^)(void))reloadCompleteBlock{
    NSArray * currentDataArray = self.dataArray;
    NSInteger finalCellNum = self.dataArray.count;
    PLVLinkMicOnlineUser * firstSiteOnlineUser = self.dataArray.firstObject;

    if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc) { /// 完全RTC (云课堂连麦)
        if (self.showingExternalView) {
            if (![self.showingExternalCellLinkMicUserId isEqualToString:firstSiteOnlineUser.linkMicUserId]) {
                /// 若 “第一画面” 发生变更
                [self rollbackExternalView];
                [self wantExchangeWithExternalViewForLinkMicUser:firstSiteOnlineUser needReload:NO];
            }
        }else{
            /// 若是手动点击触发的
            if ([PLVFdUtil checkStringUseable:self.manualSwitchMainSpeakerUserId] &&
                [self.manualSwitchMainSpeakerUserId isEqualToString:firstSiteOnlineUser.linkMicUserId]) {
                [self wantExchangeWithExternalViewForLinkMicUser:firstSiteOnlineUser needReload:NO];
                self.manualSwitchMainSpeakerUserId = nil;
            }
        }
    } else if (self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PureRtc){ /// 完全RTC (新版普通直播连麦)
        if (firstSiteOnlineUser) {
            [self checkUserModelAndSetupLinkMicCanvasView:firstSiteOnlineUser];
            [self setupUserModelWillDeallocBlock:firstSiteOnlineUser];
            
            if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:showFirstSiteCanvasViewOnExternal:)]) {
                [self.delegate plvLCLinkMicWindowsView:self showFirstSiteCanvasViewOnExternal:firstSiteOnlineUser.canvasView];
            }
        }
        finalCellNum = (finalCellNum - 1) <= 0 ? 0 : (finalCellNum - 1);
    }

    if (!CGRectGetHeight(self.bounds) && finalCellNum > 0) {
        __weak typeof(self) weakSelf = self;
        self.collectionReloadBlock = ^{
            [weakSelf.collectionView reloadData];
            [weakSelf showGuideView];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf alignMainSpeakerSite];
                if (reloadCompleteBlock) { reloadCompleteBlock(); }
            });
        };
    }else{
        [self.collectionView reloadData];
        [self showGuideView];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alignMainSpeakerSite];
            if (reloadCompleteBlock) { reloadCompleteBlock(); }
        });
    }
    
    if ([PLVFdUtil checkArrayUseable:currentDataArray]) {
        self.currentMainSpeakerUserId = firstSiteOnlineUser.linkMicUserId;
    }else{
        self.currentMainSpeakerUserId = nil;
        self.manualSwitchMainSpeakerUserId = nil;
    }
}

- (void)linkMicWindowMainSpeaker:(NSString *)linkMicUserId toMainScreen:(BOOL)mainSpeakerToMainScreen{
    if (![PLVFdUtil checkStringUseable:linkMicUserId]) {
        NSLog(@"PLVLCLinkMicWindowsView - [linkMicWindowLinkMicUserId:wannaBecomeFirstSite:] call failed ,linkMicUserId illegale:%@",linkMicUserId);
        return;
    }
    
    if (mainSpeakerToMainScreen && !self.showingExternalView) {
        [self wantExchangeWithExternalViewForLinkMicUser:[self readUserModelFromDataArray:[self findCellIndexWithUserId:linkMicUserId]] needReload:YES];
        
    }else if(!mainSpeakerToMainScreen && self.showingExternalView){
        NSIndexPath * oriIndexPath = self.showingExternalCellIndexPath;
        [self rollbackExternalView];
        [self rollbackLinkMicCanvasView:oriIndexPath];
    }
}

#pragma mark Getter
- (BOOL)mainSpeakerPPTOnMain{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsViewGetMainSpeakerPPTOnMain:)]) {
        return [self.delegate plvLCLinkMicWindowsViewGetMainSpeakerPPTOnMain:self];
    }else{
        NSLog(@"PLVLCLinkMicWindowsView - delegate not implement method:[plvLCLinkMicWindowsViewGetMainSpeakerPPTOnMain:]");
        return YES; /// 默认 YES
    }
}


#pragma mark - [ Private Methods ]
- (PLVLCLinkMicWindowCell *)findLocalUserCell{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        targetUserIndex = [self.delegate plvLCLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            if (enumerateUser.localUser) { return YES; }
            return NO;
        }];
    }
    return [self getWindowCellWithIndex:targetUserIndex];
}

- (PLVLCLinkMicWindowCell *)findCellWithUserId:(NSString *)userId{
    return [self getWindowCellWithIndex:[self findCellIndexWithUserId:userId]];
}

- (NSInteger)findCellIndexWithUserId:(NSString *)userId{
    NSInteger targetUserIndex = -1;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        targetUserIndex = [self.delegate plvLCLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            if ([enumerateUser.linkMicUserId isEqualToString:userId]) { return YES; }
            return NO;
        }];
    }
    return targetUserIndex;
}

- (PLVLCLinkMicWindowCell *)getWindowCellWithIndex:(NSInteger)cellIndex{
    PLVLCLinkMicWindowCell * cell;
    if (cellIndex >= 0) { cell = (PLVLCLinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:0]]; }
    if (!cell) { NSLog(@"PLVLCLinkMicWindowsView - cell find failed"); }
    return cell;
}

- (PLVLinkMicOnlineUser *)readUserModelFromDataArray:(NSInteger)targetIndex{
    if (self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PartRtc ||
        self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PureRtc){
        targetIndex++;
    }
    
    PLVLinkMicOnlineUser * user;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:getUserModelFromOnlineUserArrayWithIndex:)]) {
        user = [self.delegate plvLCLinkMicWindowsView:self getUserModelFromOnlineUserArrayWithIndex:targetIndex];
    }
    return user;
}

- (void)showGuideView{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (self.dataArray.count <= 3 || fullScreen) { return; }
    
    if (self.hadShowedGuide && !self.guideShowing) { return; }
    
    if (!_guideBackgroudView) {
        [self addSubview:self.guideBackgroudView];
        [self layoutGuideView];
        self.hadShowedGuide = YES;
        self.guideShowing = YES;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.guideBackgroudView.alpha = 1.0;
    } completion:nil];
}

- (void)hideGuideView{
    if (!_guideBackgroudView) { return; }

    if (_guideBackgroudView.alpha == 0) { return; }
        
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.guideBackgroudView.alpha = 0;
    } completion:nil];
}

- (void)wantExchangeWithExternalViewForLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser needReload:(BOOL)reload{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:wantExchangeWithExternalViewForLinkMicUser:canvasView:)]) {
        UIView * returnView = [self.delegate plvLCLinkMicWindowsView:self wantExchangeWithExternalViewForLinkMicUser:linkMicUser canvasView:linkMicUser.canvasView];
        
        if (returnView && [returnView isKindOfClass:UIView.class]) {
            self.showingExternalCellLinkMicUserId = linkMicUser.linkMicUserId;
            self.externalView = returnView;
            if (reload) {
                NSInteger targetCellIndex = [self findCellIndexWithUserId:linkMicUser.linkMicUserId];
                if (targetCellIndex >= 0) {
                    NSIndexPath * targetCellIndexPath = [NSIndexPath indexPathForRow:targetCellIndex inSection:0];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.collectionView reloadItemsAtIndexPaths:@[targetCellIndexPath]];
                    });
                }else{
                    NSLog(@"PLVLCLinkMicWindowsView - wantExchangeWithExternalViewForLinkMicUser failed, targetCellIndex illegal:%ld",(long)targetCellIndex);
                }
            }
        }else{
            NSLog(@"PLVLCLinkMicWindowsView - return view illegal, returnView:%@",returnView);
        }
    }
}

- (void)rollbackExternalView{
    // 告知外部对象，进行视图位置回退、恢复
    if (self.externalView) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:rollbackExternalView:)]) {
            [self.delegate plvLCLinkMicWindowsView:self rollbackExternalView:self.externalView];
        }
        self.showingExternalCellIndexPath = nil;
        self.showingExternalCellLinkMicUserId = nil;
        self.externalView = nil;
    }
}

- (void)rollbackLinkMicCanvasView:(NSIndexPath *)oriIndexPath{
    PLVLinkMicOnlineUser * oriUserModel = [self readUserModelFromDataArray:oriIndexPath.row];
    if (oriUserModel){
        // 将播放画布视图恢复至默认位置
        PLVLCLinkMicWindowCell * showingExternalCell = (PLVLCLinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:oriIndexPath];
        [showingExternalCell switchToShowRtcContentView:oriUserModel.canvasView];
    } else {
        NSLog(@"PLVLCLinkMicWindowsView - rollbackLinkMicCanvasView failed, oriIndexPath %@ can't get userModel",oriIndexPath);
    }
}

/// 对齐主讲主副屏位置
- (void)alignMainSpeakerSite{
    if (!self.hadAlignMainSpeakerSite) {
        self.hadAlignMainSpeakerSite = YES;
        
        BOOL currentMainSpeakerPPTOnMain = self.mainSpeakerPPTOnMain;
        if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc &&
            self.showingExternalView == currentMainSpeakerPPTOnMain) {
            [self linkMicWindowMainSpeaker:self.dataArray.firstObject.linkMicUserId toMainScreen:!currentMainSpeakerPPTOnMain];
        }
    }
}

- (void)cleanLinkMicCellWithLinkMicUser:(PLVLinkMicOnlineUser *)didLeftLinkMicUser{
    __weak typeof(self) weakSelf = self;
    
    PLVLCLinkMicCanvasView * canvasView = didLeftLinkMicUser.canvasView;
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
        PLVLCLinkMicCanvasView * canvasView = [[PLVLCLinkMicCanvasView alloc] init];
        [canvasView addRTCView:linkMicUserModel.rtcView];
        linkMicUserModel.canvasView = canvasView;
        linkMicUserModel.networkQualityChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if (onlineUser.canvasView) { [onlineUser.canvasView updateNetworkQualityImageViewWithStatus:onlineUser.currentNetworkQuality]; }
        };
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
        [_collectionView registerClass:[PLVLCLinkMicWindowCell class] forCellWithReuseIdentifier:identifier];
    }
    return _collectionView;
}

- (UICollectionViewFlowLayout *)collectionViewLayout{
    return ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout);
}

- (UIView *)guideBackgroudView{
    if (!_guideBackgroudView) {
        _guideBackgroudView = [[UIView alloc]init];
        _guideBackgroudView.userInteractionEnabled = NO;
        _guideBackgroudView.alpha = 0.0;
        [_guideBackgroudView.layer addSublayer:self.guideShadowLayer];
        [_guideBackgroudView addSubview:self.guideImageView];
        [_guideBackgroudView addSubview:self.guideTextLabel];
    }
    return _guideBackgroudView;
}

- (CAGradientLayer *)guideShadowLayer{
    if (!_guideShadowLayer) {
        _guideShadowLayer = [CAGradientLayer layer];
        _guideShadowLayer.endPoint = CGPointMake(0, 0.5);
        _guideShadowLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.65].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor];
        _guideShadowLayer.locations = @[@(0), @(1.0f)];
    }
    return _guideShadowLayer;
}

- (UIImageView *)guideImageView{
    if (!_guideImageView) {
        _guideImageView = [[UIImageView alloc]init];
        _guideImageView.image = [PLVLCUtils imageForLinkMicResource:@"plvlc_linkmic_guide_leftdrag"];
    }
    return _guideImageView;
}

- (UILabel *)guideTextLabel{
    if (!_guideTextLabel) {
        _guideTextLabel = [[UILabel alloc]init];
        _guideTextLabel.text = @"向左滑动试试";
        _guideTextLabel.font = [UIFont systemFontOfSize:12];
        _guideTextLabel.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
        _guideTextLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _guideTextLabel;
}

- (PLVChannelLinkMicSceneType)linkMicSceneType{
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsViewGetCurrentLinkMicSceneType:)]) {
        return [self.delegate plvLCLinkMicWindowsViewGetCurrentLinkMicSceneType:self];
    }
    return PLVChannelLinkMicSceneType_Unknown;
}

- (NSIndexPath *)showingExternalCellIndexPath{
    if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc) { return _showingExternalCellIndexPath; }
    return nil;
}

- (NSString *)showingExternalCellLinkMicUserId{
    if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc) { return _showingExternalCellLinkMicUserId; }
    return nil;
}

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray{
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsViewGetCurrentUserModelArray:)]) {
        NSArray * dataArray = [self.delegate plvLCLinkMicWindowsViewGetCurrentUserModelArray:self];
        if (dataArray.count == 0) {
            self.hadAlignMainSpeakerSite = NO;
        }
        return dataArray;
    }
    return nil;
}

- (BOOL)showingExternalView{
    return [PLVFdUtil checkStringUseable:self.showingExternalCellLinkMicUserId];
}


#pragma mark - [ Delegate ]
#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.lastOffsetX = scrollView.contentOffset.x;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.lastOffsetX < scrollView.contentOffset.x) {
        self.guideShowing = NO;
        [self hideGuideView];
    }
}

#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger dataNum = self.dataArray.count;
    if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc) {
        return dataNum; /// 此场景下，全部连麦用户在连麦窗口列表中，均有座位
    } else if (self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PartRtc ||
               self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PureRtc){
        NSInteger finalCellNum = (dataNum - 1) <= 0 ? 0 : (dataNum - 1);
        return finalCellNum; /// 此场景下，第一位连麦用户，不需在连麦窗口列表中拥有座位
    }
    return dataNum;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    BOOL thisCellShowingExternalView = NO;
    PLVLinkMicOnlineUser * linkMicUserModel = [self readUserModelFromDataArray:indexPath.row];
    if (!linkMicUserModel) {
        NSLog(@"PLVLCLinkMicWindowsView - cellForItemAtIndexPath for %@ error",indexPath);
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVLCLinkMicWindowCellID" forIndexPath:indexPath];
    }
    
    [self checkUserModelAndSetupLinkMicCanvasView:linkMicUserModel];
    [self setupUserModelWillDeallocBlock:linkMicUserModel];
    
    // 若两值一致，则表示此 Cell 将需要展示外部视图，此时应更新 showingExternalCellIndexPath
    if ([self.showingExternalCellLinkMicUserId isEqualToString:linkMicUserModel.linkMicUserId]) {
        self.showingExternalCellIndexPath = indexPath;
        thisCellShowingExternalView = YES;
    }
    
    PLVLCLinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVLCLinkMicWindowCellID" forIndexPath:indexPath];
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
        itemSize = CGSizeMake(150.0, 85.0);
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
    
    BOOL needCallToChangeFirstSite = (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc) ? (indexPath.row > 0) : YES;
    if (needCallToChangeFirstSite) {
        if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:linkMicUserWantToBecomeFirstSite:)]) {
            NSInteger targetUserIndex = (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc) ? indexPath.row : (indexPath.row + 1);
            [self.delegate plvLCLinkMicWindowsView:self linkMicUserWantToBecomeFirstSite:targetUserIndex];
        }
        self.manualSwitchMainSpeakerUserId = currentTapUserModel.linkMicUserId;
    } else {
        if (self.showingExternalView) {
            // 将 外部视图 交回给外部，并将rtc视图显示回列表中
            NSIndexPath * oriIndexPath = self.showingExternalCellIndexPath;
            [self rollbackExternalView];
            [self rollbackLinkMicCanvasView:oriIndexPath];
        } else {
            [self wantExchangeWithExternalViewForLinkMicUser:currentTapUserModel needReload:YES];
        }
    }
}

@end
