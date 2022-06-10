//
//  PLVSABeautyTitleButton.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyTitleButton.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSABeautyTitleButton()

@property (nonatomic, strong) UIView *indicatorView;

@end

@implementation PLVSABeautyTitleButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.indicatorView];
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        self.titleEdgeInsets = UIEdgeInsetsMake(-5, 0, 0, 0);
        [self setTitleColor:[PLVColorUtil colorFromHexString:@"#979797"] forState:UIControlStateNormal];
        [self setTitleColor:[PLVColorUtil colorFromHexString:@"#F0F1F5"] forState:UIControlStateSelected];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.indicatorView.frame = CGRectMake((self.bounds.size.width - 4) / 2, self.bounds.size.height - 4, 4, 4);
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.indicatorView.hidden = !selected;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] init];
        _indicatorView.backgroundColor = [UIColor colorWithRed:51/255.0 green:153/255.0 blue:255/255.0 alpha:1/1.0];
        _indicatorView.layer.cornerRadius = 2;
        _indicatorView.layer.masksToBounds = YES;
        _indicatorView.hidden = YES;
    }
    return _indicatorView;
}

@end
