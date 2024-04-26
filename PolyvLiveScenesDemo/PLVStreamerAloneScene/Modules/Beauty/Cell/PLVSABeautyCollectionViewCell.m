//
//  PLVSABeautyCollectionViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyCollectionViewCell.h"
// 工具
#import "PLVSAUtils.h"
// 模块
#import "PLVSABeautyCellModel.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSABeautyCollectionViewCell()

#pragma mark UI
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *beautyMaskView;
#pragma mark 数据
@property (nonatomic, strong) PLVSABeautyCellModel *model;
@property (nonatomic, assign) BOOL beautyOpen;

@end

@implementation PLVSABeautyCollectionViewCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(self.bounds.size.width/2 - 18, 0, 36, 36);
    self.titleLabel.frame = CGRectMake(-5, CGRectGetMaxY(self.imageView.frame) + 8, self.contentView.bounds.size.width + 10, 17);
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

- (void)updateCellModel:(PLVSABeautyCellModel *)cellModel beautyOpen:(BOOL)beautyOpen{
    self.model = cellModel;
    self.beautyOpen = beautyOpen;
    
    UIImage *image = [PLVSAUtils imageForBeautyResource:cellModel.imageName];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.imageView.image = image;
    self.titleLabel.text = cellModel.title;
    [self updateColor];
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.layer.cornerRadius = 18;
        _imageView.layer.masksToBounds = YES;
        _imageView.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.08];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        }
    return _titleLabel;
}

#pragma mark 设置图层颜色
- (void)updateColor {
    if (self.beautyOpen) {
        self.imageView.tintColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.9];
        if (self.selected) {
            self.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#4399FF"];
            self.imageView.layer.borderWidth = 1;
            self.imageView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4399FF"].CGColor;
        } else {
            self.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
            self.imageView.layer.borderWidth = 0;
            self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        }
    } else {
        self.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        self.imageView.tintColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.4];
    }
}
@end

