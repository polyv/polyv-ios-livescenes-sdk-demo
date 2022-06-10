//
//  PLVLCDownloadListViewController.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadListViewController.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCUtils.h"
#import "PLVLCTabbarItemCell.h"
#import "PLVLCDownloadingViewController.h"
#import "PLVLCDownloadedViewController.h"
#import "PLVLCDownloadViewModel.h"

static NSString *kTitleCellIdentifier = @"kPageTitleCell";

@interface PLVLCDownloadListViewController ()<
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UIPageViewControllerDataSource,
UIPageViewControllerDelegate
>

/// 数据
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *controllers;
@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, assign) NSUInteger nextIndex;

/// UI
@property (nonatomic, strong) UICollectionView *titleCollectionView;
@property (nonatomic, strong) UIPageViewController *pageController;

@end

@implementation PLVLCDownloadListViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
    
    self.nextIndex = NSNotFound;
    
    [self initNavigationBar];
    [self.view addSubview:self.pageController.view];
    [self addChildViewController:self.pageController];
    
    NSArray *initControllers = @[self.controllers[self.selectIndex]];
    [self.pageController setViewControllers:initControllers direction:0 animated:NO completion:nil];
    
    [PLVLCDownloadViewModel sharedViewModel].viewProxy = self;
    [[PLVLCDownloadViewModel sharedViewModel] setUpDownloadTaskInfoArrayRefreshObserver:NSStringFromClass(self.class)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)dealloc {
    [[PLVLCDownloadViewModel sharedViewModel] removeDownloadTaskInfoArrayRefreshObserver:NSStringFromClass(self.class)];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - [ Initialize ]

- (void)initNavigationBar {
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
        appearance.shadowColor = [PLVColorUtil colorFromHexString:@"#000000"];
        appearance.shadowImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#000000"]];
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = self.navigationController.navigationBar.standardAppearance;
    }else {
        [self.navigationController.navigationBar setBackgroundImage:[PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#202127"]] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setBarTintColor:[PLVColorUtil colorFromHexString:@"#202127"]];
    }
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 44, 44);
    [leftButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_skin_back"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -40, 0, 0);
    UIBarButtonItem *backItem =[[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItem = backItem;

    self.navigationItem.titleView = self.titleCollectionView;
    [self.titleCollectionView reloadData];
}

#pragma mark - [ Action ]

- (void)backAction {
    if (self.navigationController) {
        if ([self.navigationController.viewControllers count] == 1) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - [ Private Methods ]

-(void)selecteAtIndex:(NSUInteger)index {
    self.selectIndex = index;
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:self.selectIndex inSection:0];
    [self.titleCollectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];

    PLVLCTabbarItemCell *cell = (PLVLCTabbarItemCell *)[self.titleCollectionView cellForItemAtIndexPath:selectedIndexPath];
    [cell setClicked:YES];
}

-(void)deselectAtIndex:(NSUInteger)index {
    NSIndexPath *deselectedPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.titleCollectionView deselectItemAtIndexPath:deselectedPath animated:NO];
    
    PLVLCTabbarItemCell *cell = (PLVLCTabbarItemCell *)[self.titleCollectionView cellForItemAtIndexPath:deselectedPath];
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

#pragma mark - [ Delegate ]

#pragma mark - UICollectionView Layout

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return CGSizeMake(125, 44);
    }else{
        CGFloat itemWidth = 266 * 0.5;
        return CGSizeMake(itemWidth, 44);
    }
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
}

#pragma mark - UICollectionView DataSource & Deleaget

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titles.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCTabbarItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTitleCellIdentifier forIndexPath:indexPath];
    cell.titleLabel.text = self.titles[indexPath.item];
    [cell setClicked:indexPath.item == self.selectIndex];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.selectIndex) {
        return;
    }
    
    self.selectIndex = indexPath.item;
    [collectionView reloadData];
    
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    NSArray *showController = @[self.controllers[indexPath.item]];
    [self.pageController setViewControllers:showController direction:0 animated:NO completion:nil];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCTabbarItemCell *cell = (PLVLCTabbarItemCell *)[collectionView cellForItemAtIndexPath:indexPath];
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

#pragma mark - [ Loadlazy ]

- (UICollectionView *)titleCollectionView {
    if (!_titleCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        CGRect frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            frame = CGRectMake(0, 0, 250, 44);
        }else{
            frame = CGRectMake(0, 0, 266, 44);
        }
        _titleCollectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        _titleCollectionView.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
        _titleCollectionView.allowsSelection = YES;
        _titleCollectionView.showsVerticalScrollIndicator = NO;
        _titleCollectionView.showsHorizontalScrollIndicator = NO;
        _titleCollectionView.dataSource = self;
        _titleCollectionView.delegate = self;
        [_titleCollectionView registerClass:[PLVLCTabbarItemCell class] forCellWithReuseIdentifier:kTitleCellIdentifier];
    }
    return _titleCollectionView;
}

- (UIPageViewController *)pageController {
    if (!_pageController) {
        _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
        _pageController.view.frame = self.view.bounds;
        _pageController.dataSource = self;
        _pageController.delegate =self;
        _pageController.view.clipsToBounds = NO;
        
        for (UIView *subview in _pageController.view.subviews) {
            subview.clipsToBounds = NO;
        }
    }
    return _pageController;
}

- (NSArray *)titles {
    if (!_titles) {
        _titles = @[@"下载中", @"已下载"];
    }
    return _titles;
}

- (NSArray *)controllers {
    if (!_controllers) {
        PLVLCDownloadingViewController *downloadingVC = [[PLVLCDownloadingViewController alloc]init];
        PLVLCDownloadedViewController *downloadedVC = [[PLVLCDownloadedViewController alloc]init];
        _controllers = @[downloadingVC, downloadedVC];
    }
    return _controllers;
}

@end
