//
//  PLVSABeautyFaceViewController.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyFaceViewController.h"
// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
// UI
#import "PLVSABeautyCollectionViewCell.h"
// 模块
#import "PLVSABeautyCellModel.h"
#import "PLVBeautyViewModel.h"

@interface PLVSABeautyFaceViewController () <
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UICollectionViewDelegate
>

#pragma mark UI
@property (nonatomic, strong) UICollectionView *collectionView;

@end

static CGFloat kItemWidth = 46; // item宽度
static int kItemLineNum = 3; // 每行item数

@implementation PLVSABeautyFaceViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if ([PLVFdUtil checkArrayUseable:self.dataArray]) {
        [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    [[PLVBeautyViewModel sharedViewModel] selectBeautyOption:PLVBBeautyOption_ReshapeDeformEye];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

#pragma mark - [ Override ]
- (void)setupDataArray {
    [super setupDataArray];
    if ([PLVBeautyViewModel sharedViewModel].beautySDKType == PLVBeautySDKTypeProfessional){
        self.dataArray = [NSArray arrayWithObjects:
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"大眼") imageName:@"plvsa_beauty_face_eye" beautyOption:PLVBBeautyOption_ReshapeDeformEye selected:YES],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"瘦脸") imageName:@"plvsa_beauty_face_overall" beautyOption:PLVBBeautyOption_ReshapeDeformOverAll],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"下颌") imageName:@"plvsa_beauty_face_jawbone" beautyOption:PLVBBeautyOption_ReshapeDeformZoomJawbone],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"额头") imageName:@"plvsa_beauty_face_head" beautyOption:PLVBBeautyOption_ReshapeDeformForeHead],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"亮眼") imageName:@"plvsa_beauty_face_brightenEye" beautyOption:PLVBBeautyOption_ReshapeBeautyBrightenEye],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"瘦鼻") imageName:@"plvsa_beauty_face_nose" beautyOption:PLVBBeautyOption_ReshapeDeformNose],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"嘴巴") imageName:@"plvsa_beauty_face_mouth" beautyOption:PLVBBeautyOption_ReshapeDeformZoomMouth],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"美牙") imageName:@"plvsa_beauty_face_whitenTeeth" beautyOption:PLVBBeautyOption_ReshapeBeautyWhitenTeeth],nil];
    }
    else if ([PLVBeautyViewModel sharedViewModel].beautySDKType == PLVBeautySDKTypeLight){
        // 保利威轻美颜 重新配置数据
        self.dataArray = [NSArray arrayWithObjects:
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"大眼") imageName:@"plvsa_beauty_face_eye" beautyOption:PLVBBeautyOption_ReshapeDeformEye selected:YES],
            [[PLVSABeautyCellModel alloc] initWithTitle:PLVLocalizedString(@"瘦脸") imageName:@"plvsa_beauty_face_overall" beautyOption:PLVBBeautyOption_ReshapeDeformOverAll],nil];
    }
}

- (void)showContentView {
    [super showContentView];
    if ([PLVBeautyViewModel sharedViewModel].beautyIsOpen) {
        [self didSelectItemAtIndexPath:self.selectedIndexPath];
    } else {
        [self.collectionView reloadData];
    }
}

- (void)beautyOpen:(BOOL)open {
    [super beautyOpen:open];
    [self.collectionView reloadData];
    if (open && self.selectedIndexPath &&
        self.dataArray.count > self.selectedIndexPath.item) {
        [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = [PLVSAUtils sharedUtils].isLandscape ?  UICollectionViewScrollDirectionVertical : UICollectionViewScrollDirectionHorizontal;
        flowLayout.itemSize = CGSizeMake(kItemWidth, 61);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[PLVSABeautyCollectionViewCell class] forCellWithReuseIdentifier:PLVSABeautyCollectionViewCell.cellID];
    }
    return _collectionView;
}

#pragma mark didSelectItem
- (void)didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([PLVBeautyViewModel sharedViewModel].beautyIsOpen &&
        indexPath &&
        self.dataArray.count > indexPath.row) {
        self.selectedIndexPath = indexPath;
        
        PLVSABeautyCellModel *model = self.dataArray[indexPath.row];
        for (PLVSABeautyCellModel *tempModel in self.dataArray) {
            [tempModel updateSelected:model == tempModel];
        }
        [[PLVBeautyViewModel sharedViewModel] selectBeautyOption:model.beautyOption];
    }
}

#pragma mark - [ Delegate ]
#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVSABeautyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PLVSABeautyCollectionViewCell.cellID forIndexPath:indexPath];
    if (self.dataArray.count > indexPath.row) {
        PLVSABeautyCellModel *model = self.dataArray[indexPath.row];
        [cell updateCellModel:model beautyOpen:[PLVBeautyViewModel sharedViewModel].beautyIsOpen];
        cell.userInteractionEnabled = [PLVBeautyViewModel sharedViewModel].beautyIsOpen;
    }
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if ([PLVSAUtils sharedUtils].isLandscape) { // 横屏collectionView垂直滚动，minimumLineSpacing为上下间距
        return 20;
    } else { // 竖屏collectionView水平滚动，minimumLineSpacing为左右间距
        return 32;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if ([PLVSAUtils sharedUtils].isLandscape) { // 横屏collectionView垂直滚动，minimumInteritemSpacing为左右间距
        return (CGRectGetWidth(self.view.frame) - kItemWidth * kItemLineNum) / kItemLineNum;
    } else { // 竖屏collectionView水平滚动，minimumInteritemSpacing为上下间距
        return 0;
    }
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self didSelectItemAtIndexPath:indexPath];
}

@end
