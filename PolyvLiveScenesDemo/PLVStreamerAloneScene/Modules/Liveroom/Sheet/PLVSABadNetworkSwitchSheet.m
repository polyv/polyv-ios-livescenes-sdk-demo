//
//  PLVSABadNetworkSwitchSheet.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/5/4.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABadNetworkSwitchSheet.h"
#import "PLVSABadNetworkSwitchButton.h"
// 工具类
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVSABadNetworkSwitchSheet()

@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) PLVSABadNetworkSwitchButton *clearButton; // 画质优先按钮
@property (nonatomic, strong) PLVSABadNetworkSwitchButton *smoothButton; // 流畅优先按钮

@end

@implementation PLVSABadNetworkSwitchSheet

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    
    CGFloat titleLabelOirignX = isPad ? 56 : 32;
    self.sheetTitleLabel.frame = CGRectMake(titleLabelOirignX, 32, 90, 18);
    
    CGFloat buttonOriginX = isLandscape ? 32 : (isPad ? 56 : 16);
    CGFloat buttonOriginY = 80.0;
    CGFloat buttonWidth = contentViewWidth - buttonOriginX * 2;
    CGFloat buttonHeight = 84.0;
    CGFloat buttonPadding = 12.0;
    
    self.clearButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
    buttonOriginY += buttonHeight + buttonPadding;

    self.smoothButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
    buttonOriginY += buttonHeight + buttonPadding;
}

#pragma mark - [ Override ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        
        [self.contentView addSubview:self.clearButton];
        [self.contentView addSubview:self.smoothButton];
    }
    return self;
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
        _sheetTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _sheetTitleLabel.text = PLVLocalizedString(@"弱网处理");
    }
    return _sheetTitleLabel;
}

- (PLVSABadNetworkSwitchButton *)clearButton {
    if (!_clearButton) {
        _clearButton = [[PLVSABadNetworkSwitchButton alloc] initWithVideoQosPreference:PLVBRTCVideoQosPreferenceClear];
        __weak typeof(self) weakSelf = self;
        [_clearButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectVideoQosPreference:PLVBRTCVideoQosPreferenceClear selected:selected];
        }];
    }
    return _clearButton;
}

- (PLVSABadNetworkSwitchButton *)smoothButton {
    if (!_smoothButton) {
        _smoothButton = [[PLVSABadNetworkSwitchButton alloc] initWithVideoQosPreference:PLVBRTCVideoQosPreferenceSmooth];
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
