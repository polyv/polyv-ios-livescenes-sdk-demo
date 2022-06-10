//
//  PLVSABeautySliderView.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautySliderView.h"
// 工具
#import "PLVSAUtils.h"
// UI
#import "PLVSASliderView.h"
// 模块
#import "PLVSABeautyViewModel.h"

@interface PLVSABeautySliderView() <
PLVSASliderViewDelegate
>

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) PLVSASliderView *slider;

@end

@implementation PLVSABeautySliderView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.valueLabel];
        [self addSubview:self.slider];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.slider.frame = CGRectMake(0, self.bounds.size.height - 20, self.bounds.size.width, 20);
}

#pragma mark - [ Public Method ]

- (void)updateSliderValue:(CGFloat)value defaultValue:(CGFloat)defaultValue {
    self.slider.progress = value;
    self.slider.defaultProgress = defaultValue;
    
    // 设置文字、文字阴影
    NSString *title = [NSString stringWithFormat:@"%ld", lroundf(self.slider.progress * 100)];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 1;
    shadow.shadowOffset = CGSizeMake(0, 0);
    shadow.shadowColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.4];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:title attributes:@{NSShadowAttributeName:shadow, NSFontAttributeName : self.valueLabel.font, NSForegroundColorAttributeName : self.valueLabel.textColor}];
    self.valueLabel.attributedText = attributedString;
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter

- (UILabel *)valueLabel {
    if (!_valueLabel) {
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont systemFontOfSize:14];
        _valueLabel.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
        _valueLabel.text = @"";
        _valueLabel.textAlignment = [PLVSAUtils sharedUtils].isLandscape ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    }
    return _valueLabel;
}

- (PLVSASliderView *)slider {
    if (!_slider) {
        _slider = [[PLVSASliderView alloc] init];
        _slider.delegate = self;
        _slider.backgroundColor = [UIColor clearColor];
    }
    return _slider;
}

#pragma mark 计算文字size
- (CGSize)valueLabelSize {
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:self.valueLabel.text attributes:@{NSFontAttributeName : self.valueLabel.font}];
    return [attributed boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 20) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
}

#pragma mark - [ Delegate ]
#pragma mark PLVSASliderViewDelegate
- (void)sliderView:(PLVSASliderView *)sliderView didChangedValue:(CGFloat)value {
    self.valueLabel.text = [NSString stringWithFormat:@"%ld", lroundf(value * 100)];
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(beautySliderView:didChangedValue:)]){
        [self.delegate beautySliderView:self didChangedValue:value];
    }
}

- (void)sliderView:(PLVSASliderView *)sliderView didChangedCircleRect:(CGRect)rect {
    CGSize size = [self valueLabelSize];
    rect = [sliderView convertRect:rect toView:self];
    if ([PLVSAUtils sharedUtils].isLandscape) {
        rect.origin.x = CGRectGetMaxX(self.slider.frame);
        rect.origin.y = size.height - rect.size.height;
    } else {
        rect.origin.x = rect.origin.x - (size.width - rect.size.width) / 2;
        rect.origin.y = rect.origin.y - size.height - 4;
    }
    rect.size = size;
    
    self.valueLabel.frame = rect;
}

@end
