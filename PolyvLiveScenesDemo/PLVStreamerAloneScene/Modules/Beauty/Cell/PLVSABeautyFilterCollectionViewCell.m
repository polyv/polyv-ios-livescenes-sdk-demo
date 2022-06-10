//
//  PLVSABeautyFilterCollectionViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/18.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyFilterCollectionViewCell.h"
// 工具
#import "PLVSAUtils.h"
// UI
#import "PLVSABeautyMaskView.h"
// 模块
#import "PLVSABeautyCellModel.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSABeautyFilterCollectionViewCell()

#pragma mark UI
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) PLVSABeautyMaskView *beautyMaskView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

#pragma mark 数据
@property (nonatomic, strong) PLVSABeautyCellModel *model;
@property (nonatomic, assign) BOOL beautyOpen;

@end

@implementation PLVSABeautyFilterCollectionViewCell
#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.beautyMaskView];
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.contentView.bounds;
    self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame) - 17, self.contentView.bounds.size.width, 17);
    self.gradientLayer.frame = CGRectMake(0, self.imageView.frame.size.height - 17, self.imageView.frame.size.width, 17);
    self.beautyMaskView.frame = self.contentView.bounds;
}

#pragma mark - [ Override ]

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateColor];
}

#pragma mark - [ Public Method ]
+ (NSString *)cellID {
    return NSStringFromClass(self.class);
}

- (void)updateCellModel:(PLVSABeautyCellModel *)cellModel beautyOpen:(BOOL)beautyOpen {
    self.model = cellModel;
    self.beautyOpen = beautyOpen;
    
    self.imageView.image = [PLVSAUtils imageForBeautyResource:cellModel.imageName];
    self.titleLabel.text = cellModel.title;
    [self updateColor];
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        [_imageView.layer addSublayer:self.gradientLayer];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        }
    return _titleLabel;
}

- (PLVSABeautyMaskView *)beautyMaskView {
    if (!_beautyMaskView) {
        _beautyMaskView = [[PLVSABeautyMaskView alloc] init];
        _beautyMaskView.hidden = YES;
    }
    return _beautyMaskView;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#000000" alpha:0.0].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#000000" alpha:0.6].CGColor,];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0.5, 0);
        _gradientLayer.endPoint = CGPointMake(0.5, 1);
        _gradientLayer.masksToBounds = YES;
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 56, 17) byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(8, 8)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = maskPath.bounds;
        maskLayer.path = maskPath.CGPath;
        _gradientLayer.mask = maskLayer;
    }
    return _gradientLayer;
}

#pragma mark 设置图层颜色
- (void)updateColor {
    if (self.beautyOpen) {
        if (self.selected) {
            self.beautyMaskView.hidden = NO;
        } else {
            self.beautyMaskView.hidden = YES;
        }
        self.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    } else {
        self.beautyMaskView.hidden = NO;
        self.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
    }
    
    [self.beautyMaskView beautyOpen:self.beautyOpen];
}

@end
