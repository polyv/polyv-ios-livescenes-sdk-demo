//
//  PLVLCMediaDanmuSettingCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/4/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCMediaDanmuSettingCell.h"

#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCMediaDanmuSettingCellSlider : UISlider

// 点的数量
@property (nonatomic, assign) NSInteger numberOfDots;
// 点的半径
@property (nonatomic, assign) CGFloat dotRadius;
// 点的颜色
@property (nonatomic, strong) UIColor *dotColor;
// 轨道的颜色
@property (nonatomic, strong) UIColor *trackColor;

@end

@implementation PLVLCMediaDanmuSettingCellSlider

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor {
    if (!self.numberOfDots || self.numberOfDots < 2) {
        [super setMinimumTrackTintColor:[UIColor clearColor]];
    } else {
        [super setMinimumTrackTintColor:minimumTrackTintColor];
    }
}

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor {
    if (!self.numberOfDots || self.numberOfDots < 2) {
        [super setMaximumTrackTintColor:[UIColor clearColor]];
    } else {
        [super setMaximumTrackTintColor:maximumTrackTintColor];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!self.numberOfDots || self.numberOfDots < 2) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGFloat trackHeight = trackRect.size.height;
    CGFloat trackY = trackRect.origin.y + (trackRect.size.height - trackHeight) / 2.0;
    CGFloat trackWidth = trackRect.size.width;
    UIBezierPath *trackPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(trackRect.origin.x, trackY, trackWidth, trackHeight) cornerRadius:1];
    CGContextSetFillColorWithColor(context, self.trackColor.CGColor);
    CGContextAddPath(context, trackPath.CGPath);
    CGContextFillPath(context);

    CGFloat dotSpacing = trackRect.size.width / (self.numberOfDots - 1);
    CGFloat dotX = trackRect.origin.x;
    CGFloat dotY = trackRect.origin.y + trackRect.size.height / 2;
    CGFloat offset = 2;
    
    for (NSUInteger i = 0; i < self.numberOfDots; i++) {
        // 第一个点和最后一个点调整偏移位置
        if (i == 0) {
            CGContextAddArc(context, dotX + offset, dotY, self.dotRadius, 0, M_PI*2, 0);
        } else if (i == self.numberOfDots - 1) {
            CGContextAddArc(context, dotX - offset, dotY, self.dotRadius, 0, M_PI*2, 0);
        } else {
            CGContextAddArc(context, dotX, dotY, self.dotRadius, 0, M_PI*2, 0);
        }
        CGContextSetFillColorWithColor(context, self.dotColor.CGColor);
        CGContextFillPath(context);
        
        dotX += dotSpacing;
    }
}

- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectMake(0, bounds.size.height / 2.0 - 2, bounds.size.width, 4);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.value];
    CGRect extendedThumbRect = CGRectInset(thumbRect, -22.0, -22.0);
    return CGRectContainsPoint(extendedThumbRect, point);
}

@end

@interface PLVLCMediaDanmuSettingCell ()

#pragma mark 数据


@property (nonatomic, strong) NSArray <NSNumber *> *currentScaleValueArray;
@property (nonatomic, strong) NSArray <NSString *> *currentScaleTitleArray;
@property (nonatomic, copy) NSString *currentSelectedTitle;
@property (nonatomic, copy) NSNumber *currentSelectedScaleIndex;

#pragma mark UI
/// view hierarchy
///
/// (PLVLCMediaMoreCell) self
/// └── (UIView) contentView
///     ├── (UILabel) optionTitleLabel
///     ├── (UISlider) itemLabel
///     └── (UILabel) slider
@property (nonatomic, strong) UILabel *optionTitleLabel;
@property (nonatomic, strong) UILabel *itemLabel;
@property (nonatomic, strong) PLVLCMediaDanmuSettingCellSlider *slider;

@end

@implementation PLVLCMediaDanmuSettingCell

#pragma mark - [ Life Period ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    // 横屏布局
    CGFloat leftPadding = 32.0;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    self.optionTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.optionTitleLabel.frame = CGRectMake(leftPadding, 0, 100, 14);
    self.itemLabel.frame = CGRectMake(viewWidth - 66 - 58, CGRectGetMaxY(self.optionTitleLabel.frame) + 14, 62, 14);
    self.slider.frame = CGRectMake(leftPadding, CGRectGetMinY(self.itemLabel.frame), CGRectGetMinX(self.itemLabel.frame) - leftPadding - 14, 14);
}

#pragma mark - [ Public Methods ]

- (void)setDanmuSpeedCellWithTitle:(NSString *)title scaleValueArray:(NSArray<NSNumber *> *)scaleValueArray scaleTitleArray:(NSArray<NSString *> *)scaleTitleArray defaultScaleIndex:(NSNumber *)defaultScaleIndex {
    self.optionTitleLabel.text = title;
    self.currentScaleValueArray = scaleValueArray;
    self.currentScaleTitleArray = scaleTitleArray;
    self.currentSelectedScaleIndex = defaultScaleIndex;
    NSString *currentScaleTitle = [self currentTitleWithIndex:defaultScaleIndex];
    self.itemLabel.text = currentScaleTitle;
    self.currentSelectedTitle = currentScaleTitle;
    [self resetSlider];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.optionTitleLabel];
    [self.contentView addSubview:self.slider];
    [self.contentView addSubview:self.itemLabel];
}

- (void)resetSlider{
    self.slider.value = self.currentSelectedScaleIndex.floatValue;
    NSUInteger numberOfScale = ![PLVFdUtil checkArrayUseable:self.currentScaleValueArray] ? 0 : self.currentScaleValueArray.count;
    if (numberOfScale > 2) {
        self.slider.trackColor = PLV_UIColorFromRGB(@"#666666");
        self.slider.dotColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.5);
        self.slider.dotRadius = 2;
    } else {
        self.slider.minimumTrackTintColor = PLV_UIColorFromRGB(@"#2196F3");
        self.slider.maximumTrackTintColor = PLV_UIColorFromRGB(@"#666666");
    }
    self.slider.numberOfDots = numberOfScale;
}

#pragma mark Getter

- (UILabel *)optionTitleLabel {
    if (!_optionTitleLabel) {
        _optionTitleLabel = [[UILabel alloc] init];
        _optionTitleLabel.text = PLVLocalizedString(@"弹幕速度");
        _optionTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _optionTitleLabel.textColor = PLV_UIColorFromRGB(@"#C2C2C2");
    }
    return _optionTitleLabel;
}

- (UILabel *)itemLabel {
    if (!_itemLabel) {
        _itemLabel = [[UILabel alloc] init];
        _itemLabel.text = PLVLocalizedString(@"标准");
        _itemLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _itemLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
    }
    return _itemLabel;
}

- (PLVLCMediaDanmuSettingCellSlider *)slider {
    if (!_slider) {
        _slider = [[PLVLCMediaDanmuSettingCellSlider alloc] init];
        _slider.minimumValue = 0.0;
        _slider.maximumValue = 4.0;
        _slider.value = 2.0;
        [_slider addTarget:self action:@selector(sliderTouchEndAction:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [_slider addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventValueChanged];
        _slider.minimumTrackTintColor = PLV_UIColorFromRGB(@"#2196F3");
        _slider.maximumTrackTintColor = PLV_UIColorFromRGB(@"#666666");
        [_slider setThumbImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_skin_slider_blue_thumbimage"] forState:UIControlStateNormal];
    }
    return _slider;
}

- (NSString *)currentTitleWithIndex:(NSNumber *)index {
    NSUInteger i = index.integerValue;
    if (![PLVFdUtil checkArrayUseable:self.currentScaleTitleArray] ||
        self.currentScaleTitleArray.count - 1 < i ) {
        return nil;
    }
    return self.currentScaleTitleArray[i];
}

- (NSNumber *)currentValueWithIndex:(NSNumber *)index {
    NSUInteger i = index.integerValue;
    if (![PLVFdUtil checkArrayUseable:self.currentScaleValueArray] ||
        self.currentScaleValueArray.count - 1 < i ) {
        return nil;
    }
    return self.currentScaleValueArray[i];
}

#pragma mark - Action

- (void)sliderTouchEndAction:(UISlider *)sender {
    int index = (int)self.slider.value;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaDanmuSettingCell:updateSelectedScaleValue:)]) {
        [self.delegate plvLCMediaDanmuSettingCell:self updateSelectedScaleValue:[self currentValueWithIndex:[NSNumber numberWithInt:index]]];
    }
}

- (void)sliderValueChangedAction:(UISlider *)slider {
    float newStep = roundf(slider.value);
    slider.value = newStep;
    self.itemLabel.text = [self currentTitleWithIndex:[NSNumber numberWithFloat:newStep]];
}

@end
