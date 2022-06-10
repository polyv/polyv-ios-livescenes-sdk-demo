//
//  PLVLSBeautyFaceViewController.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautyFaceViewController.h"
// 工具
#import "PLVLSUtils.h"
// UI
#import "PLVLSBeautyCollectionViewCell.h"
// 模块
#import "PLVLSBeautyCellModel.h"
#import "PLVLSBeautyViewModel.h"

@interface PLVLSBeautyFaceViewController () <
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UICollectionViewDelegate
>

#pragma mark UI
@property (nonatomic, strong) UICollectionView *collectionView;

@end

static CGFloat kItemWidth = 36; // item宽度
static CGFloat kItemHeight = 61; // item高度

@implementation PLVLSBeautyFaceViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [[PLVLSBeautyViewModel sharedViewModel] selectBeautyOption:PLVBBeautyOption_ReshapeDeformEye];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

#pragma mark - [ Override ]
- (void)setupDataArray {
    [super setupDataArray];
    self.dataArray = [NSArray arrayWithObjects:
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"大眼" imageName:@"plvls_beauty_face_eye" beautyOption:PLVBBeautyOption_ReshapeDeformEye selected:YES],
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"瘦脸" imageName:@"plvls_beauty_face_overall" beautyOption:PLVBBeautyOption_ReshapeDeformOverAll],
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"下颌" imageName:@"plvls_beauty_face_jawbone" beautyOption:PLVBBeautyOption_ReshapeDeformZoomJawbone],
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"额头" imageName:@"plvls_beauty_face_head" beautyOption:PLVBBeautyOption_ReshapeDeformForeHead],
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"亮眼" imageName:@"plvls_beauty_face_brightenEye" beautyOption:PLVBBeautyOption_ReshapeBeautyBrightenEye],
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"瘦鼻" imageName:@"plvls_beauty_face_nose" beautyOption:PLVBBeautyOption_ReshapeDeformNose],
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"嘴巴" imageName:@"plvls_beauty_face_mouth" beautyOption:PLVBBeautyOption_ReshapeDeformZoomMouth],
                  [[PLVLSBeautyCellModel alloc] initWithTitle:@"美牙" imageName:@"plvls_beauty_face_whitenTeeth" beautyOption:PLVBBeautyOption_ReshapeBeautyWhitenTeeth],nil];
}

- (void)showContentView {
    [super showContentView];
    if ([PLVLSBeautyViewModel sharedViewModel].beautyIsOpen) {
        [self didSelectItemAtIndexPath:self.selectedIndexPath];
    } else {
        [self.collectionView reloadData];
    }
}

- (void)beautyOpen:(BOOL)open {
    [super beautyOpen:open];
    [self.collectionView reloadData];
    if (open &&
        self.selectedIndexPath) {
        [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.itemSize = CGSizeMake(kItemWidth, kItemHeight);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[PLVLSBeautyCollectionViewCell class] forCellWithReuseIdentifier:PLVLSBeautyCollectionViewCell.cellID];
    }
    return _collectionView;
}

#pragma mark didSelectItem
- (void)didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([PLVLSBeautyViewModel sharedViewModel].beautyIsOpen &&
        indexPath &&
        self.dataArray.count > indexPath.row) {
        self.selectedIndexPath = indexPath;
        
        PLVLSBeautyCellModel *model = self.dataArray[indexPath.row];
        for (PLVLSBeautyCellModel *tempModel in self.dataArray) {
            [tempModel updateSelected:model == tempModel];
        }
        [[PLVLSBeautyViewModel sharedViewModel] selectBeautyOption:model.beautyOption];
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
    PLVLSBeautyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PLVLSBeautyCollectionViewCell.cellID forIndexPath:indexPath];
    if (self.dataArray.count > indexPath.row) {
        PLVLSBeautyCellModel *model = self.dataArray[indexPath.row];
        [cell updateCellModel:model beautyOpen:[PLVLSBeautyViewModel sharedViewModel].beautyIsOpen];
        cell.userInteractionEnabled = [PLVLSBeautyViewModel sharedViewModel].beautyIsOpen;
    }
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 36; // 竖屏collectionView水平滚动，minimumLineSpacing为左右间距
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self didSelectItemAtIndexPath:indexPath];
}

@end
