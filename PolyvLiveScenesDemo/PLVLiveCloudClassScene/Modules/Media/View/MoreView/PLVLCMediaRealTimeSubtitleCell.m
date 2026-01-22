//
//  PLVLCMediaRealTimeSubtitleCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2026/1/19.
//

#import "PLVLCMediaRealTimeSubtitleCell.h"

#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCMediaRealTimeSubtitleCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) PLVLCMediaMoreModel *model;

@end

@implementation PLVLCMediaRealTimeSubtitleCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    CGFloat leftPadding = fullScreen ? 16.0 : 32.0;
    CGFloat rightPadding = 16.0;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat minGap = 24.0;
    
    CGFloat titleHeight = 20.0;
    CGFloat titleCenterY = (viewHeight - titleHeight) / 2.0;
    
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, titleHeight)];
    
    CGSize buttonSize = CGSizeZero;
    if (self.switchButton.currentImage) {
        buttonSize = self.switchButton.currentImage.size;
    } else {
        buttonSize = self.switchButton.intrinsicContentSize;
    }
    CGFloat maxTitleWidth = viewWidth - leftPadding - rightPadding - buttonSize.width - minGap;
    if (maxTitleWidth < 0) {
        maxTitleWidth = 0;
    }
    CGFloat titleWidth = MIN(titleSize.width, maxTitleWidth);
    self.titleLabel.frame = CGRectMake(leftPadding, titleCenterY, titleWidth, titleHeight);
    
    CGFloat buttonX = CGRectGetMaxX(self.titleLabel.frame) + minGap;
    if (buttonX + buttonSize.width + rightPadding > viewWidth) {
        buttonX = viewWidth - rightPadding - buttonSize.width;
    }
    self.switchButton.frame = CGRectMake(buttonX, (viewHeight - buttonSize.height) / 2.0, buttonSize.width, buttonSize.height);
}

#pragma mark - Public Method

- (void)setupWithModel:(PLVLCMediaMoreModel *)model {
    self.model = model;
    self.titleLabel.text = model.optionTitle;
    BOOL selected = model.selectedIndex == 1;
    self.switchButton.selected = selected;
}

#pragma mark - Private Methods

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.switchButton];
}

- (void)switchButtonAction:(UIButton *)sender {
    if (!self.model) { return; }
    sender.selected = !sender.selected;
    self.model.selectedIndex = sender.selected ? 1 : 0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaRealTimeSubtitleCell:didToggle:model:)]) {
        [self.delegate plvLCMediaRealTimeSubtitleCell:self didToggle:sender.selected model:self.model];
    }
}

#pragma mark - Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#C2C2C2");
        _titleLabel.text = PLVLocalizedString(@"实时字幕");
    }
    return _titleLabel;
}

- (UIButton *)switchButton {
    if (!_switchButton) {
        _switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLCUtils imageForMediaResource:@"plvlc_media_moremenu_switch_off"];
        UIImage *selectedImage = [PLVLCUtils imageForMediaResource:@"plvlc_media_moremenu_switch_on"];
        [_switchButton setImage:normalImage forState:UIControlStateNormal];
        [_switchButton setImage:selectedImage forState:UIControlStateSelected];
        [_switchButton addTarget:self action:@selector(switchButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchButton;
}

@end
