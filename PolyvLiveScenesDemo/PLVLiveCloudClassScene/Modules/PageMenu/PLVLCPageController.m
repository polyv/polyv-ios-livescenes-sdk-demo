//
//  PLVPageController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCPageController.h"
#import "PLVLCPageViewCell.h"
#import "PLVLCUtils.h"
#import "PLVLCKeyboardMoreView.h"
#import "PLVRoomDataManager.h"
#import "PLVLCChatViewController.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

static CGFloat kBarHeight = 48.0;
static CGFloat kSeperatorHeight = 1.0;
static CGFloat kMoreboardHeight = 115.0;

static NSString *kTitleCellIdentifier = @"kPageTitleCell";

static NSString *PLVLCPageInteractUpdateChatButtonCallbackNotification = @"PLVInteractUpdateChatButtonCallbackNotification";

@interface PLVLCPageController ()<
PLVLCKeyboardMoreViewDelegate,
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
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView *gestureView;
@property (nonatomic, strong) PLVLCKeyboardMoreView *moreboard;

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(interactUpdateChatButtonCallback:) name:PLVLCPageInteractUpdateChatButtonCallbackNotification
                                                   object:nil];
        [[PLVRoomDataManager sharedManager].roomData requestChannelFunctionSwitch];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PLVLCPageInteractUpdateChatButtonCallbackNotification
                                                  object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.placeholderImageView];
    [self.view addSubview:self.placeholderLabel];
    [self.view addSubview:self.titleCollectionView];
    
    [self.view addSubview:self.pageController.view];
    [self addChildViewController:self.pageController];
    
    [self.view addSubview:self.seperator];
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live) {
        [self.view addSubview:self.moreButton];
    }
}

- (void)viewWillLayoutSubviews {
    CGFloat imageWidth = 88;
    CGFloat rightPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 右边距
    CGFloat centerPadding = rightPadding + 40.0 / 2.0; // 40pt宽的按钮屏幕右间距为rightPadding，悬浮按钮都跟40pt宽的按钮垂直对齐
    self.placeholderImageView.frame = CGRectMake(CGRectGetMidX(self.view.bounds) - imageWidth / 2, CGRectGetMidY(self.view.bounds) - imageWidth, imageWidth, imageWidth);
    self.placeholderLabel.frame = CGRectMake(CGRectGetMinX(self.placeholderImageView.frame) + 16 , CGRectGetMaxY(self.placeholderImageView.frame) + 8, 56, 20);
    self.titleCollectionView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), kBarHeight);
    self.seperator.frame = CGRectMake(0, kBarHeight, CGRectGetWidth(self.view.bounds), kSeperatorHeight);
    self.pageController.view.frame = CGRectMake(0, kBarHeight + kSeperatorHeight, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - kBarHeight - kSeperatorHeight);
    [self.titleCollectionView reloadData];
    self.moreButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - centerPadding - 16, CGRectGetHeight(self.view.bounds) - P_SafeAreaBottomEdgeInsets() - 56 - 36, 32, 32);
    self.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, kMoreboardHeight);
}

#pragma mark - Getter & Setter

- (UICollectionView *)titleCollectionView {
    if (!_titleCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _titleCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), kBarHeight) collectionViewLayout:layout];
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
        _pageController.view.frame = CGRectMake(0, originY, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - originY);
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
        _seperator = [[UIView alloc] initWithFrame:CGRectMake(0, kBarHeight, CGRectGetWidth(self.view.bounds), kSeperatorHeight)];
        _seperator.backgroundColor = [UIColor blackColor];
    }
    return _seperator;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    self.selectedTitle = self.titles[selectedIndex];
}

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] initWithImage:[PLVLCUtils imageForMenuResource:@"plvlc_menu_missing"]];
        _placeholderImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _placeholderImageView;
}

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _placeholderLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.4);
        _placeholderLabel.text = PLVLocalizedString(@"暂无菜单");
        _placeholderLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _placeholderLabel;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *moreBtnImage = [PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_btn_more"];
        [_moreButton setImage:moreBtnImage forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UIView *)gestureView {
    if (!_gestureView) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        _gestureView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_gestureView addGestureRecognizer:tap];
    }
    return _gestureView;
}

- (PLVLCKeyboardMoreView *)moreboard {
    if (!_moreboard) {
        _moreboard = [[PLVLCKeyboardMoreView alloc] init];
        _moreboard.delegate = self;
        _moreboard.hiddenBulletin = NO;
        _moreboard.sendImageEnable = NO;
        _moreboard.onlyTeacherEnable = NO;
    }
    return _moreboard;
}

#pragma mark - Public Methods

- (void)setTitles:(NSArray<NSString *> *)titles controllers:(NSArray<UIViewController *> *)controllers {
    if (![PLVFdUtil checkArrayUseable:titles] || ![PLVFdUtil checkArrayUseable:controllers]) {
        [self.titles removeAllObjects];
        [self.controllers removeAllObjects];
        self.pageController.view.hidden = YES;
        self.seperator.hidden = YES;
        self.titleCollectionView.hidden = YES;
        self.moreButton.hidden = NO;
        self.placeholderLabel.hidden = NO;
        self.placeholderImageView.hidden = NO;
        return;
    }
    
    BOOL chatMenuDisplay = NO;
    if ([PLVFdUtil checkArrayUseable:controllers]) {
        for (UIViewController *viewController in controllers) {
            if ([viewController isKindOfClass:PLVLCChatViewController.class]) {
                chatMenuDisplay = YES;
                break;
            }
        }
    }
    self.moreButton.hidden = chatMenuDisplay;
    self.pageController.view.hidden = NO;
    self.seperator.hidden = NO;
    self.titleCollectionView.hidden = NO;
    self.placeholderLabel.hidden = YES;
    self.placeholderImageView.hidden = YES;
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
    if (self.selectedIndex == NSNotFound ||
        self.titles.count <= self.selectedIndex ||
        (self.selectedIndex != NSNotFound && ![self.selectedTitle isEqualToString:self.titles[self.selectedIndex]])) {
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return CGSizeMake(CGRectGetWidth(self.view.bounds) / MIN(self.titles.count, 5), collectionView.frame.size.height);
    }else{
        return CGSizeMake(CGRectGetWidth(self.view.bounds) / MIN(self.titles.count, 3), collectionView.frame.size.height);
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
    
    if (self.controllers.count > indexPath.item) {
        NSArray *showController = @[self.controllers[indexPath.item]];
        [self.pageController setViewControllers:showController direction:0 animated:NO completion:nil];
    }
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

#pragma mark - PLVKeyboardMoreViewDelegate

- (void)keyboardMoreView_openBulletin:(PLVLCKeyboardMoreView *)moreView {
    [self tapAction:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomOpenBulletinNotification object:nil];
}

- (void)keyboardMoreView_onlyTeacher:(PLVLCKeyboardMoreView *)moreView on:(BOOL)on {
    
}


- (void)keyboardMoreView_openAlbum:(PLVLCKeyboardMoreView *)moreView {
    
}


- (void)keyboardMoreView_openCamera:(PLVLCKeyboardMoreView *)moreView {
    
}


- (void)keyboardMoreView_openInteractApp:(PLVLCKeyboardMoreView *)moreView eventName:(NSString *)eventName {
    [self tapAction:nil];
    if ([PLVFdUtil checkStringUseable:eventName]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomOpenInteractAppNotification object:eventName];
    }
}


- (void)keyboardMoreView_switchRewardDisplay:(PLVLCKeyboardMoreView *)moreView on:(BOOL)on {
    
}

#pragma mark - Private Methods

-(void)selecteAtIndex:(NSUInteger)index {
    self.selectedIndex = index;
    
    if (self.titles && self.titles.count > index) {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:self.selectedIndex inSection:0];
        [self.titleCollectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];

        PLVLCPageViewCell *cell = (PLVLCPageViewCell *)[self.titleCollectionView cellForItemAtIndexPath:selectedIndexPath];
        [cell setClicked:YES];
    }
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

#pragma mark - [ Event ]
#pragma mark Action

- (void)moreButtonAction:(UIButton *)sender {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (self.moreboard.superview == window) {
        return;
    }
    
    [window addSubview:self.gestureView];
    [window addSubview:self.moreboard];
    self.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, kMoreboardHeight);
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0 animations:^{
        weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight - kMoreboardHeight, kScreenWidth, kMoreboardHeight);
    }];
}

- (void)tapAction:(id)sender {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (self.moreboard.superview != window) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, kMoreboardHeight);
    } completion:^(BOOL finished) {
        [weakSelf.gestureView removeFromSuperview];
        [weakSelf.moreboard removeFromSuperview];
    }];
}

- (void)interactUpdateChatButtonCallback:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSArray *buttonDataArray = PLV_SafeArraryForDictKey(dict, @"dataArray");
    [self.moreboard updateChatButtonDataArray:buttonDataArray];
}

@end
