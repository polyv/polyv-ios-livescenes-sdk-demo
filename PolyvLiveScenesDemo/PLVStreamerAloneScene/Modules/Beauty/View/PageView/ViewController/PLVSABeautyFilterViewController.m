//
//  PLVSABeautyFilterViewController.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyFilterViewController.h"
// 工具
#import "PLVSAUtils.h"
// UI
#import "PLVSABeautyFilterCollectionViewCell.h"
// 模块
#import "PLVSABeautyCellModel.h"
#import "PLVSABeautyViewModel.h"

@interface PLVSABeautyFilterViewController () <
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UICollectionViewDelegate
>

#pragma mark UI
@property (nonatomic, strong) UICollectionView *collectionView;

@end

static CGFloat kItemWidth = 56; // item宽度
static int kItemLineNum = 3; // 每行item数

@implementation PLVSABeautyFilterViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self didSelectItemAtIndexPath:self.selectedIndexPath];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

#pragma mark - [ Override ]
- (void)setupDataArray {
    [super setupDataArray];
    NSMutableArray *tempArrayM = [NSMutableArray arrayWithCapacity:[PLVSABeautyViewModel sharedViewModel].filterOptionArray.count];
    for (PLVBFilterOption *option in [PLVSABeautyViewModel sharedViewModel].filterOptionArray) {
        PLVSABeautyCellModel *model = [[PLVSABeautyCellModel alloc] initWithTitle:option.filterName imageName:[NSString stringWithFormat:@"plvsa_beauty_filter_%@", option.filterSpellName] beautyOption:-1 selected:NO filterOption:option];
        [tempArrayM addObject:model];
    }
    self.dataArray = [tempArrayM copy];
}

- (void)showContentView {
    [super showContentView];
    if ([PLVSABeautyViewModel sharedViewModel].beautyIsOpen) {
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

- (void)resetBeauty {
    [super resetBeauty];
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = [PLVSAUtils sharedUtils].isLandscape ?  UICollectionViewScrollDirectionVertical : UICollectionViewScrollDirectionHorizontal;
        flowLayout.itemSize = CGSizeMake(kItemWidth, 72);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[PLVSABeautyFilterCollectionViewCell class] forCellWithReuseIdentifier:PLVSABeautyFilterCollectionViewCell.cellID];
    }
    return _collectionView;
}

#pragma mark didSelectItem
- (void)didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([PLVSABeautyViewModel sharedViewModel].beautyIsOpen &&
        self.dataArray.count > indexPath.row) {
        self.selectedIndexPath = indexPath;
        
        PLVSABeautyCellModel *model = self.dataArray[indexPath.row];
        for (PLVSABeautyCellModel *tempModel in self.dataArray) {
            [tempModel updateSelected:model == tempModel];
        }
        [[PLVSABeautyViewModel sharedViewModel] selectBeautyFilterOption:model.filerOption];
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
    PLVSABeautyFilterCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PLVSABeautyFilterCollectionViewCell.cellID forIndexPath:indexPath];
    if (self.dataArray.count > indexPath.row) {
        PLVSABeautyCellModel *model = self.dataArray[indexPath.row];
        [cell updateCellModel:model beautyOpen:[PLVSABeautyViewModel sharedViewModel].beautyIsOpen];
        cell.userInteractionEnabled = [PLVSABeautyViewModel sharedViewModel].beautyIsOpen;
    }
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if ([PLVSAUtils sharedUtils].isLandscape) { // 横屏collectionView垂直滚动，minimumLineSpacing为上下间距
        return 12;
    } else { // 竖屏collectionView水平滚动，minimumLineSpacing为左右间距
        return 12;
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
