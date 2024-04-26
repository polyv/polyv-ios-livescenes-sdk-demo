//
//  PLVLSBadNetworkSwitchButton.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/5/4.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLSBadNetworkSwitchButton.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLSBadNetworkSwitchButton ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) PLVBRTCVideoQosPreference videoQosPreference;

@end

@implementation PLVLSBadNetworkSwitchButton

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGFloat originX = 20.0;
    CGFloat originY = 12.0;
    
    CGFloat titleHeight = self.titleLabel.font.lineHeight;
    self.titleLabel.frame = CGRectMake(originX, originY, width - originX * 2, titleHeight);
    
    originY = CGRectGetMaxY(self.titleLabel.frame) + 4.0;
    self.detailLabel.frame = CGRectMake(originX, originY, width - originX * 2, height - originY);
    [self.detailLabel sizeToFit];
    
    self.selectedImageView.frame = CGRectMake(width - 28, height - 32, 28, 32);
}

#pragma mark - [ Public Method ]

- (instancetype)initWithVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference {
    self = [super init];
    if (self) {
        _videoQosPreference = videoQosPreference;
        
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
    
    if (self.videoQosPreference == PLVBRTCVideoQosPreferenceClear) {
        self.titleLabel.text = PLVLocalizedString(@"画质优先");
        self.detailLabel.text = PLVLocalizedString(@"当网络状态差时，优先保证画面清晰度，但会造成观看画面卡顿");
    } else if (self.videoQosPreference == PLVBRTCVideoQosPreferenceSmooth) {
        self.titleLabel.text = PLVLocalizedString(@"流畅优先");
        self.detailLabel.text = PLVLocalizedString(@"当网络状态差时，优先保证画面流畅度，但清晰度会下降");
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
        _detailLabel.font = [UIFont systemFontOfSize:12];
        _detailLabel.numberOfLines = 0;
    }
    return _detailLabel;
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
