//
//  PLVPageController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCPageController.h"
#import "PLVLCPageViewCell.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

static CGFloat kBarHeight = 48.0;
static CGFloat kSeperatorHeight = 1.0;

static NSString *kTitleCellIdentifier = @"kPageTitleCell";

@interface PLVLCPageController ()<
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UIPageViewControllerDataSource,
UIPageViewControllerDelegate
>

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *controllers;

@property (nonatomic, strong) UICollectionView *titleCollectionView;
@property (nonatomic, strong) UIPageViewController *pageController;
@property (nonatomic, strong) UIView *seperator;

@property (nonatomic, assign) NSUInteger nextIndex;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, copy) NSString *selectedTitle;

@end

@implementation PLVLCPageController

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _nextIndex = NSNotFound;
        _selectedIndex = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.titleCollectionView];
    
    [self.view addSubview:self.pageController.view];
    [self addChildViewController:self.pageController];
    
    [self.view addSubview:self.seperator];
}

#pragma mark - Getter & Setter

- (UICollectionView *)titleCollectionView {
    if (!_titleCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _titleCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, PLVScreenWidth, kBarHeight) collectionViewLayout:layout];
        
        _titleCollectionView.backgroundColor = [UIColor colorWithRed:0x3e/255.0 green:0x3e/255.0 blue:0x4e/255.0 alpha:1.0];
        _titleCollectionView.allowsSelection = YES;
        _titleCollectionView.showsVerticalScrollIndicator = NO;
        _titleCollectionView.showsHorizontalScrollIndicator = NO;
        _titleCollectionView.dataSource = self;
        _titleCollectionView.delegate = self;
        [_titleCollectionView registerClass:[PLVLCPageViewCell class] forCellWithReuseIdentifier:kTitleCellIdentifier];
    }
    return _titleCollectionView;
}

- (UIPageViewController *)pageController {
    if (!_pageController) {
        _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
        CGFloat originY = kBarHeight + kSeperatorHeight;
        _pageController.view.frame = CGRectMake(0, originY, PLVScreenWidth, CGRectGetHeight(self.view.bounds) - originY);
        _pageController.dataSource = self;
        _pageController.delegate =self;
        _pageController.view.clipsToBounds = NO;
        
        for (UIView *subview in _pageController.view.subviews) {
            subview.clipsToBounds = NO;
        }
    }
    return _pageController;
}

- (UIView *)seperator {
    if (!_seperator) {
        _seperator = [[UIView alloc] initWithFrame:CGRectMake(0, kBarHeight, PLVScreenWidth, kSeperatorHeight)];
        _seperator.backgroundColor = [UIColor blackColor];
    }
    return _seperator;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    self.selectedTitle = self.titles[selectedIndex];
}

#pragma mark - Public Methods

- (void)setTitles:(NSArray<NSString *> *)titles controllers:(NSArray<UIViewController *> *)controllers {
    if (self.selectedIndex == NSNotFound) { // 初次设置
        self.titles = [[NSMutableArray alloc] initWithCapacity:titles.count];
        self.controllers = [[NSMutableArray alloc] initWithCapacity:controllers.count];
    } else {
        [self.titles removeAllObjects];
        [self.controllers removeAllObjects];
    }
    
    [self.titles addObjectsFromArray:titles];
    [self.controllers addObjectsFromArray:controllers];
    
    // 更新选中索引
    if ((self.selectedIndex != NSNotFound && ![self.selectedTitle isEqualToString:self.titles[self.selectedIndex]])
        || self.selectedIndex == NSNotFound) {
        self.selectedIndex = 0;
    }
    
    // 刷新 UI
    [self.titleCollectionView reloadData];
    NSArray *initControllers = @[self.controllers[self.selectedIndex]];
    [self.pageController setViewControllers:initControllers direction:0 animated:NO completion:nil];
}

- (void)scrollEnable:(BOOL)enable {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIScrollView *scrollView;
        for(id subview in self.pageController.view.subviews) {
            if([subview isKindOfClass:UIScrollView.class]) {
                scrollView=subview;
                break;
            }
        }
        scrollView.scrollEnabled = enable;
    });
}

#pragma mark - UICollectionView Layout

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(PLVScreenWidth / 3.0, collectionView.frame.size.height);
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
}

#pragma mark - UICollectionView DataSource & Deleaget

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titles.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCPageViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTitleCellIdentifier forIndexPath:indexPath];
    cell.titleLabel.text = self.titles[indexPath.item];
    [cell setClicked:indexPath.item == self.selectedIndex];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.selectedIndex) {
        return;
    }
    
    self.selectedIndex = indexPath.item;
    [collectionView reloadData];
    
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    NSArray *showController = @[self.controllers[indexPath.item]];
    [self.pageController setViewControllers:showController direction:0 animated:NO completion:nil];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCPageViewCell *cell = (PLVLCPageViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell setClicked:NO];
}

#pragma mark - UIPageViewController DataSource & Delegate

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:viewController];
    if (index ==  NSNotFound ) {
        return nil;
    }

    return [self viewControllerAtIndex:--index];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:viewController];
    if (index == NSNotFound ) {
        return nil;
    }
    
    if (++index > self.controllers.count) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}

-(void)pageViewController:(UIPageViewController *)pageViewController
willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    NSUInteger index = [self indexOfViewController:pendingViewControllers.firstObject];
    self.nextIndex = index;
}

-(void)pageViewController:(UIPageViewController *)pageViewController
       didFinishAnimating:(BOOL)finished
  previousViewControllers:(NSArray *)previousViewControllers
      transitionCompleted:(BOOL)completed {
    if (completed) {
        NSUInteger index = [self indexOfViewController:previousViewControllers.firstObject];
        if (index != self.nextIndex) {
            [self deselectAtIndex:index];
            [self selecteAtIndex:self.nextIndex];
        }
    }
}

#pragma mark - Private Methods

-(void)selecteAtIndex:(NSUInteger)index {
    self.selectedIndex = index;
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:self.selectedIndex inSection:0];
    [self.titleCollectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];

    PLVLCPageViewCell *cell = (PLVLCPageViewCell *)[self.titleCollectionView cellForItemAtIndexPath:selectedIndexPath];
    [cell setClicked:YES];
}

-(void)deselectAtIndex:(NSUInteger)index {
    NSIndexPath *deselectedPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.titleCollectionView deselectItemAtIndexPath:deselectedPath animated:NO];
    
    PLVLCPageViewCell *cell = (PLVLCPageViewCell *)[self.titleCollectionView cellForItemAtIndexPath:deselectedPath];
    [cell setClicked:NO];
}

-(UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == NSNotFound || index >= self.controllers.count) {
        return nil;
    }
    return self.controllers[index];
}

-(NSUInteger)indexOfViewController:(UIViewController *)viewController {
    return [self.controllers indexOfObject:viewController];
}

@end
