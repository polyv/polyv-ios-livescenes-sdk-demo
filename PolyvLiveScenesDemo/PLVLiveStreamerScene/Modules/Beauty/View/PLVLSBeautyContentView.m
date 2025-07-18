//
//  PLVLSBeautyContentView.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautyContentView.h"
// 工具
#import "PLVLSUtils.h"
// UI
#import "PLVLSBeautyPageContentView.h"
#import "PLVLSBeautyWhitenViewController.h"
#import "PLVLSBeautyFilterViewController.h"
#import "PLVLSBeautyFaceViewController.h"
// 模块
#import "PLVBeautyViewModel.h"

@interface PLVLSBeautyContentView()

@property (nonatomic, strong) PLVLSBeautyPageContentView *contentView;
@property (nonatomic, strong) NSArray<UIViewController *> *childArray;

@end

@implementation PLVLSBeautyContentView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentView.frame = self.bounds;
}

// 强制刷新内容视图布局，用于处理开播时的布局变化
- (void)refreshContentViewLayout {
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
}

#pragma mark - [ Public Method ]

- (void)selectContentViewWithType:(PLVBeautyType)type {
    if (self.childArray.count > type) {
        PLVLSBeautyBaseViewController *viewController = (PLVLSBeautyBaseViewController *)self.childArray[type];
        [viewController showContentView];
    }
    [self.contentView setPageContentViewWithTargetIndex:type];
}

- (void)beautyOpen:(BOOL)open {
    for (PLVLSBeautyBaseViewController *viewController in self.childArray) {
        [viewController beautyOpen:open];
    }
}

- (void)resetBeauty {
    for (PLVLSBeautyBaseViewController *viewController in self.childArray) {
        [viewController resetBeauty];
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter
- (PLVLSBeautyPageContentView *)contentView {
    if (!_contentView) {
        _contentView = [[PLVLSBeautyPageContentView alloc] initWithChildArray:self.childArray parentViewController:[PLVLSUtils sharedUtils].homeVC];
    }
    return _contentView;
}

- (NSArray<UIViewController *> *)childArray {
    if (!_childArray) {
        PLVLSBeautyWhitenViewController *whiteVC = [[PLVLSBeautyWhitenViewController alloc] init];
        whiteVC.beautyType = PLVBeautyTypeWhiten;
        
        PLVLSBeautyFilterViewController *filterVC = [[PLVLSBeautyFilterViewController alloc] init];
        filterVC.beautyType = PLVBeautyTypeFilter;
        
        PLVLSBeautyFaceViewController *faceVC = [[PLVLSBeautyFaceViewController alloc] init];
        faceVC.beautyType = PLVBeautyTypeFace;
        
        _childArray = [NSArray arrayWithObjects:whiteVC, filterVC, faceVC, nil];
    }
    return _childArray;
}

@end
