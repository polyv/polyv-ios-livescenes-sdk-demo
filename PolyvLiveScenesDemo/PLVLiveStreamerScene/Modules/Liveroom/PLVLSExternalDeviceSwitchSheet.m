//
//  PLVLSExternalDeviceSwitchSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/7/1.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLSExternalDeviceSwitchSheet.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLSExternalDeviceSwitchButton : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL localExternalDeviceEnabled;

/// 点击触发
@property (nonatomic, copy) void (^buttonActionBlock) (BOOL selected);

- (instancetype)initWithExternalDeviceEnabled:(BOOL)enabled;

@end

@implementation PLVLSExternalDeviceSwitchButton

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGFloat originX = 20.0;
    CGFloat titleHeight = self.titleLabel.font.lineHeight;
    CGFloat originY = (height - titleHeight)/2;
    
    self.titleLabel.frame = CGRectMake(originX, originY, width - originX * 2, titleHeight);
    self.selectedImageView.frame = CGRectMake(width - 28, height - 32, 28, 32);
}

#pragma mark - [ Public Method ]

- (instancetype)initWithExternalDeviceEnabled:(BOOL)enabled {
    self = [super init];
    if (self) {
        _localExternalDeviceEnabled = enabled;
        
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
    [self addSubview:self.selectedImageView];
    
    self.titleLabel.text = self.localExternalDeviceEnabled ? PLVLocalizedString(@"开启") : PLVLocalizedString(@"关闭");
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

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.image = [PLVLSUtils imageForLiveroomResource:@"plvls_liveroom_selected_icon"];
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

@interface PLVLSExternalDeviceSwitchSheet()

@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UILabel *sheetDetailLabel;// 弹层详细信息
@property (nonatomic, strong) PLVLSExternalDeviceSwitchButton *openButton; // 开启按钮
@property (nonatomic, strong) PLVLSExternalDeviceSwitchButton *closeButton; // 关闭按钮

@end

@implementation PLVLSExternalDeviceSwitchSheet

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    
    CGFloat titleLabelOirignX = isPad ? 56 : 32;
    self.sheetTitleLabel.frame = CGRectMake(titleLabelOirignX, 32, contentViewWidth - titleLabelOirignX, 18);

    CGFloat buttonOriginX = isPad ? 56 : 16;
    CGFloat buttonWidth = contentViewWidth - buttonOriginX * 2;
    CGFloat buttonHeight = 64;
    CGFloat buttonPadding = 16.0;
    
    self.sheetDetailLabel.frame = CGRectMake(buttonOriginX, CGRectGetMaxY(self.sheetTitleLabel.frame) + 24, contentViewWidth - buttonOriginX * 2, 44);
    CGFloat buttonOriginY = CGRectGetMaxY(self.sheetDetailLabel.frame) + 16;
    
    self.openButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
    buttonOriginY += buttonHeight + buttonPadding;

    self.closeButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
}

#pragma mark - [ Override ]

- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth {
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.sheetDetailLabel];
        [self.contentView addSubview:self.openButton];
        [self.contentView addSubview:self.closeButton];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView currentExternalDeviceEnabled:(BOOL)enabled {
    if (enabled) {
        self.openButton.selected = YES;
        self.closeButton.selected = NO;
    } else {
        self.openButton.selected = NO;
        self.closeButton.selected = YES;
    }
    
    [self showInView:parentView];
}

#pragma mark - [ Private Method ]

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _sheetTitleLabel.text = PLVLocalizedString(@"外接设备");
    }
    return _sheetTitleLabel;
}

- (UILabel *)sheetDetailLabel {
    if (!_sheetDetailLabel) {
        _sheetDetailLabel = [[UILabel alloc] init];
        _sheetDetailLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.6];
        _sheetDetailLabel.font = [UIFont systemFontOfSize:14];
        _sheetDetailLabel.text = PLVLocalizedString(@"适用于直播过程中，通过外接麦克风收集音量的场景时，开启此功能后将切换至媒体音量，保证正常收音。");
        _sheetDetailLabel.numberOfLines = 0;
    }
    return _sheetDetailLabel;
}

- (PLVLSExternalDeviceSwitchButton *)openButton {
    if (!_openButton) {
        _openButton = [[PLVLSExternalDeviceSwitchButton alloc] initWithExternalDeviceEnabled:YES];
        __weak typeof(self) weakSelf = self;
        [_openButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectExternalDeviceEnable:YES selected:selected];
        }];
    }
    return _openButton;
}

- (PLVLSExternalDeviceSwitchButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[PLVLSExternalDeviceSwitchButton alloc] initWithExternalDeviceEnabled:NO];
        __weak typeof(self) weakSelf = self;
        [_closeButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectExternalDeviceEnable:NO selected:selected];
        }];
    }
    return _closeButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)selectExternalDeviceEnable:(BOOL)enabled selected:(BOOL)selected {
    if (!enabled || selected) {
        [self dismiss];
    }
    
    if (!selected) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(externalDeviceSwitchSheet:wannaChangeExternalDevice:)]) {
            [self.delegate externalDeviceSwitchSheet:self wannaChangeExternalDevice:enabled];
        }
    }
}

@end 