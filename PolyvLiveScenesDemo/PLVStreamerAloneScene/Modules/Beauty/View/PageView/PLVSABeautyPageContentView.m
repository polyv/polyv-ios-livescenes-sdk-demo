//
//  PLVSABeautyPageContentView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyPageContentView.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#define PLVSABeautyPageContentViewCellID @"PLVSABeautyPageContentViewCellID"

@interface PLVSABeautyPageContentView()<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionView *mainCollectionView;
@property (nonatomic, strong) NSArray *childViewControllerArray;
@property (nonatomic, weak) UIViewController *parentViewController;
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation; // 当前屏幕方向

@end

@implementation PLVSABeautyPageContentView

#pragma mark - [ Life Cycle ]
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.mainCollectionView];
        [self.mainCollectionView reloadData];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.mainCollectionView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChildArray:(NSArray<UIViewController *> *)childArray parentViewController:(UIViewController *) parentVC{
    self.childViewControllerArray = childArray;
    self.parentViewController = parentVC;
    return [super init];
}

- (void)setPageContentViewWithTargetIndex:(NSUInteger)index{
    CGFloat targetIndex = index < _childViewControllerArray.count? index: _childViewControllerArray.count;
    [_mainCollectionView setContentOffset:CGPointMake(targetIndex * self.frame.size.width, 0) animated:NO]; // 使用动画会提前加载后面的页面
}

#pragma mark - [ Private Method ]
#pragma mark Getter
- (UICollectionView *)mainCollectionView {
    if (!_mainCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = CGFLOAT_MIN;
        flowLayout.minimumInteritemSpacing = CGFLOAT_MIN;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _mainCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _mainCollectionView.backgroundColor = [UIColor clearColor];
        _mainCollectionView.dataSource = self;
        _mainCollectionView.delegate = self;
        _mainCollectionView.pagingEnabled = YES;
        _mainCollectionView.showsVerticalScrollIndicator = NO;
        _mainCollectionView.showsHorizontalScrollIndicator = NO;
        [_mainCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:PLVSABeautyPageContentViewCellID];
        _mainCollectionView.bounces = NO;
        _mainCollectionView.scrollEnabled = NO;
    }
    return _mainCollectionView;
}

- (NSArray *)childViewControllerArray {
    if (!_childViewControllerArray) {
        _childViewControllerArray = [NSArray array];
    }
    return _childViewControllerArray;
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.childViewControllerArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PLVSABeautyPageContentViewCellID forIndexPath:indexPath];
    
    UIViewController *vc = self.childViewControllerArray[indexPath.row];
    vc.view.frame = self.bounds;
    [self.parentViewController addChildViewController:vc]; //A
    for (UIView *view in cell.contentView.subviews) { // 清除cell.contentView子视图缓存
        if (view &&
            [view isKindOfClass:[UIView class]]) {
            [view removeFromSuperview];
        }
    }
    [cell.contentView addSubview:vc.view];
    [vc didMoveToParentViewController:self.parentViewController]; //B
    return cell;
    //A B这两个操作是为了让子vc继承父vc的一些方法，比如navigation push等等。。
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return self.frame.size;
}


@end
