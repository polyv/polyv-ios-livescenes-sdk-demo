//
//  PLVLSBadNetworkSwitchSheet.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/5/4.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBadNetworkSwitchSheet.h"
#import "PLVLSBadNetworkSwitchButton.h"
// 工具类
#import "PLVLSUtils.h"

@interface PLVLSBadNetworkSwitchSheet()

@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIView *titleSplitLine; // 标题底部分割线
@property (nonatomic, strong) PLVLSBadNetworkSwitchButton *clearButton; // 画质优先按钮
@property (nonatomic, strong) PLVLSBadNetworkSwitchButton *smoothButton; // 流畅优先按钮

@property (nonatomic, assign) CGFloat sheetWidth; // 父类数据
@end

@implementation PLVLSBadNetworkSwitchSheet

@synthesize sheetWidth = _sheetWidth;

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    CGFloat sheetWidth = [UIScreen mainScreen].bounds.size.width * 0.44;
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.titleSplitLine];
        
        [self.contentView addSubview:self.clearButton];
        [self.contentView addSubview:self.smoothButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat originX = 16;
    CGFloat sheetTitleLabelTop = 14;
    CGFloat titleSplitLineTop = 44;
    CGFloat logoutButtonHeight = 48;
    
    if (isPad) {
        sheetTitleLabelTop += PLVLSUtils.safeTopPad;
        titleSplitLineTop += PLVLSUtils.safeTopPad;
        logoutButtonHeight = 60;
    }
    
    self.sheetTitleLabel.frame = CGRectMake(originX, sheetTitleLabelTop, self.sheetWidth - originX * 2, 22);
    self.titleSplitLine.frame = CGRectMake(originX, titleSplitLineTop, self.sheetWidth - originX * 2, 1);
    
    CGFloat buttonOriginX = 32.0;
    CGFloat buttonOriginY = CGRectGetMaxY(self.titleSplitLine.frame) + 24;
    CGFloat buttonWidth = self.sheetWidth - buttonOriginX * 2;
    CGFloat buttonHeight = 84.0;
    CGFloat buttonPadding = 12.0;
    
    self.clearButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
    buttonOriginY += buttonHeight + buttonPadding;
    
    self.smoothButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
    buttonOriginY += buttonHeight + buttonPadding;
}

#pragma mark - [ Override ]

- (void)showInView:(UIView *)parentView {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat scale = isPad ? 0.43 : 0.44;
    self.sheetWidth = screenWidth * scale;
    [super showInView:parentView];
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView currentVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference {
    if (videoQosPreference == PLVBRTCVideoQosPreferenceClear) {
        self.clearButton.selected = YES;
        self.smoothButton.selected = NO;
    } else if (videoQosPreference == PLVBRTCVideoQosPreferenceSmooth) {
        self.clearButton.selected = NO;
        self.smoothButton.selected = YES;
    }
    
    [self showInView:parentView];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sheetTitleLabel.text = @"弱网处理";
    }
    return _sheetTitleLabel;
}

- (UIView *)titleSplitLine {
    if (!_titleSplitLine) {
        _titleSplitLine = [[UIView alloc] init];
        _titleSplitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1];
    }
    return _titleSplitLine;
}

- (PLVLSBadNetworkSwitchButton *)clearButton {
    if (!_clearButton) {
        _clearButton = [[PLVLSBadNetworkSwitchButton alloc] initWithVideoQosPreference:PLVBRTCVideoQosPreferenceClear];
        __weak typeof(self) weakSelf = self;
        [_clearButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectVideoQosPreference:PLVBRTCVideoQosPreferenceClear selected:selected];
        }];
    }
    return _clearButton;
}

- (PLVLSBadNetworkSwitchButton *)smoothButton {
    if (!_smoothButton) {
        _smoothButton = [[PLVLSBadNetworkSwitchButton alloc] initWithVideoQosPreference:PLVBRTCVideoQosPreferenceSmooth];
        __weak typeof(self) weakSelf = self;
        [_smoothButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectVideoQosPreference:PLVBRTCVideoQosPreferenceSmooth selected:selected];
        }];
    }
    return _smoothButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)selectVideoQosPreference:(PLVBRTCVideoQosPreference)selectedPeference selected:(BOOL)selected {
    [self dismiss];
    
    if (!selected) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(switchSheet:didChangedVideoQosPreference:)]) {
            [self.delegate switchSheet:self didChangedVideoQosPreference:selectedPeference];
        }
    }
}

@end
