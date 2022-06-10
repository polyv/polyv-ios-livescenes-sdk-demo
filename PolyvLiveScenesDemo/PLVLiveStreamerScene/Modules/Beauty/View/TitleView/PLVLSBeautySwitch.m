//
//  PLVLSBeautySwitch.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautySwitch.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@implementation PLVLSBeautySwitch

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
        [self addSubview:self.beautySwitch];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(0, (self.bounds.size.height - 20) / 2, 60, 20);
    self.beautySwitch.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame) + 4, (self.bounds.size.height - 18) / 2, 32, 18);
}

#pragma mark - [ Public Method ]
- (void)setOn:(BOOL)on {
    _on = on;
    self.beautySwitch.on = on;
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textColor = [UIColor whiteColor];
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 1;
        shadow.shadowOffset = CGSizeMake(0, 0);
        shadow.shadowColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.4];
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"美颜开关" attributes:@{NSShadowAttributeName:shadow}];
        _titleLabel.attributedText = attributedString;
    }
    return _titleLabel;
}

- (UISwitch *)beautySwitch {
    if (!_beautySwitch) {
        _beautySwitch = [[UISwitch alloc] init];
        _beautySwitch.onTintColor = [PLVColorUtil colorFromHexString:@"#0080FF"];
        _beautySwitch.transform = CGAffineTransformMakeScale(0.627, 0.58);
        [_beautySwitch addTarget:self action:@selector(beautySwitchAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _beautySwitch;
}

#pragma mark - [ Event ]
#pragma mark Action
- (void)beautySwitchAction:(UISwitch *)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautySwitch:didChangeOn:)]) {
        [self.delegate beautySwitch:self didChangeOn:sender.on];
    }
}

@end
