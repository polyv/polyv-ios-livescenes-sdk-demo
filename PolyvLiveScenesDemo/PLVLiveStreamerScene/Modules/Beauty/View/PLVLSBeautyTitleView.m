//
//  PLVLSBeautyTitleView.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautyTitleView.h"
// 工具
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
// UI
#import "PLVLSBeautyTitleButton.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSBeautyTitleView()

@property (nonatomic, strong) PLVLSBeautyTitleButton *whitenButton; // 美白
@property (nonatomic, strong) PLVLSBeautyTitleButton *filterButton; // 滤镜
@property (nonatomic, strong) PLVLSBeautyTitleButton *faceButton; // 脸部细节

@property (nonatomic, strong) NSArray <UIButton *> *beautyButtonArray;

@end

@implementation PLVLSBeautyTitleView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.whitenButton];
        [self addSubview:self.filterButton];
        [self addSubview:self.faceButton];
        
        self.beautyButtonArray = [NSArray arrayWithObjects:
                            self.whitenButton,
                            self.filterButton,
                            self.faceButton, nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat paddingX = 28;
    self.whitenButton.frame = CGRectMake(0, 0, 45, self.bounds.size.height);
    self.filterButton.frame = CGRectMake(CGRectGetMaxX(self.whitenButton.frame) + paddingX, 0, 40, self.bounds.size.height);
    self.faceButton.frame = CGRectMake(CGRectGetMaxX(self.filterButton.frame) + paddingX, 0, 60, self.bounds.size.height);
}

#pragma mark - [ Public Method ]

- (void)selectTitleButtonWithType:(PLVBeautyType)type {
    [self resetAllButtonSelected];
    for (UIButton *button in self.beautyButtonArray) {
        button.selected = button.tag == type;
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter

- (PLVLSBeautyTitleButton *)whitenButton {
    if (!_whitenButton) {
        _whitenButton = [[PLVLSBeautyTitleButton alloc] init];
        _whitenButton.tag = PLVBeautyTypeWhiten;
        [_whitenButton setTitle:PLVLocalizedString(@"美颜") forState:UIControlStateNormal];
        _whitenButton.selected = YES;
        [_whitenButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _whitenButton;
}

- (PLVLSBeautyTitleButton *)filterButton {
    if (!_filterButton) {
        _filterButton = [[PLVLSBeautyTitleButton alloc] init];
        _filterButton.tag = PLVBeautyTypeFilter;
        [_filterButton setTitle:PLVLocalizedString(@"滤镜") forState:UIControlStateNormal];
        [_filterButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _filterButton;
}

- (PLVLSBeautyTitleButton *)faceButton {
    if (!_faceButton) {
        _faceButton = [[PLVLSBeautyTitleButton alloc] init];
        _faceButton.tag = PLVBeautyTypeFace;
        [_faceButton setTitle:PLVLocalizedString(@"脸部细节") forState:UIControlStateNormal];
        [_faceButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _faceButton;
}

#pragma mark 工具
- (void)resetAllButtonSelected {
    for (UIButton *button in self.beautyButtonArray) {
        button.selected = NO;
    }
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)buttonAction:(UIButton *)button {
    [self resetAllButtonSelected];
    button.selected = YES;
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautyTitleView:didTapButton:)]) {
        [self.delegate beautyTitleView:self didTapButton:button.tag];
    }
}

@end

