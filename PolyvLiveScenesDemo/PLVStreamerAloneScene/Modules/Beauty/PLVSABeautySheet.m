//
//  PLVSABeautySheet.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautySheet.h"
// 工具类
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
// UI
#import "PLVSABeautySliderView.h"
#import "PLVSABeautySwitch.h"
#import "PLVSABeautyTitleView.h"
#import "PLVSABeautyContentView.h"
#import "PLVSABeautyFilterTitleView.h"
// 模块
#import "PLVBeautyViewModel.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSABeautySheet()<
PLVSABeautyTitleViewDelegate,
PLVSABeautySliderViewDelegate,
PLVBeautyViewModelDelegate,
PLVSABeautySwitchDelegate
>

/// view hierarchy
///
/// (PLVSABottomSheet) superview
///  └── (PLVSABeautySheet) self (lowest)
///    ├── (PLVSABeautySliderView) sliderView
///    ├── (PLVSABeautySwitch) beautySwitch
///    ├── (PLVSABeautyTitleView) beautyTypeTitleView
///    ├── (PLVLSBeautyContentView) beautyContentView
///    ├── (PLVSABeautyFilterTitleView) filterTitleView
///    ├── (UIButton) resetButton
///
///
/// UI
@property (nonatomic, strong) PLVSABeautySliderView *sliderView; // 美颜强度sliderView
@property (nonatomic, strong) PLVSABeautySwitch *beautySwitch; // 美颜开关
@property (nonatomic, strong) PLVSABeautyTitleView *beautyTypeTitleView; // 美颜分类标题视图
@property (nonatomic, strong) PLVSABeautyContentView *beautyContentView; // 美颜内容视图
@property (nonatomic, strong) PLVSABeautyFilterTitleView *filterTitleView; // 滤镜标题视图
@property (nonatomic, strong) UIButton *resetButton; // 重置

@end

@implementation PLVSABeautySheet

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth{
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth backgroundColor:[UIColor clearColor]];
    if (self) {
        [PLVBeautyViewModel sharedViewModel].delegate = self;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    UIEdgeInsets areaInsets = [PLVSAUtils sharedUtils].areaInsets;
    
    CGFloat filterTitleViewX = (self.bounds.size.width - 160) / 2;
    CGFloat filterTitleViewY = areaInsets.top + 80;
    CGFloat beautySwitchX = self.bounds.size.width - 100 - (isPad ? 56 : 24);
    CGFloat beautySwitchY = self.bounds.size.height - self.sheetHight - 8 - 30;
    CGFloat resetButtonX = self.bounds.size.width - 56 - (isPad ? 56 : 24);
    CGFloat resetButtonY = 32;
    CGFloat beautyTypeTitleViewX = isPad ? 56 : 24;
    CGFloat beautyTypeTitleViewY = 32;
    CGFloat beautyTypeTitleViewWidth = self.contentView.bounds.size.width - beautyTypeTitleViewX * 2;
    CGFloat sliderViewX = isPad ? 56 : 24;
    CGFloat sliderViewY = self.bounds.size.height - self.sheetHight - 8 - 48;
    CGFloat sliderViewWidth = 211;
    CGFloat sliderViewHeight = 48;
    CGFloat beautyContentViewX = isPad ? 56 : 24;
    CGFloat beautyContentViewY = 72;
    CGFloat beautyContentViewWidth = self.contentView.bounds.size.width - beautyContentViewX;
    CGFloat beautyContentViewHeight = 72;
    if (isLandscape) {
        filterTitleViewX = self.bounds.size.width - self.sheetLandscapeWidth - 160 - 64;
        filterTitleViewY = areaInsets.top + 32;
        beautySwitchX =  self.bounds.size.width - self.sheetLandscapeWidth - areaInsets.right + 28;
        beautySwitchY = 32;
        resetButtonX = self.sheetLandscapeWidth - 56 - 45;
        resetButtonY = 34;
        beautyTypeTitleViewX = 28;
        beautyTypeTitleViewY = 80;
        beautyTypeTitleViewWidth = self.sheetLandscapeWidth - beautyTypeTitleViewX - 45;
        sliderViewX = self.bounds.size.width - self.sheetLandscapeWidth - areaInsets.right + 28;
        sliderViewY = 123;
        sliderViewWidth = self.sheetLandscapeWidth - 28 - 45;
        sliderViewHeight = 20;
        beautyContentViewX = 28;
        beautyContentViewY = self.sliderView.hidden ? sliderViewY : 156;
        beautyContentViewWidth = beautyTypeTitleViewWidth;
        beautyContentViewHeight = self.bounds.size.height - sliderViewY - sliderViewHeight - 17;
    }
    
    // 父类为self
    self.sliderView.frame = CGRectMake(sliderViewX, sliderViewY, sliderViewWidth, sliderViewHeight);
    self.beautySwitch.frame = CGRectMake(beautySwitchX, beautySwitchY, 100, 30);
    
    // 父类为self.contentView
    self.filterTitleView.frame = CGRectMake(filterTitleViewX, filterTitleViewY, 160, 32);
    self.resetButton.frame = CGRectMake(resetButtonX, resetButtonY, 60, 20);
    self.beautyTypeTitleView.frame = CGRectMake(beautyTypeTitleViewX, beautyTypeTitleViewY, beautyTypeTitleViewWidth, 24);
    self.beautyContentView.frame = CGRectMake(beautyContentViewX, beautyContentViewY, beautyContentViewWidth, beautyContentViewHeight);
    
}

#pragma mark - [ Override ]
- (void)deviceOrientationDidChange {
    [super deviceOrientationDidChange];
    [self removeAllView];
    [self setupUI];
}

- (void)showInView:(UIView *)parentView {
    self.sliderView.hidden = ![PLVBeautyViewModel sharedViewModel].beautyIsOpen;
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
- (PLVSABeautySliderView *)sliderView {
    if (!_sliderView) {
        _sliderView = [[PLVSABeautySliderView alloc] init];
        _sliderView.delegate = self;
        _sliderView.hidden = ![PLVBeautyViewModel sharedViewModel].beautyIsOpen;
    }
    return _sliderView;
}

- (PLVSABeautySwitch *)beautySwitch {
    if (!_beautySwitch) {
        _beautySwitch = [[PLVSABeautySwitch alloc] init];
        _beautySwitch.on = [PLVBeautyViewModel sharedViewModel].beautyIsOpen;
        _beautySwitch.delegate = self;
    }
    return _beautySwitch;
}

- (PLVSABeautyTitleView *)beautyTypeTitleView {
    if (!_beautyTypeTitleView) {
        _beautyTypeTitleView = [[PLVSABeautyTitleView alloc] init];
        _beautyTypeTitleView.delegate = self;
    }
    return _beautyTypeTitleView;
}

- (PLVSABeautyContentView *)beautyContentView {
    if (!_beautyContentView) {
        _beautyContentView = [[PLVSABeautyContentView alloc] init];
    }
    return _beautyContentView;
}

- (PLVSABeautyFilterTitleView *)filterTitleView {
    if (!_filterTitleView) {
        _filterTitleView = [[PLVSABeautyFilterTitleView alloc] init];
    }
    return _filterTitleView;
}

- (UIButton *)resetButton {
    if (!_resetButton) {
        _resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_resetButton setTitle:PLVLocalizedString(@"重置") forState:UIControlStateNormal];
        UIImage *image = [PLVSAUtils imageForBeautyResource:@"plvsa_beauty_reset"];
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
    [self addSubview:self.beautySwitch];
    
    [self.contentView addSubview:self.beautyTypeTitleView];
    [self.contentView addSubview:self.beautyContentView];
    [self.contentView addSubview:self.resetButton];
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
    [PLVSAUtils showAlertWithTitle:PLVLocalizedString(@"确定重置吗") Message:PLVLocalizedString(@"重置后所有美颜参数将恢复默认值") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
        [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"重置成功")];
        
        [[PLVBeautyViewModel sharedViewModel] resetBeautyOptionIntensity];
        [weakSelf.beautyContentView resetBeauty];
    }];
    
}

#pragma mark - [ Delegate ]
#pragma mark PLVSABeautyTitleViewDelegate
- (void)beautyTitleView:(PLVSABeautyTitleView *)beautyTitleView didTapButton:(PLVBeautyType)type {
    [[PLVBeautyViewModel sharedViewModel] selectBeautyType:type];
    [self.beautyContentView selectContentViewWithType:type];
}

#pragma mark PLVSABeautySliderViewDelegate
- (void)beautySliderView:(PLVSABeautySliderView *)beautySliderView didChangedValue:(CGFloat)value {
    [[PLVBeautyViewModel sharedViewModel] updateBeautyOptionWithIntensity:value];
}

#pragma mark PLVBeautyViewModelDelegate
- (void)beautyViewModel:(PLVBeautyViewModel *)beautyViewModel didChangeIntensity:(CGFloat)intensity defaultIntensity:(CGFloat)defaultIntensity {
    if (intensity == -1) {
        self.sliderView.hidden = YES;
    } else {
        self.sliderView.hidden = NO;
        [self.sliderView updateSliderValue:intensity defaultValue:defaultIntensity];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)beautyViewModel:(PLVBeautyViewModel *)beautyViewModel didChangeFilterName:(NSString *)filterName {
    [self.filterTitleView showAtView:self title:filterName];
}

#pragma mark PLVSABeautySwitchDelegate
- (void)beautySwitch:(PLVSABeautySwitch *)beautySwitch didChangeOn:(BOOL)on {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautySheet:didChangeOn:)]) {
        [self.delegate beautySheet:self didChangeOn:on];
    }
    
    if (on && ![PLVBeautyViewModel sharedViewModel].isSelectedOriginFilter) {
        self.sliderView.hidden = NO; // 美颜开启 并且 不是选中原图滤镜 时显示强度进度条
    } else {
        self.sliderView.hidden = YES;
    }
    
    [[PLVBeautyViewModel sharedViewModel] beautyOpen:on];
    [self beautyOpen:on];
    [self.beautyContentView beautyOpen:on];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
