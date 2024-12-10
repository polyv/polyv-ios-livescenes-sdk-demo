//
//  PLVLSSettingSheetCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSettingSheetCell.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

// 选项按钮 tag 常量
static int kOptionButtonTagConst = 100;
// 选项按钮最大宽度，屏幕尺寸不足时根据屏幕尺寸进行缩减
static float kOptionButtonMaxWidth = 78.0;

@interface PLVLSSettingSheetCell ()

@property (nonatomic, strong) NSArray <UIButton *> *optionsButton; // 选项按钮数组，只初始化一次
@property (nonatomic, strong) UIView *selectedView; // 选中选项底下蓝色圆点

@property (nonatomic, assign) NSInteger selectedIndex; // 选中索引，初始值为 -1

@end

@implementation PLVLSSettingSheetCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.selectedIndex = -1;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originX = 0;
    CGFloat buttonWidth = kOptionButtonMaxWidth;
    CGFloat leftWidth = self.contentView.bounds.size.width - originX;
    if (leftWidth < [self.optionsButton count] * kOptionButtonMaxWidth) {
        buttonWidth = floor(leftWidth / self.optionsButton.count);
    }
    CGFloat buttonHeight = 30;
    for (int i = 0; i < [self.optionsButton count]; i++) {
        CGFloat buttonOriginX = originX + i * buttonWidth;
        UIButton *button = self.optionsButton[i];
        button.frame = CGRectMake(buttonOriginX, 0, buttonWidth, buttonHeight);
    }
    
    if (self.selectedIndex != -1) {
        self.selectedView.frame = CGRectMake(originX + self.selectedIndex * buttonWidth + (buttonWidth - 4) / 2.0, 25, 4, 4);
    }
}

#pragma mark - Getter

- (UIView *)selectedView {
    if (!_selectedView) {
        _selectedView = [[UIView alloc] init];
        _selectedView.layer.cornerRadius = 2;
        _selectedView.layer.masksToBounds = YES;
        _selectedView.backgroundColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1];
    }
    return _selectedView;
}

#pragma mark - Action

- (void)optionButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (button.selected) {
        return;
    }
    
    NSInteger buttonIndex = button.tag - kOptionButtonTagConst;
    if (self.didSelectedAtIndex) {
        self.didSelectedAtIndex(buttonIndex);
    }
    
    for (int i = 0; i < [self.optionsButton count]; i++) {
        UIButton *button = self.optionsButton[i];
        button.selected = (i == buttonIndex);
    }
    self.selectedIndex = buttonIndex;
    
    if (!self.selectedView.superview) {
        [self.contentView addSubview:self.selectedView];
    }
    CGFloat buttonWidth = button.frame.size.width;
    self.selectedView.frame = CGRectMake(button.frame.origin.x + (buttonWidth - 4) / 2.0, 25, 4, 4);
}

#pragma mark - Public

- (void)setOptionsArray:(NSArray <NSString *> *)optionsArray selectedIndex:(NSInteger)selectedIndex {
    [self updateOptions:optionsArray selectedIndex:selectedIndex];
}

- (void)updateOptions:(NSArray <NSString *> *)options selectedIndex:(NSInteger)selectedIndex {
    if (!options || ![options isKindOfClass:[NSArray class]]) {
        return;
    }
    
    if (!self.optionsButton) { // 设置选项只初始化一次就不再改变，cell不做复用
        NSMutableArray *buttonMuArray = [[NSMutableArray alloc] initWithCapacity:[options count]];
        for (int i = 0; i < [options count]; i++) {
            NSString *option = options[i];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = i + kOptionButtonTagConst;
            button.titleLabel.font = [UIFont systemFontOfSize:14];
            [button setTitle:option forState:UIControlStateNormal];
            UIColor *normalColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
            UIColor *selectedColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1];
            [button setTitleColor:normalColor forState:UIControlStateNormal];
            [button setTitleColor:selectedColor forState:UIControlStateSelected];
            [button addTarget:self action:@selector(optionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [buttonMuArray addObject:button];
            [self.contentView addSubview:button];
        }
        self.optionsButton = [buttonMuArray copy];
    }
    
    if (selectedIndex < 0 || selectedIndex >= [self.optionsButton count] ||
        self.selectedIndex == selectedIndex) {
        return;
    }
    
    if (self.selectedIndex == -1) {
        [self.contentView addSubview:self.selectedView];
    }
    
    for (int i = 0; i < [self.optionsButton count]; i++) {
        UIButton *button = self.optionsButton[i];
        button.selected = (i == selectedIndex);
    }
    self.selectedIndex = selectedIndex;
}

+ (CGFloat)cellHeight {
    return 30 + 15;
}
@end

@interface PLVLSResolutionLevelSheetCell()

@property (nonatomic, strong) UIView *backgroundContentView;
@property (nonatomic, strong) UILabel *resolutionTitleLabel;
@property (nonatomic, strong) UILabel *resolutionDetailsLabel;
@property (nonatomic, strong) UILabel *notSupportedLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;

@end

@implementation PLVLSResolutionLevelSheetCell

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
        _selectedImageView.image = [PLVLSUtils imageForLiveroomResource:@"plvls_liveroom_selected_icon"];
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
