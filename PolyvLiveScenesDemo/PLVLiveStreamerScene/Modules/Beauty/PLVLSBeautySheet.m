//
//  PLVLSBeautySheet.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautySheet.h"
// 工具类
#import "PLVLSUtils.h"
// UI
#import "PLVLSBeautySliderView.h"
#import "PLVLSBeautySwitch.h"
#import "PLVLSBeautyTitleView.h"
#import "PLVLSBeautyContentView.h"
#import "PLVLSBeautyFilterTitleView.h"
// 模块
#import "PLVLSBeautyViewModel.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSBeautySheet()<
PLVLSBeautyTitleViewDelegate,
PLVLSBeautySliderViewDelegate,
PLVLSBeautyViewModelDelegate,
PLVLSBeautySwitchDelegate
>

/// view hierarchy
///
/// (PLVLSBottomSheet) superview
///  └── (PLVLSBeautySheet) self (lowest)
///    ├── (PLVLSBeautySliderView) sliderView
///    ├── (PLVLSBeautySwitch) beautySwitch
///    ├── (PLVLSBeautyTitleView) beautyTypeTitleView
///    ├── (PLVLSBeautyContentView) beautyContentView
///    ├── (PLVLSBeautyFilterTitleView) filterTitleView
///    ├── (UIButton) resetButton
///
///
/// UI
@property (nonatomic, strong) PLVLSBeautySliderView *sliderView; // 美颜强度sliderView
@property (nonatomic, strong) PLVLSBeautySwitch *beautySwitch; // 美颜开关
@property (nonatomic, strong) PLVLSBeautyTitleView *beautyTypeTitleView; // 美颜分类标题视图
@property (nonatomic, strong) PLVLSBeautyContentView *beautyContentView; // 美颜内容视图
@property (nonatomic, strong) PLVLSBeautyFilterTitleView *filterTitleView; // 滤镜标题视图
@property (nonatomic, strong) UIButton *resetButton; // 重置

@end

@implementation PLVLSBeautySheet

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight showSlider:(BOOL)showSlider {
    self = [super initWithSheetHeight:sheetHeight showSlider:YES];
    if (self) {
        [PLVLSBeautyViewModel sharedViewModel].delegate = self;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat filterTitleViewX = (self.bounds.size.width - 90) / 2;
    CGFloat filterTitleViewY = 56;
    CGFloat beautySwitchX = self.bounds.size.width - 100 - 64;
    CGFloat beautySwitchY = 20;
    CGFloat resetButtonX = self.bounds.size.width - 56 - 28 - 100 - 64;
    CGFloat resetButtonY = 24;
    CGFloat beautyTypeTitleViewX = 64;
    CGFloat beautyTypeTitleViewY = 24;
    CGFloat beautyTypeTitleViewWidth = self.contentView.bounds.size.width - beautyTypeTitleViewX * 2;
    CGFloat sliderViewX = 64;
    CGFloat sliderViewY = self.bounds.size.height - self.sheetHight - 8 - 48;
    CGFloat sliderViewWidth = 211;
    CGFloat sliderViewHeight = 48;
    CGFloat beautyContentViewX = 64;
    CGFloat beautyContentViewY = 60;
    CGFloat beautyContentViewWidth = self.contentView.bounds.size.width - beautyContentViewX;
    CGFloat beautyContentViewHeight = 72;
    
    // 父类为self
    self.sliderView.frame = CGRectMake(sliderViewX, sliderViewY, sliderViewWidth, sliderViewHeight);

    // 父类为self.contentView
    self.filterTitleView.frame = CGRectMake(filterTitleViewX, filterTitleViewY, 90, 30);
    self.beautySwitch.frame = CGRectMake(beautySwitchX, beautySwitchY, 100, 30);
    self.resetButton.frame = CGRectMake(resetButtonX, resetButtonY, 56, 20);
    self.beautyTypeTitleView.frame = CGRectMake(beautyTypeTitleViewX, beautyTypeTitleViewY, beautyTypeTitleViewWidth, 24);
    self.beautyContentView.frame = CGRectMake(beautyContentViewX, beautyContentViewY, beautyContentViewWidth, beautyContentViewHeight);
}

#pragma mark - [ Override ]

- (void)showInView:(UIView *)parentView {
    self.sliderView.hidden = ![PLVLSBeautyViewModel sharedViewModel].beautyIsOpen;
    self.beautySwitch.hidden = NO;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautySheet:didChangeShow:)]) {
        [self.delegate beautySheet:self didChangeShow:YES];
    }
    [super showInView:parentView];
}

- (void)dismiss {
    self.sliderView.hidden = YES;
    self.beautySwitch.hidden = YES;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautySheet:didChangeShow:)]) {
        [self.delegate beautySheet:self didChangeShow:NO];
    }
    [super dismiss];
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter
- (PLVLSBeautySliderView *)sliderView {
    if (!_sliderView) {
        _sliderView = [[PLVLSBeautySliderView alloc] init];
        _sliderView.delegate = self;
        _sliderView.hidden = ![PLVLSBeautyViewModel sharedViewModel].beautyIsOpen;
    }
    return _sliderView;
}

- (PLVLSBeautySwitch *)beautySwitch {
    if (!_beautySwitch) {
        _beautySwitch = [[PLVLSBeautySwitch alloc] init];
        _beautySwitch.on = [PLVLSBeautyViewModel sharedViewModel].beautyIsOpen;
        _beautySwitch.delegate = self;
    }
    return _beautySwitch;
}

- (PLVLSBeautyTitleView *)beautyTypeTitleView {
    if (!_beautyTypeTitleView) {
        _beautyTypeTitleView = [[PLVLSBeautyTitleView alloc] init];
        _beautyTypeTitleView.delegate = self;
    }
    return _beautyTypeTitleView;
}

- (PLVLSBeautyContentView *)beautyContentView {
    if (!_beautyContentView) {
        _beautyContentView = [[PLVLSBeautyContentView alloc] init];
    }
    return _beautyContentView;
}

- (PLVLSBeautyFilterTitleView *)filterTitleView {
    if (!_filterTitleView) {
        _filterTitleView = [[PLVLSBeautyFilterTitleView alloc] init];
    }
    return _filterTitleView;
}

- (UIButton *)resetButton {
    if (!_resetButton) {
        _resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_resetButton setTitle:@"重置" forState:UIControlStateNormal];
        UIImage *image = [PLVLSUtils imageForBeautyResource:@"plvls_beauty_reset"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_resetButton setImage:image forState:UIControlStateNormal];
        _resetButton.tintColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _resetButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _resetButton.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _resetButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        [_resetButton addTarget:self action:@selector(resetButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resetButton;
}

#pragma mark 初始化UI
- (void)setupUI {
    [self addSubview:self.sliderView];
    
    [self.contentView addSubview:self.beautyTypeTitleView];
    [self.contentView addSubview:self.beautyContentView];
    [self.contentView addSubview:self.resetButton];
    [self.contentView addSubview:self.beautySwitch];
}

- (void)removeAllView {
    [self.sliderView removeFromSuperview];
    _sliderView = nil;
    
    [self.beautySwitch removeFromSuperview];
    _beautySwitch = nil;
    
    [self.beautyTypeTitleView removeFromSuperview];
    _beautyTypeTitleView = nil;
    
    [self.beautyContentView removeFromSuperview];
    _beautyContentView = nil;
    
    [self.resetButton removeFromSuperview];
    _resetButton = nil;
}

#pragma mark 重置
- (void)beautyOpen:(BOOL)open {
    self.resetButton.userInteractionEnabled = open;
    if (open) {
        self.resetButton.tintColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        self.resetButton.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    } else {
        self.resetButton.tintColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.4];
        self.resetButton.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.4];
    }
}

#pragma mark - [ Event ]
#pragma mark Action
- (void)resetButtonAction:(UIButton *)button {
    __weak typeof(self) weakSelf = self;
    [PLVLSUtils showAlertWithMessage:@"重置后所有美颜参数将恢复默认值" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
        [PLVLSUtils showToastInHomeVCWithMessage:@"重置成功"];
        
        [[PLVLSBeautyViewModel sharedViewModel] resetBeautyOptionIntensity];
        [weakSelf.beautyContentView resetBeauty];
    }];
    
}

#pragma mark - [ Delegate ]
#pragma mark PLVLSBeautyTitleViewDelegate
- (void)beautyTitleView:(PLVLSBeautyTitleView *)beautyTitleView didTapButton:(PLVLSBeautyType)type {
    [[PLVLSBeautyViewModel sharedViewModel] selectBeautyType:type];
    [self.beautyContentView selectContentViewWithType:type];
}

#pragma mark PLVLSBeautySliderViewDelegate
- (void)beautySliderView:(PLVLSBeautySliderView *)beautySliderView didChangedValue:(CGFloat)value {
    [[PLVLSBeautyViewModel sharedViewModel] updateBeautyOptionWithIntensity:value];
}

#pragma mark PLVLSBeautyViewModelDelegate
- (void)beautyViewModel:(PLVLSBeautyViewModel *)beautyViewModel didChangeIntensity:(CGFloat)intensity defaultIntensity:(CGFloat)defaultIntensity {
    if (intensity == -1) {
        self.sliderView.hidden = YES;
    } else {
        self.sliderView.hidden = NO;
        [self.sliderView updateSliderValue:intensity defaultValue:defaultIntensity];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)beautyViewModel:(PLVLSBeautyViewModel *)beautyViewModel didChangeFilterName:(NSString *)filterName {
    [self.filterTitleView showAtView:self title:filterName];
}

#pragma mark PLVLSBeautySwitchDelegate
- (void)beautySwitch:(PLVLSBeautySwitch *)beautySwitch didChangeOn:(BOOL)on {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautySheet:didChangeOn:)]) {
        [self.delegate beautySheet:self didChangeOn:on];
    }
    
    if (on && ![PLVLSBeautyViewModel sharedViewModel].isSelectedOriginFilter) {
        self.sliderView.hidden = NO; // 美颜开启 并且 不是选中原图滤镜 时显示强度进度条
    } else {
        self.sliderView.hidden = YES;
    }
    
    [[PLVLSBeautyViewModel sharedViewModel] beautyOpen:on];
    [self beautyOpen:on];
    [self.beautyContentView beautyOpen:on];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
