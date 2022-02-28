//
//  PLVHCLinkMicWindowsView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicWindowsView.h"

//UI
#import "PLVHCLinkMicWindowCell.h"
#import "PLVHCLinkMicSettingPopView.h"
#import "PLVHCLinkMicTeacherPreView.h"
#import "PLVHCLinkMicCollectionViewFlowLayout.h"
#import "PLVHCLinkMicPlaceholderView.h"

/// 数据模型
#import "PLVLinkMicOnlineUser+HC.h"

/// 工具
#import "PLVHCUtils.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVHCLinkMicZoomManager.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const PLVHCLinkMicWindowCell_Six_Id = @"PLVHCLinkMicWindowSixCellId";
static NSString *const PLVHCLinkMicWindowCell_Sixteen_Id = @"PLVHCLinkMicWindowSixteenCellId";
static NSString *const PLVHCLinkMicWindowCell_Sixteen_Teacher_Id = @"PLVHCLinkMicWindowSixteenTeacherCellId";

@interface PLVHCLinkMicWindowsView ()<
UICollectionViewDelegate,
UICollectionViewDataSource,
PLVHCLinkMicCollectionViewFlowLayoutDelegate,
PLVHCLinkMicTeacherPreViewDelegate,
PLVHCLinkMicSettingPopViewDelegate
>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCLinkMicWindowsView) self
/// ├── (UICollectionView) collectionView (lowest)
/// │   ├── (PLVHCLinkMicWindowCell) windowCell
/// │   ├── ...
/// │   └── (PLVHCLinkMicWindowCell) windowCell
/// ├── (PLVHCLinkMicTeacherPreView) teacherPreView
/// └── (PLVHCLinkMicPlaceholderView) teacherPrePlaceholderView
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) PLVHCLinkMicTeacherPreView *teacherPreView; // 讲师预览画面视图（初始化连麦窗口时，如果未上课则添加本视图，上课后被移除）
@property (nonatomic, strong) PLVHCLinkMicPlaceholderView *teacherPrePlaceholderView; // 讲师预览画面占位图（存在teacherPreView，并且teacherPreView被放大（移出连麦窗口）时才添加该视图）
@property (nonatomic, strong) PLVHCLinkMicSettingPopView *settingPopView; // 连麦窗口操作弹窗

#pragma mark 状态
@property (nonatomic, assign) BOOL localPreviewInZoom; // 本地预览画面在放大区域
@property (nonatomic, strong) NSMutableArray <NSNumber *> *cellIndexArray; // 把数据源下标按照列表展示顺序重新排序

#pragma mark 数据
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> *dataArray; // 当前连麦在线用户数组
@property (nonatomic, assign, readonly) PLVRoomUserType userType; // 用户类型
@property (nonatomic, assign, readonly) NSInteger linkNumber; // 目前课节设置允许连麦人数
@property (nonatomic, assign, readonly) NSInteger maxLinkMicNumber; // 可显示最多连麦人数（不一定等于linkNumber，linkNumber不包含讲师）

@end

@implementation PLVHCLinkMicWindowsView {
    /// 操作映射字典的信号量，防止多线程读写
    dispatch_semaphore_t _mapDictLock;
}

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化信号量
        _mapDictLock = dispatch_semaphore_create(1);
        
        // 初始化UI
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
  
    //7~16人连麦讲师cell size 和1v6人连麦的cell size
    CGSize itemSize = self.linkNumber > 6 ? CGSizeMake(148, 85) : CGSizeMake(106, 60);
    if ([PLVHCUtils sharedUtils].isPad) { // iPad适配
        itemSize = self.linkNumber > 6 ? CGSizeMake(205, 115.3) : CGSizeMake(146, 82);
    }
    
    if (!self.localPreviewInZoom && _teacherPreView) {
        self.teacherPreView.bounds = (CGRect){{0,0}, itemSize};
        self.teacherPreView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
    _teacherPrePlaceholderView.bounds = (CGRect){{0,0}, itemSize};
    _teacherPrePlaceholderView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

#pragma mark - [ Public Method ]

- (void)reloadLinkMicUserWindows {
    if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass) {
        if (_teacherPreView) { // 已上课则确保讲师预览视图已被清理
            _teacherPreView.delegate = nil;
            [_teacherPreView removeFromSuperview];
            _teacherPreView = nil;
            [_teacherPrePlaceholderView removeFromSuperview];
            _teacherPrePlaceholderView = nil;
        }
        // 刷新列表列表
        self.collectionView.hidden = NO;
        [self.collectionView reloadData];
    }
}

- (void)enableLocalMic:(BOOL)enable {
    if (_teacherPreView) {
        [self.teacherPreView enableLocalMic:enable];
    }
}

- (void)enableLocalCamera:(BOOL)enable {
    if (_teacherPreView) {
        [self.teacherPreView enableLocalCamera:enable];
    }
}

- (void)startPreview {
    if (_teacherPreView) {
        [self.teacherPreView startPreview];
    }
}

- (void)showLocalSettingView {
    if (self.userType == PLVRoomUserTypeSCStudent) {
        return;
    }
    [self.settingPopView showLocalSettingView];
}

- (void)showSettingViewWithUser:(PLVLinkMicOnlineUser *)user {
    if (self.userType == PLVRoomUserTypeSCStudent) {
        return;
    }
    [self.settingPopView showSettingViewWithUser:user];
}

- (UIView *)getLinkMicItemViewWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    
    // 正在 本地预览 场景
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if (_teacherPreView && [userId isEqualToString:roomUser.viewerId]) {
        self.localPreviewInZoom = YES; // 设置本地预览正在放大区域
        [self showTeacherPrePlaceholderView:YES]; // 连麦列表显示占位图
        return self.teacherPreView; // 返回本地预览视图对象
    }
    
    // 正在 上课 场景 
    NSArray <PLVLinkMicOnlineUser *> *array = [self.dataArray copy];
    __block PLVLinkMicOnlineUser *userModel = nil;
    [array enumerateObjectsUsingBlock:^(PLVLinkMicOnlineUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            userModel = obj;
            *stop = YES;
        }
    }];
    
    if (!userModel) { // 当前用户还未成功连麦，返回nil； 等待此用户会连麦成功后，连麦列表刷新后调用notifyListenerDidRefreshLinkMiItemView:刷新放大视图。
        return nil;
    }
    
    PLVHCLinkMicWindowCell *cell = [self cellWithLinkMicUser:userModel];
    if (!cell ||
        ![cell isKindOfClass:[PLVHCLinkMicWindowCell class]] ||
        !cell.itemView) {
        return nil;
    }
    [cell showZoomPlaceholder:YES]; // 当前用户显示占位图
    return (UIView *)cell.itemView;
}

#pragma mark - [ Private Method ]

#pragma mark Getter & Setter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        PLVHCLinkMicCollectionViewFlowLayout *layout = [[PLVHCLinkMicCollectionViewFlowLayout alloc] init];
        layout.delegate = self;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = [UIColor clearColor];
        [collectionView registerClass:[PLVHCLinkMicWindowSixCell class] forCellWithReuseIdentifier:PLVHCLinkMicWindowCell_Six_Id];
        [collectionView registerClass:[PLVHCLinkMicWindowSixteenCell class] forCellWithReuseIdentifier:PLVHCLinkMicWindowCell_Sixteen_Id];
        [collectionView registerClass:[PLVHCLinkMicWindowSixteenTeacherCell class] forCellWithReuseIdentifier:PLVHCLinkMicWindowCell_Sixteen_Teacher_Id];
        collectionView.hidden = YES;
        _collectionView = collectionView;
    }
    return _collectionView;
}

- (PLVHCLinkMicPlaceholderView *)teacherPrePlaceholderView {
    if (!_teacherPrePlaceholderView) {
        _teacherPrePlaceholderView = [[PLVHCLinkMicPlaceholderView alloc] init];
        NSString *nickName = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerName;
        [_teacherPrePlaceholderView setupNickname:[NSString stringWithFormat:@"老师-%@的位置",nickName]];
    }
    return _teacherPrePlaceholderView;
}

- (PLVHCLinkMicSettingPopView *)settingPopView {
    if (!_settingPopView) {
        _settingPopView = [[PLVHCLinkMicSettingPopView alloc] init];
        _settingPopView.delegate = self;
    }
    return _settingPopView;
}

- (NSMutableArray <NSNumber *> *)cellIndexArray {
    if (!_cellIndexArray) {
        _cellIndexArray  = [NSMutableArray array];
    }
    return _cellIndexArray;
}

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsViewGetCurrentUserModelArray:)]) {
        NSArray *listArray = [self.delegate plvHCLinkMicWindowsViewGetCurrentUserModelArray:self];
        if (self.linkNumber > 6) {
            [self updateCellIndexArrayWithUserArray:listArray];
        }
        return listArray;
    }
    return nil;
}

- (PLVRoomUserType)userType {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.roomUser.viewerType;
}

- (NSInteger)linkNumber {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.linkNumber;
}

- (NSInteger)maxLinkMicNumber {
    NSInteger maxLinkMicNumber;
    if ([PLVHiClassManager sharedManager].groupState == PLVHiClassGroupStateInGroup) { // 分组
        maxLinkMicNumber = self.linkNumber + ([PLVHiClassManager sharedManager].teacherInGroup ? 1 : 0);
    } else { // 大房间
        maxLinkMicNumber = self.linkNumber + 1;
    }
    return maxLinkMicNumber;
}

#pragma mark Initialize

- (void)updateCellIndexArrayWithUserArray:(NSArray *)userArray {
    // 每次获取到数据后都清空cellIndexArray数组，根据数据源重新生成
    [self.cellIndexArray removeAllObjects];
    
    if (userArray.count < 2) { // 数组数目小于2不需要更新cellIndexArray，直接按数组原顺序显示
        return;
    }
    
    dispatch_semaphore_wait(_mapDictLock, DISPATCH_TIME_FOREVER);
    
    // 按数据长度区分奇偶两个数组，数组内容是数据下标
    NSInteger number = userArray.count;
    NSMutableArray <NSNumber *> *evenNumberArray = [NSMutableArray array]; //偶数
    NSMutableArray <NSNumber *> *oddNumberArray = [NSMutableArray array]; //奇数
    for (NSInteger i = 1; i < number; i ++) {
        if (i%2 == 0) {
            [evenNumberArray addObject:@(i)];
        } else {
            [oddNumberArray addObject:@(i)];
        }
    }
    
    // 把奇数数组分成 1、5、9，... 跟 3，7，11，...
    NSMutableArray <NSNumber *> *oddFirstArray = [NSMutableArray array];
    NSMutableArray <NSNumber *> *oddSecondArray = [NSMutableArray array];
    [oddNumberArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((([obj integerValue] + 1)/2) % 2 == 0) {
            [oddFirstArray addObject:obj]; // 3，7，11，...
        } else {
            [oddSecondArray addObject:obj]; // 1，5, 9，...
        }
    }];
    
    // 生成奇数数组 oddCalArray，顺序为 3、1、7、5、11、9...
    NSInteger maxCount = MAX(oddFirstArray.count, oddSecondArray.count);
    NSMutableArray <NSNumber *> *oddCalArray = [NSMutableArray array]; //偶数
    for (NSInteger index = 0 ; index < maxCount; index ++) {
        if (oddFirstArray.count > index) {
            [oddCalArray addObject:oddFirstArray[index]];
        }
        if (oddSecondArray.count > index) {
            [oddCalArray addObject:oddSecondArray[index]];
        }
    }
    
    // 把奇数数组 oddCalArray 置反，顺序为 9、11、5、7、1、3
    NSArray *oddSortArray = [[oddCalArray reverseObjectEnumerator] allObjects];
    
    // 对索引进行排序，先是置反后的奇数数组，然后是老师（0），最后是偶数数组
    // 9、11、5、7、1、3、0、2、4、6、8...
    [self.cellIndexArray addObjectsFromArray:oddSortArray];
    [self.cellIndexArray addObject:@(0)];  // 老师的下标位置
    [self.cellIndexArray addObjectsFromArray:evenNumberArray];
    
    dispatch_semaphore_signal(_mapDictLock);
}

#pragma mark 根据UI下标获取数据模型、数据下标

- (PLVLinkMicOnlineUser *)linkMicUserWithCellIndex:(NSInteger)cellIndex {
    NSInteger dataIndex = [self dataIndexWithCellIndex:cellIndex];
    PLVLinkMicOnlineUser *user;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:getUserModelFromOnlineUserArrayWithIndex:)]) {
        user = [self.delegate plvHCLinkMicWindowsView:self getUserModelFromOnlineUserArrayWithIndex:dataIndex];
    }
    return user;
}

- (NSInteger)dataIndexWithCellIndex:(NSInteger)cellIndex {
    if ([self.cellIndexArray count] == 0) {
        return cellIndex;
    }
    
    if (cellIndex >= [self.cellIndexArray count]) {
        return -1;
    }
    
    return [self.cellIndexArray[cellIndex] integerValue];
}

#pragma mark 根据数据模型、数据下标获取UI、UI下标

- (PLVHCLinkMicWindowCell *)cellWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    PLVHCLinkMicWindowCell *cell = nil;
    NSInteger cellIndex = [self cellIndexWithUserId:linkMicUser.userId];
    if (cellIndex >= 0) { // 防止cell不是visible的或者index超過有效范围，就返回nil
        [self.collectionView layoutIfNeeded];
        cell = (PLVHCLinkMicWindowCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:0]];
    }
    return cell;
}

- (NSInteger)cellIndexWithUserId:(NSString *)userId {
    NSInteger dataIndex = -1;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        dataIndex = [self.delegate plvHCLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicOnlineUser * _Nonnull enumerateUser) {
            return [enumerateUser.linkMicUserId isEqualToString:userId];
        }];
    }
    return [self cellIndexWithDataIndex:dataIndex];
}

- (NSInteger)cellIndexWithDataIndex:(NSInteger)dataIndex {
    if (dataIndex < 0) {
        return -1;
    }
    
    if ([self.cellIndexArray count] == 0) {
        return dataIndex;
    }
    
    __block NSInteger cellIndex = -1;
    [self.cellIndexArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj integerValue] == dataIndex) {
            cellIndex = idx;
            *stop = YES;
        }
    }];
    return cellIndex;
}

#pragma mark UI 视图相关

- (void)setupUI {
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C36"];
    [self addSubview:self.collectionView];
    self.collectionView.hidden = [PLVHiClassManager sharedManager].status != PLVHiClassStatusInClass;
    
    if ([PLVHiClassManager sharedManager].status != PLVHiClassStatusInClass) {
        _teacherPreView = [[PLVHCLinkMicTeacherPreView alloc] init];
        _teacherPreView.delegate = self;
        [self addSubview:_teacherPreView];
    }
}

/// 根据用户模型获取cellID
- (NSString *)cellIdentifierWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    if (self.linkNumber < 7) {
        return PLVHCLinkMicWindowCell_Six_Id;
    }
    if (linkMicUser.userType == PLVSocketUserTypeTeacher ||
        (linkMicUser.groupLeader && ![PLVHiClassManager sharedManager].teacherInGroup)) {
        return PLVHCLinkMicWindowCell_Sixteen_Teacher_Id;
    }
    return PLVHCLinkMicWindowCell_Sixteen_Id;
}

// 销毁数据模型之前，移除连麦rtc画布视图
- (void)cleanLinkMicCanvasViewWithLinkMicModel:(PLVLinkMicOnlineUser *)linkMicUser {
    PLVHCLinkMicCanvasView *canvasView = linkMicUser.canvasView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [canvasView removeRTCView];
        [canvasView removeFromSuperview];
    });
}

// 若连麦用户Model未有连麦rtc画布视图，则此时需创建并交由连麦用户Model进行管理
- (void)setupLinkMicCanvasViewWithLinkMicModel:(PLVLinkMicOnlineUser *)linkMicUser {
    if (linkMicUser.canvasView == nil) {
        PLVHCLinkMicCanvasView *canvasView = [[PLVHCLinkMicCanvasView alloc] init];
        [canvasView addRTCView:linkMicUser.rtcView];
        linkMicUser.canvasView = canvasView;
    }
}

- (void)showTeacherPrePlaceholderView:(BOOL)show {
    if (show) {
        [self addSubview:self.teacherPrePlaceholderView];
    } else {
        if (_teacherPrePlaceholderView) {
            [_teacherPrePlaceholderView removeFromSuperview];
        }
    }
}

#pragma mark 发送PLVHCLinkMicWindowsViewDelegate协议方法

- (void)notifyListenerDidRefreshLinkMiItemView:(PLVHCLinkMicItemView *)itemView {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:didRefreshLinkMiItemView:)]) {
        [self.delegate plvHCLinkMicWindowsView:self didRefreshLinkMiItemView:itemView];
    }
}

- (void)notifyListenerDidSwitchLinkMicWithExternalView:(UIView *)exView userId:(NSString *)userId showInZoom:(BOOL)showInZoom{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:didSwitchLinkMicWithExternalView:userId:showInZoom:)]) {
        [self.delegate plvHCLinkMicWindowsView:self didSwitchLinkMicWithExternalView:exView userId:userId showInZoom:showInZoom];
    }
}

#pragma mark - [ Delegate ]

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return MIN(self.maxLinkMicNumber, self.dataArray.count); // 确保连麦列表展示的人数，不得超过房间设置的连麦人数(讲师不占用人数)
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLinkMicOnlineUser *linkMicUser = [self linkMicUserWithCellIndex:indexPath.row];
    NSString *cellIdentifier = [self cellIdentifierWithLinkMicUser:linkMicUser];
    PLVHCLinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!linkMicUser) {
        return cell;
    }
    
    [self setupLinkMicCanvasViewWithLinkMicModel:linkMicUser];
    
    // 设置 连麦用户的 ’即将销毁‘ Block，用于在连麦用户退出时，及时回收资源
    __weak typeof(self) weakSelf = self;
    linkMicUser.willDeallocBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [[PLVHCLinkMicZoomManager sharedInstance] linkMicUserWillDealloc:onlineUser.userId]; // 移除连麦放大视图窗口
        [weakSelf cleanLinkMicCanvasViewWithLinkMicModel:onlineUser];
    };
    
    [cell updateOnlineUser:linkMicUser];
    
    if (linkMicUser.inLinkMicZoom) { // 连麦人数变化，cell可能会重新创建，所以需要重新将itemView赋值给放大区域
        [self notifyListenerDidRefreshLinkMiItemView:cell.itemView];
    }
    
    return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.userType != PLVRoomUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
        return;
    }
    PLVLinkMicOnlineUser *linkMicUserModel = [self linkMicUserWithCellIndex:indexPath.row];
    if (linkMicUserModel.userType == PLVRoomUserTypeTeacher &&
        [PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 组长无法操作讲师连麦
        return;
    }
    if (linkMicUserModel.inLinkMicZoom) { // 正在放大区域无法操作
        return;
    }
    [self.settingPopView showSettingViewWithUser:linkMicUserModel];
}

#pragma mark PLVHCLinkMicCollectionViewFlowLayoutDelegate

- (BOOL)linkMicFlowLayout:(PLVHCLinkMicCollectionViewFlowLayout *)flowLayout teacherItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLinkMicOnlineUser *linkMicUserModel = [self linkMicUserWithCellIndex:indexPath.row];
    if (linkMicUserModel.userType == PLVSocketUserTypeTeacher ||
        (linkMicUserModel.groupLeader && ![PLVHiClassManager sharedManager].teacherInGroup)) {
        return YES;
    }
    return NO;
}

- (CGSize)linkMicFlowLayoutGetWindowsViewSize:(PLVHCLinkMicCollectionViewFlowLayout *)flowLayout {
    return self.bounds.size;
}

#pragma mark PLVHCLinkMicTeacherPreViewDelegate

- (void)didTeacherPreViewSelected:(PLVHCLinkMicTeacherPreView *)preView {
    [self.settingPopView setupLocalPrevierUserInLinkMicZoom:self.localPreviewInZoom]; // 配置是否在放大区域UI
    [self.settingPopView showLocalSettingView];
}

#pragma mark PLVHCLinkMicSettingPopViewDelegate

- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView didSwitchLinkMicWithUserModel:(nonnull PLVLinkMicOnlineUser *)userModel localPreviewUser:(BOOL)localPreviewUser showInZoom:(BOOL)showInZoom {
    if (showInZoom &&
        [PLVHCLinkMicZoomManager sharedInstance].isMaxZoomNum) {
        [PLVHCUtils showToastInWindowWithMessage:[NSString stringWithFormat:@"最多支持放大%d个摄像头",kPLVHCLinkMicZoomMAXNum]];
        return;
    }
    
    UIView *exView = nil;
    NSString *userId = nil;
    self.localPreviewInZoom = localPreviewUser && showInZoom;
    
    if (localPreviewUser) {
        exView = self.teacherPreView;
        userId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
        
        [self showTeacherPrePlaceholderView:showInZoom];
        if (!showInZoom) { // 显示本地预览画面回连麦列表
            [self addSubview:self.teacherPreView];
        }
    } else {
        userId = userModel.userId;
        PLVHCLinkMicWindowCell *cell = [self cellWithLinkMicUser:userModel];
        if (cell &&
            [cell isKindOfClass:[PLVHCLinkMicWindowCell class]] &&
            cell.itemView) {
            exView = (UIView *)cell.itemView;
        }
    }
    if (!exView && showInZoom) { // 放大连麦视图需要确保有exView
        return;
    }
    
    [self notifyListenerDidSwitchLinkMicWithExternalView:exView userId:userId showInZoom:showInZoom];
}

@end
