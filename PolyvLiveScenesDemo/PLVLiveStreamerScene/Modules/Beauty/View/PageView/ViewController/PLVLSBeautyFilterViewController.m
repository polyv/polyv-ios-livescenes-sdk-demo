//
//  PLVLSBeautyFilterViewController.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautyFilterViewController.h"
// 工具
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
// UI
#import "PLVLSBeautyFilterCollectionViewCell.h"
// 模块
#import "PLVLSBeautyCellModel.h"
#import "PLVBeautyViewModel.h"

@interface PLVLSBeautyFilterViewController () <
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UICollectionViewDelegate
>

#pragma mark UI
@property (nonatomic, strong) UICollectionView *collectionView;

@end

static CGFloat kItemWidth = 60; // item宽度
static CGFloat kItemHeight = 72; // item高度

@implementation PLVLSBeautyFilterViewController

#pragma mark - [ Life Cycle ]

- (void)setupData {
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
    
    PLVBFilterOption *cacheFilter = [[PLVBeautyViewModel sharedViewModel] getCacheSelectFilterOption];
    if (!cacheFilter || !self.dataArray) {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }else {
        for (NSInteger i = 0; i < self.dataArray.count; i++) {
            PLVLSBeautyCellModel *model = self.dataArray[i];
            if ([model.filerOption.filterSpellName isEqualToString:cacheFilter.filterSpellName]) {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
                break;
            }
        }
    }
    
    if (self.dataArray && self.dataArray.count > self.selectedIndexPath.item) {
        [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    [self didSelectItemAtIndexPath:self.selectedIndexPath];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

#pragma mark - [ Override ]
- (void)setupDataArray {
    [super setupDataArray];
    NSMutableArray *tempArrayM = [NSMutableArray arrayWithCapacity:[PLVBeautyViewModel sharedViewModel].filterOptionArray.count];
    for (PLVBFilterOption *option in [PLVBeautyViewModel sharedViewModel].filterOptionArray) {
        PLVLSBeautyCellModel *model = [[PLVLSBeautyCellModel alloc] initWithTitle:PLVLocalizedString(option.filterName) imageName:[NSString stringWithFormat:@"plvls_beauty_filter_%@", option.filterSpellName] beautyOption:-1 selected:NO filterOption:option];
        [tempArrayM addObject:model];
    }
    self.dataArray = [tempArrayM copy];
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

- (void)resetBeauty {
    [super resetBeauty];
    if ([PLVFdUtil checkArrayUseable:self.dataArray]) {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
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
        [_collectionView registerClass:[PLVLSBeautyFilterCollectionViewCell class] forCellWithReuseIdentifier:PLVLSBeautyFilterCollectionViewCell.cellID];
    }
    return _collectionView;
}

#pragma mark didSelectItem
- (void)didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([PLVBeautyViewModel sharedViewModel].beautyIsOpen &&
        self.dataArray.count > indexPath.row) {
        self.selectedIndexPath = indexPath;
        
        PLVLSBeautyCellModel *model = self.dataArray[indexPath.row];
        for (PLVLSBeautyCellModel *tempModel in self.dataArray) {
            [tempModel updateSelected:model == tempModel];
        }
        [[PLVBeautyViewModel sharedViewModel] selectBeautyFilterOption:model.filerOption];
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
    PLVLSBeautyFilterCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PLVLSBeautyFilterCollectionViewCell.cellID forIndexPath:indexPath];
    if (self.dataArray.count > indexPath.row) {
        PLVLSBeautyCellModel *model = self.dataArray[indexPath.row];
        [cell updateCellModel:model beautyOpen:[PLVBeautyViewModel sharedViewModel].beautyIsOpen];
        cell.userInteractionEnabled = [PLVBeautyViewModel sharedViewModel].beautyIsOpen;
    }
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 16; // 竖屏collectionView水平滚动，minimumLineSpacing为左右间距
}


#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self didSelectItemAtIndexPath:indexPath];
}

@end
