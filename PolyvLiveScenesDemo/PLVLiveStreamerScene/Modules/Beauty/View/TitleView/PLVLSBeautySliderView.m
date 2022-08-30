//
//  PLVLSBeautySliderView.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautySliderView.h"
// 工具
#import "PLVLSUtils.h"
// UI
#import "PLVLSSliderView.h"
// 模块
#import "PLVBeautyViewModel.h"

@interface PLVLSBeautySliderView()<
PLVLSSliderViewDelegate
>

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) PLVLSSliderView *slider;

@end

@implementation PLVLSBeautySliderView

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
        _valueLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _valueLabel;
}

- (PLVLSSliderView *)slider {
    if (!_slider) {
        _slider = [[PLVLSSliderView alloc] init];
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
#pragma mark PLVLSSliderViewDelegate
- (void)sliderView:(PLVLSSliderView *)sliderView didChangedValue:(CGFloat)value {
    self.valueLabel.text = [NSString stringWithFormat:@"%ld", lroundf(value * 100)];
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(beautySliderView:didChangedValue:)]){
        [self.delegate beautySliderView:self didChangedValue:value];
    }
}

- (void)sliderView:(PLVLSSliderView *)sliderView didChangedCircleRect:(CGRect)rect {
    CGSize size = [self valueLabelSize];
    rect = [sliderView convertRect:rect toView:self];
   
    rect.origin.x = rect.origin.x - (size.width - rect.size.width) / 2;
    rect.origin.y = rect.origin.y - size.height - 4;
    rect.size = size;
    
    self.valueLabel.frame = rect;
}

@end
