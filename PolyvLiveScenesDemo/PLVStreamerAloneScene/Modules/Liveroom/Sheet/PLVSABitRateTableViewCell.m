//
//  PLVSABitRateTableViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/12/26.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABitRateTableViewCell.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVSABitRateTableViewCell()

@property (nonatomic, strong) UIView *backgroundContentView;
@property (nonatomic, strong) UILabel *resolutionTitleLabel;
@property (nonatomic, strong) UILabel *resolutionDetailsLabel;
@property (nonatomic, strong) UILabel *notSupportedLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;

@end

@implementation PLVSABitRateTableViewCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.backgroundContentView];
        [self.backgroundContentView addSubview:self.resolutionTitleLabel];
        [self.backgroundContentView addSubview:self.resolutionDetailsLabel];
        [self.backgroundContentView addSubview:self.selectedImageView];
        [self.backgroundContentView addSubview:self.notSupportedLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat backgroundContentViewWidth = CGRectGetWidth(self.contentView.bounds) - 52;
    self.backgroundContentView.frame = CGRectMake(26, 0, backgroundContentViewWidth, CGRectGetHeight(self.contentView.bounds) - 12);
    CGFloat labelWidth = [self.resolutionTitleLabel sizeThatFits:CGSizeMake(backgroundContentViewWidth - 40, 22)].width;
    self.resolutionTitleLabel.frame = CGRectMake(20, 12, labelWidth, 22);
    self.resolutionDetailsLabel.frame = CGRectMake(20, CGRectGetMaxY(self.resolutionTitleLabel.frame) + 4, backgroundContentViewWidth - 40, CGRectGetHeight(self.backgroundContentView.bounds) - CGRectGetMaxY(self.resolutionTitleLabel.frame) - 4 - 12);
    self.selectedImageView.frame = CGRectMake(backgroundContentViewWidth - 28, CGRectGetHeight(self.backgroundContentView.bounds) - 32, 28, 32);
    labelWidth = [self.notSupportedLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)].width + 10;
    self.notSupportedLabel.frame = CGRectMake(CGRectGetMaxX(self.resolutionTitleLabel.frame) + 6, CGRectGetMidY(self.resolutionTitleLabel.frame) - 8, labelWidth, 16);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.selectedImageView.hidden = !selected;
    if (selected) {
        self.backgroundContentView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4399FF"].CGColor;
    } else {
        self.backgroundContentView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.04].CGColor;
    }
}

#pragma mark Getter

- (UIView *)backgroundContentView {
    if (!_backgroundContentView) {
        _backgroundContentView = [[UIView alloc] init];
        _backgroundContentView.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.04];
        _backgroundContentView.layer.cornerRadius = 8.0f;
        _backgroundContentView.layer.borderWidth = 1.0f;
        _backgroundContentView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.04].CGColor;
    }
    return _backgroundContentView;
}

- (UILabel *)resolutionTitleLabel {
    if (!_resolutionTitleLabel) {
        _resolutionTitleLabel = [[UILabel alloc] init];
        _resolutionTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _resolutionTitleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
    }
    return _resolutionTitleLabel;
}

- (UILabel *)resolutionDetailsLabel {
    if (!_resolutionDetailsLabel) {
        _resolutionDetailsLabel = [[UILabel alloc] init];
        _resolutionDetailsLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _resolutionDetailsLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        _resolutionDetailsLabel.numberOfLines = 0;
    }
    return _resolutionDetailsLabel;
}

- (UILabel *)notSupportedLabel {
    if (!_notSupportedLabel) {
        _notSupportedLabel = [[UILabel alloc] init];
        _notSupportedLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
        _notSupportedLabel.textAlignment = NSTextAlignmentCenter;
        _notSupportedLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.3];
        _notSupportedLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.1];
        _notSupportedLabel.text = PLVLocalizedString(@"暂不支持");
        _notSupportedLabel.hidden = YES;
        _notSupportedLabel.layer.masksToBounds = YES;
        _notSupportedLabel.layer.cornerRadius = 2.0f;
        _notSupportedLabel.layer.borderWidth = 1.0f;
        _notSupportedLabel.layer.borderColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.1].CGColor;
    }
    return _notSupportedLabel;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_selected_icon"];
        _selectedImageView.hidden = YES;
    }
    return _selectedImageView;
}

#pragma mark - [ Public Method ]

- (void)setupVideoParams:(PLVClientPushStreamTemplateVideoParams *)videoParams {
    NSString *resolutionDetails = @"";
    if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) {
        self.resolutionTitleLabel.text = videoParams.qualityName;
        resolutionDetails = [NSString stringWithFormat:@"分辨率：%.0fp，", videoParams.videoResolution.height];
    } else {
        self.resolutionTitleLabel.text = videoParams.qualityEnName;
    }
    resolutionDetails = [resolutionDetails stringByAppendingFormat:PLVLocalizedString(@"码率：%ldkbps，帧率：%ldfps"), videoParams.videoBitrate, videoParams.videoFrameRate];
    self.resolutionDetailsLabel.text = resolutionDetails;
    if (videoParams.isSupportVideoParams) {
        self.notSupportedLabel.hidden = YES;
        self.userInteractionEnabled = YES;
        self.resolutionDetailsLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        self.resolutionTitleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
    } else {
        self.userInteractionEnabled = NO;
        self.notSupportedLabel.hidden = NO;
        self.resolutionDetailsLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.3];
        self.resolutionTitleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.3];
    }
}

@end
