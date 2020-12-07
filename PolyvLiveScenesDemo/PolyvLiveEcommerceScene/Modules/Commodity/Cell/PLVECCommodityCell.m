//
//  PLVECCommodityCell.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCommodityCell.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>

@implementation PLVECCommodityCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        
        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.layer.cornerRadius = 10.0;
        self.coverImageView.layer.masksToBounds = YES;
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.coverImageView];
        
        self.showIdLabel = [[UILabel alloc] init];
        self.showIdLabel.frame = CGRectMake(0, 0, 27, 16);
        self.showIdLabel.textColor = UIColor.whiteColor;
        self.showIdLabel.font = [UIFont systemFontOfSize:12];
        self.showIdLabel.textAlignment = NSTextAlignmentCenter;
        self.showIdLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35f];
        [self.coverImageView addSubview:self.showIdLabel];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.textColor = UIColor.whiteColor;
        self.nameLabel.font = [UIFont systemFontOfSize:14.0];
        self.nameLabel.numberOfLines = 2;
        [self addSubview:self.nameLabel];
        
        self.realPriceLabel = [[UILabel alloc] init];
        self.realPriceLabel.textColor = [UIColor colorWithRed:1 green:71/255.0 blue:58/255.0 alpha:1];
        self.realPriceLabel.textAlignment = NSTextAlignmentLeft;
        if (@available(iOS 8.2, *)) {
            self.realPriceLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
        } else {
            self.realPriceLabel.font = [UIFont systemFontOfSize:18.0];
        }
        [self addSubview:self.realPriceLabel];
        
        self.priceLabel = [[UILabel alloc] init];
        self.priceLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.priceLabel];
        
        self.selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.selectButton.layer.cornerRadius = 13.5;
        self.selectButton.layer.masksToBounds = YES;
        self.selectButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        self.selectButton.backgroundColor = [UIColor colorWithRed:1 green:166/255.0 blue:17/255.0 alpha:1];
        [self.selectButton setTitle:@"去购买" forState:UIControlStateNormal];
        [self.selectButton addTarget:self action:@selector(selectButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.selectButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.coverImageView.frame = CGRectMake(0, 0, CGRectGetHeight(self.bounds), CGRectGetHeight(self.bounds));
    CGFloat positionX = CGRectGetMaxX(self.coverImageView.frame) + 10;
    self.nameLabel.frame = CGRectMake(positionX, 0, CGRectGetWidth(self.bounds)-positionX, 40);
    [self.nameLabel sizeToFit]; // 顶端对齐
    self.realPriceLabel.frame = CGRectMake(positionX, CGRectGetHeight(self.bounds)-25, 200, 25);
    [self.realPriceLabel sizeToFit];
    self.selectButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-60, CGRectGetHeight(self.bounds)-28, 60, 28);
    CGFloat priceLabelX = CGRectGetMaxX(self.realPriceLabel.frame) + 4;
    self.priceLabel.frame = CGRectMake(priceLabelX, CGRectGetMinY(self.realPriceLabel.frame)+4, CGRectGetMinX(self.selectButton.frame)-10-priceLabelX, 17);
}

#pragma mark - Setter

- (void)setCellModel:(PLVECCommodityCellModel *)cellModel {
    _cellModel = cellModel;
    if (!cellModel) {
        return;
    }
    
    self.nameLabel.text = cellModel.model.name;
    self.realPriceLabel.text = cellModel.realPriceStr;
    self.priceLabel.attributedText = cellModel.priceAtrrStr;
    self.showIdLabel.text = [NSString stringWithFormat:@"%ld",cellModel.model.showId];
    
    self.coverImageView.image = nil;
    [PLVFdUtil setImageWithURL:cellModel.coverUrl inImageView:self.coverImageView completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
        if (error) {
            NSLog(@"-setCellModel:图片加载失败，%@",imageURL);
        }
    }];
}

#pragma mark - Action

- (void)selectButtonAction {
    if (self.cellModel && [self.delegate respondsToSelector:@selector(commodity:didSelect:)]) {
        [self.delegate commodity:self didSelect:self.cellModel];
    }
}

@end
