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

//模块
#import "PLVHCUtils.h"
#import "PLVRoomDataManager.h"
#import "PLVLinkMicOnlineUser+HC.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const PLVHCLinkMicWindowCell_Six_Id = @"PLVHCLinkMicWindowSixCellId";
static NSString *const PLVHCLinkMicWindowCell_Sixteen_Id = @"PLVHCLinkMicWindowSixteenCellId";
static NSString *const PLVHCLinkMicWindowCell_Sixteen_Teacher_Id = @"PLVHCLinkMicWindowSixteenTeacherCellId";

@interface PLVHCLinkMicWindowsView ()<
UICollectionViewDelegate,
UICollectionViewDataSource,
PLVHCLinkMicCollectionViewFlowLayoutDelegate,
PLVHCLinkMicTeacherPreViewDelegate,
PLVHCLinkMicSettingPopViewDelegate>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCLinkMicWindowsView) self
/// ├── (UICollectionView) collectionView (lowest)
/// │   ├── (PLVHCLinkMicWindowCell) windowCell
/// │   ├── ...
/// │   └── (PLVHCLinkMicWindowCell) windowCell
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) PLVHCLinkMicSettingPopView *settingPopView;
@property (nonatomic, strong) PLVHCLinkMicTeacherPreView *teacherPreView;//在未上课时，初次加载才会有本视图，上课后将其置空

#pragma mark 数据
@property (nonatomic, strong, readonly) NSArray <PLVLinkMicOnlineUser *> * dataArray; // 只读，当前连麦在线用户数组
@property (nonatomic, assign, readonly) BOOL shouldShowLocalPreview; //第一次加载且没上课才会有预览图
@property (nonatomic, assign) PLVRoomUserType userType;//用户类型
@property (nonatomic, assign) NSInteger linkNumber;//房间设置连麦人数
@property (nonatomic, assign) CGSize cellItemSize; //不同连麦人数的cell size
@property (nonatomic, strong) NSMutableDictionary *indexMapDict; //下表映射字典

@end

@implementation PLVHCLinkMicWindowsView {
    /// 操作映射字典的信号量，防止多线程读写
    dispatch_semaphore_t _mapDictLock;
}

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.userType = roomData.roomUser.viewerType;
        self.linkNumber = roomData.lessonInfo.linkNumber;
        self.indexMapDict = [NSMutableDictionary dictionary];
        // 初始化信号量
        _mapDictLock = dispatch_semaphore_create(1);
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.shouldShowLocalPreview) {
        self.teacherPreView.bounds = (CGRect){{0,0}, self.cellItemSize};
        self.teacherPreView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
}

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

- (PLVHCLinkMicSettingPopView *)settingPopView {
    if (!_settingPopView) {
        _settingPopView = [[PLVHCLinkMicSettingPopView alloc] init];
        _settingPopView.delegate = self;
    }
    return _settingPopView;
}

- (PLVHCLinkMicTeacherPreView *)teacherPreView {
    if (!_teacherPreView) {
        _teacherPreView = [[PLVHCLinkMicTeacherPreView alloc] init];
        _teacherPreView.delegate = self;
        _teacherPreView.hidden = YES;
    }
    return _teacherPreView;
}

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsViewGetCurrentUserModelArray:)]) {
        NSArray *listArray = [self.delegate plvHCLinkMicWindowsViewGetCurrentUserModelArray:self];
        if (self.linkNumber > 6) {
            [self mapUserListIndexWithUserArray:listArray];
        }
        return listArray;
    }
    return nil;
}

- (BOOL)shouldShowLocalPreview {
    if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
        return NO;
    }
    
    if (!_teacherPreView) {
        return NO;
    }
   
    return YES;
}

#pragma mark - [ Public Method ]

- (void)reloadLinkMicUserWindows {
    if (self.shouldShowLocalPreview) {
        return;
    }
    self.collectionView.hidden = NO;
    [self clearTeacherPreView];
    [self.collectionView reloadData];
}

- (void)linkMicWindowsViewEnableLocalMic:(BOOL)enable {
    if (_teacherPreView) {
        [self.teacherPreView teacherPreViewEnableMicrophone:enable];
    }
}

- (void)linkMicWindowsViewEnableLocalCamera:(BOOL)enable {
    if (_teacherPreView) {
        [self.teacherPreView teacherPreViewEnableCamera:enable];
    }
}

- (void)linkMicWindowsViewSwitchLocalCameraFront:(BOOL)switchFront {
    if (_teacherPreView) {
        [self.teacherPreView teacherPreViewSwitchCameraFront:switchFront];
    }
}

- (void)linkMicWindowsViewStartRunning {
    if (_teacherPreView) {
        [self.teacherPreView startRunning];
    }
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C36"];
    [self addSubview:self.collectionView];
    [self addSubview:self.teacherPreView];
    self.teacherPreView.hidden = !self.shouldShowLocalPreview;
    //7~16人连麦讲师cell size 和1v6人连麦的cell size
    self.cellItemSize = self.linkNumber > 6 ? CGSizeMake(148, 85) : CGSizeMake(106, 60);
}

- (PLVLinkMicOnlineUser *)readUserModelFromDataArray:(NSInteger)targetIndex{
    NSInteger mapIndex = [self getMapIndexWithRow:targetIndex];
    PLVLinkMicOnlineUser * user;
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:getUserModelFromOnlineUserArrayWithIndex:)]) {
        user = [self.delegate plvHCLinkMicWindowsView:self getUserModelFromOnlineUserArrayWithIndex:mapIndex];
    }
    return user;
}

- (void)cleanLinkMicCellWithLinkMicUser:(PLVLinkMicOnlineUser *)didLeftLinkMicUser{
    PLVHCLinkMicCanvasView *canvasView = didLeftLinkMicUser.canvasView;
    dispatch_async(dispatch_get_main_queue(), ^{
        /// 回收资源
        [canvasView removeRTCView];
        [canvasView removeFromSuperview];
    });
}

// 若 连麦用户Model 未有 连麦rtc画布视图，则此时需创建并交由 连麦用户Model 进行管理
- (void)checkUserModelAndSetupLinkMicCanvasView:(PLVLinkMicOnlineUser *)linkMicUserModel{
    if (linkMicUserModel.canvasView == nil) {
        PLVHCLinkMicCanvasView *canvasView = [[PLVHCLinkMicCanvasView alloc] init];
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

//创建用户下标映射关系，因为连麦7～16用户的下标顺序不同
- (void)mapUserListIndexWithUserArray:(NSArray *)userArray {
    [self.indexMapDict removeAllObjects];
    if (userArray.count < 2) { return; }
    
    dispatch_semaphore_wait(_mapDictLock, DISPATCH_TIME_FOREVER);
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
    NSMutableArray <NSNumber *> *oddFirstArray = [NSMutableArray array];
    NSMutableArray <NSNumber *> *oddSecondArray = [NSMutableArray array];
    [oddNumberArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((([obj integerValue] + 1)/2) % 2 == 0) {
            [oddFirstArray addObject:obj];
        } else {
            [oddSecondArray addObject:obj];
        }
    }];
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
    NSArray *oddSortArray = [[oddCalArray reverseObjectEnumerator] allObjects];
    NSMutableArray *listIndexArray = [NSMutableArray arrayWithCapacity:number]; //偶数
    [listIndexArray addObjectsFromArray:oddSortArray];
    [listIndexArray addObject:@(0)];  //老师的下标位置
    [listIndexArray addObjectsFromArray:evenNumberArray];
    for (NSInteger keyIndex = 0; keyIndex < number; keyIndex ++) {
        if (listIndexArray.count > keyIndex) {
            NSString *keyIndexString = [NSString stringWithFormat:@"%ld", (long)keyIndex];
            plv_dict_set(self.indexMapDict, keyIndexString, listIndexArray[keyIndex]);
        }
    }
    dispatch_semaphore_signal(_mapDictLock);
}

//通过indexPath.row 获取实际对应的数据下标
- (NSInteger)getMapIndexWithRow:(NSInteger)row {
    if (self.indexMapDict.allKeys.count == 0) {
        return row;
    }
    NSString *rowString = [NSString stringWithFormat:@"%ld", (long)row];
    NSInteger mapIndex = PLV_SafeIntegerForDictKey(self.indexMapDict, rowString);
    return mapIndex;
}

- (NSString *)getIdentifierWithUserModel:(PLVLinkMicOnlineUser *)userModel {
    if (self.linkNumber < 7) {
        return PLVHCLinkMicWindowCell_Six_Id;
    }
    if (userModel.userType == PLVSocketUserTypeTeacher) {
        return PLVHCLinkMicWindowCell_Sixteen_Teacher_Id;
    }
    return PLVHCLinkMicWindowCell_Sixteen_Id;
}

- (void)clearTeacherPreView {
    if (_teacherPreView) {
        [_teacherPreView clear];
        _teacherPreView.delegate = nil;
        [_teacherPreView removeFromSuperview];
        _teacherPreView = nil;
    }
}

#pragma mark - [ Delegate ]

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLinkMicOnlineUser *linkMicUserModel = [self readUserModelFromDataArray:indexPath.row];
    NSString *cellIdentifier = [self getIdentifierWithUserModel:linkMicUserModel];
    PLVHCLinkMicWindowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!linkMicUserModel) {
        NSLog(@"PLVHCLinkMicWindowsView - cellForItemAtIndexPath for %@ error",indexPath);
        return cell;
    }
    
    [self checkUserModelAndSetupLinkMicCanvasView:linkMicUserModel];
    [self setupUserModelWillDeallocBlock:linkMicUserModel];
    [cell updateOnlineUser:linkMicUserModel];
    return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.userType == PLVRoomUserTypeSCStudent) {
        return;
    }
    PLVLinkMicOnlineUser *linkMicUserModel = [self readUserModelFromDataArray:indexPath.row];
    [self.settingPopView showSettingViewWithUser:linkMicUserModel];
}

#pragma mark PLVHCLinkMicCollectionViewFlowLayoutDelegate

- (BOOL)linkMicFlowLayout:(PLVHCLinkMicCollectionViewFlowLayout *)flowLayout teacherItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLinkMicOnlineUser *linkMicUserModel = [self readUserModelFromDataArray:indexPath.row];
    if (linkMicUserModel.userType == PLVSocketUserTypeTeacher) {
        return YES;
    }
    return NO;
}

- (CGSize)linkMicFlowLayoutGetWindowsViewSize:(PLVHCLinkMicCollectionViewFlowLayout *)flowLayout {
    return self.bounds.size;
}

#pragma mark PLVHCLinkMicTeacherPreViewDelegate

- (void)teacherPreView:(PLVHCLinkMicTeacherPreView *)preView didSelectAtUserConfig:(NSDictionary *)configDict {
    [self.settingPopView showSettingViewWithLocalConfig:configDict];
}

#pragma mark PLVHCLinkMicSettingPopViewDelegate

- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView enableMic:(BOOL)enable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:enableLocalMic:)]) {
        [self.delegate plvHCLinkMicWindowsView:self enableLocalMic:enable];
    }
}

- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView enableCamera:(BOOL)enable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:enableLocalCamera:)]) {
        [self.delegate plvHCLinkMicWindowsView:self enableLocalCamera:enable];
    }
}

- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView cameraFront:(BOOL)switchFront {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvHCLinkMicWindowsView:switchLocalCameraFront:)]) {
        [self.delegate plvHCLinkMicWindowsView:self switchLocalCameraFront:switchFront];
    }
}

@end
