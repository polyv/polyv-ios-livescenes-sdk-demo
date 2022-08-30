//
//  PLVSABeautyContentView.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyContentView.h"
// 工具
#import "PLVSAUtils.h"
// UI
#import "PLVSABeautyPageContentView.h"
#import "PLVSABeautyWhitenViewController.h"
#import "PLVSABeautyFilterViewController.h"
#import "PLVSABeautyFaceViewController.h"

@interface PLVSABeautyContentView()

@property (nonatomic, strong) PLVSABeautyPageContentView *contentView;
@property (nonatomic, strong) NSArray<UIViewController *> *childArray;

@end

@implementation PLVSABeautyContentView

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

#pragma mark - [ Public Method ]

- (void)selectContentViewWithType:(PLVBeautyType)type {
    if (self.childArray.count > type) {
        PLVSABeautyBaseViewController *viewController = (PLVSABeautyBaseViewController *)self.childArray[type];
        [viewController showContentView];
    }
    [self.contentView setPageContentViewWithTargetIndex:type];
}

- (void)beautyOpen:(BOOL)open {
    for (PLVSABeautyBaseViewController *viewController in self.childArray) {
        [viewController beautyOpen:open];
    }
}

- (void)resetBeauty {
    for (PLVSABeautyBaseViewController *viewController in self.childArray) {
        [viewController resetBeauty];
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter
- (PLVSABeautyPageContentView *)contentView {
    if (!_contentView) {
        _contentView = [[PLVSABeautyPageContentView alloc] initWithChildArray:self.childArray parentViewController:[PLVSAUtils sharedUtils].homeVC];
    }
    return _contentView;
}

- (NSArray<UIViewController *> *)childArray {
    if (!_childArray) {
        PLVSABeautyWhitenViewController *whiteVC = [[PLVSABeautyWhitenViewController alloc] init];
        whiteVC.beautyType = PLVBeautyTypeWhiten;
        
        PLVSABeautyFilterViewController *filterVC = [[PLVSABeautyFilterViewController alloc] init];
        filterVC.beautyType = PLVBeautyTypeFilter;
        
        PLVSABeautyFaceViewController *faceVC = [[PLVSABeautyFaceViewController alloc] init];
        faceVC.beautyType = PLVBeautyTypeFace;
        
        _childArray = [NSArray arrayWithObjects:whiteVC, filterVC, faceVC, nil];
    }
    return _childArray;
}

@end
