//
//  PLVSANoiseCancellationModeSwitchSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/7/30.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVSANoiseCancellationModeSwitchSheet.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVSANoiseCancellationModeSwitchButton : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) PLVBLinkMicNoiseCancellationLevel noiseCancellationLevel;

/// 点击触发
@property (nonatomic, copy) void (^buttonActionBlock) (BOOL selected);

- (instancetype)initWithNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel;

@end

@implementation PLVSANoiseCancellationModeSwitchButton

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGFloat originX = 20.0;
    CGFloat originY = 20.0;
    
    CGFloat titleHeight = self.titleLabel.font.lineHeight;
    self.titleLabel.frame = CGRectMake(originX, originY, width - originX * 2, titleHeight);
    
    originY = CGRectGetMaxY(self.titleLabel.frame) + 8.0;
    self.detailLabel.frame = CGRectMake(originX, originY, width - originX * 2, height - originY);
    [self.detailLabel sizeToFit];
    
    self.selectedImageView.frame = CGRectMake(width - 28, height - 32, 28, 32);
}

#pragma mark - [ Public Method ]

- (instancetype)initWithNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel{
    self = [super init];
    if (self) {
        _noiseCancellationLevel = noiseCancellationLevel;
        
        [self initUI];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    self.layer.borderWidth = selected ? 1.0 : 0;
    self.selectedImageView.hidden = !selected;
}

#pragma mark - [ Private Method ]

- (void)initUI {
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.04];
    self.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4399FF"].CGColor;
    self.layer.borderWidth = self.selected ? 1.0 : 0;
    self.layer.cornerRadius = 8.0;
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.detailLabel];
    [self addSubview:self.selectedImageView];
    
    if (self.noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelAggressive) {
        self.titleLabel.text = PLVLocalizedString(@"自适应降噪");
        self.detailLabel.text = PLVLocalizedString(@"提供声源智能识别和降噪的能力，适用于会议、教育培训等大多数直播场景");
    } else if (self.noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelSoft) {
        self.titleLabel.text = PLVLocalizedString(@"均衡降噪");
        self.detailLabel.text = PLVLocalizedString(@"提供统一的降噪效果，主要减少背景中的环境噪音，对人声和主要声音有较好的保留效果，适用于氛围型直播场景");
    }
}

#pragma mark Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _titleLabel.font = [UIFont systemFontOfSize:16];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        _detailLabel.font = [UIFont systemFontOfSize:14];
        _detailLabel.numberOfLines = 0;
    }
    return _detailLabel;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_selected_icon"];
        _selectedImageView.hidden = YES;
    }
    return _selectedImageView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    if (self.buttonActionBlock) {
        self.buttonActionBlock(self.selected);
    }
}

@end

@interface PLVSANoiseCancellationModeSwitchSheet()

@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) PLVSANoiseCancellationModeSwitchButton *adaptiveModeButton; // 自适应降噪按钮
@property (nonatomic, strong) PLVSANoiseCancellationModeSwitchButton *balancedModeButton; // 均衡降噪按钮

@end

@implementation PLVSANoiseCancellationModeSwitchSheet

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    
    CGFloat titleLabelOirignX = isPad ? 56 : 32;
    self.sheetTitleLabel.frame = CGRectMake(titleLabelOirignX, 32, contentViewWidth - titleLabelOirignX, 18);
    
    CGFloat buttonOriginX = isLandscape ? 32 : (isPad ? 56 : 16);
    CGFloat buttonOriginY = 80.0;
    CGFloat buttonWidth = contentViewWidth - buttonOriginX * 2;
    CGFloat buttonHeight = 116.0;
    CGFloat buttonPadding = 12.0;
    
    self.adaptiveModeButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
    buttonOriginY += buttonHeight + buttonPadding;
    buttonHeight += 22;

    self.balancedModeButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
}

#pragma mark - [ Override ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        
        [self.contentView addSubview:self.adaptiveModeButton];
        [self.contentView addSubview:self.balancedModeButton];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView currentNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel {
    if (noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelAggressive) {
        self.adaptiveModeButton.selected = YES;
        self.balancedModeButton.selected = NO;
    } else if (noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelSoft) {
        self.adaptiveModeButton.selected = NO;
        self.balancedModeButton.selected = YES;
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
        _sheetTitleLabel.text = PLVLocalizedString(@"降噪");
    }
    return _sheetTitleLabel;
}

- (PLVSANoiseCancellationModeSwitchButton *)adaptiveModeButton {
    if (!_adaptiveModeButton) {
        _adaptiveModeButton = [[PLVSANoiseCancellationModeSwitchButton alloc] initWithNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelAggressive];
        __weak typeof(self) weakSelf = self;
        [_adaptiveModeButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelAggressive selected:selected];
        }];
    }
    return _adaptiveModeButton;
}

- (PLVSANoiseCancellationModeSwitchButton *)balancedModeButton {
    if (!_balancedModeButton) {
        _balancedModeButton = [[PLVSANoiseCancellationModeSwitchButton alloc] initWithNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelSoft];
        __weak typeof(self) weakSelf = self;
        [_balancedModeButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelSoft selected:selected];
        }];
    }
    return _balancedModeButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)selectNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)selectedLevel selected:(BOOL)selected {
    [self dismiss];
    
    if (!selected) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(noiseCancellationModeSwitchSheet:wannaChangeNoiseCancellationLevel:)]) {
            [self.delegate noiseCancellationModeSwitchSheet:self wannaChangeNoiseCancellationLevel:selectedLevel];
        }
    }
}

@end
